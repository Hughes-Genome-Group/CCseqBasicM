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

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# /home/molhaem2/telenius/CCseqBasic/CCseqBasic4/bin/runscripts/filterArtifactMappers/filter.sh
CaptureTopPath="$( echo $0 | sed 's/\/parallel_QC.sh//' )"
CaptureCommonHelpersPath=$( dirname ${CaptureTopPath} )"/commonSubroutines"

# SETTING THE GENOME BUILD PARAMETERS
. ${CaptureCommonHelpersPath}/genomeSetters.sh

# SETTING THE BLACKLIST GENOME LIST PARAMETERS
. ${CaptureCommonHelpersPath}/blacklistSetters.sh

# DEBUG SUBROUTINES - for the situations all hell breaks loose
# . ${CapturePipePath}/subroutines/debugHelpers.sh

# TESTING file existence, log file output general messages
. ${CaptureCommonHelpersPath}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found in $0. Cannot continue without safety features turned on ! \n EXITING !! "
    printToLogFile
    exit 1
fi


#------------------------------------------

# From where to call the main scripts operating from the runscripts folder..

echo
echo "PipeTopPath ${PipeTopPath}"
echo "CaptureCommonHelpersPath ${CaptureCommonHelpersPath}"
echo


#------------------------------------------

printThis="$0"
printToLogFile

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

printThis="Testing the tester subroutines in $0 .."
printToLogFile
printThis="${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err"
printToLogFile
   
${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err
# The above exits if any of the tests don't work properly.

# The below exits if the logger test sub wasn't found (path above wrong or file not found)
if [ "$?" -ne 0 ]; then
    printThis="Testing testers_and_loggers.sh safety routines failed in $0 . Cannot continue without testing safety features ! \n EXITING !! "
    printToLogFile
    exit 1
else
    printThis="Testing the tester subroutines completed - continuing ! "
    printToLogFile
fi

# Comment this out, if you want to save these files :
rm -f testers_and_loggers_test.out testers_and_loggers_test.err

#------------------------------------------

# From where to call the CONFIGURATION script..

confFolder=$( dirname $( dirname ${CaptureTopPath} ) )"/conf"

#------------------------------------------

echo
echo "confFolder ${confFolder}"
echo

#------------------------------------------

# Calling in the CONFIGURATION script and its default setup :

echo "Calling in the conf/config.sh script and its default setup .."

CaptureDigestPath="NOT_IN_USE"
supportedGenomes=()
BOWTIE1=()
UCSC=()
genomesWhichHaveBlacklist=()
BLACKLIST=()

. ${confFolder}/loadNeededTools.sh

# setConfigLocations
setPathsForPipe

# -------------------------------


# ------------------------------------------

oneMultiqcRound(){
# ------------------------------------------

rm -rf forMulti_TMP
mkdir  forMulti_TMP

for folder in fastq_*
do 
mkdir forMulti_TMP/$folder
cp -r $folder/F1_beforeCCanalyser_${samplename}_${CCversion}/${multiRoundFolder}     forMulti_TMP/$folder/${multiRoundName}_fastqc
cp    $folder/F1_beforeCCanalyser_${samplename}_${CCversion}/${multiRoundFolder}.zip forMulti_TMP/$folder/${multiRoundName}_fastqc.zip
done

rm -rf forMulti_${multiRoundName}
multiqc -o multiqcReports/${multiRoundName} forMulti_TMP
rm -rf forMulti_TMP

# ------------------------------------------
}

# ------------------------------------------

makeMultiqcReports(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs

rm -rf multiqcReports

multiRoundName="FLASHED"
multiRoundFolder="FLASHED_fastqc"
oneMultiqcRound

multiRoundName="NONFLASHED"
multiRoundFolder="NONFLASHED_fastqc"
oneMultiqcRound

multiRoundName="FLASHED_REdig"
multiRoundFolder="FLASHED_REdig_fastqc"
oneMultiqcRound

multiRoundName="NONFLASHED_REdig"
multiRoundFolder="NONFLASHED_REdig_fastqc"
oneMultiqcRound

multiRoundName="READ1_unmodified"
multiRoundFolder="READ1_fastqc_ORIGINAL"
oneMultiqcRound

multiRoundName="READ2_unmodified"
multiRoundFolder="READ2_fastqc_ORIGINAL"
oneMultiqcRound

multiRoundName="READ1_trimmed"
multiRoundFolder="READ1_fastqc_TRIMMED"
oneMultiqcRound

multiRoundName="READ2_trimmed"
multiRoundFolder="READ2_fastqc_TRIMMED"
oneMultiqcRound

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

samplename=$1
CCversion=$2

makeMultiqcReports





