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


# The subs below are copied from plate96screen codes VS03
# Copied as they were 16Feb2018, from the file inputFastqs.sh

concludeFastqInspection(){
  
    echo
    echo "origR1Count ${origR1Count}"
    echo "origR2Count ${origR2Count}"
    echo "newR1Count  ${newR1Count}"
    echo "newR2Count  ${newR2Count}"
    echo
    
    if [ "${origR1Count}" -ne "${newR1Count}" ];then
        printThis="R1 Fastq file got corrupted in the process !"
        printToLogFile
        printThis="Exiting !"
        printToLogFile
        prepareOK=0
    fi
    
    if [ "${SINGLE_END}" -eq 0 ] ; then
    if [ "${origR2Count}" -ne "${newR2Count}" ];then
        printThis="R2 Fastq file got corrupted in the process !"
        printToLogFile
        printThis="Exiting !"
        printToLogFile
        prepareOK=0
    fi
    fi  
    
}

inspectFastq(){
    
    printThis="Inspecting fetched fastq files  ..."
    printToLogFile
    
    echo "Counting lines in R1 (original file) ${fileList1[$i]}.."
    origR1Count=0
    if [ "${GZIP}" -eq 0 ] ; then
    origR1Count=$(($( cat ${fileList1[$i]} | grep -Pv "^$" | grep -c "" )))
    else
    origR1Count=$(($( zcat ${fileList1[$i]} | grep -Pv "^$" | grep -c "" )))    
    fi
    echo "Found ${origR1Count} lines."    

    if [ "${SINGLE_END}" -eq 0 ] ; then
    
    echo "Counting lines in R2 (original file) ${fileList2[$i]}.."
    origR2Count=0
    if [ "${GZIP}" -eq 0 ] ; then
    origR2Count=$(($( cat ${fileList2[$i]} | grep -Pv "^$" | grep -c "" )))
    else
    origR2Count=$(($( zcat ${fileList2[$i]} | grep -Pv "^$" | grep -c "" )))
    fi
    echo "Found ${origR2Count} lines."
    
    fi

    echo
    echo "Counting lines in fetched R1 (fetched, possibly unzipped file) .."
    newR1Count=0
    newR1Count=$(($( cat READ1.fastq | grep -c "" )))    
    echo "Found ${newR1Count} lines."    

    if [ "${SINGLE_END}" -eq 0 ] ; then
    echo "Counting lines in R2 (fetched, possibly unzipped file) .."
    newR2Count=$(($( cat READ2.fastq | grep -c "" )))
    echo "Found ${newR2Count} lines."
    
    fi

    concludeFastqInspection


}

inspectFastqMultilane(){
    
    #folderList=($( cut -f 1 ./PIPE_fastqPaths.txt ))
    #fileList1=($( cut -f 2 ./PIPE_fastqPaths.txt ))
    #fileList2=($( cut -f 3 ./PIPE_fastqPaths.txt ))
    
    printThis="Inspecting fetched fastq files (we have $LANES lanes)..."
    printToLogFile
   

    # One lane at a time.. 
    allLanes=${fileList1[$i]}

    echo "Counting lines in R1 (original file) ${fileList1[$i]} .."
    origR1Count=0
    for l in $( seq 1 ${LANES[@]} ); do
        echo "Lane no $l .."
        
        if [ "${GZIP}" -eq 0 ] ; then
           tempCount=$(($( cat ${fileList1[$i]} | grep -Pv "^$" | grep -c "" )))
           origR1Count=$((${origR1Count}+${tempCount}))
        else
           tempCount=$(($( zcat ${fileList1[$i]} | grep -Pv "^$" | grep -c "" )))
           origR1Count=$((${origR1Count}+${tempCount}))
        fi
        
        # Saving rest and looping to next round..
        removeThis=$( echo ${currentLane} | sed 's/\//\\\//g' )
        restOfLanes=$( echo ${allLanes} | sed s'/'${removeThis}',//' )
        echo "Rest of lanes (still to be counted) : ${restOfLanes}"
        allLanes=${restOfLanes}  
    done
    
    if [ "${SINGLE_END}" -eq 0 ] ; then
    
    # One lane at a time.. 
    allLanes=${fileList2[$i]}

    echo ""
    echo "Counting lines in R2 (original file) ${fileList2[$i]}.."
    origR2Count=0
    for l in $( seq 1 ${LANES[@]} ); do
        echo "Lane no $l .."
        
        if [ "${GZIP}" -eq 0 ] ; then
           tempCount=$(($( cat ${fileList2[$i]} | grep -Pv "^$" | grep -c "" )))
           origR2Count=$((${origR2Count}+${tempCount}))
        else
           tempCount=$(($( zcat ${fileList2[$i]} | grep -Pv "^$" | grep -c "" )))
           origR2Count=$((${origR2Count}+${tempCount}))
        fi
        
        # Saving rest and looping to next round..
        removeThis=$( echo ${currentLane} | sed 's/\//\\\//g' )
        restOfLanes=$( echo ${allLanes} | sed s'/'${removeThis}',//' )
        echo "Rest of lanes (still to be counted) : ${restOfLanes}"
        allLanes=${restOfLanes}  
    done
    
    fi
    
    echo
    echo "Counting lines in R1 (fetched, possibly unzipped file) .."
    newR1Count=0
    newR1Count=$(($( cat READ1.fastq | grep -c "" )))    
    echo "Found ${newR1Count} lines."    

    if [ "${SINGLE_END}" -eq 0 ] ; then
    echo "Counting lines in R2 ((fetched, possibly unzipped file) .."
    newR2Count=$(($( cat READ2.fastq | grep -c "" )))
    echo "Found ${newR2Count} lines."
    fi
        
    concludeFastqInspection
    
}



fetchFastq(){
    
echo "Loading fastqs started at :" > ${thisFastqDownloadLogBasename}_inProgress.log
date >> ${thisFastqDownloadLogBasename}_inProgress.log
    
    printThis="Fetching fastq files  ..."
    printToLogFile

    printThis="${fileList1[$i]}"
    printToLogFile
    
    if [ "${GZIP}" -eq 0 ] ; then
        
    cp "${fileList1[$i]}" ./READ1.fastq
    testedFile="READ1.fastq"
    doTempFileTesting
    
    else
    cp "${fileList1[$i]}" ./READ1.fastq.gz
    testedFile="READ1.fastq.gz"
    doTempFileTesting
    
    fi
    
    if [ "${SINGLE_END}" -eq 0 ] ; then
        
    printThis="${fileList2[$i]}"
    printToLogFile
    
    if [ "${GZIP}" -eq 0 ] ; then
        
    cp "${fileList2[$i]}" ./READ2.fastq
    testedFile="READ2.fastq"
    doTempFileTesting
    
    else
    cp "${fileList2[$i]}" ./READ2.fastq.gz
    testedFile="READ2.fastq.gz"
    doTempFileTesting    
    fi
    
    
    fi

echo "Loading fastqs finished at at :" >> ${thisFastqDownloadLogBasename}_inProgress.log
date >> ${thisFastqDownloadLogBasename}_inProgress.log
    
mv -f ${thisFastqDownloadLogBasename}_inProgress.log ${thisFastqDownloadLogBasename}_finished.log
mv -f ${thisFastqDownloadLogBasename}_finished.log .
    
   # -------
   # unpacking ..

    
    if [ "${GZIP}" -eq 1 ] ; then    
   
    printThis="${fileList1[$i]} - unpacking"
    printToLogFile

    gzip -d READ1.fastq.gz
    
    testedFile="READ1.fastq"
    doTempFileTesting
   
    if [ "${SINGLE_END}" -eq 0 ] ; then
    
    printThis="${fileList2[$i]} - unpacking"
    printToLogFile

    gzip -d READ2.fastq.gz
    
    testedFile="READ2.fastq"
    doTempFileTesting

    fi
    
    fi
    
    
    echo "Fetched fastqs :"
    ls -lh | grep fastq | cut -d " " -f 1,2,3,4 --complement
    
}

fetchFastqMultilane(){
    
echo "Loading fastqs started at :" > ${thisFastqDownloadLogBasename}_inProgress.log
date >> ${thisFastqDownloadLogBasename}_inProgress.log
    
    #folderList=($( cut -f 1 ./PIPE_fastqPaths.txt ))
    #fileList1=($( cut -f 2 ./PIPE_fastqPaths.txt ))
    #fileList2=($( cut -f 3 ./PIPE_fastqPaths.txt ))
    
    printThis="Fetching fastq files (we have $LANES lanes)..."
    printToLogFile

    echo "Read1 - generating combined fastq.."
    printThis="${fileList1[$i]}"
    printToLogFile
    

    # One lane at a time.. catenating files !
    rm -f ./READ1.fastq 
    allLanes=${fileList1[$i]}

    for l in $( seq 1 ${LANES[@]} ); do
        echo ""
        echo "Lane no $l .."
        currentLane=$( echo ${allLanes} | sed s'/,.*$//' )
        echo "Current lane : ${currentLane}"
        
        if [ "${GZIP}" -eq 0 ] ; then
           cat "${currentLane}" >> ./READ1.fastq
        else
           cp "${currentLane}" ./TEMP.fastq.gz
           gzip -d TEMP.fastq.gz 
           cat TEMP.fastq >> ./READ1.fastq
           rm -f TEMP.fastq*
        fi
        
        # Saving rest and looping to next round..
        removeThis=$( echo ${currentLane} | sed 's/\//\\\//g' )
        restOfLanes=$( echo ${allLanes} | sed s'/'${removeThis}',//' )
        echo "Rest of lanes (still to be added to the file) : ${restOfLanes}"
        allLanes=${restOfLanes}  
    done
    # Removing empty lines
    grep -Pv "^$" READ1.fastq >  temp.fastq
    mv -f temp.fastq READ1.fastq
    
    testedFile="READ1.fastq"
    doTempFileTesting
    
    if [ "${SINGLE_END}" -eq 0 ] ; then
    
    echo ""
    echo "Read2 - generating combined fastq.."
    printThis="${fileList2[$i]}"
    printToLogFile

    rm -f ./READ2.fastq 
    allLanes=${fileList2[$i]}
    for l in $( seq 1 ${LANES[@]} ); do
        echo ""
        echo "Lane no $l .."
        currentLane=$( echo ${allLanes} | sed s'/,.*$//' )
        echo "Current lane : ${currentLane}"
        
        if [ "${GZIP}" -eq 0 ] ; then
           cat "${currentLane}" >> ./READ2.fastq
        else
           cp "${currentLane}" ./TEMP.fastq.gz
           gzip -d TEMP.fastq.gz
           cat TEMP.fastq >> ./READ2.fastq
           rm -f TEMP.fastq*
        fi
        
        # Saving rest and looping to next round..
        removeThis=$( echo ${currentLane} | sed 's/\//\\\//g' )
        restOfLanes=$( echo ${allLanes} | sed s'/'${removeThis}',//' )
        echo "Rest of lanes (still to be added to the file) : ${restOfLanes}"
        allLanes=${restOfLanes}   
    done
    # Removing empty lines
    grep -Pv "^$" READ2.fastq >  temp.fastq
    mv -f temp.fastq READ2.fastq
    
    testedFile="READ2.fastq"
    doTempFileTesting
    
    fi

    echo "Generated merged fastqs :"
    ls -lh | grep fastq | cut -d " " -f 1,2,3,4 --complement

echo "Loading fastqs finished at at :" >> ${thisFastqDownloadLogBasename}_inProgress.log
date >> ${thisFastqDownloadLogBasename}_inProgress.log
    
mv -f ${thisFastqDownloadLogBasename}_inProgress.log ${thisFastqDownloadLogBasename}_finished.log
mv -f ${thisFastqDownloadLogBasename}_finished.log .
    
}
