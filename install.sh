#!/usr/bin/env bash
# dagger-rs 0.2.1 — one-line install (Linux x86_64, root):
#
#   curl -fsSL https://raw.githubusercontent.com/khodehamed/dagger-rs/main/install.sh | sudo bash
#
# The .run bundle reads its payload from its own file, so it is saved to disk
# and checked before it runs. It is not executed from a pipe.
# curl|bash leaves this script's stdin on the pipe. The bundle is started with
# --no-setup so its old menu cannot read that pipe, then the new menu is
# installed and attached to /dev/tty.
set -euo pipefail

REPO="khodehamed/dagger-rs"
BRANCH="main"
ASSET="files-to-upload/dagger-rs-linux-x86_64.run"
SHA256="51d34306d901ea43ed5446ddee1dee5c345aabc212695246c1c5b9d1000d3f6f"
URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${ASSET}"
MENU_ASSET="dagger-setup"
MENU_SHA256="c03ed385ba824fab24ab3a5bfc3e6ae0217320dd880eb1c35fd9a1331196bdc8"
MENU_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${MENU_ASSET}"

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

have_tty=no
if [[ -r /dev/tty && -w /dev/tty ]]; then
  have_tty=yes
fi

tmp="$(mktemp --suffix=.run)"
menu_tmp="$(mktemp)"
cleanup() { rm -f -- "$tmp" "$menu_tmp"; }
trap cleanup EXIT

echo "Downloading ${ASSET}"
curl -fL --retry 3 --connect-timeout 20 --max-time 180 "$URL" -o "$tmp"
echo "${SHA256}  ${tmp}" | sha256sum --check --status
chmod 0755 "$tmp"

echo "Downloading setup menu"
curl -fL --retry 3 --connect-timeout 20 --max-time 60 "$MENU_URL" -o "$menu_tmp"
echo "${MENU_SHA256}  ${menu_tmp}" | sha256sum --check --status

# Redirect stdin so the rest of this piped script is not eaten as menu input.
if [[ "$have_tty" == yes ]]; then
  bash "$tmp" --no-setup "$@" </dev/tty
else
  bash "$tmp" --no-setup "$@" </dev/null
fi

install -m 0755 "$menu_tmp" /usr/local/bin/dagger-setup

trap - EXIT
rm -f -- "$tmp" "$menu_tmp"

if [[ "$have_tty" == yes ]]; then
  exec /usr/local/bin/dagger-setup </dev/tty
fi
echo "Installed. Open the menu with: sudo dagger-setup"
exit 0
