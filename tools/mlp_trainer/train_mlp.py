#!/usr/bin/env python3
"""
MLP Gamma 예측 모델 학습 및 ONNX 내보내기

학습 데이터셋(Parquet)으로 MLP를 학습하고,
ONNX 형식으로 내보내어 C# OnnxRuntime에서 추론할 수 있게 합니다.

Usage:
    python train_mlp.py --input synthetic_dataset.parquet
    python train_mlp.py --input steplog_dataset.parquet --epochs 300 --batch_size 512
"""

import argparse
import copy
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset


# ========== 모델 정의 ==========

class GammaPredictorMLP(nn.Module):
    """
    MLP Gamma 예측 모델.

    입력 (11): Band, Gray, Target_x, Target_y, Target_Lv,
               ELVSS, VAR_A_R, VAR_A_GB, InitLUT_R, InitLUT_G, InitLUT_B
    출력 (3):  Gamma_R, Gamma_G, Gamma_B (정규화 0~1, 실제값 = x * 32767)
    """

    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(11, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.1),
            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.1),
            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Linear(64, 3),  # Gamma_R, G, B (정규화 0~1)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


# ========== 정규화 (C# GammaPredictor.BuildInput과 동일) ==========

def normalize_inputs(df: pd.DataFrame) -> np.ndarray:
    """
    입력 특성 정규화.
    C# GammaPredictor.BuildInput()과 동일한 정규화 적용.
    """
    features = np.column_stack([
        (df["Band"].values - 42.0) / 42.0,           # Band: 중심 42, 범위 ~84
        (df["Gray"].values - 256.0) / 256.0,          # Gray: 중심 256, 범위 ~512
        (df["Target_x"].values - 0.31) / 0.04,        # Target_x: CIE x 좌표
        (df["Target_y"].values - 0.32) / 0.03,        # Target_y: CIE y 좌표
        np.log10(df["Target_Lv"].values + 1) / 3.5,   # Target_Lv: 로그 스케일
        (df["ELVSS"].values - 1.9) / 1.1,             # ELVSS: 중심 1.9V
        df["VAR_A_R"].values / 0.1,                    # VAR_A_R: +-0.1V 범위
        df["VAR_A_GB"].values / 0.1,                   # VAR_A_GB: +-0.1V 범위
        df["InitLUT_R"].values / 32767.0,              # InitLUT: DAC 정규화
        df["InitLUT_G"].values / 32767.0,
        df["InitLUT_B"].values / 32767.0,
    ])
    return features.astype(np.float32)


def normalize_outputs(df: pd.DataFrame) -> np.ndarray:
    """출력 정규화: Gamma DAC → 0~1 범위."""
    outputs = np.column_stack([
        df["Gamma_R"].values / 32767.0,
        df["Gamma_G"].values / 32767.0,
        df["Gamma_B"].values / 32767.0,
    ])
    return outputs.astype(np.float32)


# ========== 데이터 분할 ==========

def split_dataset(
    df: pd.DataFrame,
    train_ratio: float = 0.70,
    val_ratio: float = 0.15,
    force_random: bool = False,
) -> tuple:
    """
    데이터셋을 train/val/test로 분할.
    force_random=True이면 항상 랜덤 분할.
    force_random=False이고 panel_id가 있으면 패널 단위 분할.
    """
    use_panel = ("panel_id" in df.columns) and (not force_random)

    if use_panel:
        # 패널 단위 분할
        panel_ids = df["panel_id"].unique()
        rng = np.random.default_rng(42)
        rng.shuffle(panel_ids)

        n = len(panel_ids)
        n_train = int(n * train_ratio)
        n_val = int(n * val_ratio)

        train_panels = set(panel_ids[:n_train])
        val_panels = set(panel_ids[n_train:n_train + n_val])
        test_panels = set(panel_ids[n_train + n_val:])

        train_df = df[df["panel_id"].isin(train_panels)]
        val_df = df[df["panel_id"].isin(val_panels)]
        test_df = df[df["panel_id"].isin(test_panels)]

        print(f"[분할] 패널 단위 - train: {len(train_panels)}패널 ({len(train_df)}행), "
              f"val: {len(val_panels)}패널 ({len(val_df)}행), "
              f"test: {len(test_panels)}패널 ({len(test_df)}행)")
    else:
        # 랜덤 분할
        df_shuffled = df.sample(frac=1.0, random_state=42).reset_index(drop=True)
        n = len(df_shuffled)
        n_train = int(n * train_ratio)
        n_val = int(n * val_ratio)

        train_df = df_shuffled[:n_train]
        val_df = df_shuffled[n_train:n_train + n_val]
        test_df = df_shuffled[n_train + n_val:]

        print(f"[분할] 랜덤 - train: {len(train_df)}, val: {len(val_df)}, test: {len(test_df)}")

    return train_df, val_df, test_df


# ========== 학습 루프 ==========

def train_model(
    model: nn.Module,
    train_loader: DataLoader,
    val_loader: DataLoader,
    epochs: int,
    lr: float,
    weight_decay: float,
    patience: int,
    device: torch.device,
) -> dict:
    """모델 학습 + Early Stopping."""
    model.to(device)

    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=weight_decay)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingWarmRestarts(optimizer, T_0=10, T_mult=2)
    criterion = nn.MSELoss()

    best_val_loss = float("inf")
    best_model_state = None
    patience_counter = 0
    history = {"train_loss": [], "val_loss": []}

    print(f"\n{'Epoch':>6} | {'Train Loss':>12} | {'Val Loss':>12} | {'LR':>10} | {'Status'}")
    print("-" * 65)

    for epoch in range(1, epochs + 1):
        # --- Train ---
        model.train()
        train_losses = []
        for X_batch, y_batch in train_loader:
            X_batch, y_batch = X_batch.to(device), y_batch.to(device)

            optimizer.zero_grad()
            pred = model(X_batch)
            loss = criterion(pred, y_batch)
            loss.backward()
            optimizer.step()
            train_losses.append(loss.item())

        scheduler.step()
        avg_train_loss = np.mean(train_losses)

        # --- Validation ---
        model.eval()
        val_losses = []
        with torch.no_grad():
            for X_batch, y_batch in val_loader:
                X_batch, y_batch = X_batch.to(device), y_batch.to(device)
                pred = model(X_batch)
                loss = criterion(pred, y_batch)
                val_losses.append(loss.item())

        avg_val_loss = np.mean(val_losses)
        current_lr = optimizer.param_groups[0]["lr"]

        history["train_loss"].append(avg_train_loss)
        history["val_loss"].append(avg_val_loss)

        # --- Early Stopping ---
        status = ""
        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            best_model_state = copy.deepcopy(model.state_dict())
            patience_counter = 0
            status = "* best"
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"{'':>6} | Early stopping at epoch {epoch} (patience={patience})")
                break

        if epoch % 5 == 0 or epoch <= 3 or status:
            print(f"{epoch:6d} | {avg_train_loss:12.6f} | {avg_val_loss:12.6f} | "
                  f"{current_lr:10.2e} | {status}")

    # 최적 가중치 복원
    if best_model_state is not None:
        model.load_state_dict(best_model_state)

    return history


# ========== 평가 ==========

def evaluate_model(
    model: nn.Module,
    test_loader: DataLoader,
    device: torch.device,
) -> dict:
    """테스트 셋 평가: MAE를 DAC 단위로 계산."""
    model.eval()
    all_preds = []
    all_labels = []

    with torch.no_grad():
        for X_batch, y_batch in test_loader:
            X_batch = X_batch.to(device)
            pred = model(X_batch)
            all_preds.append(pred.cpu().numpy())
            all_labels.append(y_batch.numpy())

    preds = np.vstack(all_preds) * 32767.0  # DAC 단위로 복원
    labels = np.vstack(all_labels) * 32767.0

    errors = preds - labels
    abs_errors = np.abs(errors)

    # 전체 MAE
    overall_mae = abs_errors.mean()

    # 채널별 MAE
    channel_names = ["Gamma_R", "Gamma_G", "Gamma_B"]
    channel_mae = {}
    for i, name in enumerate(channel_names):
        channel_mae[name] = abs_errors[:, i].mean()

    print(f"\n{'=' * 50}")
    print(f"테스트 셋 평가 결과 (DAC 단위)")
    print(f"{'=' * 50}")
    print(f"전체 MAE: {overall_mae:.2f} DAC")
    for name, mae in channel_mae.items():
        print(f"  {name} MAE: {mae:.2f} DAC")

    # RMSE
    rmse = np.sqrt(np.mean(errors ** 2, axis=0))
    print(f"\nRMSE: R={rmse[0]:.2f}, G={rmse[1]:.2f}, B={rmse[2]:.2f}")

    # 정확도 범위
    for threshold in [3, 5, 10]:
        within = (abs_errors <= threshold).all(axis=1).mean() * 100
        print(f"+-{threshold} DAC 이내: {within:.1f}%")

    return {
        "overall_mae": overall_mae,
        "channel_mae": channel_mae,
        "preds": preds,
        "labels": labels,
    }


# ========== ONNX 내보내기 ==========

def export_onnx(
    model: nn.Module,
    output_path: str,
    device: torch.device,
) -> None:
    """ONNX 형식으로 모델 내보내기 (동적 배치 축)."""
    model.eval()
    model.to("cpu")

    dummy_input = torch.randn(1, 11, dtype=torch.float32)

    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        export_params=True,
        opset_version=17,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={
            "input": {0: "batch_size"},
            "output": {0: "batch_size"},
        },
    )

    file_size = Path(output_path).stat().st_size / 1024
    print(f"\n[ONNX] 저장 완료: {output_path} ({file_size:.1f} KB)")

    # ONNX 검증
    try:
        import onnx
        onnx_model = onnx.load(output_path)
        onnx.checker.check_model(onnx_model)
        print("[ONNX] 모델 검증 통과")
    except ImportError:
        print("[ONNX] onnx 패키지 없음 - 검증 건너뜀")
    except Exception as e:
        print(f"[ONNX] 검증 실패: {e}")


# ========== Main ==========

def main():
    parser = argparse.ArgumentParser(
        description="MLP Gamma 예측 모델 학습 및 ONNX 내보내기"
    )
    parser.add_argument(
        "--input", required=True,
        help="학습 데이터셋 파일 경로 (CSV/Parquet)",
    )
    parser.add_argument(
        "--input_real", default=None,
        help="실제 StepLog 데이터 (CSV/Parquet). 가상 데이터와 혼합 학습 시 사용",
    )
    parser.add_argument(
        "--real_weight", type=float, default=10.0,
        help="실 데이터 반복 배수 (기본: 10). 실 데이터를 N배 복제하여 가중치 부여",
    )
    parser.add_argument(
        "--output", default="gamma_predictor.onnx",
        help="출력 ONNX 모델 경로 (기본: gamma_predictor.onnx)",
    )
    parser.add_argument(
        "--epochs", type=int, default=200,
        help="최대 에포크 수 (기본: 200)",
    )
    parser.add_argument(
        "--batch_size", type=int, default=1024,
        help="배치 크기 (기본: 1024)",
    )
    parser.add_argument(
        "--lr", type=float, default=1e-3,
        help="학습률 (기본: 1e-3)",
    )
    parser.add_argument(
        "--weight_decay", type=float, default=1e-4,
        help="가중치 감쇠 (기본: 1e-4)",
    )
    parser.add_argument(
        "--patience", type=int, default=15,
        help="Early stopping patience (기본: 15)",
    )
    parser.add_argument(
        "--split", choices=["auto", "random", "panel"], default="auto",
        help="분할 방식: auto(panel_id 있으면 패널), random(항상 랜덤), panel(항상 패널) (기본: auto)",
    )
    parser.add_argument(
        "--device", default="auto",
        help="학습 디바이스: cpu, cuda, auto (기본: auto)",
    )
    args = parser.parse_args()

    # 디바이스 설정
    if args.device == "auto":
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    else:
        device = torch.device(args.device)
    print(f"[디바이스] {device}")

    # 데이터 로드
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[오류] 파일을 찾을 수 없습니다: {args.input}")
        sys.exit(1)

    if input_path.suffix == '.csv':
        df = pd.read_csv(input_path)
    else:
        df = pd.read_parquet(input_path)
    print(f"[데이터] {len(df):,}행 로드 (주 데이터): {input_path}")

    # 실 데이터 혼합 (--input_real 지정 시)
    if args.input_real:
        real_path = Path(args.input_real)
        if real_path.exists():
            if real_path.suffix == '.csv':
                df_real = pd.read_csv(real_path)
            else:
                df_real = pd.read_parquet(real_path)
            n_real = len(df_real)
            # 실 데이터를 real_weight배 복제하여 가중치 부여
            repeat = max(1, int(args.real_weight))
            df_real_repeated = pd.concat([df_real] * repeat, ignore_index=True)
            df = pd.concat([df, df_real_repeated], ignore_index=True).sample(frac=1, random_state=42).reset_index(drop=True)
            print(f"[혼합] 실 데이터 {n_real:,}행 x {repeat}배 = {len(df_real_repeated):,}행 추가 → 총 {len(df):,}행")
        else:
            print(f"[경고] 실 데이터 파일 없음: {args.input_real}")

    # 필수 컬럼 확인
    required_cols = [
        "Band", "Gray", "Target_x", "Target_y", "Target_Lv",
        "ELVSS", "VAR_A_R", "VAR_A_GB",
        "InitLUT_R", "InitLUT_G", "InitLUT_B",
        "Gamma_R", "Gamma_G", "Gamma_B",
    ]
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        print(f"[오류] 필수 컬럼 누락: {missing}")
        sys.exit(1)

    # NaN 제거
    before = len(df)
    df = df.dropna(subset=required_cols)
    if len(df) < before:
        print(f"[정제] NaN 행 {before - len(df)}개 제거")

    # 데이터 분할
    force_random = (args.split == "random")
    train_df, val_df, test_df = split_dataset(df, force_random=force_random)

    # 정규화
    X_train = normalize_inputs(train_df)
    y_train = normalize_outputs(train_df)
    X_val = normalize_inputs(val_df)
    y_val = normalize_outputs(val_df)
    X_test = normalize_inputs(test_df)
    y_test = normalize_outputs(test_df)

    # NaN/Inf 체크
    for name, arr in [("X_train", X_train), ("y_train", y_train)]:
        if np.any(np.isnan(arr)) or np.any(np.isinf(arr)):
            print(f"[경고] {name}에 NaN/Inf 발견. 해당 행 제거 중...")

    # DataLoader 생성
    train_ds = TensorDataset(torch.from_numpy(X_train), torch.from_numpy(y_train))
    val_ds = TensorDataset(torch.from_numpy(X_val), torch.from_numpy(y_val))
    test_ds = TensorDataset(torch.from_numpy(X_test), torch.from_numpy(y_test))

    train_loader = DataLoader(train_ds, batch_size=args.batch_size, shuffle=True, drop_last=True)
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False)
    test_loader = DataLoader(test_ds, batch_size=args.batch_size, shuffle=False)

    print(f"[DataLoader] train: {len(train_loader)} batches, "
          f"val: {len(val_loader)} batches, test: {len(test_loader)} batches")

    # 모델 생성
    model = GammaPredictorMLP()
    total_params = sum(p.numel() for p in model.parameters())
    print(f"[모델] GammaPredictorMLP - {total_params:,} 파라미터")

    # 학습
    start_time = time.time()
    history = train_model(
        model, train_loader, val_loader,
        epochs=args.epochs,
        lr=args.lr,
        weight_decay=args.weight_decay,
        patience=args.patience,
        device=device,
    )
    elapsed = time.time() - start_time
    print(f"\n[학습] 완료: {elapsed:.1f}초, {len(history['train_loss'])} 에포크")

    # 테스트 평가
    results = evaluate_model(model, test_loader, device)

    # ONNX 내보내기
    export_onnx(model, args.output, device)

    # 학습 이력 저장 (검증 도구에서 활용)
    history_path = Path(args.output).with_suffix(".history.csv")
    history_df = pd.DataFrame({
        "epoch": range(1, len(history["train_loss"]) + 1),
        "train_loss": history["train_loss"],
        "val_loss": history["val_loss"],
    })
    history_df.to_csv(history_path, index=False)
    print(f"[이력] 저장: {history_path}")

    print(f"\n{'=' * 50}")
    print(f"완료 요약")
    print(f"{'=' * 50}")
    print(f"모델: {args.output}")
    print(f"테스트 MAE: {results['overall_mae']:.2f} DAC")
    for ch, mae in results["channel_mae"].items():
        print(f"  {ch}: {mae:.2f} DAC")


if __name__ == "__main__":
    main()
