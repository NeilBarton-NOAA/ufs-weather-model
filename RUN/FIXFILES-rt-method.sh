#!/bin/bash
########################
# RT method for copying link files
FV3_RUN=${FV3_RUN:-cpld_control_run.IN}
[[ -f fv3_run ]] && rm fv3_run
for i in ${FV3_RUN}; do
    atparse < ${PATHRT}/fv3_conf/${i} >> fv3_run
done

if [[ ${DEBUG} == F ]]; then
    RT_SUFFIX=""
    echo 'RUNNING fv3_run'
    source ./fv3_run
    # fix files for FV3
    cp ${INPUTDATA_ROOT}/FV3_fix/*.txt .
    cp ${INPUTDATA_ROOT}/FV3_fix/*.f77 .
    cp ${INPUTDATA_ROOT}/FV3_fix/*.dat .
    cp ${INPUTDATA_ROOT}/FV3_fix/fix_co2_proj/* .
    if [[ $TILEDFIX != .true. ]]; then
        cp ${INPUTDATA_ROOT}/FV3_fix/*.grb .
    fi
fi

