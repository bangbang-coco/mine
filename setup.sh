#!/usr/bin/env bash
# macOS 개발자 세팅 원라이너
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/bangbang-coco/mine/main/setup.sh)
#
# 주의: `curl ... | bash` 대신 `bash <(curl ...)` 형태로 실행해야
# sudo 비밀번호/대화형 프롬프트가 동작한다.

set -euo pipefail

log() { printf '\n>>> %s\n' "$*"; }

# 기존 파일이 있으면 타임스탬프 백업 후 내용 교체
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" ]]; then
    cp -a "$target" "${target}.bak.$(date +%s)"
  fi
}

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
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

# ===== 7. dotfile 작성 =====
log "dotfile 작성 (기존 파일은 .bak.<timestamp>로 백업)"

# ----- ~/.zshrc -----
backup_if_exists "$HOME/.zshrc"
cat > "$HOME/.zshrc" <<'ZSHRC_EOF'
# ===== Homebrew =====
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# ===== History =====
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# ===== Completion =====
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ===== Key bindings =====
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# ===== Aliases =====
# macOS NFD 한글 파일명 -> NFC 정규화
nfc() { python3 -c "import sys,unicodedata;sys.stdout.buffer.write(unicodedata.normalize('NFC',sys.stdin.read()).encode())" }
ls() { command eza --icons --color=always "$@" | nfc }
ll() { command eza -la --icons --git --color=always "$@" | nfc }
la() { command eza -a --icons --color=always "$@" | nfc }
tree() { command eza --tree --icons --color=always "$@" | nfc }
alias cat='bat --paging=never'
alias g='git'
alias gs='git status'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gco='git checkout'
alias vim='nvim'
alias vi='nvim'
alias du='dust'
alias top='btm'

# ===== Plugins =====
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ===== fzf =====
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --level=2 {}'"

# ===== zoxide =====
eval "$(zoxide init zsh)"

# ===== Starship Prompt =====
eval "$(starship init zsh)"
ZSHRC_EOF

# ----- ~/.config/starship.toml -----
backup_if_exists "$HOME/.config/starship.toml"
cat > "$HOME/.config/starship.toml" <<'STARSHIP_EOF'
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = false

format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$cmd_duration\
$character"""

[directory]
style = "blue"
truncation_length = 8
truncate_to_repo = false

[character]
success_symbol = "[>](purple)"
error_symbol = "[>](red)"
vimcmd_symbol = "[<](green)"

[git_branch]
format = " [$branch]($style) "
style = "bold #cba6f7"

[git_status]
format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)"
style = "cyan"
conflicted = ""
untracked = ""
modified = ""
staged = ""
renamed = ""
deleted = ""
stashed = ""

[git_state]
format = '\([$state( $progress_current/$progress_total)]($style)\) '
style = "bright-black"

[cmd_duration]
min_time = 500
format = "[$duration]($style) "
style = "yellow"

[python]
format = "[$virtualenv]($style) "
style = "bright-black"
detect_extensions = []
detect_files = []

[package]
disabled = true

[aws]
disabled = true

[gcloud]
disabled = true

[azure]
disabled = true

[nodejs]
disabled = true

[rust]
disabled = true

[golang]
disabled = true

[docker_context]
disabled = true

[kubernetes]
disabled = true
STARSHIP_EOF

# ----- ~/.config/ghostty/config -----
backup_if_exists "$HOME/.config/ghostty/config"
cat > "$HOME/.config/ghostty/config" <<'GHOSTTY_EOF'
# ===== 셸 =====
command = /bin/zsh --login
working-directory = home

# ===== 폰트 =====
font-family = "MesloLGS Nerd Font"
font-family = "D2CodingLigature Nerd Font"
font-size = 14
font-thicken = true
# 한글 -> D2Coding
font-codepoint-map = U+AC00-U+D7AF=D2CodingLigature Nerd Font
font-codepoint-map = U+1100-U+11FF=D2CodingLigature Nerd Font
font-codepoint-map = U+3130-U+318F=D2CodingLigature Nerd Font
# Nerd Font 아이콘 -> MesloLGS (fallback 방지)
font-codepoint-map = U+E000-U+F8FF=MesloLGS Nerd Font
font-codepoint-map = U+F0000-U+FFFFF=MesloLGS Nerd Font
font-codepoint-map = U+100000-U+10FFFF=MesloLGS Nerd Font

# ===== 테마 =====
theme = light:catppuccin latte,dark:catppuccin mocha

# ===== SSH 호환성 =====
term = xterm-256color
shell-integration-features = sudo,title

# ===== 창 설정 =====
window-inherit-working-directory = false
tab-inherit-working-directory = false
split-inherit-working-directory = false
macos-titlebar-style = tabs
window-padding-x = 12
window-padding-y = 12
window-height = 35
window-width = 140

# ===== Quick Terminal (Cmd+` 토글) =====
keybind = global:cmd+grave_accent=toggle_quick_terminal
quick-terminal-position = bottom
quick-terminal-animation-duration = 0.15

# ===== 클립보드 =====
clipboard-read = allow
clipboard-write = allow
clipboard-paste-bracketed-safe = false
clipboard-paste-protection = true
copy-on-select = clipboard
keybind = shift+insert=paste_from_clipboard
keybind = cmd+v=paste_from_clipboard

# ===== 선택 =====
selection-word-chars = @#;      '"│`|:,()[]{}<>$

# ===== 커서 =====
cursor-style = bar

# ===== 키보드 =====
macos-option-as-alt = true

# ===== 스크롤 =====
scrollback-limit = 100000000
keybind = shift+page_up=scroll_page_up
keybind = shift+page_down=scroll_page_down

# ===== 기타 =====
confirm-close-surface = false
desktop-notifications = true
bell-features = system,attention,title
notify-on-command-finish = unfocused
notify-on-command-finish-action = no-bell,notify
notify-on-command-finish-after = 5s

unfocused-split-opacity = 0.7
split-divider-color = #666666

#background-opacity = 0.9
#background-blur = 16
GHOSTTY_EOF

# ----- ~/.config/tmux/tmux.conf -----
backup_if_exists "$HOME/.config/tmux/tmux.conf"
cat > "$HOME/.config/tmux/tmux.conf" <<'TMUX_EOF'
# ===== Prefix 변경 (Ctrl+B -> Ctrl+A) =====
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# ===== 기본 설정 =====
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -sg escape-time 0
set -g focus-events on
set -g status-interval 5

# ===== 창 분할 =====
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %
bind c new-window -c "#{pane_current_path}"

# ===== 패널 이동 (vim 스타일) =====
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# ===== 패널 크기 조절 =====
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# 설정 리로드
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

# ===== 복사 모드 (vi) =====
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"

# ===== 상태바 (Catppuccin Mocha) =====
set -g status-position top
set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
set -g status-left "#[bg=#89b4fa,fg=#1e1e2e,bold] #S #[bg=#1e1e2e] "
set -g status-left-length 30
set -g status-right "#[fg=#a6adc8]%Y-%m-%d #[fg=#cdd6f4,bold]%H:%M "
set -g status-right-length 40

setw -g window-status-format "#[fg=#6c7086] #I:#W "
setw -g window-status-current-format "#[bg=#313244,fg=#89b4fa,bold] #I:#W "

set -g pane-border-style "fg=#313244"
set -g pane-active-border-style "fg=#89b4fa"

set -g message-style "bg=#313244,fg=#cdd6f4"
TMUX_EOF

# ===== 8. 기본 셸 zsh =====
log "기본 셸 zsh"
if [[ "$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh || echo "chsh 실패 - 수동으로 'chsh -s /bin/zsh' 실행."
fi

# ===== 9. Git 설정 (user.name/email은 따로) =====
log "Git 설정"
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

# ===== 10. Python (uv) =====
log "Python (uv)"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ===== 완료 =====
cat <<'DONE'

=== 설치 완료 ===
dotfile은 자동 작성됐다 (기존 파일은 *.bak.<timestamp>로 백업).

남은 수동 작업:
  1. 새 터미널 열기
  2. git config --global user.name "이름"
     git config --global user.email "이메일"
  3. ssh-keygen -t ed25519 -C "이메일" (필요 시)
  4. macOS 시스템 환경설정 (README 섹션 0 참고)
  5. Neovim lazy.nvim 플러그인 설정 (README 섹션 8-5 참고)
DONE
