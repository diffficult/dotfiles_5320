#!/usr/bin/env sh

# Alternative logout method to go from i3 to lightdm
# without getting kernel error
#
#  [drm:drm_atomic_helper_wait_for_dependencies [drm_kms_helper]] ERROR [CRTC:37:pipe A] flip_done timed out.
#
# using systemd through loginctl, listing sessions and terminating current session
#
#

session=`loginctl session-status | awk 'NR==1{print $1}'`
loginctl terminate-session $session
