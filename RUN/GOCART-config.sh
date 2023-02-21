#!/bin/sh
echo 'GOCART-config.sh'

cp ${PATHRT}/parm/gocart/*.rc .
atparse < ${PATHRT}/parm/gocart/AERO_HISTORY.rc.IN > AERO_HISTORY.rc

