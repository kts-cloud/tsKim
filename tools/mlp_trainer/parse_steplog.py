#!/usr/bin/env python3
"""
StepLog CSV 파서 (Real Production Data Parser)

실제 OC 프로세스에서 생성된 StepLog CSV 파일들을 파싱하여
수렴된 (최종 루프) 데이터를 추출하고 학습용 데이터셋으로 변환합니다.

Usage:
    python parse_steplog.py --input_dir ./steplogs/
    python parse_steplog.py --input_dir ./steplogs/ --param_csv path/to/DGMA_Parameter.csv
"""

import argparse
import os
import sys
from pathlib import Path
from typing import List

import numpy as np
import pandas as pd


# StepLog CSV 컬럼 정의
STEPLOG_COLUMNS = [
    "Date", "CH", "SEQUENCE", "BAND", "DBV", "REAL_GRAY",
    "OC_TOTAL_Time", "Step_OC_Time", "LOOP",
    "GAMMA_R", "GAMMA_G", "GAMMA_B",
    "Measured_X", "Measured_Y", "Measured_LV",
    "V_R", "V_G", "V_B",
    "TOP_V_R", "TOP_V_G", "TOP_V_B",
    "BOT_V_R", "BOT_V_G", "BOT_V_B",
    "VSSEL", "VAR_AR", "VAR_AGB",
]


def find_steplog_files(input_dir: str) -> List[Path]:
    """StepLog CSV 파일을 재귀적으로 탐색."""
    root = Path(input_dir)
    if not root.exists():
        print(f"[오류] 디렉토리가 존재하지 않습니다: {input_dir}")
        sys.exit(1)

    files = sorted(root.rglob("*.csv"))
    # StepLog 패턴 필터: 파일명에 'StepLog' 또는 'steplog' 포함
    steplog_files = [f for f in files if "steplog" in f.name.lower()]

    if not steplog_files:
        # StepLog 패턴이 없으면 모든 CSV 시도
        print(f"[경고] 'StepLog' 패턴 파일 없음. 전체 CSV 파일 시도 ({len(files)}개)")
        steplog_files = files

    print(f"[탐색] {input_dir} 에서 {len(steplog_files)}개 CSV 파일 발견")
    return steplog_files


def parse_dgma_targets(csv_path: str) -> pd.DataFrame:
    """
    DGMA_Parameter.csv에서 Band+Gray별 Target 값 로드.
    StepLog 데이터에 Target_x, Target_y, Target_Lv를 조인하기 위함.
    """
    df = pd.read_csv(csv_path, header=None, skiprows=2)

    targets = pd.DataFrame({
        "Band": pd.to_numeric(df.iloc[:, 0], errors="coerce"),
        "Gray": pd.to_numeric(df.iloc[:, 1], errors="coerce"),
        "Target_x": pd.to_numeric(df.iloc[:, 5], errors="coerce"),
        "Target_y": pd.to_numeric(df.iloc[:, 6], errors="coerce"),
        "Target_Lv": pd.to_numeric(df.iloc[:, 7], errors="coerce"),
        "OCExec": pd.to_numeric(df.iloc[:, 11], errors="coerce"),
    })

    # 활성 탭만
    targets = targets[targets["OCExec"] == 1].copy()
    targets = targets[targets["Target_Lv"] > 0].copy()
    targets.drop(columns=["OCExec"], inplace=True)
    targets.reset_index(drop=True, inplace=True)

    print(f"[DGMA] Target 테이블: {len(targets)}행 (활성 탭)")
    return targets


def parse_single_steplog(file_path: Path) -> pd.DataFrame | None:
    """단일 StepLog CSV 파일 파싱."""
    try:
        df = pd.read_csv(file_path, header=0)

        # 컬럼 수 확인
        if len(df.columns) < 27:
            print(f"  [건너뜀] 컬럼 부족 ({len(df.columns)}): {file_path.name}")
            return None

        # 컬럼명 정규화 (공백 제거)
        df.columns = [c.strip() for c in df.columns]

        # 필수 컬럼 존재 확인
        required = ["BAND", "REAL_GRAY", "LOOP", "GAMMA_R", "GAMMA_G", "GAMMA_B",
                     "VSSEL", "VAR_AR", "VAR_AGB"]
        # 대소문자 무시 매핑
        col_map = {c.upper(): c for c in df.columns}
        missing = [r for r in required if r.upper() not in col_map]
        if missing:
            # CH 컬럼 없으면 'CH' 대신 다른 이름일 수 있음
            print(f"  [건너뜀] 필수 컬럼 누락 {missing}: {file_path.name}")
            return None

        # 숫자 변환
        numeric_cols = ["BAND", "REAL_GRAY", "LOOP", "GAMMA_R", "GAMMA_G", "GAMMA_B",
                        "VSSEL", "VAR_AR", "VAR_AGB"]
        for col in numeric_cols:
            actual_col = col_map.get(col.upper(), col)
            if actual_col in df.columns:
                df[actual_col] = pd.to_numeric(df[actual_col], errors="coerce")

        return df

    except Exception as e:
        print(f"  [오류] {file_path.name}: {e}")
        return None


def extract_converged_data(df: pd.DataFrame, file_id: int) -> pd.DataFrame:
    """
    각 (CH, BAND, REAL_GRAY) 그룹에서:
    - LOOP=max인 행 = 수렴된 결과 (라벨)
    - LOOP=0인 행 = InitLUT (입력 특성)
    """
    # CH 컬럼 존재 확인
    col_map = {c.upper(): c for c in df.columns}
    ch_col = col_map.get("CH", "CH")
    band_col = col_map.get("BAND", "BAND")
    gray_col = col_map.get("REAL_GRAY", "REAL_GRAY")
    loop_col = col_map.get("LOOP", "LOOP")

    group_cols = [ch_col, band_col, gray_col]
    # CH가 없으면 BAND, REAL_GRAY만으로 그룹
    if ch_col not in df.columns:
        group_cols = [band_col, gray_col]

    records = []

    for group_key, group_df in df.groupby(group_cols):
        # 수렴 결과: max LOOP
        max_loop_idx = group_df[loop_col].idxmax()
        converged = group_df.loc[max_loop_idx]

        gamma_r = converged.get("GAMMA_R", 0)
        gamma_g = converged.get("GAMMA_G", 0)
        gamma_b = converged.get("GAMMA_B", 0)

        # 감마값이 모두 0이면 건너뜀 (미실행 탭)
        if gamma_r == 0 and gamma_g == 0 and gamma_b == 0:
            continue

        # InitLUT: LOOP=0 행
        init_rows = group_df[group_df[loop_col] == 0]
        if len(init_rows) > 0:
            init_row = init_rows.iloc[0]
            init_r = init_row.get("GAMMA_R", gamma_r)
            init_g = init_row.get("GAMMA_G", gamma_g)
            init_b = init_row.get("GAMMA_B", gamma_b)
        else:
            # LOOP=0이 없으면 min LOOP 사용
            min_loop_idx = group_df[loop_col].idxmin()
            init_row = group_df.loc[min_loop_idx]
            init_r = init_row.get("GAMMA_R", gamma_r)
            init_g = init_row.get("GAMMA_G", gamma_g)
            init_b = init_row.get("GAMMA_B", gamma_b)

        records.append({
            "file_id": file_id,
            "Band": int(converged.get(band_col, 0)),
            "Gray": int(converged.get(gray_col, 0)),
            "ELVSS": converged.get("VSSEL", 0),
            "VAR_A_R": converged.get("VAR_AR", 0),
            "VAR_A_GB": converged.get("VAR_AGB", 0),
            "InitLUT_R": init_r,
            "InitLUT_G": init_g,
            "InitLUT_B": init_b,
            "Gamma_R": gamma_r,
            "Gamma_G": gamma_g,
            "Gamma_B": gamma_b,
        })

    return pd.DataFrame(records)


def main():
    parser = argparse.ArgumentParser(
        description="StepLog CSV 파싱 및 학습 데이터셋 추출"
    )
    parser.add_argument(
        "--input_dir", required=True,
        help="StepLog CSV 파일이 있는 디렉토리 (재귀 탐색)",
    )
    parser.add_argument(
        "--param_csv",
        default="../../IT_OLED_OC_X3584_CSharp/LGDDLL/Setting/Parameters/X3584/DGMA_Parameter.csv",
        help="DGMA_Parameter.csv 경로 (Target 값 조인용)",
    )
    parser.add_argument(
        "--output", default="steplog_dataset.parquet",
        help="출력 Parquet 파일 경로 (기본: steplog_dataset.parquet)",
    )
    args = parser.parse_args()

    # DGMA Target 로드
    param_path = Path(args.param_csv)
    if not param_path.exists():
        script_dir = Path(__file__).resolve().parent
        param_path = script_dir / args.param_csv
    if not param_path.exists():
        print(f"[오류] DGMA_Parameter.csv를 찾을 수 없습니다: {args.param_csv}")
        sys.exit(1)

    targets = parse_dgma_targets(str(param_path))

    # StepLog 파일 탐색
    steplog_files = find_steplog_files(args.input_dir)
    if not steplog_files:
        print("[오류] CSV 파일을 찾을 수 없습니다.")
        sys.exit(1)

    # 전체 파일 파싱
    all_data = []
    success_count = 0

    for i, fpath in enumerate(steplog_files):
        print(f"\n[{i+1}/{len(steplog_files)}] {fpath.name}")
        raw = parse_single_steplog(fpath)
        if raw is None:
            continue

        extracted = extract_converged_data(raw, file_id=i)
        if len(extracted) > 0:
            all_data.append(extracted)
            success_count += 1
            print(f"  추출: {len(extracted)}행 (수렴 데이터)")
        else:
            print(f"  [건너뜀] 유효 데이터 없음")

    if not all_data:
        print("\n[오류] 유효한 데이터가 없습니다.")
        sys.exit(1)

    # 병합
    df = pd.concat(all_data, ignore_index=True)
    print(f"\n[병합] 총 {len(df)}행 (파일 {success_count}개)")

    # StepLog Band는 0-based, DGMA_Parameter Band는 1-based → +1 보정
    df["Band_csv"] = df["Band"] + 1
    df = df.merge(targets, left_on=["Band_csv", "Gray"], right_on=["Band", "Gray"],
                  how="left", suffixes=("", "_target"))
    # Band 원본(0-based) 유지, 조인용 임시 컬럼 제거
    if "Band_target" in df.columns:
        df.drop(columns=["Band_target"], inplace=True)
    df.drop(columns=["Band_csv"], inplace=True)

    # Target 없는 행 제거
    before = len(df)
    df = df.dropna(subset=["Target_x", "Target_y", "Target_Lv"])
    after = len(df)
    if before != after:
        print(f"[조인] Target 매칭 안 되는 {before - after}행 제거")

    # panel_id 할당 (file_id 기반)
    df["panel_id"] = df["file_id"]
    df.drop(columns=["file_id"], inplace=True)

    # 컬럼 순서 정리
    col_order = [
        "panel_id", "Band", "Gray",
        "Target_x", "Target_y", "Target_Lv",
        "ELVSS", "VAR_A_R", "VAR_A_GB",
        "InitLUT_R", "InitLUT_G", "InitLUT_B",
        "Gamma_R", "Gamma_G", "Gamma_B",
    ]
    df = df[[c for c in col_order if c in df.columns]]

    # 저장 (parquet 또는 CSV 폴백)
    output_path = Path(args.output)
    try:
        df.to_parquet(output_path, index=False, engine="pyarrow")
        print(f"\n[저장] {output_path.resolve()}")
    except Exception:
        csv_path = output_path.with_suffix('.csv')
        df.to_csv(csv_path, index=False)
        print(f"\n[저장] {csv_path.resolve()} (parquet 미지원 → CSV)")

    # 통계
    print("\n" + "=" * 60)
    print("StepLog 데이터셋 통계")
    print("=" * 60)
    print(f"총 샘플 수: {len(df):,}")
    print(f"패널(파일) 수: {df['panel_id'].nunique()}")

    print(f"\n--- Band별 분포 ---")
    for band, count in df.groupby("Band").size().items():
        print(f"  Band {band:2d}: {count:>6,} 샘플")

    print(f"\n--- Gamma DAC 범위 ---")
    for ch in ["Gamma_R", "Gamma_G", "Gamma_B"]:
        if ch in df.columns:
            print(f"  {ch}: min={df[ch].min():.1f}, max={df[ch].max():.1f}, "
                  f"mean={df[ch].mean():.1f}")


if __name__ == "__main__":
    main()
