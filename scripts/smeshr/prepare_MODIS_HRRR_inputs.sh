#!/usr/bin/env bash

# Script Name: prepare_MODIS_HRRR_inputs.sh
# Author: J. Michelle Hu | University of Utah
# Date: 8.8.24
# Description: Generates directory structure and runs smeshr scripts accordingly
# Requires smeshr conda env
# Usage: ./prepare_MODIS_HRRR_inputs.sh <BASIN_NAME> <WY> <TOPO>
# Example: prepare_MODIS_HRRR_inputs.sh animas 2022 /full/path/to/topo.nc
# echo "time prepare_MODIS_HRRR_inputs.sh $BASIN $WY $TOPO 2>&1 | tee prep_${BASIN}_wy${WY}_$(date +%Y%m%d_%H%M).log"

if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" == "smeshr" ]]; then
  echo "Conda environment 'smeshr' is active."
else
  echo "Conda environment 'smeshr' is not active, exiting script"
  exit 1
fi

echo ; echo "Running $0 $1 $2" ; echo "    $3" ; echo "    from $(pwd)"

# Script running flags
verbose=true
realrun=true
process_cloudcover=true
process_radiation=true
process_albedo=true
process_netsolar=true

if [ "$ENTRY_POINT" = 1 ] ; then
    process_cloudcover=false
elif [ "$ENTRY_POINT" = 2 ] ; then
    process_cloudcover=false
    process_radiation=false
elif [ "$ENTRY_POINT" = 3 ] ; then
    process_cloudcover=false
    process_radiation=false
    process_albedo=false
fi

echo ; echo verbose is $verbose, realrun is $realrun ; echo
echo $process_cloudcover $process_radiation $process_albedo $process_netsolar

#==========================================================
#========  Establish variables and directory names ========
#==========================================================
# Basin-specific variables
BASIN=$1
WY=$2
YEAR=$(echo "${WY} - 1" | bc)
# TOPO=/uufs/chpc.utah.edu/common/home/skiles-group3/jmhu/isnobal_scripts/blue_setup/output_100m/topo.nc
# TOPO=/uufs/chpc.utah.edu/common/home/skiles-group3/jmhu/isnobal_scripts/animas_setup/output_100m/topo.nc
# TOPO=/uufs/chpc.utah.edu/common/home/skiles-group3/jmhu/isnobal_scripts/yampa_setup/output_100m/topo.nc
# TOPO=/uufs/chpc.utah.edu/common/home/skiles-group3/jmhu/isnobal_scripts/erw_setup/output_100m/topo.nc
TOPO=$3
RES=100 #default value

# Global directories
HRRR_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/HRRR_CBR/
SMESHR_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/SMESHR/

# Basin-specific output directories
BASIN_SMESHR_DIR=${SMESHR_DIR}${BASIN}
TCDC=${BASIN_SMESHR_DIR}/TCDC/
TCDC_out=${BASIN_SMESHR_DIR}/TCDC_out/
DSWRF_DIR=${BASIN_SMESHR_DIR}/DSWRF/
ALBEDO_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/MODIS_albedo/
NET_SOLAR_DIR=${BASIN_SMESHR_DIR}/net_HRRR_MODIS
MODEL_DIR=/uufs/chpc.utah.edu/common/home/skiles-group3/model_runs/

# isnoda scripts and repo directory
ISNODA_DIR=/uufs/chpc.utah.edu/common/home/u6058223/git_dirs/isnoda/
tcdc_script=${ISNODA_DIR}scripts/smeshr/tcdc_for_topo.sh
dswrf_script=${ISNODA_DIR}scripts/smeshr/dswrf_for_topo.sh
generic_albedo_script=${ISNODA_DIR}scripts/smeshr/MODIS-STC/MODIS_albedo_basin.sh
net_solar_script=${ISNODA_DIR}scripts/smeshr/MODIS-STC/net_dswrf_for_topo_MODIS.sh
linker_script=${ISNODA_DIR}scripts/smeshr/HRRR_linker.sh

cd ${HRRR_DIR} || exit 1

# Make the basin directory
if $realrun ; then
    if [ ! -d ${BASIN_SMESHR_DIR} ] ; then
        mkdir -pv ${BASIN_SMESHR_DIR}
    fi
fi

# Copy generic albedo script to basin-specific script to run and keep in SMESHR dir
albedo_script=${BASIN_SMESHR_DIR}/MODIS_albedo_basin_${BASIN}.sh
cp -pv $generic_albedo_script $albedo_script

#==========================================
#======== Process HRRR cloud cover ========
#==========================================
# Prepare directory structure for outputs
if $process_cloudcover ; then
    if $realrun ; then
        if [ ! -d ${TCDC} ] ; then
            mkdir -pv ${TCDC}
            mkdir -pv ${TCDC_out}
        fi
    fi
    if $verbose ; then
        echo "mkdir -pv ${TCDC}"
        echo "mkdir -pv ${TCDC_out}"
        echo
    fi

    # Extract TCDC from HRRR files
    # Run September preceding your WY
    if $verbose ; then
        echo "${tcdc_script}"
        echo "    ${TOPO}"
        echo "    hrrr.${YEAR}09*"
        echo "    hrrr.t*f06.grib2"
        echo "    ${TCDC}"
        echo "    ${WY}"
        echo "    11"
        echo "    ${TCDC_out}"
    fi
    if $realrun ; then
        ${tcdc_script} ${TOPO} "hrrr.${YEAR}09*" "hrrr.t*f06.grib2" ${TCDC} ${WY} "-1" ${TCDC_out}
    fi

    # Run October through December for your WY
    if $verbose ; then
        echo "${tcdc_script}"
        echo "    ${TOPO}"
        echo "    hrrr.${YEAR}1*"
        echo "    hrrr.t*f06.grib2"
        echo "    ${TCDC}"
        echo "    ${WY}"
        echo "    0 1 2"
        echo "    ${TCDC_out}"
    fi
    if $realrun ; then
        ${tcdc_script} ${TOPO} "hrrr.${YEAR}1*" "hrrr.t*f06.grib2" ${TCDC} ${WY} "0 1 2" ${TCDC_out}
    fi
    # Run January through September for your WY
    if $verbose ; then
        echo "${tcdc_script}"
        echo "    ${TOPO}"
        echo "    hrrr.${WY}*"
        echo "    hrrr.t*f06.grib2"
        echo "    ${TCDC}"
        echo "    ${WY}"
        echo "    3 4 5 6 7 8 9 10 11"
        echo "    ${TCDC_out}"
    fi
    if $realrun ; then
        ${tcdc_script} ${TOPO} "hrrr.${WY}0*" "hrrr.t*f06.grib2" ${TCDC} ${WY} "3 4 5 6 7 8 9 10 11" ${TCDC_out}
    fi

    echo ; echo " ============== Finished processing HRRR cloud cover ============== " ; echo
else
    echo ; echo " ============== Skipping HRRR cloud cover processing ============== " ; echo
fi

#==========================================
#========== Process SW radiation ==========
#==========================================
if $process_radiation ; then
    # Create directory for SW outputs
    if $verbose ; then
        echo "mkdir -pv ${SMESHR_DIR}${BASIN}/DSWRF/" ; echo
    fi
    if $realrun ; then
        if [ ! -d ${SMESHR_DIR}${BASIN}/DSWRF/ ] ; then
            mkdir -pv ${SMESHR_DIR}${BASIN}/DSWRF/
        fi
    fi

    # Extract SW from HRRR outputs
    # Run for the WY, looping month by month beginning with the last day of the preceding September
    dt=${YEAR}09
    end_dt=${WY}09

    while [ "$dt" -le "$end_dt" ]
    do
        if $verbose ; then
            echo -ne "Processing $dt\r"
            sleep 0.01
        fi
        echo ${dt}
        if $realrun ; then
            # check for preceding september and process last day only
            if [ ${dt} == ${YEAR}09 ] ; then
                echo "${dswrf_script} ${TOPO} "hrrr.${dt}30" "hrrr.t*f06.grib2" ${DSWRF_DIR}"
                ${dswrf_script} ${TOPO} "hrrr.${dt}30" "hrrr.t*f06.grib2" ${DSWRF_DIR}
            else
                ${dswrf_script} ${TOPO} "hrrr.${dt}*" "hrrr.t*f06.grib2" ${DSWRF_DIR}
            fi
        fi
        dt=$(date -d "${dt}01 +1 month" +%Y%m)
    done

    echo ; echo ; echo " ============== Finished processing HRRR SW radiation ============== " ; echo
else
    echo ; echo ; echo " ============== Skipping HRRR SW radiation processing ============== " ; echo
fi

#==========================================
#========== Process MODIS albedo ==========
#==========================================
if $process_albedo ; then
    # Edit MODIS_albedo_basin.sh
    function update_verbose()
    {
        echo "          Formerly: $1"
        echo "          Now: $2"
        sed -i "s|${1}|${2}|g" $3
        echo
    }

    # Extract extents of basin from topo.nc
    # Get x bounds
    minx=$(cdo sinfon ${TOPO} | grep x | tail -n 1 | cut -d ':' -f2 | cut -d ' ' -f2)
    maxx=$(cdo sinfon ${TOPO} | grep x | tail -n 1 | cut -d ':' -f2 | cut -d ' ' -f4)

    # Get y bounds. Note that this order is reversed in cdo sinfon output
    miny=$(cdo sinfon ${TOPO} | grep y | tail -n 1 | cut -d ':' -f2 | cut -d ' ' -f4)
    maxy=$(cdo sinfon ${TOPO} | grep y | tail -n 1 | cut -d ':' -f2 | cut -d ' ' -f2)

    # Adjust extents based on half the resolution size (RES) and basic calculator (bc)
    # Decrease minx and miny
    minx=$(echo "${minx} - ${RES}/2" | bc)
    miny=$(echo "${miny} - ${RES}/2" | bc)
    # Increase maxx and maxy
    maxx=$(echo "${maxx} + ${RES}/2" | bc)
    maxy=$(echo "${maxy} + ${RES}/2" | bc)

    # Put together new extents
    extents="${minx} ${miny} ${maxx} ${maxy}"

    # Update variables in MODIS_albedo_basin.sh
    # Update BASIN
    current=$(grep BASIN= ${albedo_script})
    # shellcheck disable=SC2089
    new="export BASIN='${BASIN}'"
    if $realrun ; then update_verbose "$current" "$new" $albedo_script ; fi

    # Update BASIN_EXTENT
    current=$(grep BASIN_EXTENT= ${albedo_script})
    # shellcheck disable=SC2089
    new="BASIN_EXTENT='${extents}'"
    if $realrun ; then update_verbose "$current" "$new" $albedo_script ; fi

    # Run the albedo processing script
    if $verbose ; then echo ${albedo_script} ${ALBEDO_DIR} ${WY} ; fi
    if $realrun ; then ${albedo_script} ${ALBEDO_DIR} ${WY} ; fi

    echo ; echo " ============== Finished processing MODIS albedo ============== " ; echo
else
    echo ; echo " ============== Skipping MODIS albedo processing ============== " ; echo
fi
#==========================================
#========== Prepare net_solar.nc ==========
#==========================================
# Prepare net_solar.nc from MODIS albedo and HRRR SW
if $process_netsolar ; then
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
        echo "    ${ALBEDO_DIR}wy${WY} "
        echo "    ${NET_SOLAR_DIR}"
    fi

    if $realrun ; then
        ${net_solar_script} ${WY} "0 1 2 3 4 5 6 7 8 9 10 11" ${DSWRF_DIR} ${ALBEDO_DIR}wy${WY} ${NET_SOLAR_DIR}
    fi

    echo ; echo " ============== Finished processing net_solar.nc ============== " ; echo
else
    echo ; echo " ============== Skipping net_solar.nc processing ============== " ; echo
fi

#===========================================
#======= Link outputs to iSnobal dir =======
#===========================================
# Generate the directory structure
OUTDIR=${MODEL_DIR}${BASIN}_100m_isnobal/wy${WY}/${BASIN}_basin_100m_solar_albedo/
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
