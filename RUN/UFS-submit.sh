#!/bin/bash
set -u
DEBUG=${DEBUG:-F}
[[ ${DEBUG} == T ]] && set -x
################################################
# submit UFS weather model largely folling RTs, but with more flexability 
#   default is to run the S2SWA using the RT defaults
#   TODOS:
#       - link needed data instead of running ./fv3_run
#       - not sure if field table in FV3-config.sh is needed
########################
RUNDIR=${1} 
UFS_HOME=${UFS_HOME:-${0%/*}}
RT_TEST=${RT_TEST:-cpld_bmark_p8}

########################
# delete run dir if needed
if [[ -d ${RUNDIR} ]]; then
    if [[ ${DEBUG} == F ]]; then
        echo "RUNDIR: ${RUNDIR}"
        read -p 'RUNDIR exists, Delete existing directory? (d) or Create new directory (c) ' ans
        case ${ans} in
            [Dd]* ) rm -r ${RUNDIR}/*;; 
            [Cc]* ) RUNDIR=${RUNDIR}_$( date +%s ) && echo "NEW RUNDIR: ${RUNDIR}";;
            *) echo "Please answer yes or no";;
        esac
    else
        rm -r ${RUNDIR}/*
    fi
else
    echo "RUNDIR: ${RUNDIR}"
fi
mkdir -p ${RUNDIR} && cd ${RUNDIR}

########################
# defaults
FIX_METHOD=${FIX_METHOD:-'LINK'} #RT for original method
PATH_RUN=${PATH_RUN:-${UFS_HOME}/RUN}
PATHRT=${UFS_HOME}/tests
# tools
source ${PATHRT}/rt_utils.sh
source ${PATHRT}/atparse.bash
# machine specific directories
source ${PATH_RUN}/MACHINE-config.sh
# variables
source ${PATHRT}/default_vars.sh
source ${PATHRT}/tests/${RT_TEST}

########################
# change of default based on values needed for most scripts
OCN_tasks=${OCN_NMPI:-$OCN_tasks}
ICE_tasks=${ICE_NMPI:-$ICE_tasks}
WAV_tasks=${WAV_NMPI:-$WAV_tasks}
CHM_tasks=${CHM_NMPI:-0}
ATMRES=${ATM_RES:-$ATMRES}
OCNRES=${OCN_RES:-$OCNRES}
FL=${FORECAST_LENGTH:-1}
FHMAX=$( echo "${FL} * 24" | bc )
FHMAX=${FHMAX%.*}

########################
# FV3_RUN TODO
if [[ ${FIX_METHOD} == 'RT' ]]; then
    source ${PATH_RUN}/FIXFILES-rt-method.sh
fi
########################
# set year and default year for coupled bmark run
DTG=${DTG:-${SYEAR}${SMONTH}${SDAY}${SHOUR}00}
export SYEAR=${DTG:0:4}
export SMONTH=${DTG:4:2}
export SDAY=${DTG:6:2}
export SHOUR=${DTG:8:2}
export SECS=$( printf "%05d" $(( $SHOUR * 3600 )) )

####################################
# Write Namelist Files 
source ${PATH_RUN}/FV3-config.sh
[[ ${CHM_tasks} != 0 ]] && source ${PATH_RUN}/GOCART-config.sh
source ${PATH_RUN}/MOM6-config.sh
source ${PATH_RUN}/CICE-config.sh
[[ ${WAV_tasks} != 0 ]] && source ${PATH_RUN}/WW3-config.sh 
source ${PATH_RUN}/CMEPS-config.sh

####################################
# LINK needed files into RUNDIR
if [[ ${FIX_METHOD} == 'LINK' ]]; then
    source ${PATH_RUN}/FIXFILES-link.sh
fi
########################
# create job card
source ${PATH_RUN}/JOB-config.sh
# execute model
echo 'RUNDIR: ' ${PWD}
[[ ${DEBUG} == F ]] && ${SUBMIT} job_card
