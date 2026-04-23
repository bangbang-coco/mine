# macOS 개발자 세팅 가이드

> 새 Mac을 사서 박스 뜯은 직후부터, 개발 가능한 상태까지 한 번에 세팅하는 가이드.
> Apple Silicon (M1/M2/M3/M4/M5) 기준. 2026년 4월 기준 최신.

---

## 빠른 설치 (TL;DR)

한 줄로 전체 세팅:

```bash
curl -fsSL https://raw.githubusercontent.com/bangbang-coco/mine/main/setup.sh | bash
```

이 스크립트가 자동으로 처리하는 것:

- Xcode Command Line Tools, Homebrew
- CLI 도구 (neovim, starship, fzf, zoxide, bat, eza, fd, ripgrep, tmux, lazygit, git-delta 등)
- GUI 앱 (Ghostty, Raycast, Alt-Tab, Stats)
- Nerd Font (MesloLGS, D2CodingLigature)
- 기본 셸 zsh 변경
- Git 기본 설정 (pull.rebase, delta pager 등)
- Python 패키지 매니저 `uv`

수동으로 해야 하는 것:

- dotfile 복사 (`~/.zshrc`, `~/.config/starship.toml`, `~/.config/ghostty/config`, `~/.config/tmux/tmux.conf`) - 섹션 8 참고
- `git config --global user.name` / `user.email`
- SSH 키 생성 (섹션 10)
- macOS 시스템 환경설정 (섹션 0)

각 단계를 상세하게 이해하고 싶으면 아래 섹션 0부터 순서대로 읽는다.

---

## 0. macOS 기본 설정

맥 초기 설정 마법사 완료 후, 시스템 설정에서 아래 항목을 먼저 잡는다.

### 키보드

```
시스템 설정 > 키보드
- 키 반복 속도: 최대 (가장 빠름)
- 반복 지연 시간: 최소 (가장 짧음)
- 지구본 키 동작: "아무것도 하지 않음" (터미널에서 Fn 키 충돌 방지)
```

### Dock

```
시스템 설정 > 데스크탑 및 Dock
- 크기: 작게
- 자동으로 Dock 가리기: 켜기
- 최근 앱 표시: 끄기
- 기본 웹 브라우저: Chrome (개발용)
```

### Finder

```
Finder > 설정 (Cmd + ,)
- 새 Finder 윈도우: 홈 디렉토리
- 확장자 항상 표시: 켜기
- 폴더 우선 정렬: 켜기

Finder > 보기 > 경로 막대 보기 (Cmd + Option + P)
Finder > 보기 > 상태 막대 보기 (Cmd + /)
```

### 트랙패드

```
시스템 설정 > 트랙패드
- 탭하여 클릭: 켜기
- 이동 속도: 최대
```

### 기타

```bash
# 숨김 파일 표시 (Finder에서 Cmd + Shift + .)
defaults write com.apple.finder AppleShowAllFiles -bool true

# 스크린샷 저장 위치 변경
mkdir -p ~/Screenshots
defaults write com.apple.screencapture location ~/Screenshots

# .DS_Store 네트워크 드라이브에 생성 금지
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Finder 재시작 (위 설정 반영)
killall Finder
```

---

## 1. Xcode Command Line Tools

Homebrew 설치 전에 반드시 먼저 설치한다.

```bash
xcode-select --install
```

팝업이 뜨면 "설치" 클릭. 수 분 소요.

---

## 2. Homebrew 설치

macOS 패키지 매니저. 이후 모든 도구 설치의 기반.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치 후 셸에 등록:

```bash
# 터미널에 아래 두 줄 붙여넣기 (설치 완료 메시지에도 나옴)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

확인:

```bash
brew --version
```

---

## 3. 셸 변경 (bash -> zsh)

macOS Catalina(10.15) 이후 기본 셸은 zsh이지만, 혹시 bash라면 변경한다.

```bash
# 현재 셸 확인
echo $SHELL

# zsh로 변경
chsh -s /bin/zsh
```

새 터미널을 열면 zsh로 동작한다.

---

## 4. 터미널 에뮬레이터: Ghostty

macOS 기본 Terminal.app 대신 Ghostty를 사용한다. GPU 가속, 분할 창, 테마 지원.

```bash
brew install --cask ghostty
```

### Ghostty 설정

```bash
mkdir -p ~/.config/ghostty
```

`~/.config/ghostty/config` 파일 생성:

```
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
# 시스템 다크/라이트 모드에 자동 연동
theme = light:catppuccin latte,dark:catppuccin mocha

# ===== SSH 호환성 =====
term = xterm-256color
shell-integration-features = sudo,title

# ===== 창 설정 =====
# 새 탭/창/split 열 때 항상 ~ 에서 시작
window-inherit-working-directory = false
tab-inherit-working-directory = false
split-inherit-working-directory = false
macos-titlebar-style = tabs
window-padding-x = 12
window-padding-y = 12
window-height = 35
window-width = 140

# ===== Quick Terminal (Cmd + ` 으로 토글) =====
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
# 더블클릭 단어 선택 시 구분자 (기본값 + @;# 추가)
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

# 비활성 창 흐리게
unfocused-split-opacity = 0.7
split-divider-color = #666666

# ===== 배경 투명도 (취향에 따라 주석 해제) =====
#background-opacity = 0.9
#background-blur = 16
```

### Ghostty 단축키

| 단축키 | 동작 |
|--------|------|
| `Cmd + `` ` | Quick Terminal 토글 |
| `Cmd + D` | 세로 분할 |
| `Cmd + Shift + D` | 가로 분할 |
| `Cmd + [` / `Cmd + ]` | 분할 패널 이동 |
| `Cmd + T` | 새 탭 |
| `Cmd + W` | 탭/패널 닫기 |

---

## 5. Nerd Font 설치

터미널 아이콘 표시에 필요. Ghostty 설정에서 참조하는 폰트.

```bash
brew install --cask font-meslo-lg-nerd-font font-d2coding-nerd-font
```

| 폰트 | 용도 |
|-------|------|
| MesloLGS Nerd Font | 영문 기본 (Powerline/아이콘 지원) |
| D2CodingLigature Nerd Font | 한글 기본 + 한글 codepoint-map 지정 |

---

## 6. CLI 도구 일괄 설치

### 필수 도구

```bash
brew install neovim starship fzf zoxide bat eza fd ripgrep jq tmux htop tlrc wget lazygit
```

### 추가 도구

```bash
brew install git-delta dust bottom gh yazi
```

### zsh 플러그인

```bash
brew install zsh-autosuggestions zsh-syntax-highlighting
```

### 도구 설명

| 도구 | 대체 대상 | 설명 |
|------|-----------|------|
| **neovim** | vim | 모던 에디터 (Lua 기반 플러그인) |
| **starship** | PS1 | 크로스셸 커스텀 프롬프트 (git, 언어 버전 표시) |
| **fzf** | - | 퍼지 검색 (`Ctrl+R` 히스토리, `Ctrl+T` 파일) |
| **zoxide** | cd | 자주 가는 디렉토리 학습 (`z` 명령어) |
| **bat** | cat | 구문 강조 + 줄 번호 |
| **eza** | ls | 아이콘, git 상태, 트리 지원 |
| **fd** | find | 직관적 문법, .gitignore 자동 반영 |
| **ripgrep** | grep | 초고속 코드 검색 |
| **jq** | - | JSON 파서/필터 |
| **tmux** | - | 터미널 멀티플렉서 (세션 유지, 창 분할) |
| **htop** | top | 대화형 프로세스 모니터 |
| **tlrc** | man | 명령어 요약 도움말 (tldr의 Rust 버전) |
| **lazygit** | git CLI | 터미널 Git UI (커밋, 브랜치, 리베이스) |
| **git-delta** | diff | side-by-side diff, 라인넘버, 구문 강조 |
| **dust** | du | 디스크 사용량 시각화 |
| **bottom (btm)** | top/htop | 그래프 기반 시스템 모니터 |
| **gh** | - | GitHub CLI (PR, issue, Actions 관리) |
| **yazi** | - | 터미널 파일 매니저 (미리보기 지원) |

---

## 7. GUI 앱 설치

```bash
brew install --cask raycast alt-tab stats
```

| 앱 | 용도 | 비고 |
|----|------|------|
| **Raycast** | Spotlight 대체 런처 | 클립보드 히스토리, 스니펫, 창 관리 통합 |
| **Alt-Tab** | 윈도우 스타일 앱 전환 | 미리보기 썸네일 표시 |
| **Stats** | 메뉴바 시스템 모니터 | CPU, 메모리, 네트워크, 디스크 실시간 표시 |

---

## 8. 설정 파일 작성

### 8-1. Zsh (~/.zshrc)

```bash
# ===== Homebrew =====
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# ===== History =====
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # 세션 간 히스토리 공유
setopt HIST_IGNORE_DUPS       # 연속 중복 제거
setopt HIST_IGNORE_SPACE      # 스페이스로 시작하면 히스토리 제외

# ===== Completion =====
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select               # 화살표로 선택
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # 대소문자 무시

# ===== Key bindings =====
bindkey -e                                # Emacs 모드
bindkey '^[[A' history-search-backward    # 위 화살표: 히스토리 역검색
bindkey '^[[B' history-search-forward     # 아래 화살표: 히스토리 순검색

# ===== Aliases (모던 CLI) =====
# macOS NFD 한글 파일명 -> NFC 정규화 (D2Coding 호환)
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
```

### 8-2. Starship (~/.config/starship.toml)

```bash
mkdir -p ~/.config
```

```toml
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

# 불필요한 모듈 비활성화
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
```

### 8-3. Git (~/.gitconfig)

```bash
git config --global user.name "이름"
git config --global user.email "이메일"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global rerere.enabled true
git config --global diff.algorithm histogram
git config --global merge.conflictstyle zdiff3

# git-delta (diff 뷰어)
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.dark true
git config --global delta.line-numbers true
git config --global delta.side-by-side true
```

완성된 `~/.gitconfig`:

```gitconfig
[user]
    name = 이름
    email = 이메일
[init]
    defaultBranch = main
[pull]
    rebase = true
[rerere]
    enabled = true
[diff]
    algorithm = histogram
[merge]
    conflictstyle = zdiff3
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    dark = true
    line-numbers = true
    side-by-side = true
```

### 8-4. tmux (~/.config/tmux/tmux.conf)

```bash
mkdir -p ~/.config/tmux
```

```bash
# ===== Prefix 변경 (Ctrl+B -> Ctrl+A) =====
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# ===== 기본 설정 =====
set -g mouse on                  # 마우스 지원
set -g base-index 1              # 창 번호 1부터
setw -g pane-base-index 1        # 패널 번호 1부터
set -g renumber-windows on       # 창 닫으면 번호 재정렬
set -g history-limit 50000       # 스크롤백 버퍼
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -sg escape-time 0            # ESC 딜레이 제거
set -g focus-events on
set -g status-interval 5

# ===== 창 분할 (직관적 키) =====
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# 새 창도 현재 경로 유지
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

# ===== 복사 모드 (vi 스타일) =====
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"

# ===== 상태바 (Catppuccin Mocha 톤) =====
set -g status-position top
set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
set -g status-left "#[bg=#89b4fa,fg=#1e1e2e,bold] #S #[bg=#1e1e2e] "
set -g status-left-length 30
set -g status-right "#[fg=#a6adc8]%Y-%m-%d #[fg=#cdd6f4,bold]%H:%M "
set -g status-right-length 40

# 윈도우 탭 스타일
setw -g window-status-format "#[fg=#6c7086] #I:#W "
setw -g window-status-current-format "#[bg=#313244,fg=#89b4fa,bold] #I:#W "

# 패널 구분선
set -g pane-border-style "fg=#313244"
set -g pane-active-border-style "fg=#89b4fa"

# 메시지 스타일
set -g message-style "bg=#313244,fg=#cdd6f4"
```

### 8-5. Neovim (lazy.nvim)

lazy.nvim 기반 커스텀 설정. catppuccin 테마, LSP, 자동완성, Telescope 등 포함.

```bash
# 디렉토리 생성
mkdir -p ~/.config/nvim/lua/plugins
```

설정 파일 구조:

```
~/.config/nvim/
  init.lua              # 기본 옵션 + lazy.nvim 부트스트랩
  lua/plugins/
    colorscheme.lua     # catppuccin mocha 테마
    editor.lua          # telescope, neo-tree, which-key, gitsigns 등
    ui.lua              # lualine, bufferline, indent-blankline
    lsp.lua             # mason, lspconfig, nvim-cmp, treesitter
```

첫 실행 시 lazy.nvim이 플러그인 자동 설치:

```bash
nvim
```

주요 키바인드:

| 키 | 동작 |
|----|------|
| `Space + e` | 파일 탐색기 (Neo-tree) |
| `Space + ff` | 파일 검색 (Telescope) |
| `Space + fg` | 코드 검색 (live grep) |
| `gd` | 정의로 이동 |
| `gr` | 참조 찾기 |
| `K` | 호버 문서 |
| `Space + ca` | 코드 액션 |
| `Space + rn` | 이름 변경 |
| `Shift + H/L` | 이전/다음 버퍼 탭 |
| `y` | 선택 복사 (macOS 클립보드 연동) |

> 설정 파일 전문은 GitHub 저장소 참고: (링크 추가 예정)

---

## 9. 개발 언어/런타임 설치

### Python (uv)

```bash
# uv 설치 (pip/venv 대체, Rust 기반 초고속)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 사용법
uv init myproject          # 새 프로젝트
uv add requests            # 의존성 추가
uv run python main.py      # 실행
uv run pytest              # 테스트
```

### Node.js

```bash
brew install node@22
```

또는 버전 관리가 필요하면:

```bash
# fnm (Fast Node Manager)
brew install fnm
echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >> ~/.zshrc
fnm install 22
fnm default 22
```

### Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Go

```bash
brew install go
```

### Docker

```bash
brew install --cask docker
```

Docker Desktop 실행 후 초기 설정 완료.

---

## 10. SSH 키 생성

```bash
# Ed25519 키 생성 (RSA보다 빠르고 안전)
ssh-keygen -t ed25519 -C "이메일@example.com"

# ssh-agent에 등록
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 공개키 복사 (GitHub 등에 등록)
pbcopy < ~/.ssh/id_ed25519.pub
```

GitHub에 등록:

```bash
gh auth login
```

---

## 11. 단축키 요약

### Ghostty

| 단축키 | 동작 |
|--------|------|
| `Cmd + `` ` | Quick Terminal 토글 |
| `Cmd + D` | 세로 분할 |
| `Cmd + Shift + D` | 가로 분할 |

### tmux (prefix = Ctrl+A)

| 단축키 | 동작 |
|--------|------|
| `prefix + \|` | 세로 분할 |
| `prefix + -` | 가로 분할 |
| `prefix + h/j/k/l` | 패널 이동 |
| `prefix + c` | 새 창 |
| `prefix + 1~9` | 창 전환 |
| `prefix + r` | 설정 리로드 |
| `prefix + d` | 세션 분리 (detach) |
| `tmux a` | 세션 재접속 (attach) |

### fzf

| 단축키 | 동작 |
|--------|------|
| `Ctrl + R` | 히스토리 퍼지 검색 |
| `Ctrl + T` | 파일 퍼지 검색 (bat 미리보기) |
| `Alt + C` | 디렉토리 이동 (tree 미리보기) |

### CLI 명령어

| 명령어 | 동작 |
|--------|------|
| `z <경로>` | 스마트 디렉토리 이동 (zoxide) |
| `lazygit` | 터미널 Git UI |
| `yazi` | 터미널 파일 매니저 |
| `btm` | 시스템 모니터 |
| `tldr <명령어>` | 명령어 요약 도움말 |

---

## 12. 전체 설치 원라이너 (자동화)

위 과정을 한 번에 실행하는 스크립트. 새 Mac에서 복붙하면 된다.

```bash
#!/bin/bash
set -e

echo ">>> Xcode CLI Tools"
xcode-select --install 2>/dev/null || true

echo ">>> Homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

echo ">>> CLI 도구"
brew install neovim starship fzf zoxide bat eza fd ripgrep jq tmux htop tlrc wget lazygit git-delta dust bottom gh yazi zsh-autosuggestions zsh-syntax-highlighting

echo ">>> GUI 앱"
brew install --cask ghostty raycast alt-tab stats

echo ">>> Nerd Font"
brew install --cask font-meslo-lg-nerd-font font-d2coding-nerd-font

echo ">>> Neovim (lazy.nvim)"
mkdir -p ~/.config/nvim/lua/plugins
# init.lua와 플러그인 설정 파일은 별도 복사 필요 (위 8-5 참고)

echo ">>> 기본 셸 zsh 변경"
chsh -s /bin/zsh

echo ">>> Git 설정"
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

echo ">>> Python (uv)"
curl -LsSf https://astral.sh/uv/install.sh | sh

echo ""
echo "=== 완료! ==="
echo "1. 새 터미널을 열어주세요"
echo "2. ~/.zshrc, ~/.config/starship.toml, ~/.config/ghostty/config, ~/.config/tmux/tmux.conf 설정 파일을 복사해주세요"
echo "3. git config --global user.name / user.email 설정해주세요"
```

---

## 부록: Homebrew 관리

```bash
brew update           # Homebrew 자체 업데이트
brew upgrade          # 설치된 패키지 전체 업그레이드
brew outdated         # 업데이트 가능한 패키지 목록
brew cleanup          # 캐시/구버전 정리
brew list             # 설치된 패키지 목록
brew info <패키지>     # 패키지 정보
```
