#!/bin/bash -e

###
# Description: Script to move the glusterfs initial setup to bind mounted directories of Atomic Host.
# Copyright (c) 2016 Red Hat, Inc. <http://www.redhat.com>
#
# This file is part of GlusterFS.
#
# This file is licensed to you under your choice of the GNU Lesser
# General Public License, version 3 or any later version (LGPLv3 or
# later), or the GNU General Public License, version 2 (GPLv2), in all
# cases as published by the Free Software Foundation.
###

DIRS_TO_RESTORE="/etc/glusterfs /var/log/glusterfs /var/lib/glusterd"
FSTAB=${FSTAB-/var/lib/heketi/fstab}
ENABLE_NTPD="${ENABLE_NTPD-yes}"
ENABLE_SSHD="${ENABLE_SSHD-no}"
ENABLE_RPCBIND="${ENABLE_RPCBIND-yes}"

err() {
  echo -ne $* 1>&2
}

enable_start_unit_if_env() {
    local unit="$1"
    local env_var="$1"
    case ${env_var,,} in
        yes|y|true|t)
            echo "Enable and start $unit"
            systemctl enable $unit
            systemctl start $unit
            ;;
    esac
}

main () {
  if [ -f "$FSTAB" ]
  then
    if ! mount -a --fstab "$FSTAB"
    then
      err "mount failed"
      exit 1
    fi
    echo "Mount Successful"
  else
    echo "fstab file $FSTAB not found"
  fi

  for dir in $DIRS_TO_RESTORE
  do
    if test "$(ls $dir)"
    then
      echo "$dir is not empty"
    else
      if ! cp -r ${dir}_bkp/* $dir
      then
        err "Failed to copy $dir"
        exit 1
      fi
    fi
  done

  enable_start_unit_if_env rpcbind.service "$ENABLE_RPCBIND"
  enable_start_unit_if_env ntpd.service "$ENABLE_NTPD"
  enable_start_unit_if_env sshd.service "$ENABLE_SSHD"

  echo "Script Ran Successfully"
}

main
