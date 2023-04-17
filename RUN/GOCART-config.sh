#!/bin/sh
echo 'GOCART-config.sh'
GOCART_OPS=${GOCART_OPS:-F}

####################################
# parse namelist
atparse < ${PATHRT}/parm/gocart/AERO_HISTORY.rc.IN > AERO_HISTORY.rc

####################################
# fix filesi
# input files
ln -sf ${AERO_INPUTS_DIR} ExtData
# namelist files
files=$(ls ${PATHRT}/parm/gocart/*.rc) 
for f in ${files}; do
    if [[ ${FIX_METHOD} == 'LINK' ]]; then
        ln -s ${f} .
    else
        cp ${f} .
    fi
done

rm AERO_ExtData.rc
ln -s ${PATH_RUN}/AERO_ExtData.rc .
#sed -i "s:dust:Dust:g" AERO_ExtData.rc

if [[ ${GOCART_OPS} == T ]]; then
files="AERO_HISTORY.rc CAP.rc DU2G_instance_DU.rc GOCART2G_GridComp.rc field_table"
${PATH_RUN}/FIX-from-hpss.sh GOCART_OPS ${NPB_FIX} 
for f in ${files}; do
    rm ${f}
    cp ${NPB_FIX}/${f} .
done
fi
