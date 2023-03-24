#!/bins/bash

TYPE=$1
NPB_FIXDIR=$2
HSI_DIR=/NCEPDEV/emc-marine/1year/Neil.Barton/FIX
files=""
mkdir -p ${NPB_FIXDIR} 
if [[ ${TYPE} == 'mx025gefs' ]]; then
    files="mod_def.mx025gefs.ww3"
elif [[ ${WAV_RES} == 'a' ]]; then
    files="mod_def.a.ww3 mesh.a.nc"
elif [[ ${WAV_RES} == 'b' ]]; then
    files="mod_def.b.ww mesh.b.nc"
elif [[ ${WAV_RES} == 'tripolar' ]]; then
    files="mod_def.tripolar.ww3"
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

