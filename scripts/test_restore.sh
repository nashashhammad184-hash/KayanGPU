#!/usr/bin/env bash
set -uo pipefail

TESTDIR="/tmp/kayangpu_restore_test_$$"
GH_USER="nashashhammad184-hash"

echo "=== KayanGPU Restore Test (isolated, temp dir) ==="
echo "Test directory: $TESTDIR"

echo ""
echo -n "أدخل GitHub Personal Access Token: "
read GH_TOKEN
echo ""

if [ -z "${GH_TOKEN:-}" ]; then
  echo "RESTORE_CLONE=FAIL"
  echo "[STOP] التوكن فارغ."
  exit 1
fi

REPO_URL="https://${GH_USER}:${GH_TOKEN}@github.com/${GH_USER}/KayanGPU.git"

echo "--- 1) Fresh clone from GitHub ---"
git clone "$REPO_URL" "$TESTDIR" >/tmp/clone_log_$$.txt 2>&1
CLONE_RESULT=$?
sed -i "s#${GH_TOKEN}#REDACTED#g" /tmp/clone_log_$$.txt 2>/dev/null || true
cat /tmp/clone_log_$$.txt
unset GH_TOKEN
unset REPO_URL

if [ "$CLONE_RESULT" -ne 0 ] || [ ! -d "$TESTDIR/.git" ]; then
  echo "RESTORE_CLONE=FAIL"
  exit 1
fi
echo "RESTORE_CLONE=PASS"

cd "$TESTDIR"
git remote set-url origin "https://github.com/${GH_USER}/KayanGPU.git"

echo ""
echo "--- 2) File completeness check ---"
EXPECTED="worker configs workflows scripts systemd docs setup.sh update.sh verify.sh restore.sh requirements.txt requirements-gpu.txt .env.example .gitignore README.md BACKUP_MANIFEST.md"
MISSING=0
for item in $EXPECTED; do
  [ ! -e "$item" ] && { echo "[MISSING] $item"; MISSING=1; }
done
[ "$MISSING" -eq 0 ] && echo "FILES_COMPLETE_IN_CLONE=PASS" || echo "FILES_COMPLETE_IN_CLONE=FAIL"

echo ""
echo "--- 3) Secrets check in fresh clone ---"
SECRETS=$(grep -raiE '(SECRET|TOKEN|PASSWORD|API_KEY)\s*=\s*[^[:space:]]' \
  --include="*.env.example" --include="*.md" . 2>/dev/null | grep -v '=\s*$' | wc -l)
echo "SECRETS_IN_CLONE=${SECRETS}"

echo ""
echo "--- 4) .env creation from template ---"
cp .env.example .env
[ -f .env ] && echo "ENV_CREATION=PASS" || echo "ENV_CREATION=FAIL"

echo ""
echo "--- 5) venv + BASE dependencies only (lightweight, no GPU on this host) ---"
python3 -m venv venv 2>&1
if [ -d venv ]; then
  source venv/bin/activate
  pip install --upgrade pip >/dev/null 2>&1
  if pip install -r requirements.txt > /tmp/pip_install_log_$$.txt 2>&1; then
    echo "BASE_DEPENDENCIES_INSTALL=PASS"
  else
    echo "BASE_DEPENDENCIES_INSTALL=FAIL (راجع /tmp/pip_install_log_$$.txt)"
  fi
  deactivate
  echo "[INFO] requirements-gpu.txt (PyTorch) لم يُختبر هنا عمداً — يتطلب GPU فعلي، سيُختبر عبر setup.sh/restore.sh مباشرة على خادم RTX 5090"
else
  echo "BASE_DEPENDENCIES_INSTALL=FAIL"
fi

echo ""
echo "--- 6) Directory preparation reproducibility ---"
mkdir -p worker/models worker/outputs worker/logs configs workflows scripts systemd docs
[ -d worker/models ] && [ -d worker/outputs ] && echo "DIRECTORY_PREP=PASS" || echo "DIRECTORY_PREP=FAIL"

echo ""
echo "--- 7) setup.sh GPU safety gate check ---"
chmod +x setup.sh
SETUP_OUTPUT=$(bash setup.sh 2>&1) || true
if echo "$SETUP_OUTPUT" | grep -q "STATUS=FAIL"; then
  echo "GPU_SAFETY_GATE=PASS (رفض العمل بدون RTX 5090 كما هو مصمم)"
else
  echo "GPU_SAFETY_GATE=UNEXPECTED"
fi

echo ""
echo "--- 8) verify.sh executability check ---"
chmod +x verify.sh
./verify.sh > /tmp/verify_output_$$.txt 2>&1 || true
grep "BACKUP_PACKAGE=" /tmp/verify_output_$$.txt || echo "BACKUP_PACKAGE=UNKNOWN"

echo ""
echo "=== RESTORE TEST SUMMARY ==="
echo "تم اختبار: الاستنساخ من GitHub، اكتمال الملفات، عدم وجود أسرار، تثبيت الاعتماديات الأساسية الخفيفة، تجهيز المجلدات، وبوابة أمان GPU."
echo "لم يُختبر هنا (يتطلب GPU فعلي): تثبيت PyTorch المطابق لـ CUDA، واختبار HunyuanVideo-1.5 الفعلي — هذه ستُختبر مباشرة عند توفر خادم RTX 5090."

cd ~
rm -rf "$TESTDIR"
echo ""
echo "[CLEANUP] تم حذف مجلد الاختبار المؤقت فقط - لم يُلمس ~/KayanGPU الأصلي"
