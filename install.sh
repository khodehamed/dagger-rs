#!/usr/bin/env bash
# dagger-rs 0.2.1 — one-line install (Linux x86_64, root):
#
#   curl -fsSL https://raw.githubusercontent.com/khodehamed/dagger-rs/main/install.sh | sudo bash
#
# The .run bundle reads its payload from its own file, so it is saved to disk
# and checked before it runs. It is not executed from a pipe.
set -euo pipefail

REPO="khodehamed/dagger-rs"
BRANCH="main"
ASSET="files-to-upload/dagger-rs-linux-x86_64.run"
SHA256="51d34306d901ea43ed5446ddee1dee5c345aabc212695246c1c5b9d1000d3f6f"
URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${ASSET}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This installer supports Linux only." >&2
  exit 1
fi
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "This bundle is for x86_64 Linux." >&2
  exit 1
fi
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/${REPO}/${BRANCH}/install.sh | sudo bash" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y ca-certificates curl python3
  fi
fi
command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for the setup menu." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum is required." >&2; exit 1; }

tmp="$(mktemp --suffix=.run)"
cleanup() { rm -f -- "$tmp"; }
trap cleanup EXIT

echo "Downloading ${ASSET}"
curl -fL --retry 3 --connect-timeout 20 --max-time 180 "$URL" -o "$tmp"
echo "${SHA256}  ${tmp}" | sha256sum --check --status
chmod 0755 "$tmp"

# Drop the trap so a failing menu does not hide the installer error, and so
# the bundle file still exists while dagger-setup is open.
trap - EXIT
bash "$tmp" "$@"
status=$?
rm -f -- "$tmp"
exit "$status"
