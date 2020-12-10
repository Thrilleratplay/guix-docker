# Guix in Docker for building Heads

Non-functional.

Based on the work of daym

* [Gitlab](https://gitlab.com/daym/)
  * https://gitlab.com/daym/guix-on-docker
* [GitHub](https://github.com/daym)
  * https://github.com/daym/build_channel/tree/wip-musl

### Clone

```bash
git clone --recurse-submodules https://github.com/Thrilleratplay/guix-docker
```

### Build and start

```bash
# Build via docker-compose
docker-compose up
```

### Search Heads

```bash
docker exec guix_1 guix package -L /build_channel/ -s heads-
```

### Build heads-coreboot

```bash
docker exec guix_1 guix build -L /build_channel/ heads-coreboot
```
