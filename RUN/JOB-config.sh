#!/bin/bash
set -u
UFS_EXEC=${UFS_EXEC:-ufs_model}
JBNME=${TEST_NAME:-UFS}
WLCLK=${WALLCLOCK:-$WLCLK_dflt}
(( $( echo "${WLCLK} < 30" | bc) )) && WLCLK=$(echo "${WLCLK} * 60" | bc)
WLCLK=${WLCLK%.*}
# Total Nodes
TPN=$(( TPN / THRD ))
if (( TASKS < TPN )); then
  TPN=${TASKS}
fi
NODES=$(( TASKS / TPN ))
if (( NODES * TPN < TASKS )); then
  NODES=$(( NODES + 1 ))
fi
TASKS=$(( NODES * TPN ))

# copy needed items
cp ${PATHRT}/module-setup.sh .
cp ${module_file} modules.fv3.lua
cp ${UFS_HOME}/modulefiles/ufs_common* .
cp ${UFS_HOME}/bin/${UFS_EXEC} fv3.exe


# Create job_card
atparse < $PATHRT/fv3_conf/${JOB_CARD} > job_card


