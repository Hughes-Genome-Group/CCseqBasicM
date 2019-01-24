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
askedProcessors=${threadCount}
neededQsubsCount=$(($((${foundFoldersCount}/${askedProcessors}))+1))

echo
echo "foundFoldersCount ${foundFoldersCount}"
echo "askedProcessors ${askedProcessors}"
echo
echo "Will submit ${neededQsubsCount} jobs to make that happen ! "
echo

qsubScriptToBeUsed='UNDEFINED_QSUB_SCRIPT'
# Override for bamcombining (never in TMPDIR)
if [ "${FastqOrCapturesite}" == "Bamcombine" ];then
    qsubScriptToBeUsed="oneThreadParallel${FastqOrCapturesite}WorkDir.sh"
else
# Normal run types
    if [ "${useTMPDIRforThis}" -eq 1 ];then
        qsubScriptToBeUsed="oneThreadParallel${FastqOrCapturesite}.sh"
        echo "Will use cluster memory TMPDIR to store all runtime files ! "
    else
        qsubScriptToBeUsed="oneThreadParallel${FastqOrCapturesite}WorkDir.sh"
        echo "Will use $(pwd) to store all runtime files ! "
    fi
fi


cp ${CaptureParallelPath}/${qsubScriptToBeUsed} .
chmod u+x ${qsubScriptToBeUsed}

# First five parallel units we put in without hesitation :

thisIsFirstRound=1
firstfolderThisround=1
stillneedThismany=${foundFoldersCount}

# five or all ?
fiveFirstRounds=${neededQsubsCount}
if [ ${neededQsubsCount} -gt "5" ]; then
    fiveFirstRounds=5
fi
    
for (( i=1; i<=${fiveFirstRounds}; i++ ))
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
   
# After the first five parallel units we want to keep nice image - not to crowd the visual of the queue with endless hqw jobs :

sleepSeconds=600
# Override for bamcombining and capturesiterounds (start more frequently than every 10 minutes)
if [ "${FastqOrCapturesite}" == "Bamcombine" ];then
    sleepSeconds=1
elif [ "${FastqOrCapturesite}" == "Capturesite" ];then
    sleepSeconds=10
fi

if [ ${neededQsubsCount} -gt "5" ]; then
    
printThis="After the first five parallel units submit, submitting once the previous runs have advanced."
printToLogFile
printThis="Starting this with parameter values : neededQsubsCount=${neededQsubsCount}  firstfolderThisround=${firstfolderThisround}  stillneedThismany=${stillneedThismany} "
printToLogFile

for (( i=6; i<=${neededQsubsCount}; i++ ))
do {
    
    wePotentiallyStartNew=1
    # qstat shows first 10 letters of the job name - parsing for this :
    weAreLookingForThis=$( echo ${CCversion}_$$_${fqOrOL} | awk '{print substr($1,1,10)}' )
    
    if [ $(($( qstat | sed 's/\s\s*/\t/g' | cut -f 3,5 | grep -c '^'${weAreLookingForThis}'\shqw$' ))) -ge 5 ]; then
        wePotentiallyStartNew=0
    fi
    
    while [ ${wePotentiallyStartNew} -eq 0 ]
    do
        wePotentiallyStartNew=1
        if [ $(($( qstat | sed 's/\s\s*/\t/g' | cut -f 3,5 | grep -c '^'${weAreLookingForThis}'\shqw$' ))) -ge 5 ]; then
            wePotentiallyStartNew=0
        fi
        sleep ${sleepSeconds}
    done
    
    # If we are fine with these.
    if [ "${stillneedThismany}" -le "${askedProcessors}" ]; then
        # not first round, but it is enough, submitting all, with hold_jid
        printThis="Submitting runs ${firstfolderThisround}-$((${firstfolderThisround}+${stillneedThismany}-1)) \n in $(pwd) with hold_jid as more runs than requested processors : "
        printToLogFile
        printThis="qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${stillneedThismany}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}"
        printToLogFile
        qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${stillneedThismany}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}
        break # this is enough now, exiting loop
    
    # If we need to do more ..
    else
        # not first round, and it is not enough, submitting a batch, with hold_jid
        printThis="Submitting runs ${firstfolderThisround}-$((${firstfolderThisround}+${askedProcessors}-1)) \n in $(pwd) with hold_jid as more runs than requested processors : "
        printToLogFile
        printThis="qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${askedProcessors}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}"
        printToLogFile
        qsub -cwd -q batchq -t ${firstfolderThisround}-$((${firstfolderThisround}+${askedProcessors}-1)) -N ${CCversion}_$$_${fqOrOL}${i} -hold_jid ${CCversion}_$$_${fqOrOL}$((${i}-1)) ./${qsubScriptToBeUsed}       
        stillneedThismany=$((${stillneedThismany}-${askedProcessors}))
    fi
    
    # Sending different numbers in taskID..
    firstfolderThisround=$((${firstfolderThisround}+${askedProcessors}))
    
   }
   done

fi
   
# Now - monitoring the little ones while they are running :)

# 1) we may be queueuing -  nothing running and no log files yet
# 2) we may be running - we have log files now

sleepSeconds=60

echo
echo "Will be monitoring the runs in $(pwd)/allRunsJUSTNOW.txt "
echo "every ${sleepSeconds} seconds"
echo

weAreLookingForThis=$( echo ${CCversion}_$$_${fqOrOL} | awk '{print substr($1,1,10)}' )

while [ $(($( qstat | sed 's/\s\s*/\t/g' | cut -f 3 | grep -c '^'${weAreLookingForThis}'$' ))) -gt 0 ]
do
{

monitorRun

# For threaded jobs ..
qstat | grep ${weAreLookingForThis} >> allRunsJUSTNOW.txt

# For testing purposes (threaded jobs)
qstat | grep ${weAreLookingForThis} >> wholerunQstatMessages.txt

sleep ${sleepSeconds}
}
done

# Now everything is done, so cleaning up !

mkdir qsubLogFiles
mv ${CCversion}_$$_${fqOrOL}* qsubLogFiles/.
mv ${fastqOrCapturesite}*_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log qsubLogFiles/.
mv wholerun* qsubLogFiles/.
mv -f allRunsJUSTNOW.txt qsubLogFiles/allRunsRUNTIME.log
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

printThis="All ${fastqOrCapturesite} runs are finished (or crashed) ! "
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
if [ "${FastqOrCapturesite}" == "Bamcombine" ];then
    runScriptToBeUsed="one${FastqOrCapturesite}WholenodeWorkDir.sh"
else
# Normal run types
    if [ "${useTMPDIRforThis}" -eq 1 ];then
        runScriptToBeUsed="one${FastqOrCapturesite}Wholenode.sh"
        echo "Will use cluster memory TMPDIR to store all runtime files ! "
    else
        runScriptToBeUsed="one${FastqOrCapturesite}WholenodeWorkDir.sh"
        echo "Will use $(pwd) to store all runtime files ! "
    fi
fi

# TMP area memory in Megas - the whole node has this amount. Thou shalt not go over :D
wholenodeDisk=300000
wholenodesafetylimitDisk=$((${wholenodeDisk}-80000))

# wholenode RAM memory in Megas - the whole node has this amount. Thou shalt not go over :D
wholenodeMem=260000
wholenodesafetylimitMem=$((${wholenodeMem}-80000))

# foundFoldersCount=$(($(ls -1 | grep '^fastq_' | grep -c "")))
# We default to 24 processors, and are not planning to change this to become a flag instead ..
askedProcessors=24
# Override for bamcombining and capturesiterounds (start more frequently than every 1 minutes)
if [ "${FastqOrCapturesite}" == "Bamcombine" ];then
    askedProcessors=100
elif [ "${FastqOrCapturesite}" == "Capturesite" ];then
    askedProcessors=40
fi
neededQsubsCount=$(($((${foundFoldersCount}/${askedProcessors}))+1))

echo
echo "foundFoldersCount ${foundFoldersCount}"
echo "askedProcessors ${askedProcessors}"
echo
echo "Will need to run ~ ${neededQsubsCount} times the whole node capasity ${askedProcessors} to satisfy this run ! "
echo

# -------------------

sleepSeconds=600
reportEverythismanyRounds=1
# Override for bamcombining and capturesiterounds (start more frequently than every 1 minutes)
if [ "${FastqOrCapturesite}" == "Bamcombine" ];then
    sleepSeconds=1
    reportEverythismanyRounds=60
elif [ "${FastqOrCapturesite}" == "Capturesite" ];then
    sleepSeconds=1
    reportEverythismanyRounds=60
fi
longSleep=$((${sleepSeconds}*10))
# Override for Fastq runs - we want to stagger the whole run every 10min,
# as we are so prone to oscillate and crash when starting new runs right after we have crashed as TMPdir area got full
# this leading one TMPdir area full event essentially crashing all subsequent samples like dominoes
if [ "${FastqOrCapturesite}" == "Fastq" ];then
    longSleep=${sleepSeconds}
fi

echo
echo "Will be sleeping between starting each of the first 24 runs (to avoid i/o rush hour in downloading ${fastqOrCapturesite}s) .. "
echo "sleep time : ${longSleep} seconds"
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
    
    # Log folder for other-than-fastq-runs to be the chr/capturesite directory
    if [ "${FastqOrCapturesite}" == "Fastq" ];then
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
    # First round starters get longer stagger - to avoid the initial REdig peaks to co-incide ..
    # sleep ${sleepSeconds}
    sleep ${longSleep}
    
    # for testing purposes
    # echo ${allOfTheRunningOnes} >> allRunsJUSTNOW.txt
    ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> allRunsJUSTNOW.txt
    echo "That is ${i} running just now" >> allRunsJUSTNOW.txt
    echo >> allRunsJUSTNOW.txt
    
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

    # Log folder for other-than-fastq-runs to be the chr/capturesite directory
    if [ "${FastqOrCapturesite}" == "Fastq" ];then
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
    # First round starters get longer stagger - to avoid the initial REdig peaks to co-incide ..
    # sleep ${sleepSeconds}
    sleep ${longSleep}
    
    # for testing purposes
    date  >> allRunsJUSTNOW.txt
    # echo ${allOfTheRunningOnes} >> allRunsJUSTNOW.txt
    ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> allRunsJUSTNOW.txt
    echo "That is ${i} runs started so far" >> allRunsJUSTNOW.txt
    echo >> allRunsJUSTNOW.txt

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
repLoop=0
while [ "${weStillNeedThisMany}" -gt 0 ]
do
{

repLoop=$((${repLoop}+1))

countOfThemRunningJustNow=$(($( ps --no-headers -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))

checkThis="${countOfThemRunningJustNow}"
checkedName='${countOfThemRunningJustNow}'
checkParse

if [ "${countOfThemRunningJustNow}" -lt "${askedProcessors}" ]; then
    
    wePotentiallyStartNew=1

    checkIfDownloadsInProgress

    checkIfTooMuchMemUseAlready

    if [ "${wePotentiallyStartNew}" -eq 1 ];then
  
    # Log folder for other-than-fastq-runs to be the chr/capturesite directory
    if [ "${FastqOrCapturesite}" == "Fastq" ];then
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
    
    weStillNeedThisMany=$((${weStillNeedThisMany}-1))
    # This was confusing as inconsistent with above where the looper is ${i}
    # currentFastqNumber=$((${currentFastqNumber}+1))
    i=$((${i}+1))
    
    # Not reporting every round, if we are fast-looping (bam or capturesite loop)
    if [ $((${repLoop}%${reportEverythismanyRounds})) -eq 0 ]; then        
        # for testing purposes
        date  >> allRunsJUSTNOW.txt
        # echo ${allOfTheRunningOnes} >> allRunsJUSTNOW.txt
        ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> allRunsJUSTNOW.txt
        
        TEMPcountAllNow=$( echo ${allOfTheRunningOnes} | tr ' ' '\n' | grep -c "" )
        TEMPcountOfThemRunningJustNow=$(($( ps --no-headers -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))
        
        echo "That is ${TEMPcountAllNow} runs started, ${TEMPcountOfThemRunningJustNow} running just now, and we still need to start ${weStillNeedThisMany} runs" >> allRunsJUSTNOW.txt
        echo >> allRunsJUSTNOW.txt
    fi
    
    fi    
    
fi

# Not reporting every round, if we are fast-looping (bam or capturesite loop)
if [ $((${repLoop}%${reportEverythismanyRounds})) -eq 0 ]; then
    monitorRun
    # Zeroing the counter, to not to go integer overflow in fast looping loops..
    repLoop=0
fi

sleep ${sleepSeconds}

}
done

    
fi

# --------------------------------------

# Now monitoring until the jobs have ended ..


countOfThemRunningJustNow=$(($( ps --no-headers -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))
checkThis="${countOfThemRunningJustNow}"
checkedName='${countOfThemRunningJustNow}'
checkParse

# This while seems to be leaking a little - maybe the output files still get written after
# the process id is vanished
# or I simply parse the id wrongly ?

echo '----------------------------'
echo "Into while monitored with ps --no-headers -p"
date
echo '----------------------------'

while [ "${countOfThemRunningJustNow}" -gt 0 ]
do
{

monitorRun

sleep ${sleepSeconds}
countOfThemRunningJustNow=$(($( ps --no-headers -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') | grep -c "" )))
checkThis="${countOfThemRunningJustNow}"
checkedName='${countOfThemRunningJustNow}'
checkParse

}
done

echo '----------------------------'
echo 'Out of while monitored with ps --no-headers -p'
date
echo '----------------------------'

# for testing purposes
date  >> allRunsJUSTNOW.txt
# echo ${allOfTheRunningOnes} >> allRunsJUSTNOW.txt
ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> allRunsJUSTNOW.txt
echo "That is ${countOfThemRunningJustNow} running just now - out of WHILE monitored with ps $(date)" >> allRunsJUSTNOW.txt
echo >> allRunsJUSTNOW.txt

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
date  >> allRunsJUSTNOW.txt
# echo ${allOfTheRunningOnes} >> allRunsJUSTNOW.txt
ps -p $(echo ${allOfTheRunningOnes} | tr ' ' ',') >> allRunsJUSTNOW.txt
echo "That is ${countOfThemRunningJustNow} running just now - out of WAIT all processes at $(date)" >> allRunsJUSTNOW.txt
echo >> allRunsJUSTNOW.txt

# Now everything is done, so cleaning up !

mkdir qsubLogFiles

if [ "${erroutLogsToHere}" == '.' ]; then

mkdir runscripts
mv run*.sh runscripts/.

mv run${FqOrOl}*.out qsubLogFiles/.
mv run${FqOrOl}*.err qsubLogFiles/.

mv ${fastqOrCapturesite}*_listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log qsubLogFiles/.

fi

mv -f allRunsJUSTNOW.txt qsubLogFiles/allRunsRUNTIME.log

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
cat qsubLogFiles/wholerunUsage*.txt | cut -f 3 | grep M | sed 's/M//' \
| awk 'BEGIN{m=0}{if($1>m){m=$1}}END{print m}' | sed 's/$/M/' >> maxMemUsages.log
echo >> maxMemUsages.log
echo "Maximum work area t1-data memory usage (during our run) : " >> maxMemUsages.log
cat qsubLogFiles/wholerunUsage*.txt | cut -f 2 | grep M | sed 's/M//' \
| awk 'BEGIN{m=0}{if($1>m){m=$1}}END{print m}' | sed 's/$/M/' >> maxMemUsages.log

echo > qsubLogFiles/a_README.txt
echo "All the logs have runtime data in intervals of ${sleepSeconds} seconds, througout the whole run" >> qsubLogFiles/a_README.txt
echo >> qsubLogFiles/a_README.txt

# Lastly we empty the TMPDIR

echo "Emptying TMPDIR .."
checkThis="${TMPDIR}"
checkedName='TMPDIR'
checkParse
rm -rf ${TMPDIR}/*

printThis="All ${fastqOrCapturesite} runs are finished (or crashed) ! "
printNewChapterToLogFile

printThis="Run log files available in : $(basename $(pwd))/qsubLogFiles"
printToLogFile


# ---------------------------
   
}



checkIfTooMuchMemUseAlready(){
# If we are already quite high in memory or disk usage - we can not start a new one ..

# ----------------------------------------

weUseThisManyMegas=0
# All of these get the top logs.
top -b -n 1 | head -n 5 > TEMPtop.log
freeMemJustNow=$( tail -n 2 TEMPtop.log | head -n 1 | sed 's/.*used,\s*//' | sed 's/...k.*//' )
cachedMemJustNow=$( tail -n 1 TEMPtop.log | sed 's/.*free,\s*//' | sed 's/...k.*//' )
rm -f TEMPtop.log

weUseThisManyMegas=$((${wholenodeMem}-${freeMemJustNow}-${cachedMemJustNow}))

if [ "${weUseThisManyMegas}" -gt "${wholenodesafetylimitMem}" ];then

    echo >> allRunsJUSTNOW.txt
    date >> allRunsJUSTNOW.txt
    echo "We currently use ${weUseThisManyMegas}M memory in our node" >> allRunsJUSTNOW.txt
    echo " and as the safe usage upper limit is ${wholenodesafetylimitMem}M," >> allRunsJUSTNOW.txt
    echo " we need to wait until the load comes down, before starting new ones .." >> allRunsJUSTNOW.txt
    
    wePotentiallyStartNew=0
    
    date >> highMemoryTimelog.txt
    echo "We currently use ${weUseThisManyMegas}M memory in our node" >> highMemoryTimelog.txt
    
    
fi

# ----------------------------------------
if [ "${useTMPDIRforThis}" -eq 1 ];then

weUseThisManyMegas=0
if [ "${useWholenodeQueue}" -eq 1 ]; then
    # Not using du in TMPDIR as TMPDIR for each node has its own filesystem, so df can be used instead (tip from Ewan 310718)
    weUseThisManyMegas=$( df --block-size 1000000 ${TMPDIR} | sed 's/\s\s*/\t/g' | cut -f 3 | tail -n 1 )
    # weUseThisManyMegas=$(($( du -sm ${TMPDIR} 2>> /dev/null | cut -f 1 )))
else
    if [ -s runJustNow_${m}.log.tmpdir ];then
        tempareaMemoryUsage=$( cat runJustNow_${m}.log.tmpdir )
    else
        tempareaMemoryUsage=0
    fi
fi

if [ "${weUseThisManyMegas}" -gt "${wholenodesafetylimitDisk}" ];then

    echo >> allRunsJUSTNOW.txt
    date >> allRunsJUSTNOW.txt
    echo "We currently use ${weUseThisManyMegas}M disk space in TMPDIR" >> allRunsJUSTNOW.txt
    echo " and as the safe usage upper limit is ${wholenodesafetylimitDisk}M," >> allRunsJUSTNOW.txt
    echo " we need to wait until the load comes down, before starting new ones .." >> allRunsJUSTNOW.txt
    
    wePotentiallyStartNew=0
    
    date >> highTMPdiskUsageTimelog.txt
    echo "We currently use ${weUseThisManyMegas}M disk space in TMPDIR" >> highTMPdiskUsageTimelog.txt
    
    
fi

fi
# ----------------------------------------

}


checkIfDownloadsInProgress(){
# If we have downloads in progress - we can not start a new one .. 
if [ $(($( ls | grep ${fastqOrCapturesite}*_download_inProgress.log | grep -c "" ))) -ne 0 ]; then
    echo >> allRunsJUSTNOW.txt
    date >> allRunsJUSTNOW.txt
    echo "Downloads in progress for runs : " >> allRunsJUSTNOW.txt
    ls | grep ${fastqOrCapturesite}*_download_inProgress.log | sed 's/_download_inProgress.log//' >> allRunsJUSTNOW.txt
    echo "Will wait until download finished, before starting new ones .." >> allRunsJUSTNOW.txt
    
    wePotentiallyStartNew=0
    
    date >> downloadIOlimitedLog.txt
    echo "Downloads in progress for runs : " >> downloadIOlimitedLog.txt
    ls | grep ${fastqOrCapturesite}*_download_inProgress.log | sed 's/_download_inProgress.log//' >> downloadIOlimitedLog.txt
    
fi  
}

monitorRun(){
    
timepoint=$(date +%H:%M)

# All of these get the top logs.
top -b -n 1 | head -n 5 > TEMPtop.log
usedProcsRightNow=$( head -n 1 TEMPtop.log | sed 's/.*load average: //' | sed 's/,.*//' )
procUsePercentsRightNow=$( head -n 3 TEMPtop.log | tail -n 1 | tr ',' '\t' | tr ':' '\t' | sed 's/\s\s*/\t/g'| cut -f 2,3,5,6 | sed 's/%/\t%/g' )
freeMemJustNow=$( tail -n 2 TEMPtop.log | head -n 1 | sed 's/.*used,\s*//' | sed 's/...k.*/M/' )
cachedMemJustNow=$( tail -n 1 TEMPtop.log | sed 's/.*free,\s*//' | sed 's/...k.*/M/' )
stuffParsedFromTop=" ${usedProcsRightNow} ${procUsePercentsRightNow} ${freeMemJustNow} ${cachedMemJustNow}"
rm -f TEMPtop.log

# If we are bamcombine run, not doing the complicated parts at all.    
if [ "${FastqOrCapturesite}" != "Bamcombine" ]
then
    
#_____________________
# For testing purposes

# free -m
# df -m 
# du -m 
# ps T

#_____________________

# Counting first .

date > runsJUSTNOW.txt

# Memory as well

# Commenting this out as this is too much. du takes so long time when we have A LOT OF FILES like we have (tens of thousands)
# localMemoryUsage=$( du -sm ${wholenodeSubmitDir} 2>> /dev/null | cut -f 1 )
localMemoryUsage="NOTcounted"

# Override for bamcombining (never in TMPDIR)
if [ "${FastqOrCapturesite}" == "Bamcombine" ];then
    tempareaMemoryUsage=0
else

    if [ "${useTMPDIRforThis}" -eq 1 ];then
        if [ "${useWholenodeQueue}" -eq 1 ]; then
        # tempareaMemoryUsage=$( du -sm ${TMPDIR} 2>> /dev/null | cut -f 1 )
        # Not using du in TMPDIR as TMPDIR for each node has its own filesystem, so df can be used instead (tip from Ewan 310718)
        tempareaMemoryUsage=$( df --block-size 1000000 ${TMPDIR} | sed 's/\s\s*/\t/g' | cut -f 3 | tail -n 1 )
        
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

#_____________________

# Reporting all running children

cat runJustNow_*.log | tr '\n' ' ' | sed 's/$/\n/' | sed 's/^/'${timepoint}' /' | sed 's/\s/\t/g' >> wholerunTasks.txt
usageMessage="${localMemoryUsage}M ${tempareaMemoryUsage}M ${timepoint}${stuffParsedFromTop}"
echo ${usageMessage} | sed 's/\s/\t/g' >> wholerunUsage.txt


# If we are bamcombine run, only top output, and only once. 
else
    
    usageMessage="${timepoint}${stuffParsedFromTop}"
    echo ${usageMessage} | sed 's/\s/\t/g' >> wholerunUsage.txt
fi

}
