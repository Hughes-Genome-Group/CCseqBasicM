#!/bin/bash

##########################################################################
# Copyright 2017, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of CCseqBasic5 .                                     #
#                                                                        #
# CCseqBasic5 is free software: you can redistribute it and/or modify    #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# CCseqBasic5 is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with CCseqBasic5.  If not, see <http://www.gnu.org/licenses/>.   #
##########################################################################

# ------------------------------------------

echo "Parallel visualisation - by Jelena Telenius, 26/02/2018"
echo
timepoint=$( date )
echo "run started : ${timepoint}"
echo
echo "Script located at"
echo "$0"
echo

echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "parallelVisualisation.sh" $@
echo

parameterList=$@

# -----------------------------------------

PublicPath="$1"
Sample="$2"
CCversion="$3"
restrictionEnzyme="$4"

PublicPath="${PublicPath}/${Sample}/${CCversion}_${REenzyme}"

# To follow the naming in hubber.sh :
publicPathForCCanalyser="${PublicPath}"
sampleForCCanalyser="${Sample}"

# -----------------------------------------

RunScriptsPath="$( echo $0 | sed 's/\/parallelVisualisation.sh$//' )"
CaptureTopPath="$( dirname $( dirname $(echo ${RunScriptsPath}) ))"
CapturePipePath="${CaptureTopPath}/bashHelpers"
CaptureCommonHelpersPath="${CaptureTopPath}/commonSubroutines"
CapturePlotPath="${CaptureCommonHelpersPath}/drawFigure"

# From where to call the CONFIGURATION script..
confFolder=$( dirname ${CaptureTopPath} )"/conf"

#------------------------------------------

echo
echo "CaptureTopPath ${CaptureTopPath}"
echo "confFolder ${confFolder}"
echo "CapturePipePath ${CapturePipePath}"
echo "CaptureCommonHelpersPath ${CaptureCommonHelpersPath}"
echo "CapturePlotPath ${CapturePlotPath}"
echo

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# HUBBING subroutines
. ${CaptureCommonHelpersPath}/hubbers.sh

# DEBUG SUBROUTINES - for the situations all hell breaks loose
# . ${CapturePipePath}/debugHelpers.sh

# TESTING file existence, log file output general messages

. ${CaptureCommonHelpersPath}/testers_and_loggers.sh

#------------------------------------------
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

# Test the testers and loggers ..

printThis="Testing the tester subroutines .."
printToLogFile
printThis="${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err"
printToLogFile
   
${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err
# The above exits if any of the tests don't work properly.

# The below exits if the logger test sub wasn't found (path above wrong or file not found)
if [ "$?" -ne 0 ]; then
    printThis="Testing testers_and_loggers.sh safety routines failed. Cannot continue without testing safety features ! \n EXITING !! "
    printToLogFile
    exit 1
else
    printThis="Testing the tester subroutines completed - continuing ! "
    printToLogFile
fi

# Comment this out, if you want to save these files :
rm -f testers_and_loggers_test.out testers_and_loggers_test.err

#------------------------------------------

# . ${confFolder}/config.sh
. ${confFolder}/genomeBuildSetup.sh
. ${confFolder}/loadNeededTools.sh

echo "Calling in the conf/config.sh script and its default setup .."

supportedGenomes=()
UCSC=()

setPathsForPipe
setGenomeLocations

# ------------------------------------------

GENOME="UNDEFINDED"
GENOME=$( cat $( ls -1 ${PublicPath}/bunches/*genomes.txt | head -n 1 ) | grep '^genome\s' | sed 's/genome\s*//' )
echo "GENOME ${GENOME}"

ucscBuild="UNDEFINED"
setUCSCgenomeSizes

# -----------------------------------------

printThis="Generating final visualisation hubs."
printNewChapterToLogFile


printThis="Oligo and exclusion coordinate bigbeds .."
printToLogFile

# Single track oligo coordinates (assuming no overlapping oligos)
# Single track exclusion coordinates (assuming no overlapping oligos)

# -----------------------------

# The tracks are in here :

# ${PublicPath}/bunches/

# And the above description.html was put to
# ${PublicPath}
# Where the main hub should go too

# The hubbers.sh subs use this to point to the folder of interest :
# publicPathForCCanalyser

# ------------------------------
# Oligos

rm -f COMBO.bed
for file in ${PublicPath}/bunches/*_oligo.bb
do
    rm -f TEMP.bed
    bigBedToBed -type=bed9 $file TEMP.bed
    cat TEMP.bed >> COMBO.bed
    rm -f TEMP.bed
done
cat COMBO.bed | sort -k1,1 -k2,2n > COMBO_sorted.bed
rm -f COMBO.bed

bedToBigBed -type=bed9 COMBO_sorted.bed ${ucscBuild} "${PublicPath}/oligos.bb"
rm -f COMBO_sorted.bed

# ------------------------------
# exclusions

rm -f COMBO.bed
for file in ${PublicPath}/bunches/*_exclusion.bb
do
    rm -f TEMP.bed
    bigBedToBed -type=bed9 $file TEMP.bed
    cat TEMP.bed >> COMBO.bed
    rm -f TEMP.bed
done
cat COMBO.bed | sort -k1,1 -k2,2n > COMBO_sorted.bed
rm -f COMBO.bed

bedToBigBed -type=bed9 COMBO_sorted.bed ${ucscBuild} "${PublicPath}/exclusions.bb"
rm -f COMBO_sorted.bed

# ------------------------------

    fileName="oligos.bb"
    trackName=$( echo ${fileName} | sed 's/\.bb$//' )
    longLabel="${trackName}_coordinates"
    trackColor="133,0,122"
    trackPriority="1"
    visibility="full"
    trackType="bb"
    
    doRegularTrack
    
    fileName="exclusions.bb"
    trackName=$( echo ${fileName} | sed 's/\.bb$//' )
    longLabel="${trackName}_coordinates"
    trackColor="133,0,0"
    trackPriority="2"
    visibility="full"
    trackType="bb"
    
    doRegularTrack
    
# -----------------------------

printThis="Rainbow tracks, hub.txt genomes.txt  .."
printToLogFile


# The missing part is :
# genomes.txt hub.txt
# tracks.txt (for the already-existing bigwig COMBINED tracks - which should have numbers according to their color already)

# -----------------------------

# Main folder hubs are the COMBINED hubs, so should have relative paths (between hub and genome) already ..
cp $( ls -1 ${PublicPath}/bunches/*hub.txt | head -n 1 ) ${Sample}_${CCversion}_hub.txt
sed -i 's/hub\s*/hub ' ${Sample}_${CCversion}'_rainbow/'
echo "genome ${GENOME}" > ${Sample}_${CCversion}_genomes.txt
echo "trackDb ${Sample}_${CCversion}_tracks.txt" > ${Sample}_${CCversion}_genomes.txt

    
longLabel="${Sample}_${CCversion}_rainbow"
trackName="${Sample}_${CCversion}_rainbow"
overlayType="transparentOverlay"
windowingFunction="maximum"
visibility="full"
doMultiWigParent

# Go through all bigwigs in the run folder
setColors
for file in $( ls -1 ${PublicPath}/bunches/${GENOME}/*.bw )
do
  doOneColorChild
done

cat TEMP2_tracks.txt >> ${PublicPath}/${Sample}_${CCversion}_tracks.txt

# This relies on the knowledge that this was started in the D_VISUALISATIONS folder

B_FOLDER_PATH=$(dirname$($(pwd))/B_mapAndDivideFastqs)
D_FOLDER_PATH=$(dirname$($(pwd))/D_analyseOligoWise)

pwd

# -------------------------------

printThis="Description.html copy to public .."
printToLogFile

# Moving the description file
thisLocalData="${sampleForCCanalyser}"
thisLocalDataName'${sampleForCCanalyser}'
isThisLocalDataParsedFineAndMineToMeddle

thisPublicFolder="${publicPathForCCanalyser}"
thisPublicFolderName='${publicPathForCCanalyser}'
isThisPublicFolderParsedFineAndMineToMeddle

rm -f ${publicPathForCCanalyser}/${sampleForCCanalyser}_description.html
cp "${sampleForCCanalyser}_description.html" "${publicPathForCCanalyser}/."
    
printThis="All done with the combined Rainbow hub !"
printNewChapterToLogFile

updateHub_part3 





