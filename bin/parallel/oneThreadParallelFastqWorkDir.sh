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
echo "RUN CRASHED ! oneThreadParallelFastqWorkDir.sh for fastq_${fastqCounter} - check qsub.err to see why !"
echo

echo "prepareOK 0 runOK 0" > ${SGE_O_WORKDIR}/fastq_${fastqCounter}/fastqRoundSuccess.log

else

echo
date
printThis="oneThreadParallelFastqWorkDir.sh : Analysis complete for fastq_${fastqCounter} ! "
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

echo "oneThreadParallelFastqWorkDir.sh - by Jelena Telenius, 26/05/2018"
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
echo "oneThreadParallelFastqWorkDir.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
fastqCounter=$SGE_TASK_ID

# Writing the queue environment variables to a log file :
./fastq_${fastqCounter}/echoer_for_SunGridEngine_environment.sh > ${SGE_O_WORKDIR}/fastq${SGE_TASK_ID}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

printThis="fastq_${fastqCounter} : Run F1 folder fastq-wise (QC,trimming,flashing,RE-digestion,mapping) .. "
printNewChapterToLogFile
  

    cd fastq_${fastqCounter}        
    pwd
    echo
    
    ./prepareFastqs.sh
    prepareOK=$(($( cat prepareOK )))
    rm -f prepareOK
    if [ "${prepareOK}" -ne 0 ]; then {

      echo "fastq analysis started : $(date)"
     
      printThis="$(cat runFastqs.sh)"
      printToLogFile
      printThis="You can follow the run progress from error and out files :\nB_mapAndDivideFastqs/fastq_${fastqCounter}/runB.out\nB_mapAndDivideFastqs/fastq_${fastqCounter}/runB.err"
      printToLogFile
        
      runOK=1
      # ${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${capturesitefile} --R1 READ1.fastq --R2 READ2.fastq --parallel 1 --parallelSubsample fastq_${fastqCounter} --${REenzymeShort} --pf ${publicfolder}  ${parameterList}  --outfile runB.out --errfile runB.err  1> runB.out 2> runB.err
      ./runFastqs.sh
      if [ $? != 0 ]; then
      {
        runOK=0    

        printThis="Fastq run and/or dividing bam files along capturesite file coordinates failed on line ${fastqCounter} of PIPE_fastqPaths.txt ! "
        printToLogFile
        
      }
      fi  
    }
    else
    {
      printThis="Couldn't prepare fastqs on line ${fastqCounter} of PIPE_fastqPaths.txt for CCanalyser run ! "
      printToLogFile  
      runOK=0
    }
    fi
    
    printThis="prepareOK ${prepareOK} runOK ${runOK}"
    printToLogFile
    echo "prepareOK ${prepareOK} runOK ${runOK}" > fastqRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

