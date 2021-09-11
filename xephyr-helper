#!/bin/bash
#
# Reflect changes in any Xephyr window clipboard to the $DISPLAY (main)
# X server clipboard, and vice-versa; also ensure all Xephyr windows have the
# correct internal bounds (for click mapping) by perodically running xrandr
# on them.
#
# To allow bi-directional clipboard reflection, create (touch) both sentinel files:
#   ~/.main_clipboard_read_ok and
#   ~/.main_clipboard_write_ok
# For a more restrictive approach, create only one (or neither), as required.
#
# Should be run as the regular user, in the top-level (containing) display
# and ideally autostarted on login.
#
# Copyright (c) 2018 sakaki <sakaki@deciban.com>
#
# License (GPL v3.0)
# ------------------
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

declare -A CLIPBOARDS
declare -a XEPHYRS
CONTENT=""

# the following two sentinel files can be used to control
# whether the main desktop clipboard is readable (and so
# reflected into Xephyr windows) and writeable (and so
# can reflect the clipboard from Xephyr windows)
# respectively
READ_MAIN_CLIPBOARD_OK="$HOME/.main_clipboard_read_ok"
WRITE_MAIN_CLIPBOARD_OK="$HOME/.main_clipboard_write_ok"

locate_and_rescale_xephyr_displays() {
	declare -a xephyrs
	local display
	xephyrs=($(pgrep -u $(id -u) -a Xephyr | egrep -o "[[:digit:]]+$"))
	for display in ${xephyrs[@]}; do
		if [[ ! " ${XEPHYRS[@]} " =~ " $display " ]]; then
			# new xephyr display
			# initialize it from the main display's clipboard, if allowed
			if [[ -f "$READ_MAIN_CLIPBOARD_OK" ]]; then
				xsel --output --clipboard --display "$DISPLAY" | \
					xsel --input --clipboard --display ":$display"
			fi
		fi
	done
	for display in ${XEPHYRS[@]}; do
		if [[ ! " ${xephyrs[@]} " =~ " $display " ]]; then
			# closed xephyr display
			unset CLIPBOARDS[$display]
		fi
	done
	XEPHYRS=(${xephyrs[@]})
	# now ensure the window size of all Xephyr displays is correct
	for display in ${XEPHYRS[@]}; do
		xrandr --display ":$display" &>/dev/null
	done
}

snapshot_clipboards() {
	local display
	# X displays are of format :<number>
	# we drop the prefix colon when using as an associative array key
	if [[ -f "$READ_MAIN_CLIPBOARD_OK" ]]; then
		CLIPBOARDS[${DISPLAY#:}]="$(xsel --output --clipboard --display "$DISPLAY")"
	fi
	for display in ${XEPHYRS[@]}; do
		CLIPBOARDS[$display]="$(xsel --output --clipboard --display ":$display")"
	done
}

set_all_clipboards_to() {
	local display
	CONTENT="$1"
	for display in "${!CLIPBOARDS[@]}"; do
		CLIPBOARDS[$display]="$CONTENT"
		# update actual clipboard; note we don't use <<< here, as that
		# appends a newline
		# only reflect to main display if permitted
		if [[ ":$display" != "$DISPLAY" || -f "$WRITE_MAIN_CLIPBOARD_OK" ]]; then
			echo -n "$CONTENT" | \
				xsel --input --clipboard --display ":$display" &>/dev/null
		fi
	done
}

reflect_changes() {
	local display
	for display in "${!CLIPBOARDS[@]}"; do
		if [[ "${CLIPBOARDS[$display]}" != "$CONTENT" ]]; then
			set_all_clipboards_to "${CLIPBOARDS[$display]}"
			break
		fi
	done
}

# main program loop
renice -n 19 $$ &>/dev/null
while true; do
	locate_and_rescale_xephyr_displays
	snapshot_clipboards
	reflect_changes
	sleep 1
done
