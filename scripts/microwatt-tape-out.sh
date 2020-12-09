#!/bin/bash -e

export OPENLANE_IMAGE_NAME=localhost/openlane:rc7
export IMAGE_NAME=$OPENLANE_IMAGE_NAME
export PDK_ROOT=/shared/anton/pdk.rc7
export OPENLANE_ROOT=/shared/anton/openlane.rc7

export CARAVEL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../

$CARAVEL_PATH/scripts/microwatt-build-macros.sh
$CARAVEL_PATH/scripts/microwatt-commit-macros.py
$CARAVEL_PATH/scripts/microwatt-build-caravel.sh
$CARAVEL_PATH/scripts/microwatt-commit-caravel.py
