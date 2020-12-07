ARG GUIX_VERSION
FROM guix-base:${GUIX_VERSION}

ARG BOOTSTRAP_GUIX_COMMIT_ID
ENV BOOTSTRAP_GUIX_COMMIT_ID $BOOTSTRAP_GUIX_COMMIT_ID


# The commit to Guix that updated the package definition of "guix" in gnu/packages/package-management.scm,
# and that is earlier (not equal to) the commit you actually want to use.
# Note:     && rm -rf /var/guix/substitute/cache (19 MB)
RUN source /root/.config/guix/current/etc/profile \
    && guix archive --authorize < /root/.config/guix/current/share/guix/ci.guix.gnu.org.pub \
    && root/.config/guix/current/bin/guix-daemon --disable-chroot --build-users-group=guixbuild > /dev/null 2>&1 \
    & sleep 3 \
    && find / -type f -name guix-daemon -path "*bin/guix*" >A \
    && find / -type f -name guix -path "*/bin/guix" >>A \
    && guix pull --verbosity=0 --commit=${BOOTSTRAP_GUIX_COMMIT_ID} \
    && hash guix \
    && guix package -p /var/guix/profiles/per-user/root/current-guix -u ".*" \
    && guix gc

# RUN pkill guix-daemon

# && rm -f /var/guix/daemon-socket/socket \

RUN  ln -sf /var/guix/profiles/per-user/root/current-guix/bin/guix /usr/local/bin/guix \
    && find / -type f -name guix-daemon -path "*bin/guix*" >B \
    && find / -type f -name guix -path "*/bin/guix" >>B \
    && (diff -ru A B || true) \
    && ls -ld /var/guix/profiles/per-user/root/current-guix*


COPY set-mtimes.scm /

VOLUME ["/heads-guix"]

RUN ["/usr/local/bin/guix", "repl", "/set-mtimes.scm"]
ENTRYPOINT ["/root/.config/guix/current/bin/guix-daemon", "--build-users-group=guixbuild", "--disable-chroot"]
