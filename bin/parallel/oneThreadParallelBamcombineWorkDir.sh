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

function finish {

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! oneThreadParallelFastqWorkDir.sh for ${capturesiteFolderRelativePath} - check qsub.err to see why !"
echo

echo "runOK 0" > ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log

else

echo
date
printThis="oneThreadParallelBamcombineWorkDir.sh : Analysis complete for fastq_${capturesiteCounter} ! "
printToLogFile
    
fi
}
trap finish EXIT

printToLogFile(){
   
# Needs this to be set :
# printThis="" 

echo ""
echo -e "${printThis}"
echo ""

echo "" >> "/dev/stderr"
echo -e "${printThis}" >> "/dev/stderr"
echo "" >> "/dev/stderr"
    
}


printNewChapterToLogFile(){

# Needs this to be set :
# printThis=""
    
echo ""
echo "---------------------------------------------------------------------"
echo -e "${printThis}"
echo "---------------------------------------------------------------------"
echo ""

echo "" >> "/dev/stderr"
echo "----------------------------------------------------------------------" >> "/dev/stderr"
echo -e "${printThis}" >> "/dev/stderr"
echo "----------------------------------------------------------------------" >> "/dev/stderr"
echo "" >> "/dev/stderr"
    
}

# -----------------------------------------

# Normal runs (not only help request) starts here ..

echo "oneThreadParallelBamcombineWorkDir.sh - by Jelena Telenius, 26/05/2018"
echo
timepoint=$( date )
echo "run started : ${timepoint}"
echo
echo "Script located at"
echo "$0"
echo

threadedrunSubmitDir=$(pwd)
echo "threadedrunSubmitDir ${threadedrunSubmitDir}"


echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "oneThreadParallelBamcombineWorkDir.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
capturesiteCounter=$SGE_TASK_ID
echo "bamCombine" > runJustNow_${capturesiteCounter}.log

printThis="capturesite_${capturesiteCounter} : Combining BAM files of all fastqs .. "
printNewChapterToLogFile
  
    capturesiteFolderRelativePath=$(cat runlistings/capturesite${capturesiteCounter}.txt | head -n 1 | cut -f 1)

    cd ${capturesiteFolderRelativePath}        
    pwd
    echo

    echo "bam combining started : $(date)"

    # Writing the queue environment variables to a log file :
    # ./echoer_for_SunGridEngine_environment.sh > ${SGE_O_WORKDIR}/bamcombine${capturesiteCounter}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
    ./echoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
    
    finCount=0
    nfinCount=0
    foutCount=0
    nfoutCount=0
    runOK=1
    ./bamCombineRun.sh
    if [ $? != 0 ] || [ -s samtoolsCat.err ]; then
    {
        runOK=0    

        printThis="Bam-combining failed on line ${capturesiteCounter} of C_analyseCapturesiteBunches/runlist.txt ! "
        printToLogFile
        
    }
    else
    {
        rm -f TEMP_FLASHED.head TEMP_NONFLASHED.head
        finCount=$(cat FLASHEDbamINcounts.txt | tr '\n' '+' | sed 's/+$/\n/' | bc -l)
        nfinCount=$(cat NONFLASHEDbamINcounts.txt | tr '\n' '+' | sed 's/+$/\n/' | bc -l)
        foutCount=$(cat FLASHEDbamOUTcount.txt)
        nfoutCount=$(cat NONFLASHEDbamOUTcount.txt)
        
        if [ "${finCount}" -ne "${foutCount}" ] || [ "${nfinCount}" -ne "${nfoutCount}" ]; then runOK=0; 
        
        printThis="Bam-combining generated truncated files on line ${capturesiteCounter} of C_analyseCapturesiteBunches/runlist.txt ! "
        printToLogFile
        
        fi
    }
    fi   
    
    if [ -s samtoolsCat.err ]; then
        printThis="This was samtools cat crash : error messages in "$(pwd)/samtoolsCat.err
        printToLogFile
    else
        rm -f samtoolsCat.err
    fi
    
    printThis="FLASHEDin ${finCount} FLASHEDout ${finCount} NONFLASHEDin ${nfinCount} NONFLASHEDout ${nfoutCount} runOK ${runOK}"
    printToLogFile
    echo "FLASHEDin ${finCount} FLASHEDout ${finCount} NONFLASHEDin ${nfinCount} NONFLASHEDout ${nfoutCount} runOK ${runOK}" > bamcombineSuccess.log
    
# ----------------------------------------
# All done !

cd ${threadedrunSubmitDir}

rm -f runJustNow_${capturesiteCounter}.log


exit 0

