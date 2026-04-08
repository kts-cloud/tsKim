#!/usr/bin/env python3
"""
합성 학습 데이터 생성기 (Synthetic Training Data Generator)

실제 StepLog CSV 데이터에서 (Band, Gray) → 수렴 Gamma 분포를 학습한 후,
해당 분포를 기반으로 대량의 가상 학습 데이터를 생성합니다.

StepLog가 없을 경우 DGMA_Parameter.csv의 초기 Gamma와 물리 모델로 시뮬레이션합니다.

Usage:
    # 실제 StepLog 기반 (권장)
    python generate_synthetic_data.py --steplog_dir ../../IT_OLED_OC_X3584_CSharp/LGDDLL/OCLog/StepLog --num_panels 10000

    # StepLog 없이 물리 모델만 사용
    python generate_synthetic_data.py --param_csv ../../IT_OLED_OC_X3584_CSharp/LGDDLL/Setting/Parameters/X3584/DGMA_Parameter.csv --num_panels 10000
"""

import argparse
import os
import sys
from pathlib import Path
from glob import glob

import numpy as np
import pandas as pd


# ──────────────────────────────────────────────────────────
# 1. 실제 StepLog CSV 파싱 → (Band, Gray)별 수렴 Gamma 통계 추출
# ──────────────────────────────────────────────────────────

def parse_steplog_files(steplog_dir: str) -> pd.DataFrame:
    """StepLog CSV 파일들에서 DGMA_SEARCH 수렴 데이터를 추출합니다."""
    csv_files = glob(os.path.join(steplog_dir, "**", "*StepLog*.csv"), recursive=True)
    if not csv_files:
        print(f"[WARN] StepLog CSV 파일을 찾을 수 없습니다: {steplog_dir}")
        return pd.DataFrame()

    print(f"[INFO] StepLog CSV {len(csv_files)}개 발견")

    all_rows = []
    for fpath in csv_files:
        try:
            df = pd.read_csv(fpath, encoding='utf-8', on_bad_lines='skip')
            # 열 이름 정리 (마지막 빈 열 제거)
            df.columns = [c.strip() for c in df.columns]
            if '' in df.columns:
                df = df.drop(columns=[''])

            # DGMA_SEARCH만 필터
            dgma = df[df['SEQUENCE'] == 'DGMA_SEARCH'].copy()
            if dgma.empty:
                continue

            # (BAND, REAL_GRAY) 그룹별 마지막 iteration (최대 LOOP) = 수렴 결과
            for (band, gray), grp in dgma.groupby(['BAND', 'REAL_GRAY']):
                max_loop_idx = grp['LOOP'].astype(int).idxmax()
                converged = grp.loc[max_loop_idx]

                # LOOP=0 행 = InitLUT 초기값
                loop0 = grp[grp['LOOP'].astype(int) == 0]
                if not loop0.empty:
                    init_r = float(loop0.iloc[0]['GAMMA_R'])
                    init_g = float(loop0.iloc[0]['GAMMA_G'])
                    init_b = float(loop0.iloc[0]['GAMMA_B'])
                else:
                    init_r = float(converged['GAMMA_R'])
                    init_g = float(converged['GAMMA_G'])
                    init_b = float(converged['GAMMA_B'])

                all_rows.append({
                    'Band': int(band),
                    'Gray': int(gray),
                    'Gamma_R': float(converged['GAMMA_R']),
                    'Gamma_G': float(converged['GAMMA_G']),
                    'Gamma_B': float(converged['GAMMA_B']),
                    'Measured_X': float(converged['Measured_X']),
                    'Measured_Y': float(converged['Measured_Y']),
                    'Measured_LV': float(converged['Measured_LV']),
                    'V_R': float(converged['V_R']),
                    'V_G': float(converged['V_G']),
                    'V_B': float(converged['V_B']),
                    'VSSEL': float(converged['VSSEL']),
                    'VAR_AR': float(converged['VAR_AR']),
                    'VAR_AGB': float(converged['VAR_AGB']),
                    'InitLUT_R': init_r,
                    'InitLUT_G': init_g,
                    'InitLUT_B': init_b,
                    'Loop_Count': int(converged['LOOP']),
                    'source_file': os.path.basename(fpath),
                })
        except Exception as e:
            print(f"[WARN] 파싱 실패: {fpath} - {e}")
            continue

    if not all_rows:
        return pd.DataFrame()

    result = pd.DataFrame(all_rows)
    print(f"[INFO] 추출된 수렴 데이터: {len(result)}개 (파일 {len(csv_files)}개)")
    return result


def compute_band_gray_stats(real_data: pd.DataFrame) -> dict:
    """(Band, Gray)별 Gamma R/G/B의 평균, 표준편차, VSSEL/VAR 범위 등 통계를 계산합니다."""
    stats = {}
    for (band, gray), grp in real_data.groupby(['Band', 'Gray']):
        stats[(band, gray)] = {
            'gamma_r_mean': grp['Gamma_R'].mean(),
            'gamma_r_std': max(grp['Gamma_R'].std(), 5.0),  # 최소 std = 5 DAC
            'gamma_g_mean': grp['Gamma_G'].mean(),
            'gamma_g_std': max(grp['Gamma_G'].std(), 5.0),
            'gamma_b_mean': grp['Gamma_B'].mean(),
            'gamma_b_std': max(grp['Gamma_B'].std(), 5.0),
            'vssel_mean': grp['VSSEL'].mean(),
            'vssel_std': max(grp['VSSEL'].std(), 0.1),
            'var_ar_mean': grp['VAR_AR'].mean(),
            'var_ar_std': max(grp['VAR_AR'].std(), 0.01),
            'var_agb_mean': grp['VAR_AGB'].mean(),
            'var_agb_std': max(grp['VAR_AGB'].std(), 0.01),
            'measured_x_mean': grp['Measured_X'].mean(),
            'measured_y_mean': grp['Measured_Y'].mean(),
            'measured_lv_mean': grp['Measured_LV'].mean(),
            'count': len(grp),
        }
    return stats


# ──────────────────────────────────────────────────────────
# 2. DGMA_Parameter.csv 파싱 (Target/Tolerance)
# ──────────────────────────────────────────────────────────

def parse_dgma_parameter(param_csv: str) -> pd.DataFrame:
    """DGMA_Parameter.csv에서 활성(OCExec=1) 탭의 Target/Tolerance를 추출합니다."""
    lines = open(param_csv, 'r', encoding='utf-8').readlines()
    # 헤더 2행 건너뛰기, 이후 Band당 22행 (행0=P-GMA상단, 행1~20=D-GMA, 행21=P-GMA하단)
    data_lines = lines[2:]  # 행2부터 데이터

    tabs = []
    for i, line in enumerate(data_lines):
        parts = line.strip().split(',')
        if len(parts) < 12:
            continue

        band_row = i % 22  # 0~21
        band_idx = i // 22  # Band index

        # 행0, 행21은 P-GMA → 건너뛰기
        if band_row == 0 or band_row == 21:
            continue

        try:
            oc_exec = int(float(parts[11]))
        except (ValueError, IndexError):
            continue

        if oc_exec != 1:
            continue

        try:
            tabs.append({
                'Band': int(float(parts[0])),
                'Gray': int(float(parts[1])),
                'Init_Gamma_R': int(float(parts[2])),
                'Init_Gamma_G': int(float(parts[3])),
                'Init_Gamma_B': int(float(parts[4])),
                'Target_x': float(parts[5]),
                'Target_y': float(parts[6]),
                'Target_Lv': float(parts[7]),
                'Tolerance_dx': float(parts[8]),
                'Tolerance_dy': float(parts[9]),
                'Tolerance_dLv': float(parts[10]),
            })
        except (ValueError, IndexError):
            continue

    result = pd.DataFrame(tabs)
    print(f"[INFO] DGMA_Parameter.csv: 활성 탭 {len(result)}개 / 전체 {len(data_lines)} 행")
    return result


# ──────────────────────────────────────────────────────────
# 3. 가상 데이터 생성
# ──────────────────────────────────────────────────────────

def generate_from_real_stats(
    param_df: pd.DataFrame,
    real_data: pd.DataFrame,
    num_panels: int,
    noise_level: float = 1.0,
) -> pd.DataFrame:
    """실제 StepLog 수렴 데이터를 리샘플링 + 노이즈로 가상 데이터를 생성합니다.

    핵심: 실제 (ELVSS, VAR, InitLUT, Gamma) 행을 랜덤 선택 후
    소량 노이즈를 추가하여 실제 분포와 상관관계를 그대로 보존합니다.
    """
    rng = np.random.default_rng(42)

    # (Band, Gray)별 실제 데이터 그룹핑
    grouped = {}
    for (band, gray), grp in real_data.groupby(['Band', 'Gray']):
        grouped[(band, gray)] = grp.reset_index(drop=True)

    all_chunks = []
    for _, tab in param_df.iterrows():
        band, gray = int(tab['Band']), int(tab['Gray'])
        key = (band, gray)

        # DGMA_Parameter의 Band는 1-based, StepLog는 0-based → -1 보정
        key_0based = (band - 1, gray)

        if key_0based in grouped:
            src = grouped[key_0based]
        elif key in grouped:
            src = grouped[key]
        else:
            # 실제 데이터 없는 (Band,Gray) → 같은 Gray의 가장 가까운 Band에서 차용
            found = False
            for delta in range(1, 10):
                for try_band in [band - 1 + delta, band - 1 - delta]:
                    if (try_band, gray) in grouped:
                        src = grouped[(try_band, gray)]
                        found = True
                        break
                if found:
                    break
            if not found:
                continue  # 매칭 불가 → 건너뛰기

        n_src = len(src)
        n = num_panels

        # 실제 데이터에서 랜덤 리샘플링 (복원 추출)
        indices = rng.choice(n_src, size=n, replace=True)

        # 실제 값 + 소량 노이즈 (실제 분포 보존)
        gamma_r_src = src['Gamma_R'].values[indices].astype(np.float64)
        gamma_g_src = src['Gamma_G'].values[indices].astype(np.float64)
        gamma_b_src = src['Gamma_B'].values[indices].astype(np.float64)
        elvss_src = src['VSSEL'].values[indices].astype(np.float64)
        var_ar_src = src['VAR_AR'].values[indices].astype(np.float64)
        var_agb_src = src['VAR_AGB'].values[indices].astype(np.float64)
        init_r_src = src['InitLUT_R'].values[indices].astype(np.float64)
        init_g_src = src['InitLUT_G'].values[indices].astype(np.float64)
        init_b_src = src['InitLUT_B'].values[indices].astype(np.float64)

        # 노이즈 추가 (noise_level 배율)
        # Gamma: ±20 DAC 노이즈 (실제 패널 간 편차 수준)
        gr = np.clip(gamma_r_src + rng.normal(0, 20 * noise_level, n), 0, 32767).astype(np.int32)
        gg = np.clip(gamma_g_src + rng.normal(0, 20 * noise_level, n), 0, 32767).astype(np.int32)
        gb = np.clip(gamma_b_src + rng.normal(0, 20 * noise_level, n), 0, 32767).astype(np.int32)

        # ELVSS/VAR: ±소량 노이즈
        v = (elvss_src + rng.normal(0, 0.1 * noise_level, n)).astype(np.float32)
        ar = (var_ar_src + rng.normal(0, 0.02 * noise_level, n)).astype(np.float32)
        ag = (var_agb_src + rng.normal(0, 0.02 * noise_level, n)).astype(np.float32)

        # ELVSS 변동 → Gamma 연동 보정 (실제 상관관계 반영)
        # 실제 데이터에서 ELVSS-Gamma 상관계수 추정
        if n_src >= 5 and src['VSSEL'].std() > 0.01:
            corr_r = np.corrcoef(src['VSSEL'].values, src['Gamma_R'].values)[0, 1]
            corr_g = np.corrcoef(src['VSSEL'].values, src['Gamma_G'].values)[0, 1]
            corr_b = np.corrcoef(src['VSSEL'].values, src['Gamma_B'].values)[0, 1]
            sensitivity = 5.0  # ELVSS 1V → Gamma ~5 DAC (추정)
            elvss_delta = v - elvss_src.astype(np.float32)
            if not np.isnan(corr_r):
                gr = np.clip(gr + (elvss_delta * sensitivity * corr_r).astype(np.int32), 0, 32767)
            if not np.isnan(corr_g):
                gg = np.clip(gg + (elvss_delta * sensitivity * corr_g).astype(np.int32), 0, 32767)
            if not np.isnan(corr_b):
                gb = np.clip(gb + (elvss_delta * sensitivity * corr_b).astype(np.int32), 0, 32767)

        # InitLUT: 실제 InitLUT + 소량 노이즈 (이전 패널과의 차이 시뮬레이션)
        ir = np.clip(init_r_src + rng.normal(0, 15 * noise_level, n), 0, 32767).astype(np.int32)
        ig = np.clip(init_g_src + rng.normal(0, 15 * noise_level, n), 0, 32767).astype(np.int32)
        ib = np.clip(init_b_src + rng.normal(0, 15 * noise_level, n), 0, 32767).astype(np.int32)

        chunk = pd.DataFrame({
            'Band': np.full(n, band, dtype=np.int32),
            'Gray': np.full(n, gray, dtype=np.int32),
            'Target_x': np.full(n, tab['Target_x'], dtype=np.float32),
            'Target_y': np.full(n, tab['Target_y'], dtype=np.float32),
            'Target_Lv': np.full(n, tab['Target_Lv'], dtype=np.float32),
            'ELVSS': v,
            'VAR_A_R': ar,
            'VAR_A_GB': ag,
            'InitLUT_R': ir,
            'InitLUT_G': ig,
            'InitLUT_B': ib,
            'Gamma_R': gr,
            'Gamma_G': gg,
            'Gamma_B': gb,
        })
        all_chunks.append(chunk)

    if not all_chunks:
        return pd.DataFrame()
    return pd.concat(all_chunks, ignore_index=True)


def generate_from_physics(
    param_df: pd.DataFrame,
    num_panels: int,
    noise_level: float = 1.0,
) -> pd.DataFrame:
    """StepLog 없을 때 물리 모델로만 가상 데이터를 생성합니다 (numpy 벡터화)."""
    rng = np.random.default_rng(42)
    n_tabs = len(param_df)
    total = n_tabs * num_panels

    bands = np.empty(total, dtype=np.int32)
    grays = np.empty(total, dtype=np.int32)
    target_x = np.empty(total, dtype=np.float32)
    target_y = np.empty(total, dtype=np.float32)
    target_lv = np.empty(total, dtype=np.float32)
    elvss = np.empty(total, dtype=np.float32)
    out_var_ar = np.empty(total, dtype=np.float32)
    out_var_agb = np.empty(total, dtype=np.float32)
    out_init_r = np.empty(total, dtype=np.int32)
    out_init_g = np.empty(total, dtype=np.int32)
    out_init_b = np.empty(total, dtype=np.int32)
    out_gamma_r = np.empty(total, dtype=np.int32)
    out_gamma_g = np.empty(total, dtype=np.int32)
    out_gamma_b = np.empty(total, dtype=np.int32)

    idx = 0
    for _, tab in param_df.iterrows():
        band, gray = int(tab['Band']), int(tab['Gray'])
        tgt_lv = tab['Target_Lv']
        n = num_panels
        sl = slice(idx, idx + n)

        gamma_exp = rng.uniform(2.0, 2.4, n)
        v = rng.uniform(-9.5, -4.5, n).astype(np.float32)
        ar = rng.normal(1.1, 0.05 * noise_level, n).astype(np.float32)
        ag = rng.normal(2.2, 0.05 * noise_level, n).astype(np.float32)

        lv_max, v_max = 2900.0, 5.0
        if tgt_lv > 0:
            v_ratio = (tgt_lv / lv_max) ** (1.0 / gamma_exp)
            v_required = v_max * v_ratio
        else:
            v_required = np.full(n, 0.1)

        base_dac = (5.8 - v_required) / 5.0 * 32767.0

        gr = (base_dac + rng.normal(0, 30 * noise_level, n) + v * 2.0)
        gg = (base_dac + rng.normal(0, 30 * noise_level, n) + v * 2.0)
        gb = (base_dac + rng.normal(0, 30 * noise_level, n) + v * 2.0 + rng.normal(0, 20, n))

        gr = np.clip(gr, 0, 32767).astype(np.int32)
        gg = np.clip(gg, 0, 32767).astype(np.int32)
        gb = np.clip(gb, 0, 32767).astype(np.int32)

        ir = np.clip(gr + rng.normal(0, 5, n), 0, 32767).astype(np.int32)
        ig = np.clip(gg + rng.normal(0, 5, n), 0, 32767).astype(np.int32)
        ib = np.clip(gb + rng.normal(0, 5, n), 0, 32767).astype(np.int32)

        bands[sl] = band; grays[sl] = gray
        target_x[sl] = tab['Target_x']; target_y[sl] = tab['Target_y']; target_lv[sl] = tgt_lv
        elvss[sl] = v; out_var_ar[sl] = ar; out_var_agb[sl] = ag
        out_init_r[sl] = ir; out_init_g[sl] = ig; out_init_b[sl] = ib
        out_gamma_r[sl] = gr; out_gamma_g[sl] = gg; out_gamma_b[sl] = gb
        idx += n

    return pd.DataFrame({
        'Band': bands, 'Gray': grays,
        'Target_x': target_x, 'Target_y': target_y, 'Target_Lv': target_lv,
        'ELVSS': elvss, 'VAR_A_R': out_var_ar, 'VAR_A_GB': out_var_agb,
        'InitLUT_R': out_init_r, 'InitLUT_G': out_init_g, 'InitLUT_B': out_init_b,
        'Gamma_R': out_gamma_r, 'Gamma_G': out_gamma_g, 'Gamma_B': out_gamma_b,
    })


# ──────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='MLP 학습용 합성 데이터 생성기')
    parser.add_argument('--steplog_dir', type=str, default=None,
                        help='실제 StepLog CSV 디렉토리 (있으면 실제 분포 기반 생성)')
    parser.add_argument('--param_csv', type=str,
                        default='../../IT_OLED_OC_X3584_CSharp/LGDDLL/Setting/Parameters/X3584/DGMA_Parameter.csv',
                        help='DGMA_Parameter.csv 경로')
    parser.add_argument('--num_panels', type=int, default=10000,
                        help='생성할 가상 패널 수')
    parser.add_argument('--noise_level', type=float, default=1.0,
                        help='노이즈 배율 (1.0=실제 수준, 0.5=절반)')
    parser.add_argument('--output', type=str, default='synthetic_dataset.parquet',
                        help='출력 Parquet 파일')
    args = parser.parse_args()

    # 1. DGMA_Parameter.csv 로딩
    if not os.path.exists(args.param_csv):
        print(f"[ERROR] DGMA_Parameter.csv 파일을 찾을 수 없습니다: {args.param_csv}")
        sys.exit(1)

    param_df = parse_dgma_parameter(args.param_csv)
    if param_df.empty:
        print("[ERROR] 활성 탭 포인트가 없습니다.")
        sys.exit(1)

    # 2. StepLog 기반 or 물리 모델 기반 생성
    if args.steplog_dir and os.path.isdir(args.steplog_dir):
        print(f"\n[MODE] 실제 StepLog 분포 기반 생성")
        real_data = parse_steplog_files(args.steplog_dir)

        if not real_data.empty:
            print(f"[INFO] 실제 수렴 데이터 {len(real_data)}개 → 리샘플링 + 노이즈로 가상 데이터 생성")
            dataset = generate_from_real_stats(param_df, real_data, args.num_panels, args.noise_level)
        else:
            print("[WARN] StepLog 데이터 추출 실패 → 물리 모델 폴백")
            dataset = generate_from_physics(param_df, args.num_panels, args.noise_level)
    else:
        print(f"\n[MODE] 물리 모델 기반 생성 (StepLog 없음)")
        dataset = generate_from_physics(param_df, args.num_panels, args.noise_level)

    # 3. 저장 (parquet 또는 CSV)
    try:
        dataset.to_parquet(args.output, index=False)
        print(f"\n[OUTPUT] {args.output} ({len(dataset):,}개 샘플)")
    except Exception:
        csv_out = args.output.replace('.parquet', '.csv')
        dataset.to_csv(csv_out, index=False)
        print(f"\n[OUTPUT] {csv_out} ({len(dataset):,}개 샘플) (parquet 미지원 → CSV)")
        args.output = csv_out

    # CSV 샘플 (처음 200행)
    csv_sample = args.output.replace('.parquet', '').replace('.csv', '') + '_sample.csv'
    dataset.head(200).to_csv(csv_sample, index=False)
    print(f"[OUTPUT] {csv_sample} (샘플 200행)")

    # 통계 출력
    print(f"\n{'='*60}")
    print(f"데이터셋 통계:")
    print(f"  총 샘플 수: {len(dataset):,}")
    print(f"  활성 (Band, Gray) 수: {len(param_df)}")
    print(f"  가상 패널 수: {args.num_panels:,}")
    print(f"  노이즈 배율: {args.noise_level}")
    print(f"\n  Gamma_R 범위: {dataset['Gamma_R'].min():.0f} ~ {dataset['Gamma_R'].max():.0f}")
    print(f"  Gamma_G 범위: {dataset['Gamma_G'].min():.0f} ~ {dataset['Gamma_G'].max():.0f}")
    print(f"  Gamma_B 범위: {dataset['Gamma_B'].min():.0f} ~ {dataset['Gamma_B'].max():.0f}")
    print(f"  ELVSS 범위: {dataset['ELVSS'].min():.2f} ~ {dataset['ELVSS'].max():.2f}")
    print(f"  Target_Lv 범위: {dataset['Target_Lv'].min():.2f} ~ {dataset['Target_Lv'].max():.2f}")

    # Band별 분포
    band_counts = dataset.groupby('Band').size()
    print(f"\n  Band별 샘플 수 (상위 10):")
    for band, cnt in band_counts.nlargest(10).items():
        print(f"    Band {band}: {cnt:,}")


if __name__ == '__main__':
    main()
