#!/bin/bash

##########################################################################
# Copyright 2017, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of CCseqBasic5 .                                     #
#                                                                        #
# CCseqBasic5 is free software: you can redistribute it and/or modify    #
# it under the terms of the MIT license.
#
#
#                                                                        #
# CCseqBasic5 is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# MIT license for more details.
#                                                                        #
# You should have received a copy of the MIT license
# along with CCseqBasic5.  
##########################################################################

# These colors are originally combined together to CaptureC overlays by Helena Francis,
# and first presented in this tracks file :
# /public/hfrancis/capture_data/170511_5MbCapture_WT_Inven_Spleen/5Mb_stats_cis/overlay_hub/mm9/tracks.txt

# -------------------------------------------
# Setting $HOME to the current dir
echo 'Turning on safety measures for cd rm and mv commands in $0 - restricting script to file operations "from this dir below" only :'
HOME=$(pwd)
echo $HOME
echo
# - to enable us to track mv rm and cd commands
# from taking over the world accidentally
# this is done in testers_and_loggers.sh subroutines, which are to be used
# every time something gets parsed, and after that when the parsed value is used to mv cd or rm anything
# ------------------------------------------



doOneParent(){

echo track ${parentname} >> preliminary_dataHubData.txt
echo shortLabel ${parentname} >> preliminary_dataHubData.txt
echo longLabel ${parentname} >> preliminary_dataHubData.txt
echo type bigWig >> preliminary_dataHubData.txt
echo container multiWig >> preliminary_dataHubData.txt
echo aggregate transparentOverlay >> preliminary_dataHubData.txt
echo showSubtrackColorOnUi on >> preliminary_dataHubData.txt
echo visibility full >> preliminary_dataHubData.txt
echo windowingFunction maximum >> preliminary_dataHubData.txt
echo autoScale on >> preliminary_dataHubData.txt
echo alwaysZero on >> preliminary_dataHubData.txt
echo priority 120  >> preliminary_dataHubData.txt
echo   >> preliminary_dataHubData.txt


}



# Folder name as the parent name
parentname=$(basename $(pwd))
doOneParent

# Go through all bigwigs in the run folder
counter=1
for file in $( ls -1 *.bw )
do
  doOneChild
  counter=${counter}+1
done


