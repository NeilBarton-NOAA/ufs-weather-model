#!/bin/sh
echo 'CICE-config.sh'
mkdir -p history

####################################
# look for restarts if provided
ICE_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/cpc}
ice_ic=$( find ${ICE_ICDIR} -name "*ice*.nc" )
if [[ ! -f ${ice_ic} ]]; then
    echo "  FATAL: ${ice_ic} file not found"
    exit 1
fi
rm -f cice_model.res.nc
if [[ ${FIX_METHOD} == 'RT' ]]; then
    ln -sf ${IC_DIR}/ocn/* .
else
    LF+=(["${ice_ic}"]="cice_model.res.nc")
fi
CICERUNTYPE=${CICERUNTYPE:-'initial'}
USE_RESTART_TIME=${CICE_USE_RESTART_TIME:-.false.}
cat <<EOF > ice.restart_file
cice_model.res.nc
EOF

####################################
# IO options
CICE_OUTPUT=${CICE_OUTPUT:-F}
RESTART_FREQ=${RESTART_FREQ:-$FHMAX}
DUMPFREQ_N=$(( RESTART_FREQ / 24 ))
CICE_HIST_AVG='.true.'

####################################
# determine block size from ICE_tasks and grid
NPROC_ICE=${ICE_tasks}
ice_omp_num_threads=${ICE_THRD:-${ice_omp_num_threads}}
cice_processor_shape=${CICE_DECOMP:-'slenderX2'}
shape=${cice_processor_shape#${cice_processor_shape%?}}
NPX=$(( ICE_tasks / shape )) #number of processors in x direction
NPY=$(( ICE_tasks / NPX ))   #number of processors in y direction
if (( $(( NX_GLB % NPX )) == 0 )); then
    BLCKX=$(( NX_GLB / NPX ))
else
    BLCKX=$(( (NX_GLB / NPX) + 1 ))
fi
if (( $(( NY_GLB % NPY )) == 0 )); then
    BLCKY=$(( NY_GLB / NPY ))
else
    BLCKY=$(( (NY_GLB / NPY) + 1 ))
fi

####################################
# fix files
LF+=(
["${FIX_DIR}/cice/20220805/${OCNRES}/grid_cice_NEMS_mx${OCNRES}.nc"]="."
["${FIX_DIR}/cice/20220805/${OCNRES}/kmtu_cice_NEMS_mx${OCNRES}.nc"]="."
["${FIX_DIR}/cice/20220805/${OCNRES}/mesh.mx${OCNRES}.nc"]="."
)

####################################
# parse namelist file
atparse < ${PATHRT}/parm/ice_in_template > ice_in
if [[ ${CICE_OUTPUT} == F ]]; then
    sed -i "s:histfreq       = 'm','d','h','x','x':histfreq       = 'x','x','x','x','x':g"  ice_in
    sed -i "s:histfreq_n     =  0 , 0 , 6 , 1 , 1:histfreq_n     =  0 , 0 , 0 , 0 , 0:g" ice_in
else
    sed -i "s:histfreq       = 'm','d','h','x','x':histfreq       = 'm','d','h','x','x':g"  ice_in
    sed -i "s:histfreq_n     =  0 , 0 , 6 , 1 , 1:histfreq_n     =  0 , 0 , 24 , 0 , 0:g" ice_in

fi

