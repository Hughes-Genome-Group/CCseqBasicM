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
bwsuffix=$4
abbrev=$5
visibility=$6
ccversion=$7
noparent=$8

# Setting suffix (or any of these flags) to 'none' turns it off, i.e. sets it to ""

if [     "${folder}" == "none" ]; then     folder="";fi
if [  "${subfolder}" == "none" ]; then  subfolder="";fi
if [   "${bwprefix}" == "none" ]; then   bwprefix="";fi
if [   "${bwsuffix}" == "none" ]; then   bwsuffix="";fi
if [     "${abbrev}" == "none" ]; then     abbrev="";fi
if [ "${visibility}" == "none" ]; then visibility="";fi
if [  "${ccversion}" == "none" ]; then  ccversion="";fi

# ----------------------------

echo -n "- ${subfolder} "
echo -n "- ${subfolder} " >> "/dev/stderr"

parentname="${folder}_${subfolder}${bwsuffix}"

rm -f ${parentname}_tracks.txt

# If we didn't disable, making a parent track ..
if [ "${noparent}" != "noparent" ]; then
  doOneParent
else
  echo -n '(skipping parent track), '  
fi

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
if [ -s "${folder}/${subfolder}/${bwprefix}_CM5_${oligolist[i]}${bwsuffix}.bw" ]; then
  doOneChild
else
  echo -n "( skipping ${oligolist[i]} ) "
  echo -n "( skipping ${oligolist[i]} ) " >> "/dev/null"
  
  # For testing purposes ..
  # echo
  # echo ${folder}/${subfolder}/${bwprefix}_CM5_${oligolist[i]}${bwsuffix}.bw
  
fi

done


