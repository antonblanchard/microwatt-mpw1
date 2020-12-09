#!/bin/bash -e

cd $CARAVEL_PATH
make uncompress
cd openlane

for macro in icache dcache register_file multiply_4 RAM_512x64
do
	make $macro < /dev/null &
done

wait
