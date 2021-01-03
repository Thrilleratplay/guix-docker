#!/bin/#!/usr/bin/env bash

# COMMIT_ID="50b18b5c10803a910cf29718e9c35261e65f5d93"
#
#
#  guix pull --commit=$COMMIT_ID

# TODO
 # --target=i686-linux \
#
# Maybe add --profile-name=name

guix pack -f docker \
          --derivation \
          --root=/outputpack.tar.gz \
          --save-provenance \
          --manifest=/coreboot_packages.scm


# mv $(readlink /outputpack.tar.gz) /output/coreboot-build.tar.gz
