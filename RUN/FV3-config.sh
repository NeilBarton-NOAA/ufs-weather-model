#!/bin/bash
set -u
declare -A LF
LF=()
echo 'FV3-config.sh'
mkdir -p INPUT RESTART

####################################
# namelist defaults
INPUT_NML=${INPUT_NML:-cpld_control.nml.IN}
MODEL_CONFIGURE=${MODEL_CONFIGURE:-model_configure.IN}
CCPP_SUITE=${CPP_SUITE:-FV3_GFS_v17_coupled_p8}
DIAG_TABLE=${DIAG_TABLE:-diag_table_p8_template}

####################################
# restarts 
if [[ ${FIX_METHOD} == 'LINK' ]]; then
ATM_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/p8c/${ATMRES}_L${NPZ}/INPUT}
n_files=$( find ${ATM_ICDIR} -name "*sfc_data*nc" 2>/dev/null | wc -l )
if (( ${n_files} == 0 )); then
    echo '  FATAL: no atm ICs found in:' ${ATM_ICDIR}
    exit 1
fi
n_files=$( find ${ATM_ICDIR} -name "*gfs_data*.nc" 2>/dev/null | wc -l)
if (( ${n_files} == (( NTILES )) )); then
    echo "  FV3 Cold Start"
    PREFIXS="gfs_data sfc_data"
    for t in $(seq ${NTILES}); do
        for v in ${PREFIXS}; do
            f=$( find ${ATM_ICDIR} -name "${v}.tile${t}.nc" )
            LF+=(["${f}"]="INPUT/")
        done
    done
    f=$( find ${ATM_ICDIR} -name "gfs_ctrl.nc" )
    LF+=(["${f}"]="INPUT/")
else #ATM WARMSTART
    echo "  FV3 Warm Start"
    warm_files='*ca_data*nc \
                *fv_core.res*nc \
                *fv_srf_wnd.res*nc \
                *fv_srf_wnd.res*nc \
                *fv_tracer*nc \
                *phy_data*nc \
                *sfc_data*nc'
    for warm_file in ${warm_files}; do
        files=$( find ${ATM_ICDIR} -name "${atm_ic}" )
        for atm_ic in ${files}; do
            f=$( basename ${atm_ic} )
            if [[ ${f:11:4} == '0000' ]]; then
                f=${f:16}
            fi
            LF+=(["${atm_ic}"]="INPUT/${f}")
        done
    done
    # make coupler.res file
    cat >> INPUT/coupler.res << EOF
 3        (Calendar: no_calendar=0, thirty_day_months=1, julian=2, gregorian=3, noleap=4)
 ${SYEAR}  ${SMONTH}  ${SDAY}  ${SHOUR}     0     0        Model start time:   year, month, day, hour, minute, second
 ${SYEAR}  ${SMONTH}  ${SDAY}  ${SHOUR}     0     0        Current model time: year, month, day, hour, minute, second
EOF
    # change namelist options
    WARM_START=.true.
    MAKE_NH=.false.
    NA_INIT=0
    EXTERNAL_IC=.false.
    NGGPS_IC=.false.
    MOUNTAIN=.true.
    TILEDFIX=.true.
fi #cold start/warm start
fi #LINK

####################################
# IO options
RESTART_N=${RESTART_FREQ:-${FHMAX}}
OUTPUT_N=${OUTPUT_FREQ:-${FHMAX}}
WRITE_DOPOST=${DOPOST_WRITE:-.false.}
RESTART_INTERVAL="${RESTART_N} -1"
OUTPUT_FH="${OUTPUT_N} -1"
OUTPUT_FILE="'netcdf_parallel' 'netcdf_parallel'"
#[[ ${QUILTING} == '.false.' ]] && OUTPUT_HISTORY=.false. # not sure what OUTPUT_HISTORY controls

####################################
# NMPI options and thread options
INPES=${ATM_INPES:-$INPES}
JNPES=${ATM_JNPES:-$JNPES}
atm_omp_num_threads=${ATM_THRD:-${atm_omp_num_threads}}
WPG=${ATM_WPG:-0}
WRTTASK_PER_GROUP=$(( WPG * atm_omp_num_threads ))
[[ ${WPG} == 0 ]] && QUILTING = '.false'

####################################
# resolution options
NPZ=${ATM_LEVELS:-127}
NPZP=$(( NPZ + 1 ))
case "${ATMRES}" in
    "C384") DT_ATMOS=${ATM_DT:-$DT_ATMOS}
            IMO=1536 
            JMO=768
            NPX=385
            NPY=385;;
esac

####################################
#  input.nml edits based on components running
[[ ${CHM_tasks} == 0 ]] && CPLCHM=.false.
[[ ${WAV_tasks} == 0 ]] && CPLWAV=.false. && CPLWAV2ATM=.false.

####################################
# namelist options 
IMP_PHYSICS=${ATM_PHYSICS:-${IMP_PHYSICS}}
ICHUNK2D=$(( 4 * ${ATMRES:1} ))
JCHUNK2D=$(( 2 * ${ATMRES:1} ))
ICHUNK3D=$(( 4 * ${ATMRES:1} ))
JCHUNK3D=$(( 2 * ${ATMRES:1} ))
KCHUNK3D=1
IDEFLATE=1
NBITS=14
DNATS=0
DOGP_CLDOPTICS_LUT=.false.
DOGP_LWSCAT=.false.

####################################
# parse namelist files
atparse < ${PATHRT}/parm/${INPUT_NML} > input.nml
atparse < ${PATHRT}/parm/${MODEL_CONFIGURE} > model_configure
cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table #TODO: not sure if field_table is needed
if [[ ${QUILTING} == '.true.' ]]; then
    atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
else
cat <<EOF > diag_table
${SYEAR}${SMONTH}${SDAY}.${SHOUR}Z.${ATMRES}.64bit.non-mono
${SYEAR} ${SMONTH} ${SDAY} ${SHOUR} 0 0
EOF
fi
####################################
# FIX FILES
#["${INPUTDATA_ROOT}/FV3_fix/postxconfig-NT.txt"]="."
#["${INPUTDATA_ROOT}/FV3_fix/postxconfig-NT_FH00.txt"]="."
LF+=(
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2009.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2011.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2012.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2013.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2014.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2015.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2016.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2017.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2018.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2019.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2020.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_2021.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2historicaldata_glob.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/co2monthlycyc.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/sfc_emissivity_idx.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/solarconstant_noaa_an.txt"]="."
["${INPUTDATA_ROOT}/FV3_fix/aerosol.dat"]="."
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m01.nc"]="aeroclim.m01.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m02.nc"]="aeroclim.m02.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m03.nc"]="aeroclim.m03.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m04.nc"]="aeroclim.m04.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m05.nc"]="aeroclim.m05.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m06.nc"]="aeroclim.m06.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m07.nc"]="aeroclim.m07.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m08.nc"]="aeroclim.m08.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m09.nc"]="aeroclim.m09.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m10.nc"]="aeroclim.m10.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m11.nc"]="aeroclim.m11.nc"
["${FIX_DIR}/aer/20220805/merra2.aerclim.2003-2014.m12.nc"]="aeroclim.m12.nc"
["${FIX_DIR}/am/20220805/qr_acr_qgV2.dat"]="."
["${FIX_DIR}/am/20220805/qr_acr_qsV2.dat"]="."
["${FIX_DIR}/am/20220805/global_h2o_pltc.f77"]="global_h2oprdlos.f77"
["${FIX_DIR}/am/20220805/ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"]="global_o3prdlos.f77"
["${FIX_DIR}/am/20220805/global_soilmgldas.statsgo.t1534.3072.1536.grb"]="."
["${FIX_DIR}/am/20220805/global_slmask.t1534.3072.1536.grb"]="."
["${FIX_DIR}/am/20220805/CFSR.SEAICE.1982.2012.monthly.clim.grb"]="."
["${FIX_DIR}/am/20220805/IMS-NIC.blended.ice.monthly.clim.grb"]="."
["${FIX_DIR}/am/20220805/RTGSST.1982.2012.monthly.clim.grb"]="."
)
#if [ ${TILEDFIX} = .true. ]; then
LF+=(
["${FIX_DIR}/am/20220805/global_albedo4.1x1.grb"]="."
["${FIX_DIR}/am/20220805/global_glacier.2x2.grb"]="."
["${FIX_DIR}/am/20220805/global_maxice.2x2.grb"]="."
["${FIX_DIR}/am/20220805/global_shdmax.0.144x0.144.grb"]="."
["${FIX_DIR}/am/20220805/global_shdmin.0.144x0.144.grb"]="."
["${FIX_DIR}/am/20220805/global_slope.1x1.grb"]="."
["${FIX_DIR}/am/20220805/global_snoclim.1.875.grb"]="."
["${FIX_DIR}/am/20220805/global_tg3clim.2.6x1.5.grb"]="."
["${FIX_DIR}/am/20220805/global_vegfrac.0.144.decpercent.grb"]="."
["${FIX_DIR}/am/20220805/global_zorclim.1x1.grb"]="."
["${FIX_DIR}/am/20220805/seaice_newland.grb"]="."
)
#fi
if [ ${WRITE_DOPOST} = .true. ]; then
LF+=(
["${PATHRT}/parm/post_itag"]="itag"
["${PATHRT}/parm/postxconfig-NT.txt"]="."
["${PATHRT}/parm/postxconfig-NT_FH00.txt"]="."
["${PATHRT}/parm/params_grib2_tbl_new"]="."
)
fi

if (( ${IMP_PHYSICS} == 8 )); then
LF+=(
["${FIX_DIR}/am/20220805/CCN_ACTIVATE.BIN"]="."
["${FIX_DIR}/am/20220805/freezeH2O.dat"]="."
["${FIX_DIR}/am/20220805/qr_acr_qg.dat"]="."
["${FIX_DIR}/am/20220805/qr_acr_qs.dat"]="."
)
fi

LF+=(
["${FIX_DIR}/lut/20220805/optics_BC.v1_3.dat"]="optics_BC.dat"
["${FIX_DIR}/lut/20220805/optics_OC.v1_3.dat"]="optics_OC.dat"
["${FIX_DIR}/lut/20220805/optics_DU.v15_3.dat"]="optics_DU.dat"
["${FIX_DIR}/lut/20220805/optics_SS.v3_3.dat"]="optics_SS.dat"
["${FIX_DIR}/lut/20220805/optics_SU.v1_3.dat"]="optics_SU.dat"
)

for t in $(seq ${NTILES}); do
    LF+=(["${FIX_DIR}/orog/20220805/${ATMRES}.mx${OCNRES}/${ATMRES}_grid.tile${t}.nc"]="INPUT/")
    LF+=(["${FIX_DIR}/orog/20220805/${ATMRES}.mx${OCNRES}/oro_${ATMRES}.mx${OCNRES}.tile${t}.nc"]="INPUT/oro_data.tile${t}.nc")
    LF+=(["${FIX_DIR}/ugwd/20220805/${ATMRES}/${ATMRES}_oro_data_ls.tile${t}.nc"]="INPUT/oro_data_ls.tile${t}.nc")
    LF+=(["${FIX_DIR}/ugwd/20220805/${ATMRES}/${ATMRES}_oro_data_ss.tile${t}.nc"]="INPUT/oro_data_ss.tile${t}.nc")
    PREFIXS="
    facsf 
    maximum_snow_albedo 
    slope_type 
    snowfree_albedo 
    soil_type 
    substrate_temperature 
    vegetation_greenness 
    vegetation_type"
    for v in ${PREFIXS}; do
        LF+=(["${FIX_DIR}/orog/20220805/${ATMRES}.mx${OCNRES}/fix_sfc/${ATMRES}.${v}.tile${t}.nc"]=".")
    done
done
LF+=(["${FIX_DIR}/cpl/20220805/a${ATMRES}o${OCNRES}/grid_spec.nc"]="INPUT/")
LF+=(["${FIX_DIR}/orog/20220805/${ATMRES}.mx${OCNRES}/${ATMRES}_mosaic.nc"]="INPUT/")
