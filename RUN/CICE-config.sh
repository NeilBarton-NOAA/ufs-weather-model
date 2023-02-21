#!/bin/sh
echo 'CICE-config.sh'
ICE_tasks=${ICE_NMPI:-$ICE_tasks}
NPROC_ICE=${ICE_tasks}
atparse < ${PATHRT}/parm/ice_in_template > ice_in

