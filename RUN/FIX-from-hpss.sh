#!/bin/bash

TYPE=$1
NPB_FIXDIR=$2
HSI_DIR=/NCEPDEV/emc-marine/1year/Neil.Barton/FIX
files=""
mkdir -p ${NPB_FIXDIR} 
if [[ ${TYPE} == 'mx025gefs' ]]; then
    files="mod_def.mx025gefs.ww3"
elif [[ ${TYPE} == 'gefsv13_025' ]]; then
    files="mod_def.ww3.gefsv13_025 mesh.gefsv13_025.nc"
elif [[ ${TYPE} == 'glo_025' ]]; then
    files="mod_def.glo_025 mesh.glo_025.nc"
elif [[ ${TYPE} == 'glo_025_1800' ]]; then
    files="mod_def.glo_025_1800 mesh.glo_025.nc"
elif [[ ${TYPE} == 'a' ]]; then
    files="mod_def.a.ww3 mesh.a.nc"
elif [[ ${TYPE} == 'b' ]]; then
    files="mod_def.b.ww mesh.b.nc"
elif [[ ${TYPE} == 'tripolar' ]]; then
    files="mod_def.tripolar.ww3"
elif [[ ${TYPE} == "GOCART_OPS" ]]; then
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

