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
# The sub printRunStartArraysOligo is taken from plateScreen96.sh main script, and modified here.

function finish {

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! oneThreadParallelOligo.sh for oligo_${oligoCounter} - check qsub.err to see why !"
echo "Dumped files in ${SGE_O_WORKDIR}/${oligoFolderRelativePath}_CRASHED"
echo

echo "$(pwd) before cleaning up : "
ls -lht

echo "TMPDIR before cleaning up : "
ls -lht

mkdir ${SGE_O_WORKDIR}/${oligoFolderRelativePath}_CRASHED
mv -f ${TMPDIR}/* ${SGE_O_WORKDIR}/${oligoFolderRelativePath}_CRASHED/*

rm -f ${TMPDIR}/*

echo "TMPDIR after cleaning up"
ls -lht ${TMPDIR}

if [ ! -d ${SGE_O_WORKDIR}/${oligoFolderRelativePath} ];then
mkdir ${SGE_O_WORKDIR}/${oligoFolderRelativePath}
fi
echo "runOK 0" > ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/oligoRoundSuccess.log

else
    
printThis='Deleting all folder D bam and wig files (gff files and bigwig files remain, along with the original bam file in folder C ) '
printToLogFile

echo "Total disk space Megas (before deleting) : " > ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm 2>> /dev/null | cut -f 1 >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log

echo "Total disk space Megas of bam files (before deleting) : " >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm F[12345]*/*.bam 2>> /dev/null | cut -f 1 | tr '\n' '+' | sed 's/+$/\n/' | bc >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log
rm -f F[12345]*/*.bam

echo "Total disk space Megas of wig files (before deleting) : " >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm F[123456]*/*.wig 2>> /dev/null | cut -f 1 | tr '\n' '+' | sed 's/+$/\n/' | bc >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log
rm -f F[123456]*/*.wig

echo "Total disk space (after deleting) : " >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm 2>> /dev/null | cut -f 1 >> ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/bamWigSizesBeforeDeleting.log

echo
date
printThis="oneThreadParallelOligo.sh : Analysis complete for ${oligoFolderRelativePath} ! "
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

echo "oneThreadParallelOligo.sh - by Jelena Telenius, 26/05/2018"
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
echo "oneThreadParallelOligo.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
oligoCounter=$SGE_TASK_ID

# Starting the memory monitoring ..
echo './tmpdirMemoryasker.sh ${oligoCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ & '
echo "i.e."
echo "./tmpdirMemoryasker.sh ${oligoCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ & "
./tmpdirMemoryasker.sh ${oligoCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ &
tmpdirMmemoryAskerProcessnumber=$!

# Writing the queue environment variables to a log file :
# ${oligoFolderRelativePath}/echoer_for_SunGridEngine_environment.sh > ${SGE_O_WORKDIR}/oligo${oligoCounter}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
${oligoFolderRelativePath}/echoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

printThis="oligo_${oligoCounter} : Run CC analysis oligo-wise (after F1 folder) .. "
printNewChapterToLogFile

oligoFolderRelativePath=$(cat runlistings/oligo${oligoCounter}.txt | head -n 1 | cut -f 1)

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
    
    cp -r ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/* .
    mv ${SGE_O_WORKDIR}/${oligoFolderRelativePath} ${SGE_O_WORKDIR}/${oligoFolderRelativePath}_beforeTMPDIR
    
    echo
    echo "Copied over the parameter files :"
    echo
    
    ls -lht
    
    # ##########################################  

    echo "capture analysis started : $(date)"
    
      printThis="$(cat run.sh)"
      printToLogFile
        
      runOK=1
      ./run.sh
      if [ $? != 0 ]; then
      {
        runOK=0    

        printThis="Oligo-wise CC analysis failed on line ${oligoCounter} of C_analyseOligoBunches/runlist.txt ! "
        printToLogFile
        
      }
      fi  
    
    doQuotaTesting
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > oligoRoundSuccess.log
    
  
    # ##########################################
    # HERE PARALLEL MOVE BACK TO REAL DIR !
    
    printThis="Moving back to real life - from TMPDIR ${TMPDIR}"
    printNewChapterToLogFile
    
    printThis="moving data from "${TMPDIR}" to "${SGE_O_WORKDIR}
    printToLogFile
    
    ls -lR $(pwd) > TMPareaBeforeMovingBack.log

    mkdir ${SGE_O_WORKDIR}/${oligoFolderRelativePath}
    mv -f * ${SGE_O_WORKDIR}/${oligoFolderRelativePath}/.
    
    printThis="emptying temp area ${TMPDIR}"
    printToLogFile
    
    rm -rf *
    
    printThis="returning to "${SGE_O_WORKDIR}/${oligoFolderRelativePath}
    printToLogFile
    
    cd ${SGE_O_WORKDIR}/${oligoFolderRelativePath}
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
        # rm -rf ${SGE_O_WORKDIR}/${oligoFolderRelativePath}_beforeTMPDIR
    fi
    
    cd ${SGE_O_WORKDIR}
    
    echo
    echo "Now all is clear - we can continue like we never went to TMPDIR ! "
    echo

    # ##########################################
    
    # Non-functinal symlink looks kinda bad, so getting rid of it now ..
    rm -f echoer_for_SunGridEngine_environment.sh
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > ${oligoFolderRelativePath}/oligoRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

