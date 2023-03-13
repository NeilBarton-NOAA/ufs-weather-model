#!/bin/bash
########################
if [[ ${FIX_METHOD} == 'LINK' ]]; then
    for f in "${!LF[@]}"; do
        sl_f=${LF[$f]}
        if [ ! -f "${f}" ]; then
            echo "FATAL: cannot find file to link:" ${f}
            echo "  FIX_DIR: ${FIX_DIR}"
            echo "  INPUTDATA_ROOT: ${INPUTDATA_ROOT}"
            exit 1
        fi
        ln -sf ${f} ${sl_f}
    done
fi

