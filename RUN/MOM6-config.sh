#!/bin/sh
echo 'MOM6-config.sh'
MOM_INPUT=${MOM_INPUT:-MOM_input_template_${OCNRES}}
ocn_omp_num_threads=${OCN_THRD:-${ocn_omp_num_threads}}
mkdir -p INPUT MOM6_OUTPUT

####################################
# options based on other active components
[[ ${WAV_tasks} == 0 ]] && MOM6_USE_WAVES=false

####################################
# look for restarts if provided
OCN_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/mom6_da}
n_files=$( find ${OCN_ICDIR} -name "MOM.res*nc" 2>/dev/null | wc -l )
if (( ${n_files} == 0 )); then
    echo '   FATAL: no ocn ICs found in:' ${OCN_ICDIR}
    exit 1
fi
if [[ ${FIX_METHOD} == 'RT' ]]; then
    ln -sf ${IC_DIR}/ocn/* .
else
   ocn_ics=$( find ${OCN_ICDIR} -name "MOM.res*nc" 2>/dev/null )
   for ocn_ic in ${ocn_ics}; do
    LF+=(["${ocn_ic}"]="INPUT/")
   done
fi

####################################
# fix files
LF+=(
["${FIX_DIR}/mom6/20220805/${OCNRES}/All_edits.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/MOM_channels_global_025"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/MOM_layout"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/MOM_override"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/geothermal_davies2013_v1.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/hycom1_75_800m.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/interpolate_zgrid_40L.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/layer_coord.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/ocean_hgrid.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/ocean_mask.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/ocean_mosaic.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/ocean_topog.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/runoff.daitren.clim.1440x1080.v20180328.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/seawifs-clim-1997-2010.1440x1080.v20180328.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/tidal_amplitude.v20140616.nc"]="INPUT/"
["${FIX_DIR}/mom6/20220805/${OCNRES}/topog.nc"]="INPUT/"
)

###################################
# parse namelist file
atparse < ${PATHRT}/parm/${MOM_INPUT} > INPUT/MOM_input

