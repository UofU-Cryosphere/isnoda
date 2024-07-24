#!/usr/bin/env bash
#
# Download Snotel csv data from USDA for a site with end of day values in
# metric units for the full period of record. Modified from get_snotel_csv.sh
# Default state is Colorado, update as needed.
# Data includes: Depth, SWE, Density, Wind Speed, Air Temperature, Precipitation
#
# More information is in the header of the generated csv file.
#
# Arguments:
#  1: Snotel Site ID
#
# Outputs: CSV file
#   Name: [downloaddate]_PoR_site[SiteID].csv
#
# Example:
#  get_snotelPoR_csv.sh 112

set -e

if [ "$#" -ne 1 ]; then
    echo 'Provide site number as the sole argument'
    exit 1
fi


Help()
{
   # Display Help
   echo "Download SNOTEL period of record data for input site"
   echo
   echo "Syntax: get_snotelPoR_csv.sh siteID [-h]"
   echo "options:"
   echo "h     Print this Help."
   echo
}

# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done

HOST="https://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customMultiTimeSeriesGroupByStationReport,metric/daily/end_of_period/"
COLUMNS="/POR_BEGIN,POR_END/SNWD::value,WTEQ::value,SNDN::value,WSPDV::value,TOBS::value,PRCP::value"
STATE="${VARIABLE:-CO}"

echo "Downloading SNOTEL period of record data for site ${1}"
curl "${HOST}${1}:${STATE}:SNTL%7Cid=%22%22%7Cname/${COLUMNS}" > $(date +%Y%m%d)_PoR_site${1}.csv

