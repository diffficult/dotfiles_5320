#!/bin/bash

# Find out the state of bluetooth
if rfkill list bluetooth | grep -q "Soft blocked: no"; then
    # if it's not soft-blocked, then block it
    rfkill block bluetooth
else
    # if it's soft-blocked, then unblock it
    rfkill unblock bluetooth
fi
