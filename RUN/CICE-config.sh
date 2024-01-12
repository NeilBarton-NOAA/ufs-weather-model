#!/bin/sh
echo 'CICE-config.sh'
mkdir -p history

####################################
# look for restarts if provided
ICE_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/cpc}
ice_ic=${ice_ic:-$( find -L ${ICE_ICDIR} -name "*ice*.nc" )}
if [[ ${ice_ic} != 'default' ]]; then
if [[ ! -f ${ice_ic} ]]; then
    echo "  FATAL: ${ice_ic} file not found"
    exit 1
fi
fi
rm -f cice_model.res.nc
if [[ ${FIX_METHOD} == 'RT' ]]; then
    ln -sf ${IC_DIR}/ocn/* .
else
    if [[ ${ice_ic} != 'default' ]]; then
        LF+=(["${ice_ic}"]="cice_model.res.nc")
    fi
fi
CICE_RESTART=${CICE_RESTART:-'.true.'}
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
CICE_HIST_AVG='.false.'

########################
# resolution options
case "${OCNRES}" in 
    "100")
    NX_GLB=360
    NY_GLB=320
    CICE_DECOMP="slenderX1"
    ;;
    "025")
    NX_GLB=1440
    NY_GLB=1080
    CICE_DECOMP="slenderX2"
    ;;
    *)
    echo "FATAL ERROR: Unsupported CICE resolution = ${OCNRES}, ABORT!"
    exit 1
    ;;
esac
CICEGRID=grid_cice_NEMS_mx${OCNRES}.nc
CICEMASK=kmtu_cice_NEMS_mx${OCNRES}.nc

####################################
# determine block size from ICE_tasks and grid
DT_CICE=${DT_ATMOS:-$DT_CICE}
NPROC_ICE=${ICE_tasks} && CICE_NPROC=${ICE_tasks}
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
FIX_VER_CICE=$(ls -ltr ${FIX_DIR}/cice | tail -n 1 | awk '{print $9}')
if [[ ${OCNRES} == 025 ]]; then
LF+=(
["${FIX_DIR}/cice/${FIX_VER_CICE}/${OCNRES}/grid_cice_NEMS_mx${OCNRES}.nc"]="."
["${FIX_DIR}/cice/${FIX_VER_CICE}/${OCNRES}/kmtu_cice_NEMS_mx${OCNRES}.nc"]="."
["${FIX_DIR}/cice/${FIX_VER_CICE}/${OCNRES}/mesh.mx${OCNRES}.nc"]="."
)
elif [[ ${OCNRES} = 100 ]]; then
LF+=(
["${INPUTDATA_ROOT}/CICE_FIX/${OCNRES}/grid_cice_NEMS_mx${OCNRES}.nc"]="."
["${INPUTDATA_ROOT}/CICE_FIX/${OCNRES}/kmtu_cice_NEMS_mx${OCNRES}.nc"]="."
["${INPUTDATA_ROOT}/CICE_FIX/${OCNRES}/mesh.mx${OCNRES}.nc"]="."
)
fi
####################################
# parse namelist file
[[ -f ${PATHRT}/parm/ice_in.IN ]] && parse_file=ice_in.IN
[[ -f ${PATHRT}/parm/ice_in_template ]] && parse_file=ice_in_template
atparse < ${PATHRT}/parm/${parse_file} > ice_in
if [[ ${CICE_OUTPUT} == F ]]; then
    sed -i "s:histfreq       = 'm','d','h','x','x':histfreq       = 'x','x','x','x','x':g"  ice_in
    sed -i "s:histfreq_n     =  0 , 0 , 6 , 1 , 1:histfreq_n     =  0 , 0 , 0 , 0 , 0:g" ice_in
else
    sed -i "s:histfreq       = 'm','d','h','x','x':histfreq       = 'm','d','h','1','x':g"  ice_in
    sed -i "s:histfreq_n     =  0 , 0 , 6 , 1 , 1:histfreq_n     =  0 , 0 , 3 , 1 , 0:g" ice_in

fi
if [[ ${CICE_RESTART} == '.false.' ]]; then
    sed -i "s:restart        = .true.:restart        = .false.:g" ice_in
fi
if [[ ${ice_ic} == 'default' ]]; then
    sed -i "s:ice_ic         = 'cice_model.res.nc':ice_ic         = '${ice_ic}':g" ice_in
fi
