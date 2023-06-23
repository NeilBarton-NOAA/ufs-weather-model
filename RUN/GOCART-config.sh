#!/bin/sh
echo 'GOCART-config.sh'
GOCART_NO3=${GOCART_NO3:-T}

####################################
# parse namelist
atparse < ${PATHRT}/parm/gocart/AERO_HISTORY.rc.IN > AERO_HISTORY.rc

####################################
# namelist files
files=$(ls ${PATHRT}/parm/gocart/*.rc) 
for f in ${files}; do
    cp ${f} .
done

####################################
# input files
ln -sf ${AERO_INPUTS_DIR} ExtData
# Edit AERO_ExtData.rc to use GW data
sed -i "s:dust:Dust:g" AERO_ExtData.rc
sed -i "s:QFED:nexus/QFED:g" AERO_ExtData.rc
sed -i "s:ExtData/CEDS:ExtData/nexus/CEDS:g" AERO_ExtData.rc
sed -i "s:ExtData/MEGAN_OFFLINE_BVOC:ExtData/nexus/MEGAN_OFFLINE_BVOC:g" AERO_ExtData.rc

if [[ ${GOCART_NO3} == F ]]; then
    sed -i "s/COLLECTIONS: 'inst_aod'/COLLECTIONS:/g" AERO_HISTORY.rc
    sed -i "/'NIEXTTAU'      , 'NI'       , 'AOD_NI',/d" AERO_HISTORY.rc
    sed -i "/NH3,NI                  nh3/d" CAP.rc
    sed -i "/NH4a,NI                 nh4a/d" CAP.rc
    sed -i "/NO3an1,NI               no3an1/d" CAP.rc
    sed -i "/NO3an2,NI               no3an2/d" CAP.rc
    sed -i "/NO3an3,NI               no3an3/d" CAP.rc
    sed -i "s/alpha: 0.039/alpha: 0.04/g" DU2G_instance_DU.rc
    sed -i "s/gamma: 0.8/gamma: 1.0/g" DU2G_instance_DU.rc
    sed -i "s/ACTIVE_INSTANCES_NI:  NI  # NI.data/ACTIVE_INSTANCES_NI:/g" GOCART2G_GridComp.rc
    cp ${PATHRT}/parm/field_table/field_table_thompson_noaero_tke_GOCART_NONITRATES field_table 
fi
