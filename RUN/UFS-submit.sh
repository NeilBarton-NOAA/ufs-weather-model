#!/bin/bash
set -u
#set -x
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
CHM_NMPI=${CHM_NMPI:-default}
WAV_NMPI=${WAV_NMPI:-default}

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
# change of default based on values
FL=${FORECAST_LENGTH:-1}
FHMAX=$( echo "${FL} * 24" | bc )
FHMAX=${FHMAX%.*}

########################
# set year and default year for coupled bmark run
#DTG=${DTG:-${SYEAR}${SMONTH}${SDAY}${SHOUR}00}
#export SYEAR=${DTG:0:4}
#export SMONTH=${DTG:6:2}
#export SDAY=${DTG:8:2}
#export SHOUR=${DTG:10:2}
#export SECS=$( $SHOUR * 3600 )

####################################
# Write Namelist Files 
source ${PATH_RUN}/FV3-config.sh
[[ ${CHM_NMPI} != 0 ]] && source ${PATH_RUN}/GOCART-config.sh
source ${PATH_RUN}/MOM6-config.sh
source ${PATH_RUN}/CICE-config.sh
[[ ${WAV_NMPI} != 0 ]] && source ${PATH_RUN}/WW3-config.sh || WAV_tasks=${WAV_NMPI}
source ${PATH_RUN}/CMEPS-config.sh

########################
# create job card
source ${PATH_RUN}/JOB-config.sh
# execute model
echo 'RUNDIR: ' ${PWD}
[[ ${DEBUG} == F ]] && ${SUBMIT} job_card
