#!/bin/sh
set -u
#This routine will make the mod_defs that are needed as input in 
#ufs-apps using WW3
#   UFSMODELDIR is the location of your clone of ufs-weather-model  
#   OUTDIR is the location where the mod_def.* outputs will end up from this script
#   SRCDIR is the location of the ww3_grid.inp files 
#   WORKDIR is the working directory for log files, e

INP_FILE=${1}
UFSMODELDIR=${2}
m=${3}
grid=${INP_FILE##*.inp.}

###################################
#  Set up                         #
###################################
if [ ${m} = hera ]; then export target=hera.intel ; fi
if [ ${m} = wcoss2 ]; then export target=wcoss2.intel ; fi
if [ ${m} = orion ]; then export target=orion.intel ; fi
if [ ${m} = stampede ]; then export target=stampede.intel ; fi
if [ ${m} = gaea ]; then export target=gaea.intel ; fi
if [ ${m} = jet ]; then export target=jet.intel ; fi

module use ${UFSMODELDIR}/modulefiles
module load ufs_${target}

########################################
#  Build ww3_grid, if needed           #
########################################
export WW3_DIR=${UFSMODELDIR}/WW3
WW3_EXEDIR=${WW3_DIR}/model/bin
export SWITCHFILE="${WW3_DIR}/model/esmf/switch"
if [[ ! -f ${WW3_EXEDIR}/ww3_grid ]]; then
    echo 'BUILDING executable for inp2moddef'
    path_build=${PWD}/build_ww3
    mkdir -p ${path_build}
    cd ${path_build}
    echo $(cat ${SWITCHFILE}) > ${path_build}/tempswitch
    sed -e "s/DIST/SHRD/g"\
        -e "s/OMPG / /g"\
        -e "s/OMPH / /g"\
        -e "s/MPIT / /g"\
        -e "s/MPI / /g"\
        -e "s/B4B / /g"\
        -e "s/PDLIB / /g"\
        -e "s/NOGRB/NCEP2/g"\
        ${path_build}/tempswitch > ${path_build}/switch
    rm ${path_build}/tempswitch
    cat $path_build/switch
    cmake $WW3_DIR -DSWITCH=$path_build/switch -DCMAKE_INSTALL_PREFIX=install >& cmake.out
    rc=$?
    if [[ $rc -ne 0 ]] ; then
        echo "Fatal error in cmake."
        exit $rc
    fi
    make -j 8 >& make.out
    rc=$?
    if [[ $rc -ne 0 ]] ; then
        echo "Fatal error in make."
        exit $rc
    fi
    make install >& install.out
    if [[ $rc -ne 0 ]] ; then
        echo "Fatal error in make install."
        exit $rc
    fi
    cp ${path_build}/bin/ww3_grid ${WW3_EXEDIR}
fi

###################################
#  Make mod_def files mesh        #
###################################

if [[ -f ${INP_FILE} ]]; then
  workdir=${PWD}/workdir 
  mkdir -p ${workdir} && cd ${workdir}
  cp ${INP_FILE} ww3_grid.inp

  if [ -f ${workdir}/ww3_${grid}.out ]; then
    rm ${workdir}/ww3_${grid}.out
  fi
  echo "Executing ww3_grid, see grid output in ww3_${grid}.out"
  ${WW3_EXEDIR}/ww3_grid > ${workdir}/ww3_${grid}.out
  mkdir -p ${UFSMODELDIR}/RUN
  mv mod_def.ww3 ${UFSMODELDIR}/RUN/mod_def.${grid}
  rm -f ww3_grid.inp ST4TABUHF2.bin
else
  echo ' '
  echo " WW3 grid input file ww3_grid.inp.${grid} not found! "
  echo ' ****************** ABORTING *********************'
  echo ' '
  exit 1
fi

