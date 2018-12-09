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
parent=$8

# Setting suffix (or any of these flags) to 'none' turns it off, i.e. sets it to ""

if [     "${folder}" == "none" ]; then     folder="";fi
if [  "${subfolder}" == "none" ]; then  subfolder="";fi
if [   "${bwprefix}" == "none" ]; then   bwprefix="";fi
if [   "${bwsuffix}" == "none" ]; then   bwsuffix="";fi
if [     "${abbrev}" == "none" ]; then     abbrev="";fi
if [ "${visibility}" == "none" ]; then visibility="";fi
if [  "${ccversion}" == "none" ]; then  ccversion="";fi

# ----------------------------
# for testing purposes :
# echo '$0' '$1' '$2' '$3' '$4' '$5' '$6' '$7' '$8'
# echo "'$0' '$1' '$2' '$3' '$4' '$5' '$6' '$7' '$8'"
# ----------------------------

echo -n "- ${subfolder} "
echo -n "- ${subfolder} " >> "/dev/stderr"

trackfilename="${folder}_${subfolder}${bwsuffix}"

# If we want to have chr name in the parent
if [ "${parent}" == "wholegenparent" ] || [ "${parent}" == "noparent" ]; then
  parentname="${subfolder}${bwsuffix}"
else
  parentname="${folder}_${subfolder}${bwsuffix}"
fi


rm -f ${parentname}_tracks.txt

# If we didn't disable, making a parent track ..
if [ "${parent}" != "noparent" ]; then
  doOneParent
else
  echo -n '(skipping parent track), '  
fi

color=(); capturesitelist=(); olistrlist=(); olistplist=(); excstrlist=(); excstplist=()

capturesiteListSetter
echo -n "${#capturesitelist[@]} capturesites found, "
setRainbowColors
echo -n "using ${#color[@]} colors "

counter=1
# track_symlinks/${chr}/${folder}/${subfolder}_REdig_CM5_*.bw
for (( i=0; i<${#capturesitelist[@]}; i++ ))
do

# to get error if no file found :
# ls ${folder}/${subfolder}/${bwprefix}_CM5_${capturesitelist[i]}.bw >> "/dev/null"

# echo track_symlinks/chr${folder}/${folder}/${subfolder}_CM5_${capturesitelist[i]}_1.bw
if [ -s "${folder}/${subfolder}/${bwprefix}_CM5_${capturesitelist[i]}${bwsuffix}.bw" ]; then
  doOneChild
else
  echo -n "( skipping ${capturesitelist[i]} ) "
  echo -n "( skipping ${capturesitelist[i]} ) " >> "/dev/null"
  
  # For testing purposes ..
   echo
   echo ${folder}/${subfolder}/${bwprefix}_CM5_${capturesitelist[i]}${bwsuffix}.bw
  
fi

done


