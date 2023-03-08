#!/bin/bash
echo 'WW3-config.sh'
####################################
# thread options
wav_omp_num_threads=${WAV_THRD:-${wav_omp_num_threads}}

####################################
# IO options
RESTART_FREQ=${RESTART_FREQ:-$FHMAX}
DT_2_RST=$(( RESTART_FREQ * 3600 )) 

####################################
# change grid if needed
WAV_MOD_DEF=${WAV_MOD_DEF:-'default'}
if [[ ${WAV_MOD_DEF} != 'default' ]]; then
    if [[ ! -f ${WAV_MOD_DEF} ]]; then
        echo "${WAV_MOD_DEF} file not found"
        exit 1
    fi
    cp ${WAV_MOD_DEF} mod_def.ww3
    WAV_MESH=${WAV_MESH:-'default'}
    if [[ ${WAV_MESH} != 'default' ]]; then
        if [[ ! -f ${WAV_MESH} ]]; then
            echo "${WAV_MESH} file not found"
            exit 1
        fi
        ln -sf ${WAV_MESH} .
        MESH_WAV=$(basename ${WAV_MESH})
    else
        MESH_WAV=mesh.mx025.nc
    fi
fi

####################################
# look for restarts if provided
if [[ ${IC_DIR} != 'none' ]]; then
    wav_ic=${IC_DIR}/wav/${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart.ww3.${WAV_RES}
    if [[ ! -f ${wav_ic} ]]; then
        wav_ic=${IC_DIR}/wav/${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart.ww3
        echo "WARNING: wav IC with RES not found, looking for a restart without RES defined"
    fi
    if [[ ! -f ${wav_ic} ]]; then
        echo "${wav_ic} file not found"
        exit 1
    fi
    ln -sf ${wav_ic} restart.ww3
fi

####################################
#parse namelist file
if [[ $MULTIGRID = 'true' ]]; then
 atparse < ${PATHRT}/parm/ww3_multi.inp.IN > ww3_multi.inp
else
 atparse < ${PATHRT}/parm/ww3_shel.inp.IN > ww3_shel.inp
fi

