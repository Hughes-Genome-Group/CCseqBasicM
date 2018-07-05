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

# This file fetches the fastqs in plateScreen96.sh style, the way that code was 21Feb2018
# The sub printRunStartArraysFastq is taken from plateScreen96.sh main script, and modified here.

function finish {

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! oneThreadParallelFastq.sh for fastq_${fastqCounter} - check qsub.err to see why !"
echo "Dumped files in ${SGE_O_WORKDIR}/fastq_${fastqCounter}_CRASHED"
echo

echo "$(pwd) before cleaning up : "
ls -lht

echo "TMPDIR before cleaning up : "
ls -lht

mkdir ${SGE_O_WORKDIR}/fastq_${fastqCounter}_CRASHED
mv -f ${TMPDIR}/* ${SGE_O_WORKDIR}/fastq_${fastqCounter}_CRASHED/*

rm -f ${TMPDIR}/*

echo "TMPDIR after cleaning up"
ls -lht ${TMPDIR}

if [ ! -d ${SGE_O_WORKDIR}/fastq_${fastqCounter} ];then
mkdir ${SGE_O_WORKDIR}/fastq_${fastqCounter}
fi
echo "prepareOK 0 runOK 0" > ${SGE_O_WORKDIR}/fastq_${fastqCounter}/fastqRoundSuccess.log

else

echo
date
printThis="oneThreadParallelFastq.sh : Analysis complete for fastq_${fastqCounter} ! "
printToLogFile
    
fi

kill ${tmpdirMmemoryAskerProcessnumber}

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

doQuotaTesting(){
        
    echo
    echo "Local disk usage for THIS RUN - at the moment (check you don't go over your t1-data area quota) :"
    du -sh ${SGE_O_WORKDIR} 2>> /dev/null
    echo "TMPDIR cluster temp area usage - check you don't go over 12GB (normal queue) or 200GB (largemem queue) :"
    du -sh ${TMPDIR} 2>> /dev/null

#_____________________
# For testing purposes

# echo $0

free -m
# df -m 
# du -m 
# ps T

#_____________________
    
    
}



# -----------------------------------------

# Normal runs (not only help request) starts here ..

echo "oneThreadParallelFastq.sh - by Jelena Telenius, 26/05/2018"
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
echo "oneThreadParallelFastq.sh" $@
echo

parameterList=$@
#------------------------------------------

# The fastq number is the task number ..
fastqCounter=$SGE_TASK_ID

# Writing the queue environment variables to a log file :
fastq_${fastqCounter}/echoer_for_SunGridEngine_environment.sh > ${SGE_O_WORKDIR}/fastq${fastqCounter}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

printThis="fastq_${fastqCounter} : Run F1 folder fastq-wise (QC,trimming,flashing,RE-digestion,mapping) .. "
printNewChapterToLogFile
    # ##########################################
    # HERE PARALLEL MOVE TO TEMPDIR !
    
    printThis="Moving to TMPDIR ${TMPDIR}"
    printNewChapterToLogFile
    
    cd ${TMPDIR}
    echo
    echo "Here we are :"
    echo
    pwd
    echo
    
    cp -r ${SGE_O_WORKDIR}/fastq_${fastqCounter}/* .
    mv ${SGE_O_WORKDIR}/fastq_${fastqCounter} ${SGE_O_WORKDIR}/fastq_${fastqCounter}_beforeTMPDIR
    
    echo
    echo "Copied over the parameter files :"
    echo
    
    ls -lht
    
    # ##########################################
    
    # Starting the memory monitoring ..
    
    echo './tmpdirMemoryasker.sh ${oligoCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ & '
    echo "i.e."
    echo "./tmpdirMemoryasker.sh ${oligoCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ & "
    ./tmpdirMemoryasker.sh ${fastqCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ &
    tmpdirMmemoryAskerProcessnumber=$!

    # ##########################################
    
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
      # ${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${oligofile} --R1 READ1.fastq --R2 READ2.fastq --parallel 1 --parallelSubsample fastq_${fastqCounter} --${REenzymeShort} --pf ${publicfolder}  ${parameterList}  --outfile runB.out --errfile runB.err  1> runB.out 2> runB.err
      ./runFastqs.sh
      if [ $? != 0 ]; then
      {
        runOK=0    

        printThis="Fastq run and/or dividing bam files along oligo file coordinates failed on line ${fastqCounter} of PIPE_fastqPaths.txt ! "
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
  
    # ##########################################
    # HERE PARALLEL MOVE BACK TO REAL DIR !
    
    printThis="Moving back to real life - from TMPDIR ${TMPDIR}"
    printNewChapterToLogFile
    
    printThis="moving data from "${TMPDIR}" to "${SGE_O_WORKDIR}
    printToLogFile
    
    ls -lR $(pwd) > TMPareaBeforeMovingBack.log

    mkdir ${SGE_O_WORKDIR}/fastq_${fastqCounter}
    mv -f * ${SGE_O_WORKDIR}/fastq_${fastqCounter}/.
    
    printThis="emptying temp area ${TMPDIR}"
    printToLogFile
    
    rm -rf *
    
    printThis="returning to "${SGE_O_WORKDIR}/fastq_${fastqCounter}
    printToLogFile
    
    cd ${SGE_O_WORKDIR}/fastq_${fastqCounter}
    echo
    echo "Here we are :"
    echo
    pwd
    echo
    
    ls -lR $(pwd) > TMPareaAfterMovingBack.log
    
    cat TMPareaBeforeMovingBack.log  | sed 's/\s\s*/\t/g' | grep '^-' | cut -f 5,9 | sort -k2,2 -k1,1 | grep -v MovingBack > forDiff1.txt
    cat TMPareaAfterMovingBack.log   | sed 's/\s\s*/\t/g' | grep '^-' | cut -f 5,9 | sort -k2,2 -k1,1 | grep -v MovingBack > forDiff2.txt
    
    doQuotaTesting
    
    printThis="checking that all got moved properly"
    printToLogFile
    
    if [ $(($(diff forDiff1.txt forDiff2.txt | grep -c ""))) -ne 0 ]; then
        printThis="MOVE FAILED - run not fine ! "
        printNewChapterToLogFile
        
        runOK=0    
    fi
    
    # Removing temp if all went fine
    if [ "${runOK}" -eq 1 ];then
        echo "would delete beforeTMPDIR here - but commenterd out "
        # rm -rf ${SGE_O_WORKDIR}/fastq_${fastqCounter}_beforeTMPDIR
    fi
    
    cd ${SGE_O_WORKDIR}
    
    echo
    echo "Now all is clear - we can continue like we never went to TMPDIR ! "
    echo

    # ##########################################
    
    # Non-functinal symlink looks kinda bad, so getting rid of it now ..
    rm -f echoer_for_SunGridEngine_environment.sh
    
    printThis="prepareOK ${prepareOK} runOK ${runOK}"
    printToLogFile
    echo "prepareOK ${prepareOK} runOK ${runOK}" > fastq_${fastqCounter}/fastqRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

