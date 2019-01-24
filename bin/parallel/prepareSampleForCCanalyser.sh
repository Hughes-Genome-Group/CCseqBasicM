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

# This file fetches the fastqs in plateScreen96.sh style, the way that code was 21Feb2018
# The sub printRunStartArraysFastq is taken from plateScreen96.sh main script, and modified here.

printRunStartArraysFastq(){
    
    echo
    echo "Ready to run ! - here printout of main for loop parameters : "
    echo
 

    for k in $( seq 0 $((${#fileList1[@]} - 1)) ); do
        echo "fileList1[$k]  ${fileList1[$k]}"
    done    
    echo    
      
    for k in $( seq 0 $((${#fileList2[@]} - 1)) ); do
        echo "fileList2[$k]  ${fileList2[$k]}"
    done    
    echo
    
    
}

# ------------------------------------------

# Hardcoded parameters - this pipeline does not support multilane, non-gzipped, or single end data

LANES=1
GZIP=1
SINGLE_END=0

timestamp=$( date +%d%b%Y_%H_%M )

#------------------------------------------

echo "prepareSampleForCCanalyser.sh - by Jelena Telenius, 14/02/2018"
echo
timepoint=$( date )
echo "run started : ${timepoint}"
echo
echo "Script located at"
which $0
echo

echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "prepareSampleForCCanalyser.sh" $@
echo

thisFastqDownloadLogBasename=$1
JustNowLogFile=$2


echo "BLAT" > ${JustNowLogFile}

echo "thisFastqDownloadLogBasename ${thisFastqDownloadLogBasename}"
echo "JustNowLogFile ${JustNowLogFile}"

# For making sure we know where we are ..
weAreHere=$( pwd )

#------------------------------------------

echo "SetParams" > ${JustNowLogFile}

# Loading subroutines in ..

echo "Loading subroutines in .."

PipeTopPath="$( which $0 | sed 's/\/prepareSampleForCCanalyser.sh$//' )"

BashHelpersPath="${PipeTopPath}/bashHelpers"

# READING THE PARAMETER FILES IN (in NGseqBasic style)
 . ${BashHelpersPath}/parameterFileReaders.sh

# LOADING FASTQS AND COMBINING LANES (NGseqBasic style - basic subroutines, tester subs in GEObuilder style)
. ${BashHelpersPath}/inputFastqs.sh

# TEST THE EXISTENCE OF INPUT FILES
. ${BashHelpersPath}/fileTesters.sh

# TESTING file existence, log file output general messages
CaptureCommonHelpersPath=$( dirname ${PipeTopPath} )"/commonSubroutines"
. ${CaptureCommonHelpersPath}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found in $0. Cannot continue without safety features turned on ! \n EXITING !! "
    printToLogFile
    exit 1
fi


#------------------------------------------

echo
echo "PipeTopPath ${PipeTopPath}"
echo "BashHelpersPath ${BashHelpersPath}"
echo

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

# Here PIPE_fastqPaths.txt is a 3 or 4 column file where the 1st column is the TEMP FOLDER BASENAME from the parallel scripts
# This temp folder name will be just a line number from the fastq file.
# But as far as this script is concerned, it is the "sample name" - as it is column 1 in the PIPE_fastqPaths.txt
# PIPE_fastqPaths.txt entering this script is oneliner - the loop over it will be exactly loop over one sample.

if [ ! -s "./PIPE_fastqPaths.txt" ] ;then
    echo  >&2
    echo "PIPE_fastqPaths.txt file not found : fastq paths cannot be set ! - analysis aborted"  >&2
    echo  >&2
    exit 1
fi

#---------------------------------------------------------
# Here parsing the parameter files - if they are not purely tab-limited, but partially space-limited, or multiple-tab limited, this fixes it.
# Also, removing emptylines.

echo
echo "PARAMETER FILES GIVEN IN RUN FOLDER :"
echo

for file in ./PIPE*.txt
    do
        echo ${file}
        sed -i 's/\s\s*/\t/g' ${file}
        sed -i 's/^\s*//' ${file}
        sed -i 's/\s*$//' ${file}
        
        moveCommand='mv -f ${file} TEMP.txt'
        moveThis="${file}"
        moveToHere="TEMP.txt"
        checkMoveSafety
        
        mv -f ${file} TEMP.txt
        cat TEMP.txt | sed 's/^\s*$//' | grep -v "^\s*$" > ${file}
        rm -f TEMP.txt
    done

#--------THE-LOOP-over-all-FASTQ-files------------------------------------------------------   

# PIPE_fastqPaths.txt entering this script is ONELINER - the loop over it will be exactly loop over one sample.

printThis="Found parameter file PIPE_fastqPaths.txt - will proceed with FASTQ file loading !"
printToLogFile

# pwd >&2
cdCommand='cd ${weAreHere}'
cdToThis="${weAreHere}"
checkCdSafety  
cd ${weAreHere} 
# pwd >&2

    nameList=()
    fileList1=()
    fileList2=()
    fastqParameterFileReader
    # The above reads PIPE_fastqPaths.txt
    # And sets these :
    # LISTS : nameList fileList1 fileList2
    
    printRunStartArraysFastq
    
    # NOTE !! about "nameList" :
    #
    # Here PIPE_fastqPaths.txt is a 3 or 4 column file where the 1st column is the TEMP FOLDER BASENAME from the parallel scripts
    # This temp folder name will be just a line number from the fastq file.
    # But as far as this script is concerned, it is the "sample name" - as it is column 1 in the PIPE_fastqPaths.txt

for (( i=0; i<=$(( ${#nameList[@]} -1 )); i++ ))
do
    printThis="$( echo ${nameList[$i]} | sed 's/gz_/gz\n/g' )"
    printNewChapterToLogFile
    prepareOK=1

    # NOTE !! about "nameList" :
    #
    # Here PIPE_fastqPaths.txt is a 3 or 4 column file where the 1st column is the TEMP FOLDER BASENAME from the parallel scripts
    # This temp folder name will be just a line number from the fastq file.
    # But as far as this script is concerned, it is the "sample name" - as it is column 1 in the PIPE_fastqPaths.txt
    
    pwd
    pwd >&2
    
    #Fetch FASTQ :
    if [ "$LANES" -eq 1 ] ; then 
    # If we have single lane sequencing.
    
    echo "fetchFastq" > ${JustNowLogFile}    
    fetchFastq
    echo "inspectFastq" > ${JustNowLogFile}
    inspectFastq
    
    if [ "${prepareOK}" -ne 0 ]; then {
        # The actual pipe run !
        printThis="Fastqs loaded - Ready for fastq analysis run !"
        printNewChapterToLogFile
        echo 1 > prepareOK
        }
    else {
        printThis="Fastqs not loaded - Aborting fastq analysis run for sample : ${nameList[$i]}"
        printNewChapterToLogFile
        echo 0 > prepareOK
        }
    fi

    else
    # If we have MULTIPLE lanes from sequencing.
    echo "fetchFastq" > ${JustNowLogFile}  
    fetchFastqMultilane
    echo "inspectFastq" > ${JustNowLogFile}
    inspectFastqMultilane

    if [ "${prepareOK}" -ne 0 ]; then {
        # The actual pipe run !
        printThis="Fastqs loaded - Ready for CCanalyser runs for sample : ${nameList[$i]}"
        printNewChapterToLogFile
        }
    else {
        printThis="Fastqs not loaded - Aborting CCanalyser runs for sample : ${nameList[$i]}"
        printNewChapterToLogFile
        }
    fi
    
    fi

done

# ----------------------------------------
# All done !

timepoint=$( date )
echo
echo "fastq preparing finished : ${timepoint}"
echo

exit 0




