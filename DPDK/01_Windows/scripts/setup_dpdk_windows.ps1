<#
.SYNOPSIS
    Windows DPDK 환경 설정 및 빌드 자동화 스크립트
.DESCRIPTION
    1. Python 필수 패키지(Meson, Ninja) 설치 확인 및 설치
    2. DPDK 소스 코드 Clone
    3. Meson을 이용한 빌드 구성 (Clang 사용)
    4. Ninja를 이용한 컴파일
.NOTES
    실행 전 Clang과 Python이 설치되어 있어야 합니다.
#>

$DPDK_REPO = "http://dpdk.org/git/dpdk"
$SRC_DIR = "dpdk-src"
$BUILD_DIR = "build"

Write-Host ">>> [1/4] 필수 도구 확인 중..." -ForegroundColor Cyan

# Check Python
if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Error "Python이 설치되어 있지 않습니다. Python 3.x를 먼저 설치해주세요."
    exit 1
}

# Check Clang
if (-not (Get-Command "clang" -ErrorAction SilentlyContinue)) {
    Write-Error "Clang이 감지되지 않았습니다. DPDK 빌드를 위해 Clang/LLVM 설치가 필요합니다."
    Write-Host "    -> https://github.com/llvm/llvm-project/releases 에서 'LLVM-xx.x.x-win64.exe'를 다운로드하여 설치해주세요."
    Write-Host "    (설치 시 'Add LLVM to the system PATH' 옵션을 반드시 선택해야 합니다.)"
    exit 1
}

Write-Host ">>> [2/4] Python 패키지(Meson, Ninja) 설치..." -ForegroundColor Cyan
try {
    pip install meson ninja pyelftools
}
catch {
    Write-Error "Python 패키지 설치 실패. 관리자 권한으로 실행하거나 네트워크를 확인하세요."
    exit 1
}

Write-Host ">>> [3/4] DPDK 소스 코드 다운로드 (Git Clone)..." -ForegroundColor Cyan
if (-not (Test-Path $SRC_DIR)) {
    git clone $DPDK_REPO $SRC_DIR
} else {
    Write-Host "    -> 이미 폴더가 존재합니다. Clone을 건너뜁니다."
}

Set-Location $SRC_DIR

Write-Host ">>> [4/4] DPDK 빌드 시작 (Meson + Ninja)..." -ForegroundColor Cyan
Write-Host "    -> 빌드 폴더(build) 상태 점검..." -ForegroundColor Yellow

if (Test-Path $BUILD_DIR) {
    Write-Host "    -> 기존 빌드 폴더가 발견되었습니다. 환경 일치 여부를 점검합니다..." -ForegroundColor Yellow

    # 이전 PC의 Python 경로 등이 남아있어 빌드가 깨지는 경우가 많으므로,
    # 안전을 위해 새 PC 환경에서는 재설정을 권장하거나 자동 처리합니다.
    try {
        Write-Host "    -> 환경 동기화를 위해 기존 빌드 설정을 초기화하고 새로 구성합니다." -ForegroundColor Cyan
        Remove-Item -Path $BUILD_DIR -Recurse -Force
    } catch {
        Write-Error "    -> 기존 'build' 폴더 삭제 실패. 다른 프로그램이 사용 중인지 확인하세요."
        Set-Location ..
        exit 1
    }
}

# Meson 설정 및 빌드 실행
try {
    Write-Host "    -> Meson 설정 중..." -ForegroundColor Yellow

    # Clang을 컴파일러로 강제 지정 (Windows 환경 표준)
    $env:CC = "clang"
    $env:CXX = "clang"

    # 1. Meson Setup
    meson setup $BUILD_DIR --default-library=shared

    # 2. Ninja Build
    Write-Host "    -> 컴파일 시작 (시간이 소요될 수 있습니다)..." -ForegroundColor Yellow
    ninja -C $BUILD_DIR

    Write-Host ">>> DPDK 빌드 성공!" -ForegroundColor Green
} catch {
    Write-Error ">>> 빌드 중 오류가 발생했습니다. 'dpdk-src\build' 폴더를 수동으로 삭제하고 다시 시도해 보세요."
    Set-Location ..
    exit 1
}

Set-Location ..
Write-Host "`n설정 완료. 'Windows_DPDK_Manual.md'를 참고하여 Hugepage 설정 후 실행하세요." -ForegroundColor Yellow
