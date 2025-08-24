# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# oh-my-zsh
export ZSH="$HOME/.config/zsh/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will load a random
# theme each time Oh My Zsh is loaded, in which case, to know which specific one
# was loaded, run: echo $RANDOM_THEME See
# https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random Setting this variable
# when ZSH_THEME=random will cause zsh to load a theme from this variable
# instead of looking in $ZSH/themes/ If set to an empty array, this variable
# will have no effect. ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior zstyle
# ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls. DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for
# completion. You can also set it to another string to have that shown instead
# of the default red dots. e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1
# (see #5765) COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster. DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output. You can set one of the optional
# three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd" or set a custom format
# using the strftime function format specifications, see 'man strftime' for
# details. HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.config/zsh/.oh-my-zsh/custom

# Which plugins would you like to load? Standard plugins can be found in
# $ZSH/plugins/ Custom plugins may be added to $ZSH_CUSTOM/plugins/ Example
# format: plugins=(rails git textmate ruby lighthouse) Add wisely, as too many
# plugins slow down shell startup.
plugins=(
  git fzf branch zsh-autosuggestions zsh-syntax-highlighting bgnotify sudo
)

source $ZSH/oh-my-zsh.sh

# zsh-autosuggestions
source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting
source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# p10k
source $HOME/.config/zsh/.p10k.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions if [[ -n $SSH_CONNECTION ]];
# then export EDITOR='vim' else export EDITOR='nvim' fi

# Compilation flags export ARCHFLAGS="-arch $(uname -m)"

# ensure path is unique
typeset -U path

# define paths you care about
my_paths=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/fnm"
  "$HOME/.bun/bin"
  "$HOME/.deno/bin",
  "/opt/mssql-tools/bin"
)

# add existing paths to $path
for p in $my_paths; do
  [[ -d "$p" ]] && path=($p $path)
done

# export back to PATH string
export PATH="${(j/:/)path}"

# fnm
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env)"
fi

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# zoxide
eval "$(zoxide init zsh)"

# load aliases if file exists
[[ -f ~/.config/zsh/.zsh_aliases ]] && source ~/.config/zsh/.zsh_aliases

# load functions if file exists
[[ -f ~/.config/zsh/.zsh_functions ]] && source ~/.config/zsh/.zsh_functions

# eza vars
export EZA_ICONS_AUTO=true
export EZA_COLORS_AUTO=true

# set default editor
export SUDO_EDITOR=nvim
export EDITOR=nvim

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
