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

# ------------------------------------------

# Hardcoded parameters - this pipeline does not support multilane, non-gzipped, or single end data

LANES=1
GZIP=1
SINGLE_END=0

timestamp=$( date +%d%b%Y_%H_%M )

#------------------------------------------

echo "fastqExistenceChecks.sh - by Jelena Telenius, 14/02/2018"
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
echo "fastqExistenceChecks.sh" $@
echo


# For making sure we know where we are ..
weAreHere=$( pwd )

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

PipeTopPath="$( which $0 | sed 's/\/fastqExistenceChecks.sh$//' )"

BashHelpersPath="${PipeTopPath}/bashHelpers"

# TEST THE FASTQ PARAMETER FILES FOR INCONSISTENCIES (pyramid VS004 17Feb2017 copied subroutines, modified to 2-3 column input file - only testing, no generating or parsing)
. ${BashHelpersPath}/fastqChecksFromPyramid.sh

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
echo "CaptureCommonHelpersPath ${CaptureCommonHelpersPath}"
echo

#------------------------------------------

if [ ! -s "./PIPE_fastqPaths.txt" ] ;then
    echo  >&2
    echo "PIPE_fastqPaths.txt file not found : fastq paths cannot be set ! - analysis aborted"  >&2
    echo  >&2
    exit 1
fi

#---------------------------------------------------------
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


#--------THE-TEST-PARAMETER-FILE-LOOP-over-all-FASTQ-files------------------------------------------------------

printThis="Found parameter file PIPE_fastqPaths.txt - will check that the FASTQ parameters are fine .."
printNewChapterToLogFile

fastqDataOK=1

rm -rf TEMPdir
mkdir TEMPdir
cd TEMPdir
# Exit, if it didn't happen : avoid overwriting intact PIPE_fastqPaths.txt just because some crazy error.
if [ "$( basename $( pwd ))" != "TEMPdir" ]; then print "Couldn't make a TEMP dir for exploring parameter files - exiting ! " >&2 ; exit 1 ; fi

    # Test that we have uniq lines, uniq files, uniq lanes, etc, here ..
    # ( using PYRAMID VS004 copied 17Feb2017 subroutines modified to 2-3 column input files : see below)
    
    # The divideFastqFilenames needs file ../PIPE_fastqPaths.txt to read in (only files plus folder, so 3 column file - in principle also supports single end )..
    # So, possibilities are :
    #
    # file        | file       | path   PE (no multilane support)
    # path/file   | path/file           PE (no multilane support)
    #
    # file        | path                SE (the below sub checkFastqFiles supports this - but CC pipe obviously doesn't. no multilane support.)
    # path/file                         SE (the below sub checkFastqFiles supports this - but CC pipe obviously doesn't. no multilane support.)
    #
    
    rm -f PIPE_fastqPaths.txt
    cp ../PIPE_fastqPaths.txt .
   
    checkFastqFiles
    
    if [ -s "./FASTQ_LOAD.err" ]; then
        mv FASTQ_LOAD.err ../.
    fi
    
cd ..
rm -rf TEMPdir

# The above generates FASTQ_LOAD.err - checking for the existence of it is enough to see if it went wrong !
# Also - parameter value fastqDataOK=0 would tell the same.

#--------Crashing-if-needed---------------------------------------------------------------------

if [ "${fastqDataOK}" -eq 0 ] ; then

printThis="Run crashed - parameter files given wrong. Check output files FASTQ_LOAD.err "
printToLogFile

printThis="  fastqDataOK ${fastqDataOK}\n "
printToLogFile

if [ -s "./FASTQ_LOAD.err" ] ; then
    cat FASTQ_LOAD.err  >&2
    cat FASTQ_LOAD.err  
fi

exit 1

else
    
printThis="  fastqDataOK ${fastqDataOK}\n "
printToLogFile
    
fi

#---------------------------------------------------------

