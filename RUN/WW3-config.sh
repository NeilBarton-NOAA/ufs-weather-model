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
wav_ic=$( find ${WAV_ICDIR} -name "${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart*${WAV_RES}" )
if [[ ! -f ${wav_ic} ]]; then
    echo "  WARNING: wav IC with RES not found, looking for a restart without RES defined"
    wav_ic=$( find ${WAV_ICDIR} -name "${SYEAR}${SMONTH}${SDAY}.${SHOUR}0000.restart" )
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
if [[ ${WAV_RES} == 'gwes_30m' ]]; then
    WAV_MOD_DEF=${INPUTDATA_ROOT}/WW3_input_data_20220624/mod_def.gwes_30m
    MESH_WAV=${FIX_DIR}/wave/20220805/mesh.gwes_30m.nc
elif [[ ${WAV_RES} == 'mx025gefs' ]]; then
    WAV_MOD_DEF=${NPB_FIX}/mod_def.mx025gefs.ww3
    MESH_WAV=${FIX_DIR}/cice/20220805/025/mesh.mx025.nc
elif [[ ${WAV_RES} == 'gefsv13_025' ]]; then
    WAV_MOD_DEF=${NPB_FIX}/mod_def.ww3.gefsv13_025
    MESH_WAV=${NPB_FIX}/mesh.gefsv13_025.nc
elif [[ ${WAV_RES} == 'a' ]]; then
    WAV_MOD_DEF=${NPB_FIX}/mod_def.a.ww3
    MESH_WAV=${NPB_FIX}/mesh.a.nc
elif [[ ${WAV_RES} == 'b' ]]; then
    WAV_MOD_DEF=${NPB_FIX}/mod_def.b.ww3
    MESH_WAV=${NPB_FIX}/mesh.b.nc
elif [[ ${WAV_RES} == 'tripolar' ]]; then
    WAV_MOD_DEF=${NPB_FIX}/mod_def.tripolar.ww3
    MESH_WAV=${FIX_DIR}/cice/20220805/025/mesh.mx025.nc
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
if [[ $MULTIGRID = 'true' ]]; then
 atparse < ${PATHRT}/parm/ww3_multi.inp.IN > ww3_multi.inp
else
 atparse < ${PATHRT}/parm/ww3_shel.inp.IN > ww3_shel.inp
fi

