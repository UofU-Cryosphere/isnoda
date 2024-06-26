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

HOST="https://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customMultiTimeSeriesGroupByStationReport,metric/daily/end_of_period/"
COLUMNS="/POR_BEGIN,POR_END/SNWD::value,WTEQ::value,SNDN::value,WSPDV::value,TOBS::value,PRCP::value"
STATE="CO"

echo "Downloading SNOTEL period of record data for site ${1}"
curl "${HOST}${1}:${STATE}:SNTL%7Cid=%22%22%7Cname/${COLUMNS}" > $(date +%Y%m%d)_PoR_site${1}.csv


