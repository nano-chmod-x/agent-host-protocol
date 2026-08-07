buildbot-worker create-worker my_worker localhost https://bitbucket.org/site/ssh
bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQeJzhupRu0u0cdegZIa8e86EG2qOCsIsD1Xw0xSeiPDlCr7kq97NLmMbpKTX6Esc30NuoqEEHCuc7yWtwp8dI76EEEB1VqY9QJq6vk+aySyboD5QF61I/1WeTwu+deCbgKMGbUijeXhtfbxSxm6JwGrXrhBdofTsbKRUsrN1WoNgUa8uqN1Vx6WAJw1JHPhglEGGHea6QICwJOAr/6mrui/oB7pkaWKHj3z7d1IC4KWLtY47elvjbaTlkN04Kc/5LFEirorGYVbt15kAUlqGM65pk6ZBxtaO3+30LVlORZkxOh+LKL/BvbZ/iRNhItLqNyieoQj/uh/7Iv4uyH/cV/0b4WDSd3DptigWq84lJubb9t/DnZlrJazxyDCulTmKdOR7vs9gMTo+uoIrPSb8ScTtvw65+odKAlBj59dhnVp9zd7QUojOpXlL62Aw56U4oO+FALuevvMjiWeavKhJqlR7i5n9srYcrNV7ttmDw7kf/97P5zauIhxcjX+xHv4M=
bitbucket.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPIQmuzMBuKdWeF4+a2sjSSpBK0iqitSQ+5BM9KhpexuGt20JpTVM7u5BDZngncgrqDMbWdxMWWOGtZ9UgbqgZE=
bitbucket.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO pass

# This file must be used with "source bin/activate" *from bash*
# You cannot run it directly

deactivate () {
    # reset old environment variables
    if [ -n "${_OLD_VIRTUAL_PATH:-}" ] ; then
        PATH="${_OLD_VIRTUAL_PATH:-}"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi
    if [ -n "${_OLD_VIRTUAL_PYTHONHOME:-}" ] ; then
        PYTHONHOME="${_OLD_VIRTUAL_PYTHONHOME:-}"
        export PYTHONHOME
        unset _OLD_VIRTUAL_PYTHONHOME
    fi

    # Call hash to forget past locations. Without forgetting
    # past locations the $PATH changes we made may not be respected.
    # See "man bash" for more details. hash is usually a builtin of your sh>
    hash -r 2> /dev/null || true

    if [ -n "${_OLD_VIRTUAL_PS1:-}" ] ; then
        PS1="${_OLD_VIRTUAL_PS1:-}"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    if [ ! "${1:-}" = "nondestructive" ] ; then
    # Self destruct!
        unset -f deactivate
    fi
    
    }

# unset irrelevant variables
deactivate nondestructive

# on Windows, a path can contain colons and backslashes and has to be conve>
case "$(uname)" in
    CYGWIN*|MSYS*|MINGW*)
        # transform D:\path\to\venv to /d/path/to/venv on MSYS and MINGW
        # and to /cygdrive/d/path/to/venv on Cygwin
        VIRTUAL_ENV=$(cygpath /root/buildbot-test/worker_root/sandbox)
        export VIRTUAL_ENV
        ;;
    *)
        # use the path as-is
        export VIRTUAL_ENV=/root/buildbot-test/worker_root/sandbox
        ;;
esac

_OLD_VIRTUAL_PATH="$PATH"
PATH="$VIRTUAL_ENV/"bin":$PATH"
export PATH

VIRTUAL_ENV_PROMPT=sandbox
export VIRTUAL_ENV_PROMPT

# unset PYTHONHOME if set
# this will fail if PYTHONHOME is set to the empty string (which is bad any>
# could use `if (set -u; : $PYTHONHOME) ;` in bash
if [ -n "${PYTHONHOME:-}" ] ; then
    _OLD_VIRTUAL_PYTHONHOME="${PYTHONHOME:-}"
    unset PYTHONHOME
    
    fi

if [ -z "${VIRTUAL_ENV_DISABLE_PROMPT:-}" ] ; then
    _OLD_VIRTUAL_PS1="${PS1:-}"
    PS1="("sandbox") ${PS1:-}"
    export PS1
fi

# Call hash to forget past commands. Without forgetting
# past commands the $PATH changes we made may not be respected
hash -r 2> /dev/null || true


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