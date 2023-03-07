#!/bin/bash
set -u
echo 'CMEPS-config.sh'
NEMS_CONFIGURE=${NEMS_CONFIGURE:-${PATHRT}/parm/nems.configure.cpld_esmfthreads.IN}
PET_LOGS=${PETLOGS:-F}
MED_tasks=${MED_NMPI:-$(( INPES * JNPES * atm_omp_num_threads ))}
med_omp_num_threads=${atm_omp_num_threads}

########################
# options based on other active components
[[ ${CHM_tasks} == 0 && ${WAV_tasks} == 0 ]] && NEMS_CONFIGURE=${PATHRT}/parm/nems.configure.cpld_noaero_nowave.IN
[[ ${CHM_tasks} == 0 && ${WAV_tasks} != 0 ]] && NEMS_CONFIGURE=${PATHRT}/parm/nems.configure.cpld_noaero_outwav.IN
#[[ ${CHM_NMPI} == 0 && ${WAV_NMPI} != 0 ]] && NEMS_CONFIGURE=${PATHRT}/parm/nems.configure.cpld_noaero.IN
WAV_GRID=${WAV_GRID:-'default'}
[[ ${WAV_GRID} != 'default' ]] && MESH_WAV=$(basename ${WAV_GRID})

########################
#if [[ ${IC_DIR} != 'none' ]]; then
#    f=$(ls ${IC_DIR}/med/*)
#    ln -sf ${f} ufs.cpld.cpl.r.nc
#    rm -f rpointer.cpl && touch rpointer.cpl
#    echo "ufs.cpld.cpl.r.nc" >> "rpointer.cpl"
#fi

########################
# write namelists files
compute_petbounds_and_tasks
cp ${PATHRT}/parm/fd_nems.yaml fd_nems.yaml
atparse < ${NEMS_CONFIGURE} > nems.configure
# post edits
[[ ${PET_LOGS} == F ]] && sed -i "s:ESMF_LOGKIND_MULTI:ESMF_LOGKIND_MULTI_ON_ERROR:g" nems.configure

