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

runMultitask(){
# ------------------------------------------
# 4) for each fastq in the list : start the qsubs for the main run, mainRunner.sh --parallel 1

printThis='READY TO SUBMIT JOBS AS REGULAR MULTITASK RUNS !'
printNewChapterToLogFile

printThis="You can follow the queue status of all the sub-jobs (waiting=qw, running=r) in file : \ncat  $(basename $(pwd))/allRunsJUSTNOW.txt"
printToLogFile

printThis="The run progress and memory usage can be monitored with files  $(basename $(pwd))/wholerunUsage_*.txt"
printToLogFile

printThis="Each job will write the output and error logs to files  $(basename $(pwd))/${CCversion}_$$_${fqOrOL}*.o* and  $(basename $(pwd))/${CCversion}_$$_${fqOrOL}*.e*"
printToLogFile

printThis="After the runs finish (or crash) all the above log files will be moved to  $(basename $(pwd))/qsubLogFiles"
printToLogFile

# foundFoldersCount=$(($(ls -1 | grep '^fastq_' | grep -c "")))
# We default to 8 processors, and are not planning to change this to become a flag instead ..
# askedProcessors=8
askedProcessors=2
neededQsubsCount=$(($((${foundFoldersCount}/${askedProcessors}))+1))

echo
echo "foundFoldersCount ${foundFoldersCount}"
echo "askedProcessors ${askedProcessors}"
echo
echo "Will submit ${neededQsubsCount} jobs to make that happen ! "
echo

qsubScriptToBeUsed='UNDEFINED_QSUB_SCRIPT'
# Override for bamcombining (never in TMPDIR)
if [ "${FastqOrOligo}" == "Bamcombine" ];then
    qsubScriptToBeUsed="oneThreadParallel${FastqOrOligo}WorkDir.sh"
else
# Normal run types
    if [ "${useTMPDIRforThis}" -eq 1 ];then
        qsubScriptToBeUsed="oneThreadParallel${FastqOrOligo}.sh"
        echo "Will use cluster memory TMPDIR to store all runtime files ! "
    else
        qsubScriptToBeUsed="oneThreadParallel${FastqOrOligo}WorkDir.sh"
        echo "Will use $(pwd) to store all runtime files ! "
    fi
fi


cp ${CaptureParallelPath}/${qsubScriptToBeUsed} .
chmod u+x ${qsubScriptToBeUsed}

thisIsFirstRound=1
firstfolderThisround=1
stillneedThismany=${foundFoldersCount}
for (( i=1; i<=${neededQsubsCount}; i++ ))
do {
    # If we are fine with these.
    if [ "${stillneedThismany}" -le "${askedProcessors}" ]; then
        if [ "${thisIsFirstRound}" -eq 1 ]; then
            # first round, and it is enough, submitting all
            printThis="Submitting runs 1-${stillneedThismany} \n in $(pwd) with command : "
            printToLogFile
            printThis="qsub -cwd -q batchq -t 1-${stillneedThismany} -N ${CCversion}_$$_${fqOrOL}${i} ./${qsubScriptToBeUsed}"
            printToLogFile
            printThis="RUNNING : runtime out/error logs are now readable in here :\ncat  $(basename $(pwd))/${CCversion}_$$_${fqOrOL}${i}.o*  \ncat  $(basename $(pwd))/${CCversion}_$$_${fqOrOL}${i}.e*"
            printToLogFile
            qsub -cwd -q batchq -t 1-${stillneedThismany} -N ${CCversion}_$$_${fqOrOL}${i} ./${qsubScriptToBeUsed}
            thisIsFirstRound=0
        else
            # not first round, but it is enough, submitting all, with hold_jid
            printThis="Submitting runs ${firstfolderThisround}-$((${firstfolderThisround}+${stillneedThismany}-1)) \n in $(pwd) with hold_jid as more runs than requested processors : "
            printToLogFile
            printThis="qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${stillneedThismany}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}"
            printToLogFile
            qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${stillneedThismany}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}
        fi
        break # this is enough now, exiting loop
    
    # If we need to do more ..
    else
        if [ "${thisIsFirstRound}" -eq 1 ]; then
            # first round, but it is not enough, submitting first batch
            printThis="Submitting runs 1-${askedProcessors} \n in $(pwd) with command : "
            printToLogFile
            printThis="qsub -cwd -q batchq -t 1-${askedProcessors} -N ${CCversion}_$$_${fqOrOL}${i} ./${qsubScriptToBeUsed}"
            printToLogFile
            qsub -cwd -q batchq -t 1-${askedProcessors} -N ${CCversion}_$$_${fqOrOL}${i} ./${qsubScriptToBeUsed}
            thisIsFirstRound=0
        else
            # not first round, and it is not enough, submitting a batch, with hold_jid
            printThis="Submitting runs ${firstfolderThisround}-$((${firstfolderThisround}+${askedProcessors}-1)) \n in $(pwd) with hold_jid as more runs than requested processors : "
            printToLogFile
            printThis="qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${askedProcessors}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}"
            printToLogFile
            qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${askedProcessors}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}
        fi        
        stillneedThismany=$((${stillneedThismany}-${askedProcessors}))
    fi
    
    # Sending different numbers in taskID..
    firstfolderThisround=$((${firstfolderThisround}+${askedProcessors}))
    
   }
   done
   
# Now - monitoring the little ones while they are running :)

# 1) we may be queueuing -  nothing running and no log files yet
# 2) we may be running - we have log files now

sleepSeconds=60
# Override for bamcombining and oligorounds (start more frequently than every 1 minutes)
if [ "${FastqOrOligo}" == "Bamcombine" ] || [ "${FastqOrOligo}" == "Oligo" ];then
    sleepSeconds=10
fi


echo
echo "Will be monitoring the runs in $(pwd)/allRunsJUSTNOW.txt "
echo "every ${sleepSeconds} seconds"
echo

while [ $(($( qstat | grep -c ${CCversion}_$$ ))) -gt 0 ]
do
{

monitorRun

qstat | grep ${CCversion}_$$ >> allRunsJUSTNOW.txt

# For testing purposes
qstat | grep ${CCversion}_$$ >> wholerunQstatMessages.txt

sleep ${sleepSeconds}
}
done

# Now everything is done, so cleaning up !

mkdir qsubLogFiles
mv ${CCversion}_$$_${fqOrOL}* qsubLogFiles/.
mv ${fastqOrOligo}*_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log qsubLogFiles/.
mv wholerun* qsubLogFiles/.
rm -f allRunsJUSTNOW.txt
rm -f runsJUSTNOW*.txt

echo > maxMemUsages.log
echo "Maximum cluster TMPDIR memory area usage (for any our qsubs) : " > maxMemUsages.log
cat qsubLogFiles/wholerunUsage_*.txt | cut -f 3 | grep M | sed 's/M//' \
| awk 'BEGIN{m=0}{if($1>m){m=$1}}END{print m}' | sed 's/$/M/' >> maxMemUsages.log
echo >> maxMemUsages.log
echo "Maximum work area t1-data memory usage (during our run) : " >> maxMemUsages.log
cat qsubLogFiles/wholerunUsage_*.txt | cut -f 2 | grep M | sed 's/M//' \
| awk 'BEGIN{m=0}{if($1>m){m=$1}}END{print m}' | sed 's/$/M/' >> maxMemUsages.log


echo > qsubLogFiles/a_README.txt
echo "All the logs have runtime data in intervals of ${sleepMinutes} minutes, i.e ${sleepSeconds} seconds, througout the whole run" >> qsubLogFiles/a_README.txt
echo "wholerunUsage columns : TASK localMem TMPDIRmem HH:MM" >> qsubLogFiles/a_README.txt
echo >> qsubLogFiles/a_README.txt

# Lastly we empty the TMPDIR

echo "Emptying TMPDIR .."
checkThis="${TMPDIR}"
checkedName='TMPDIR'
checkParse
rm -rf ${TMPDIR}/*

printThis="All ${fastqOrOligo} runs are finished (or crashed) ! "
printNewChapterToLogFile

printThis="Run log files available in : $(basename $(pwd))/qsubLogFiles"
printToLogFile
   
}


runWholenode(){
# ------------------------------------------
# 4) for each fastq in the list : start the qsubs for the main run, mainRunner.sh --parallel 1

printThis='READY TO SUBMIT JOBS IN WHOLENODE QUEUE !'
printNewChapterToLogFile

printThis="After the runs finish (or crash) all the above log files will be moved to  $(basename $(pwd))/qsubLogFiles"
printToLogFile


runScriptToBeUsed='UNDEFINED_RUN_SCRIPT'

# Override for bamcombining (never in TMPDIR)
if [ "${FastqOrOligo}" == "Bamcombine" ];then
    runScriptToBeUsed="one${FastqOrOligo}WholenodeWorkDir.sh"
else
# Normal run types
    if [ "${useTMPDIRforThis}" -eq 1 ];then
        runScriptToBeUsed="one${FastqOrOligo}Wholenode.sh"
        echo "Will use cluster memory TMPDIR to store all runtime files ! "
    else
        runScriptToBeUsed="one${FastqOrOligo}WholenodeWorkDir.sh"
        echo "Will use $(pwd) to store all runtime files ! "
    fi
fi

# memory in Megas - the whole node has this amount. Thou shalt not go over :D
wholenodemem=300000
wholenodesafetylimit=$((${wholenodemem}-80000))

# foundFoldersCount=$(($(ls -1 | grep '^fastq_' | grep -c "")))
# We default to 24 processors, and are not planning to change this to become a flag instead ..
askedProcessors=24
# askedProcessors=2
neededQsubsCount=$(($((${foundFoldersCount}/${askedProcessors}))+1))

echo
echo "foundFoldersCount ${foundFoldersCount}"
echo "askedProcessors ${askedProcessors}"
echo
echo "Will need to run ~ ${neededQsubsCount} times the whole node capasity ${askedProcessors} to satisfy this run ! "
echo

# -------------------

# sleepMinutes=30
sleepMinutes=1
sleepSeconds=$((${sleepMinutes}*60))
# sleepSeconds=10

echo
echo "Will be sleeping between starting each of the first 24 runs (to avoid i/o rush hour in downloading ${fastqOrOligo}s) .. "
echo "sleep time : ${sleepMinutes} minutes"
echo "i.e. ${sleepSeconds} seconds"
echo

echo
echo "Will be writing updates of the running jobs to here : "
echo "$(pwd)/allRunsJUSTNOW.txt"
echo


# ----------------------

# If we have upto 24, that's easy - just running them is fine !
if [ "${neededQsubsCount}" -eq 1 ]; then

for (( i=1; i<=${foundFoldersCount}; i++ ))
do {
   
    wePotentiallyStartNew=1
    checkIfDownloadsInProgress
    checkIfTooMuchMemUseAlready
    
    while [ ${wePotentiallyStartNew} -eq 0 ]
    do
    wePotentiallyStartNew=1
    checkIfDownloadsInProgress
    checkIfTooMuchMemUseAlready
    
    monitorRun
    sleep ${sleepSeconds}
    
    done
    
    # Log folder for other-than-fastq-runs to be the chr/oligo directory
    if [ "${FastqOrOligo}" == "Fastq" ];then
        erroutLogsToHere="."
    else
        erroutLogsToHere="runtimelogfiles/${i}"
        checkThis="${erroutLogsToHere}"
        checkedName='${erroutLogsToHere}'
        checkParse
        mkdir -p ${erroutLogsToHere}
    fi
    
    cp ${CaptureParallelPath}/${runScriptToBeUsed} ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh
    chmod u+x ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh
    echo "./run${FqOrOl}${i}_$$.sh ${i}  1> run${FqOrOl}${i}.out 2> run${FqOrOl}${i}.err"
    ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh ${i}  1> ${erroutLogsToHere}/run${FqOrOl}${i}.out 2> ${erroutLogsToHere}/run${FqOrOl}${i}.err &
    echo run${FqOrOl}${i}_$$.sh >> startedRunsList.log
    
    monitorRun
    sleep ${sleepSeconds}
    
    # for testing purposes
    echo ${allOfTheRunningOnes} >> processNumbersRunning.log
    ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> processNumbersRunning.log
    echo "That is ${i} running just now" >> processNumbersRunning.log
    echo >> processNumbersRunning.log
    
}
done

else
# The first 24 are easy - just running them is fine !
# after that we need to monitor ..

allOfTheRunningOnes=""
for (( i=1; i<=${askedProcessors}; i++ ))
do {
    
    wePotentiallyStartNew=1
    checkIfDownloadsInProgress
    checkIfTooMuchMemUseAlready
    
    while [ ${wePotentiallyStartNew} -eq 0 ]
    do
    wePotentiallyStartNew=1
    checkIfDownloadsInProgress
    checkIfTooMuchMemUseAlready
    
    monitorRun
    sleep ${sleepSeconds}
    
    done

    # Log folder for other-than-fastq-runs to be the chr/oligo directory
    if [ "${FastqOrOligo}" == "Fastq" ];then
        erroutLogsToHere="."
    else
        erroutLogsToHere="runtimelogfiles/${i}"
        checkThis="${erroutLogsToHere}"
        checkedName='${erroutLogsToHere}'
        checkParse
        mkdir -p ${erroutLogsToHere}
    fi
    
    cp ${CaptureParallelPath}/${runScriptToBeUsed} ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh
    chmod u+x ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh
    echo "./run${FqOrOl}${i}_$$.sh ${i}  1> run${FqOrOl}${i}.out 2> run${FqOrOl}${i}.err"
    ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh ${i}  1> ${erroutLogsToHere}/run${FqOrOl}${i}.out 2> ${erroutLogsToHere}/run${FqOrOl}${i}.err &
    allOfTheRunningOnes="${allOfTheRunningOnes} $!"
    echo run${FqOrOl}${i}_$$.sh >> startedRunsList.log
    
    monitorRun 
    sleep ${sleepSeconds}
    
    # for testing purposes
    echo ${allOfTheRunningOnes} >> processNumbersRunning.log
    ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> processNumbersRunning.log
    echo "That is ${i} runs started so far" >> processNumbersRunning.log
    echo >> processNumbersRunning.log

}
done

# Now monitoring ..

echo
echo "Will be monitoring the runs - and if previous ones have ended, submitting new ones .. "
echo "every ${sleepMinutes} minutes"
echo "i.e. every ${sleepSeconds} seconds"
echo

weStillNeedThisMany=$((${foundFoldersCount}-${askedProcessors}))
# This was confusing as inconsistent with above where the looper is ${i}
# currentFastqNumber=$((${askedProcessors}+1))
i=$((${askedProcessors}+1))
while [ "${weStillNeedThisMany}" -gt 0 ]
do
{

countOfThemRunningJustNow=$(($( ps h -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))

checkThis="${countOfThemRunningJustNow}"
checkedName='${countOfThemRunningJustNow}'
checkParse

if [ "${countOfThemRunningJustNow}" -lt "${askedProcessors}" ]; then
    
    wePotentiallyStartNew=1
    checkIfDownloadsInProgress
    checkIfTooMuchMemUseAlready

    if [ "${wePotentiallyStartNew}" == 1 ];then
  
    # Log folder for other-than-fastq-runs to be the chr/oligo directory
    if [ "${FastqOrOligo}" == "Fastq" ];then
        erroutLogsToHere="."
    else
        erroutLogsToHere="runtimelogfiles/${i}"
        checkThis="${erroutLogsToHere}"
        checkedName='${erroutLogsToHere}'
        checkParse
        mkdir -p ${erroutLogsToHere}
    fi
    
    cp ${CaptureParallelPath}/${runScriptToBeUsed} ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh
    chmod u+x ${erroutLogsToHere}/${FqOrOl}${i}_$$.sh
    echo "./run${FqOrOl}${i}_$$.sh ${i}  1> run${FqOrOl}${i}.out 2> run${FqOrOl}${i}.err"
    ${erroutLogsToHere}/run${FqOrOl}${i}_$$.sh ${i}  1> ${erroutLogsToHere}/run${FqOrOl}${i}.out 2> ${erroutLogsToHere}/run${FqOrOl}${i}.err &
    allOfTheRunningOnes="${allOfTheRunningOnes} $!"
    echo run${FqOrOl}${i}_$$.sh >> startedRunsList.log
    
    weStillNeedThisMany=$((${weStillNeedThisMany}-1))
    # This was confusing as inconsistent with above where the looper is ${i}
    # currentFastqNumber=$((${currentFastqNumber}+1))
    i=$((${i}+1))
    
    # for testing purposes
    echo ${allOfTheRunningOnes} >> processNumbersRunning.log
    ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> processNumbersRunning.log
    echo "That is "$( ${allOfTheRunningOnes} | tr ' ' '\n' | grep -c "")" runs started, ${countOfThemRunningJustNow} running just now, and we still need to start ${weStillNeedThisMany} runs" >> processNumbersRunning.log
    echo >> processNumbersRunning.log
    
    fi    
    
fi

monitorRun

sleep ${sleepSeconds}

}
done

    
fi

# --------------------------------------

# Now monitoring until the jobs have ended ..


countOfThemRunningJustNow=$(($( ps h -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))
checkThis="${countOfThemRunningJustNow}"
checkedName='${countOfThemRunningJustNow}'
checkParse

# This while seems to be leaking a little - maybe the output files still get written after
# the process id is vanished
# or I simply parse the id wrongly ?

echo '----------------------------'
echo "Into while monitored with ps h -p"
date
echo '----------------------------'

while [ "${countOfThemRunningJustNow}" -gt 0 ]
do
{

monitorRun

sleep ${sleepSeconds}
countOfThemRunningJustNow=$(($( ps h -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))
checkThis="${countOfThemRunningJustNow}"
checkedName='${countOfThemRunningJustNow}'
checkParse

}
done

echo '----------------------------'
echo 'Out of while monitored with ps h -p'
date
echo '----------------------------'

# for testing purposes
echo ${allOfTheRunningOnes} >> processNumbersRunning.log
ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> processNumbersRunning.log
echo "That is ${countOfThemRunningJustNow} running just now - out of WHILE monitored with ps $(date)" >> processNumbersRunning.log
echo >> processNumbersRunning.log

# As the above seems leaking, adding extra wait here ..
# (hoping wait attacks also background processes, and defaults to the user's processes ..)
# Bash manual states :
# by default :
# all currently active child processes are waited for

wait

# explicitely the same should be :
# wait ${allOfTheRunningOnes}

echo '----------------------------'
echo "Out of WAIT -now we actually exited all processes .."
date
echo '----------------------------'

# for testing purposes
echo ${allOfTheRunningOnes} >> processNumbersRunning.log
ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> processNumbersRunning.log
echo "That is ${countOfThemRunningJustNow} running just now - out of WAIT all processes at $(date)" >> processNumbersRunning.log
echo >> processNumbersRunning.log

# Now everything is done, so cleaning up !

mkdir qsubLogFiles

if [ "${erroutLogsToHere}" == '.' ]; then

mkdir runscripts
mv run*.sh runscripts/.

mv run${FqOrOl}*.out qsubLogFiles/.
mv run${FqOrOl}*.err qsubLogFiles/.

mv ${fastqOrOligo}*_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log qsubLogFiles/.

fi

mv processNumbersRunning.log qsubLogFiles/.

echo > maxMemUsages.log
echo "Maximum cluster TMPDIR memory area usage (during our run) : " > maxMemUsages.log
cat qsubLogFiles/run${FqOrOl}*.out | grep -A 1 'cluster temp area usage' | grep -v '^TMPDIR' | sed 's/\s\s*/\t/' | cut -f 1 | grep '[MG]$' | sed 's/M/\tM/' | sed 's/G/\tG/' \
| awk 'BEGIN{m=0;g=0}{if($1>m && $2=="M"){m=$1}if($1>g && $2=="G"){g=$1}}END{if(g==0){print m"M"}else{print g"G"}}' >> maxMemUsages.log
echo >> maxMemUsages.log
echo "Maximum work area t1-data memory usage (during our run) : " >> maxMemUsages.log
cat qsubLogFiles/run${FqOrOl}*.out | grep -A 1 'Local disk usage"' | grep -v '^Local' | sed 's/\s\s*/\t/' | cut -f 1 | grep '[MG]$' | sed 's/M/\tM/' | sed 's/G/\tG/' \
| awk 'BEGIN{m=0;g=0}{if($1>m && $2=="M"){m=$1}if($1>g && $2=="G"){g=$1}}END{if(g==0){print m"M"}else{print g"G"}}' >> maxMemUsages.log

rm -f runsJUSTNOW.txt
mv wholerun* qsubLogFiles/.

echo > maxMemUsages.log
echo "Maximum cluster TMPDIR memory area usage (for any our qsubs) : " > maxMemUsages.log
cat qsubLogFiles/wholerunUsage_*.txt | cut -f 3 | grep M | sed 's/M//' \
| awk 'BEGIN{m=0}{if($1>m){m=$1}}END{print m}' | sed 's/$/M/' >> maxMemUsages.log
echo >> maxMemUsages.log
echo "Maximum work area t1-data memory usage (during our run) : " >> maxMemUsages.log
cat qsubLogFiles/wholerunUsage_*.txt | cut -f 2 | grep M | sed 's/M//' \
| awk 'BEGIN{m=0}{if($1>m){m=$1}}END{print m}' | sed 's/$/M/' >> maxMemUsages.log

echo > qsubLogFiles/a_README.txt
echo "All the logs have runtime data in intervals of ${sleepMinutes} minutes, i.e ${sleepSeconds} seconds, througout the whole run" >> qsubLogFiles/a_README.txt
echo >> qsubLogFiles/a_README.txt

# Lastly we empty the TMPDIR

echo "Emptying TMPDIR .."
checkThis="${TMPDIR}"
checkedName='TMPDIR'
checkParse
rm -rf ${TMPDIR}/*

printThis="All ${fastqOrOligo} runs are finished (or crashed) ! "
printNewChapterToLogFile

printThis="Run log files available in : $(basename $(pwd))/qsubLogFiles"
printToLogFile


# ---------------------------
   
}



checkIfTooMuchMemUseAlready(){
# If we are already quite high in memory usage - we can not start a new one ..


if [ "${useTMPDIRforThis}" -eq 1 ];then

weUseThisManyMegas=0
if [ "${useWholenodeQueue}" -eq 1 ]; then
    weUseThisManyMegas=$(($( du -sm ${TMPDIR} 2>> /dev/null | cut -f 1 )))
else
    if [ -s runJustNow_${m}.log.tmpdir ];then
        tempareaMemoryUsage=$( cat runJustNow_${m}.log.tmpdir )
    else
        tempareaMemoryUsage=0
    fi
fi

if [ "${weUseThisManyMegas}" -gt "${wholenodesafetylimit}" ];then

    echo >> allRunsJUSTNOW.txt
    echo "We currently use ${weUseThisManyMegas}M memory in TMPDIR ," >> allRunsJUSTNOW.txt
    echo " and as the safe usage upper limit is ${wholenodesafetylimit}M," >> allRunsJUSTNOW.txt
    echo " we need to wait until the load comes down, before starting new ones .." >> allRunsJUSTNOW.txt
    
    wePotentiallyStartNew=0
    
    date >> highMemoryTimelog.txt
    echo "We currently use ${weUseThisManyMegas}M memory in TMPDIR ," >> highMemoryTimelog.txt
    
    
fi

fi
}


checkIfDownloadsInProgress(){
# If we have downloads in progress - we can not start a new one .. 
if [ $(($( ls | grep ${fastqOrOligo}*_download_inProgress.log | grep -c "" ))) -ne 0 ]; then
    echo >> allRunsJUSTNOW.txt
    echo "Downloads in progress for runs : " >> allRunsJUSTNOW.txt
    ls | grep ${fastqOrOligo}*_download_inProgress.log | sed 's/_download_inProgress.log//' >> allRunsJUSTNOW.txt
    echo "Will wait until download finished, before starting new ones .." >> allRunsJUSTNOW.txt
    
    wePotentiallyStartNew=0
    
    date >> downloadIOlimitedLog.txt
    echo "Downloads in progress for runs : " >> downloadIOlimitedLog.txt
    ls | grep ${fastqOrOligo}*_download_inProgress.log | sed 's/_download_inProgress.log//' >> downloadIOlimitedLog.txt
    
fi  
}

monitorRun(){
    
#_____________________
# For testing purposes

# free -m
# df -m 
# du -m 
# ps T

#_____________________

date > runsJUSTNOW.txt

for (( m=1; m<=${foundFoldersCount}; m++ ))
do {

# Memory as well
localMemoryUsage=$( du -sm ${wholenodeSubmitDir} 2>> /dev/null | cut -f 1 )
timepoint=$(date +%H:%M)

# Override for bamcombining (never in TMPDIR)
if [ "${FastqOrOligo}" == "Bamcombine" ];then
    tempareaMemoryUsage=0
else

    if [ "${useTMPDIRforThis}" -eq 1 ];then
        if [ "${useWholenodeQueue}" -eq 1 ]; then
        tempareaMemoryUsage=$( du -sm ${TMPDIR} 2>> /dev/null | cut -f 1 )
        else
            if [ -s runJustNow_${m}.log.tmpdir ];then
            tempareaMemoryUsage=$( cat runJustNow_${m}.log.tmpdir )
            else
            tempareaMemoryUsage="NO_TEMP_FILE_TO_READ 0"
            fi
        fi
    else
    tempareaMemoryUsage=0    
    fi

fi

if [ -s runJustNow_${m}.log ];then

usageMessage="runNo ${m} $(cat runJustNow_${m}.log) localmem ${localMemoryUsage}M TEMPDIRmem ${tempareaMemoryUsage}M ${timepoint}"
echo ${usageMessage} >> runsJUSTNOW.txt
usageMessage="$(cat runJustNow_${m}.log) ${localMemoryUsage}M ${tempareaMemoryUsage}M ${timepoint}"
echo ${usageMessage} | sed 's/\s/\t/g' >> wholerunUsage_${m}.txt

fi

}
done


}
