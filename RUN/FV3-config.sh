#!/bin/bash
set -u
echo 'FV3-config.sh'
####################################
# namelist defaults
INPUT_NML=${INPUT_NML:-cpld_control.nml.IN}
MODEL_CONFIGURE=${MODEL_CONFIGURE:-model_configure.IN}
CCPP_SUITE=${CPP_SUITE:-FV3_GFS_v17_coupled_p8}
DIAG_TABLE=${DIAG_TABLE:-diag_table_p8_template}

####################################
# NMPI options and thread options
INPES=${ATM_INPES:-$INPES}
JNPES=${ATM_JNPES:-$JNPES}
atm_omp_num_threads=${ATM_THRD:-${atm_omp_num_threads}}
WPG=${ATM_WPG:-48}
WRTTASK_PER_GROUP=$(( WPG * atm_omp_num_threads ))

####################################
#  input.nml edits based on components running
[[ ${CHM_tasks} == 0 ]] && CPLCHM=.false.
[[ ${WAV_tasks} == 0 ]] && CPLWAV=.false. && CPLWAV2ATM=.false.

####################################
# resolution options
NPZ=${ATM_LEVELS:-127}
NPZP=$(( NPZ + 1 ))
case "${ATM_RES}" in
    "C384") DT_ATMOS=${ATM_DT:-$DT_ATMOS}
            IMO=1536 
            JMO=768
            NPX=385
            NPY=385;;
esac

####################################
# IO options
RESTART_N=${RESTART_FREQ:-${FHMAX}}
OUTPUT_N=${OUTPUT_FREQ:-${FHMAX}}
WRITE_DPOST=${WRITE_DPOST:-.false.}
RESTART_INTERVAL="${RESTART_N} -1"
OUTPUT_FH="${OUTPUT_N} -1"
OUTPUT_FILE="'netcdf_parallel' 'netcdf_parallel'"

####################################
# namelist options 
IMP_PHYSICS=${ATM_PHYSICS:-${IMP_PHYSICS}}
ICHUNK2D=$(( 4 * ${ATM_RES:1} ))
JCHUNK2D=$(( 2 * ${ATM_RES:1} ))
ICHUNK3D=$(( 4 * ${ATM_RES:1} ))
JCHUNK3D=$(( 2 * ${ATM_RES:1} ))
KCHUNK3D=1
IDEFLATE=1
NBITS=14
DNATS=0
DOGP_CLDOPTICS_LUT=.false.
DOGP_LWSCAT=.false.

####################################
# look for restarts if provided
#if [[ ${IC_DIR} != 'none' ]]; then
#    mkdir -p RESTART
#    ln -sf ${IC_DIR}/atm/* RESTART/
#    WARM_START=.true.
#    MAKE_NH=.false.
#    NA_INIT=0
#    EXTERNAL_IC=.false.
#    NGGPS_IC=.false.
#    MOUNTAIN=.true.
#fi

####################################
# parse namelist files
atparse < ${PATHRT}/parm/${INPUT_NML} > input.nml
atparse < ${PATHRT}/parm/${MODEL_CONFIGURE} > model_configure
atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table #TODO: not sure if field_table is needed

####################################
# fix files
cp ${INPUTDATA_ROOT}/FV3_fix/*.txt .
cp ${INPUTDATA_ROOT}/FV3_fix/*.f77 .
cp ${INPUTDATA_ROOT}/FV3_fix/*.dat .
cp ${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/* .
if [[ $TILEDFIX != .true. ]]; then
    cp ${INPUTDATA_ROOT}/FV3_fix/*.grb .
fi

