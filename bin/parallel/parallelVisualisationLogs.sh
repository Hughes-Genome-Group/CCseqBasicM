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

combineCounts(){
    
# needs these 2 input files :
# fastqwise_counts.txt
# oligobunchqwise_counts.txt
   
echo
echo "Will count stuff in unix calculator bc :"
bc --version
bc limits
echo

# Below sub oneSumCount parses the file, and saves the sum into sum_of_all_counts.txt

rm -f sum_of_all_counts.txt 

countfile="fastqwise_counts.txt"

word="all"
oneSumCount

word="allflashed"
oneSumCount

word="allnonflashed"
oneSumCount

word="REflashed"
oneSumCount

word="REnonflashed"
oneSumCount

word="continuesToMappingFlashed"
oneSumCount

word="continuesToMappingNonflashed"
oneSumCount

word="containsCaptureFlashed"
oneSumCount

word="containsCaptureNonflashed"
oneSumCount

word="containsCapAndRepFlashed"
oneSumCount

word="containsCapAndRepNonflashed"
oneSumCount

word="singleCapFlashed"
oneSumCount

word="singleCapNonflashed"
oneSumCount

word="multiCapFlashed"
oneSumCount

word="multiCapNonflashed"
oneSumCount


# countfile="oligobunchqwise_counts.txt"

# word="nonduplicateFlashed"
# oneSumCount

# word="nonduplicateNonflashed"
# oneSumCount

# word="blatploidyFlashed"
# oneSumCount

# word="blatploidyNonflashed"
# oneSumCount

    
}

# ------------------------------------------

oneSumCount(){

  # From bc help page in
  # https://www.gnu.org/software/bc/manual/html_mono/bc.html
  # pi=$(echo "scale=10; 4*a(1)" | bc -l)
  
  echo "cat ${countfile} | grep '^'${word}'=' | sed 's/'${word}'=//' | tr '\n' '+' | sed 's/+$/\n/' | bc -l | sed 's/^/'${word}'=/'"
  cat ${countfile} | grep '^'${word}'=' | sed 's/'${word}'=//' | tr '\n' '+' | sed 's/+$/\n/'  | bc -l | sed 's/^/'${word}'=/' >> sum_of_all_counts.txt
}

# ------------------------------------------

echo "Parallel visualisation log file generation - by Jelena Telenius, 26/02/2018"
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
echo "parallelVisualisationLogs.sh" $@
echo

parameterList=$@

# -----------------------------------------

PublicPath="$1"
Sample="$2"
CCversion="$3"
REenzyme="$4"
GENOME="$5"
TILED="$6"
B_FOLDER_BASENAME="$7"
C_FOLDER_BASENAME="$8"
OligoFile="$9"

PublicPath="${PublicPath}/${Sample}/${CCversion}_${REenzyme}"

# To follow the naming in hubber.sh :
publicPathForCCanalyser="${PublicPath}"
sampleForCCanalyser="${Sample}"
genomeName=${GENOME}

# Relative paths to log files
ServerAndPath="."

# -----------------------------------------

RunScriptsPath="$( echo $0 | sed 's/\/parallelVisualisation.sh$//' )"
CapturePipePath="$( dirname $( dirname $(echo ${RunScriptsPath}) ))"
CaptureCommonHelpersPath="${CapturePipePath}/commonSubroutines"
CapturePlotPath="${CaptureCommonHelpersPath}/drawFigure"

# From where to call the CONFIGURATION script..
confFolder=$( dirname ${CapturePipePath} )"/conf"

#------------------------------------------

echo
echo "CapturePipePath ${CapturePipePath}"
echo "confFolder ${confFolder}"
echo "CaptureCommonHelpersPath ${CaptureCommonHelpersPath}"
echo "RunScriptsPath ${RunScriptsPath}"
echo "CapturePlotPath ${CapturePlotPath}"
echo

echo "( PublicPath ${PublicPath} )"
echo "( Sample ${Sample} )( CCversion ${CCversion} )( REenzyme ${REenzyme} )( genomeName ${genomeName} )"
echo "( TILED ${TILED} )( B_FOLDER_BASENAME ${B_FOLDER_BASENAME} )( C_FOLDER_BASENAME ${C_FOLDER_BASENAME} )"
echo "( OligoFile ${OligoFile} )"

echo

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# HUBBING subroutines
. ${CaptureCommonHelpersPath}/hubbers.sh

# TESTING file existence, log file output general messages

. ${CaptureCommonHelpersPath}/testers_and_loggers.sh

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

printThis="Testing the tester subroutines .."
printToLogFile
printThis="${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err"
printToLogFile
   
${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err
# The above exits if any of the tests don't work properly.

# The below exits if the logger test sub wasn't found (path above wrong or file not found)
if [ "$?" -ne 0 ]; then
    printThis="Testing testers_and_loggers.sh safety routines failed. Cannot continue without testing safety features ! \n EXITING !! "
    printToLogFile
    exit 1
else
    printThis="Testing the tester subroutines completed - continuing ! "
    printToLogFile
fi

# Comment this out, if you want to save these files :
rm -f testers_and_loggers_test.out testers_and_loggers_test.err

#------------------------------------------

. ${confFolder}/loadNeededTools.sh

setPathsForPipe

echo "Calling in the conf/serverAddressAndPublicDiskSetup.sh script and its default setup .."

SERVERTYPE="UNDEFINED"
SERVERADDRESS="UNDEFINED"
REMOVEfromPUBLICFILEPATH="NOTHING"
ADDtoPUBLICFILEPATH="NOTHING"
tobeREPLACEDinPUBLICFILEPATH="NOTHING"
REPLACEwithThisInPUBLICFILEPATH="NOTHING"

. ${confFolder}/serverAddressAndPublicDiskSetup.sh

setPublicLocations

echo
echo "SERVERTYPE ${SERVERTYPE}"
echo "SERVERADDRESS ${SERVERADDRESS}"
echo "ADDtoPUBLICFILEPATH ${ADDtoPUBLICFILEPATH}"
echo "REMOVEfromPUBLICFILEPATH ${REMOVEfromPUBLICFILEPATH}"
echo "tobeREPLACEDinPUBLICFILEPATH ${tobeREPLACEDinPUBLICFILEPATH}"
echo "REPLACEwithThisInPUBLICFILEPATH ${REPLACEwithThisInPUBLICFILEPATH}"
echo

# Here, parsing the data area location, to reach the public are address..
diskFolder=${PublicPath}
serverFolder=""   
echo
parsePublicLocations
echo

tempJamesUrlForPrintingOnly="${SERVERADDRESS}/${serverFolder}"
JamesUrlForPrintingOnly=$( echo ${tempJamesUrlForPrintingOnly} | sed 's/\/\//\//g' )
ServerAndPathForPrintingOnly="${SERVERTYPE}://${JamesUrlForPrintingOnly}"

# We are NOT using the above for many things - only for printing the final server addresses for user.
# we ONLY use relative paths in making the html pages

# ----------------------------------

printThis="Combining the counters."
printNewChapterToLogFile

# ----------------------------------

printThis="Statistics counts, summary figure, description.html  .."
printToLogFile

# --------------------------------
# Make final counters ..

# F1foldername="F1_beforeCCanalyser_${samplename}_${exactCCoutputFolderEnding}"
# B_subfolderWhereBamsAre="${F1foldername}/LOOP5_filteredSams"

echo "cat ../${B_FOLDER_BASENAME}/fastq_*/F2_dividedSams_${Sample}_${CCversion}/FLASHED_REdig_report_${CCversion}.txt | grep '^11e' > TEMP_11eBoth.txt"
cat ../${B_FOLDER_BASENAME}/fastq_*/F2_dividedSams_${Sample}_${CCversion}/FLASHED_REdig_report_${CCversion}.txt | grep '^11e' > TEMP_11eBoth.txt

cat TEMP_11eBoth.txt | grep '^11e\s'  | sed 's/\s:\s\s*/:\t/' | sed 's/\s/./g' | sed 's/:\./:\t/' | sort -k1,1 > TEMP_11e.txt
cat TEMP_11eBoth.txt | grep '^11ee\s' | sed 's/\s:\s\s*/:\t/' | sed 's/\s/./g' | sed 's/:\./:\t/' | sort -k1,1 > TEMP_11ee.txt

cat TEMP_11e.txt | \
awk 'BEGIN{p="UNDEF";s=0}{if($1!=p && p!="UNDEF"){print p"\t"s;s=0 }s=s+$2;p=$1}END{if(s!=0){print p"\t"s}}' | tr '.' ' ' \
> FLASHED_REdig_report11_${CCversion}.txt

cat TEMP_11ee.txt | \
awk 'BEGIN{p="UNDEF";s=0}{if($1!=p && p!="UNDEF"){print p"\t"s;s=0 }s=s+$2;p=$1}END{if(s!=0){print p"\t"s}}' | tr '.' ' ' \
>> FLASHED_REdig_report11_${CCversion}.txt

# for debugging
# mkdir flashed_TEMP11e
# mv TEMP_11e* flashed_TEMP11e/.


# -------------------------------------

echo "cat ../${B_FOLDER_BASENAME}/fastq_*/F2_dividedSams_${Sample}_${CCversion}/NONFLASHED_REdig_report_${CCversion}.txt | grep '^11e' > TEMP_11eBoth.txt"
cat ../${B_FOLDER_BASENAME}/fastq_*/F2_dividedSams_${Sample}_${CCversion}/NONFLASHED_REdig_report_${CCversion}.txt | grep '^11e' > TEMP_11eBoth.txt

cat TEMP_11eBoth.txt | grep '^11e\s'  | sed 's/\s:\s\s*/:\t/' | sed 's/\s/./g' | sed 's/:\./:\t/' | sort -k1,1 > TEMP_11e.txt
cat TEMP_11eBoth.txt | grep '^11ee\s' | sed 's/\s:\s\s*/:\t/' | sed 's/\s/./g' | sed 's/:\./:\t/' | sort -k1,1 > TEMP_11ee.txt

cat TEMP_11e.txt | \
awk 'BEGIN{p="UNDEF";s=0}{if($1!=p && p!="UNDEF"){print p"\t"s;s=0 }s=s+$2;p=$1}END{if(s!=0){print p"\t"s}}' | tr '.' ' ' \
> NONFLASHED_REdig_report11_${CCversion}.txt

cat TEMP_11ee.txt | \
awk 'BEGIN{p="UNDEF";s=0}{if($1!=p && p!="UNDEF"){print p"\t"s;s=0 }s=s+$2;p=$1}END{if(s!=0){print p"\t"s}}' | tr '.' ' ' \
>> NONFLASHED_REdig_report11_${CCversion}.txt

# for debugging
# mkdir nonflashed_TEMP11e
# mv TEMP_11e* nonflashed_TEMP11e/.

rm -f TEMP_11e*

# -------------------------------
# Copy above (and other readymade) files over ..

copyFastqSummaryLogFilesToPublic
copyBamCombiningLogFilesToPublic

# -------------------------------
# Make summary figure ..

# Now we have these folders with the figure counters :

# Fastq-based counts for F1 and F2
# ../${B_FOLDER_BASENAME}/*/F7_summaryFigure_*/counts.py

# Oligo-bunch-based counts for F3, F4, F5, F6
# ../${C_FOLDER_BASENAME}/*/F7_summaryFigure_*/counts.py


echo "cat ../${B_FOLDER_BASENAME}/fastq_*/F7_summaryFigure_${Sample}_${CCversion}/counts.py > fastqwise_counts.txt"
cat ../${B_FOLDER_BASENAME}/fastq_*/F7_summaryFigure_${Sample}_${CCversion}/counts.py > fastqwise_counts.txt

# echo "cat ../${C_FOLDER_BASENAME}/oligoBunch_*/F7_summaryFigure_${Sample}_${CCversion}/counts.py > oligobunchqwise_counts.txt"
# cat ../${C_FOLDER_BASENAME}/bunch_*/F7_summaryFigure_${Sample}_${CCversion}/counts.py > oligobunchqwise_counts.txt

combineCounts
# generates sum_of_all_counts.txt
# which can be used by the visualisation scripts.

mkdir F7_summaryFigure_${Sample}_${CCversion}
moveCommand='mv -f sum_of_all_counts.txt F7_summaryFigure_${Sample}_${CCversion}/counts.py'
moveThis="sum_of_all_counts.txt"
moveToHere="F7_summaryFigure_${Sample}_${CCversion}/counts.py"
checkMoveSafety
# mv -f sum_of_all_counts.txt F7_summaryFigure_${Sample}_${CCversion}/counts.py
cp sum_of_all_counts.txt F7_summaryFigure_${Sample}_${CCversion}/counts.py

countsFromCCanalyserScriptname="countsFromCCanalyserOutput_parallel1.sh"
percentagesFromCountsScriptname="generatePercentages_parallel1.py"

if [[ "${TILED}" -eq "1" ]]; then
    figureFromPercentagesScriptname="drawFigure_parallel1tiled.py"
else
    figureFromPercentagesScriptname="drawFigure_parallel1.py"    
fi


generateSummaryFigure

# -----------------------------
# Collect all above to the description page ..

generateCombinedFastqonlyDescriptionpage
 
printThis="All done with the log files of the Rainbow run !"
printNewChapterToLogFile

updateHub_part3pfinal




