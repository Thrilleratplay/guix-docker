#!/usr/bin/env sh

#############################################################################

# git ls-remote -h https://git.savannah.gnu.org/git/guix.git |grep 'refs/heads/master$' |awk '{ print $1 }'

COMMIT_ID="${COMMIT_ID}"
BUILD_FOR_SYSTEM="${BUILD_FOR_SYSTEM:=i686-linux}"

#############################################################################

# Start Guix daemon
/root/.config/guix/current/bin/guix-daemon --build-users-group=guixbuild --disable-chroot &

sleep 2

# Pull specific commit
guix pull --system=$BUILD_FOR_SYSTEM --commit=$COMMIT_ID


# Create docker pack based on coreboot_packages.scm manifest
guix pack -f docker \
          --compression=xz \
          --system=$BUILD_FOR_SYSTEM \
          --save-provenance \
          --manifest=/scripts/coreboot_packages.scm


# move created pack to volume directory /output/
find /gnu/store/ -maxdepth 1 -name "*-docker-pack.*xz" -exec mv {} /output/coreboot-build.xz \;
