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

# This is to divide the run, in same order as the parallel run
# But for serial excecution.
# All the actual stuff is done in scripts which are called from here (which all import their own accessory scripts)
# to keep it lightweight on the parallelisation level.

# The sister script doing exactly the same, but with nextFlow parallelisation
# is CCseqBasic5parallel.sh

# ------------------------------------------------------

# The serial execution order is :

# 1) check forbidden flags (not allowing sub-level flags --onlyREdigest, --parallel 1 --parallel 2 --R1 --R2 --outfile --errfile)
# 2) sort oligo file, check fastq integrity
# 3) mainRunner.sh --onlyREdigest
# 4) for each fastq in the list : mainRunner.sh --parallel 1
# 5) combine results
# 6) mainRunner.sh --onlyBlat
# 7) for each oligo bunch in the list : mainRunner.sh --parallel 2
# 8) visualise

# For eachof these 8 steps the main script needs to be an EXCECUTABLE SCRIPT (so that the logic is exactly parallel to that what will be in the parallel nextFlow run )

# Steps 1-2 will be in same script "prepare.sh"


# ------------------------------------------

checkFastqRunErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs

# Check that no errors.

rm -f fastqRoundSuccess.log
for file in fastq_*/fastqRoundSuccess.log
do
    cat ${file} | sed 's/^/'$(dirname ${file})'\t/' >> fastqRoundSuccess.log
done

howManyErrors=$(($( cat fastqRoundSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some fastqs crashed during first steps of analysis ( possibly quota issues ? )."
  printNewChapterToLogFile
  
  echo "These samples had errors :"
  echo
  cat fastqRoundSuccess.log | grep -v '^#' | grep -v '\s1$'
  echo
  
  head -n 1 fastqRoundSuccess.log > failedFastqsList.log
  cat fastqRoundSuccess.log | grep -v '^#' | grep -v '\s1$' >> failedFastqsList.log
  
  printThis="Check which samples failed : $(pwd)/failedFastqsList.log ! "
  printToLogFile
  printThis="Detailed error logs in files : B_mapAndDivideFastqs/fastq_*/run.err "
  printToLogFile
  printThis="Detailed rerun instructions (to rescue failed fastqs and restart the run) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All fastqs finished first steps of analysis ! - moving on to analyse sam files .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

prepareFastqRun(){
# ------------------------------------------
# 4) for each fastq in the list : prepare for main run, mainRunner.sh --parallel 1

printThis="Prepare parameter files and fastq-folders for the runs .. "
printNewChapterToLogFile

# Generating possibly-existing output folder - aborting if exists (not supporting any of that stuff yet)

if [ -d B_mapAndDivideFastqs ];then
    printThis="Found existing folder $(pwd)/B_mapAndDivideFastq ! \n Refusing to overwrite ! \n EXITING !! "
    printToLogFile
    exit 1    
fi

mkdir B_mapAndDivideFastqs

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs
bfolderDirForTestCase=$(pwd)
JustNowFile=$(pwd)/runJustNow

echo
echo $( cat ../PIPE_fastqPaths.txt | grep -c "" )" fastq file pairs found ! "
echo

echo > fastqrunfolderPrepare.log
echo $( cat ../PIPE_fastqPaths.txt | grep -c "" )" fastq file pairs found ! " >> fastqrunfolderPrepare.log
echo >> fastqrunfolderPrepare.log

fastqCounter=1;
for (( i=1; i<=$(($( cat ../PIPE_fastqPaths.txt | grep -c "" ))); i++ ))
do {
    
    printThis="Parameters for ${fastqCounter}th row of of PIPE_fastqPaths.txt , i.e. folder fastq_${fastqCounter}"
    printToLogFile
   
    mkdir fastq_${fastqCounter}
    cat ../PIPE_fastqPaths.txt | tail -n +${fastqCounter} | head -n 1 | awk '{print $1"_"$2"_"$3"\t"$0}' > fastq_${fastqCounter}/PIPE_fastqPaths.txt
    
    downloadLogBasename="$(pwd)/fastq${fastqCounter}_download"
    # in prepareSampleForCCanalyser.sh this file will be in $(pwd), while download in progress :
    # ${downloadLogBasename}_inProgress.log
    # i.e. $(pwd)/fastq${fastqCounter}_download_inProgress.log
    
    cdCommand='cd fastq_${fastqCounter}'
    cdToThis="fastq_${fastqCounter}"
    checkCdSafety
    tempHere=$(pwd)
    cd fastq_${fastqCounter}
    
    echo ${CaptureParallelPath}/prepareSampleForCCanalyser.sh ${downloadLogBasename} ${JustNowFile}_${fastqCounter}.log > prepareFastqs.sh
    chmod u+x prepareFastqs.sh
    
    echo ${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${oligofile} --R1 READ1.fastq --R2 READ2.fastq --parallel 1 --parallelSubsample fastq_${fastqCounter} --${REenzymeShort} --pf ${publicfolder} --monitorRunLogFile ${JustNowFile}_${fastqCounter}.log ${parameterList}  > runFastqs.sh
    chmod u+x runFastqs.sh 
    
    echo 
    echo '_______________________________________' >> ../fastqrunfolderPrepare.log
    echo "fastq_${fastqCounter} in folder $(pwd)" >> ../fastqrunfolderPrepare.log    
    echo >> ../fastqrunfolderPrepare.log
    echo "Generated run commands : " >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    echo "prepareFastqs.sh -----------------------" >> ../fastqrunfolderPrepare.log
    cat prepareFastqs.sh >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    echo "runFastqs.sh ---------------------------" >> ../fastqrunfolderPrepare.log
    cat runFastqs.sh >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    
    # Wholenodequeue needs only one copy - and it can already be copied there, as this runs with ONE qsub job only
    # and parallelises "manually" to 24 processes
    if [ "${useWholenodeQueue}" -eq 1 ]; then

        tempHereWeAre="$(pwd)/"

        # Normal user case : using tmpdir.
        if [ "${useTMPDIRforThis}" -eq 1 ]; then
        cd $TMPDIR
        # not using tmpdir - for testing purposes only.    
        else
        echo "Using wholenode queue WITHOUT tmpdir : testing purposes only ! "
        cd ..
        fi
        
        # If we didn't do this already (i.e. if we are the first fastq to be prepared)
        if [ ! -d A_commonForAll ]; then
            mkdir A_commonForAll
            cd A_commonForAll
            cp ${reGenomeFilePath} .
            cp ${reBlacklistFilePath} .
            cp ${reWhitelistFilePath} .
        else
            cd A_commonForAll
        fi
        
        pwd >> ${tempHereWeAre}../fastqrunfolderPrepare.log
        ls -lht >> ${tempHereWeAre}../fastqrunfolderPrepare.log
        
        cdCommand='cd ${tempHereWeAre} in making A_commonForAll in TMPDIR'
        cdToThis="${tempHereWeAre}"
        checkCdSafety
        cd ${tempHereWeAre}
        pwd >> ../fastqrunfolderPrepare.log
        
        
    # Task-job gets symlinks to each file - in each fastq.
    # Also making the runtime TMPDIR monitoring script
    else
        ln -s ${reGenomeFilePath} .
        ln -s ${reBlacklistFilePath} .
        ln -s ${reWhitelistFilePath} .
        
        if [ "${useTMPDIRforThis}" -eq 1 ];then
        # TMPDIR memory usage ETERNAL loop into here, as cannot be done outside the node ..
        echo 'while [ 1 == 1 ]; do' > tmpdirMemoryasker.sh
        echo 'du -sm ${2} | cut -f 1 > ${3}runJustNow_${1}.log.tmpdir' >> tmpdirMemoryasker.sh                
        echo 'sleep 60' >> tmpdirMemoryasker.sh
        echo 'done' >> tmpdirMemoryasker.sh
        echo  >> tmpdirMemoryasker.sh
        chmod u+x ./tmpdirMemoryasker.sh        
        fi

    fi

    cp ${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh .
    chmod u+x echoer_for_SunGridEngine_environment.sh
    ls -lht >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    
    fastqCounter=$((${fastqCounter}+1))
    cdCommand='cd ${tempHere}'
    cdToThis="${tempHere}"
    checkCdSafety
    cd ${tempHere}

    }
    done

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}
    
}

checkBamcombineErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cdCommand='cd ${checkBamsOfThisDir}'
cdToThis="${checkBamsOfThisDir}"
checkCdSafety  
cd ${checkBamsOfThisDir}

# Check that no errors.

rm -f bamcombineSuccess.log
for file in */*/bamcombineSuccess.log
do
    
    thisOligoName=$( basename $( dirname ${file} ))
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    thisChr=$( basename  $( dirname $( dirname ${file} )))
    checkThis="${thisChr}"
    checkedName='${thisChr}'
    checkParse
    echo -en "${thisChr}_${thisOligoName}\t" >> bamcombineSuccess.log    
    cat $file >> bamcombineSuccess.log

done

howManyErrors=$(($( cat bamcombineSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some oligo bunches in ${checkBamsOfThisDir} crashed during the combining process ( possibly quota issues ? )."
  printNewChapterToLogFile
  
  echo "These oligo bunches had errors :"
  echo
  cat bamcombineSuccess.log | grep -v '^#' | grep -v '\s1$'
  echo

  cat bamcombineSuccess.log | grep -v '^#' | grep -v '\s1$' >> failedBamcombineList.log
  
  printThis="Check which samples failed, and why : $(pwd)/failedBamcombineList.log ! "
  printToLogFile
  printThis="Detailed rerun instructions (to rescue failed fastqs and restart the run) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All bams of ${checkBamsOfThisDir} were combined ! - moving to bam-wise analysis steps .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

checkBamprepcombineErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cdCommand='cd ${checkBamsOfThisDir}'
cdToThis="${checkBamsOfThisDir}"
checkCdSafety  
cd ${checkBamsOfThisDir}

# Check that no errors.

howManyErrors=$(($( cat bamcombineprepSuccess.log | grep -v '^#' | cut -f 2 | grep -cv '^1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Couldn't prepare some oligo bunches in ${checkBamsOfThisDir} for the bam combining."
  printNewChapterToLogFile
  
  echo "These oligo bunches had errors :"
  echo
  cat bamcombineprepSuccess.log | grep -v '^#' | grep -v '\s1\s'
  echo

  cat bamcombineprepSuccess.log | grep -v '^#' | grep -v '\s1\s' >> failedBamcombineprepList.log
  
  printThis="Check which samples failed, and why : $(pwd)/failedBamcombineprepList.log ! "
  printToLogFile
  printThis="Detailed rerun instructions (to rescue failed fastqs and restart the run) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All bamcombining preparations of ${checkBamsOfThisDir} were made ! - moving to actually combining the bam files .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

bamCombineInnerSub(){

    echo "thisChr/thisOligoName ${thisChr}/${thisOligoName}"
    echo "firstflashedfile ${firstflashedfile}"
    echo "firstnonflashedfile ${firstnonflashedfile}"
    echo "inputbamstringFlashed ${inputbamstringFlashed}"
    echo "inputbamstringNonflashed ${inputbamstringNonflashed}"
    echo "outputbamsfolder ${outputbamsfolder}"
    echo "outputlogsfolder ${outputlogsfolder}"
    
    echo "ls -lht ${inputbamstringFlashed} > ${outputlogsfolder}/logfiles/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt"
    ls -lht ${inputbamstringFlashed} > ${outputlogsfolder}/logfiles/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt
    TEMPfine=$?
    echo "ls -lht ${inputbamstringNonflashed} > ${outputlogsfolder}/logfiles/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt"
    ls -lht ${inputbamstringNonflashed} > ${outputlogsfolder}/logfiles/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt
    TEMPfine2=$?
    if [ "${TEMPfine}" -ne 0 ] && [ "${TEMPfine2}" -ne 0 ];then thisBunchIsFine=0;fi

    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ] ; then {
     echo -e "\t0\tcannot_find_files_in_ls" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi  
    
    if [ "${thisBunchIsFine}" -eq 1 ]; then
    {
    samtools view -H ${firstflashedfile} > ${outputbamsfolder}/TEMP_FLASHED.head 2> TEMP.err
    # The above is necessary, as samtools/1.3 does not give output status 1 if it fails. But it writes to error stream, so using that instead.
    if [ $? != 0 ] || [ -s TEMP.err ]; then
        thisBunchIsFine=0
        cat TEMP.err >> "/dev/stderr" 
    fi
    rm -f TEMP.err
    
    samtools view -H ${firstnonflashedfile} > ${outputbamsfolder}/TEMP_NONFLASHED.head 2> TEMP.err
    if [ $? != 0 ] || [ -s TEMP.err ]; then
        thisBunchIsFine=0
        cat TEMP.err >> "/dev/stderr"
    fi
    rm -f TEMP.err
    }
    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\tcannot_make_sam_headers" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi    
    
    if [ "${thisBunchIsFine}" -eq 1 ]; then
    {
    echo "echo Read counts" > ${outputbamsfolder}/bamCombineRun.sh    
    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo "TEMPcountFtotal=0" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "for tempfile in ${inputbamstringFlashed}" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "do" >> ${outputbamsfolder}/bamCombineRun.sh    
    echo 'TEMPcountF=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ -s "${tempfile}" ]; then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountF=$( samtools view -c ${tempfile} )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountFtotal=$((${TEMPcountFtotal}+${TEMPcountF}))' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcountF}\t${tempfile}" >> '$(cd ${outputlogsfolder};pwd)"/logfiles/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh    
    echo 'echo ${TEMPcountF} >> FLASHEDbamINcounts.txt' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "done" >> ${outputbamsfolder}/bamCombineRun.sh

    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo "TEMPcountNFtotal=0" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "for tempfile in ${inputbamstringNonflashed}" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "do" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountNF=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ -s "${tempfile}" ]; then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountNF=$( samtools view -c ${tempfile} )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountNFtotal=$((${TEMPcountNFtotal}+${TEMPcountNF}))' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcountNF}\t${tempfile}" >> '$(cd ${outputlogsfolder};pwd)"/logfiles/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo ${TEMPcountNF} >> NONFLASHEDbamINcounts.txt' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "done" >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo "echo Samtools cat" >> ${outputbamsfolder}/bamCombineRun.sh
    echo  >> ${outputbamsfolder}/bamCombineRun.sh

    # Flashed - if we have bams ..
    echo 'if [ "${TEMPcountFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "date" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "samtools cat -h TEMP_FLASHED.head ${inputbamstringFlashed} > FLASHED_REdig.bam 2> samtoolsCat.err" >> ${outputbamsfolder}/bamCombineRun.sh 
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    # Nonflashed - if we have bams ..
    echo 'if [ "${TEMPcountNFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "date" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "samtools cat -h TEMP_NONFLASHED.head ${inputbamstringNonflashed} > NONFLASHED_REdig.bam 2>> samtoolsCat.err" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    echo  >> ${outputbamsfolder}/bamCombineRun.sh

    # Counts ..
    echo 'TEMPcount=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ "${TEMPcountFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcount=$( samtools view -c FLASHED_REdig.bam )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcount}\t"$(pwd)"/FLASHED_REdig.bam" >> '$(cd ${outputlogsfolder};pwd)"/logfiles/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    echo 'echo ${TEMPcount} >> FLASHEDbamOUTcount.txt' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcount=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ "${TEMPcountNFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcount=$( samtools view -c NONFLASHED_REdig.bam )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcount}\t"$(pwd)"/NONFLASHED_REdig.bam" >> '$(cd ${outputlogsfolder};pwd)"/logfiles/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    echo 'echo ${TEMPcount} >> NONFLASHEDbamOUTcount.txt' >> ${outputbamsfolder}/bamCombineRun.sh

    if [ ! -s ${outputbamsfolder}/bamCombineRun.sh ]; then thisBunchIsFine=0;fi
    
    }    
    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\trunscript_generation_failed" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    chmod u+x ${outputbamsfolder}/bamCombineRun.sh
    if [ $? != 0 ]; then
        thisBunchIsFine=0
    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\trunscript_chmod_failed" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    if [ "${thisBunchIsFine}" -eq 1 ];then
     rm -f TEMP_FLASHED.head TEMP_NONFLASHED.head
     echo -e "\t1\tbamCombinePrep_succeeded" >> ${outputlogsfolder}/bamcombineprepSuccess.log
    fi
    
    cp ${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh ${outputbamsfolder}/.
    chmod u+x ${outputbamsfolder}/echoer_for_SunGridEngine_environment.sh

    
}

bamCombineChecksSaveThisForFuturePurposes(){
    
    ls -lht ${outputbamsfolder}/FLASHED_REdig.bam
    if [ $? != 0 ]; then thisBunchIsFine=0;fi
    # ls -lht ${outputbamsfolder}/NONFLASHED_REdig.bam
    if [ $? != 0 ]; then thisBunchIsFine=0;fi

    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\tsamtools_cat_output_bams_dont_exist" >> ${outputlogsfolder}/bamcombineSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    if [ ! -s "${outputbamsfolder}/FLASHED_REdig.bam" ]
    then thisBunchIsFine=0;fi
    if [ ! -s "${outputbamsfolder}/NONFLASHED_REdig.bam" ]
    then thisBunchIsFine=0;fi
    
    if [ "${thisBunchAlreadyReportedFailure}" -eq 0 ];then
    
    if [ "${thisBunchIsFine}" -eq 0 ]; then
    {
     echo -e "\t0\tsamtools_cat_output_bams_are_empty_files" >> ${outputlogsfolder}/bamcombineSuccess.log
    }
    else
    {
     echo -en "\t1\tbamCombine_succeeded" >> ${outputlogsfolder}/bamcombineSuccess.log
     
     TEMPflashedCount=$( samtools view -c ${outputbamsfolder}/FLASHED_REdig.bam )
     TEMPnonflashedCount=$( samtools view -c ${outputbamsfolder}/NONFLASHED_REdig.bam )
     
     echo -e "\tFlashedreadCount:${TEMPflashedCount}\tNonflashedreadCount:${TEMPnonflashedCount}" >> ${outputlogsfolder}/bamcombineSuccess.log
     
     # Globin combining doesn't get the very detailed counters - so asking if detailed counters folder exists ..
     if [ -d  logfiles ];then
     echo -e "Combined count :\t${TEMPflashedCount}" >> logfiles/bamlisting_FLASHED_chr${thisOligoName}.txt
     echo -e "Combined count :\t${TEMPnonflashedCount}" >> logfiles/bamlisting_NONFLASHED_chr${thisOligoName}.txt
     fi 
     
    }
    fi
    
    fi
    
}

bamCombinePrepareRun(){

# ------------------------------------------

weWereHereDir=$(pwd)
cd C_combineOligoWise

echo "# Bam combine - preparing for run - 1 (prepare finished without errors) , 0 (prepare finished with errors)" > bamcombineprepSuccess.log

# We are supposed to have oneliner oligo files of structure :
# C_combineOligoWise/chr1/Hba-1/oligoFileOneliner.txt

# Copy over the folder structure - for the log files
mkdir logfiles
cp -r * logfiles/. 2> "/dev/null"
rmdir logfiles/logfiles
rm -f logfiles/bamcombineprepSuccess.log

mkdir runlistings

F1foldername="F1_beforeCCanalyser_${samplename}_${CCversion}"
B_subfolderWhereBamsAre="${F1foldername}/LOOP5_filteredSams"

printThis="B_FOLDER_PATH ${B_FOLDER_PATH}\nB_subfolderWhereBamsAre ${B_subfolderWhereBamsAre}\nF1foldername ${F1foldername}"
printToLogFile

oligofileCount=1
for oligoFolder in chr*/*
do
{
    printThis="${oligoFolder}"
    printToLogFile
    thisOligoName=$( basename ${oligoFolder} )
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    thisChr=$( dirname ${oligoFolder} )
    checkThis="${thisChr}"
    checkedName='${thisChr}'
    checkParse
    echo -n "${thisChr}_${thisOligoName}" >> bamcombineprepSuccess.log
    thisBunchIsFine=1
    thisBunchAlreadyReportedFailure=0
    
    inputbamstringFlashed="${B_FOLDER_PATH}/fastq_*/${B_subfolderWhereBamsAre}/${thisChr}/FLASHED_${thisOligoName}_possibleCaptures.bam"
    inputbamstringNonflashed="${B_FOLDER_PATH}/fastq_*/${B_subfolderWhereBamsAre}/${thisChr}/NONFLASHED_${thisOligoName}_possibleCaptures.bam"
    firstflashedfile=$( ls -1 ${inputbamstringFlashed} | head -n 1 )
    firstnonflashedfile=$( ls -1 ${inputbamstringNonflashed} | head -n 1 )
    outputbamsfolder="${thisChr}/${thisOligoName}"
    outputlogsfolder="."
    
    bamCombineInnerSub
    
    # Run list update
    echo "${thisChr}/${thisOligoName}" >> runlist.txt
    echo "${thisChr}/${thisOligoName}" > runlistings/oligo${oligofileCount}.txt
    
    oligofileCount=$((${oligofileCount}+1))

}
done

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

checkParallelCCanalyserErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd D_analyseOligoWise

# Check that no errors.

rm -f oligoRoundSuccess.log
for file in */*/oligoRoundSuccess.log
do
    
    thisOligoName=$( basename $( dirname ${file} ))
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    thisChr=$( basename  $( dirname $( dirname ${file} )))
    checkThis="${thisChr}"
    checkedName='${thisChr}'
    checkParse
    echo -en "${thisChr}_${thisOligoName}\t" >> oligoRoundSuccess.log 
    cat $file >> oligoRoundSuccess.log

done

howManyErrors=$(($( cat oligoRoundSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some CC runs crashed ."
  printNewChapterToLogFile
  
  echo "These oligo bunches had problems in blat :"
  echo
  cat oligoRoundSuccess.log | grep -v '^#' | grep -v '\s1$'
  echo
  
  cat oligoRoundSuccess.log | grep -v '^#' | grep -v '\s1$' > failedOligorunsList.log
  
  printThis="Check which oligo bunches failed, and why : $(pwd)/failedOligorunsList.log ! "
  printToLogFile
  printThis="Detailed rerun instructions : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All oligo-bunch-wise runs finished - moving on .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

prepareParallelCCanalyserRun(){
# ------------------------------------------    

BLAT_FOLDER_PREFIX=$(pwd)"/BLAT/reuseblatFolder"
F1foldername="F1_beforeCCanalyser_${samplename}_${CCversion}"

# Copying the existing structure ..

rm -rf D_analyseOligoWise
mkdir D_analyseOligoWise
mkdir D_analyseOligoWise/runlistings
mkdir D_analyserOligoWise/


oligofileCount=1
weSawGlobins=0
for file in $(pwd)/C_combineOligoWise/*/*/oligoFileOneliner.txt 
do
    printThis="$oligofile"
    printToLogFile
    thisOligoName=$( basename $( dirname $file ))
    thisOligoChr=$( basename $( dirname $( dirname $file ))) 
    thisChrFolder=$( dirname $( dirname $file ))
    
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    
    checkThis="${thisOligoChr}"
    checkedName='${thisOligoChr}'
    checkParse
    
    checkThis="${thisChrFolder}"
    checkedName='${thisChrFolder}'
    checkParse
    
    if [ ! -d D_analyseOligoWise/${thisOligoChr} ]; then
        mkdir D_analyseOligoWise/${thisOligoChr}
    fi
    
    # Copy over the folder structure - for the log files
    mkdir -p D_analyseOligoWise/logfiles/${thisOligoChr}/${thisOligoName}
    
    # If we enter the printing loops for this oligo - by default we do, if we already did that globin, we don't.
    wePrepareThisOligo=1
    # If this oligo is globin oligo - by default no.
    thisIsGlobinRound=0
    
    # Hard coding the globin oligos ..    
    if [ "${thisOligoName}" == "Hba-1" ] || [ "${thisOligoName}" == "Hba-2" ]; then
        thisOligoName="HbaCombined"
    elif [ "${thisOligoName}" == "Hbb-b1" ] || [ "${thisOligoName}" == "Hbb-b2" ]; then
        thisOligoName="HbbCombined"
    fi

    # For testing purposes
    echo ${thisOligoName}
    rm -f D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh
    
    # Hard coding the globin captures here ..
    if [ "${thisOligoName}" == "HbaCombined" ] || [ "${thisOligoName}" == "HbbCombined" ]; then
        weSawGlobins=1
        thisIsGlobinRound=1
        
        # We enter these oligos twice, naturally, so doing them only if they aren't there yet ..
        if [ -d D_analyseOligoWise/${thisOligoChr}/${thisOligoName} ];then
            wePrepareThisOligo=0
        fi
    fi
    
    # Doing the globin, if need be ..
    if [ "${thisIsGlobinRound}" -eq 1 ]; then
        if [ "${wePrepareThisOligo}" -eq 1 ]; then 
            
            printThis="Combining globines - preparing ${thisOligoName} for Capture analysis"
            printToLogFile
            
            echo -n "${thisChr}_${thisOligoName}" >> D_analyseOligoWise/bamcombineSuccess.log
            thisBunchIsFine=1
            thisBunchAlreadyReportedFailure=0
            
            mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}
            mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/${F1foldername}        
            
            globin1="UNDEF"
            globin2="UNDEF"
            
            if [ "${thisOligoName}" == "HbaCombined" ]; then
                globin1="Hba-1"
                globin2="Hba-2"                    
            fi    
            if [ "${thisOligoName}" == "HbbCombined" ]; then
                globin1="Hbb-b1"
                globin2="Hbb-b2"                    
            fi                
            
            # Oligo list - hard coding the globin captures here  ..
            cat ${thisChrFolder}/${globin1}/oligoFileOneliner.txt ${thisChrFolder}/${globin2}/oligoFileOneliner.txt > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/oligoFileOneliner.txt
            # Exclusion list - hard coding the globin captures here  ..
            cat  A_prepareForRun/OLIGOFILE/oligofile_sorted.txt | grep -v '^'${globin1}'\s' | grep -v '^'${globin2}'\s' > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/exclusions.txt
            
            # Catenating the globins to single file ..
            
            if [ ! -d  D_analyseOligoWise/runlistings ]; then mkdir D_analyseOligoWise/runlistings; fi
            
            firstflashedfile="${thisChrFolder}/${globin1}/FLASHED_REdig.bam"
            firstnonflashedfile="${thisChrFolder}/${globin1}/NONFLASHED_REdig.bam"
            inputbamstringFlashed="${thisChrFolder}/${globin1}/FLASHED_REdig.bam ${thisChrFolder}/${globin2}/FLASHED_REdig.bam"
            inputbamstringNonflashed="${thisChrFolder}/${globin1}/NONFLASHED_REdig.bam ${thisChrFolder}/${globin2}/NONFLASHED_REdig.bam"
            outputbamsfolder="D_analyseOligoWise/${thisOligoChr}/${thisOligoName}"
            outputlogsfolder="D_analyseOligoWise"
            
            bamCombineInnerSub
            
            # Run list update (in here this is for log purposes only - not used in the run below)
            echo "${thisOligoChr}/${thisOligoName}" >> D_analyseOligoWise/runlist.txt
            
            tempGlobinUpperDir=$(pwd)
            cd D_analyseOligoWise/${thisOligoChr}/${thisOligoName}
            
            printThis="Combining globin BAMS ${globin1} and ${globin2} too become ${thisOligoName}"
            printToLogFile 
            
            # The below are copied from oneBamcombineWholenodeWorkdir.sh
            echo "bam combining started : $(date)"
              
              fCount=0
              nfCount=0
              runOK=1
              ./bamCombineRun.sh
              if [ $? != 0 ] || [ -s samtoolsCat.err ]; then
              {
                runOK=0    
        
                printThis="Bam-combining failed ! "
                printToLogFile
                
              }
              else
              {
                rm -r TEMP_FLASHED.head TEMP_NONFLASHED.head
                fCount=$(cat FLASHEDbamOUTcount.txt)
                nfCount=$(cat NONFLASHEDbamOUTcount.txt)
              }
              fi  
        
            if [ -s samtoolsCat.err ]; then
                printThis="This was samtools cat crash : error messages in "$(pwd)/samtoolsCat.err
                printToLogFile
            else
                rm -f samtoolsCat.err
            fi
            
            doQuotaTesting
            
            mkdir ${F1foldername}
            mv FLASHED_REdig.bam ${F1foldername}/.
            mv NONFLASHED_REdig.bam ${F1foldername}/.
            
            printThis="FLASHEDcount ${fCount} NONFLASHEDcount ${nfCount} runOK ${runOK}"
            printToLogFile
            echo "FLASHEDcount ${fCount} NONFLASHEDcount ${nfCount} runOK ${runOK}" > bamcombineSuccess.log
            
            cdCommand="cd ${tempGlobinUpperDir}"
            cdToThis="${tempGlobinUpperDir}"
            checkCdSafety
            cd ${tempGlobinUpperDir}
         
        fi
        
    else
        # Normal captures (no globins)
        mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}
        mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/${F1foldername} 
        # Oligo itself ..
        cp $file D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.
        # Exclusion list - all but the actual oligo itself ..
        cat  A_prepareForRun/OLIGOFILE/oligofile_sorted.txt | grep -v '^'${thisOligoName}'\s' > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/exclusions.txt
        
        # Not using symlinks - as the mainrunner.sh code will meddle with these files - and thus making restarts potentially quite hard to troubleshoot
        # ln -s ../../../../C_combineOligoWise/${thisOligoChr}/${thisOligoName}/${F1foldername} D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.
        
        # True copy of the bams is made only run-time (to avoid messing up symlinked bams if something goes wrong, and avoid memory peaks before they are needed
        # - this results in saving the bams essentially twice, once in C folder, once in D folder - but for the time being keeping it like it is as assuming a lot of restart needs )
        echo "cp -r $(pwd)/C_combineOligoWise/${thisOligoChr}/${thisOligoName}/*.bam ${F1foldername}/." > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh
        
    fi
    
    # All runs (globins or not)
    
    if [ "${wePrepareThisOligo}" -eq 1 ]; then
    
    # lister ..
    cp ${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.
    chmod u+x D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/echoer_for_SunGridEngine_environment.sh
    
    # RE fragments ..
    ln -s ${reGenomeFilePath} D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.        
    
    # All runs (globins or not) - get the same run.sh - except normal oligos get the copy of the F1 folder, but globins already have true copy so don't need this.
    JustNowFile=$(pwd)/D_analyseOligoWise/runJustNow
    
    echo "${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --parallel 2 --BLATforREUSEfolderPath ${BLAT_FOLDER_PREFIX} --pf ${publicfolder}/bunchWise/bunch_${thisOligoName} --monitorRunLogFile ${JustNowFile}_${oligofileCount}.log ${parameterList} "
    echo "${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --parallel 2 --BLATforREUSEfolderPath ${BLAT_FOLDER_PREFIX} --pf ${publicfolder}/bunchWise/bunch_${thisOligoName} --monitorRunLogFile ${JustNowFile}_${oligofileCount}.log ${parameterList}" >> D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh
    
    chmod u+x D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh

    # Run list update
    echo "${thisOligoChr}/${thisOligoName}" >> D_analyseOligoWise/runlist.txt
    echo "${thisOligoChr}/${thisOligoName}" >> D_analyseOligoWise/runlistings/oligo${oligofileCount}.txt
    oligofileCount=$((${oligofileCount}+1))
    
    # If we go thread-wise in TMPDIR, we need to monitor the memory inside there ..
    if [ "${useWholenodeQueue}" -eq 0 ] &&[ "${useTMPDIRforThis}" -eq 1 ];then
        # TMPDIR memory usage ETERNAL loop into here, as cannot be done outside the node ..
        echo 'while [ 1 == 1 ]; do' > tmpdirMemoryasker.sh
        echo 'du -sm ${2} | cut -f 1 > ${3}runJustNow_${1}.log.tmpdir' >> tmpdirMemoryasker.sh                
        echo 'sleep 60' >> tmpdirMemoryasker.sh
        echo 'done' >> tmpdirMemoryasker.sh
        echo  >> tmpdirMemoryasker.sh
        chmod u+x ./tmpdirMemoryasker.sh  
    fi
    
    fi
    
    
done

# If we had globins in design, now checking that those got combined no problem ..

if [ "${weSawGlobins}" -eq 1 ]; then

checkBamsOfThisDir="D_analyseOligoWise"
checkBamcombineErrors

fi

# ------------------------------------------    
}

prepareBlatFolder(){

printThis="Preparing BLAT folder .. "
printToLogFile

if [ -e BLAT ]; then
    printThis="Found existing BLAT folder. Refusing to overwrite. "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1  
fi

mkdir BLAT

# If we have previous blats.
if [ "${isReuseBlatPathGiven}" -eq 1 ]; then

# ls ${reuseblatpath}
if [ $? -ne 0 ];then
    printThis="Cannot find the BLAT results folder --BLATforREUSEfolderPath ${reuseblatpath} . Check your run command ! "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi

pslFilesFound=$(($( ls ${reuseblatpath} | grep -c psl )))
if [ "${pslFilesFound}" -eq 0 ];then
    printThis="No .psl files found in the BLAT results folder --BLATforREUSEfolderPath ${reuseblatpath} . Check your run REUSE_blat folder ! "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi

ln -s ${reuseblatpath} BLAT/reuseblatFolder
ls -l BLAT | grep reuseblatFolder

fi

# ------------------------------

# Here we would do blat - but that is wishful thinking, as very impractical,
# so forcing people to provide blat paths ..

if [ "${isReuseBlatPathGiven}" -eq 0 ] && [ "${onlyblat}" -eq 0 ]; then

printThis="Reuse blat paths were not given - exiting ! ( parallel runs have to have --BLATforREUSEfolderPath set )"
printToLogFile
printThis="Generate the REUSEfolder by using --onlyBlat in your run command"
printToLogFile

exit 1

fi

# ------------------------------

# If we have previous blats, and we are not to generate more (i.e. normal run not BLAT only run)

if [ "${isReuseBlatPathGiven}" -eq 1 ] && [ "${onlyblat}" -eq 0 ]; then

oligofileCount=0
blatwarningsCount=0
blatwarningOligoList=""
for file in A_prepareForRun/OLIGOSindividualFiles/*/*/oligoFileOneliner.txt 
do
    oligofileCount=$((${fastqCount}+1))
    
    thisOligoName=$( basename $( dirname $file ))
    thisOligoChr=$( basename $( dirname $( dirname $file ))) 

    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse

    checkThis="${thisOligoChr}"
    checkedName='${thisOligoChr}'
    checkParse
    
    ls BLAT/reuseblatFolder | grep TEMP_${thisOligoName}_blat.psl >> "/dev/null"
    if [ $? -ne 0 ];then
        blatwarningsCount=$((${blatwarningsCount}+1))
        blatwarningOligoList="${blatwarningOligoList} ${thisOligoChr}/${thisOligoName}"
    fi
    
done

if [ "${blatwarningsCount}" -eq "${pslFilesFound}" ];then
    printThis="None of the oligos had .psl files in the BLAT results folder --BLATforREUSEfolderPath ${reuseblatpath} . Maybe you are using wrong REUSE_blat folder ? "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi
if [ "${blatwarningsCount}" -ne 0 ];then
    printThis="EXITING : ${blatwarningsCount} of the oligos didn't have BLAT results .psl file in folder --BLATforREUSEfolderPath ${reuseblatpath} . \t(Even no-homology-regions generates heading lines into the .psl file - assuming failed or missing BLAT run). "
    printToLogFile
    printThis="The psl files in the folder need to be named like this : TEMP_{thisOligoName}_blat.psl \nwhere {thisOligoName} is the oligo name from the oligo file"
    printToLogFile
    printThis="List of the missing oligos below : \n ${blatwarningOligoList}"
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi

fi

}

checkBlatErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd BLAT

# Check that no errors.

howManyErrors=$(($( cat blatSuccess.log | grep -v '^#' | cut -f 2 | grep -cv '^1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some blat runs crashed ."
  printNewChapterToLogFile
  
  echo "These oligos had problems in blat :"
  echo
  cat blatSuccess.log | grep -v '^#' | grep -v '\s1\s'
  echo

  head -n 1 failedBlatsList.log > failedBlatsList.log
  cat failedBlatsList.log | grep -v '^#' | grep -v '\s1$' >> failedBlatsList.log
  
  printThis="Check which oligos failed, and why : $(pwd)/failedBlatsList.log ! "
  printToLogFile
  printThis="To rerun only BLAT runs use --onlyBlat"
  printToLogFile
  printThis="Detailed rerun instructions (if you want to continue automatically to folderC and D generation) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All files finished BLAT - moving on .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

blatRun(){
    
# ------------------------------------------
    
step6topdir=$(pwd)

printThis="Starting the BLAT runs .. "
printNewChapterToLogFile

rm -rf BLAT
mkdir BLAT
BLAT_FOLDER="$(pwd)/BLAT"
cd BLAT

step6middir=$(pwd)

echo "# Blat round run statuses - 1 (finished without errors) , 0 (finished with errors)" > blatSuccess.log

for file in ${oligoBunchesFolder}/* 
do   
    printThis="Blat for oligo bunch file $file"
    printToLogFile
    thisOligoName=$( basename $file | sed 's/^oligofile_sorted_chr//' | sed 's/\.txt$//' )
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    
    echo -n "chr${thisOligoName}" >> blatSuccess.log
    thisBunchIsFine=1
    thisBunchAlreadyReportedFailure=0
    
    
    rmCommand='rm -rf oligoBunch_${thisOligoName}'
    rmThis="oligoBunch_${thisOligoName}"
    checkRemoveSafety
    rm -rf oligoBunch_${thisOligoName}
    mkdir oligoBunch_${thisOligoName}
    
    cdCommand='cd oligoBunch_${thisOligoName}'
    cdToThis="oligoBunch_${thisOligoName}"
    checkCdSafety
    cd oligoBunch_${thisOligoName}
    
    ln -s ${reGenomeFilePath} .
    if [ $? != 0 ]; then thisBunchIsFine=0;fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\tcannot_symlink_REgenome_file" >> blatSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    printThis="${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --onlyBlat --BLATforREUSEfolderPath ${reuseblatpath} --pf ${publicfolder}/bunchWise ${parameterList} --outfile runBLAT.out --errfile runBLAT.err"
    printToLogFile
    printThis="You can follow the run progress from error and out files :\nBLAT/oligoBunch_${thisOligoName}/runBLAT.out\nBLAT/oligoBunch_${thisOligoName}/runBLAT.err"
    printToLogFile
    ${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --onlyBlat --BLATforREUSEfolderPath ${reuseblatpath} --pf ${publicfolder}/bunchWise ${parameterList} --outfile runBLAT.out --errfile runBLAT.err 1> runBLAT.out 2> runBLAT.err
    if [ $? != 0 ]; then thisBunchIsFine=0;fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     # Here better parse ? - should make the filter.sh to report a little better to a log file which we can parse here ..
     echo -e "\t0\tfilter.sh_run_crashed" >> blatSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    if [ "${thisBunchAlreadyReportedFailure}" -eq 0 ];then
    
    if [ "${thisBunchIsFine}" -eq 0 ]; then
    {
     echo -e "\t0\tblatting_failed_sorryDidntCatchTheReason_checkOutputErrorLogs" >> blatSuccess.log
    }
    else
    {
     echo -e "\t1\tblatting_succeeded" >> blatSuccess.log
    }
    fi  

    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ]; then
      printThis="Blat filter generation failed for oligo bunch ${thisOligoName} ! "
      printToLogFile
        
      # Print some mainrunner error messages here ..
      cat runBLAT.err | grep -v '^\s*$' | grep -B 1 EXITING >&2
      cat runBLAT.err | grep 'refusing to overwrite' >&2

      cat runBLAT.err | grep -v '^\s*$' | grep -B 1 EXITING
      cat runBLAT.err | grep 'refusing to overwrite'
       
      printThis="More details of the crash in file : $(pwd)/runBLAT.err"
      printToLogFile
     
    fi
    
    cdCommand='cd ${step6middir}'
    cdToThis="${step6middir}"
    checkCdSafety  
    cd ${step6middir}
done
cdCommand='cd ${step6topdir}'
cdToThis="${step6topdir}"
checkCdSafety  
cd ${step6topdir}
    
# ------------------------------------------    
}
