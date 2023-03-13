#!/bin/sh
echo 'GOCART-config.sh'
ln -sf ${INPUTDATA_ROOT}/GOCART/p8c_5d/ExtData .

cp ${PATHRT}/parm/gocart/*.rc .
atparse < ${PATHRT}/parm/gocart/AERO_HISTORY.rc.IN > AERO_HISTORY.rc

