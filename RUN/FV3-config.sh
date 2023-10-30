#!/bin/bash
####################################
# Appendix A
# https://www.gfdl.noaa.gov/wp-content/uploads/2020/02/FV3-Technical-Description.pdf
# experimental fix files for different resolutions
#   hera:/scratch2/NCEPDEV/stmp1/Sanath.Kumar/my_grids
####################################
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
FIELD_TABLE=${FIELD_TABLE:-field_table_thompson_noaero_tke_GOCART}
ENS_SETTINGS=${ENS_SETTINGS:-T}

####################################
# restarts 
ATM_ICDIR=${ICDIR:-${INPUTDATA_ROOT_BMIC}/${SYEAR}${SMONTH}${SDAY}${SHOUR}/p8c/${ATMRES}_L${NPZ}/INPUT}
n_files=$( find -L ${ATM_ICDIR} -name "*sfc_data*nc" 2>/dev/null | wc -l )
if (( ${n_files} == 0 )); then
    echo '  FATAL: no atm ICs found in:' ${ATM_ICDIR}
    exit 1
fi
n_files=$( find -L ${ATM_ICDIR} -name "*gfs_data*.nc" 2>/dev/null | wc -l)
if (( ${n_files} == (( NTILES )) )); then
    echo "  FV3 Cold Start"
    PREFIXS="gfs_data sfc_data"
    for t in $(seq ${NTILES}); do
        for v in ${PREFIXS}; do
            f=$( find -L ${ATM_ICDIR} -name "${v}.tile${t}.nc" )
            if [[ ${FIX_METHOD} == 'LINK' ]]; then
                LF+=(["${f}"]="INPUT/")
            else
                cp ${f} INPUT/
            fi
        done
    done
    f=$( find -L ${ATM_ICDIR} -name "gfs_ctrl.nc" )
    if [[ ${FIX_METHOD} == 'LINK' ]]; then
        LF+=(["${f}"]="INPUT/")
    else
        cp ${f} INPUT/$(basename ${f})
    fi
else #ATM WARMSTART
    echo "  FV3 Warm Start"
    warm_files='*ca_data*nc \
                *fv_core.res*nc \
                *fv_srf_wnd.res*nc \
                *fv_tracer*nc \
                *phy_data*nc \
                *sfc_data*nc'
    for warm_file in ${warm_files}; do
        files=$( find -L ${ATM_ICDIR} -name "${warm_file}" )
        for atm_ic in ${files}; do
            f=$( basename ${atm_ic} )
            if [[ ${f:11:4} == '0000' ]]; then
                f=${f:16}
            fi
            if [[ ${FIX_METHOD} == 'LINK' ]]; then
                LF+=(["${atm_ic}"]="INPUT/${f}")
            else
                cp ${atm_ic} INPUT/${f}
            fi
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

####################################
# IO options
RESTART_N=${RESTART_FREQ:-${FHMAX}}
OUTPUT_N=${OUTPUT_FREQ:-${FHMAX}}
RESTART_INTERVAL="${RESTART_N} -1"
OUTPUT_FH="${OUTPUT_N} -1"
case "${ATMRES}" in
    "C384") 
        OUTPUT_FILE="'netcdf_parallel' 'netcdf_parallel'"
        ;;
    "C192" | "C96" ) 
        OUTPUT_FILE="'netcdf'"
        ;;
    *)
        echo "  FATAL: ${ATMRES} not found yet supported"
        exit 1
        ;;
esac


####################################
# NMPI options and thread options
INPES=${ATM_INPES:-$INPES}
JNPES=${ATM_JNPES:-$JNPES}
atm_omp_num_threads=${ATM_THRD:-${atm_omp_num_threads}}
WPG=${ATM_WPG:-0}
WRTTASK_PER_GROUP=$(( WPG * atm_omp_num_threads ))
[[ ${WPG} == 0 ]] && QUILTING='.false.' 

####################################
# resolution options
NPZ=${ATM_LEVELS:-127}
NPZP=$(( NPZ + 1 ))
case "${ATMRES}" in
    "C384") 
        DT_ATMOS=${ATM_DT:-$DT_ATMOS}
        ICHUNK2D=$(( 4 * ${ATMRES:1} ))
        JCHUNK2D=$(( 2 * ${ATMRES:1} ))
        ICHUNK3D=$(( 4 * ${ATMRES:1} ))
        JCHUNK3D=$(( 2 * ${ATMRES:1} ))
        KCHUNK3D=1
        IDEFLATE=1
        NBITS=14
        DNATS=0
        ;;
    "C192")
        DT_ATMOS=${ATM_DT:-450}
        ;;
    "C96") 
        DT_ATMOS=${ATM_DT:-720}
        FNSMCC="'global_soilmgldas.statsgo.t1534.3072.1536.grb'"
        FNMSKH="'global_slmask.t1534.3072.1536.grb'"
        DOMAINS_STACK_SIZE=8000000
        ;;
    *)
        echo "  FATAL: ${ATMRES} not found yet supported"
        exit 1
        ;;
esac
res=$( echo ${ATMRES} | cut -c2- )
IMO=$(( ${res} * 4 ))
JMO=$(( ${res} * 2 ))
NPX=$(( ${res} + 1 ))
NPY=$(( ${res} + 1 ))
FNALBC="'${ATMRES}.snowfree_albedo.tileX.nc'"
FNALBC2="'${ATMRES}.facsf.tileX.nc'"
FNVETC="'${ATMRES}.vegetation_type.tileX.nc'"
FNSOTC="'${ATMRES}.soil_type.tileX.nc'"
FNABSC="'${ATMRES}.maximum_snow_albedo.tileX.nc'"
FNTG3C="'${ATMRES}.substrate_temperature.tileX.nc'"
FNVEGC="'${ATMRES}.vegetation_greenness.tileX.nc'"
FNSLPC="'${ATMRES}.slope_type.tileX.nc'"
FNVMNC="'${ATMRES}.vegetation_greenness.tileX.nc'"
FNVMXC="'${ATMRES}.vegetation_greenness.tileX.nc'"
DT_INNER=${DT_ATMOS}

####################################
#  input.nml edits based on components running
[[ ${CHM_tasks} == 0 ]] && CPLCHM=.false. && FIELD_TABLE=field_table_thompson_noaero_tke_progsigma
[[ ${WAV_tasks} == 0 ]] && CPLWAV=.false. && CPLWAV2ATM=.false.
[[ ${CHM_tasks} != 0 ]] && IAER=2011

####################################
# get latst versions of fix files
FIX_VER_OROG=$(ls -ltr ${FIX_DIR}/orog | tail -n 1 | awk '{print $9}')
FIX_VER_AER=$(ls -ltr ${FIX_DIR}/aer | tail -n 1 | awk '{print $9}')
FIX_VER_AM=$(ls -ltr ${FIX_DIR}/am | tail -n 1 | awk '{print $9}')
FIX_VER_LUT=$(ls -ltr ${FIX_DIR}/lut | tail -n 1 | awk '{print $9}')
FIX_VER_UGWD=$(ls -ltr ${FIX_DIR}/ugwd | tail -n 1 | awk '{print $9}')
FIX_VER_CPL=$(ls -ltr ${FIX_DIR}/cpl | tail -n 1 | awk '{print $9}')
FV3_OROG_DIR=${FV3_OROG_DIR:-${FIX_DIR}/orog/${FIX_VER_OROG}}

####################################
# namelist options
IMP_PHYSICS=${ATM_PHYSICS:-${IMP_PHYSICS}}
if [[ ${FV3_OROG_DIR}} == *Kumar* ]]; then
    FRAC_GRID=.false.
fi
if [[ ${ENS_SETTINGS} == T ]]; then
    DO_SPPT=.true.
    DO_SHUM=.false.
    DO_SKEB=.true.
    PERT_MP=.false.
    PERT_RADTEND=.false.
    PERT_CLDS=.true.
fi

####################################
# parse and edit namelist files
atparse < ${PATHRT}/parm/${INPUT_NML} > input.nml
atparse < ${PATHRT}/parm/${MODEL_CONFIGURE} > model_configure
cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table 
if [[ ${QUILTING} == '.true.' ]]; then
    atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
    sed -i "s:6,  "hours", 1,:${OUTPUT_FH},  "hours", 1,:g" diag_table
    sed -i "s:1,  "days", 1,:${OUTPUT_FH},  "hours", 1,:g" diag_table
else
cat <<EOF > diag_table
${SYEAR}${SMONTH}${SDAY}.${SHOUR}Z.${ATMRES}.64bit.non-mono
${SYEAR} ${SMONTH} ${SDAY} ${SHOUR} 0 0
EOF
fi

# add stochastic options to input.nml
if [[ ${ENS_SETTINGS} == T ]]; then
ens_options="\\
  skeb = 0.8,-999,-999,-999,-999\n\
  iseed_skeb = 0\n\
  skeb_tau = 2.16E4,1.728E5,2.592E6,7.776E6,3.1536E7\n\
  skeb_lscale = 500.E3,1000.E3,2000.E3,2000.E3,2000.E3\n\
  skebnorm = 1\n\
  skeb_npass = 30\n\
  skeb_vdof = 5\n\
  sppt = 0.56,0.28,0.14,0.056,0.028\n\
  iseed_sppt = 20210929000103,20210929000104,20210929000105,20210929000106,20210929000107\n\
  sppt_tau = 2.16E4,2.592E5,2.592E6,7.776E6,3.1536E7\n\
  sppt_lscale = 500.E3,1000.E3,2000.E3,2000.E3,2000.E3\n\
  sppt_logit = .true.\n\
  sppt_sfclimit = .true.\n\
  use_zmtnblck = .true.\n\
  OCNSPPT=0.8,0.4,0.2,0.08,0.04\n\
  OCNSPPT_LSCALE=500.E3,1000.E3,2000.E3,2000.E3,2000.E3\n\
  OCNSPPT_TAU=2.16E4,2.592E5,2.592E6,7.776E6,3.1536E7\n\
  ISEED_OCNSPPT=20210929000108,20210929000109,20210929000110,20210929000111,20210929000112\n\
  EPBL=0.8,0.4,0.2,0.08,0.04\n\
  EPBL_LSCALE=500.E3,1000.E3,2000.E3,2000.E3,2000.E3\n\
  EPBL_TAU=2.16E4,2.592E5,2.592E6,7.776E6,3.1536E7\n\
  ISEED_EPBL=20210929000113,20210929000114,20210929000115,20210929000116,20210929000117
"
sed -i "/nam_stochy/a ${ens_options}" input.nml
fi

# add options to model_configure namelist
ln=$(grep -wn nbits model_configure | cut -d: -f1) && ln=$(( ln + 1))
sed -i "${ln} i ichunk2d:                $(( 4 * ${ATMRES:1} ))" model_configure && ln=$(( ln + 1))
sed -i "${ln} i jchunk2d:                $(( 2 * ${ATMRES:1} ))" model_configure

####################################
# FIX FILES
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
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m01.nc"]="aeroclim.m01.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m02.nc"]="aeroclim.m02.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m03.nc"]="aeroclim.m03.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m04.nc"]="aeroclim.m04.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m05.nc"]="aeroclim.m05.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m06.nc"]="aeroclim.m06.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m07.nc"]="aeroclim.m07.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m08.nc"]="aeroclim.m08.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m09.nc"]="aeroclim.m09.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m10.nc"]="aeroclim.m10.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m11.nc"]="aeroclim.m11.nc"
["${FIX_DIR}/aer/${FIX_VER_AER}/merra2.aerclim.2003-2014.m12.nc"]="aeroclim.m12.nc"
["${FIX_DIR}/am/${FIX_VER_AM}/global_h2o_pltc.f77"]="global_h2oprdlos.f77"
["${FIX_DIR}/am/${FIX_VER_AM}/ozprdlos_2015_new_sbuvO3_tclm15_nuchem.f77"]="global_o3prdlos.f77"
["${FIX_DIR}/am/${FIX_VER_AM}/global_soilmgldas.statsgo.t1534.3072.1536.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_slmask.t1534.3072.1536.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/CFSR.SEAICE.1982.2012.monthly.clim.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/IMS-NIC.blended.ice.monthly.clim.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/RTGSST.1982.2012.monthly.clim.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_albedo4.1x1.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_glacier.2x2.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_maxice.2x2.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_shdmax.0.144x0.144.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_shdmin.0.144x0.144.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_slope.1x1.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_snoclim.1.875.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_tg3clim.2.6x1.5.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_vegfrac.0.144.decpercent.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/global_zorclim.1x1.grb"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/seaice_newland.grb"]="."
)
if [ ${WRITE_DOPOST} = .true. ]; then
if [[ -f ${PATHRT}/parm/post_itag_gfs ]]; then
LF+=(
["${PATHRT}/parm/post_itag_gfs"]="itag"
["${PATHRT}/parm/postxconfig-NT-gfs.txt"]="postxconfig-NT.txt"
["${PATHRT}/parm/postxconfig-NT-gfs_FH00.txt"]="postxconfig-NT_FH00.txt"
["${PATHRT}/parm/params_grib2_tbl_new"]="."
["${PATHRT}/parm/noahmptable.tbl"]="."
)
else
LF+=(
["${PATHRT}/parm/post_itag"]="itag"
["${PATHRT}/parm/postxconfig-NT.txt"]="postxconfig-NT.txt"
["${PATHRT}/parm/postxconfig-NT_FH00.txt"]="postxconfig-NT_FH00.txt"
["${PATHRT}/parm/params_grib2_tbl_new"]="."
)
fi
fi

if (( ${IMP_PHYSICS} == 8 )); then
LF+=(
["${FIX_DIR}/am/${FIX_VER_AM}/CCN_ACTIVATE.BIN"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/freezeH2O.dat"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/qr_acr_qgV2.dat"]="."
["${FIX_DIR}/am/${FIX_VER_AM}/qr_acr_qsV2.dat"]="."
)
fi

LF+=(
["${FIX_DIR}/lut/${FIX_VER_LUT}/optics_BC.v1_3.dat"]="optics_BC.dat"
["${FIX_DIR}/lut/${FIX_VER_LUT}/optics_OC.v1_3.dat"]="optics_OC.dat"
["${FIX_DIR}/lut/${FIX_VER_LUT}/optics_DU.v15_3.dat"]="optics_DU.dat"
["${FIX_DIR}/lut/${FIX_VER_LUT}/optics_SS.v3_3.dat"]="optics_SS.dat"
["${FIX_DIR}/lut/${FIX_VER_LUT}/optics_SU.v1_3.dat"]="optics_SU.dat"
)

for t in $(seq ${NTILES}); do
    LF+=(["${FV3_OROG_DIR}/${ATMRES}.mx${OCNRES}/${ATMRES}_grid.tile${t}.nc"]="INPUT/")
    oro_tile=${FV3_OROG_DIR}/${ATMRES}.mx${OCNRES}/${ATMRES}_oro_data.tile${t}.nc
    if [[ ! -f ${oro_tile} ]]; then
        oro_tile=${FV3_OROG_DIR}/${ATMRES}.mx${OCNRES}/oro_${ATMRES}.mx${OCNRES}.tile${t}.nc
    fi
    LF+=(["${oro_tile}"]="INPUT/oro_data.tile${t}.nc")
    LF+=(["${FIX_DIR}/ugwd/${FIX_VER_UGWD}/${ATMRES}/${ATMRES}_oro_data_ls.tile${t}.nc"]="INPUT/oro_data_ls.tile${t}.nc")
    LF+=(["${FIX_DIR}/ugwd/${FIX_VER_UGWD}/${ATMRES}/${ATMRES}_oro_data_ss.tile${t}.nc"]="INPUT/oro_data_ss.tile${t}.nc")
    PREFIXS="
    facsf 
    substrate_temperature
    maximum_snow_albedo 
    snowfree_albedo 
    soil_color
    soil_type 
    vegetation_type
    vegetation_greenness 
    slope_type 
    "
    for v in ${PREFIXS}; do
        LF+=(["${FV3_OROG_DIR}/${ATMRES}/sfc/${ATMRES}.${v}.tile${t}.nc"]=".")
        #LF+=(["${FV3_OROG_DIR}/${ATMRES}.mx${OCNRES}/fix_sfc/${ATMRES}.${v}.tile${t}.nc"]=".")
    done
done
GRID_SPEC_FILE=${GRID_SPEC_FILE:-${FIX_DIR}/cpl/${FIX_VER_CPL}/a${ATMRES}o${OCNRES}/grid_spec.nc}
LF+=(["${GRID_SPEC_FILE}"]="INPUT/")
LF+=(["${FV3_OROG_DIR}/${ATMRES}.mx${OCNRES}/${ATMRES}_mosaic.nc"]="INPUT/")
