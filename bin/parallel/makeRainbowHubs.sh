#!/bin/bash

# The color setting subroutines and track making subroutines

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
ucscBuildName=$3

parentname="${folder}_${subfolder}"
echo ${parentname}

doGenomeAndHub

rm -f ${parentname}_tracks.txt
doOneParent

oligolist=(); olistrlist=(); olistplist=(); excstrlist=(); excstplist=()
oligoListSetter

counter=1
# track_symlinks/${chr}/${folder}/${subfolder}_REdig_CM5_*.bw
for (( i=0; i<${#oligolist[@]}; i++ ))
do

# echo track_symlinks/chr${folder}/${folder}/${subfolder}_CM5_${oligolist[i]}_1.bw
if [ -s "track_symlinks/chr${folder}/${folder}_${subfolder}_CM5_${oligolist[i]}_1.bw" ]; then
  doOneChild
fi

done


