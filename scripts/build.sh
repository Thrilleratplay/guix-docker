#!/usr/bin/env sh

#############################################################################

# git ls-remote -h https://git.savannah.gnu.org/git/guix.git |grep 'refs/heads/master$' |awk '{ print $1 }'

COMMIT_ID="${COMMIT_ID}"
BUILD_FOR_SYSTEM="${BUILD_FOR_SYSTEM:=i686-linux}"

BUILD_USERNAME="${BUILD_USERNAME:=builduser}"
DOCKER_IMAGE_NAME="coreboot-base-env"


GLIBCUTF8LOCALE=$(find /gnu/store/ -maxdepth 1 -name "*-glibc-utf8-locale*")

export GUIX_LOCPATH="$GLIBCUTF8LOCALE/lib/locale"
export LC_ALL=en_US.utf8

#############################################################################

cat << EOF > /root/.config/guix/channels.scm
(list (channel
        (name 'guix)
        (url "https://git.savannah.gnu.org/git/guix.git")
        (commit  "$COMMIT_ID"))
      (channel
        (name 'heads)
        (url "https://github.com/daym/heads-guix.git")
        (branch "wip")))

EOF

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
LATEST_CHECKOUT=$(grep "git.savannah.gnu.org" /root/.cache/guix/checkouts/*/.git/config | awk -F"/" '{print $6}')

cd "/root/.cache/guix/checkouts/$LATEST_CHECKOUT/" || exit
CREATED_DATETIME=$(TZ=UTC git show --date=iso-strict-local --pretty='%cd' "$COMMIT_ID" | head -n1)

# Create TARBALL pack based on coreboot_packages.scm manifest
LC_LANG=en_US.utf8 guix pack -f tarball \
          --compression=none \
          --system=$BUILD_FOR_SYSTEM \
          --save-provenance \
          --no-grafts \
          --manifest=/scripts/coreboot_packages.scm

TARBALL=$(find /gnu/store/ -maxdepth 1 -name "*-pack.tar");

# If the TARBALL cannot be found, abandon ship.
if [ -z "${TARBALL}" ]; then
  >&2 echo "Guix pack TARBALL cannot be found.  Exiting due to error!!!!"
  exit 1
fi

################################################################################
############################# POST Guix manipulation ###########################
################################################################################

TARBALL_SHA256=$(sha256sum "$TARBALL" | awk '{ print $1 }')

# # make temp directory
TMPDIR=$(mktemp -d)

# # if the temp directory wasn't created successfully, adbandon ship
if [ ! -e "$TMPDIR" ]; then
  >&2 echo "Failed to create temp directory"
  exit 1
fi

# extract tarball to "$TMPDIR/tmp_layer"
mkdir "$TMPDIR/tmp_layer"
tar xf "$TARBALL" -C "$TMPDIR/tmp_layer/"

cd "$TMPDIR/tmp_layer/gnu/store/" || exit

PROFILE_PATH=$(ls -d ./*profile)
cd "$PROFILE_PATH" || exit
mv ./* ./.* ../../../
cd ../../.. || exit
rmdir "./gnu/store/$PROFILE_PATH" || exit

# Replace sh with bash
# unlink "/bin/sh"
cp "./bin/bash" "./bin/sh"

# Create tmp directory
mkdir "./tmp"
chmod 1777 "./tmp"

# Create root directory
mkdir "./root"

# Create /usr directory
mkdir "./usr/"
mv "./include" "./usr/"
mv "./lib" "./usr/"
mv "./bin" "./usr/"
mv "./src" "./usr/"
ln -s "./usr/bin" "./bin"
ln -s "./usr/bin" "./sbin"
ln -s "./usr/lib" "./lib"
ln -s "./usr/lib" "./lib64"

# Create $BUILD_USERNAME home directory
mkdir -p "./home/$BUILD_USERNAME/"
chmod 755 "./home/$BUILD_USERNAME/"
chown -R 1000:1000 "./home/$BUILD_USERNAME/"

#######

# /etc/hostname
echo "$DOCKER_IMAGE_NAME-$COMMIT_ID" > ./etc/hostname

# https://tldp.org/LDP/sag/html/adduser.html
# https://tldp.org/LDP/lame/LAME/linux-admin-made-easy/shadow-file-formats.html

cat << EOF > ./etc/passwd
root:x:0:0:root:/root:/bin/bash
$BUILD_USERNAME:x:1000:1000:$BUILD_USERNAME:/home/$BUILD_USERNAME:/bin/bash

EOF

cat << EOF > ./etc/shadow
root:!::0:::::
$BUILD_USERNAME::0:::::

EOF

cat << EOF > ./etc/group
root:x:0:root
$BUILD_USERNAME:x:1000:$BUILD_USERNAME

EOF

# /etc/profile
cat << EOF > ./etc/profile
#
# /etc/profile
#
umask 022

export PATH="/bin:/usr/bin"
export CMAKE_PREFIX_PATH="/"
export SSL_CERT_DIR="/etc/ssl/certs"
export GIT_EXEC_PATH="/usr/libexec/git-core"
export BASH_LOADABLES_PATH="/usr/lib/bash"
export TERMINFO_DIRS="/usr/share/terminfo"
export PKG_CONFIG_PATH="/usr/lib/pkgconfig"
export PYTHONPATH="/usr/lib/python3.8/site-packages"
export GIT_SSL_CAINFO="/etc/ssl/certs/ca-certificates.crt"
export C_INCLUDE_PATH="/usr/include"
export CPLUS_INCLUDE_PATH="/usr/include"
export LIBRARY_PATH="/usr/lib"
export SHELL="/bin/bash"
export GUIX_LOCPATH="/usr/lib/locale"
export LOCPATH="/usr/lib/locale"
export LC_ALL="en_US.utf8"

. /etc/bash.bashrc

EOF

cat << EOF > ./etc/bash.bashrc
#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

EOF

#############################################

# create new archive as a layer
tar -cf "$TMPDIR/layer.tar" .

python3 /scripts/pack2dockerImage.py \
  --commit "$COMMIT_ID" \
  --date "$CREATED_DATETIME" \
  --orig-tarball-sha256 "$TARBALL_SHA256" \
  --tarball "$TMPDIR/layer.tar" \
  --docker-image-name "$DOCKER_IMAGE_NAME" \
  --user-name "$BUILD_USERNAME"
