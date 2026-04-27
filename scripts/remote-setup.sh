#!/usr/bin/env bash
# Sets up a remote Linux box so it is ready for benchmark runs — passwordless SSH,
# passwordless sudo, and verified local prerequisites — without requiring the user
# to ever log into the box directly.
#
# Once this script completes successfully, use scripts/perf-lab/run-benchmarks.sh
# with --host and --user to run the actual benchmarks.
#
# Usage:
#   scripts/remote-setup.sh --host <HOST> --user <USER> [options]
#
# Options:
#   --host <HOST>      Remote host (domain name or IP)
#   --user <USER>      Username on the remote host
#   --ssh-key <PATH>   Path to SSH private key to use/install (auto-detected if omitted)
#   --ssh-port <PORT>  SSH port on the remote host (default: 22)
#   --skip-sudo        Skip passwordless sudo setup
#   --check-only       Verify the setup without making any changes
#   -h, --help         Show this help message

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[FAIL]${NC} $*" >&2; }
die()  { err "$*"; exit 1; }
step() { echo; echo -e "${BOLD}━━ $* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ─── Defaults ─────────────────────────────────────────────────────────────────
HOST=""
REMOTE_USER=""
SSH_KEY=""
SSH_PORT="22"
SKIP_SUDO=false
CHECK_ONLY=false

# ─── Help ─────────────────────────────────────────────────────────────────────
help() {
  cat <<EOF

${BOLD}remote-setup.sh${NC} — Prepare a remote Linux box for benchmark runs.

${BOLD}Usage:${NC}
  scripts/remote-setup.sh --host <HOST> --user <USER> [options]

${BOLD}Required:${NC}
  --host <HOST>      Remote host (domain name or IP address)
  --user <USER>      Username on the remote host

${BOLD}Optional:${NC}
  --ssh-key <PATH>   Path to SSH private key (auto-detected if omitted)
  --ssh-port <PORT>  SSH port on the remote host (default: 22)
  --skip-sudo        Skip passwordless sudo configuration
  --check-only       Only verify the current setup — make no changes
  -h, --help         Show this help message

${BOLD}What this script does:${NC}
  1. Verifies local prerequisites: git, jbang, jq
  2. Locates (or generates) an SSH key pair
  3. Installs the public key on the remote host (passwordless SSH login)
  4. Configures passwordless sudo for the remote user
  5. Verifies the remote shell environment
  6. Ensures the C/C++ build toolchain is present (required for native image builds)
  7. Prints example run-benchmarks.sh commands

${BOLD}After a successful run:${NC}
  cd scripts/perf-lab
  ./run-benchmarks.sh --host <HOST> --user <USER> [benchmark options]

EOF
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)    help; exit 0 ;;
      --host)       HOST="$2";        shift 2 ;;
      --user)       REMOTE_USER="$2"; shift 2 ;;
      --ssh-key)    SSH_KEY="$2";     shift 2 ;;
      --ssh-port)   SSH_PORT="$2";    shift 2 ;;
      --skip-sudo)  SKIP_SUDO=true;   shift   ;;
      --check-only) CHECK_ONLY=true;  shift   ;;
      -*) die "Unknown option: $1 — run with --help for usage." ;;
      *)  die "Unexpected argument: $1 — run with --help for usage." ;;
    esac
  done
}

validate_args() {
  [[ -n "$HOST" ]]        || die "--host is required."
  [[ -n "$REMOTE_USER" ]] || die "--user is required."
  if [[ -n "$SSH_KEY" && ! -f "$SSH_KEY" ]]; then
    die "SSH key not found: $SSH_KEY"
  fi
}

# ─── SSH helpers ──────────────────────────────────────────────────────────────
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -p "$SSH_PORT")

ssh_batch() {
  # Non-interactive SSH — returns non-zero if password is required
  ssh "${SSH_OPTS[@]}" -o BatchMode=yes "${REMOTE_USER}@${HOST}" "$@"
}

ssh_interactive() {
  # Interactive SSH — may prompt for password
  ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${HOST}" "$@"
}

ssh_tty() {
  # Interactive SSH with allocated tty — needed for sudo password prompts
  ssh -t "${SSH_OPTS[@]}" "${REMOTE_USER}@${HOST}" "$@"
}

# ─── 1. Local prerequisites ───────────────────────────────────────────────────
check_local_prereqs() {
  step "Checking local prerequisites"

  local missing=()

  if command -v git &>/dev/null; then
    ok "git $(git --version | awk '{print $3}')"
  else
    missing+=("git")
    err "git not found — install via your package manager or https://git-scm.com"
  fi

  if command -v jbang &>/dev/null; then
    ok "jbang $(jbang --version 2>&1 | head -1)"
  else
    warn "jbang not found locally — the benchmark wrapper will download it on first run."
    warn "To install now: curl -Ls https://sh.jbang.dev | bash -s - app setup"
  fi

  if command -v jq &>/dev/null; then
    ok "jq $(jq --version)"
  else
    missing+=("jq")
    if [[ "$(uname)" == "Darwin" ]]; then
      err "jq not found — install with: brew install jq"
    else
      err "jq not found — install with: sudo apt-get install jq  (or your distro's equivalent)"
    fi
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing required local tools: ${missing[*]}"
  fi
}

# ─── 2 & 3. SSH key setup (skipped entirely if login already works) ───────────
setup_ssh_auth() {
  step "SSH key authentication"

  if ssh_batch true 2>/dev/null; then
    ok "Passwordless SSH login already works — skipping key setup."
    return
  fi

  if $CHECK_ONLY; then
    die "Passwordless SSH not configured. Re-run without --check-only to install the key."
  fi

  # Only locate / generate a key when we actually need to install one
  if [[ -z "$SSH_KEY" ]]; then
    local candidates=("$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ecdsa" "$HOME/.ssh/id_rsa")
    for k in "${candidates[@]}"; do
      if [[ -f "$k" ]]; then
        SSH_KEY="$k"
        info "Auto-selected key: $SSH_KEY"
        break
      fi
    done
  fi

  if [[ -z "$SSH_KEY" ]]; then
    info "No SSH key found — generating ed25519 key pair."
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "${REMOTE_USER}@benchmark-setup"
    SSH_KEY="$HOME/.ssh/id_ed25519"
    ok "Generated: $SSH_KEY"
  fi

  info "Installing public key on ${REMOTE_USER}@${HOST}:${SSH_PORT} …"
  info "(You may be prompted for the remote user's password once.)"

  local pub_key="${SSH_KEY}.pub"
  [[ -f "$pub_key" ]] || die "Public key not found: $pub_key"

  if command -v ssh-copy-id &>/dev/null; then
    ssh-copy-id -i "$pub_key" -p "$SSH_PORT" "${REMOTE_USER}@${HOST}"
  else
    # Fallback for systems without ssh-copy-id (some macOS setups)
    local key_content
    key_content=$(<"$pub_key")
    ssh "${SSH_OPTS[@]}" "${REMOTE_USER}@${HOST}" \
      "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '${key_content}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  fi

  # Verify
  if ssh_batch true 2>/dev/null; then
    ok "Passwordless SSH login confirmed."
  else
    die "SSH key installation appeared to succeed but passwordless login still fails. Check sshd_config on the remote host (PubkeyAuthentication must be 'yes')."
  fi
}

# ─── 4. Passwordless sudo ─────────────────────────────────────────────────────
setup_passwordless_sudo() {
  step "Passwordless sudo"

  if ssh_batch "sudo -n true" 2>/dev/null; then
    ok "Passwordless sudo already configured."
    return
  fi

  if $CHECK_ONLY; then
    die "Passwordless sudo not configured. Re-run without --check-only to configure it."
  fi

  info "Configuring passwordless sudo for '${REMOTE_USER}' on ${HOST} …"
  info "(You will be prompted for the remote user's sudo password.)"

  local sudoers_file="/etc/sudoers.d/${REMOTE_USER}-nopasswd"
  local sudoers_entry="${REMOTE_USER} ALL=(ALL) NOPASSWD: ALL"

  # We need a tty here so sudo can prompt for its password
  ssh_tty "echo '${sudoers_entry}' | sudo tee '${sudoers_file}' > /dev/null && sudo chmod 0440 '${sudoers_file}' && sudo visudo -c -q"

  # Verify
  if ssh_batch "sudo -n true" 2>/dev/null; then
    ok "Passwordless sudo confirmed."
  else
    die "Passwordless sudo configuration failed. Manually verify ${sudoers_file} on the remote host."
  fi
}

# ─── 5. C/C++ build toolchain ────────────────────────────────────────────────
ensure_build_toolchain() {
  step "C/C++ build toolchain"

  # Check each required tool independently so we install anything that's missing
  # even if some tools are already present.
  local need_gcc=false need_zlib=false

  if ssh_batch "command -v gcc" &>/dev/null; then
    local gcc_ver
    gcc_ver=$(ssh_batch "gcc --version 2>/dev/null | head -1")
    ok "gcc: $gcc_ver"
  else
    warn "gcc not found"
    need_gcc=true
  fi

  # Probe for zlib dev headers via the pkg-config or a direct header check.
  if ssh_batch "pkg-config --exists zlib 2>/dev/null || test -f /usr/include/zlib.h" &>/dev/null; then
    ok "zlib dev headers: present"
  else
    warn "zlib dev headers not found (GraalVM native-image linker requires -lz)"
    need_zlib=true
  fi

  if ! $need_gcc && ! $need_zlib; then
    return
  fi

  if $CHECK_ONLY; then
    $need_gcc  && warn "Re-run without --check-only to install the C/C++ toolchain."
    $need_zlib && warn "Re-run without --check-only to install zlib dev headers."
    return
  fi

  info "Detecting Linux distribution …"

  local distro_id distro_like
  distro_id=$(ssh_batch ". /etc/os-release && echo \$ID" 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  distro_like=$(ssh_batch ". /etc/os-release && echo \${ID_LIKE:-}" 2>/dev/null | tr '[:upper:]' '[:lower:]')

  local pkg_cmd="" pre_cmd=""
  case "$distro_id" in
    ubuntu|debian|linuxmint|pop)
      pre_cmd="apt-get update -y"
      pkg_cmd="apt-get install -y build-essential zlib1g-dev" ;;
    fedora)
      pkg_cmd="dnf install -y gcc gcc-c++ make zlib-devel" ;;
    rhel|centos|almalinux|rocky)
      pkg_cmd="dnf groupinstall -y 'Development Tools' && sudo dnf install -y zlib-devel" ;;
    opensuse*|sles)
      pkg_cmd="zypper install -y gcc gcc-c++ make zlib-devel" ;;
    arch|manjaro)
      pkg_cmd="pacman -Sy --noconfirm base-devel" ;;
    *)
      if [[ "$distro_like" == *debian* || "$distro_like" == *ubuntu* ]]; then
        pre_cmd="apt-get update -y"
        pkg_cmd="apt-get install -y build-essential zlib1g-dev"
      elif [[ "$distro_like" == *fedora* || "$distro_like" == *rhel* ]]; then
        pkg_cmd="dnf install -y gcc gcc-c++ make zlib-devel"
      else
        warn "Unknown distribution '$distro_id' — cannot auto-install the build toolchain."
        warn "Please install gcc and zlib dev headers manually (e.g. 'build-essential zlib1g-dev' on Debian/Ubuntu)."
        return
      fi ;;
  esac

  if [[ -n "$pre_cmd" ]]; then
    info "Refreshing package lists: sudo $pre_cmd"
    ssh_batch "sudo $pre_cmd" || warn "Package list update failed — will try installing anyway."
  fi

  info "Installing build toolchain on remote host: sudo $pkg_cmd"
  ssh_batch "sudo $pkg_cmd" || die "Failed to install build toolchain. Install manually with: sudo $pkg_cmd"

  # Verify both tools are now present
  local post_failed=0
  if ssh_batch "command -v gcc" &>/dev/null; then
    local gcc_ver
    gcc_ver=$(ssh_batch "gcc --version 2>/dev/null | head -1")
    ok "gcc installed: $gcc_ver"
  else
    err "gcc still not found after installation."
    (( post_failed++ )) || true
  fi
  if ssh_batch "pkg-config --exists zlib 2>/dev/null || test -f /usr/include/zlib.h" &>/dev/null; then
    ok "zlib dev headers: installed"
  else
    err "zlib dev headers still not found after installation."
    (( post_failed++ )) || true
  fi
  if [[ $post_failed -gt 0 ]]; then
    die "Build toolchain installation incomplete — $post_failed component(s) still missing."
  fi
}

# ─── 6. Remote environment verification ───────────────────────────────────────
verify_remote_environment() {
  step "Verifying remote environment"

  local checks_failed=0

  # bash
  local remote_bash
  if remote_bash=$(ssh_batch "bash --version 2>/dev/null | head -1" 2>/dev/null); then
    ok "bash: $remote_bash"
  else
    err "bash not found on remote host — this is required."
    (( checks_failed++ )) || true
  fi

  # OS type
  local remote_os
  if remote_os=$(ssh_batch "uname -sr" 2>/dev/null); then
    ok "OS: $remote_os"
    if [[ "$remote_os" != Linux* ]]; then
      warn "Remote host does not appear to be Linux. Only Linux is supported for benchmarks."
    fi
  fi

  # curl (needed for SDKMAN, jbang, etc.)
  if ssh_batch "command -v curl" &>/dev/null; then
    ok "curl: present"
  else
    err "curl not found on the remote host. Install it before running benchmarks (e.g. sudo apt-get install curl)."
    (( checks_failed++ )) || true
  fi

  # Check that the benchmark runner can SSH back in non-interactively (qDup requirement)
  if ssh_batch "echo 'connectivity ok'" &>/dev/null; then
    ok "Non-interactive SSH round-trip: ok"
  else
    err "Non-interactive SSH round-trip failed."
    (( checks_failed++ )) || true
  fi

  if [[ $checks_failed -gt 0 ]]; then
    die "$checks_failed remote environment check(s) failed. Fix the issues above and re-run."
  fi
}

# ─── 7. Summary ───────────────────────────────────────────────────────────────
print_summary() {
  echo
  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}${BOLD}  Setup complete!${NC}"
  echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo
  echo -e "  ${BOLD}Remote host:${NC} ${REMOTE_USER}@${HOST}:${SSH_PORT}"
  [[ -n "$SSH_KEY" ]] && echo -e "  ${BOLD}SSH key:${NC}     $SSH_KEY"
  echo
  echo -e "  ${BOLD}Run benchmarks from the perf-lab directory:${NC}"
  echo
  echo -e "    cd scripts/perf-lab"
  echo
  echo -e "  ${BOLD}All runtimes (JVM + native):${NC}"
  echo    "    ./run-benchmarks.sh \\"
  echo    "      --host ${HOST} \\"
  echo    "      --user ${REMOTE_USER} \\"
  echo    "      --quarkus-version <VERSION> \\"
  echo    "      --springboot3-version <VERSION>"
  echo
  echo -e "  ${BOLD}JVM runtimes only (faster):${NC}"
  echo    "    ./run-benchmarks.sh \\"
  echo    "      --host ${HOST} \\"
  echo    "      --user ${REMOTE_USER} \\"
  echo    "      --runtimes 'quarkus3-jvm,spring3-jvm,spring4-jvm,dotnet10' \\"
  echo    "      --quarkus-version <VERSION> \\"
  echo    "      --springboot3-version <VERSION>"
  echo
  echo -e "  See ${BOLD}./run-benchmarks.sh --help${NC} for all options."
  echo
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo
  echo -e "${BOLD}remote-setup.sh — Remote Benchmark Host Setup${NC}"
  echo -e "Host: ${HOST}  User: ${REMOTE_USER}  Port: ${SSH_PORT}"
  if $CHECK_ONLY; then
    echo -e "${YELLOW}[check-only mode — no changes will be made]${NC}"
  fi

  check_local_prereqs
  setup_ssh_auth
  $SKIP_SUDO || setup_passwordless_sudo
  verify_remote_environment
  ensure_build_toolchain
  print_summary
}

parse_args "$@"
validate_args
main
