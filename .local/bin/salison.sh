#!/bin/bash

kill $(cat /tmp/alison.pid)
clear && echo "Alison Desktop process terminated"
