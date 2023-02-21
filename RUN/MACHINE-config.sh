#!/bin/bash
set -u
echo 'MACHINE-config.sh'
machine=$(uname -n)
compiler=${compiler:-intel}
debug=${debug:-F}

if [[ ${machine} == hfe* ]]; then
    export machine='hera'
    export dprefix=/scratch1/NCEPDEV
    export DISKNM=$dprefix/nems/emc.nemspara/RT
    export SCHEDULER=slurm
    export ACCNR=${ACCNR:-marine-cpu}
    export QUEUE=batch
    export SUBMIT=sbatch

fi

export MACHINE_ID=${machine}.${compiler}

if [[ ${debug} == T ]]; then
    export module_file=${UFS_HOME}/modulefiles/ufs_hera.${compiler}_debug.lua
else
    export module_file=${UFS_HOME}/modulefiles/ufs_hera.${compiler}.lua
fi    

