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

# These subs are taken from readParameters.sh of macs2hubber (as they were 20Feb2018)

removeMacsParam(){
# removes the above param from ${parameterList}
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
parameterList=$( echo ${parameterList} | sed 's/'${macsflag}'\s\s*//g' )

}

removeMacsParamAndValue(){
# removes the above param from ${parameterList}
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
# macsvalue="0"

# If it was there multiple times - we cannot use global..
# So, we do recursion instead !

# First, we save values : as they were when this sub was called :
TEMPmacsHasThisFlag=${macsHasThisFlag}
TEMPmacsvalue=${macsvalue}

# Then we do the recursion !
macsOnOff

while [ "${macsHasThisFlag}" -eq 1 ]
do
# echo macs
# We ask which value we now see
macsParam
TEMPflag=$( echo ${macsvalue} | sed 's/\//\\\//g' | sed 's/^/'${macsflag}'\\s\\s\*/' | sed 's/$/\\s\\s\*/' )
# echo ${TEMPflag}
# echo ${parameterList} | sed 's/'${TEMPflag}'//'
parameterList=$( echo ${parameterList} | sed 's/'${TEMPflag}'//' )
# We ask if we still see the flag
macsOnOff

done

# We reset the pre-call values :

macsHasThisFlag=${TEMPmacsHasThisFlag}
macsvalue=${TEMPmacsvalue}

}

macsParamListFromValue(){
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
macslist=()
macslist=($( echo ${parameterList} | sed 's/.*\s\s*'${macsflag}'\s\s*//' | sed 's/\s.*$//' | tr ',' '\n' ))
}

macsParam(){
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"

# If multiple occurences, gives the last one (will mimick MACS2 behavior - the last of them will be the one taking effect ! )

macsvalue=""
macsvalue=$( echo ${parameterList} | sed 's/.*\s\s*'${macsflag}'\s\s*//' | sed 's/\s.*$//' )
}

longlabelParam(){
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
longlabelvalue=""
longlabelvalue=$( echo ${longlabel} | sed 's/.*\s\s*'${macsflag}'\s\s*//' | sed 's/\s.*$//' )
}

macsTwoValueParam(){
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
macsvalue=""
macsvalue=$( echo ${parameterList} | sed 's/.*\s\s*'${macsflag}'\s\s*//' | sed 's/\s\s*/_/' | sed 's/\s.*$//' | sed 's/_/ /' )
}

macsOnOff(){
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
macsHasThisFlag=0
# echo "${parameterList}" | grep -c ${TEMPflag} | awk '{ if ($1>0) print 1; else print 0}'
TEMPflag="\s${macsflag}\s"
macsHasThisFlag=$(($( echo "${parameterList}" | grep -c ${TEMPflag} | awk '{ if ($1>0) print 1; else print 0}' )))
}

longlabelOnOff(){
# NOTE ! - the below works only because we have added PARAMETERS\s (text+space) to the beginning (and text+END) to the end of the parameter list before ever entering this subroutine
# This because : 1) we need space before the first argument to parse this kind of arguments "--shift-control" (to know whether our hyphen - is happening in the middle of argument or beginning of it)
#                2) command "echo" shares flags --version and -n with macs2 : we need to shield with a string "PARAMETERS" before these flags, to not to give them as arguments to echo !

# Needs this to be set :
# macsflag="--shift-control"
longlabelHasThisFlag=0
# echo "${parameterList}" | grep -c ${TEMPflag} | awk '{ if ($1>0) print 1; else print 0}'
TEMPflag="\s${macsflag}\s"
longlabelHasThisFlag=$(($( echo "${longlabel}" | grep -c ${TEMPflag} | awk '{ if ($1>0) print 1; else print 0}' )))
}

checkIfObligatoryWasFound(){

if [ "${macsHasThisFlag}" -eq 0 ];then
    printThis="Run command didn't include flag ${macsflag} : You cannot run without setting that !"
    printToLogFile
    obligatoryFlagsFound=0
fi

}

checkIfSuggestedWasFound(){

if [ "${macsHasThisFlag}" -eq 0 ];then
    printThis="NOTE !! Run command didn't include flag ${macsflag} : \nOptimising this parameter to suit your data set is recommended ! \n( now running with default parameters )"
    printToLogFile
fi

}

checkIfSynonymousSuggestedWasFound(){

if [ "${macsHasThisFlag_first}" -eq 0 ] && [ "${macsHasThisFlag_second}" -eq 0 ] ;then
    printThis="NOTE !! Run command didn't include flag ${macsflag} : \nOptimising this parameter to suit your data set is recommended ! \n( now running with default parameters )"
    printToLogFile
fi

}
   
onlyIntraPipeFlagErrorMessage(){
       echo "" >&2
       echo "Flag ${macsflag} in command line is not allowed. This flag is only for intra-pipeline calls of the underlying mainRunner.sh !" >&2
       echo "Fix your command line parameters " >&2
       echo "" >&2    
}

onlySerialPipeFlagErrorMessage(){
       echo "" >&2
       echo "Flag ${macsflag} in command line is not allowed. This flag is only for SERIAL RUN pipeline calls (CB5 or older) - nowadays R1 and R2 have to be given via PIPE_fastqPaths.txt !" >&2
       echo "Fix your command line parameters, and write fastq paths into PIPE_fastqPaths.txt instead  " >&2
       echo "" >&2    
}

missingFlagErrorMessage(){
       echo "" >&2
       echo "Flag ${macsflag} is obligatory !" >&2
       echo "Fix your command line parameters  " >&2
       echo "" >&2    
}

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

PipeTopPath="$( which $0 | sed 's/\/checkParameters.sh$//' )"

BashHelpersPath="${PipeTopPath}/bashHelpers"

# READING THE PARAMETER FILES IN (in NGseqBasic style)
# . ${BashHelpersPath}/parameterFileReaders.sh

# TESTING file existence, log file output general messages
CaptureCommonHelpersPath=$( dirname ${PipeTopPath} )"/commonSubroutines"
. ${CaptureCommonHelpersPath}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found in $0. Cannot continue without safety features turned on ! \n EXITING !! "
    printToLogFile
    exit 1
fi

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

printThis="Checking command line parameters .. "
printToLogFile

echo -n "" > TEMP.mainparam
parametersOK=1

# We start by adding \s to the beginning of the list (to differentiate between - in the middle of flag (--shift-control) and in the beginning of it ..)
parameterList=$( cat TEMP.param )
# echo "parameterList ${parameterList} "

# check forbidden flags (not allowing sub-level flags --onlyREdigest, --parallel 1 --parallel 2 --R1 --R2 --outfile --errfile)

   macsflag='--onlyREdigest'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 1 ];then
       parametersOK=0
       onlyIntraPipeFlagErrorMessage
   fi

   macsflag='--parallel'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 1 ];then
       parametersOK=0
       onlyIntraPipeFlagErrorMessage
   fi
   
   macsflag='--outfile'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 1 ];then
       parametersOK=0
       onlyIntraPipeFlagErrorMessage
   fi

   macsflag='--errfile'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 1 ];then
       parametersOK=0
       onlyIntraPipeFlagErrorMessage
   fi
   
   macsflag='--R1'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 1 ];then
       parametersOK=0
       onlySerialPipeFlagErrorMessage
   fi

   macsflag='--R2'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 1 ];then
       parametersOK=0
       onlySerialPipeFlagErrorMessage
   fi

   
# Will be parsed to a VARIABLE to be used in shell (instead of MACS2) if given (and no parameter file is given) :

# -o (oligo file)

   macsflag='-o'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 0 ];then
       parametersOK=0
       missingFlagErrorMessage
   else
       macsParam
       # above sets this : macsvalue
       echo "oligofile ${macsvalue}" >> TEMP.mainparam
       removeMacsParamAndValue
   fi
   
   macsflag='--genome'
   macsOnOff
   if [ "${macsHasThisFlag}" -eq 0 ];then
       parametersOK=0
       missingFlagErrorMessage
   else
       macsParam
       # above sets this : macsvalue
       echo "inputgenomename ${macsvalue}" >> TEMP.mainparam
       removeMacsParamAndValue
   fi
   
   macsflag='--BLATforREUSEfolderPath'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       macsParam
       echo "reuseblatpath ${macsvalue}" >> TEMP.mainparam
       removeMacsParamAndValue
   fi

   macsflag='--CCversion'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       macsParam
       echo "CCversion ${macsvalue}" >> TEMP.mainparam
       removeMacsParamAndValue
   fi  

   macsflag='--onlyBlat'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo onlyBlat >> TEMP.mainparam
       removeMacsParam
   fi
   
   macsflag='--repairBrokenFastqs'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo rerunBrokenFastqs >> TEMP.mainparam
       removeMacsParam
   fi

   macsflag='--stopAfterFolderB'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo stopAfterFolderB >> TEMP.mainparam
       removeMacsParam
   fi

   macsflag='--startAfterFolderB'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo startAfterFolderB >> TEMP.mainparam
       removeMacsParam
   fi

   macsflag='--stopAfterBamCombining'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo stopAfterBamCombining >> TEMP.mainparam
       removeMacsParam
   fi

   macsflag='--onlyCCanalyser'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo onlyCCanalyser >> TEMP.mainparam
       removeMacsParam
   fi

   macsflag='--onlyHub'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
       echo onlyHub >> TEMP.mainparam
       removeMacsParam
   fi

   macsflag='-s'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
        macsParam
       # above sets this : macsvalue
       echo "samplename ${macsvalue}" >> TEMP.mainparam
       removeMacsParamAndValue
   fi

   macsflag='--pf'
   macsOnOff
   if [ "${macsHasThisFlag}" -ne 0 ];then
        macsParam
       # above sets this : macsvalue
       echo "publicfolder ${macsvalue}" >> TEMP.mainparam
       removeMacsParamAndValue
   fi
   
   macsflag='--tiled'
   macsOnOff
   echo "tiled ${macsHasThisFlag}" >> TEMP.mainparam
   
   macsflag='--useClusterDiskArea'
   macsOnOff
   echo "useTMPDIRforThis ${macsHasThisFlag}" >> TEMP.mainparam
   
   macsflag='--wholenode24'
   macsOnOff
   echo "useWholenodeQueue ${macsHasThisFlag}" >> TEMP.mainparam
   if [ "${macsHasThisFlag}" -ne 0 ];then
       removeMacsParam
   fi
   
   macsflag='--dpn'
   macsOnOff
   macsHasThisFlag1=${macsHasThisFlag}
   howmanyHasThisMacsFlag=$((${macsHasThisFlag}))
   
   macsflag='--nla'
   macsOnOff
   macsHasThisFlag2=${macsHasThisFlag}
   howmanyHasThisMacsFlag=$((${howmanyHasThisMacsFlag}+${macsHasThisFlag}))
   
   macsflag='--hind'
   macsOnOff
   macsHasThisFlag3=${macsHasThisFlag}
   howmanyHasThisMacsFlag=$((${howmanyHasThisMacsFlag}+${macsHasThisFlag}))
   
   if [ "${howmanyHasThisMacsFlag}" -gt 1 ] ;then
       printThis="Multiple REenzymes (dpn ${macsHasThisFlag1}, nla ${macsHasThisFlag2}, hind ${macsHasThisFlag3}) given - cannot run like this. EXITING !"
       printToLogFile
       parametersOK=0
   fi
   
   if [ "${macsHasThisFlag1}" -ne 0 ] ;then
       echo "REenzyme dpnII" >> TEMP.mainparam
       echo "REenzymeShort dpn" >> TEMP.mainparam
   elif [ "${macsHasThisFlag2}" -ne 0 ]  ;then
       echo "REenzyme nlaIII" >> TEMP.mainparam
       echo "REenzymeShort nla" >> TEMP.mainparam
   elif [ "${macsHasThisFlag3}" -ne 0 ]  ;then
       echo "REenzyme hindIII" >> TEMP.mainparam
       echo "REenzymeShort hind" >> TEMP.mainparam
   else
       echo "REenzyme dpnII" >> TEMP.mainparam
       echo "REenzymeShort dpn" >> TEMP.mainparam
   fi   
   
   # ----------------------------------------------------------------------------------------------

   echo ${parameterList} > TEMP.param
   
   #--------Crashing-if-needed---------------------------------------------------------------------

    printThis="  parametersOK ${parametersOK}\n "
    printToLogFile
    
    if [ "${parametersOK}" -eq 0 ] ; then

    printThis="Run crashed - command line parameters given wrong ! "
    printToLogFile
    
    exit 1
    
    fi

