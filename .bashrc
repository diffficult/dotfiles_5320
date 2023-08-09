#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

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


