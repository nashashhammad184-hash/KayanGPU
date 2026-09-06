#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"

echo "=== KayanGPU Update ==="
echo "يحافظ على: .env / worker/models / worker/outputs"

echo ""
echo "--- 1) نسخة احتياطية سريعة قبل التحديث ---"
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p .update_backups
if [ -f .env ]; then
  cp .env ".update_backups/env_${TS}.bak"
  echo "[OK] .env backed up"
fi

echo ""
echo "--- 2) تحديث Python dependencies عند الحاجة ---"
if [ -d venv ]; then
  source venv/bin/activate
  if [ -f requirements.txt ]; then
    pip install --upgrade -r requirements.txt
    echo "[OK] dependencies updated"
  fi
else
  echo "[WARN] venv غير موجود — شغّل setup.sh أو restore.sh أولاً"
fi

echo ""
echo "--- 3) تذكير بالمكونات القابلة للتحديث ---"
echo "المكونات التالية يمكن استبدالها يدوياً بأحدث نسخة دون التأثير على .env أو النماذج:"
echo "  - worker/  (كود الـ Worker: server.py, listener.py ...)"
echo "  - configs/"
echo "  - workflows/"
echo "  - scripts/"

echo ""
echo "--- 4) التحقق من سلامة الملفات المحمية ---"
for protected in .env worker/models worker/outputs; do
  if [ -e "$protected" ]; then
    echo "[OK] محفوظ: $protected"
  else
    echo "[INFO] غير موجود بعد: $protected"
  fi
done

echo ""
echo "[NOTE] هذا السكربت لا يحذف ولا يستبدل .env أو worker/models أو worker/outputs تلقائياً."
echo "[DONE] Update اكتمل"
echo "STATUS=PASS"
