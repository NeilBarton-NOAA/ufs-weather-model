#!/bin/bash
set -u
echo 'FV3-config.sh'
INPUT_NML=${INPUT_NML:-cpld_control.nml.IN}
MODEL_CONFIGURE=${MODEL_CONFIGURE:-model_configure.IN}
CCPP_SUITE=${CPP_SUITE:-FV3_GFS_v17_coupled_p8}
DIAG_TABLE=${DIAG_TABLE:-diag_table_p8_template}
FV3_RUN=${FV3_RUN:-cpld_control_run.IN}

# NMPI options
INPES=${ATM_INPES:-$INPES}
JNPES=${ATM_JNPES:-$JNPES}
ATM_compute_tasks=$(( INPES * JNPES * NTILES ))

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

WPG=${WPG:-48}
THRD_ATM=${THRD_ATM:-2}
IMP_PHYSICS=${ATM_PHYSICS:-${IMP_PHYSICS}}
NPZ=${ATM_LEVELS:-127}
NPZP=$(( NPZ + 1 ))
WRTTASK_PER_GROUP=$(( WPG * THRD_ATM ))
RESTART_N=${RESTART_N:-3}
RESTART_INTERVAL="${RESTART_N} -1"

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

