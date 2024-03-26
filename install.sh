#!/bin/sh
# shellcheck disable=SC3043

# Keep this script as short as possible _and_ optional - some
# distributions don't use it at all.
#
# The "real" installation process belongs to sof/installer/ in the
# main repo where any developer can use it and fix it.

set -e

# Default values, override on the command line
: "${FW_DEST:=/lib/firmware/intel}"
: "${FW_LOCATION:=sof-bin}"

usage()
{
    cat <<EOF
Usage example:
        sudo $0 [[v1.8.x/]v1.8]
EOF
    exit 1
}

main()
{
    test "$#" -le 1 || usage

    # Never empty, dirname returns "." instead (opengroup.org)
    local path; path=$(dirname "$1")
    local ver; #ver=$(basename "$1")
    local sdir optversuffix

    [ -z "$ver" ] || optversuffix="-$ver"

    # Do this first so we can fail immediately and not leave a
    # half-install behind
    if [ -n "$optversuffix" ]; then
        if test -e "$FW_LOCATION/sof${optversuffix}" -a -e "$FW_LOCATION/sof-tplg${optversuffix}" ; then
            : # SOF IPC3 SOF layout
        elif test -e "$FW_LOCATION/sof-ipc4${optversuffix}" -a -e "$FW_LOCATION/sof-ace-tplg${optversuffix}" ; then
            : # SOF IPC4 layout for Intel Meteor Lake (and newer)
        else
            die "Files not found or unknown FW file layout $1 \n"
        fi

        for sdir in sof sof-ipc4 sof-ipc4-tplg sof-ace-tplg sof-tplg; do
            if test -e "$FW_LOCATION/$path/$sdir${optversuffix}" ; then
                # Test workaround. Currently enough to run the whole test suite on Darwin
                case "$(uname)" in
                    Darwin) safer_ln=;;
                    *) safer_ln='--no-target-directory';;
                esac
                ( set -x; ln -s $safer_ln "$sdir-$ver" "${FW_DEST}/$sdir" ) || {
                    set +x
                    die '%s already installed? (Re)move it first.\n' "${FW_DEST}/$sdir"
                }
            fi
        done
    fi

    # Trailing slash in srcdir/ ~= srcdir/*
	rsync -a "${FW_LOCATION}/${path}"/sof*"$optversuffix" "${FW_DEST}"/
}

die()
{
    >&2 printf '%s ERROR: ' "$0"
    # We want die() to be usable exactly like printf
    # shellcheck disable=SC2059
    >&2 printf "$@"
    exit 1
}

main "$@"
