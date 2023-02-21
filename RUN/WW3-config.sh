#!/bin/bash
echo 'WW3-config.sh'

if [[ $MULTIGRID = 'true' ]]; then
 atparse < ${PATHRT}/parm/ww3_multi.inp.IN > ww3_multi.inp
else
 atparse < ${PATHRT}/parm/ww3_shel.inp.IN > ww3_shel.inp
fi

