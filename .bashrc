#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

##
# Unlock gnome keyring
##

if [ -n "$DESKTOP_SESSION" ];then
    eval $(gnome-keyring-daemon --start)
    export SSH_AUTH_SOCK
fi


##
# Aliases #
##

# load alias/functions that works with both zsh/bash
if [[ -f ~/.aliasrc ]]; then
    source ~/.aliasrc
if

###
# Prompt
###

PS1='[\u@\h \W]\$ '


##
# Completions
##
#
source /etc/bash_completion.d/climate_completion


