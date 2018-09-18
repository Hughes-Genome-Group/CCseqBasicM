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
subfolder=$2
bwprefix=$3
abbrev=$4
visibility=$5

echo -n "- ${subfolder} "
echo -n "- ${subfolder} " >> "/dev/stderr"

parentname="${folder}_${subfolder}"

rm -f ${parentname}_tracks.txt
doOneParent

color=(); oligolist=(); olistrlist=(); olistplist=(); excstrlist=(); excstplist=()

oligoListSetter
echo -n "${#oligolist[@]} oligos found, "
setRainbowColors
echo -n "using ${#color[@]} colors "

counter=1
# track_symlinks/${chr}/${folder}/${subfolder}_REdig_CM5_*.bw
for (( i=0; i<${#oligolist[@]}; i++ ))
do

# to get error if no file found :
# ls ${folder}/${subfolder}/${bwprefix}_CM5_${oligolist[i]}.bw >> "/dev/null"

# echo track_symlinks/chr${folder}/${folder}/${subfolder}_CM5_${oligolist[i]}_1.bw
if [ -s "${folder}/${subfolder}/${bwprefix}_CM5_${oligolist[i]}.bw" ]; then
  doOneChild
else
  echo -n "( skipping ${oligolist[i]} as no data found ) "
  echo -n "( skipping ${oligolist[i]} as no data found ) " >> "/dev/null"
fi

done


