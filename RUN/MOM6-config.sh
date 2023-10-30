#!/bin/sh
echo 'MOM6-config.sh'
MOM_INPUT=MOM_input_template_${OCNRES}
ocn_omp_num_threads=${OCN_THRD:-${ocn_omp_num_threads}}
mkdir -p INPUT MOM6_OUTPUT

####################################
# options based on other active components
[[ ${WAV_tasks} == 0 ]] && MOM6_USE_WAVES=false

####################################
# look for restarts if provided
OCN_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/mom6_da}
n_files=$( find -L ${OCN_ICDIR} -name "MOM.res*nc" 2>/dev/null | wc -l )
MOM6_RESTART_SETTING='r'
if (( ${n_files} == 0 )); then
    echo '   WARNING: no ocn ICs found in:' ${OCN_ICDIR}
    echo '            will use TS file'
    MOM6_RESTART_SETTING='n'
    case "${OCNRES}" 
        in "100")
        LF+=(
        ["${INPUTDATA_ROOT}/MOM6_IC/100/2011100100/MOM6_IC_TS_2011100100.nc"]="INPUT/MOM6_IC_TS.nc"
        ) 
        ;;
        "025")
        LF+=(
        ["${INPUTDATA_ROOT}/MOM6_IC/MOM6_IC_TS_2021032206.nc"]="INPUT/MOM6_IC_TS.nc"
        ) 
        ;;
        *)
        echo '  FATAL: TS IC not found'
        exit 1
        ;;
    esac
fi
if [[ ${FIX_METHOD} == 'RT' ]]; then
    ln -sf ${IC_DIR}/ocn/* .
else
   ocn_ics=$( find -L ${OCN_ICDIR} -name "MOM.res*nc" 2>/dev/null )
   for ocn_ic in ${ocn_ics}; do
    LF+=(["${ocn_ic}"]="INPUT/")
   done
fi

if [[ ${MOM6_RESTART_SETTING} == 'n' ]]; then
    sed -i "s:input_filename = 'r':input_filename = 'n':g" input.nml
fi

########################
# resolution options
case "${OCNRES}" in 
    "100")
    OCNTIM=3600
    NX_GLB=360
    NY_GLB=320
    DT_DYNAM_MOM6='3600'
    DT_THERM_MOM6='3600'
    FRUNOFF=""
    CHLCLIM="seawifs_1998-2006_smoothed_2X.nc"
    MOM6_RIVER_RUNOFF='False'
    TOPOEDITS="ufs.topo_edits_011818.nc"
    MOM6_ALLOW_LANDMASK_CHANGES="True"
    ;;
    "025")
    OCNTIM=1800
    NX_GLB=1440
    NY_GLB=1080
    DT_DYNAM_MOM6='900'
    DT_THERM_MOM6='1800'
    FRUNOFF="runoff.daitren.clim.${NX_GLB}x${NY_GLB}.v20180328.nc"
    CHLCLIM="seawifs-clim-1997-2010.${NX_GLB}x${NY_GLB}.v20180328.nc"
    MOM6_RIVER_RUNOFF='True'
    ;;
    *)
    echo "FATAL ERROR: Unsupported MOM6 resolution = ${ONCRES}, ABORT!"
    exit 1
    ;;
esac

########################
# IO
FIX_VER_MOM6=$(ls -ltr ${FIX_DIR}/mom6 | tail -n 1 | awk '{print $9}')
MOM_LAYOUT=${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/MOM_layout 
if [[ -f ${MOM_LAYOUT} ]]; then
    cp ${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/MOM_layout INPUT/
    MOM6_IO_LAYOUT=${MOM6_IO_LAYOUT:-'1,1'}
    if [[ ${MOM6_IO_LAYOUT} != '1,1' ]]; then
        sed -i "s:IO_LAYOUT = 1,1:IO_LAYOUT = ${MOM6_IO_LAYOUT}:g" INPUT/MOM_layout
        ln=$(grep -wn INPUT/MOM_input input.nml | cut -d: -f1) && ln=$(( ln + 1))
        sed -i "${ln} i   'INPUT/MOM_layout'," input.nml
    fi
fi
touch INPUT/MOM_override

###################################
# namelist settings
if [[ ${ENS_SETTINGS} == T ]]; then
DO_OCN_SPPT=true
PERT_EPBL=true

fi

###################################
# parse namelist file
atparse < ${PATHRT}/parm/${MOM_INPUT} > INPUT/MOM_input

####################################
# fix files
LF+=(
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/hycom1_75_800m.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/interpolate_zgrid_40L.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/layer_coord.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/ocean_hgrid.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/ocean_mask.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/ocean_mosaic.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/topog.nc"]="INPUT/"
)

if [[ ${OCNRES} == 025 ]]; then
LF+=(
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/ocean_topog.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/geothermal_davies2013_v1.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/All_edits.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/MOM_override"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/MOM_channels_global_025"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/runoff.daitren.clim.1440x1080.v20180328.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/seawifs-clim-1997-2010.1440x1080.v20180328.nc"]="INPUT/"
["${FIX_DIR}/mom6/${FIX_VER_MOM6}/${OCNRES}/tidal_amplitude.v20140616.nc"]="INPUT/"
)
fi

if [[ ${OCNRES} == 100 ]]; then
LF+=(
["${INPUTDATA_ROOT}/MOM6_FIX/${OCNRES}/ufs.topo_edits_011818.nc"]="INPUT/"
["${INPUTDATA_ROOT}/MOM6_FIX/${OCNRES}/MOM_channels_SPEAR"]="INPUT/"
["${INPUTDATA_ROOT}/MOM6_FIX/${OCNRES}/KH_background_2d.nc"]="INPUT/"
["${INPUTDATA_ROOT}/MOM6_FIX/${OCNRES}/tidal_amplitude.nc"]="INPUT/"
["${INPUTDATA_ROOT}/MOM6_FIX/${OCNRES}/seawifs_1998-2006_smoothed_2X.nc"]="INPUT/"
)
fi


