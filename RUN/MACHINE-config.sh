#!/bin/bash
set -u
echo 'MACHINE-config.sh'
RT_COMPILER=${RT_COMPILER:-intel}
debug=${debug:-F}
source ${PATHRT}/detect_machine.sh

if [[ ${MACHINE_ID} == hera* ]]; then
    dprefix=/scratch1/NCEPDEV
    DISKNM=$dprefix/nems/emc.nemspara/RT
    FIX_DIR=/scratch1/NCEPDEV/global/glopara/fix
    AERO_INPUTS_DIR=/scratch1/NCEPDEV/global/glopara/data/gocart_emissions
    NPB_FIX=/scratch2/NCEPDEV/stmp3/Neil.Barton/CODE/FIX
    SCHEDULER=slurm
    ACCNR=${ACCNR:-marine-cpu}
    QUEUE=batch
    SUBMIT=sbatch
    JOB_CARD=fv3_slurm.IN_hera
elif [[ ${MACHINE_ID} == wcoss2* ]]; then #WCOSS2
    DISKNM=/lfs/h2/emc/nems/noscrub/emc.nems/RT
    FIX_DIR=/lfs/h2/emc/global/noscrub/emc.global/FIX/fix
    AERO_INPUTS_DIR=/lfs/h2/emc/global/noscrub/emc.global/data/gocart_emissions
    NPB_FIX=/lfs/h2/emc/ptmp/neil.barton/CODE/FIX/
    SCHEDULER=pbs
    ACCNR=${ACCNR:-GFS-DEV}
    QUEUE=dev
    SUBMIT=qsub
    JOB_CARD=fv3_qsub.IN_wcoss2
fi


BUILD_ID=$(echo ${MACHINE_ID//.*}) # remove compiler info for older model versions
BUILD_ID=${BUILD_ID}.${RT_COMPILER}
if [[ ${debug} == T ]]; then
    export module_file=${UFS_HOME}/modulefiles/ufs_${BUILD_ID}_debug.lua
else
    export module_file=${UFS_HOME}/modulefiles/ufs_${BUILD_ID}.lua
fi    

# directories
TEMP=$(ls -ltrd ${DISKNM}/NEMSfv3gfs/input-data-*/ | tail -n 1 | awk '{print $9}')
INPUTDATA_ROOT=${INPUTDATA_ROOT:-${TEMP}}
TEMP=$(ls -ltrd ${DISKNM}/NEMSfv3gfs/BM_IC-*/ | tail -n 1 | awk '{print $9}')
INPUTDATA_ROOT_BMIC=${INPUTDATA_ROOT_BMIC:-${TEMP}}
TEMP=$(ls -ltrd ${INPUTDATA_ROOT}/WW3_input_data_*/ | tail -n 1 | awk '{print $9}')
INPUTDATA_ROOT_WW3=$(ls -ltrd ${INPUTDATA_ROOT}/WW3_input_data_*/ | tail -n 1 | awk '{print $9}')
