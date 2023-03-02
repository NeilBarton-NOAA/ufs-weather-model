#!/bin/bash
echo 'WW3-config.sh'
DT_2_RST=86400
wav_omp_num_threads=${WAV_THRD:-${wav_omp_num_threads}}

WAV_GRID=${WAV_GRID:-'default'}
if [[ ${WAV_GRID} != 'default' ]]; then
    cp ${WAV_GRID} .
    MESH_WAV=$(basename ${WAV_GRID})
    grid=${MESH_WAV##mesh_}
    grid=${grid%%.nc}
    cp $(dirname ${WAV_GRID})/mod_def_${grid}.ww3 mod_def.ww3
fi

if [[ $MULTIGRID = 'true' ]]; then
 atparse < ${PATHRT}/parm/ww3_multi.inp.IN > ww3_multi.inp
else
 atparse < ${PATHRT}/parm/ww3_shel.inp.IN > ww3_shel.inp
fi

