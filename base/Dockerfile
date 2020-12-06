# https://willschenk.com/articles/2019/installing_guix_on_nuc/
FROM alpine:3.12

ENV ALPINE_PACKAGES="gnupg xz findutils procps git"

ARG GUIX_VERSION
ENV GUIX_VERSION $GUIX_VERSION

# Add packages required to install Guix during docker build
RUN apk add --no-cache ${ALPINE_PACKAGES}

# create users and user group for Guix builder
RUN addgroup -S guixbuild \
    && for i in `seq -w 1 10`; \
    do \
      adduser -S -G guixbuild -h /var/empty -s `which nologin` -g "Guix build user $i" guixbuilder$i; \
      addgroup guixbuilder$i kvm; \
    done

RUN wget -q -O - "https://sv.gnu.org/people/viewgpg.php?user_id=15145" | gpg --import -

# TODO: gpg --verify /tmp/guix-bootstrap.tar.xz
RUN wget -q -O /tmp/guix-bootstrap.tar.xz https://ftp.gnu.org/gnu/guix/guix-binary-${GUIX_VERSION}.x86_64-linux.tar.xz \
    && cat /tmp/guix-bootstrap.tar.xz | xz -d | tar x -C / \
    && rm -f /tmp/guix-bootstrap.tar.xz \
    && mkdir -p /root/.config/guix \
    && ln -sf /var/guix/profiles/per-user/root/current-guix /root/.config/guix/current \
    && mkdir -p /usr/local/bin \
    && ln -sf /var/guix/profiles/per-user/root/current-guix/bin/guix /usr/local/bin/guix


# Remove packages required to install Guix during docker build
RUN apk del ${ALPINE_PACKAGES}

COPY etc/passwd /etc
COPY etc/group /etc
COPY etc/services /etc
