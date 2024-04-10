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
    wav_ic=$( find -L ${WAV_ICDIR} -name "${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart*" )
    if [[ ! -f ${wav_ic} ]]; then
        wav_ic=$( find -L ${WAV_ICDIR} -name "*restart*.ww3*" )
    fi
fi

if [[ ! -f ${wav_ic} ]]; then
    echo "  WAV IC not found, waves will cold start"
else
    cp ${wav_ic} ufs.cpld.ww3.r.${SYEAR}-${SMONTH}-${SDAY}-${SECS}
fi

####################################
# change grid if needed
FIX_VER_WAVE=$(ls -ltr ${FIX_DIR}/wave | tail -n 1 | awk '{print $9}')
${PATH_RUN}/FIX-from-hpss.sh ${WAV_RES} ${NPB_FIX} 
MESH_WAV=${FIX_DIR}/wave/${FIX_VER_WAVE}/mesh.${WAV_RES}.nc
WAV_MOD_DEF=${INPUTDATA_ROOT_WW3}/mod_def.${WAV_RES}
if [[ ! -f ${WAV_MOD_DEF} ]]; then
    WAV_MOD_DEF=${PATH_RUN}/mod_def.${WAV_RES}
    if [[ ! -f ${WAV_MOD_DEF} ]]; then 
        WAV_INP=${FIX_DIR}/wave/${FIX_VER_WAVE}/ww3_grid.inp.${WAV_RES}
        module purge
        [[ ${MACHINE_ID} == wcoss2* ]] && module reset
        ${PATH_RUN}/WW3-inp2moddef.sh ${WAV_INP} ${UFS_HOME} ${PATH_RUN} ${MACHINE_ID} 
        (( $? > 0 )) && echo 'FATAL: WAV_inp2moddef.sh failed' && exit 1
    fi
fi

if [[ ${FIX_METHOD} == 'RT' ]]; then 
    cp ${WAV_MOD_DEF} mod_def.ww3
    cp ${WAV_MESH} .
    cp ${INPUTDATA_ROOT_WW3}/mod_def.points .
else
    LF+=(
    ["${WAV_MOD_DEF}"]="mod_def.ww3"
    ["${INPUTDATA_ROOT_WW3}/mod_def.points"]="."
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
MULTIGRID=${MULTIGRID:-'false'}
if [[ $MULTIGRID = 'true' ]]; then
 atparse < ${PATHRT}/parm/ww3_multi.inp.IN > ww3_multi.inp
else
 atparse < ${PATHRT}/parm/ww3_shel.nml.IN > ww3_shel.nml
 cp ${PATHRT}/parm/ww3_points.list .
fi

