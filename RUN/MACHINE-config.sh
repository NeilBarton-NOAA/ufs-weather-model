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
    SCHEDULER=slurm
    ACCNR=${ACCNR:-marine-cpu}
    QUEUE=batch
    SUBMIT=sbatch
    JOB_CARD=fv3_slurm.IN_hera
elif [[ ${machine} == *login* ]]; then #WCOSS2
    machine='wcoss2'
    DISKNM=/lfs/h2/emc/nems/noscrub/emc.nems/RT
    FIX_DIR=/lfs/h2/emc/global/noscrub/emc.global/FIX/fix
    SCHEDULER=pbs
    ACCNR=${ACCNR:-GFS-DEV}
    QUEUE=dev
    SUBMIT=qsub
    JOB_CARD=fv3_qsub.IN_wcoss2
fi

export MACHINE_ID=${machine}.${compiler}

if [[ ${debug} == T ]]; then
    export module_file=${UFS_HOME}/modulefiles/ufs_${machine}.${compiler}_debug.lua
else
    export module_file=${UFS_HOME}/modulefiles/ufs_${machine}.${compiler}.lua
fi    

