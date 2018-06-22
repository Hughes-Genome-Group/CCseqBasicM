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

. ${confFolder}/genomeBuildSetup.sh
. ${confFolder}/loadNeededTools.sh
. ${confFolder}/serverAddressAndPublicDiskSetup.sh

# setConfigLocations
setPathsForPipe
setGenomeLocations
setPublicLocations

echo 
echo "Supported genomes : "
for g in $( seq 0 $((${#supportedGenomes[@]}-1)) ); do echo -n "${supportedGenomes[$g]} "; done
echo 
echo

echo 
echo "Blacklist filtering available for these genomes : "
for g in $( seq 0 $((${#genomesWhichHaveBlacklist[@]}-1)) ); do echo -n "${genomesWhichHaveBlacklist[$g]} "; done
echo 
echo

# -------------------------------


oneFlashFastqcCopyRound(){
    
# http://multiqc.info/docs/
# The FastQC MultiQC module looks for files called fastqc_data.txt or ending in _fastqc.zip.
# If the zip files are found, they are read in memory and fastqc_data.txt parsed.

if [ ! -d ${reportfolder}/${flashtype} ]; then
  mkdir ${reportfolder}/${flashtype}
fi    

for folder in */F1*/${flashtype}_fastqc
do 
nameStart=$( echo $folder | sed 's/\/.*//')
nameEnd=$( basename $folder | sed 's/_fastqc$//' )
nameMiddle=$( dirname $folder | sed 's/.*\/F1_beforeCCanalyser_//' )
# ln -s ../../$folder ${reportfolder}/${flashtype}/${nameStart}_${nameMiddle}_${nameEnd}_fastqc
cp ${folder}.zip ${reportfolder}/${flashtype}/${nameStart}_${nameMiddle}_${nameEnd}_fastqc.zip
ls -l ${reportfolder}/${flashtype}/${nameStart}_${nameMiddle}_${nameEnd}_fastqc.zip
done

}

oneTrimFastqcCopyRound(){

# http://multiqc.info/docs/
# The FastQC MultiQC module looks for files called fastqc_data.txt or ending in _fastqc.zip.
# If the zip files are found, they are read in memory and fastqc_data.txt parsed.

if [ ! -d ${reportfolder}/${trimtype}_READ1 ]; then
  mkdir ${reportfolder}/${trimtype}_READ1
fi    

if [ ! -d ${reportfolder}/${trimtype}_READ2 ]; then
  mkdir ${reportfolder}/${trimtype}_READ2
fi    

for folder in */F1*/READ1*_fastqc_${trimtype}
do 
nameStart=$( echo $folder | sed 's/\/.*//')
nameEnd=$( basename $folder | sed 's/_fastqc$//' )
nameMiddle=$( dirname $folder | sed 's/.*\/F1_beforeCCanalyser_//' )
cp ${folder}.zip ${reportfolder}/${trimtype}_READ1/${nameStart}_${nameMiddle}_${nameEnd}_fastqc.zip
# ls -l ${reportfolder}/${trimtype}_READ1/${nameStart}_${nameMiddle}_${nameEnd}_fastqc.zip
done

for folder in */F1*/READ2*_fastqc_${trimtype}
do 
nameStart=$( echo $folder | sed 's/\/.*//')
nameEnd=$( basename $folder | sed 's/_fastqc$//' )
nameMiddle=$( dirname $folder | sed 's/.*\/F1_beforeCCanalyser_//' )
cp ${folder}.zip ${reportfolder}/${trimtype}_READ2/${nameStart}_${nameMiddle}_${nameEnd}_fastqc.zip
# ls -l ${reportfolder}/${trimtype}_READ2/${nameStart}_${nameMiddle}_${nameEnd}_fastqc.zip
done

}

    
weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs

tempTopDir=$(pwd)
echo
pwd

reportfolder="fastqcReports"
multiqcfolder="multiqc"
multiqcreportfolder="multiqcReports"

echo "reportfolder : fastqcReports"
echo "multiqcfolder : multiqc"
echo "multiqcreportfolder : multiqcReports"

rmCommand='rm -rf ${reportfolder}'
rmThis="${reportfolder}"
checkRemoveSafety
rm -rf ${reportfolder}
mkdir ${reportfolder}

rmCommand='rm -rf ${multiqcfolder}'
rmThis="${multiqcfolder}"
checkRemoveSafety
rm -rf ${multiqcfolder}
mkdir ${multiqcfolder}

rmCommand='rm -rf ${multiqcreportfolder}'
rmThis="${multiqcreportfolder}"
checkRemoveSafety
rm -rf ${multiqcreportfolder}
mkdir ${multiqcreportfolder}

trimtype="ORIGINAL"
oneTrimFastqcCopyRound

trimtype="TRIMMED"
oneTrimFastqcCopyRound

flashtype="FLASHED"
oneFlashFastqcCopyRound

flashtype="FLASHED_REdig"
oneFlashFastqcCopyRound

flashtype="NONFLASHED"
oneFlashFastqcCopyRound

flashtype="NONFLASHED_REdig"
oneFlashFastqcCopyRound

cdCommand='cd ${reportfolder}'
cdToThis="${reportfolder}"
checkCdSafety
cd ${reportfolder}
# ls -lh
# ls -lh *

for folder in *
do
echo $folder
if [ -d $folder ]; then
  echo "multiqc -d -o ../${multiqcfolder}/${folder}_report $folder"
  multiqc -d -o ../${multiqcfolder}/${folder}_report $folder
fi
done
cdCommand='cd ${tempTopDir}'
cdToThis="${tempTopDir}"
checkCdSafety
cd ${tempTopDir}
# ls -lht ${multiqcfolder}/*_report/multiqc_report.html

for file in ${multiqcfolder}/*_report/multiqc_report.html
do
    cp $file ${multiqcreportfolder}/$( basename $( dirname $file ) ).html
done
    
ls -lht ${multiqcreportfolder}

rmCommand='rm -rf ${reportfolder}'
rmThis="${reportfolder}"
checkRemoveSafety
rm -rf ${reportfolder}

rmCommand='rm -rf ${multiqcfolder}'
rmThis="${multiqcfolder}"
checkRemoveSafety
rm -rf ${multiqcfolder}

multiqcreportfolder=$(pwd)/${multiqcreportfolder}

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety
cd ${weWereHereDir}
    


