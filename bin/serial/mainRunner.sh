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

copyMainrunnerLogFiles(){
    
# Copying log files

echo "Copying run log files.." >> "/dev/stderr"

if [ ! -d ${PublicPath}/${Sample}_logFiles ]
then
    mkdir -p ${PublicPath}/${Sample}_logFiles
fi

cp -f ${QSUBOUTFILE} "${PublicPath}/${Sample}_logFiles/${Sample}_$(basename ${QSUBOUTFILE})"
cp -f ${QSUBERRFILE} "${PublicPath}/${Sample}_logFiles/${Sample}_$(basename ${QSUBERRFILE})"

echo "Log files copied !" >> "/dev/stderr"
    
}

# The trap below gets overwritten if running via rainbow.
# This is actually quite OK. But this is why the copyMainrunnerLogFiles is above
# (the log files never get copied if inside the trap - as the rainbow script's own trap overwriters this one)
# But, if this is ran without the rainbow, the below trap gets to report normally !
function finishMainRunner {
if [ $? != "0" ]; then
echo
echo "RUN CRASHED ! - check qsub.err to see why !"
echo
echo "If your run passed folder1 (F1) succesfully - i.e. you have F2 or later folders formed correctly - you can restart in same folder, same run.sh :"
echo "Just add --onlyCCanalyser to the end of run command in run.sh, and start the run normally, in the same folder you crashed now (this will overrwrite your run from bowtie output onwards)."
echo
echo "If you are going to rerun a crashed run without using --onlyCCanalyser , copy your run script to a NEW EMPTY FOLDER,"
echo "and remember to delete your malformed /public/ hub-folders (especially the tracks.txt files) to avoid wrongly generated data hubs (if you are going to use same SAMPLE NAME as in the crashed run)" 
echo
echo "Analysis not complete !"
date

else
    

if [ "${parameterList}" != "-h" ] && [ "${parameterList}" != "--help" ]
then
echo "Analysis complete ! $(date)"
fi
rm -f ${JustNowLogFile}
fi

}
trap finishMainRunner EXIT

#------------------------------------------

CCversion="CM5"
captureScript="analyseMappedReads"
CCseqBasicVersion="CCseqBasic5"

CCscriptname="${captureScript}.pl"

# -----------------------------------------

CaptureTopPath="$( echo $0 | sed 's/\/mainRunner.sh$//' )"

CapturePipePath="${CaptureTopPath}/subroutines"

CaptureCommonHelpersPath=$( dirname ${CaptureTopPath} )"/commonSubroutines"

JustNowLogFile=$(pwd)/justNowDoingThis.log

# -----------------------------------------

# Help-only run type ..

if [ $# -eq 1 ]
then
parameterList=$@
if [ ${parameterList} == "-h" ] || [ ${parameterList} == "--help" ]
then
. ${CapturePipePath}/usageAndVersion.sh
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

echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "${CCseqBasicVersion}.sh" $@

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# CREATING default parameters and their values
. ${CapturePipePath}/defaultparams.sh

# SETTING parameter values - subroutines
. ${CapturePipePath}/parametersetters.sh

# HUBBING subroutines
. ${CaptureCommonHelpersPath}/hubbers.sh

# CLEANING folders and organising structures
. ${CapturePipePath}/cleaners.sh

# RUNNING the main tools (flash, ccanalyser, etc..)
. ${CapturePipePath}/runtools.sh

# SETTING THE GENOME BUILD PARAMETERS
. ${CaptureCommonHelpersPath}/genomeSetters.sh

# SETTING THE BLACKLIST GENOME LIST PARAMETERS
. ${CaptureCommonHelpersPath}/blacklistSetters.sh

# PRINTING HELP AND VERSION MESSAGES
. ${CapturePipePath}/usageAndVersion.sh

# DEBUG SUBROUTINES - for the situations all hell breaks loose
# . ${CaptureAnalysisPath}/subroutines/debugHelpers.sh

# TESTING file existence, log file output general messages
. ${CaptureCommonHelpersPath}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found in $0. Cannot continue without safety features turned on ! \n EXITING !! "
    printToLogFile
    exit 1
fi

# -----------------------------------------

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

# From where to call the main scripts operating from the runscripts folder..

RunScriptsPath="${CaptureTopPath}/runscripts"

#------------------------------------------

# From where to call the filtering scripts..
# (blacklisting regions with BLACKLIST pre-made region list, as well as on-the-fly BLAT-hit based "false positive" hits) 

CaptureFilterPath="${RunScriptsPath}/filterArtifactMappers"

#------------------------------------------

# From where to call the python plots..
# (blacklisting regions with BLACKLIST pre-made region list, as well as on-the-fly BLAT-hit based "false positive" hits) 

CapturePlotPath="${CaptureCommonHelpersPath}/drawFigure"

# default counts : all counts. parallel 1 and parallel 2 overwrite this on the fly
countsFromCCanalyserScriptname="countsFromCCanalyserOutput.sh"
# default percentages : all percentages. parallel 1 and parallel 2 overwrite this on the fly
percentagesFromCountsScriptname="generatePercentages.py"
# default figure script : all counts. parallel 1 and parallel 2 overwrite this on the fly
figureFromPercentagesScriptname="drawFigure.py"

#------------------------------------------

# From where to call the CONFIGURATION script..

# confFolder="${CaptureTopPath}/conf"
confFolder=$( dirname $( dirname ${CaptureTopPath} ))"/conf"

#------------------------------------------

echo
echo "CaptureTopPath ${CaptureTopPath}"
echo "CapturePipePath ${CapturePipePath}"
echo "CaptureCommonHelpersPath ${CaptureCommonHelpersPath}"
echo "confFolder ${confFolder}"
echo "RunScriptsPath ${RunScriptsPath}"
echo "CaptureFilterPath ${CaptureFilterPath}"
echo "CapturePlotPath ${CapturePlotPath}"
echo

#------------------------------------------

# Calling in the CONFIGURATION script and its default setup :

# Defaulting this to "not in use" - if it is not set in the config file.
CaptureDigestPath="NOT_IN_USE"

#------------------------------------------

# Calling in the CONFIGURATION script and its default setup :

echo "Calling in the conf/config.sh script and its default setup .."

CaptureDigestPath="NOT_IN_USE"
supportedGenomes=()
BOWTIE1=()
BOWTIE2=()
UCSC=()
BLACKLIST=()
genomesWhichHaveBlacklist=()


# . ${confFolder}/config.sh
. ${confFolder}/genomeBuildSetup.sh
. ${confFolder}/loadNeededTools.sh
. ${confFolder}/serverAddressAndPublicDiskSetup.sh

# setConfigLocations
setPathsForPipe
setGenomeLocations

echo 
echo "Supported genomes : "
for g in $( seq 0 $((${#supportedGenomes[@]}-1)) ); do echo -n "${supportedGenomes[$g]} "; done
echo 
echo

echo 
echo "Blacklist filtering available for these genomes : "
for g in $( seq 0 $((${#genomesWhichHaveBlacklist[@]}-1)) ); do echo -n $( echo ${genomesWhichHaveBlacklist[$g]} | grep -v '^MASKED_GENOME_SHOULD_NOT' )" "; done
echo 
echo

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

#------------------------------------------

OPTS=`getopt -o h,m:,M:,e:,o:,s:,w:,i:,v: --long help,dump,snp,dpn,nla,hind,tiled,strandSpecificDuplicates,onlyCCanalyser,onlyHub,onlyOligoDivision,onlyREdigest,flash,noFlash,onlyCis,onlyBlat,UMI,useSymbolicLinks,useClusterDiskArea,noPloidyFilter,saveGenomeDigest,dontSaveGenomeDigest,trim,noTrim,bowtie1,bowtie2,processors:,CCversion:,BLATforREUSEfolderPath:,globin:,parallelSubsample:,outfile:,errfile:,limit:,pf:,genome:,R1:,R2:,chunkmb:,window:,increment:,ada3read1:,ada3read2:,extend:,qmin:,flashBases:,flashMismatch:,stringent,trim3:,trim5:,seedmms:,seedlen:,maqerr:,stepSize:,tileSize:,minScore:,maxIntron:,oneOff:,wobblyEndBinWidth:,sonicationSize:,parallel:,oligosPerBunch:,monitorRunLogFile: -- "$@"`
if [ $? != 0 ]
then
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -h) usage ; shift;;
        -m) LOWERCASE_M=$2 ; shift 2;;
        -M) CAPITAL_M=$2 ; shift 2;;
        -o) OligoFile=$2 ; shift 2;;
        -e) otherParameters="${otherParameters} -e $2" ; shift 2;;
        -w) WINDOW=$2 ; shift 2;;
        -i) INCREMENT=$2 ; shift 2;;
        -s) Sample=$2 ; shift 2;;
        -v) LOWERCASE_V=$2; shift 2;;
        --help) usage ; shift;;
        --UMI) otherParameters="${otherParameters} --umi" ; shift;;
        --useSymbolicLinks) otherParameters="${otherParameters} --symlinks" ; shift;;
        --CCversion) CCversion="$2"; shift 2;;       
        --dpn) REenzyme="dpnII" ; shift;;
        --nla) REenzyme="nlaIII" ; shift;;
        --hind) REenzyme="hindIII" ; shift;;
        --tiled) TILED=1;otherParameters="${otherParameters} --tiled"; shift;;
        --onlyCCanalyser) ONLY_CC_ANALYSER=1 ; shift;;
        --onlyHub) ONLY_HUB=1 ; shift;;
        --onlyBlat) ONLY_BLAT=1 ; shift;;
        --onlyOligoDivision) ONLY_DIVIDE_OLIGOS=1 ; shift;;
        --onlyREdigest) ONLY_RE_DIGESTS=1 ; shift;;
        --onlyCis) onlyCis=1;otherParameters="${otherParameters} --onlycis"; shift;;
        --R1) Read1=$2 ; shift 2;;
        --R2) Read2=$2 ; shift 2;;
        --bowtie1) BOWTIE=1 ; shift;;
        --bowtie2) BOWTIE=2 ; shift;;
        --chunkmb) BOWTIEMEMORY=$2 ; shift 2;;
        --parallel) PARALLEL=$2 ; shift 2;;
        --saveGenomeDigest) saveDpnGenome=1 ; shift;;
        --dontSaveGenomeDigest) saveDpnGenome=0 ; shift;;
        --useClusterDiskArea) useTMPDIRforThis=1 ; shift;;
        --trim) TRIM=1 ; shift;;
        --noTrim) TRIM=0 ; shift;;
        --flash) FLASH=1 ; shift;;
        --noFlash) FLASH=0 ; shift;;
        --window) WINDOW=$2 ; shift 2;;
        --increment) INCREMENT=$2 ; shift 2;;
        --monitorRunLogFile) JustNowLogFile=$2 ; shift 2;;
        --genome) GENOME=$2 ; shift 2;;
        --ada3read1) ADA31=$2 ; shift 2;;
        --ada3read2) ADA32=$2 ; shift 2;;
        --extend) extend=$2 ; shift 2;;
        --noPloidyFilter) ploidyFilter="--noploidyfilter " ; shift;;
        --sonicationSize) sonicationSize=$2 ; shift 2;;
        --strandSpecificDuplicates) otherParameters="${otherParameters} --stranded"; strandSpecificDuplicates=1 ; shift;;
        --dump) otherParameters="${otherParameters} --dump" ; shift;;
        --snp) otherParameters="${otherParameters} --snp" ; shift;;
        --globin) otherParameters="${otherParameters} --globin $2" ; shift 2;;
        --limit) otherParameters="${otherParameters} --limit $2" ; shift 2;;
        --stringent) otherParameters="${otherParameters} --stringent" ; shift 1;;
        --pf) PublicPath="$2" ; shift 2;;
        --qmin) QMIN="$2" ; shift 2;;
        --BLATforREUSEfolderPath) reuseBLATpath="$2" ; shift 2;;
        --flashBases) flashOverlap="$2" ; shift 2;;
        --flashMismatch) flashErrorTolerance="$2" ; shift 2;;
        --trim3) otherBowtieParameters="${otherBowtieParameters} --trim3 $2 " ; shift 2;;
        --trim5) otherBowtieParameters="${otherBowtieParameters} --trim5 $2 " ; shift 2;;
        --seedmms) bowtie1MismatchBehavior="${bowtie1MismatchBehavior} --seedmms $2 " ; ${bowtie2MismatchBehavior}="${bowtie2MismatchBehavior} -N $2 "  ; shift 2;;
        --seedlen) bowtie1MismatchBehavior="${bowtie1MismatchBehavior} --seedlen $2 " ; ${bowtie2MismatchBehavior}="${bowtie2MismatchBehavior} -L $2 " ; shift 2;;
        --maqerr) bowtie1MismatchBehavior="${bowtie1MismatchBehavior} --maqerr $2 " ; shift 2;;
        --stepSize) stepSize=$2 ; shift 2;;
        --tileSize) tileSize==$2 ; shift 2;;
        --minScore) minScore=$2 ; shift 2;;
        --maxIntron) maxIntron=$2 ; shift 2;;
        --oneOff) oneOff=$2 ; shift 2;;
        --outfile) QSUBOUTFILE=$2 ; shift 2;;
        --errfile) QSUBERRFILE=$2 ; shift 2;;
        --parallelSubsample) PARALLELSUBSAMPLE=$2 ; shift 2;;
        --wobblyEndBinWidth) otherParameters="${otherParameters} --wobble $2" ; shift 2;;
        --oligosPerBunch) otherParameters="${otherParameters} --oligosperbunch $2" ; shift 2;;
        --) shift; break;;
    esac
done


echo
echo "JustNowLogFile ${JustNowLogFile}"
echo
echo "SetParams" > ${JustNowLogFile}

# -----------------------------------------------

# Shortcut to the --onlyOligoBunches run type : bypasses most of the setup ..

# Currently this is NOT USED at all (the flag is never called)
# - but the user case is preserved in order to bring back TILED analysis (which may need this, possibly)

if [[ ${ONLY_DIVIDE_OLIGOS} -eq "1" ]]; then
    
  oligoRunIsFine=1
  
  checkThis="${OligoFile}"
  checkedName='OligoFile'
  checkParse
  testedFile="${OligoFile}"
  doInputFileTesting

  printThis="Running ONLY OLIGO FILE DIVISION (parallel run - preparing for oligo-file wise loops)"
  printToLogFile

  CCscriptname="${captureScript}.pl"
  runCCanalyserOnlyOligos
  
  if [ "${oligoRunIsFine}" -eq 0 ]; then
        printThis="Oligo file division failed. EXITING !"
        printToLogFile
      exit 1
  fi
  
  copyMainrunnerLogFiles
  exit 0

fi

# ----------------------------------------------

# Setting artificial chromosome on, if we have it .

if [ "${GENOME}" == "mm9PARP" ] ; then

# Whether we have artificial chromosome chrPARP or not, to feed to analyseMappedReads.pl (to be filtered out before visualisation)
# Will be turned on based on genome name, to become :
otherParameters="$otherParameters --parp"

fi

# ----------------------------------------------

# Modifying and adjusting parameter values, based on run flags

setBOWTIEgenomeSizes
setGenomeFasta

echo "GenomeFasta ${GenomeFasta}" >> parameters_capc.log
echo "BowtieGenome ${BowtieGenome}" >> parameters_capc.log

# If the visualisation genome name differs from the asked genome name : masked genomes
setUCSCgenomeName
# Visualisation genome sizes file
setUCSCgenomeSizes

echo "ucscBuildName ${ucscBuildName}" >> parameters_capc.log
echo "ucscBuild ${ucscBuild}" >> parameters_capc.log

#------------------------------------------

CaptureDigestPath="${CaptureDigestPath}/${REenzyme}"

setParameters
testParametersForParseFailures

# ----------------------------------------------

# Loading the environment - either with module system or setting them into path.
# This subroutine comes from conf/config.sh file

printThis="LOADING RUNNING ENVIRONMENT"
printToLogFile

setPathsForPipe

#---------------------------------------------------------

# Check that the requested RE actually exists ..

if [ ! -s ${RunScriptsPath}/${REenzyme}cutReads4.pl ] || [ ! -s ${RunScriptsPath}/${REenzyme}cutGenome4.pl ] ; then

printThis="EXITING ! - Restriction enzyme ${REenzyme} is not supported (check your spelling)"
printToLogFile
exit 1
   
fi

#---------------------------------------------------------

echo "Run with parameters :"
echo

writeParametersToCapcLogFile

cat parameters_capc.log
echo

echo "Whole genome fasta file path : ${GenomeFasta}"
echo "Bowtie genome index path : ${BowtieGenome}"
echo "Chromosome sizes for UCSC bigBed generation will be red from : ${ucscBuild}"

checkThis="${OligoFile}"
checkedName='OligoFile'
checkParse
testedFile="${OligoFile}"
doInputFileTesting

# Doing the ONLY_BLAT  user case first - they doesn't need existing input files (except the oligo file) - so we shouldn't enter any testing of parameters here.

if [[ "${ONLY_BLAT}" -eq "1" ]]; then
{

  paramGenerationRunFineOK=0
  
  printThis="Running ONLY BLATS (user given --onlyBlat flag, or parallel run first step)"
  printToLogFile

  # --------------------------

  CCscriptname="${captureScript}.pl"
  runCCanalyserOnlyBlat


  # Return information to log file if we are parallel ..
  if [ "${paramGenerationRunFineOK}" -ne 0 ];then {

    printThis="CCanalyser to prepare BLAT runs failed."
    printToLogFile
    printThis="EXITING !"
    printToLogFile
  
  exit 1
  }
  fi
  
  # --------------------------

  echo "BLAT" > ${JustNowLogFile}

  ${CaptureFilterPath}/filter.sh --onlyBlat --reuseBLAT ${reuseBLATpath} -p parameters_for_filtering.log --pipelinecall --extend ${extend} --onlyCis ${onlyCis} --stepSize ${stepSize} --minScore ${minScore} --maxIntron=${maxIntron} --tileSize=${tileSize} --oneOff=${oneOff} > filtering.log
  # cat filtering.log

  if [ "$?" -ne 0 ]; then {
      printThis="Running filter.sh crashed - BLAT filtering failed !"
      printToLogFile
      printThis="EXITING !"
      printToLogFile    
      exit 1
  }  
  fi

  # --------------------------

  printThis="Your psl-files for BLAT-filtering can be found in folder :\n $( pwd )/BlatPloidyFilterRun/REUSE_blat/"
  printToLogFile
  
  copyMainrunnerLogFiles
  exit 0
  
}
fi


# ---------------------------------------

# Now,  public areas setup, as PARALLEL=0 and PARALLEL=2 run types require public area storing ..

echo "Parsing the public data area and server locations .."

if [ "${PARALLEL}" -eq 1 ]; then
  PublicPath="${PublicPath}/${Sample}/${CCversion}_${REenzyme}/fastqWise/${PARALLELSUBSAMPLE}"
elif [ "${PARALLEL}" -eq 2 ]; then
  PublicPath=$(pwd)"/PRELIMINARY_TRACKS"
else
  PublicPath="${PublicPath}/${Sample}/${CCversion}_${REenzyme}"
fi

echo "Updated PublicPath (disk path) to be : ${PublicPath}"

# Here, parsing the data area location, to reach the public are address..
diskFolder=${PublicPath}
serverFolder=""   
echo
parsePublicLocations
echo

tempJamesUrl="${SERVERADDRESS}/${serverFolder}"
JamesUrl=$( echo ${tempJamesUrl} | sed 's/\/\//\//g' )
ServerAndPath="${SERVERTYPE}://${JamesUrl}"

# Check the parses - the public area ownership test comes later (when the dir actually gets generated)

checkThis="${PublicPath}"
checkedName='${PublicPath}'
checkParse

checkThis="${ServerAndPath}"
checkedName='${ServerAndPath}'
checkParse

# ----------------------------------------------


# Making output folder.. (and crashing run if found it existing from a previous crashed run)
if [[ ${ONLY_HUB} -eq "0" ]]; then
if [[ ${ONLY_CC_ANALYSER} -eq "0" ]] && [[ ${PARALLEL} -ne 2 ]] && [[ ${ONLY_RE_DIGESTS} -ne 1 ]]; then

if [ -d F1_beforeCCanalyser_${Sample}_${CCversion} ] ; then
  # Crashing here !
  printThis="EXITING ! Previous run data found in run folder ! - delete data of previous run (or define rerun with --onlyCCanalyser )"
  printToLogFile
  exit 1
  
fi
    
mkdir F1_beforeCCanalyser_${Sample}_${CCversion}   
fi
fi

# Here crashing if public folder exists (and this is not --onlyCCanalyser run ..

if [ "${PARALLEL}" -ne "1" ] && [[ ${PARALLEL} -ne 2 ]]; then

if [ -d ${PublicPath} ] && [ ${ONLY_CC_ANALYSER} -eq "0" ] ; then
    # Allows to remove if it is empty..
    rmdir ${PublicPath}

if [ -d ${PublicPath} ] ; then
   # Crashing here !
  printThis="EXITING ! Existing public data found in folder ${PublicPath} "
  printToLogFile
  printThis="Delete the data before restarting the script (refusing to overwrite) "
  printToLogFile
  exit 1
fi

fi
fi


if [[ ${ONLY_HUB} -eq "0" ]]; then

# RE enzyme digestion (if needed .. )
fullPathDpnGenome=""

echo "ReDigest" > ${JustNowLogFile}

# If we are parallel, we assume we have symlink genome_${REenzyme}_coordinates.txt in pwd when we start ..
if [[ ${PARALLEL} -eq "0" ]]; then
    generateReDigest
else
    fullPathDpnGenome=$(pwd)"/genome_${REenzyme}_coordinates.txt"
fi

# RE enzyme genome blacklist generation (regions farther than sonication lenght from the cut site)
fullPathDpnBlacklist=""
if [[ ${PARALLEL} -eq "0" ]]; then
    generateReBlacklist
else
    fullPathDpnBlacklist=$(pwd)"/genome_${REenzyme}_blacklist.bed"
fi

# We need also the oligo white list - to speed up large runs ..

fullPathOligoWhitelist=""
fullPathOligoWhitelistChromosomes=""
if [[ ${PARALLEL} -eq "0" ]]; then
    generateOligoWhitelist
else
    fullPathOligoWhitelist=$(pwd)"/genome_${REenzyme}_oligo_overlap.bed"
    fullPathOligoWhitelistChromosomes=$(pwd)"/genome_${REenzyme}_oligo_chromosomes.txt"
fi

# Early exit for ONLY_RE_DIGESTS

if [[ ${ONLY_RE_DIGESTS} -eq "1" ]]; then

echo > REdigest.log
date >> REdigest.log
echo >> REdigest.log
echo "ucscBuildName ${ucscBuildName}" >> REdigest.log
echo "genome_${REenzyme}_coordinates.txt" >> REdigest.log
echo "fullPathDpnGenome ${fullPathDpnGenome}" >> REdigest.log
echo >> REdigest.log
echo "genome_${REenzyme}_blacklist.bed" >> REdigest.log
echo "fullPathDpnBlacklist ${fullPathDpnBlacklist}" >> REdigest.log
echo "fullPathOligoWhitelist ${fullPathOligoWhitelist}" >> REdigest.log
echo "fullPathOligoWhitelistChromosomes ${fullPathOligoWhitelistChromosomes}" >> REdigest.log
echo >> REdigest.log

copyMainrunnerLogFiles
exit 0

fi


# Save oligo file full path (to not to lose the file when we cd into the folder, if we used relative paths ! )
TEMPdoWeStartWithSlash=$(($( echo ${OligoFile} | awk '{print substr($1,1,1)}' | grep -c '/' )))
if [ "${TEMPdoWeStartWithSlash}" -eq 0 ]
then
 OligoFile=$(pwd)"/"${OligoFile}
fi

checkThis="${OligoFile}"
checkedName='OligoFile'
checkParse
testedFile="${OligoFile}"
doInputFileTesting


# Folder F1 generation ..
if [[ ${ONLY_CC_ANALYSER} -eq "0" ]] && [[ ${PARALLEL} -ne "2" ]]; then
runDir=$( pwd )
runF1folder
fi

echo "bamToSam" > ${JustNowLogFile}

# Folder F1 bam-to-sam, public delete, other folders delete - if we have onlyCCanalyser 
if [[ ${ONLY_CC_ANALYSER} -eq "1" ]] && [[ ${PARALLEL} -ne "2" ]]; then
runDir=$( pwd )
prepareForOnlyCCanalyserRun
prepareF1Sams
fi

# Folder F1 bam-to-sam, if we have second step of parallel run ..
if [[ ${PARALLEL} -eq "2" ]]; then
runDir=$( pwd )
prepareF1Sams
fi

################################################################
# Store the pre-CCanalyser log files for metadata html

runDir=$( pwd )

if [[ ${PARALLEL} -ne "2" ]]; then

echo "publicFiles" > ${JustNowLogFile}

printThis="Store the pre-CCanalyser log files for metadata html.."
printToLogFile

copyPreCCanalyserLogFilesToPublic

fi

################################################################
# Running CAPTURE-C analyser for the aligned file..

printThis="##################################"
printToLogFile
if [[ ${PARALLEL} -ne "1" ]]; then
printThis="Running CCanalyser without filtering - generating the RED graphs.."
else
printThis="Running CCanalyser to divide the bam to oligo bunches.."
fi
printToLogFile
printThis="##################################"
printToLogFile

runDir=$( pwd )
dirForQuotaAsking=${runDir}
samDirForCCanalyser=${runDir}

publicPathForCCanalyser="${PublicPath}/RAW"
JamesUrlForCCanalyser="${JamesUrl}/RAW"

# If first part of parallel run - skipping visualisations and all filtering and counters at and after step 16 (duplicate filter). Only printing mock sam file for parallel run to parse. ..
if [[ ${PARALLEL} -eq 1 ]]; then
  otherParameters="${otherParameters} --onlyoligobunches"
fi

################################

printThis="Flashed reads.."
printToLogFile

sampleForCCanalyser="RAW_${Sample}"

samForCCanalyser="F1_beforeCCanalyser_${Sample}_${CCversion}/FLASHED_REdig.sam"
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

rm -f parameters_for_filtering.log

# For testing purposes..
# otherParameters="${otherParameters} --dump"

FLASHED=1
DUPLFILTER=0

echo "F2_fl" > ${JustNowLogFile}

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting

printThis="##################################"
printToLogFile

printThis="Non-flashed reads.."
printToLogFile

sampleForCCanalyser="RAW_${Sample}"

samForCCanalyser="F1_beforeCCanalyser_${Sample}_${CCversion}/NONFLASHED_REdig.sam"
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

# Files which come twice (both flashed and nonflashed runs) are removed here ..
rm -f parameters_for_filtering.log

# For testing purposes..
# otherParameters="${otherParameters} --dump"

FLASHED=0
DUPLFILTER=0

echo "F2_nonfl" > ${JustNowLogFile}

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting


else
# This is the "ONLY_HUB" end fi - if only hubbing, skipped everything before this point :
# assuming existing output on the above mentioned files - all correctly formed except the public folder (assumes correctly generated bigwigs, however) !
echo
echo "RE-HUB ! - running only public tracks.txt file update (assumes existing bigwig files and other hub structure)."
echo "If your bigwig files are missing (you see no .bw files in ${publicPathForCCanalyser}, or you wish to RE-LOCATE your data hub, run with --onlyCCanalyser parameter (instead of the --onlyHub parameter)"
echo "This is because parts of the hub generation are done inside captureC analyser script, and this assumes only tracks.txt generation failed."
echo

# Remove the malformed tracks.txt for a new try..
# thisPublicFolder="${publicPathForCCanalyser}/${sampleForCCanalyser}_${CCversion}_tracks.txt"
# thisPublicFolderName='${publicPathForCCanalyser}/${sampleForCCanalyser}_${CCversion}_tracks.txt'
# if [ -s "${thisPublicFolder}" ]; then
# isThisPublicFolderParsedFineAndMineToMeddle
# rm -f ${publicPathForCCanalyser}/${sampleForCCanalyser}_${CCversion}_tracks.txt
# fi

thisPublicFolder="${PublicPath}/RAW/RAW_${Sample}_${CCversion}_tracks.txt"
thisPublicFolderName='${PublicPath}/RAW/RAW_${Sample}_${CCversion}_tracks.txt'
if [ -s "${thisPublicFolder}" ]; then
isThisPublicFolderParsedFineAndMineToMeddle
rm -f ${PublicPath}/RAW/RAW_${Sample}_${CCversion}_tracks.txt
fi

thisPublicFolder="${PublicPath}/FILTERED/FILTERED_${Sample}_${CCversion}_tracks.txt"
thisPublicFolderName='${PublicPath}/FILTERED/FILTERED_${Sample}_${CCversion}_tracks.txt'
if [ -s "${thisPublicFolder}" ]; then
isThisPublicFolderParsedFineAndMineToMeddle
rm -f ${PublicPath}/FILTERED/FILTERED_${Sample}_${CCversion}_tracks.txt
fi

thisPublicFolder="${PublicPath}/${Sample}_${CCversion}_tracks.txt"
thisPublicFolderName='${PublicPath}/${Sample}_${CCversion}_tracks.txt'
if [ -s "${thisPublicFolder}" ]; then
isThisPublicFolderParsedFineAndMineToMeddle
rm -f ${PublicPath}/${Sample}_${CCversion}_tracks.txt
fi

fi

################################################################
# Updating the public folder with analysis log files..

echo "publicFiles" > ${JustNowLogFile}

# to create file named ${Sample}_description.html - and link it to each of the tracks.

if [[ "${PARALLEL}" -ne "1" ]]; then
    subfolder="RAW"
    updateCCanalyserDataHub
else
    # sampleForCCanalyser="${Sample}"
    publicPathForCCanalyser="${PublicPath}"
    
    printThis="mainRunner about to call updateCCanalyserReportsToPublic"
    printToLogFile
    ls -lht ${sampleForCCanalyser}_${CCversion}
    echo
    ls -lht 
    
    updateCCanalyserReportsToPublic
fi

moveCommand='mv -f RAW_${Sample}_${CCversion} F2_redGraphs_${Sample}_${CCversion}'
moveThis="RAW_${Sample}_${CCversion}"
moveToHere="F2_redGraphs_${Sample}_${CCversion}"
checkMoveSafety
mv -f RAW_${Sample}_${CCversion} F2_redGraphs_${Sample}_${CCversion}

#################################################################

# Early exit for PARALLEL 1 :

if [[ "${PARALLEL}" -eq "1" ]]; then
        
        # Making summary figure
        
        sampleForCCanalyser="${Sample}"
        publicPathForCCanalyser="${PublicPath}"
        JamesUrlForCCanalyser="${JamesUrl}"
        # Relative paths to log files
        ServerAndPath="."
        
        countsFromCCanalyserScriptname="countsFromCCanalyserOutput_parallel1.sh"
        percentagesFromCountsScriptname="generatePercentages_parallel1.py"

        if [[ "${TILED}" -eq "1" ]]; then
            figureFromPercentagesScriptname="drawFigure_parallel1tiled.py"
        else
            figureFromPercentagesScriptname="drawFigure_parallel1.py"    
        fi
        
        generateSummaryCounts
        generateSummaryFigure
        
        generateFastqwiseDescriptionpage
        
        # Cleaning up after ourselves
        
        TEMPcurrentDir=$( pwd )
        cd F2_redGraphs_${Sample}_${CCversion}/DIVIDEDsams
        cleanCCfolder        
        cd ${TEMPcurrentDir}
        
        rmCommand='rm -rf F2_dividedSams_${Sample}_${CCversion}'
        rmThis="F2_dividedSams_${Sample}_${CCversion}"
        checkRemoveSafety
        rm -rf F2_dividedSams_${Sample}_${CCversion}
        
        moveCommand='mv -f F2_redGraphs_${Sample}_${CCversion} F2_dividedSams_${Sample}_${CCversion}'
        moveThis="F2_redGraphs_${Sample}_${CCversion}"
        moveToHere="F2_dividedSams_${Sample}_${CCversion}"
        checkMoveSafety
        mv -f F2_redGraphs_${Sample}_${CCversion} F2_dividedSams_${Sample}_${CCversion}
	
        copyMainrunnerLogFiles
        exit 0
fi 

#################################################################

# Running again - to make the otherwise filtered-but-not-blat-and-ploidy-filtered

printThis="##################################"
printToLogFile
printThis="Re-running CCanalyser with filtering - generating data to enter blat and ploidy filters.."
printToLogFile
printThis="##################################"
printToLogFile

runDir=$( pwd )
samDirForCCanalyser=${runDir}

publicPathForCCanalyser="${PublicPath}/PREfiltered"
JamesUrlForCCanalyser="${JamesUrl}/PREfiltered"

CCscriptname="${captureScript}.pl"

################################

printThis="Flashed reads.."
printToLogFile

sampleForCCanalyser="PREfiltered_${Sample}"

samForCCanalyser="F1_beforeCCanalyser_${Sample}_${CCversion}/FLASHED_REdig.sam"
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

rm -f parameters_for_filtering.log

FLASHED=1
DUPLFILTER=1

echo "F3_fl" > ${JustNowLogFile}

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting

# Adding the flashed filename, but not forgetting the common prefix either..
# cat parameters_for_filtering.log | grep dataprefix > prefixline
# sed -i 's/^dataprefix\s/dataprefix_FLASHED\t/' parameters_for_filtering.log
# cat parameters_for_filtering.log prefixline > FLASHED_parameters_for_filtering.log
# rm -f parameters_for_filtering.log

# Adding the flashed filename
mv -f parameters_for_filtering.log FLASHED_parameters_for_filtering.log
sed -i 's/^dataprefix\s/dataprefix_FLASHED\t/' FLASHED_parameters_for_filtering.log

printThis="##################################"
printToLogFile

printThis="Non-flashed reads.."
printToLogFile

sampleForCCanalyser="PREfiltered_${Sample}"

samForCCanalyser="F1_beforeCCanalyser_${Sample}_${CCversion}/NONFLASHED_REdig.sam"
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

rm -f parameters_for_filtering.log

FLASHED=0
DUPLFILTER=1

echo "F3_nonfl" > ${JustNowLogFile}

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting

# Adding the nonflashed filename
mv -f parameters_for_filtering.log NONFLASHED_parameters_for_filtering.log
sed -i 's/^dataprefix\s/dataprefix_NONFLASHED\t/' NONFLASHED_parameters_for_filtering.log

#################

# Combining parameter files..

cat FLASHED_parameters_for_filtering.log NONFLASHED_parameters_for_filtering.log | sort | uniq > parameters_for_filtering.log
rm -f FLASHED_parameters_for_filtering.log NONFLASHED_parameters_for_filtering.log


# TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
# TESTING TIME - disabling blat and rest of the pipe ..
# if [ "${PARALLEL}" -eq 2 ]; then

# not testing any more -turning this effectively off here : 
if [ "${PARALLEL}" -eq 2000 ]; then
    subfolder="PREfiltered"
    updateCCanalyserDataHub
    
    moveCommand='mv -f PREfiltered_${Sample}_${CCversion} F3_orangeGraphs_${Sample}_${CCversion}'
    moveThis="PREfiltered_${Sample}_${CCversion}"
    moveToHere="F3_orangeGraphs_${Sample}_${CCversion}"
    checkMoveSafety
    mv -f PREfiltered_${Sample}_${CCversion} F3_orangeGraphs_${Sample}_${CCversion}

    cleanUpRunFolderWhenBLATdisabled
    
    printThis="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
    printToLogFile
    printThis="Testing purposes - exiting run before BLAT and further steps .."
    printToLogFile
    printThis="TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"
    printToLogFile
    exit 0
fi
# TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT


##################################
# Filtering the data..

echo "BLAT" > ${JustNowLogFile}

printThis="##################################"
printToLogFile
printThis="Ploidy filtering and blat-filtering the data.."
printToLogFile
printThis="##################################"
printToLogFile

# ${CaptureFilterPath}
# /home/molhaem2/telenius/CC2/filter/VS101/filter.sh -p parameters.txt --outputToRunfolder --extend 30000
#
#        -p) parameterfile=$2 ; shift 2;;
#        --parameterfile) parameterfile=$2 ; shift 2;;
#        --noploidyfilter) ploidyfilter=0 ; shift 1;;
#        --pipelinecall) pipelinecall=1 ; shift 1;;
#        --extend) extend=$2 ; shift 2;;

echo "${CaptureFilterPath}/filter.sh -p parameters_for_filtering.log -s ${CaptureFilterPath} --pipelinecall ${ploidyFilter} --extend ${extend} "
echo "${CaptureFilterPath}/filter.sh -p parameters_for_filtering.log -s ${CaptureFilterPath} --pipelinecall ${ploidyFilter} --extend ${extend} "  >> "/dev/stderr"

#        --stepSize) stepSize=$2 ; shift 2;;
#        --tileSize) tileSize==$2 ; shift 2;;
#        --minScore) minScore=$2 ; shift 2;;
#        --maxIntron) maxIntron=$2 ; shift 2;;
#        --oneOff) oneOff=$2 ; shift 2;;

echo "--stepSize ${stepSize} --minScore ${minScore} --maxIntron=${maxIntron} --tileSize=${tileSize} --oneOff=${oneOff}"
echo "--stepSize ${stepSize} --minScore ${minScore} --maxIntron=${maxIntron} --tileSize=${tileSize} --oneOff=${oneOff}" >> "/dev/stderr"

echo "--reuseBLAT ${reuseBLATpath}"
echo "--reuseBLAT ${reuseBLATpath}" >> "/dev/stderr"
echo "--onlyCis ${onlyCis}"
echo "--onlyCis ${onlyCis}" >> "/dev/stderr"

mkdir filteringLogFor_${sampleForCCanalyser}_${CCversion}

moveCommand='mv parameters_for_filtering.log filteringLogFor_${sampleForCCanalyser}_${CCversion}/.'
moveThis="parameters_for_filtering.log"
moveToHere="filteringLogFor_${sampleForCCanalyser}_${CCversion}/."
checkMoveSafety
mv parameters_for_filtering.log filteringLogFor_${sampleForCCanalyser}_${CCversion}/.
cd filteringLogFor_${sampleForCCanalyser}_${CCversion}

TEMPreturnvalue=0
${CaptureFilterPath}/filter.sh --reuseBLAT ${reuseBLATpath} -p parameters_for_filtering.log --pipelinecall ${ploidyFilter} --extend ${extend} --onlyCis ${onlyCis} --stepSize ${stepSize} --minScore ${minScore} --maxIntron=${maxIntron} --tileSize=${tileSize} --oneOff=${oneOff} > filtering.log
TEMPreturnvalue=$?

cat filtering.log

checkThis="${publicPathForCCanalyser}"
checkedName='${publicPathForCCanalyser}'
checkParse

thisPublicFolder="${publicPathForCCanalyser}"
thisPublicFolderName='${publicPathForCCanalyser}'
if [ -s "${thisPublicFolder}" ]; then
isThisPublicFolderParsedFineAndMineToMeddle
rm -f ${publicPathForCCanalyser}/filtering.log
fi
cp filtering.log ${publicPathForCCanalyser}/.

if [ "${TEMPreturnvalue}" -ne 0 ]; then
    
    printThis="Filtering after BLAT was crashed ! - maybe you had no reads left in either FLASHED or NONFLASHED file for thi/es(e) oligo(s), in folder F3/preFiltered ? "
    printToLogFile
    
    printThis="EXITING !"
    printToLogFile
    exit 1
    
fi


cd ..

# By default the output of this will go to :
# ${Sample}_${CCversion}/BLAT_PLOIDY_FILTERED_OUTPUT
# because the parameter file line for data location is
# ${Sample}_${CCversion}

################################################################
# Updating the public folder with analysis PREfiltered log files..

# to create file named ${Sample}_description.html - and link it to each of the tracks.

subfolder="PREfiltered"
updateCCanalyserDataHub

moveCommand='mv -f PREfiltered_${Sample}_${CCversion} F3_orangeGraphs_${Sample}_${CCversion}'
moveThis="PREfiltered_${Sample}_${CCversion}"
moveToHere="F3_orangeGraphs_${Sample}_${CCversion}"
checkMoveSafety
mv -f PREfiltered_${Sample}_${CCversion} F3_orangeGraphs_${Sample}_${CCversion}

################################################################

printThis="##################################"
printToLogFile
printThis="Re-running CCanalyser for the filtered data.."
printToLogFile
printThis="##################################"
printToLogFile

runDir=$( pwd )
samDirForCCanalyser="${runDir}"

publicPathForCCanalyser="${PublicPath}/FILTERED"
JamesUrlForCCanalyser="${JamesUrl}/FILTERED"

CCscriptname="${captureScript}.pl"

PREVsampleForCCanalyser="${sampleForCCanalyser}"

# FLASHED

printThis="------------------------------"
printToLogFile
printThis="FLASHED file.."
printToLogFile

# keeping the "RAW" in the file name - as this part (input folder location) still needs that
ln -s filteringLogFor_${PREVsampleForCCanalyser}_${CCversion}/BlatPloidyFilterRun/BLAT_PLOIDY_FILTERED_OUTPUT/FLASHED_REdig_${CCversion}_filtered_combined.sam FLASHED_REdig.sam
samForCCanalyser="FLASHED_REdig.sam"

FILTEREDsamBasename=$( echo ${samForCCanalyser} | sed 's/.*\///' | sed 's/\.sam$//' )
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

# Now changing the identifier from "RAW" to "FILTERED" - to set the output folder

sampleForCCanalyser="FILTERED_${Sample}"

FLASHED=1
DUPLFILTER=0

echo "F5_fl" > ${JustNowLogFile}

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting

# Remove symlink
rm -f FLASHED_REdig.sam

# NONFLASHED

printThis="------------------------------"
printToLogFile
printThis="NONFLASHED file.."
printToLogFile


# keeping the "RAW" in the file name - as this part (input folder location) still needs that
ln -s filteringLogFor_${PREVsampleForCCanalyser}_${CCversion}/BlatPloidyFilterRun/BLAT_PLOIDY_FILTERED_OUTPUT/NONFLASHED_REdig_${CCversion}_filtered_combined.sam NONFLASHED_REdig.sam
samForCCanalyser="NONFLASHED_REdig.sam"

FILTEREDsamBasename=$( echo ${samForCCanalyser} | sed 's/.*\///' | sed 's/\.sam$//' )
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

# Now changing the identifier from "RAW" to "FILTERED" - to set the output folder
sampleForCCanalyser="FILTERED_${Sample}"

FLASHED=0
DUPLFILTER=0

echo "F5_nonfl" > ${JustNowLogFile}

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting

# Remove symlink
rm -f NONFLASHED_REdig.sam

################################################################
# Updating the public folder with analysis log files..

# to create file named ${Sample}_description.html - and link it to each of the tracks.

subfolder="FILTERED"
updateCCanalyserDataHub

moveCommand='mv -f FILTERED_${Sample}_${CCversion} F5_greenGraphs_separate_${Sample}_${CCversion}'
moveThis="FILTERED_${Sample}_${CCversion}"
moveToHere="F5_greenGraphs_separate_${Sample}_${CCversion}"
checkMoveSafety
mv -f FILTERED_${Sample}_${CCversion} F5_greenGraphs_separate_${Sample}_${CCversion}

################################################################

echo "F6_samcomb" > ${JustNowLogFile}

printThis="##################################"
printToLogFile
printThis="Combining FLASHED and NONFLASHED CCanalyser filtered data .."
printToLogFile
printThis="##################################"
printToLogFile

printThis="Combining sam files.."
printToLogFile

cat filteringLogFor_PREfiltered_${Sample}_${CCversion}/BlatPloidyFilterRun/BLAT_PLOIDY_FILTERED_OUTPUT/NONFLASHED_REdig_${CCversion}_filtered_combined.sam | grep -v "^@" | \
cat filteringLogFor_PREfiltered_${Sample}_${CCversion}/BlatPloidyFilterRun/BLAT_PLOIDY_FILTERED_OUTPUT/FLASHED_REdig_${CCversion}_filtered_combined.sam - > COMBINED.sam

COMBINEDsamBasename=$( echo ${samForCCanalyser} | sed 's/.*\///' | sed 's/\.sam$//' )
samForCCanalyser="COMBINED.sam"
COMBINEDsamBasename=$( echo ${samForCCanalyser} | sed 's/.*\///' | sed 's/\.sam$//' )
testedFile="${samForCCanalyser}"
tempFileFine=1
doTempFileInfo

printThis="------------------------------"
printToLogFile
printThis="Running CCanalyser.."
printToLogFile

echo "F6_cc" > ${JustNowLogFile}

runDir=$( pwd )
samDirForCCanalyser="${runDir}"

publicPathForCCanalyser="${PublicPath}/COMBINED"
JamesUrlForCCanalyser="${JamesUrl}/COMBINED"

CCscriptname="${captureScript}.pl"

sampleForCCanalyser="COMBINED_${Sample}"

# This means : flashing is "NOT IN USE" - and marks the output tracks with name "" instead of "FLASHED" or "NONFLASHED"
FLASHED=-1
DUPLFILTER=0

if [ "${PARALLEL}" -eq 2 ]; then
  otherParameters="${otherParameters} --normalisedtracks "
fi

if [ "${tempFileFine}" -eq 1 ]; then
runCCanalyser
fi
doQuotaTesting

# Remove input file
rm -f COMBINED.sam

################################################################
# Updating the public folder with analysis log files..

# to create file named ${Sample}_description.html - and link it to each of the tracks.

echo "public" > ${JustNowLogFile}

subfolder="COMBINED"
updateCCanalyserDataHub

moveCommand='mv -f COMBINED_${Sample}_${CCversion} F6_greenGraphs_combined_${Sample}_${CCversion}'
moveThis="COMBINED_${Sample}_${CCversion}"
moveToHere="F6_greenGraphs_combined_${Sample}_${CCversion}"
checkMoveSafety
mv -f COMBINED_${Sample}_${CCversion} F6_greenGraphs_combined_${Sample}_${CCversion}

################################################################


if [[ ${saveDpnGenome} -eq "0" ]] ; then
  rmCommand='rm -f genome_${REenzyme}_coordinates.txt'
  rmThis="genome_${REenzyme}_coordinates.txt"
  checkRemoveSafety
  rm -f "genome_${REenzyme}_coordinates.txt"  
fi

# Generating combined data hub

sampleForCCanalyser="${Sample}"
publicPathForCCanalyser="${PublicPath}"
JamesUrlForCCanalyser="${JamesUrl}"

# Testing purposes - skipping this for parallel 2 for the time being.
if [ "${PARALLEL}" -ne 2 ]; then

generateSummaryCounts
generateSummaryFigure

fi

if [ "${PARALLEL}" -eq 1 ]; then
    generateCombinedDataHub
fi
# The parallel runs need a combining step before making the actual visualisations.
# That is done in the topmost script instead.

# Cleaning up after ourselves ..

cleanUpRunFolder

# This would make symlinks instead of storing the bigwigs in the /public area.
# As this is not supported in Wellcome trust public area (and WIMM public area is now bigger so this is not needed), disabling this.
# makeSymbolicLinks

if [ "${PARALLEL}" -ne 1 ]; then
    # Data hub address (print to stdout) ..
    updateHub_part3final
fi

if [ "${PARALLEL}" -eq 0 ]; then
copyMainrunnerLogFiles
fi
exit 0
