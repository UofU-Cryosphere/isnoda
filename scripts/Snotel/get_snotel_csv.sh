#!/usr/bin/env bash
#
# Download Snotel csv data from USDA for a site with end of day values in
# metric units. Includes: Depth, SWE, Density, Wind Speed, Air Temperature
# More information is in the header of the generated csv file.
#
# Arguments:
#  1: Snotel Site ID
#  2: Water Year
#
# Outputs: CSV file
#   Name: WaterYear-SiteID.csv
#
# Example:
# get_snotel_csv.sh 111 2020

HOST="https://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customMultiTimeSeriesGroupByStationReport,metric/daily/end_of_period/"
COLUMNS="/SNWD::value,WTEQ::value,SNDN::value,WSPDV::value,TOBS::value"

curl "${HOST}${1}:CO:SNTL%7Cid=%22%22%7Cname/$(($2 - 1))-10-01,${2}-09-30${COLUMNS}" > ${2}-{1}.csv
