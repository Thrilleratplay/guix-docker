# WIP - Guix generated coreboot/Heads build environment

The goal is to create reproducible build environments for reproducible builds.  

## Disclaimer

This is based on a theory that has not been proven to be incorrect.

**USING THIS PROJECT IN THE CURRENT STATE IS AS INTELLIGENT AS LETTING A
 MANNEQUIN PLAY WITH FIREWORKS**

![Oops, I thought I logged on to testing](docs/images/fireworks.gif)

I tried to warn you....

## The Problem

Currently, the coreboot build environment, `coreboot-sdk`, uses a Debian docker
 base image. To install additional required packages, `apt-get update` must be
 run.  The resulting docker image is hosted in docker hub repository to be
 retrieved at any time in the future.  However, at any time in the future,
 building the same docker file will generate a different image based on the
 latest packages used in apt-get.  Overtime, as packages are updated due to bug,
 security or feature improvements, the provenance of the docker image in the the
 docker hub repository becomes increasingly difficult, if not impossible to
 audit and reproduce.

If unfamiliar with Ken Thompson's 1984 ACM TuringAward acceptance speech,
 commonly referred to as "The Ken Thompson Hack", please either
 [read it](https://dl.acm.org/doi/10.1145/358198.358210) or look up a synopsis
 that makes sense to you.  This theory is an excellent example of why one may
 want to audit the source of the source of the build environment at a later
 time.

## A Possible Solution

Guix package manager that promises to generate more reliable, reproducible, and
 portable packages. Guix also has an option to generate a standalone docker
 image based on a list of one or more packages.  If dependency versions are
 hardened, this generated docker image theoretically should be bit for bit
 reproducible either using Guix provided precompiled derivations or allow the
 user to build from from source.

## Part 1 - Guix Package Manager Image

Part 1 is will run Guix package manager on top of Alpine Linux.  The image will
 only be the base install.  The generation of the image for Part 2  will be done
 in an ephemeral container.  Due to a known issue, cross compiling is not
 allowed.  As coreboot is currently 32 bit x86, the default architecture is 32
 bit x86.

### Part 1 - Step 1 - Build Guix Package Manager Image

```bash
docker build -t guix-pack-builder:1.2.0-2 \
      --target release \
      -f ./Dockerfile.step1.base .
```

The resulting image will be named `guix-pack-builder` and tagged `1.2.0-2`.

*NOTE*: The tag schema currently used is to distinguish changes:

* `1.2.0` is the Guix version
* `2` is the version the `Dockerfile.step1.base`

**Step 1 environment variables**

|Variable|Description| Default value|
|-|-|-|
|`GUIX_VERSION`| Guix version |`1.2.0`|
|`BUILD_FOR_SYSTEM`| system architecture| `i686-linux` (32 bit x86)|

#### Part 1 - Step 2 - Generate Build Environment Image

Using the `guix-pack-builder` image, run ephemeral container to pull a specific
commit, generate build image and move it to the output directory.

To find the latest commit id run:

```bash
git ls-remote -h https://git.savannah.gnu.org/git/guix.git \
  | grep 'refs/heads/master$' \
  | awk '{ print $1 }'
```

Using a known working commit id, run the container.

```bash
docker run --rm -it \
    -v "$PWD/scripts:/scripts" \
    -v "$PWD/output:/output" \
    -e COMMIT_ID="fc68f611929df574c040e15f6653cee63401f8e2" \
    guix-pack-builder:1.2.0-2 \
    /scripts/build.sh
```

*NOTE*: Container and all Guix information related to the specified commit will
 be removed after completion.  
*NOTE*: If completed successfully, `guix-pack-builder` image is not longer
 required and can be deleted.

## Part 2 - Build Environment Image

### Part 2 - Step 1 - Load Docker image

The Docker image file will be in the output directory named
 `coreboot-build-docker-<SHORT_COMMIT_ID>.tar`, where the `SHORT_COMMIT_ID` is
 the first 7 characters of the commit id used in step 1.  The creation date of
 the image is the same as the `COMMID_ID`.

```bash
docker load -i output/coreboot-build-docker-<SHORT_COMMIT_ID>.tar

# Due to its size, remove the file after importing
rm output/coreboot-build-docker-<SHORT_COMMIT_ID>.tar
```

#### Part 2 - Step 2 - Running a container

The default user is `builduser` (`userid=1000`, `groupid=1000`).  The home
 directory can be mounted as a volume.

```bash
docker run -it --name coreboot-build-env-container \
    -v "$PWD/build_vol:/home/builduser" \
    coreboot-base-env:latest bash
```

## Known Issues

* [Cannot cross compile](https://issues.guix.gnu.org/44244)
  * For 32bit and 64bit, distinct docker images for each architecture will need
    to be created

## Q & A

**Q:** Why use Bash and Python to modify the resulting Guix tarball?
**A:** I did not want to spend too much time learning Guile as I am not still
 not sure this will even work.  Bash and Python allowed the quickest way to
 create a proof of concept.  If functional, I intend to rewrite this as a Guile
 script to fully integrate with Guix.

**Q:** Why is development so slow?
**A:** I have no idea what I am doing.  Now I feel bad.  Thanks, jerk.

**Q:** How can I determine the Guix packages used in a resulting docker image?
**A:** Provenance information manifest is saved in the root of the docker image.
 See the `--save-provenance` section of the
 [guix pack help](https://guix.gnu.org/manual/en/html_node/Invoking-guix-pack.html#Invoking-guix-pack)

### TODO

* Current blocker: configure zlib to be recognized by coreboot buildgcc
* Verify coreboot can build in build environment, adjust package manifest as needed
* Create a Bash script that wraps all of the steps and exposes command line flags.
* create [OCI spec compliant image](https://github.com/opencontainers/image-spec)
* Ensure build environment is deterministic both from Guix repo and building
 from source
* Use Continuous integration service like CircleCI to automate image generation
 and deployment
* Rewrite Python and Bash scripts into Guile Scheme script.
* Create `musl-cross` Guix package for Heads and ensure it is buildable from
 `guix-pack-builder`
* Create Heads PR to alter make files to test if Guix `musl-cross` exists or,
 if not, continue to build as it currently does.
