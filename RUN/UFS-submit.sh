#!/bin/bash
set -u
DEBUG=${DEBUG:-F}
[[ ${DEBUG} == T ]] && set -x
################################################
# submit UFS weather model largely folling RTs, but with more flexability 
#   default is to run the S2SWA using the RT defaults
#   TODOS:
#       - link needed data instead of running ./fv3_run
#       - add option to start with other ICs and start dates
#       - run with different processer and thread counts (ATM, OCN, ICE -> completed)
########################
RUNDIR=${1} && mkdir -p ${RUNDIR} && cd ${RUNDIR}
UFS_HOME=${UFS_HOME:-${0%/*}}
RT_TEST=${RT_TEST:-cpld_bmark_p8}

echo "RUNDIR: ${RUNDIR}"
########################
# delete run dir if needed
dirs=$(find . -mindepth 1 -type d)
for d in ${dirs}; do
    #echo "REMOVING ${d}"
    rm -r ${d}
done

########################
# defaults
PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
PATHRT=${UFS_HOME}/tests
# tools
source ${PATHRT}/rt_utils.sh
source ${PATHRT}/atparse.bash
# machine specific
source ${PATH_RUN}/MACHINE-config.sh
# directories 
INPUTDATA_ROOT=${INPUTDATA_ROOT:-${DISKNM}/NEMSfv3gfs/input-data-20221101}
INPUTDATA_ROOT_BMIC=${INPUTDATA_ROOT_BMIC:-$DISKNM/NEMSfv3gfs/BM_IC-20220207}
INPUTDATA_ROOT_WW3=${INPUTDATA_ROOT}/WW3_input_data_20220624
# variables
source ${PATHRT}/default_vars.sh
source ${PATHRT}/tests/${RT_TEST}

########################
# change of default based on values needed for most scripts
OCN_tasks=${OCN_NMPI:-$OCN_tasks}
ICE_tasks=${ICE_NMPI:-$ICE_tasks}
WAV_tasks=${WAV_NMPI:-$WAV_tasks}
CHM_tasks=${CHM_NMPI:-$CHM_tasks}
FL=${FORECAST_LENGTH:-1}
FHMAX=$( echo "${FL} * 24" | bc )
FHMAX=${FHMAX%.*}
IC_DIR=${IC_DIR:-'none'}

########################
# FV3_RUN TODO, change this
FV3_RUN=${FV3_RUN:-cpld_control_run.IN}
[[ -f fv3_run ]] && rm fv3_run
for i in ${FV3_RUN}; do
    atparse < ${PATHRT}/fv3_conf/${i} >> fv3_run
done
if [[ ${DEBUG} == F ]]; then
    RT_SUFFIX=""
    echo 'RUNNING fv3_run'
    source ./fv3_run
fi

########################
# set year and default year for coupled bmark run
DTG=${DTG:-${SYEAR}${SMONTH}${SDAY}${SHOUR}00}
export SYEAR=${DTG:0:4}
export SMONTH=${DTG:4:2}
export SDAY=${DTG:6:2}
export SHOUR=${DTG:8:2}
export SECS=$(( $SHOUR * 3600 ))

####################################
# Write Namelist Files 
source ${PATH_RUN}/FV3-config.sh
[[ ${CHM_tasks} != 0 ]] && source ${PATH_RUN}/GOCART-config.sh
source ${PATH_RUN}/MOM6-config.sh
source ${PATH_RUN}/CICE-config.sh
[[ ${WAV_tasks} != 0 ]] && source ${PATH_RUN}/WW3-config.sh 
source ${PATH_RUN}/CMEPS-config.sh

########################
# create job card
source ${PATH_RUN}/JOB-config.sh
# execute model
echo 'RUNDIR: ' ${PWD}
[[ ${DEBUG} == F ]] && ${SUBMIT} job_card
