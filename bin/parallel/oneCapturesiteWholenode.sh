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
# The sub printRunStartArraysCapturesite is taken from plateScreen96.sh main script, and modified here.

function finish {

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! oneCapturesiteWholenode.sh for ${capturesiteFolderRelativePath} - check qsub.err to see why !"
echo "Dumped files in ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}_CRASHED"
echo

echo "$(pwd) before cleaning up : "
ls -lht

echo "TMPDIR ${capturesiteFolderRelativePath} before cleaning up : "
ls -lht ${TMPDIR}/${capturesiteFolderRelativePath}

mkdir ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}_CRASHED
mv -f ${TMPDIR}/${capturesiteFolderRelativePath} ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}_CRASHED/*

echo "TMPDIR after cleaning up"
ls -lht ${TMPDIR}

if [ ! -d ${wholenodeSubmitDir}/${capturesiteFolderRelativePath} ];then
mkdir ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}
fi
echo "runOK 0" > ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log

else

echo
date
printThis="oneCapturesiteWholenode.sh : Analysis complete for ${capturesiteFolderRelativePath} ! "
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

echo "oneCapturesiteWholenode.sh - by Jelena Telenius, 26/05/2018"
echo
timepoint=$( date )
echo "run started : ${timepoint}"
echo
echo "Script located at"
echo "$0"
echo

wholenodeSubmitDir=$(pwd)
echo "wholenodeSubmitDir ${wholenodeSubmitDir}"

echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "oneCapturesiteWholenode.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
capturesiteCounter=$1

printThis="capturesite_${capturesiteCounter} : Run CC analysis capturesite-wise (after F1 folder) .. "
printNewChapterToLogFile
  
    capturesiteFolderRelativePath=$(cat runlistings/capturesite${capturesiteCounter}.txt | head -n 1 | cut -f 1)
    submitdirSubfolderForDu=${wholenodeSubmitDir}/${capturesiteFolderRelativePath}
    echo "submitdirSubfolderForDu ${submitdirSubfolderForDu}"
    
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
    
    mkdir -p ${capturesiteFolderRelativePath}
    cp -r ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}/* ${capturesiteFolderRelativePath}
    mv ${wholenodeSubmitDir}/${capturesiteFolderRelativePath} ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}_beforeTMPDIR
    
    echo
    echo "Copied over the parameter files :"
    echo
    
    ls -lht
    
    echo "cd ${capturesiteFolderRelativePath}"
    cd ${capturesiteFolderRelativePath}
    
    ls -lht
    
    # ##########################################  

    echo "capture analysis started : $(date)"
    
    # Writing the queue environment variables to a log file :
    # ./echoer_for_SunGridEngine_environment.sh > ${wholenodeSubmitDir}/capturesite${capturesiteCounter}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
    ./echoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
    
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
      else
      {
      printThis='Deleting all folder D bam and wig files (gff files and bigwig files remain, along with the original bam file in folder C ) '
      printToLogFile
      
      echo "Total disk space Megas (before deleting) : " > bamWigSizesBeforeDeleting.log
      du -sm 2>> /dev/null | cut -f 1 >> bamWigSizesBeforeDeleting.log
      
      echo "Total disk space Megas of bam files (before deleting) : " >> bamWigSizesBeforeDeleting.log
      du -sm F[12345]*/*.bam 2>> /dev/null | cut -f 1 | tr '\n' '+' | sed 's/+$/\n/' | bc >> bamWigSizesBeforeDeleting.log
      rm -f F[12345]*/*.bam
      
      echo "Total disk space Megas of wig files (before deleting) : " >> bamWigSizesBeforeDeleting.log
      du -sm F[123456]*/*.wig 2>> /dev/null | cut -f 1 | tr '\n' '+' | sed 's/+$/\n/' | bc >> bamWigSizesBeforeDeleting.log
      rm -f F[123456]*/*.wig
      
      echo "Total disk space (after deleting) : " >> bamWigSizesBeforeDeleting.log
      du -sm 2>> /dev/null | cut -f 1 >> bamWigSizesBeforeDeleting.log  
      }  
      fi  
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > capturesiteRoundSuccess.log
    
  
    # ##########################################
    # HERE PARALLEL MOVE BACK TO REAL DIR !
    
    printThis="Moving back to real life - from TMPDIR ${TMPDIR}"
    printNewChapterToLogFile
    
    printThis="moving data from "${TMPDIR}" to "${wholenodeSubmitDir}
    printToLogFile
    
    ls -lR $(pwd) > TMPareaBeforeMovingBack.log

    mkdir ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}
    mv -f * ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}/.
    
    printThis="returning to "${wholenodeSubmitDir}/${capturesiteFolderRelativePath}
    printToLogFile
    
    cd ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}
    echo
    echo "Here we are :"
    echo
    pwd
    echo
    
    ls -lR $(pwd) > TMPareaAfterMovingBack.log
    
    cat TMPareaBeforeMovingBack.log  | sed 's/\s\s*/\t/g' | grep '^-' | cut -f 5,9 | sort -k2,2 -k1,1 | grep -v MovingBack > forDiff1.txt
    cat TMPareaAfterMovingBack.log   | sed 's/\s\s*/\t/g' | grep '^-' | cut -f 5,9 | sort -k2,2 -k1,1 | grep -v MovingBack > forDiff2.txt
    
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
        # rm -rf ${wholenodeSubmitDir}/${capturesiteFolderRelativePath}_beforeTMPDIR
    fi
    
    cd ${wholenodeSubmitDir}
    
    echo
    echo "Now all is clear - we can continue like we never went to TMPDIR ! "
    echo

    # ##########################################
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > ${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

