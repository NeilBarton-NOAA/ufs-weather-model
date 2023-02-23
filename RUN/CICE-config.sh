#!/bin/sh
echo 'CICE-config.sh'
ICE_tasks=${ICE_NMPI:-$ICE_tasks}
NPROC_ICE=${ICE_tasks}
ICE_OUTPUT=${ICE_OUTPUT:-F}

atparse < ${PATHRT}/parm/ice_in_template > ice_in
if [[ ${ICE_OUTPUT} == F ]]; then
    sed -i "s:histfreq       = 'm','d','h','x','x':histfreq       = 'x','x','x','x','x':g"  ice_in
    sed -i "s:histfreq_n     =  0 , 0 , 6 , 1 , 1:histfreq_n     =  0 , 0 , 0 , 0 , 0:g" ice_in
fi


