#!/bin/bash
set -u
echo 'CMEPS-config.sh'
[[ ${CHM_tasks} == 0 && ${WAV_tasks} == 0 ]] && UFS_CONFIGURE=ufs.configure.s2s.IN
[[ ${CHM_tasks} == 0 && ${WAV_tasks} != 0 ]] && UFS_CONFIGURE=ufs.configure.s2sw.IN
[[ ${CHM_tasks} != 0 && ${WAV_tasks} == 0 ]] && UFS_CONFIGURE=ufs.configure.s2sa.IN
PET_LOGS=${PETLOGS:-F}

########################
# ICs
if [[ ${WARM_START} == '.true.' ]]; then
    med_ic=${med_ic:-$( find ${ICDIR} -name "*ufs.cpld.cpl.r*")}
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
# coupling time steps
coupling_interval_fast_sec=${DT_ATMOS}
coupling_interval_slow_sec=${DT_THERM_MOM6}

########################
# mpi tasks
ATM_compute_tasks=$(( INPES * JNPES * NTILES ))
MED_tasks=${MED_NMPI:-${ATM_compute_tasks}}
if (( ${MED_tasks} > ${ATM_compute_tasks} )); then
    MED_tasks=${ATM_compute_tasks}
fi
med_omp_num_threads=${atm_omp_num_threads}
chm_omp_num_threads=${atm_omp_num_threads}

########################
# options based on other active components
WAV_GRID=${WAV_GRID:-'default'}
[[ ${WAV_GRID} != 'default' ]] && MESH_WAV=$(basename ${WAV_GRID})

########################
# options based on resolutions
MESHOCN_ICE=mesh.mx${OCNRES}.nc
case "${OCNRES}" in
    "500") eps_imesh="4.0e-1";;
    "100") eps_imesh="2.5e-1";;
    *) eps_imesh="1.0e-1";;
esac
ATMTILESIZE=${ATMRES:1}

########################
# write namelists files
compute_petbounds_and_tasks
UFS_FILE=${PATHRT}/parm/${UFS_CONFIGURE}
if [[ ! -f ${UFS_FILE} ]]; then
    UFS_FILE=${PATH_RUN}/../tests/parm/${UFS_CONFIGURE}
fi
#OLDER CODE
fd_file=${PATHRT}/parm/fd_nems.yaml
yaml_file=fd_nems.yaml
config_file=nems.configure
# NEWER CODE
if [[ ! -f ${fd_file} ]]; then
    # If not there, NEWER CODE
    fd_file=${PATHRT}/parm/fd_ufs.yaml 
    yaml_file=fd_ufs.yaml
    config_file=ufs.configure
fi
atparse < ${UFS_FILE} > ${config_file}
cp ${fd_file} ${yaml_file}
# post edits
#[[ ${PET_LOGS} == F ]] && sed -i "s:ESMF_LOGKIND_MULTI:ESMF_LOGKIND_MULTI_ON_ERROR:g" ${config_file}
