# WIP - Guix generated coreboot/Heads build environment

The goal is to create reproducible build environments for reproducible builds.  

## The Problem
Currently, the coreboot build environment, `coreboot-sdk`, uses a Debian docker base image.  
  To install additional required packages, `apt-get update` must be run.  The resulting docker
  image is hosted in docker hub repository to be retrieved at any time in the future.  However,
  at any time in the future, building the same docker file will generate a different image
  based on the latest packages used in apt-get.  Overtime, as packages are updated due to bug,
  security or feature improvements, the provenance of the docker image in the the docker hub
  repository becomes increasingly difficult, if not impossible to audit and reproduce.

## A Possible Solution
Guix package manager that promises to generate more reliable, reproducible, and portable packages.
  Guix also has an option to generate a standalone docker image based on a list of one or more
  packages.  If dependency versions are hardened, this generated docker image theoretically should
  be bit for bit reproducible either using Guix provided precompiled derivations or allow the user
  to build from from source.

## Part 1 - Guix Package Manager Image

Part 1 is will run Guix package manager on top of Alpine Linux.  The image will only be the base
 install.  The generation of the image for Part 2  will be done in an ephemeral container.


#### Part 1 - Step 1 - Build Guix Package Manager Image

```bash
docker build -t guix-pack-builder:1.2.0 --squash -f ./Dockerfile.step1.base .
```
The resulting image will be named `guix-pack-builder` and tagged `1.2.0`.

#### Part 1 - Step 2 - Generate Build Environment Image
Using the `guix-pack-builder` image, run ephemeral container to pull a specific commit, generate
 build image and move it to the output directory.

To find the latest commit id run:

```bash
git ls-remote -h https://git.savannah.gnu.org/git/guix.git |grep 'refs/heads/master$' |awk '{ print $1 }'
```


Using a known working commit id, run the container.
```bash
docker run --rm -it \
    -v "$PWD/scripts:/scripts" \
    -v "$PWD/output:/output" \
    -e COMMIT_ID="fc68f611929df574c040e15f6653cee63401f8e2" \
    guix-pack-builder:1.2.0 \
    /scripts/build.sh
```

*NOTE*: Container and all Guix information related to the specified commit will be removed after completion.
*NOTE*: If completed successfully, `guix-pack-builder` image is not longer required and can be deleted.


## Part 2 - Build Environment Image

#### Part 2 - Step 1 - Import

```bash
cat ./output/coreboot-build.xz  | docker import - coreboot-build-env:latest
```

#### Part 2 - Step 2
create container using newly created image....something something...to finish later.


### TODO:
* move saved provenance created by Guix to output directory
* verify coreboot can build in build environment, adjust package manifest as needed
* Set distinct versions of Guix packages
* Ensure build environment is deterministic both from Guix repo and building from source
  * add coreboot user, timezone.
* May need to use Guix System vm to generate build environment.
  * Guix package image may not necessarily need to be reproducible; only the output of generated from it does.
  * Create `musl-cross` Guix package and is buildable from `guix-pack-builder`
* Create Heads PR to alter make files to test if Guix `musl-cross` exists or, if not, continue to
  build as it currently does.
