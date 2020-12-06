# Guix in Docker for building Heads

Non-functional.

Based on the work of daym

* [Gitlab](https://gitlab.com/daym/)
  * https://gitlab.com/daym/guix-on-docker
* [GitHub](https://github.com/daym)
  * https://github.com/daym/heads-guix/tree/wip-musl

### Build and start

```bash
# Build via docker-compose
docker-compose up --build --no-start

# Start guild-build container
docker start guix-build_1
```

### Pull channels

```bash
docker exec guix-build_1 guix pull /root/.config/guix/channels.scm
```

### Search Heads

```bash
docker exec guix-build_1 guix search heads-
```

### Build heads-dev-cpio

```bash
docker exec guix-build_1 guix build --rounds=2 heads-dev-cpio  
```
