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
echo "RUN CRASHED ! oneBamcombineWholenodeWorkDir.sh for ${oligoFolderRelativePath} - check qsub.err to see why !"
echo "Dumped files in ${wholenodeSubmitDir}/${oligoFolderRelativePath}_CRASHED"
echo

echo "runOK 0" > ${wholenodeSubmitDir}/${oligoFolderRelativePath}/oligoRoundSuccess.log

else

echo
date
printThis="oneBamcombineWholenodeWorkDir.sh : Analysis complete for ${oligoFolderRelativePath} ! "
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

doQuotaTesting(){
        
    echo
    echo "Local disk usage for THIS RUN - at the moment (check you don't go over your t1-data area quota) :"
    du -sh ${wholenodeSubmitDir}
    echo "TMPDIR cluster temp area usage - check you don't go too near to 300GB :"
    du -sh ${TMPDIR}

#_____________________
# For testing purposes

# echo $0

# free -m
# df -m 
# du -m 
# ps T

#_____________________
    
    
    
}

# -----------------------------------------

# Normal runs (not only help request) starts here ..

echo "oneBamcombineWholenodeWorkDir.sh - by Jelena Telenius, 26/05/2018"
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
echo "oneBamcombineWholenodeWorkDir.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
oligoCounter=$1
echo "bamCombine" > runJustNow_${oligoCounter}.log

   
printThis="oligo_${oligoCounter} : Combining BAM files of all fastqs .. "
printNewChapterToLogFile
  
    oligoFolderRelativePath=$(cat runlistings/oligo${oligoCounter}.txt | head -n 1 | cut -f 1)

    cd ${oligoFolderRelativePath}        
    pwd
    echo

    echo "bam combining started : $(date)"
      
    # Writing the queue environment variables to a log file :
    # ./echoer_for_SunGridEngine_environment.sh > ${wholenodeSubmitDir}/bamcombine${oligoCounter}_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
    ./echoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log
        
      fCount=0
      nfCount=0
      runOK=1
      ./bamCombineRun.sh
      if [ $? != 0 ] || [ -s samtoolsCat.err ]; then
      {
        runOK=0    

        printThis="Bam-combining failed on line ${oligoCounter} of C_analyseOligoBunches/runlist.txt ! "
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
        
        printThis="Bam-combining generated truncated files on line ${oligoCounter} of C_analyseOligoBunches/runlist.txt ! "
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
    
    doQuotaTesting
    
    printThis="FLASHEDin ${finCount} FLASHEDout ${finCount} NONFLASHEDin ${nfinCount} NONFLASHEDout ${nfoutCount} runOK ${runOK}"
    printToLogFile
    echo "FLASHEDin ${finCount} FLASHEDout ${finCount} NONFLASHEDin ${nfinCount} NONFLASHEDout ${nfoutCount} runOK ${runOK}" > bamcombineSuccess.log
    
    
# ----------------------------------------
# All done !

cd ${wholenodeSubmitDir}

rm -f runJustNow_${oligoCounter}.log

exit 0

