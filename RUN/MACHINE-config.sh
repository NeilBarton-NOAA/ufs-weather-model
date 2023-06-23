#!/bin/bash
set -u
echo 'MACHINE-config.sh'
machine=$(uname -n)
compiler=${compiler:-intel}
debug=${debug:-F}

if [[ ${machine} == hfe* ]]; then
    machine='hera'
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
elif [[ ${machine} == *login* ]]; then #WCOSS2
    machine='wcoss2'
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
FIX_VER=20230426

#export MACHINE_ID=${machine}.${compiler}
export MACHINE_ID=${machine}

if [[ ${debug} == T ]]; then
    export module_file=${UFS_HOME}/modulefiles/ufs_${machine}.${compiler}_debug.lua
else
    export module_file=${UFS_HOME}/modulefiles/ufs_${machine}.${compiler}.lua
fi    

# directories
INPUTDATA_ROOT=${INPUTDATA_ROOT:-${DISKNM}/NEMSfv3gfs/input-data-20221101}
INPUTDATA_ROOT_BMIC=${INPUTDATA_ROOT_BMIC:-$DISKNM/NEMSfv3gfs/BM_IC-20220207}
INPUTDATA_ROOT_WW3=${INPUTDATA_ROOT}/WW3_input_data_20220624

