#!/bin/bash

pkg="edu.asu.jmc.shutdown-hook-xsan"

# unload the daemon using launchctl 2.0 syntax
rmPkgDaemon() {
	local file=$1 # Launchd file to process.
	local domain=${2:-system} # Optional launchd domain for the service defaults to system

	[[ -z "$file" ]] && { echo "${FUNCNAME}(): Launchd file name not specified"; return 1; }

	name=$(defaults read "$file" Label)

	[[ -z "$name" ]] && { echo "${FUNCNAME}(): Launchd service name not found"; return 1; }

	echo "Stopping Service: $domain/$name"

	# Send a SIGKILL to the daemon to stop it without running it's shutdown hook.
	launchctl kill SIGKILL $domain/$name
	launchctl disable $domain/$name
}

# Get list of files in package and remove them
rmPkgFiles() {
	local name=$1 # Launchd file to process.

	[[ -z "$name" ]] && { echo "${FUNCNAME}(): Package name not specified"; exit 1; }

	pkginfo=$(pkgutil --pkg-info-plist $name)
	local volume=$(/usr/libexec/PlistBuddy -c 'print :volume' /dev/stdin <<< $pkginfo)
	local location=$(/usr/libexec/PlistBuddy -c 'print :install-location' /dev/stdin <<< $pkginfo)
	for file in $(pkgutil --only-files --files $name); do
		[[ -z "$file" ]] && continue
		local fullpath="${volume}${location}/${file}"
		# Strip extra slashes from constructed path
		fullpath="$(echo "${fullpath}" | tr -s /)"
		if [[ "$(dirname "$fullpath")" == "/Library/LaunchDaemons" ]]; then
			rmPkgDaemon "$fullpath"
		fi

		rm -f "$fullpath"
		unset fullpath
	done
}

installed=$(pkgutil --pkgs=$pkg)

for i in $installed; do
	echo "Removing files for Package: $installed"
	rmPkgFiles $i
	pkgutil --forget $i
done
