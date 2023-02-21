#!/bin/bash
set -u
echo 'CMEPS-config.sh'
NEMS_CONFIGURE=${NEMS_CONFIGURE:-nems.configure.cpld_esmfthreads.IN}
PET_LOGS=${PETLOGS:-F}

if [[ ${CHM_NMPI} == 0 && ${WAV_NMPI} == 0 ]]; then
    NEMS_CONFIGURE=nems.configure.cpld_noaero_nowave.IN
fi

########################
# write namelists files
compute_petbounds_and_tasks
cp ${PATHRT}/parm/fd_nems.yaml fd_nems.yaml
atparse < ${PATHRT}/parm/${NEMS_CONFIGURE} > nems.configure

# post edits
[[ ${PET_LOGS} == F ]] && sed -i "s:ESMF_LOGKIND_MULTI:ESMF_LOGKIND_MULTI_ON_ERROR:g" nems.configure

