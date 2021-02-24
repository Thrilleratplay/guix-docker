#!/usr/bin/env sh

#############################################################################

# git ls-remote -h https://git.savannah.gnu.org/git/guix.git |grep 'refs/heads/master$' |awk '{ print $1 }'

COMMIT_ID="${COMMIT_ID}"
BUILD_FOR_SYSTEM="${BUILD_FOR_SYSTEM:=i686-linux}"

DOCKER_IMAGE_NAME="coreboot-base-env"

#############################################################################

# Start Guix daemon
/root/.config/guix/current/bin/guix-daemon --build-users-group=guixbuild --disable-chroot &

sleep 2

# Pull specific commit
guix pull --system=$BUILD_FOR_SYSTEM --commit="$COMMIT_ID"

# update profile
exoprt GUIX_PROFILE="/root/.config/guix/current"
# shellcheck disable=SC1091
. "/root/.config/guix/current/etc/profile"

# Find date of commit.
# shellcheck disable=SC2012
LATEST_CHECKOUT=$(ls --group-directories-first -t /root/.cache/guix/checkouts/ | head -n1)
cd "/root/.cache/guix/checkouts/$LATEST_CHECKOUT/" || exit
CREATED_DATETIME=$(TZ=UTC git show --date=iso-strict-local --pretty='%cd' "$COMMIT_ID" | head -n1)

# Create docker pack based on coreboot_packages.scm manifest
guix pack -f docker \
          --compression=none \
          -S /usr/bin=/bin \
          --entry-point=/usr/bin/bash \
          --system=$BUILD_FOR_SYSTEM \
          --save-provenance \
          --no-grafts \
          --manifest=/scripts/coreboot_packages.scm

# TODO: SHA256 original output

mkdir -p /tmp/repack-docker/tar

find /gnu/store/ -maxdepth 1 -name "*-docker-pack.tar" -exec mv {} /tmp/repack-docker/coreboot-build.tar \;

cd /tmp/repack-docker/ || exit
tar xf coreboot-build.tar -C ./tar

# Update manifest.json
mv ./tar/manifest.json ./manifest.json.orig
jq  '.[0].RepoTags[0] = "'$DOCKER_IMAGE_NAME':latest"' manifest.json.orig >  ./tar/manifest.json

# Update config.json
mv ./tar/config.json ./config.json.orig
jq '.created="'"$CREATED_DATETIME"'"' config.json.orig > ./tar/config.json

# Update repositories
mv ./tar/repositories ./repositories.orig
jq '. + {"'$DOCKER_IMAGE_NAME'":.[keys_unsorted[0]]}|del(.[keys_unsorted[0]])' repositories.orig > ./tar/repositories

# create new docker image tar in volume directory /output/
cd ./tar || exit
tar cf /output/coreboot-build.tar .
