#!/bin/sh
echo 'MOM6-config.sh'
OCN_tasks=${OCN_NMPI:-$OCN_tasks}
MOM_INPUT=${MOM_INPUT:-MOM_input_template_${OCNRES}}

# edits
[[ ${WAV_NMPI} == 0 ]] && MOM6_USE_WAVES=false
mkdir -p INPUT
atparse < ${PATHRT}/parm/${MOM_INPUT} > INPUT/MOM_input

