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

### Build and run

via docker
```bash
docker build --rm -t guix:1.2.0 --build-arg GUIX_VERSION="1.2.0" .

docker run -d \
    --name guix_1 \
    -v "./build_channel:/build_channel" \
    -v "./build_env:/build_env" \
    guix:1.2.0
```

via docker-compose
```bash
docker-compose up -d
```

### Search Heads

```bash
docker exec guix_1 guix package -L /build_channel/ -s heads-
```

### Build heads-coreboot

```bash
docker exec guix_1 guix build -L /build_channel/ heads-coreboot
```

## TODO:
* Look into guix enviroment and manifest
  * https://guix.gnu.org/manual/en/html_node/Invoking-guix-environment.html
  * https://trivialfis.github.io/linux/2018/06/10/Using-guix-for-development.html
  * https://librehacker.com/2020/07/04/guix-manifest-functions/
* Break down channel packages into manageable sizes
