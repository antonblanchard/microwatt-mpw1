#!/bin/bash -e

cd $CARAVEL_PATH
make uncompress
cd openlane

make user_project_wrapper

docker run --rm -v $CARAVEL_PATH:$CARAVEL_PATH -v $OPENLANE_ROOT:/openLANE_flow -v $PDK_ROOT:$PDK_ROOT -e CARAVEL_PATH=$CARAVEL_PATH -e PDK_ROOT=$PDK_ROOT -u $(id -u $USER):$(id -g $USER) $IMAGE_NAME sh -c "cd $CARAVEL_PATH && make"
