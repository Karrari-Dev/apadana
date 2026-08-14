#!/usr/bin/env bash
# GitHub / local binary installer — two ELFs + optional SHA256SUMS → full panel install.
#
# GitHub (after Release is published):
#   bash <(curl -fsSL https://raw.githubusercontent.com/apadana-vpn/apadana-panel/main/get-apadana.sh) --yes
#
# Local (no GitHub — drop 3–4 files in one folder, then):
#   apadana-panel · apadana-agent · get-apadana.sh · (optional) SHA256SUMS
#   cd /root && chmod +x get-apadana.sh apadana-* && sudo bash get-apadana.sh --yes
#
# Same command upgrades a live panel (apt is skipped automatically).
# Never run deploy/panel/install-fresh-panel.sh on a live panel.
#
# Never: curl … | bash  (breaks interactive prompts)
set -euo pipefail

REPO="${APADANA_GITHUB_REPO:-apadana-vpn/apadana-panel}"
VERSION="latest"
ASSUME_YES=0
FORCE_GITHUB=0
INSTALL_ARGS=()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

usage() {
  cat <<'EOF'
usage: get-apadana.sh [--version TAG] [--yes] [--github] [install args…]

  Local mode (default when apadana-panel + apadana-agent sit next to this script):
    Place apadana-panel, apadana-agent, get-apadana.sh in /root (optional SHA256SUMS)
    sudo bash get-apadana.sh --yes

  GitHub mode:
    bash <(curl -fsSL …/main/get-apadana.sh) --yes
    or: get-apadana.sh --github --yes

  --version   release tag (GitHub mode, default: latest)
  --yes|-y    non-interactive → apadana-panel install --yes
  --github    download from GitHub even if local binaries exist
  other args  forwarded to: apadana-panel install …
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:?}"
      shift 2
      ;;
    --yes|-y)
      ASSUME_YES=1
      INSTALL_ARGS+=(--yes)
      shift
      ;;
    --github)
      FORCE_GITHUB=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      INSTALL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash get-apadana.sh" >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID}" != "ubuntu" || ( "${VERSION_ID}" != "22.04" && "${VERSION_ID}" != "24.04" ) ]]; then
  echo "Only Ubuntu 22.04 / 24.04 is supported." >&2
  exit 1
fi

ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64|amd64) ARCH_TAG="x86_64" ;;
  aarch64|arm64) ARCH_TAG="aarch64" ;;
  *)
    echo "Unsupported architecture: ${ARCH}" >&2
    exit 1
    ;;
esac

_find_local() {
  local name="$1"
  for dir in "${SCRIPT_DIR}" "$(pwd)" /root; do
    [[ -f "${dir}/${name}" ]] || continue
    echo "${dir}/${name}"
    return 0
  done
  return 1
}

_normalize_sums() {
  # Windows-packed kits often ship SHA256SUMS with CRLF; anchors like /$ then miss.
  if [[ -f SHA256SUMS ]] && grep -q $'\r' SHA256SUMS 2>/dev/null; then
    sed -i 's/\r$//' SHA256SUMS
    echo "normalized CRLF in SHA256SUMS"
  fi
}

_check() {
  local file="$1"
  local base
  base="$(basename "${file}")"
  local expected actual size
  # Never let grep-no-match + set -e abort before a clear error message.
  expected="$(
    tr -d '\r' < SHA256SUMS | awk -v b="${base}" -v t="${base}-${ARCH_TAG}" '
      $2 == b || $2 == t { print $1; exit }
    ' || true
  )"
  expected="$(printf '%s' "${expected}" | tr -d '\r')"
  if [[ -z "${expected}" ]]; then
    echo "checksum entry missing for ${base} in SHA256SUMS" >&2
    echo "  (if this file was copied from Windows, regenerate: sha256sum apadana-panel apadana-agent > SHA256SUMS)" >&2
    exit 1
  fi
  size="$(wc -c < "${file}" | tr -d ' ')"
  actual="$(sha256sum "${file}" | awk '{print $1}')"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "checksum mismatch — aborting" >&2
    echo "  file:     ${base} (${size} bytes)" >&2
    echo "  expected: ${expected}" >&2
    echo "  actual:   ${actual}" >&2
    echo "" >&2
    echo "Fix (local kit): re-copy ALL 4 files from the same kit folder:" >&2
    echo "  apadana-panel  apadana-agent  get-apadana.sh  SHA256SUMS" >&2
    echo "Or regenerate sums on this host:" >&2
    echo "  cd /root && sha256sum apadana-panel apadana-agent > SHA256SUMS" >&2
    exit 1
  fi
  echo "checksum ok ${base} (${size} bytes)"
}

LOCAL_PANEL=""
LOCAL_AGENT=""
LOCAL_SUMS=""
if [[ "${FORCE_GITHUB}" -eq 0 ]]; then
  LOCAL_PANEL="$(_find_local apadana-panel || true)"
  LOCAL_AGENT="$(_find_local apadana-agent || true)"
  LOCAL_SUMS="$(_find_local SHA256SUMS || true)"
fi

WORKDIR=""
if [[ -n "${LOCAL_PANEL}" && -n "${LOCAL_AGENT}" ]]; then
  WORKDIR="$(mktemp -d /tmp/apadana-get.XXXXXX)"
  trap 'rm -rf "${WORKDIR}"' EXIT
  cp -f "${LOCAL_PANEL}" "${WORKDIR}/apadana-panel"
  cp -f "${LOCAL_AGENT}" "${WORKDIR}/apadana-agent"
  if [[ -n "${LOCAL_SUMS}" ]]; then
    cp -f "${LOCAL_SUMS}" "${WORKDIR}/SHA256SUMS"
  fi
  cd "${WORKDIR}"
  echo "=== Apadana local install (binaries from ${LOCAL_PANEL%/*}) ==="
  if [[ -f SHA256SUMS ]]; then
    _normalize_sums
    _check apadana-panel
    _check apadana-agent
  else
    echo "WARN: SHA256SUMS not found — skipping checksum (add it for production)" >&2
  fi
else
  if [[ "${VERSION}" == "latest" ]]; then
    API_URL="https://api.github.com/repos/${REPO}/releases/latest"
    TAG="$(curl -fsSL "${API_URL}" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
    if [[ -z "${TAG}" ]]; then
      echo "Could not resolve latest release for ${REPO}" >&2
      echo "Tip: copy apadana-panel + apadana-agent next to get-apadana.sh for local install." >&2
      exit 1
    fi
  else
    TAG="${VERSION}"
  fi

  BASE="https://github.com/${REPO}/releases/download/${TAG}"
  WORKDIR="$(mktemp -d /tmp/apadana-get.XXXXXX)"
  trap 'rm -rf "${WORKDIR}"' EXIT
  cd "${WORKDIR}"

  echo "=== Apadana get ${TAG} (${ARCH_TAG}) from ${REPO} ==="
  curl -fsSL -o apadana-panel "${BASE}/apadana-panel-${ARCH_TAG}" \
    || curl -fsSL -o apadana-panel "${BASE}/apadana-panel"
  curl -fsSL -o apadana-agent "${BASE}/apadana-agent-${ARCH_TAG}" \
    || curl -fsSL -o apadana-agent "${BASE}/apadana-agent"
  curl -fsSL -o SHA256SUMS "${BASE}/SHA256SUMS"
  _normalize_sums

  _check apadana-panel
  _check apadana-agent
fi

echo ">>> installing binaries to /opt/apadana/bin"
install -d -m 0755 /opt/apadana/bin
install -d -m 1777 /var/lib/apadana/tmp
install -d -m 0755 /var/lib/apadana/runtime
for _bin in apadana-panel apadana-agent; do
  # Running the script from /opt/apadana/bin makes src==dest; `install` would abort.
  if [[ "$(readlink -f "${_bin}")" != "$(readlink -f "/opt/apadana/bin/${_bin}")" ]]; then
    install -m 0755 "${_bin}" "/opt/apadana/bin/${_bin}"
  else
    chmod 0755 "/opt/apadana/bin/${_bin}"
  fi
done
ln -sf /opt/apadana/bin/apadana-panel /usr/local/bin/apadana

export APADANA_INSTALL_MODE=binary
export APADANA_INSTALL_ROOT=/opt/apadana
export TMPDIR="${TMPDIR:-/var/lib/apadana/tmp}"

# Live panel: skip apt. First install still installs MariaDB/Redis/nginx.
if [[ -f /etc/apadana/apadana.env && -x /opt/apadana/bin/apadana-panel ]]; then
  skip_pkgs=0
  for _arg in "${INSTALL_ARGS[@]+"${INSTALL_ARGS[@]}"}"; do
    if [[ "${_arg}" == "--skip-packages" ]]; then
      skip_pkgs=1
      break
    fi
  done
  if [[ "${skip_pkgs}" -eq 0 ]]; then
    echo ">>> existing panel detected — upgrade (skip apt packages)"
    INSTALL_ARGS+=(--skip-packages)
  fi
fi

echo ">>> starting: apadana-panel install ${INSTALL_ARGS[*]:-}"
# Avoid bare exec so OOM/crash still prints a clear exit code.
set +e
/opt/apadana/bin/apadana-panel install "${INSTALL_ARGS[@]}"
rc=$?
set -e
if [[ "${rc}" -eq 137 || "${rc}" -eq 9 ]]; then
  echo "FATAL: apadana-panel install was killed (exit ${rc}) — usually OOM." >&2
  echo "  free -h; add swap or use a VPS with >=2GB RAM, then retry." >&2
  exit "${rc}"
fi
if [[ "${rc}" -ne 0 ]]; then
  echo "FATAL: apadana-panel install failed (exit ${rc})" >&2
  exit "${rc}"
fi
echo "=== get-apadana: install finished ok ==="
exit 0
