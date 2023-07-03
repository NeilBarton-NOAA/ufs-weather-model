#!/bin/bash
echo 'WW3-config.sh'
####################################
# thread options
wav_omp_num_threads=${WAV_THRD:-${wav_omp_num_threads}}

####################################
# look for restarts if provided
WAV_RES=${WAV_RES:-gwes_30m}
echo '  WAV_RES:' ${WAV_RES}
WAV_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/wav_p8c}
wav_ic=$( find -L ${WAV_ICDIR} -name "${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart*${WAV_RES}" )
if [[ ! -f ${wav_ic} ]]; then
    echo "  WARNING: wav IC with RES not found, looking for a restart without RES defined"
    wav_ic=$( find -L ${WAV_ICDIR} -name "${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart" )
fi

if [[ ! -f ${wav_ic} ]]; then
    echo "  WAV IC not found, waves will cold start"
else
    if [[ ${FIX_METHOD} == 'RT' ]]; then
        ln -sf ${wav_ic} restart.ww3
    else
        LF+=(["${wav_ic}"]="restart.ww3")
    fi
fi

####################################
# change grid if needed
${PATH_RUN}/FIX-from-hpss.sh ${WAV_RES} ${NPB_FIX} 
MESH_WAV=${FIX_DIR}/wave/${FIX_VER}/mesh.${WAV_RES}.nc
WAV_MOD_DEF=${INPUTDATA_ROOT}/WW3_input_data_20220624/mod_def.${WAV_RES}
if [[ ! -f ${WAV_MOD_DEF} ]]; then
    WAV_MOD_DEF=${UFS_HOME}/RUN/mod_def.${WAV_RES}
    if [[ ! -f ${WAV_MOD_DEF} ]]; then 
        WAV_INP=${FIX_DIR}/wave/${FIX_VER}/ww3_grid.inp.${WAV_RES}
        ${PATH_RUN}/WW3-inp2moddef.sh ${WAV_INP} ${UFS_HOME} ${machine} 
        (( $? > 0 )) && echo 'FATAL: WAV_inp2moddef.sh failed' && exit 1
    fi
fi

if [[ ${FIX_METHOD} == 'RT' ]]; then 
    cp ${WAV_MOD_DEF} mod_def.ww3
    cp ${WAV_MESH} .
    cp ${INPUTDATA_ROOT}/WW3_input_data_20220624/mod_def.points .
else
    LF+=(
    ["${WAV_MOD_DEF}"]="mod_def.ww3"
    ["${INPUTDATA_ROOT}/WW3_input_data_20220624/mod_def.points"]="."
    )
fi

####################################
# IO options
RESTART_FREQ=${RESTART_FREQ:-$FHMAX}
DT_2_RST=$(( RESTART_FREQ * 3600 )) 
DTFLD=${WW3_DTFLD:-${DT_2_RST}}
DTPNT=${WW3_DTPNT:-${DT_2_RST}}

####################################
#parse namelist file
export INPUT_CURFLD='C F     Currents'
export INPUT_ICEFLD='C F     Ice concentrations'
if [[ $MULTIGRID = 'true' ]]; then
 atparse < ${PATHRT}/parm/ww3_multi.inp.IN > ww3_multi.inp
else
 atparse < ${PATHRT}/parm/ww3_shel.inp.IN > ww3_shel.inp
fi

