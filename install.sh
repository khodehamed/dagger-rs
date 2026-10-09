#!/usr/bin/env bash
# dagger-rs 0.2.1 — one-line install (Linux x86_64, root):
#
#   curl -fsSL https://cdn.jsdelivr.net/gh/khodehamed/dagger-rs@main/install.sh | sudo bash
#
# The .run bundle reads its payload from its own file, so it is saved to disk
# and checked before it runs. It is not executed from a pipe.
# curl|bash leaves this script's stdin on the pipe. The bundle is started with
# --no-setup so its old menu cannot read that pipe, then the new menu is
# installed and attached to /dev/tty.
# Some networks drop GitHub TLS. Each file is tried from jsDelivr, then GitHub,
# until the bytes match the checksum. Existing /etc/dagger-rs files are kept.
set -euo pipefail

REPO="khodehamed/dagger-rs"
BRANCH="main"
ASSET="files-to-upload/dagger-rs-linux-x86_64.run"
SHA256="51d34306d901ea43ed5446ddee1dee5c345aabc212695246c1c5b9d1000d3f6f"
MENU_ASSET="dagger-setup"
MENU_SHA256="3a53470b634de1f3a77d6a271cf3516b2abbcdf803171be6dd5b80cf595afcd5"
INSTALL_URL="https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/install.sh"

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
  echo "  curl -fsSL ${INSTALL_URL} | sudo bash" >&2
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

fetch_checked() {
  local dest="$1"
  local sum="$2"
  shift 2
  local url
  local -a curl_args
  curl_args=(-4 --http1.1 --retry 5 --retry-delay 2 --connect-timeout 20 --max-time 180 -fL)
  if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
    curl_args+=(--retry-all-errors)
  fi
  for url in "$@"; do
    echo "Trying ${url}"
    rm -f -- "$dest"
    if curl "${curl_args[@]}" "$url" -o "$dest" \
      && [[ -s "$dest" ]] \
      && echo "${sum}  ${dest}" | sha256sum --check --status; then
      return 0
    fi
    echo "Download failed: ${url}" >&2
  done
  echo "Could not download a file that matches the checksum." >&2
  return 1
}

echo "Downloading ${ASSET}"
fetch_checked "$tmp" "$SHA256" \
  "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${ASSET}" \
  "https://github.com/${REPO}/raw/${BRANCH}/${ASSET}" \
  "https://raw.githubusercontent.com/${REPO}/${BRANCH}/${ASSET}"
chmod 0755 "$tmp"

echo "Downloading setup menu"
fetch_checked "$menu_tmp" "$MENU_SHA256" \
  "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${MENU_ASSET}" \
  "https://github.com/${REPO}/raw/${BRANCH}/${MENU_ASSET}" \
  "https://raw.githubusercontent.com/${REPO}/${BRANCH}/${MENU_ASSET}"

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
