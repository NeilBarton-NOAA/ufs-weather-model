#!/bin/bash
set -u
echo 'CMEPS-config.sh'
NEMS_CONFIGURE=${NEMS_CONFIGURE:-nems.configure.cpld_esmfthreads.IN}
[[ ${CHM_tasks} == 0 && ${WAV_tasks} == 0 ]] && NEMS_CONFIGURE=nems.configure.cpld_noaero_nowave.IN
[[ ${CHM_tasks} == 0 && ${WAV_tasks} != 0 ]] && NEMS_CONFIGURE=nems.configure.cpld_noaero_outwav.IN
[[ ${CHM_tasks} != 0 && ${WAV_tasks} != 0 ]] && NEMS_CONFIGURE=nems.configure.cpld_esmfthreads_outwav.IN
PET_LOGS=${PETLOGS:-F}

########################
# ICs
if [[ ${WARM_START} == '.true.' ]]; then
    med_ic=$( find ${ICDIR} -name "*ufs.cpld.cpl.r*")
    if [[ ! -f ${med_ic} ]]; then
        echo "  FATAL: ${med_ic} file not found"
        exit 1
    fi
    if [[ ${FIX_METHOD} == 'RT' ]]; then 
        ln -sf ${med_ic} ufs.cpld.cpl.r.nc
    else
        LF+=(["${med_ic}"]="ufs.cpld.cpl.r.nc")
    fi
    rm -f rpointer.cpl && touch rpointer.cpl
    echo "ufs.cpld.cpl.r.nc" >> "rpointer.cpl"
    RUNTYPE=continue
fi

########################
# mpi tasks
MED_tasks=${MED_NMPI:-$(( INPES * JNPES * atm_omp_num_threads ))}
med_omp_num_threads=${atm_omp_num_threads}
chm_omp_num_threads=${atm_omp_num_threads}

########################
# options based on other active components
WAV_GRID=${WAV_GRID:-'default'}
[[ ${WAV_GRID} != 'default' ]] && MESH_WAV=$(basename ${WAV_GRID})

########################
# write namelists files
compute_petbounds_and_tasks
cp ${PATHRT}/parm/fd_nems.yaml fd_nems.yaml
atparse < ${PATHRT}/parm/${NEMS_CONFIGURE} > nems.configure
# post edits
[[ ${PET_LOGS} == F ]] && sed -i "s:ESMF_LOGKIND_MULTI:ESMF_LOGKIND_MULTI_ON_ERROR:g" nems.configure
