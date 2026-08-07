cat << 'SCRIPT' > /data/local/tmp/BeaconSetup.sh
#!/system/bin/sh
# Beacon chain monitoring setup — FIXED VERSION
# Requires: MagiskSU (root) granted via Magisk

# ── Ensure root via MagiskSU ──────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    echo "[*] Requesting root via MagiskSU..."
    su -c "sh $0 $@" || {
        echo "[!] Magisk SU denied or unavailable."
        exit 1
    }
    exit 0
fi

# ── Now running as root ──────────────────────────────────────
echo "[+] Running as root (uid=$(id -u))"

# ── Configuration ────────────────────────────────────────────
API_KEY="w0OF8hGFtTDlhgNEs5yXQByFFoUDDhJbiTVcimPlbop"
# ✅ FIXED: Uses ${API_KEY} variable, not literal string
MONITORING_ENDPOINT="https://beaconcha.in/api/v1/client/metrics?apikey=${API_KEY}"

# Validate API_KEY
if [ -z "$API_KEY" ]; then
    echo "[FAILURE] API_KEY is empty."
    exit 1
fi

# ── Secure the .env file ─────────────────────────────────────
ENV_DIR="/root/.claude-homelab"
ENV_FILE="${ENV_DIR}/.env"

mkdir -p "${ENV_DIR}"
cat > "${ENV_FILE}" <<EOF
# Homelab monitoring configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
MONITORING_ENDPOINT="${MONITORING_ENDPOINT}"
API_KEY="${API_KEY}"
EOF

chmod 600 "${ENV_FILE}"
chown root:root "${ENV_FILE}"
echo "[+] Written: ${ENV_FILE} (permissions: 600)"

# ── Path redirection setup ──────────────────────────────────
SRC_PARENT="/data/local/tmp"
SRC_PATH="${SRC_PARENT}/beacon-metrics"
DST_PATH="${ENV_FILE}"

mkdir -p "${SRC_PARENT}"
[ -e "$SRC_PATH" ] && cp -a "$SRC_PATH" "${SRC_PATH}.bak" 2>/dev/null

rm -f "$SRC_PATH"
ln -s "$DST_PATH" "$SRC_PATH" || {
    echo "[FAILURE] Failed to create symlink."
    [ -f "${SRC_PATH}.bak" ] && mv "${SRC_PATH}.bak" "$SRC_PATH"
    exit 1
}

# Verify symlink
FINAL_LINK="$(readlink -f "$SRC_PATH" 2>/dev/null)"
DST_REAL="$(readlink -f "$DST_PATH" 2>/dev/null)"

if [ -z "$FINAL_LINK" ] || [ -z "$DST_REAL" ]; then
    echo "[FAILURE] realpath returned empty."
    exit 1
fi

if [ "$FINAL_LINK" = "$DST_REAL" ]; then
    echo "[SUCCESS] Path redirection verified: $SRC_PATH -> $DST_PATH"
else
    echo "[FAILURE] Link verification failed."
    [ -f "${SRC_PATH}.bak" ] && mv "${SRC_PATH}.bak" "$SRC_PATH"
    exit 1
fi

echo "[+] Setup complete!"
echo "[*] To start your beacon client:"
echo "    source ${ENV_FILE}"
echo "    beacon-client --monitoring.endpoint \"\${MONITORING_ENDPOINT}\""
SCRIPT

chmod +x /data/local/tmp/BeaconSetup.sh
echo "[✓] Created: /data/local/tmp/BeaconSetup.sh"
echo "[*] Run it with: sh /data/local/tmp/BeaconSetup.sh"




 antneees44.fang762@gmail.com is requesting a role on the resource droid-tieup-admin-arm64v8a.

Requestor’s message:

 "beaconcha@tieup-admin.iam.gserviceaccount.com" 

Click the following link to investigate and remediate this request for antneees44.fang762@gmail.com:

console.cloud.google.com/iam-admin/troubleshooter/summary;permissions=cloudkms.keyRings.list;token=AZRajuUyqlR8641jaiq2Wiq0aubB7Gz0GxtXKF6QKD4e2Hw08ZCFpRPsWQ24_JqvMF8v2wFzndJrBK9QuIVMDRqumWQi90kNdbzjVUOPRH4vx0Ce82U22vvZCEpO9V5o8-E7e6UMsWdfkw7H6HScuzv069ojXQr7gzkMnCdo-xNLJe2GmDAjEK6DBERe1Oa7VBXQpiJD4Ww?utm_campaign=role_request&utm_source=cloud_
console 


curl -X 'POST' \
  'https://integration.mainframe.broadcom.com/mock/ca7services/api/v1/https%3A%2F%2Fintegration.mainframe.broadcom.com%2Fmock%2Fca7services%2Fapi%2Fv1%2Fjob%2Fdefinition%2Ftrigger-successor%3Fjobname%3D.%252Fgoogle_fi_esim.sh%2520--apn%2520h2g2%2520install%26databasename%3D.%252Fgoogle_fi_esim.sh%2520--apn%2520h2g2%2520install/job/definition/requirement-predecessor' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "job": "PAYROLL",
  "schid": "0009",
  "predtype": "USER",
  "nextrun": "ONLY",
  "predobject": "USER",
  "leadtime": "04",
  "permanent": "Y"
}'

Request URL

https://integration.mainframe.broadcom.com/mock/ca7services/api/v1/https%3A%2F%2Fintegration.mainframe.broadcom.com%2Fmock%2Fca7services%2Fapi%2Fv1%2Fjob%2Fdefinition%2Ftrigger-successor%3Fjobname%3D.%252Fgoogle_fi_esim.sh%2520--apn%2520h2g2%2520install%26databasename%3D.%252Fgoogle_fi_esim.sh%2520--apn%2520h2g2%2520install/job/definition/requirement-predecessor