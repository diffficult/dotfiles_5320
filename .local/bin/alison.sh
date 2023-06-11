#!/bin/bash

command_path="/opt/alison-desktop/bin/Alison-Desktop"
ALISON_PID="/tmp/alison.pid"

if [ -x "$command_path" ]; then
  nohup "$command_path" >/dev/null 2>&1 &
  disown
  echo "$!" > "$ALISON_PID"
  clear
  echo "Alison Desktop running in background. PID: $(cat "$ALISON_PID")"
else
  echo "Command not found or executable: $command_path"
fi
