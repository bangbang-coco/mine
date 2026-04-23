#!/usr/bin/env bash
# macOS 개발자 세팅 원라이너
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/bangbang-coco/mine/main/setup.sh | bash
#
# 이 스크립트는 README.md 섹션 1~9 / 12의 설치 단계를 자동화한다.
# dotfile(~/.zshrc, starship.toml, ghostty config, tmux.conf)은
# README 섹션 8의 내용을 직접 복사해야 한다.

set -euo pipefail

log() { printf '\n>>> %s\n' "$*"; }

# ===== 1. Xcode CLI Tools =====
log "Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install 2>/dev/null || true
  echo "Xcode CLI Tools 설치창이 뜨면 '설치'를 누르고 완료될 때까지 대기."
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi
echo "ok: $(xcode-select -p)"

# ===== 2. Homebrew =====
log "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
BREW_PREFIX="/opt/homebrew"
if [[ "$(uname -m)" != "arm64" ]]; then BREW_PREFIX="/usr/local"; fi
if ! grep -q "brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
  echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >> "$HOME/.zprofile"
fi
eval "$(${BREW_PREFIX}/bin/brew shellenv)"

# ===== 3. CLI 도구 =====
log "CLI 도구"
brew install \
  neovim starship fzf zoxide bat eza fd ripgrep jq tmux htop tlrc wget lazygit \
  git-delta dust bottom gh yazi \
  zsh-autosuggestions zsh-syntax-highlighting

# ===== 4. GUI 앱 =====
log "GUI 앱"
brew install --cask ghostty raycast alt-tab stats

# ===== 5. Nerd Font =====
log "Nerd Font"
brew install --cask font-meslo-lg-nerd-font font-d2coding-nerd-font

# ===== 6. 설정 디렉토리 =====
log "설정 디렉토리"
mkdir -p "$HOME/.config/nvim/lua/plugins"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/tmux"

# ===== 7. 기본 셸 zsh =====
log "기본 셸 zsh"
if [[ "$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh || echo "chsh 실패 - 수동으로 'chsh -s /bin/zsh' 실행."
fi

# ===== 8. Git 설정 =====
log "Git 설정 (사용자 이름/이메일은 따로 설정)"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global rerere.enabled true
git config --global diff.algorithm histogram
git config --global merge.conflictstyle zdiff3
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.dark true
git config --global delta.line-numbers true
git config --global delta.side-by-side true

# ===== 9. Python (uv) =====
log "Python (uv)"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ===== 완료 =====
cat <<'DONE'

=== 설치 완료 ===
남은 수동 작업:
  1. 새 터미널 열기
  2. README 섹션 8의 dotfile을 복사:
     - ~/.zshrc
     - ~/.config/starship.toml
     - ~/.config/ghostty/config
     - ~/.config/tmux/tmux.conf
  3. git config --global user.name "이름"
     git config --global user.email "이메일"
  4. ssh-keygen -t ed25519 -C "이메일" (필요 시)
DONE
