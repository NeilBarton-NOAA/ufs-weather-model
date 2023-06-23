#!/bin/bash

TYPE=$1
NPB_FIXDIR=$2
HSI_DIR=/NCEPDEV/emc-marine/1year/Neil.Barton/FIX
files=""
mkdir -p ${NPB_FIXDIR} 
if [[ ${TYPE} == "GOCART_OPS" ]]; then
    files="AERO_HISTORY.rc CAP.rc DU2G_instance_DU.rc GOCART2G_GridComp.rc field_table"
fi

for f in ${files}; do
    if [[ ! -f ${NPB_FIXDIR}/${f} ]]; then
        echo "GETTING: ${HSI_DIR}/${f}"
        hsi -q get ${NPB_FIXDIR}/${f} : ${HSI_DIR}/${f} 2>/dev/null
        (( $? != 0 )) && echo "FATAL: TRANSFER FAILED: ${HSI_DIR}/${f}"
    else
        touch ${NPB_FIXDIR}/${f}
    fi
done

