#!/bin/bash

# The color setting subroutines and track making subroutines

# echo $0

thisScriptName=$(echo $0 | sed 's/\s.*//')
. $(dirname ${thisScriptName})/bashHelpers/rainbowHubHelpers.sh

# -----------------------

# Folders RAW and PREfiltered would be done like this
# folder=$1
# subfolder=$2

# COMBINED has only one run - so can skip folder (didn't make subs to differentiate as COMBINED is only one we want)
# and we don't have subfolder any more.

folder=$1
bwsuffix=$2
abbrev=$3
visibility=$4

echo -n "- ${abbrev} "
echo -n "- ${abbrev} " >> "/dev/stderr"

parentname="${abbrev}"

rm -f ${parentname}_tracks.txt
doOneParent

for fastqBwfile in ${folder}/fastq_*${bwsuffix}.bw
do
  doOneRawsamChild
done


