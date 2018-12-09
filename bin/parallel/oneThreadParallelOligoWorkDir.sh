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
echo "RUN CRASHED ! oneThreadParallelFastqWorkDir.sh for ${capturesiteFolderRelativePath} - check qsub.err to see why !"
echo

echo "runOK 0" > ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log

else
    
printThis='Deleting all folder D bam and wig files (gff files and bigwig files remain, along with the original bam file in folder C ) '
printToLogFile

echo "Total disk space Megas (before deleting) : " > ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm 2>> /dev/null | cut -f 1 >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log

echo "Total disk space Megas of bam files (before deleting) : " >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm F[12345]*/*.bam 2>> /dev/null | cut -f 1 | tr '\n' '+' | sed 's/+$/\n/' | bc >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log
rm -f F[12345]*/*.bam

echo "Total disk space Megas of wig files (before deleting) : " >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm F[123456]*/*.wig 2>> /dev/null | cut -f 1 | tr '\n' '+' | sed 's/+$/\n/' | bc >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log
rm -f F[123456]*/*.wig

echo "Total disk space (after deleting) : " >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log
du -sm 2>> /dev/null | cut -f 1 >> ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/bamWigSizesBeforeDeleting.log

echo
date
printThis="oneThreadParallelFastqWorkDir.sh : Analysis complete for fastq_${capturesiteCounter} ! "
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

echo "oneThreadParallelCapturesiteWorkDir.sh - by Jelena Telenius, 26/05/2018"
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
echo "oneThreadParallelCapturesiteWorkDir.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
capturesiteCounter=$SGE_TASK_ID

# Writing the queue environment variables to a log file :
# ./${capturesiteFolderRelativePath}/echoer_for_SunGridEngine_environment.sh > ${SGE_O_WORKDIR}/capturesite${SGE_TASK_ID}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
./${capturesiteFolderRelativePath}/echoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

printThis="capturesite_${capturesiteCounter} : Run CC analysis capturesite-wise (after F1 folder) .. "
printNewChapterToLogFile
  
    capturesiteFolderRelativePath=$(cat runlistings/capturesite${capturesiteCounter}.txt | head -n 1 | cut -f 1)

    cd ${capturesiteFolderRelativePath}        
    pwd
    echo

    echo "capture analysis started : $(date)"
    
      printThis="$(cat run.sh)"
      printToLogFile
        
      runOK=1
      ./run.sh
      if [ $? != 0 ]; then
      {
        runOK=0    

        printThis="Capturesite-wise CC analysis failed on line ${capturesiteCounter} of C_analyseCapturesiteBunches/runlist.txt ! "
        printToLogFile
        
      }
      fi  
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > capturesiteRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

