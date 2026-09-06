#!/usr/bin/env bash
echo "=== GPU Preflight Check ==="
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
if [ -z "$GPU_NAME" ]; then
  echo "[FAIL] لم يتم اكتشاف أي GPU (nvidia-smi غير متاح)"
else
  echo "[OK] GPU detected: $GPU_NAME"
  if echo "$GPU_NAME" | grep -qi "5090"; then
    echo "[OK] هذا كرت RTX 5090 - مطابق للهدف"
  else
    echo "[INFO] الكرت الحالي ليس RTX 5090 (تسجيل فقط، وليس فشلاً)"
  fi
fi
VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null)
echo "VRAM: ${VRAM:-N/A}"
DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)
echo "Driver: ${DRIVER:-not found}"
CUDA_VER=$(nvcc --version 2>/dev/null | grep release)
echo "CUDA (nvcc): ${CUDA_VER:-not found}"
TORCH_CHECK=$(python3 -c "import torch; print('PyTorch', torch.__version__, '| CUDA available:', torch.cuda.is_available())" 2>/dev/null)
echo "PyTorch: ${TORCH_CHECK:-torch not installed}"
FFMPEG_CHECK=$(ffmpeg -version 2>/dev/null | head -n1)
echo "FFmpeg: ${FFMPEG_CHECK:-ffmpeg not found}"
echo "=== End Preflight Check ==="
