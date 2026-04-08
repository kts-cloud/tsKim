#!/usr/bin/env python3
"""
ONNX 모델 검증 도구 (Model Validation Tool)

학습된 ONNX 모델을 로드하여 테스트 데이터에 대한 추론을 실행하고,
정확도 지표와 시각화 차트를 생성합니다.

Usage:
    python validate_model.py --model gamma_predictor.onnx --input synthetic_dataset.parquet
    python validate_model.py --model gamma_predictor.onnx --input steplog_dataset.parquet --output_dir ./results/
"""

import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # 비GUI 백엔드
import matplotlib.pyplot as plt
import numpy as np
import onnxruntime as ort
import pandas as pd


# ========== 정규화 (train_mlp.py와 동일) ==========

def normalize_inputs(df: pd.DataFrame) -> np.ndarray:
    """C# GammaPredictor.BuildInput()과 동일한 정규화."""
    features = np.column_stack([
        (df["Band"].values - 42.0) / 42.0,
        (df["Gray"].values - 256.0) / 256.0,
        (df["Target_x"].values - 0.31) / 0.04,
        (df["Target_y"].values - 0.32) / 0.03,
        np.log10(df["Target_Lv"].values + 1) / 3.5,
        (df["ELVSS"].values - 1.9) / 1.1,
        df["VAR_A_R"].values / 0.1,
        df["VAR_A_GB"].values / 0.1,
        df["InitLUT_R"].values / 32767.0,
        df["InitLUT_G"].values / 32767.0,
        df["InitLUT_B"].values / 32767.0,
    ])
    return features.astype(np.float32)


# ========== ONNX 추론 ==========

def run_inference(
    session: ort.InferenceSession,
    X: np.ndarray,
    batch_size: int = 4096,
) -> np.ndarray:
    """ONNX 모델로 배치 추론 실행."""
    input_name = session.get_inputs()[0].name
    all_preds = []

    for i in range(0, len(X), batch_size):
        batch = X[i:i + batch_size]
        result = session.run(None, {input_name: batch})
        all_preds.append(result[0])

    preds = np.vstack(all_preds)
    return preds * 32767.0  # DAC 단위로 복원


# ========== 지표 계산 ==========

def compute_metrics(preds: np.ndarray, labels: np.ndarray) -> dict:
    """채널별 MAE, RMSE, 정확도 범위 계산."""
    errors = preds - labels
    abs_errors = np.abs(errors)

    channel_names = ["Gamma_R", "Gamma_G", "Gamma_B"]
    metrics = {
        "overall_mae": abs_errors.mean(),
        "overall_rmse": np.sqrt(np.mean(errors ** 2)),
        "channels": {},
    }

    for i, name in enumerate(channel_names):
        ch_err = errors[:, i]
        ch_abs = abs_errors[:, i]
        metrics["channels"][name] = {
            "mae": ch_abs.mean(),
            "rmse": np.sqrt(np.mean(ch_err ** 2)),
            "max_error": ch_abs.max(),
            "std": ch_err.std(),
            "median_abs": np.median(ch_abs),
        }

    # 정확도 범위 (전체 채널 동시 만족)
    metrics["accuracy"] = {}
    for threshold in [1, 2, 3, 5, 10, 20]:
        within = (abs_errors <= threshold).all(axis=1).mean() * 100
        metrics["accuracy"][f"within_{threshold}_dac"] = within

    # 채널별 정확도
    for i, name in enumerate(channel_names):
        ch_abs = abs_errors[:, i]
        for threshold in [3, 5, 10]:
            within = (ch_abs <= threshold).mean() * 100
            metrics["channels"][name][f"within_{threshold}_dac"] = within

    return metrics


# ========== 시각화 ==========

def plot_scatter(preds: np.ndarray, labels: np.ndarray, output_dir: Path) -> None:
    """Predicted vs Actual 산점도 (R/G/B 채널별)."""
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    colors = ["#e74c3c", "#27ae60", "#3498db"]
    channel_names = ["Gamma_R", "Gamma_G", "Gamma_B"]

    for i, (ax, color, name) in enumerate(zip(axes, colors, channel_names)):
        # 포인트가 너무 많으면 샘플링
        n = len(preds)
        if n > 10000:
            idx = np.random.default_rng(42).choice(n, 10000, replace=False)
        else:
            idx = np.arange(n)

        ax.scatter(labels[idx, i], preds[idx, i], alpha=0.15, s=2, color=color)
        ax.plot([0, 32767], [0, 32767], "k--", linewidth=0.8, alpha=0.5)

        mae = np.abs(preds[:, i] - labels[:, i]).mean()
        ax.set_title(f"{name} (MAE={mae:.1f} DAC)", fontsize=12)
        ax.set_xlabel("Actual (DAC)")
        ax.set_ylabel("Predicted (DAC)")
        ax.set_xlim(0, 32767)
        ax.set_ylim(0, 32767)
        ax.set_aspect("equal")

    plt.tight_layout()
    path = output_dir / "scatter_predicted_vs_actual.png"
    plt.savefig(path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"[차트] {path}")


def plot_error_histogram(preds: np.ndarray, labels: np.ndarray, output_dir: Path) -> None:
    """예측 오차 히스토그램."""
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    colors = ["#e74c3c", "#27ae60", "#3498db"]
    channel_names = ["Gamma_R", "Gamma_G", "Gamma_B"]

    for i, (ax, color, name) in enumerate(zip(axes, colors, channel_names)):
        errors = preds[:, i] - labels[:, i]
        ax.hist(errors, bins=100, color=color, alpha=0.7, edgecolor="white", linewidth=0.3)

        mae = np.abs(errors).mean()
        std = errors.std()
        ax.axvline(0, color="black", linewidth=1, linestyle="--")
        ax.axvline(-3, color="gray", linewidth=0.8, linestyle=":")
        ax.axvline(3, color="gray", linewidth=0.8, linestyle=":")

        ax.set_title(f"{name} Error (MAE={mae:.1f}, STD={std:.1f})", fontsize=12)
        ax.set_xlabel("Error (DAC)")
        ax.set_ylabel("Count")

        # x축 범위 제한
        p99 = np.percentile(np.abs(errors), 99)
        ax.set_xlim(-p99 * 1.2, p99 * 1.2)

    plt.tight_layout()
    path = output_dir / "error_histogram.png"
    plt.savefig(path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"[차트] {path}")


def plot_per_band_mae(
    preds: np.ndarray, labels: np.ndarray, bands: np.ndarray, output_dir: Path,
) -> None:
    """Band별 MAE 막대 그래프."""
    unique_bands = np.sort(np.unique(bands))
    channel_names = ["Gamma_R", "Gamma_G", "Gamma_B"]
    colors = ["#e74c3c", "#27ae60", "#3498db"]

    fig, ax = plt.subplots(figsize=(14, 6))

    bar_width = 0.25
    x = np.arange(len(unique_bands))

    for i, (name, color) in enumerate(zip(channel_names, colors)):
        band_maes = []
        for band in unique_bands:
            mask = bands == band
            if mask.sum() > 0:
                mae = np.abs(preds[mask, i] - labels[mask, i]).mean()
            else:
                mae = 0
            band_maes.append(mae)

        ax.bar(x + i * bar_width, band_maes, bar_width, label=name, color=color, alpha=0.8)

    ax.set_xlabel("Band")
    ax.set_ylabel("MAE (DAC)")
    ax.set_title("Per-Band MAE by Channel")
    ax.set_xticks(x + bar_width)
    ax.set_xticklabels([str(b) for b in unique_bands], rotation=45 if len(unique_bands) > 10 else 0)
    ax.legend()
    ax.grid(axis="y", alpha=0.3)

    plt.tight_layout()
    path = output_dir / "per_band_mae.png"
    plt.savefig(path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"[차트] {path}")


def plot_training_history(output_dir: Path, onnx_path: Path) -> None:
    """학습 이력 차트 (train_mlp.py가 저장한 .history.csv 사용)."""
    history_path = onnx_path.with_suffix(".history.csv")
    if not history_path.exists():
        print(f"[차트] 학습 이력 파일 없음: {history_path}")
        return

    hist = pd.read_csv(history_path)

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(hist["epoch"], hist["train_loss"], label="Train Loss", linewidth=1.5)
    ax.plot(hist["epoch"], hist["val_loss"], label="Val Loss", linewidth=1.5)
    ax.set_xlabel("Epoch")
    ax.set_ylabel("MSE Loss")
    ax.set_title("Training History")
    ax.legend()
    ax.grid(alpha=0.3)
    ax.set_yscale("log")

    plt.tight_layout()
    path = output_dir / "training_history.png"
    plt.savefig(path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"[차트] {path}")


# ========== 리포트 ==========

def print_report(metrics: dict) -> None:
    """검증 결과 요약 리포트 출력."""
    print(f"\n{'=' * 60}")
    print(f"모델 검증 결과 (Model Validation Report)")
    print(f"{'=' * 60}")

    print(f"\n--- 전체 지표 ---")
    print(f"  MAE:  {metrics['overall_mae']:.2f} DAC")
    print(f"  RMSE: {metrics['overall_rmse']:.2f} DAC")

    print(f"\n--- 채널별 지표 ---")
    print(f"  {'채널':<10} {'MAE':>8} {'RMSE':>8} {'Max':>8} {'Median':>8}")
    print(f"  {'-'*42}")
    for name, ch in metrics["channels"].items():
        print(f"  {name:<10} {ch['mae']:>8.2f} {ch['rmse']:>8.2f} "
              f"{ch['max_error']:>8.1f} {ch['median_abs']:>8.2f}")

    print(f"\n--- 정확도 범위 (전 채널 동시) ---")
    for key, val in metrics["accuracy"].items():
        threshold = key.replace("within_", "+-").replace("_dac", " DAC")
        print(f"  {threshold}: {val:.1f}%")

    print(f"\n--- 채널별 정확도 ---")
    for name, ch in metrics["channels"].items():
        parts = []
        for threshold in [3, 5, 10]:
            k = f"within_{threshold}_dac"
            if k in ch:
                parts.append(f"+-{threshold}={ch[k]:.1f}%")
        print(f"  {name}: {', '.join(parts)}")


# ========== Main ==========

def main():
    parser = argparse.ArgumentParser(
        description="ONNX Gamma 예측 모델 검증 및 시각화"
    )
    parser.add_argument(
        "--model", required=True,
        help="ONNX 모델 파일 경로",
    )
    parser.add_argument(
        "--input", required=True,
        help="테스트 데이터셋 Parquet 파일 경로",
    )
    parser.add_argument(
        "--output_dir", default="./results/",
        help="차트 출력 디렉토리 (기본: ./results/)",
    )
    parser.add_argument(
        "--test_ratio", type=float, default=0.15,
        help="테스트 셋 비율 (기본: 0.15, 뒤쪽 N%%만 사용)",
    )
    args = parser.parse_args()

    # ONNX 모델 로드
    model_path = Path(args.model)
    if not model_path.exists():
        print(f"[오류] 모델 파일을 찾을 수 없습니다: {args.model}")
        sys.exit(1)

    print(f"[모델] {model_path} 로드 중...")
    session = ort.InferenceSession(
        str(model_path),
        providers=["CPUExecutionProvider"],
    )
    input_info = session.get_inputs()[0]
    output_info = session.get_outputs()[0]
    print(f"  입력: {input_info.name} {input_info.shape}")
    print(f"  출력: {output_info.name} {output_info.shape}")

    # 데이터 로드
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[오류] 데이터 파일을 찾을 수 없습니다: {args.input}")
        sys.exit(1)

    if input_path.suffix == '.csv':
        df = pd.read_csv(input_path)
    else:
        df = pd.read_parquet(input_path)
    print(f"[데이터] {len(df):,}행 로드: {input_path}")

    # 테스트 셋 분할 (학습 시와 동일한 분할 유지)
    if "panel_id" in df.columns:
        panel_ids = df["panel_id"].unique()
        rng = np.random.default_rng(42)
        rng.shuffle(panel_ids)
        n = len(panel_ids)
        n_train = int(n * 0.70)
        n_val = int(n * 0.15)
        test_panels = set(panel_ids[n_train + n_val:])
        test_df = df[df["panel_id"].isin(test_panels)].copy()
    else:
        df_shuffled = df.sample(frac=1.0, random_state=42).reset_index(drop=True)
        n = len(df_shuffled)
        test_start = int(n * (1.0 - args.test_ratio))
        test_df = df_shuffled[test_start:].copy()

    print(f"[테스트] {len(test_df):,}행")

    # 필수 컬럼 확인
    required_input = ["Band", "Gray", "Target_x", "Target_y", "Target_Lv",
                       "ELVSS", "VAR_A_R", "VAR_A_GB", "InitLUT_R", "InitLUT_G", "InitLUT_B"]
    required_output = ["Gamma_R", "Gamma_G", "Gamma_B"]
    missing = [c for c in required_input + required_output if c not in test_df.columns]
    if missing:
        print(f"[오류] 필수 컬럼 누락: {missing}")
        sys.exit(1)

    # NaN 제거
    test_df = test_df.dropna(subset=required_input + required_output)

    # 정규화 및 추론
    X_test = normalize_inputs(test_df)
    labels = np.column_stack([
        test_df["Gamma_R"].values,
        test_df["Gamma_G"].values,
        test_df["Gamma_B"].values,
    ])

    print(f"[추론] {len(X_test):,}개 샘플...")
    preds = run_inference(session, X_test)

    # 지표 계산
    metrics = compute_metrics(preds, labels)

    # 리포트 출력
    print_report(metrics)

    # 차트 생성
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"\n[차트] 출력 디렉토리: {output_dir.resolve()}")

    plot_scatter(preds, labels, output_dir)
    plot_error_histogram(preds, labels, output_dir)

    if "Band" in test_df.columns:
        bands = test_df["Band"].values
        plot_per_band_mae(preds, labels, bands, output_dir)

    plot_training_history(output_dir, model_path)

    # 결과 CSV 저장
    results_df = pd.DataFrame({
        "Band": test_df["Band"].values,
        "Gray": test_df["Gray"].values,
        "Actual_R": labels[:, 0],
        "Actual_G": labels[:, 1],
        "Actual_B": labels[:, 2],
        "Pred_R": preds[:, 0],
        "Pred_G": preds[:, 1],
        "Pred_B": preds[:, 2],
        "Error_R": preds[:, 0] - labels[:, 0],
        "Error_G": preds[:, 1] - labels[:, 1],
        "Error_B": preds[:, 2] - labels[:, 2],
    })
    csv_path = output_dir / "validation_results.csv"
    results_df.to_csv(csv_path, index=False)
    print(f"\n[저장] 상세 결과: {csv_path}")

    print(f"\n검증 완료.")


if __name__ == "__main__":
    main()
