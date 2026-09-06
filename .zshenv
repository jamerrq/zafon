# The one zsh file that has to live in $HOME.
#
# zsh reads ~/.zshenv before anything else and before it knows about ZDOTDIR --
# that is precisely what makes it the place to set ZDOTDIR. Everything after
# this point (.zshrc, .zprofile, history, completion dumps) is read from and
# written to $ZDOTDIR instead of $HOME, which is what keeps $HOME from
# collecting .zcompdump-<host>-<version> files on every zsh upgrade.
export ZDOTDIR="$HOME/.config/zsh"
