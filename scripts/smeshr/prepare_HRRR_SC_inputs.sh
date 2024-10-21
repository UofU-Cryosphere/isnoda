#!/usr/bin/env bash

# Script Name: prepare_HRRR_SC_inputs.sh
# Author: J. Michelle Hu | University of Utah
# Date: 9.24
# Description: Generates directory structure and runs smeshr scripts accordingly
# Requires smeshr conda env
# Usage: ./prepare_HRRR_SC_inputs.sh <BASIN_NAME> <WY>
# Example: prepare_HRRR_SC_inputs.sh animas 2022

set -e
echo ; echo "Running $0 $1 $2" ; echo "    from $(pwd)"

# Script running flags
verbose=true
realrun=true
prep_netsolar=true
link_outputs=true

echo ; echo verbose is $verbose, realrun is $realrun
echo prep_netsolar is $prep_netsolar, link_outputs is $link_outputs ; echo

#==========================================================  
#========  Establish variables and directory names ========
#==========================================================  
# Basin-specific variables
BASIN=$1
WY=$2
YEAR=$(echo "${WY} - 1" | bc)

# Model output directory - modify at will
MODEL_DIR=/uufs/chpc.utah.edu/common/home/skiles-group1/jmhu/model_animas_only/

# # Global directories
SMESHR_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/SMESHR/

# Basin-specific output directories
TCDC_out=${SMESHR_DIR}${BASIN}_hrrrsc/TCDC_out/ 
DSWRF_DIR=${SMESHR_DIR}${BASIN}_hrrrsc/DSWRF/
SMRF_DIR=${MODEL_DIR}/${BASIN}_100m_isnobal/wy${WY}/${BASIN}_basin/
NET_SOLAR_DIR=${SMESHR_DIR}${BASIN}_hrrrsc/net_HRRR_SMRF/
OUTDIR=${MODEL_DIR}${BASIN}_100m_isnobal_hrrrsc/wy${WY}/${BASIN}_basin_100m/

# isnoda scripts and repo directory, edit ISNODA_DIR to your install
ISNODA_DIR=/uufs/chpc.utah.edu/common/home/u6058223/git_dirs/isnoda/
net_solar_script=${ISNODA_DIR}scripts/smeshr/SMRF/net_dswrf_for_topo_SMRF.sh
linker_script=${ISNODA_DIR}scripts/smeshr/HRRR_linker.sh

#==========================================
#========== Prepare net_solar.nc ==========
#==========================================
# Prepare net_solar.nc from time decay SMRF albedo and HRRR SW
if $prep_netsolar ; then

    # Create directory for net solar output files
    if $verbose ; then echo mkdir -v ${NET_SOLAR_DIR} ; echo ; fi
    if $realrun ; then 
        if [ ! -d ${NET_SOLAR_DIR} ] ; then
            mkdir -v ${NET_SOLAR_DIR}
        fi
    fi

    if $verbose ; then 
        echo "${net_solar_script} "
        echo "    ${WY} "
        echo '    "0 1 2 3 4 5 6 7 8 9 10 11" '
        echo "    ${DSWRF_DIR} "
        echo "    ${SMRF_DIR} "
        echo "    ${NET_SOLAR_DIR}"
    fi

    if $realrun ; then 
        ${net_solar_script} ${WY} "0 1 2 3 4 5 6 7 8 9 10 11" ${DSWRF_DIR} ${SMRF_DIR} ${NET_SOLAR_DIR}
    fi

    echo ; echo " ============== Finished prepping net_solar.nc ============== " ; echo
else
    echo ; echo " ============== Skipping prep for net_solar.nc... ============== " ; echo

#===========================================
#======= Link outputs to iSnobal dir =======
#===========================================
if $link_outputs ; then
    # Generate the directory structure 
    if $verbose ; then echo mkdir -pv ${OUTDIR} ; echo ; fi
    if $realrun ; then 
        if [ ! -d ${OUTDIR} ] ; then
            mkdir -pv ${OUTDIR}
        fi
    fi

    # Loop through the WY and generate run* directories
    # print statements every 30 days
    for d in $(seq 0 364)
    do 
        # Add a spinner
        echo -ne "Processing day $d\r"
        sleep 0.001
        if $verbose ; then
            if ((d % 30 == 0)); then
                echo "    mkdir run$(date -d "${YEAR}-10-01 +$d days" +%Y%m%d)"
            fi
        fi
        if $realrun ; then 
            mkdir ${OUTDIR}run$(date -d "${YEAR}-10-01 +$d days" +%Y%m%d) ; 
        fi
    done
    echo ; echo

    # Link net_solar outputs to these run* dirs using HRRR_linker.sh
    # test verbose flag only if realrun=false to avoid excess output
    if $realrun ; then 
        ${linker_script} "${OUTDIR}run*" "${NET_SOLAR_DIR}" "net_solar.nc"
    else
        if $verbose ; then 
            echo ${linker_script}
            echo "    ${OUTDIR}run*"
            echo "    ${NET_SOLAR_DIR}"
            echo "    net_solar.nc"
        fi
    fi

    # Link the cloud cover outputs as well
    if $verbose ; then 
        echo ${linker_script}
        echo "    ${OUTDIR}run*"
        echo "    ${TCDC_out}"
        echo "    cloud_factor.nc" 
    fi
    if $realrun ; then ${linker_script} "${OUTDIR}run*" "${TCDC_out}" "cloud_factor.nc" ; fi
else
    echo ; echo " ============== Skipping output linking... ============== " ; echo