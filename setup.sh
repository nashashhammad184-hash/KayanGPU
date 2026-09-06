#!/usr/bin/env bash
set -uo pipefail

echo "=== KayanGPU Setup ==="

echo "--- OS Check ---"
uname -a
DISTRO=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
echo "Distro: ${DISTRO:-unknown}"

echo ""
echo "--- GPU Check ---"
DETECTED_GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
DETECTED_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -n1)
DRIVER_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1)
CUDA_VER=$(nvcc --version 2>/dev/null | grep release)

echo "Detected GPU: ${DETECTED_GPU:-none}"
echo "Detected VRAM: ${DETECTED_VRAM:-none}"
echo "Driver: ${DRIVER_VER:-not found}"
echo "CUDA (nvcc): ${CUDA_VER:-not found}"

EXPECTED_GPU="RTX 5090"

if [ -z "$DETECTED_GPU" ]; then
  echo ""
  echo "DETECTED_GPU=none"
  echo "DETECTED_VRAM=none"
  echo "EXPECTED_GPU=${EXPECTED_GPU}"
  echo "STATUS=FAIL"
  echo "[STOP] لا يوجد GPU على هذا الجهاز. setup.sh يعمل فقط على خادم RTX 5090 فعلي."
  exit 1
fi

if ! echo "$DETECTED_GPU" | grep -qi "5090"; then
  echo ""
  echo "DETECTED_GPU=${DETECTED_GPU}"
  echo "DETECTED_VRAM=${DETECTED_VRAM}"
  echo "EXPECTED_GPU=${EXPECTED_GPU}"
  echo "STATUS=FAIL"
  echo "[STOP] الكرت الحالي ليس RTX 5090. تم إيقاف setup.sh."
  exit 1
fi

VRAM_NUM=$(echo "$DETECTED_VRAM" | grep -oE '[0-9]+' | head -n1)
if [ -n "$VRAM_NUM" ] && [ "$VRAM_NUM" -lt 28000 ]; then
  echo ""
  echo "DETECTED_GPU=${DETECTED_GPU}"
  echo "DETECTED_VRAM=${DETECTED_VRAM}"
  echo "EXPECTED_GPU=${EXPECTED_GPU} (~32GB VRAM)"
  echo "STATUS=FAIL"
  echo "[STOP] VRAM أقل من المتوقع لـ RTX 5090."
  exit 1
fi

echo "[OK] GPU مطابق: RTX 5090 - VRAM: ${DETECTED_VRAM}"

echo ""
echo "--- Python venv ---"
cd "$(dirname "$0")"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip

echo ""
echo "--- Installing base requirements (lightweight) ---"
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
else
  echo "[WARN] requirements.txt غير موجود"
fi

echo ""
echo "--- Installing GPU requirements (PyTorch) dynamically matched to detected CUDA ---"
if [ -f requirements-gpu.txt ]; then
  CUDA_MAJOR_MINOR=$(nvidia-smi 2>/dev/null | grep -oE 'CUDA Version: [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' | head -n1)
  if [ -z "$CUDA_MAJOR_MINOR" ] && [ -n "$CUDA_VER" ]; then
    CUDA_MAJOR_MINOR=$(echo "$CUDA_VER" | grep -oE '[0-9]+\.[0-9]+' | head -n1)
  fi

  if [ -n "$CUDA_MAJOR_MINOR" ]; then
    CUDA_TAG="cu$(echo "$CUDA_MAJOR_MINOR" | tr -d '.')"
    echo "CUDA detected: ${CUDA_MAJOR_MINOR} -> trying index: https://download.pytorch.org/whl/${CUDA_TAG}"
    if pip install -r requirements-gpu.txt --index-url "https://download.pytorch.org/whl/${CUDA_TAG}"; then
      echo "[OK] PyTorch installed matching CUDA ${CUDA_MAJOR_MINOR}"
    else
      echo "[WARN] فشل التثبيت من index الخاص بـ ${CUDA_TAG}. جرّب يدوياً مطابقة الإصدار من: https://pytorch.org/get-started/locally/"
      echo "STATUS=FAIL"
      exit 1
    fi
  else
    echo "[WARN] تعذّر اكتشاف إصدار CUDA بدقة. راجع يدوياً قبل تثبيت requirements-gpu.txt"
    echo "STATUS=FAIL"
    exit 1
  fi
else
  echo "[WARN] requirements-gpu.txt غير موجود"
fi

echo ""
echo "--- FFmpeg Check ---"
FFMPEG_CHECK=$(ffmpeg -version 2>/dev/null | head -n1)
if [ -z "$FFMPEG_CHECK" ]; then
  echo "[WARN] FFmpeg غير مثبت — نفّذ: sudo apt install ffmpeg -y"
else
  echo "[OK] $FFMPEG_CHECK"
fi

echo ""
echo "--- Preparing directories ---"
mkdir -p worker/models worker/outputs worker/logs configs workflows scripts systemd docs
echo "[OK] Directories ready"

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
  echo "[OK] تم إنشاء .env من .env.example — عبّه بالقيم الحقيقية يدوياً"
fi

echo ""
echo "[DONE] Setup اكتمل. لم يتم تثبيت أي نموذج ضخم تلقائياً."
echo "STATUS=PASS"
