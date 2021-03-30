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
guix pull --system=$BUILD_FOR_SYSTEM --commit="$COMMIT_ID"

# update profile
export GUIX_PROFILE="/root/.config/guix/current"
# shellcheck disable=SC1091
. "/root/.config/guix/current/etc/profile"

# Find date of commit.
# shellcheck disable=SC2012
LATEST_CHECKOUT=$(ls --group-directories-first -t /root/.cache/guix/checkouts/ | head -n1)
cd "/root/.cache/guix/checkouts/$LATEST_CHECKOUT/" || exit
CREATED_DATETIME=$(TZ=UTC git show --date=iso-strict-local --pretty='%cd' "$COMMIT_ID" | head -n1)

# Create tarball pack based on coreboot_packages.scm manifest
guix pack -f tarball \
          --compression=none \
          --system=$BUILD_FOR_SYSTEM \
          --save-provenance \
          --no-grafts \
          --manifest=/scripts/coreboot_packages.scm

# TODO: SHA256 original output and store somewhere in image

TARBALL=$(find /gnu/store/ -maxdepth 1 -name "*-pack.tar");

python3 /scripts/pack2dockerImage.py --tarball "$TARBALL" --date "$CREATED_DATETIME" --commit "$COMMIT_ID"
