# -------------------- GIT -------------------------------------------------------------
# Enable git auto complete
# https://git-scm.com/book/en/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh
autoload -Uz compinit && compinit
# Load version control info in the prompt
# https://git-scm.com/book/en/v2/Appendix-A%3A-Git-in-Other-Environments-Git-in-Zsh
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' formats       '(%b | %u%c%m)'
# Uncomment to enable action comment
#zstyle ':vcs_info:git:*' actionformats '(%b|%a%u%c)'

# Customize prompt
setopt PROMPT_SUBST
PROMPT='%F{green}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f $ '

# Source aliases
source ~/badal/aliases/base-aliases
source ~/badal/aliases/git-aliases

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
