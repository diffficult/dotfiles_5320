command to link to this directory

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.config/zsh/prezto_runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

