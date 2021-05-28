#!/bin/bash

github_owner="yop-platform"
github_repo="yop-diag"
github_token="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"
github_issues="https://api.github.com/repos/$github_owner/$github_repo/issues"
# echo $github_issues

# 使用方法：
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/yop-platform/yop-diag/HEAD/install.sh)"

set -u

abort() {
  printf "%s\n" "$@"
  exit 1
}

# string formatters
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

have_sudo_access() {
  local -a args
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A")
  elif [[ -n "${NONINTERACTIVE-}" ]]; then
    args=("-n")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${args[*]-}" ]]; then
      SUDO="/usr/bin/sudo ${args[*]}"
    else
      SUDO="/usr/bin/sudo"
    fi
    if [[ -n "${NONINTERACTIVE-}" ]]; then
      ${SUDO} -l mkdir &>/dev/null
    else
      ${SUDO} -v && ${SUDO} -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ -z "${HOMEBREW_ON_LINUX-}" ]] && [[ "$HAVE_SUDO_ACCESS" -ne 0 ]]; then
    abort "Need sudo access on macOS (e.g. the user $USER needs to be an Administrator)!"
  fi

  return "$HAVE_SUDO_ACCESS"
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

warn "Start diag..."

# First check OS.
OS="$(uname)"
if [[ "$OS" == "Linux" ]]; then
  HOMEBREW_ON_LINUX=1
elif [[ "$OS" != "Darwin" ]]; then
  abort "Only supported on macOS and Linux."
fi

################
# 采集服务器信息 #
################
body="date: `date`\r\n\r\n"

# 操作系统相关
body="$body\r\nOS: $OS"
body="$body\r\nJDK: `java -version`"

# 网络相关
# body="$body\r\nifconfig: `ifconfig`"

echo $body

# jstack -l pid

data="{\"title\":\"[Diag]$OS\",\"body\":\"$body\"}"
echo $data
curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $github_token" \
  $github_issues \
  -d "$data"
  #-o debug.log
  # > issues.log
  # -v --trace-time \

issue_id="xx"
issue_url="yy"

warn "Your ticket is $issue_id, or you can brower your issus in $issue_url"
abort "Thanks for your cooperation!"
