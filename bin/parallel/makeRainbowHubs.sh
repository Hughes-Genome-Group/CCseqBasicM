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

# FLASHED_REdig_CM5_1190007I07Rik_L_R.bw

# Ddx3y_R Y       621870  623257  Y       620870  624257  1       A

# For the bigwig tracks 
oligolist=($(cut -f 1,2 oligofile_sorted.txt | grep '\s'${folder}'$' | cut -f 1))

# For matching the colors of the oligo and exclusion zone tracks too.
olistrlist=($(cut -f 2,3 oligofile_sorted.txt | grep '^'${folder}'\s' | cut -f 2 | awk '{print $1-1}'))
olistplist=($(cut -f 2,4 oligofile_sorted.txt | grep '^'${folder}'\s' | cut -f 2))
excstrlist=($(cut -f 2,6 oligofile_sorted.txt | grep '^'${folder}'\s' | cut -f 2 | awk '{print $1-1}'))
excstplist=($(cut -f 2,7 oligofile_sorted.txt | grep '^'${folder}'\s' | cut -f 2))

counter=1
# track_symlinks/${chr}/${folder}/${subfolder}_REdig_CM5_*.bw
for (( i=0; i<${#oligolist[@]}; i++ ))
do

# echo track_symlinks/chr${folder}/${folder}/${subfolder}_CM5_${oligolist[i]}_1.bw
if [ -s "track_symlinks/chr${folder}/${folder}_${subfolder}_CM5_${oligolist[i]}_1.bw" ]; then
  doOneChild
fi

done


