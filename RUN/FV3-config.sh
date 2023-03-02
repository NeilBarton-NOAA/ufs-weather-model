#!/bin/bash
set -u
echo 'FV3-config.sh'
# namelist defaults
INPUT_NML=${INPUT_NML:-cpld_control.nml.IN}
MODEL_CONFIGURE=${MODEL_CONFIGURE:-model_configure.IN}
CCPP_SUITE=${CPP_SUITE:-FV3_GFS_v17_coupled_p8}
DIAG_TABLE=${DIAG_TABLE:-diag_table_p8_template}
FV3_RUN=${FV3_RUN:-cpld_control_run.IN}
# FV3 defaults
WPG=${ATM_WPG:-48}
IMP_PHYSICS=${ATM_PHYSICS:-${IMP_PHYSICS}}
NPZ=${ATM_LEVELS:-127}
RESTART_N=${RESTART_FREQ:-${FHMAX}}
OUTPUT_N=${OUTPUT_FREQ:-${FHMAX}}
WRITE_DPOST=${WRITE_DPOST:-.false.}

# NMPI options and thread options
INPES=${ATM_INPES:-$INPES}
JNPES=${ATM_JNPES:-$JNPES}
atm_omp_num_threads=${ATM_THRD:-${atm_omp_num_threads}}

#  input.nml edits
[[ ${CHM_NMPI} == 0 ]] && CPLCHM=.false.
[[ ${WAV_NMPI} == 0 ]] && CPLWAV=.false. && CPLWAV2ATM=.false.

# ICs, fix files, and namelists files
FV3_RUN=${FV3_RUN:-cpld_control_run.IN}
case "${ATM_RES}" in
    "C384") DT_ATMOS=${ATM_DT:-$DT_ATMOS}
            IMO=1536 
            JMO=768
            NPX=385
            NPY=385
            DNATS=2;;
esac


WRTTASK_PER_GROUP=$(( WPG * atm_omp_num_threads ))
NPZP=$(( NPZ + 1 ))
RESTART_INTERVAL="${RESTART_N} -1"
OUTPUT_FH="${OUTPUT_N} -1"

# values similar to global workflow
OUTPUT_FILE="'netcdf_parallel' 'netcdf_parallel'"
ICHUNK2D=$(( 4 * ${ATM_RES:1} ))
JCHUNK2D=$(( 2 * ${ATM_RES:1} ))
ICHUNK3D=$(( 4 * ${ATM_RES:1} ))
JCHUNK3D=$(( 2 * ${ATM_RES:1} ))
KCHUNK3D=1
IDEFLATE=1
NBITS=14

atparse < ${PATHRT}/parm/${INPUT_NML} > input.nml
atparse < ${PATHRT}/parm/${MODEL_CONFIGURE} > model_configure
atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table #TODO: not sure if field_table is needed

[[ -f fv3_run ]] && rm fv3_run
for i in ${FV3_RUN}; do
    atparse < ${PATHRT}/fv3_conf/${i} >> fv3_run
done

####################################
# fix files
cp ${INPUTDATA_ROOT}/FV3_fix/*.txt .
cp ${INPUTDATA_ROOT}/FV3_fix/*.f77 .
cp ${INPUTDATA_ROOT}/FV3_fix/*.dat .
cp ${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/* .
if [[ $TILEDFIX != .true. ]]; then
    cp ${INPUTDATA_ROOT}/FV3_fix/*.grb .
fi

####################################
# other files
# get needed data, TODO, parse this into links and only what is needed
DEBUG=${DEBUG:-F}
if [[ ${DEBUG} == F ]]; then
    RT_SUFFIX=""
    echo 'RUNNING fv3_run'
    source ./fv3_run 
fi

