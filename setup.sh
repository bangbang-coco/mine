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

# ----- ~/.config/nvim/init.lua -----
backup_if_exists "$HOME/.config/nvim/init.lua"
cat > "$HOME/.config/nvim/init.lua" <<'NVIM_INIT_EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")

-- Plugins
require("lazy").setup("plugins")
NVIM_INIT_EOF

# ----- ~/.config/nvim/lua/plugins/colorscheme.lua -----
backup_if_exists "$HOME/.config/nvim/lua/plugins/colorscheme.lua"
cat > "$HOME/.config/nvim/lua/plugins/colorscheme.lua" <<'NVIM_COLOR_EOF'
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        treesitter = true,
        telescope = { enabled = true },
        mini = { enabled = true },
        gitsigns = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      local ok, _ = pcall(vim.cmd.colorscheme, "catppuccin")
      if not ok then
        vim.cmd.colorscheme("habamax")
      end
    end,
  },
}
NVIM_COLOR_EOF

# ----- ~/.config/nvim/lua/plugins/editor.lua -----
backup_if_exists "$HOME/.config/nvim/lua/plugins/editor.lua"
cat > "$HOME/.config/nvim/lua/plugins/editor.lua" <<'NVIM_EDITOR_EOF'
return {
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in buffer" },
    },
    config = function()
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "fzf")
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File explorer" },
    },
    opts = {
      filesystem = { follow_current_file = { enabled = true } },
    },
  },

  -- Which key
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

  -- Autopairs
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- Comment
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment line" },
      { "gc", mode = "v", desc = "Comment selection" },
    },
    opts = {},
  },

  -- Git signs
  { "lewis6991/gitsigns.nvim", event = { "BufReadPre", "BufNewFile" }, opts = {} },

  -- Surround
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },
}
NVIM_EDITOR_EOF

# ----- ~/.config/nvim/lua/plugins/ui.lua -----
backup_if_exists "$HOME/.config/nvim/lua/plugins/ui.lua"
cat > "$HOME/.config/nvim/lua/plugins/ui.lua" <<'NVIM_UI_EOF'
return {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = { options = { theme = "auto" } },
  },

  -- Buffer line
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        offsets = {
          { filetype = "neo-tree", text = "Explorer", highlight = "Directory" },
        },
      },
    },
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
    },
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- Notifications
  {
    "rcarriga/nvim-notify",
    opts = { timeout = 2000, render = "compact" },
  },
}
NVIM_UI_EOF

# ----- ~/.config/nvim/lua/plugins/lsp.lua -----
backup_if_exists "$HOME/.config/nvim/lua/plugins/lsp.lua"
cat > "$HOME/.config/nvim/lua/plugins/lsp.lua" <<'NVIM_LSP_EOF'
return {
  -- Mason
  { "mason-org/mason.nvim", opts = {} },

  -- Mason-lspconfig
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = { "lua_ls", "pyright", "ruff" },
    },
  },

  -- LSP config
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "Go to references")
          map("K", vim.lsp.buf.hover, "Hover")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").setup({})
      require("nvim-treesitter").install({
        "lua", "python", "bash", "json", "yaml", "toml",
        "markdown", "markdown_inline", "vim", "vimdoc",
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
}
NVIM_LSP_EOF

log "Neovim 플러그인 사전 설치 (headless)"
if command -v nvim >/dev/null 2>&1; then
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || echo "lazy sync 실패 - 첫 nvim 실행 시 자동 재시도됨."
fi

# ===== 8. 기본 셸 zsh =====
log "기본 셸 zsh"
if [[ "$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh || echo "chsh 실패 - 수동으로 'chsh -s /bin/zsh' 실행."
fi

# ===== 9. Python (uv) =====
log "Python (uv)"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ===== 완료 =====
cat <<'DONE'

=== 설치 완료 ===
dotfile과 Neovim 설정은 자동 작성됐다 (기존 파일은 *.bak.<timestamp>로 백업).

남은 수동 작업:
  - macOS 시스템 환경설정 (README 섹션 0 참고)
  - 새 터미널 열기 (셸 변경 적용)
DONE
