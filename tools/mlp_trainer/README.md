# MLP Gamma 예측 모델 학습 도구

OC(Optical Compensation) 프로세스의 Gamma DAC 값을 예측하는 MLP 모델을 학습하고 ONNX로 내보내는 도구입니다.

## 환경 설정

```bash
# Python 3.10+ 권장
cd tools/mlp_trainer

# 가상환경 생성 (선택)
python -m venv .venv
.venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt
```

> PyTorch GPU 버전이 필요하면 https://pytorch.org/get-started/locally/ 에서 CUDA 버전에 맞는 설치 명령을 확인하세요.

## 1단계: 학습 데이터 준비

### 방법 A: 가상 데이터 생성 (StepLog가 없을 때)

DGMA_Parameter.csv의 실제 Band/Gray/Target 값을 기반으로 패널 OC 프로세스를 시뮬레이션합니다.

```bash
# 기본 설정 (10,000 패널)
python generate_synthetic_data.py

# 패널 수 변경
python generate_synthetic_data.py --num_panels 50000

# 커스텀 DGMA 파라미터 경로
python generate_synthetic_data.py \
    --param_csv "../../IT_OLED_OC_X3584_CSharp/LGDDLL/Setting/Parameters/X3584/DGMA_Parameter.csv" \
    --output my_dataset.parquet
```

출력 파일:
- `synthetic_dataset.parquet` - 전체 데이터셋
- `synthetic_dataset.sample.csv` - 처음 100행 (검수용)

### 방법 B: 실제 StepLog CSV 파싱

생산 라인에서 생성된 StepLog CSV 파일을 파싱하여 수렴된 최종 루프 데이터를 추출합니다.

```bash
# StepLog 디렉토리 지정
python parse_steplog.py --input_dir "D:/OC_StepLogs/"

# DGMA 파라미터 경로 지정 (Target 값 조인용)
python parse_steplog.py \
    --input_dir "D:/OC_StepLogs/" \
    --param_csv "path/to/DGMA_Parameter.csv" \
    --output steplog_dataset.parquet
```

StepLog CSV 필수 컬럼:
`BAND, REAL_GRAY, LOOP, GAMMA_R, GAMMA_G, GAMMA_B, VSSEL, VAR_AR, VAR_AGB`

## 2단계: 모델 학습

```bash
# 기본 설정으로 학습
python train_mlp.py --input synthetic_dataset.parquet

# 하이퍼파라미터 조정
python train_mlp.py \
    --input synthetic_dataset.parquet \
    --epochs 300 \
    --batch_size 512 \
    --lr 0.0005 \
    --patience 20 \
    --output my_model.onnx

# GPU 사용
python train_mlp.py --input synthetic_dataset.parquet --device cuda
```

출력 파일:
- `gamma_predictor.onnx` - ONNX 모델
- `gamma_predictor.history.csv` - 학습 이력 (loss 곡선)

### 모델 아키텍처

```
입력 (11) → Linear(256) → BN → ReLU → Dropout(0.1)
         → Linear(128) → BN → ReLU → Dropout(0.1)
         → Linear(64)  → BN → ReLU
         → Linear(3)   → 출력 (Gamma_R, G, B)
```

입력 특성 (11개):
| # | 특성 | 정규화 |
|---|------|--------|
| 0 | Band | (x-42)/42 |
| 1 | Gray | (x-256)/256 |
| 2 | Target_x | (x-0.31)/0.04 |
| 3 | Target_y | (x-0.32)/0.03 |
| 4 | Target_Lv | log10(x+1)/3.5 |
| 5 | ELVSS | (x-1.9)/1.1 |
| 6 | VAR_A_R | x/0.1 |
| 7 | VAR_A_GB | x/0.1 |
| 8 | InitLUT_R | x/32767 |
| 9 | InitLUT_G | x/32767 |
| 10 | InitLUT_B | x/32767 |

## 3단계: 모델 검증

```bash
# 검증 실행
python validate_model.py \
    --model gamma_predictor.onnx \
    --input synthetic_dataset.parquet

# 결과 디렉토리 지정
python validate_model.py \
    --model gamma_predictor.onnx \
    --input steplog_dataset.parquet \
    --output_dir ./results/
```

생성되는 차트:
- `scatter_predicted_vs_actual.png` - 예측 vs 실제 산점도 (R/G/B)
- `error_histogram.png` - 오차 분포 히스토그램
- `per_band_mae.png` - Band별 MAE 막대 그래프
- `training_history.png` - 학습 손실 곡선
- `validation_results.csv` - 상세 결과 CSV

## 4단계: ONNX 모델을 DLL에 배치

학습된 `gamma_predictor.onnx` 파일을 C# 프로젝트에서 사용하려면:

### 파일 배치

```
IT_OLED_OC_X3584_CSharp/
  LGDDLL/
    Setting/
      Parameters/
        X3584/
          gamma_predictor.onnx    ← 여기에 복사
```

### C# 코드에서 사용

`GammaPredictor.cs`의 `LoadModel()` 메서드가 위 경로에서 ONNX 파일을 자동 로드합니다.
정규화 로직(`BuildInput`)이 Python 학습 시와 동일하게 구현되어 있어야 합니다.

```csharp
// GammaPredictor.BuildInput() - Python normalize_inputs()와 동일
float[] input = new float[11] {
    (band - 42f) / 42f,
    (gray - 256f) / 256f,
    (target_x - 0.31f) / 0.04f,
    (target_y - 0.32f) / 0.03f,
    MathF.Log10(target_lv + 1f) / 3.5f,
    (elvss - 1.9f) / 1.1f,
    var_a_r / 0.1f,
    var_a_gb / 0.1f,
    initLut_r / 32767f,
    initLut_g / 32767f,
    initLut_b / 32767f,
};
```

### NuGet 패키지

C# 프로젝트에 필요한 패키지:
```xml
<PackageReference Include="Microsoft.ML.OnnxRuntime" Version="1.17.0" />
```

## 주의사항

- 가상 데이터로 학습한 모델은 실제 생산 데이터와 차이가 있을 수 있습니다. 실제 StepLog 데이터가 확보되면 재학습하세요.
- Python과 C# 간 정규화 로직이 정확히 일치해야 합니다. 정규화 파라미터 변경 시 양쪽 모두 업데이트하세요.
- ONNX opset version 17을 사용합니다. OnnxRuntime 1.17+ 필요.
