#!/bin/sh
echo 'CICE-config.sh'
ICE_tasks=${ICE_NMPI:-$ICE_tasks}
NPROC_ICE=${ICE_tasks}
ICE_OUTPUT=${ICE_OUTPUT:-F}

# determine block size from ICE_tasks and grid
cice_processor_shape=${CICE_DECOMP:-'slenderX2'}
shape=${cice_processor_shape#${cice_processor_shape%?}}
NPX=$(( ICE_tasks / shape )) #number of processors in x direction
NPY=$(( ICE_tasks / NPX ))   #number of processors in y direction
if (( $(( NX_GLB % NPX )) == 0 )); then
    BLCKX=$(( NX_GLB / NPX ))
else
    BLCKX=$(( (NX_GLB / NPX) + 1 ))
fi
if (( $(( NY_GLB % NPY )) == 0 )); then
    BLCKY=$(( NY_GLB / NPY ))
else
    BLCKY=$(( (NY_GLB / NPY) + 1 ))
fi

atparse < ${PATHRT}/parm/ice_in_template > ice_in
if [[ ${ICE_OUTPUT} == F ]]; then
    sed -i "s:histfreq       = 'm','d','h','x','x':histfreq       = 'x','x','x','x','x':g"  ice_in
    sed -i "s:histfreq_n     =  0 , 0 , 6 , 1 , 1:histfreq_n     =  0 , 0 , 0 , 0 , 0:g" ice_in
fi


