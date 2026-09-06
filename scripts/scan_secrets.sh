#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."

echo "=== Secret Scan (before git commit) ==="
FOUND=0

SCAN_TARGETS="worker configs workflows scripts systemd docs setup.sh update.sh verify.sh restore.sh requirements.txt .env.example .gitignore README.md BACKUP_MANIFEST.md"

check_pattern () {
  local label="$1"
  local pattern="$2"
  local matches
  matches=$(grep -rIlE "$pattern" $SCAN_TARGETS 2>/dev/null | grep -v "\.example$")
  if [ -n "$matches" ]; then
    echo "[SECRET FOUND] ${label}:"
    echo "$matches"
    FOUND=1
  fi
}

check_pattern "OpenAI-style key (sk-...)" 'sk-[A-Za-z0-9]{20,}'
check_pattern "Replicate token (r8_...)" 'r8_[A-Za-z0-9]{20,}'
check_pattern "Groq key (gsk_...)" 'gsk_[A-Za-z0-9]{20,}'
check_pattern "Generic API_KEY with value" 'API_KEY[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}'
check_pattern "Generic TOKEN with value" 'TOKEN[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}'
check_pattern "Generic PASSWORD with value" 'PASSWORD[[:space:]]*[:=][[:space:]]*[^[:space:]]{4,}'
check_pattern "Private key block" 'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'
check_pattern "DATABASE_URL with embedded password" 'DATABASE_URL[[:space:]]*=[[:space:]]*[a-zA-Z]+://[^:]+:[^@]+@'
check_pattern "Deepgram key" 'DEEPGRAM[_A-Z]*KEY[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}'

echo ""
if [ "$FOUND" -eq 1 ]; then
  echo "SECRETS_SCAN=FAIL"
  echo "[STOP] لا ترفع شيء إلى Git قبل حل ما سبق."
  exit 1
else
  echo "SECRETS_SCAN=PASS"
  exit 0
fi
