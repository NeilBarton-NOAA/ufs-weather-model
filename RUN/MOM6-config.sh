#!/bin/sh
echo 'MOM6-config.sh'
MOM_INPUT=${MOM_INPUT:-MOM_input_template_${OCNRES}}

####################################
# options based on other active components
[[ ${WAV_tasks} == 0 ]] && MOM6_USE_WAVES=false

####################################
# look for restarts if provided
if [[ ${IC_DIR} != 'none' ]]; then
    mkdir -p INPUT
    ln -sf ${IC_DIR}/ocn/* INPUT/
fi

####################################
# parse namelist file
mkdir -p INPUT
atparse < ${PATHRT}/parm/${MOM_INPUT} > INPUT/MOM_input

