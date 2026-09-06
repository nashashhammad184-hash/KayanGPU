#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"

echo "=== KayanGPU Restore ==="
echo "الغرض: إعادة بناء KayanGPU بعد نقل هذا المجلد لخادم RTX 5090 جديد"

echo ""
echo "--- 1) GPU Check ---"
DETECTED_GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
DETECTED_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -n1)

if [ -z "$DETECTED_GPU" ]; then
  echo "DETECTED_GPU=none"
  echo "EXPECTED_GPU=RTX 5090"
  echo "STATUS=FAIL"
  echo "[STOP] لا يوجد GPU على هذا الخادم."
  exit 1
fi

echo "GPU detected: $DETECTED_GPU"
echo "VRAM: $DETECTED_VRAM"

if ! echo "$DETECTED_GPU" | grep -qi "5090"; then
  echo "[WARN] الكرت الحالي ليس RTX 5090 — سيتابع restore.sh لكن راجع مع GPU المستهدف قبل الإنتاج"
fi

echo ""
echo "--- 2) إنشاء البيئة (venv) ---"
if [ ! -d venv ]; then
  python3 -m venv venv
  echo "[OK] venv created"
else
  echo "[OK] venv already exists"
fi
source venv/bin/activate
pip install --upgrade pip

echo ""
echo "--- 3) استعادة/تثبيت الاعتماديات الأساسية (خفيفة) ---"
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
  echo "[OK] base requirements installed"
else
  echo "[FAIL] requirements.txt غير موجود"
  exit 1
fi

echo ""
echo "--- 4) تثبيت PyTorch مطابق لـ CUDA المكتشف فعلياً ---"
if [ -f requirements-gpu.txt ]; then
  CUDA_VER=$(nvcc --version 2>/dev/null | grep release)
  CUDA_MAJOR_MINOR=$(nvidia-smi 2>/dev/null | grep -oE 'CUDA Version: [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+' | head -n1)
  if [ -z "$CUDA_MAJOR_MINOR" ] && [ -n "$CUDA_VER" ]; then
    CUDA_MAJOR_MINOR=$(echo "$CUDA_VER" | grep -oE '[0-9]+\.[0-9]+' | head -n1)
  fi

  if [ -n "$CUDA_MAJOR_MINOR" ]; then
    CUDA_TAG="cu$(echo "$CUDA_MAJOR_MINOR" | tr -d '.')"
    echo "CUDA detected: ${CUDA_MAJOR_MINOR} -> index: https://download.pytorch.org/whl/${CUDA_TAG}"
    if pip install -r requirements-gpu.txt --index-url "https://download.pytorch.org/whl/${CUDA_TAG}"; then
      echo "[OK] PyTorch installed"
    else
      echo "[FAIL] فشل تثبيت PyTorch المطابق لـ ${CUDA_TAG}. راجع يدوياً: https://pytorch.org/get-started/locally/"
      exit 1
    fi
  else
    echo "[FAIL] تعذّر اكتشاف إصدار CUDA. لا يمكن تثبيت PyTorch بأمان تلقائياً."
    exit 1
  fi
else
  echo "[WARN] requirements-gpu.txt غير موجود"
fi

echo ""
echo "--- 5) تجهيز المجلدات ---"
mkdir -p worker/models worker/outputs worker/logs configs workflows scripts systemd docs
echo "[OK] directories ready"

echo ""
echo "--- 6) ملف البيئة ---"
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "[OK] .env created from .env.example — عبّه بالقيم الحقيقية يدوياً"
  else
    echo "[FAIL] .env.example غير موجود"
    exit 1
  fi
else
  echo "[OK] .env موجود مسبقاً — لم يُستبدل"
fi

echo ""
echo "--- 7) فحص FFmpeg ---"
FFMPEG_CHECK=$(ffmpeg -version 2>/dev/null | head -n1)
if [ -z "$FFMPEG_CHECK" ]; then
  echo "[WARN] FFmpeg غير مثبت — نفّذ: sudo apt install ffmpeg -y"
else
  echo "[OK] $FFMPEG_CHECK"
fi

echo ""
echo "--- 8) فحص Worker ---"
if [ -d worker ] && [ -n "$(ls -A worker 2>/dev/null)" ]; then
  echo "[OK] worker files present"
else
  echo "[INFO] مجلد worker فارغ — انسخ كود server.py/listener.py قبل التشغيل الفعلي"
fi

echo ""
echo "[NOTE] لم يتم تنزيل أي أوزان نماذج ضخمة تلقائياً (راجع docs/MODELS.md لطريقة التثبيت اليدوي)"
echo "[DONE] Restore اكتمل"
echo "STATUS=PASS"
