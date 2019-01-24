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

copyRainbowLogFiles(){

# Copying log files

echo "Copying run log files.." >> "/dev/stderr"

cp -f qsub.out "${publicfolder}/${samplename}/${CCversion}_${REenzyme}/qsub.out"
cp -f qsub.err "${publicfolder}/${samplename}/${CCversion}_${REenzyme}/qsub.err"

echo "Log files copied !" >> "/dev/stderr"
    
}

function finish {
    
cp ${CaptureParallelPath}/E_cleanupScript_toUse_afterSuccesfull_Run.sh ${HOME}/.
chmod u=rwx ${HOME}/E_cleanupScript_toUse_afterSuccesfull_Run.sh

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! - check qsub.err to see why !"
echo

else

if [ "${parameterList}" != "-h" ] && [ "${parameterList}" != "--help" ]
then
echo
date
printThis='Analysis complete !'
printToLogFile
fi
    
fi
}
trap finish EXIT

# This is to divide the run, in same order as the parallel run
# But for serial excecution.
# All the actual stuff is done in scripts which are called from here (which all import their own accessory scripts)
# to keep it lightweight on the parallelisation level.

# The sister script doing exactly the same, but with nextFlow parallelisation
# is CCseqBasic5parallel.sh
# ------------------------------------------------------

# The serial execution order is :

# 1) check forbidden flags (not allowing sub-level flags --onlyREdigest, --parallel 1 --parallel 2 --R1 --R2 --outfile --errfile)
# 2) sort capture-site (REfragment) file, check fastq integrity
# 3) mainRunner.sh --onlyREdigest
# 4) for each fastq in the list : mainRunner.sh --parallel 1
# 5) combine results
# 6) mainRunner.sh --onlyBlat
# 7) for each capture-site (REfragment) bunch in the list : mainRunner.sh --parallel 2
# 8) visualise

# For eachof these 8 steps the main script needs to be an EXCECUTABLE SCRIPT (so that the logic is exactly parallel to that what will be in the parallel nextFlow run )

# Steps 1-2 will be in same script "prepare.sh"

# ------------------------------------------

CCversion="CM5"
captureScript="analyseMappedReads"
CCseqBasicVersion="CCseqBasic5_rainbow"

# -----------------------------------------

MainScriptPath="$( which $0 | sed 's/\/'${CCseqBasicVersion}'.sh$//' )"

CaptureParallelPath="${MainScriptPath}/bin/parallel"
CaptureSerialPath="${MainScriptPath}/bin/serial"
CaptureCommonHelpersPath="${MainScriptPath}/bin/commonSubroutines"

# -----------------------------------------

# Help-only run type ..

if [ $# -eq 1 ]
then
parameterList=$@
if [ ${parameterList} == "-h" ] || [ ${parameterList} == "--help" ]
then
. ${CaptureSerialPath}/subroutines/usageAndVersion.sh
usage
exit

fi
fi
#------------------------------------------

# Normal runs (not only help request) starts here ..

echo "${CCseqBasicVersion}.sh - by Jelena Telenius, 05/01/2016"
echo
timepoint=$( date )
echo "run started : ${timepoint}"
echo
echo "Script located at"
echo "$0"
echo

# Writing the queue environment variables to a log file :

${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "${CCseqBasicVersion}.sh" $@
echo

parameterList=$@
#------------------------------------------

echo
echo "MainScriptPath ${MainScriptPath}"
echo "CaptureParallelPath ${CaptureParallelPath}"
echo "CaptureSerialPath ${CaptureSerialPath}"
echo "CaptureCommonHelpersPath ${CaptureCommonHelpersPath}"
echo

# -----------------------------------------

reGenomeFilePath="UNDEFINED"
reBlacklistFilePath="UNDEFINED"
reWhitelistFilePath="UNDEFINED"

capturesitefile="UNDEFINED"

onlyblat=0

reuseblatpath='.'

threadCount=4

rainbowRunTOPDIR=$(pwd)
echo "rainbowRunTOPDIR ${rainbowRunTOPDIR}"
echo

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# TESTING file existence, log file output general messages
. ${CaptureCommonHelpersPath}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found in $0. Cannot continue without safety features turned on ! \n EXITING !! "
    printToLogFile
    exit 1
fi

# PARALLEL RUN specific subs - these are needed only within this top level script
. ${CaptureParallelPath}/bashHelpers/parallel_runtools.sh
# PARALLEL RUN QSUBBING specific subs - these are needed only within this top level script (and in the above parallel_runtools.sh)
. ${CaptureParallelPath}/bashHelpers/multitaskers.sh

# SORTING HELPER SUBROUTINES
. ${CaptureCommonHelpersPath}/sort_helpers.sh

# RERUN INSTRUCTIONS WRITER sub
. ${CaptureSerialPath}/subroutines/usageAndVersion.sh

# DEBUG SUBROUTINES - for the situations all hell breaks loose
# . ${CaptureSerialPath}/subroutines/debugHelpers.sh

#------------------------------------------
# Setting $HOME to the current dir
echo 'Turning on safety measures for cd rm and mv commands in $0 - restricting script to file operations "from this dir below" only :'
HOME=$(pwd)
echo $HOME
echo
# - to enable us to track mv rm and cd commands
# from taking over the world accidentally
# this is done in testers_and_loggers.sh subroutines, which are to be used
# every time something gets parsed, and after that when the parsed value is used to mv cd or rm anything
# ------------------------------------------

# Test the testers and loggers ..

printThis="Testing the tester subroutines in $0 .."
printToLogFile
printThis="${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err"
printToLogFile
   
${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err
# The above exits if any of the tests don't work properly.

# The below exits if the logger test sub wasn't found (path above wrong or file not found)
if [ "$?" -ne 0 ]; then
    printThis="Testing testers_and_loggers.sh safety routines failed in $0 . Cannot continue without testing safety features ! \n EXITING !! "
    printToLogFile
    exit 1
else
    printThis="Testing the tester subroutines completed - continuing ! "
    printToLogFile
fi

# Comment this out, if you want to save these files :
rm -f testers_and_loggers_test.out testers_and_loggers_test.err

#------------------------------------------

# 1) check forbidden flags (not allowing sub-level flags --onlyREdigest, --onlyBlat , --parallel 1 --parallel 2 --R1 --R2 --outfile --errfile)
# These subs are taken from macs2hubber.sh (20Feb2018)

parameterList="PARAMETERS ${parameterList} END"
echo ${parameterList} > TEMP.param

${CaptureParallelPath}/checkParameters.sh
exitStatus=$( echo $? )

parameterList=$( cat TEMP.param | sed 's/\s*END$//' | sed 's/^PARAMETERS\s*//' )

capturesitefile=$( cat TEMP.mainparam | grep '^capturesitefile\s' | sed 's/\s\s*/\t/' | cut -f 2 )
inputgenomename=$( cat TEMP.mainparam | grep '^inputgenomename\s' | sed 's/\s\s*/\t/' | cut -f 2 )
samplename=$( cat TEMP.mainparam | grep '^samplename\s' | sed 's/\s\s*/\t/' | cut -f 2 )
REenzyme=$( cat TEMP.mainparam | grep '^REenzyme\s' | sed 's/\s\s*/\t/' | cut -f 2 )
REenzymeShort=$( cat TEMP.mainparam | grep '^REenzymeShort\s' | sed 's/\s\s*/\t/' | cut -f 2 )
publicfolder=$( cat TEMP.mainparam | grep '^publicfolder\s' | sed 's/\s\s*/\t/' | cut -f 2 )
tiled=$( cat TEMP.mainparam | grep '^tiled\s' | sed 's/\s\s*/\t/' | cut -f 2 )
useTMPDIRforThis=$( cat TEMP.mainparam | grep '^useTMPDIRforThis\s' | sed 's/\s\s*/\t/' | cut -f 2 )
useWholenodeQueue=$( cat TEMP.mainparam | grep '^useWholenodeQueue\s' | sed 's/\s\s*/\t/' | cut -f 2 )

checkThis="${capturesitefile}"
checkedName='capturesitefile'
checkParse
checkThis="${inputgenomename}"
checkedName='inputgenomename'
checkParse
checkThis="${samplename}"
checkedName='samplename'
checkParse
checkThis="${REenzyme}"
checkedName='REenzyme'
checkParse
checkThis="${REenzymeShort}"
checkedName='REenzymeShort'
checkParse
checkThis="${publicfolder}"
checkedName='publicfolder'
checkParse
checkThis="${tiled}"
checkedName='tiled'
checkParse
checkThis="${useTMPDIRforThis}"
checkedName='useTMPDIRforThis'
checkParse
checkThis="${useWholenodeQueue}"
checkedName='useWholenodeQueue'
checkParse

# Overwriting "not using TMPDIR" in situation that we are in wholenode queue.
# if [ "${useWholenodeQueue}" -eq 1 ]; then
#     useTMPDIRforThis=1
# fi

# Overwriting "using TMPDIR" in situation that we are normal threaded job.
if [ "${useWholenodeQueue}" -eq 0 ]; then
    useTMPDIRforThis=0
fi

# Forcing using symlinks - this is rainbow run, and thus visualisations will not work otherwise ..

parameterList="${parameterList} --useSymbolicLinks"

isReuseBlatPathGiven=$(($( cat TEMP.mainparam | grep -c '^reuseblatpath\s' )))
isCCversionGiven=$(($( cat TEMP.mainparam | grep -c '^CCversion\s' )))
isThreadcountGiven=$(($( cat TEMP.mainparam | grep -c '^threads\s' )))

if [ "${isReuseBlatPathGiven}" -ne 0 ]; then
reuseblatpath=$( cat TEMP.mainparam | grep '^reuseblatpath\s' | sed 's/\s\s*/\t/' | cut -f 2 )
fi
if [ "${isCCversionGiven}" -ne 0 ]; then
CCversion=$( cat TEMP.mainparam | grep '^CCversion\s' | sed 's/\s\s*/\t/' | cut -f 2 )
fi
if [ "${isThreadcountGiven}" -ne 0 ]; then
threadCount=$( cat TEMP.mainparam | grep '^threads\s' | sed 's/\s\s*/\t/' | cut -f 2 )
fi

checkThis="${reuseblatpath}"
checkedName='reuseblatpath'
checkParse
checkThis="${CCversion}"
checkedName='CCversion'
checkParse
checkThis="${threadCount}"
checkedName='threadCount'
checkParse

onlyblat=$(($( cat TEMP.mainparam | grep -c onlyBlat )))
rerunBrokenFastqs=$(($( cat TEMP.mainparam | grep -c rerunBrokenFastqs )))
stopAfterFolderB=$(($( cat TEMP.mainparam | grep -c stopAfterFolderB )))
startAfterFolderB=$(($( cat TEMP.mainparam | grep -c startAfterFolderB )))
stopAfterBamCombining=$(($( cat TEMP.mainparam | grep -c stopAfterBamCombining )))
onlyCCanalyser=$(($( cat TEMP.mainparam | grep -c onlyCCanalyser )))
onlyHub=$(($( cat TEMP.mainparam | grep -c onlyHub )))

echo
echo "Parameters after parsing :"
echo "${parameterList}"
echo "onlyblat ${onlyblat}"
echo "reuseblatpath ${reuseblatpath}"
echo "capturesitefile ${capturesitefile}"
echo "inputgenomename ${inputgenomename}"
echo "samplename ${samplename}"
echo "REenzyme ${REenzyme}"
echo "REenzymeShort ${REenzymeShort}"
echo "CCversion ${CCversion}"
echo "publicfolder ${publicfolder}"
echo "tiled ${tiled}"
echo "useWholenodeQueue ${useWholenodeQueue}"
echo "threadCount ${threadCount}"
echo "useTMPDIRforThis ${useTMPDIRforThis}"
echo "rerunBrokenFastqs ${rerunBrokenFastqs}"
echo "stopAfterFolderB ${stopAfterFolderB}"
echo "startAfterFolderB ${startAfterFolderB}"
echo "stopAfterBamCombining ${stopAfterBamCombining}"
echo "onlyCCanalyser ${onlyCCanalyser}"
echo "onlyHub ${onlyHub}"
echo

rm -f TEMP.param TEMP.mainparam
if [ "${exitStatus}" -ne 0 ]; then { exit 1 ; }; fi

# --------------------------------------
# OnlyHub ..

if [ "${onlyHub}" -eq 1 ] ; then
    
  printThis="Only generating summary counts and data hub - as user states --onlyHub  .. "
  printNewChapterToLogFile

  printThis="MultiQC reports  .. "
  printNewChapterToLogFile

  ${CaptureParallelPath}/parallel_QC.sh ${samplename} ${CCversion}

  printThis="Fastq summary counts  .. "
  printNewChapterToLogFile

  flashstatus="FLASHED"
  makeFastqrunSummaries
  flashstatus="NONFLASHED"
  makeFastqrunSummaries
  
  # Not using FLASHED/NONFLASHED flags ..
  makeGeneralFastqrunSummaries
  
  # Summary of summaries ..
  head -n 20 B_mapAndDivideFastqs/*FLASHED*.[tl][xo][tg] > B_fastqSummaryCounts.txt
  echo >> B_fastqSummaryCounts.txt
  echo '==> B_mapAndDivideFastqs/flashing.log <==' >> B_fastqSummaryCounts.txt
  cat B_mapAndDivideFastqs/flashing.log >> B_fastqSummaryCounts.txt
  
  printThis="Combined bam visualisations  .. "
  printNewChapterToLogFile

  makeCombinedBamVisualisation
  
  printThis="capture-site (REfragment)summary counts .. "
  printNewChapterToLogFile
  
  flashstatus="FLASHED"
  makeCapturesiterunSummaries
  flashstatus="NONFLASHED"
  makeCapturesiterunSummaries

  makeCombinedCapturesiterunSummaries
  
  # Summary of summaries ..
  head -n 20 D_analyseCapturesiteWise/*FLASHED_percentagesAndFinalCounts.txt > D_analysisSummaryCounts.txt
  echo >> D_analysisSummaryCounts.txt
  echo "==> D_analyseCapturesiteWise/COMBINED_meanStdMedian_overCapturesites.txt <==" >> D_analysisSummaryCounts.txt
  cat D_analyseCapturesiteWise/COMBINED_meanStdMedian_overCapturesites.txt >> D_analysisSummaryCounts.txt


  printThis="Generate data hub .. "
  printNewChapterToLogFile
  
  generateDataHub
  
  copyRainbowLogFiles 
  exit 0

fi

# --------------------------------------
# If we are to skip the whole folders A and B : we enter after succesfully rescuing our fastq analysis stages,
# when using --stopAfterFolderB  or --onlyCCanalyser
if [ "${startAfterFolderB}" -eq 1 ] || [ "${onlyCCanalyser}" -eq 1 ] ; then
  printThis="Skipping folders A and B (and their integrity tests) - as user states --startAfterFolderB  or --onlyCCanalyser  .. "
  printNewChapterToLogFile    
else
{
# 2a) check fastq integrity
${CaptureParallelPath}/fastqExistenceChecks.sh
exitStatus=$( echo $? ); if [ "${exitStatus}" -ne 0 ]; then { exit 1 ; }; fi
#------------------------------------------

printThis="Check capture-site (REfragment) file, sort coordinate-wise .. "
printNewChapterToLogFile
echo
echo "capturesitefile ${capturesitefile}"
ls -lht ${capturesitefile}
echo

# -----------------------------------------

rm -rf A_prepareForRun
mkdir A_prepareForRun
cd A_prepareForRun

stepAmiddir=$(pwd)

# 2b) sort capture-site (REfragment) file

mkdir CAPTURESITEFILE
sort -T $(pwd) -k2,2n -k3,3n ${capturesitefile} > CAPTURESITEFILE/capturesitefile_sorted.txt
capturesitefile="$(pwd)/CAPTURESITEFILE/capturesitefile_sorted.txt"

# Make oneliners for all capture-site (REfragment)s, to be used in the combining stage..

# Chr folders
mkdir CAPTURESITESindividualFiles
for TEMPnumber in $(cut -f 2 ${capturesitefile} | uniq)
do
    mkdir CAPTURESITESindividualFiles/chr${TEMPnumber}
done

# Make temp commands to make all the Chr/capturesite folders (each folder has only one capture-site (REfragment) ! )
cat ${capturesitefile} | cut -f 1-2 | awk '{print "mkdir CAPTURESITESindividualFiles/chr"$2"/"$1}' > TEMPcommands.sh
chmod u+x TEMPcommands.sh
./TEMPcommands.sh
rm -f TEMPcommands.sh

# capture-site (REfragment)wise capture-site (REfragment) files into each capture-site (REfragment) folder
cat ${capturesitefile} | awk '{print $0 >> "CAPTURESITESindividualFiles/chr"$2"/"$1"/capturesiteFileOneliner.txt"}'

# Now the whole thing can be cp -r:d to become the initial structure of folder C !
# A_prepareForRun/CAPTURESITESindividualFiles

#------------------------------------------

echo
echo "After coordinate-wise sorting :"
echo "capturesitefile ${capturesitefile}"
printThis=$( ls -lht ${capturesitefile} )
printToLogFile
echo
# -----------------------------------------

# 3) mainRunner.sh --onlyREdigest

printThis="Make Restriction Enzyme digest, and its blacklist file .. "
printNewChapterToLogFile

mkdir REdigest
cd REdigest
digestOK=1

echo "${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${capturesitefile} --${REenzymeShort} --onlyREdigest --pf ${publicfolder} --outfile runRE.out --errfile runRE.err"
${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${capturesitefile} --${REenzymeShort} --onlyREdigest --pf ${publicfolder} --outfile runRE.out --errfile runRE.err 1> runRE.out 2> runRE.err
# --------------------------
if [ "$?" -ne 0 ];then
    printThis="Digest generation run reported error !"
    printNewChapterToLogFile
    digestOK=0
fi
# --------------------------
echo "REdigest run log files were generated here : REdigest/runRE.out REdigest/runRE.err"
echo

if [ "${digestOK}" -eq 1 ]; then {

if [ ! -s REdigest.log ]; then { digestOK=0 ; }; fi
if [ "${digestOK}" -eq 1 ]; then {
  if [ "$(($( cat REdigest.log | grep -c fullPathDpnGenome )))" -eq 0 ]; then { digestOK=0 ; }; fi
  if [ "$(($( cat REdigest.log | grep -c fullPathDpnBlacklist )))" -eq 0 ]; then { digestOK=0 ; };  fi
}
fi

if [ "${digestOK}" -eq 0 ]; then
    printThis="Digest log files didn't have all needed information !"
    printNewChapterToLogFile
fi

}
fi

# --------------------------

if [ "${digestOK}" -eq 1 ]; then {
  reGenomeFilePath=$(    cat REdigest.log | grep fullPathDpnGenome    | sed 's/\s\s*/\t/' | cut -f 2)
  reBlacklistFilePath=$( cat REdigest.log | grep fullPathDpnBlacklist | sed 's/\s\s*/\t/' | cut -f 2)
  reWhitelistFilePath=$( cat REdigest.log | grep fullPathCapturesiteWhitelist | sed 's/\s\s*/\t/' | cut -f 2)
}
else {
  printThis="Restriction Enzyme digest generation failed "
  printNewChapterToLogFile
  
  # Print some mainrunner error messages here ..
  cat runRE.err | grep EXITING >&2
  cat runRE.err | grep 'refusing to overwrite' >&2
  
  printThis="More details of the crash in file : $(pwd)/runRE.err"
  printToLogFile
  
  printThis="EXITING "
  printToLogFile
  
  exit 1
}
fi    

cdCommand='cd ${stepAmiddir}'
cdToThis="${stepAmiddir}"
checkCdSafety
cd ${stepAmiddir}
#------------------------------------------

echo
echo "reGenomeFilePath ${reGenomeFilePath}"
echo "reBlacklistFilePath ${reBlacklistFilePath}"
echo "reWhitelistFilePath ${reWhitelistFilePath}"
echo
ls -lht ${reGenomeFilePath}
ls -lht ${reBlacklistFilePath}
ls -lht ${reWhitelistFilePath}
echo

checkThis="${reGenomeFilePath}"
checkedName='reGenomeFilePath'
checkParse
checkThis="${reBlacklistFilePath}"
checkedName='reBlacklistFilePath'
checkParse
checkThis="${reWhitelistFilePath}"
checkedName='reWhitelistFilePath'
checkParse

# -----------------------------------------

# Check BLAT parameters - readymade files can be given to --onlyBlat as well !

# At this point we allow incomplete blat folder - as we are to regenerate the stuff .

# ------------------------------------

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety
cd ${rainbowRunTOPDIR}

prepareBlatFolder

# -----------------------------------------

# Only blat user case ..

if [ "${onlyblat}" -eq 1 ] ; then
    printThis="Running BLAT ONLY , as user requested --onlyBlat  .. "
    printNewChapterToLogFile
  
    #  mainRunner.sh --onlyBlat

    # Test runs - disabling blat ..

    # blatRun
    # checkBlatErrors
    
    printThis="This was --onlyBlat  run, so finishing up "
    printToLogFile
    printThis="All capture-site (REfragment)s are now BLAT-analysed "
    printToLogFile
    
    copyRainbowLogFiles
    exit 0
fi
  
# -----------------------------------------

# Now, starting normal run types ..

# ------------------------------------------

# Make fastq divisions - determine if more or less fastqs than processors.
# Making as many PIPE_fastqPaths.txt files as there is threads asked 

# ------------------------------------------
# 4) for each fastq in the list : prepare for main run, mainRunner.sh --parallel 1
#

# The below generates and/or updates the analysis folder B_mapAndDivideFastqs

# -----------------------
# B_mapAndDivideFastqs
# -----------------------

prepareFastqRun
doQuotaTesting

cd B_mapAndDivideFastqs

# Here the divider between WHOLENODEQUEUE runs and NORMAL MULTITASK jobs

FqOrOl="Fq"
fqOrOL="fq"
fastqOrCapturesite="fastq"
FastqOrCapturesite="Fastq"
foundFoldersCount=$(($(ls -1 | grep '^fastq_' | grep -c "")))
checkThis="${foundFoldersCount}"
checkedName='foundFoldersCount'
checkParse

if [ "${useWholenodeQueue}" -eq 1 ]; then
runWholenode
else
runMultitask
fi
doQuotaTesting

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety  
cd ${rainbowRunTOPDIR}

# Make summaries

${CaptureParallelPath}/parallel_QC.sh ${samplename} ${CCversion}

flashstatus="FLASHED"
makeFastqrunSummaries
flashstatus="NONFLASHED"
makeFastqrunSummaries

# Not using FLASHED/NONFLASHED flags ..
makeGeneralFastqrunSummaries

# Summary of summaries ..
head -n 20 B_mapAndDivideFastqs/*FLASHED*.[tl][xo][tg] > B_fastqSummaryCounts.txt
echo >> B_fastqSummaryCounts.txt
echo '==> B_mapAndDivideFastqs/flashing.log <==' >> B_fastqSummaryCounts.txt
cat B_mapAndDivideFastqs/flashing.log >> B_fastqSummaryCounts.txt

# Check for errors ..

checkFastqRunErrors

# ------------------------------

# If running only first stages
if [ "${stopAfterFolderB}" -eq 1 ]; then
    
    printThis="This was --stopAfterFolderB  run, so finishing up .."
    printToLogFile
    printThis="All fastqs are now analysed"
    printToLogFile
    
    copyRainbowLogFiles
    exit 0
fi

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety
cd ${rainbowRunTOPDIR}
    
# This is end of if startAfterFolderB : If resuming after fastq repair reruns
}
fi
# ---------------------------------------

# Now, if we are not --onlyBlat run, we run folders F1 and F2 normally , in folder D.

# 5) Combining capture-site (REfragment) bunches in folder C , continuing to folder D to generate F1 and F2 folders

B_FOLDER_PATH="UNDEFINED"
# Checking we have folders A and B - so we have at least somewhat functional structure at this point ..
if [ ! -d A_prepareForRun ] || [ ! -d B_mapAndDivideFastqs ]; then
    
    printThis="Cannot find output folder A_prepareForRun and/or B_mapAndDivideFastqs. "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    
    exit 1
    
fi
B_FOLDER_PATH="$(pwd)/B_mapAndDivideFastqs"
    
    
if [ "${onlyCCanalyser}" -eq 1 ]; then
  printThis="Skipping folder C, and folder C integrity tests - as user states --onlyCCanalyser  .. "
  printNewChapterToLogFile
else
    

# 5a) for each capture-site (REfragment) bunch in the list : combine with samtools bam catenate, to corresponding folder in D
printThis="Combining the output bams to single files per capture-site (REfragment) bunch : flashed and nonflashed separately "
printNewChapterToLogFile

C_FOLDER_PATH="$(pwd)/C_combineCapturesiteWise"

rm -rf C_combineCapturesiteWise
# mkdir C_combineCapturesiteWise
cp -r A_prepareForRun/CAPTURESITESindividualFiles C_combineCapturesiteWise

bamCombinePrepareRun
checkBamsOfThisDir="C_combineCapturesiteWise"
checkBamprepcombineErrors

doQuotaTesting

cd C_combineCapturesiteWise

# Here the divider between WHOLENODEQUEUE runs and NORMAL MULTITASK jobs

FqOrOl="BAM"
fqOrOL="Bam"
fastqOrCapturesite="bamcombine"
FastqOrCapturesite="Bamcombine"


foundFoldersCount=$(($( cat runlist.txt | grep -c "" )))
checkThis="${foundFoldersCount}"
checkedName='foundFoldersCount'
checkParse

if [ "${useWholenodeQueue}" -eq 1 ]; then   
runWholenode
else
runMultitask
fi
doQuotaTesting

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety  
cd ${rainbowRunTOPDIR}
checkBamcombineErrors

date
cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety
cd ${rainbowRunTOPDIR}

# onlyCCanalyser end if
fi

# -----------------------------------

# 8) visualise

makeCombinedBamVisualisation

# echo "${CaptureParallelPath}/parallelVisualisationLogs.sh ${publicfolder} ${samplename} ${CCversion} ${REenzyme} ${inputgenomename} ${tiled} $(basename ${B_FOLDER_PATH}) $(basename ${C_FOLDER_PATH}) ${capturesitefile}"
# ${CaptureParallelPath}/parallelVisualisationLogs.sh ${publicfolder} ${samplename} ${CCversion} ${REenzyme} ${inputgenomename} ${tiled} $(basename ${B_FOLDER_PATH}) $(basename ${C_FOLDER_PATH}) ${capturesitefile}

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety  
cd ${rainbowRunTOPDIR}

# ------------------------------

# TILED capture support early-exit ..

if [ "${stopAfterBamCombining}" -eq 1 ]; then
    
  printThis="This is --stopAfterBamCombining run : all done, script finished ! "
  printNewChapterToLogFile

  copyRainbowLogFiles
  exit 0
  
fi

# ------------------------------
# Now we may be startAfterBamCombining - i.e. --onlyCCanalyser ..

C_FOLDER_PATH="UNDEFINED"
# Checking we have folders A and B - so we have at least somewhat functional structure at this point ..
if [ ! -d A_prepareForRun ] || [ ! -d B_mapAndDivideFastqs ] || [ ! -d C_combineCapturesiteWise ]; then
    
    printThis="Cannot find output folder A_prepareForRun and/or B_mapAndDivideFastqs and/or C_combineCapturesiteWise . "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    
    printThis=$(pwd)
    printToLogFile
    printThis=$(ls)
    printToLogFile
    
    exit 1
    
fi

if [ "${onlyCCanalyser}" -eq 1 ]; then
  printThis="Preparing/Regenerating BLAT folder - as user states --onlyCCanalyser "
fi
if [ "${startAfterFolderB}" -eq 1 ]; then
  printThis="Preparing/Regenerating BLAT folder - as user states --startAfterFolderB "
fi
printNewChapterToLogFile

if [ "${onlyCCanalyser}" -eq 1 ] || [ "${startAfterFolderB}" -eq 1 ]; then
 
  printThis="Preparing BLAT folder - as user states --onlyCCanalyser  or --startAfterFolderB "
  printNewChapterToLogFile
  
  rm -rf BLAT
  prepareBlatFolder

fi

C_FOLDER_PATH="$(pwd)/C_combineCapturesiteWise"

# Setting the RE-genome path ..

  reGenomeFilePath=$( cat A_prepareForRun/REdigest/REdigest.log | grep fullPathDpnGenome | sed 's/\s\s*/\t/' | cut -f 2 )

  checkThis="${reGenomeFilePath}"
  checkedName='reGenomeFilePath'
  checkParse
  
# ------------------------------------

# 7) for each capture-site (REfragment) bunch in the list : mainRunner.sh --parallel 2

prepareParallelCCanalyserRun
# doQuotaTesting

cd D_analyseCapturesiteWise

# Here the divider between WHOLENODEQUEUE runs and NORMAL MULTITASK jobs

FqOrOl="Ol"
fqOrOL="OL"
fastqOrCapturesite="capturesite"
FastqOrCapturesite="Capturesite"


foundFoldersCount=$(($( cat runlist.txt | grep -c "" )))
checkThis="${foundFoldersCount}"
checkedName='foundFoldersCount'
checkParse
  
if [ "${useWholenodeQueue}" -eq 1 ]; then   
runWholenode
else
runMultitask
fi
# doQuotaTesting

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety  
cd ${rainbowRunTOPDIR}

# Make summaries

flashstatus="FLASHED"
makeCapturesiterunSummaries
flashstatus="NONFLASHED"
makeCapturesiterunSummaries

makeCombinedCapturesiterunSummaries

# Summary of summaries ..
head -n 20 D_analyseCapturesiteWise/*FLASHED_percentagesAndFinalCounts.txt > D_analysisSummaryCounts.txt
echo "" >> D_analysisSummaryCounts.txt
echo "==> D_analyseCapturesiteWise/COMBINED_meanStdMedian_overCapturesites.txt <==" >> D_analysisSummaryCounts.txt
cat D_analyseCapturesiteWise/COMBINED_meanStdMedian_overCapturesites.txt >> D_analysisSummaryCounts.txt

# Check for errors

checkParallelCCanalyserErrors

# -----------------------------------

# 8) visualise

printThis="Making rainbow tracks and data hub .. "
printNewChapterToLogFile

printThis="Generate data hub .. "
printNewChapterToLogFile
  
generateDataHub

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety  
cd ${rainbowRunTOPDIR}

# -----------------------------------------

copyRainbowLogFiles

exit 0


