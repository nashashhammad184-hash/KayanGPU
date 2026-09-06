#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"

echo "=== KayanGPU Verify ==="

echo ""
echo "--- Live Hardware / Software Check ---"
GPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -n1)
DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1)
CUDA=$(nvcc --version 2>/dev/null | grep release)
if [ -f venv/bin/activate ]; then
  PYTORCH=$(venv/bin/python3 -c "import torch; print('torch', torch.__version__, '| cuda_available:', torch.cuda.is_available())" 2>/dev/null)
else
  PYTORCH=$(python3 -c "import torch; print('torch', torch.__version__, '| cuda_available:', torch.cuda.is_available())" 2>/dev/null)
fi
FFMPEG=$(ffmpeg -version 2>/dev/null | head -n1)
PYVER=$(python3 --version 2>&1)

if [ -d worker ] && [ -n "$(ls -A worker 2>/dev/null)" ]; then
  WORKER="present"
else
  WORKER="empty (pending code)"
fi

echo "GPU=${GPU:-not detected}"
echo "VRAM=${VRAM:-N/A}"
echo "DRIVER=${DRIVER:-not found}"
echo "CUDA=${CUDA:-not found}"
echo "PYTORCH=${PYTORCH:-not installed}"
echo "FFMPEG=${FFMPEG:-not found}"
echo "PYTHON=${PYVER}"
echo "WORKER=${WORKER}"

echo ""
echo "--- Package Structure Audit ---"

STATUS_OK=1

for f in setup.sh update.sh verify.sh restore.sh requirements.txt .env.example .gitignore README.md BACKUP_MANIFEST.md; do
  if [ -f "$f" ]; then
    echo "[OK] $f"
  else
    echo "[MISSING] $f"
    STATUS_OK=0
  fi
done

for d in worker configs workflows scripts systemd docs; do
  if [ -d "$d" ]; then
    echo "[OK] dir: $d"
  else
    echo "[MISSING] dir: $d"
    STATUS_OK=0
  fi
done

SYSTEMD_FILE=$(ls systemd/*.service 2>/dev/null | head -n1)
if [ -n "$SYSTEMD_FILE" ]; then
  SYSTEMD_STATUS="PASS"
else
  SYSTEMD_STATUS="FAIL"
  STATUS_OK=0
fi

# فحص عدم وجود إعداد ثابت مقفل على كرت شاشة من جيل مختلف (نبني النمط ديناميكياً لتفادي اكتشاف هذا الملف لنفسه)
OLD_GEN_PATTERN="4""090"
RTX5090_CONFIG="PASS"
MATCHES=$(grep -ril "$OLD_GEN_PATTERN" --include="*.sh" . 2>/dev/null | grep -v "\.git" | grep -v "^./verify.sh$")
if [ -n "$MATCHES" ]; then
  RTX5090_CONFIG="FAIL"
  STATUS_OK=0
fi
if [ ! -f docs/RTX5090.md ]; then
  RTX5090_CONFIG="FAIL"
  STATUS_OK=0
fi

[ -f setup.sh ] && SETUP_SCRIPT="PASS" || { SETUP_SCRIPT="FAIL"; STATUS_OK=0; }
[ -f restore.sh ] && RESTORE_SCRIPT="PASS" || { RESTORE_SCRIPT="FAIL"; STATUS_OK=0; }
[ -f verify.sh ] && VERIFY_SCRIPT="PASS" || { VERIFY_SCRIPT="FAIL"; STATUS_OK=0; }

SECRETS=$(grep -raiE '(SECRET|TOKEN|PASSWORD|API_KEY)\s*=\s*[^[:space:]]' \
  --include="*.env.example" --include="*.md" . 2>/dev/null \
  | grep -v '=\s*$' | grep -v "^Binary" | wc -l)
if [ "$SECRETS" -gt 0 ]; then
  STATUS_OK=0
fi

echo ""
echo "=== FINAL PACKAGE REPORT ==="
if [ "$STATUS_OK" -eq 1 ]; then
  echo "BACKUP_PACKAGE=PASS"
else
  echo "BACKUP_PACKAGE=FAIL"
fi
echo "RTX5090_CONFIG=${RTX5090_CONFIG}"
echo "RESTORE_SCRIPT=${RESTORE_SCRIPT}"
echo "SETUP_SCRIPT=${SETUP_SCRIPT}"
echo "VERIFY_SCRIPT=${VERIFY_SCRIPT}"
echo "SYSTEMD=${SYSTEMD_STATUS}"
echo "SECRETS=${SECRETS}"
if [ "$STATUS_OK" -eq 1 ]; then
  echo "STATUS=PASS"
else
  echo "STATUS=FAIL"
fi
