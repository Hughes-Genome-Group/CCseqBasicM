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

# Just in case emptying this out - if there happens to be one in the env
thisIsTesterLoggerTest=""

printToTesterLogFile(){
   
# Needs this to be set :
# printThis=""

# Basically, to turn off all printing - as this is just a tester in beginning of run ..

 echo "T" 
 echo -e "T ${printThis}"
 echo "T ${sumOfNotCrashedCommands} / ${totalCountOfTests} of tests failed so far"
 echo "T "

 echo "T " >> "/dev/stderr"
 echo -e "T ${printThis}" >> "/dev/stderr"
 echo "T ${sumOfNotCrashedCommands} / ${totalCountOfTests} of tests failed so far"  >> "/dev/stderr"
 echo "T " >> "/dev/stderr"
    
}

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


printToTrimmingLogFile(){
   
# Needs this to be set :
# printThis="" 

echo ""
echo -e "${printThis}"
echo ""

echo "" >> "read_trimming.log"
echo -e "${printThis}" >> "read_trimming.log"
echo "" >> "read_trimming.log"
    
}

setStringentFailForTheFollowing(){
# ------------------------
# To crash whenever anything withing this breaks ..
set -e -o pipefail
# ------------------------    
}

stopStringentFailAfterTheAbove(){
 # ------------------------
# Revert to normal (+e : don't crash when a command fails. +o pipefail takes it back to "only monitor the last command of a pipe" )
set +e +o pipefail
# ------------------------ 
}


doInputFileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      printThis="Input file not found or empty file : ${testedFile}  \nEXITING!! "
      if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
    fi
}

doTempFileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      printThis="Temporary file not found or empty file : ${testedFile} \nEXITING!! "
      if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi
}

doTempFileInfo(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""
    # SETS THIS :
    # tempFileFine=0
    
    if [ ! -r "${testedFile}" ] || [ ! -e "${testedFile}" ] || [ ! -f "${testedFile}" ] || [ ! -s "${testedFile}" ]; then
      printThis="WARNING : Temporary file not found or empty file : ${testedFile} \n Will be skipping the steps which need this file .. "
      if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; fi
fi
}

fileTesting(){
    
    # NEEDS THIS TO BE SET BEFORE CALL :
    # testedFile=""    
    
    if [ ! -s "${testedFile}" ] || [ ! -r "${testedFile}" ] || [ ! -f "${testedFile}" ] ; then
      printThis="File not found or cannot be read or empty file : ${testedFile} \nEXITING!! "
      if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
    fi
}

doQuotaTesting(){
        
    echo
    echo "Local disk usage for THIS RUN - at the moment (check you don't go over your t1-data area quota) :"
    du -sh ${dirForQuotaAsking} 2>> /dev/null
    # Not using du in TMPDIR as TMPDIR for each node has its own filesystem, so df can be used instead (tip from Ewan 310718)
    # if [ "${useTMPDIRforThis}" -ne 0 ]; then echo "TMPDIR cluster temp area usage - check you don't go over 12GB (normal queue) or 200GB (largemem queue) :"; du -sh "${TMPDIR}" 2>> /dev/null; fi
    if [ "${useTMPDIRforThis}" -ne 0 ]; then echo "TMPDIR cluster temp area usage - check you don't go over 12GB (normal queue) or 200GB (largemem queue) :"; df --block-size 1000000 ${TMPDIR} 2>> /dev/null; fi
    echo
    
}

checkParse(){

# checkThis=
# checkedName=

if [ "${#checkThis}" -eq 0 ]; then
  printThis="Parse fail - zero lenght variable ${checkedName} ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${checkThis} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' only contains whitespace ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${checkThis}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains '..' in the variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${checkThis}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains '*' in the variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${checkThis}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains these weird characters '${weirdCharacters}' in the variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# last test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${checkThis}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains whitespace in the middle of variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi
    
}

checkParseEnsureNoSlashes(){

# checkThis=
# checkedName=

if [ "${#checkThis}" -eq 0 ]; then
  printThis="Parse fail - zero lenght variable ${checkedName} ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${checkThis} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' only contains whitespace ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${checkThis}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains '..' in the variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${checkThis}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains '*' in the variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${checkThis}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains these weird characters '${weirdCharacters}' in the variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# last test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${checkThis}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains whitespace in the middle of variable ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# last test : slashes in the middle of variable name !

containsSlashes=$( echo ${checkThis} |  grep -c '/' )
if [ "${containsSlashes}" -ne 0 ]; then
  printThis="Parse fail - variable ${checkedName}='${checkThis}' contains slashes in the middle of variable  (i.e. is not a file only - but a PATH ) ! \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi
    
}

checkMoveSafety(){

# This relies on the $HOME of the script to be set to the "local top dir" in the beginning of each "main script" !
    
# moveCommand=
# moveThis=
# moveToHere=

if [ "${#moveThis}" -eq 0 ]; then
  printThis="Cannot move as moveThis variable has zero lenght in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${moveThis} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="Cannot move as moveThis variable contains only whitespace in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${moveThis}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="Cannot move as moveThis variable '${moveThis}' contains '..' in the variable name in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${moveThis}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="Cannot move as moveThis variable '${moveThis}' contains '*' in the variable name in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${moveThis}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="Cannot move as moveThis variable '${moveThis}' contains these weird characters '${weirdCharacters}' in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi


# Next test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${moveThis}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="Cannot move as moveThis variable '${moveThis}' contains whitespace in the middle of variable name in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Further testing only, if we are having / in the beginning of the path ..

startWithSlash=$( echo ${moveThis} | grep -c '^/' )
if [ "${startWithSlash}" -ne 0 ]; then
startWithHome=$( echo ${moveThis} | grep -c '^'$HOME )
if [ "${startWithHome}" -eq 0 ]; then
  printThis="Cannot move as moveThis variable ${moveThis} points outside the local area ${HOME} in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi  
fi

# -----------------------------------------

if [ "${#moveToHere}" -eq 0 ]; then
  printThis="Cannot move as moveToHere variable has zero lenght in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${moveToHere} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="Cannot move as moveToHere variable contains only whitespace in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${moveToHere}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="Cannot move as moveToHere variable '${moveToHere}' contains '..' in the variable name in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${moveToHere}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="Cannot move as moveToHere variable '${moveToHere}' contains '*' in the variable name in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${moveToHere}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="Cannot move as moveToHere variable '${moveToHere}' contains these weird characters '${weirdCharacters}' in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Next test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${moveToHere}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="Cannot move as moveToHere variable '${moveToHere}' contains whitespace in the middle of variable name in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi    

# Further testing only, if we are having / in the beginning of the path ..

startWithSlash=$( echo ${moveToHere} | grep -c '^/' )
if [ "${startWithSlash}" -ne 0 ]; then
startWithHome=$( echo ${moveToHere} | grep -c '^'$HOME )
if [ "${startWithHome}" -eq 0 ]; then
  printThis="Cannot move as moveToHere variable ${moveToHere} points outside the local area ${HOME} in move command \n ${moveCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi  
fi


}

checkCdSafety(){
    
# This relies on the $HOME of the script to be set to the "local top dir" in the beginning of each "main script" !

# cdCommand=
# cdToThis=    

if [ "${#cdToThis}" -eq 0 ]; then
  printThis="Cannot cd as cdToThis variable has zero lenght in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${cdToThis} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="Cannot cd as cdToThis variable contains only whitespace in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${cdToThis}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="Cannot cd as cdToThis variable '${cdToThis}' contains '..' in the variable name in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${cdToThis}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="Cannot cd as cdToThis variable '${cdToThis}' contains '*' in the variable name in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${cdToThis}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="Cannot cd as cdToThis variable '${cdToThis}' contains these weird characters '${weirdCharacters}' in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Next test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${cdToThis}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="Cannot cd as cdToThis variable '${cdToThis}' contains whitespace in the middle of variable name in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Further testing only, if we are having / in the beginning of the path ..

startWithSlash=$( echo ${cdToThis} | grep -c '^/' )
if [ "${startWithSlash}" -ne 0 ]; then
startWithHome=$( echo ${cdToThis} | grep -c '^'$HOME )
if [ "${startWithHome}" -eq 0 ]; then
  printThis="Cannot cd as cdToThis variable ${cdToThis} points outside the local area ${HOME} in cd command \n ${cdCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi  
fi

}

checkRemoveSafety(){
    
# This relies on the $HOME of the script to be set to the "local top dir" in the beginning of each "main script" !

# This assumes the rm command to only have ONE argument - not a list of them.
# i.e. valid command would be of format :
# rm -f kissa
# but not
# rm -f kissa koira marsu
# for multi-argument commands, run this many times, each time having different one as the ${rmThis} parameter

# The arguments are not supposed to expand - i.e give all things in non-starred format to this.
    
# rmCommand=
# rmThis=

if [ "${#rmThis}" -eq 0 ]; then
  printThis="Cannot rm as rmThis variable has zero lenght in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${rmThis} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="Cannot rm as rmThis variable contains only whitespace in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${rmThis}"  |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="Cannot rm as rmThis variable '${rmThis}' contains '..' in the variable name in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${rmThis}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="Cannot rm as rmThis variable '${rmThis}' contains '*' in the variable name in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${rmThis}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="Cannot rm as rmThis variable '${rmThis}' contains these weird characters '${weirdCharacters}' in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Next test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${rmThis}"  |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="Cannot rm as rmThis variable '${rmThis}' contains whitespace in the middle of variable name in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

    
# Testing only, if we are having / in the beginning of the path ..

startWithSlash=$( echo ${rmThis} | grep -c '^/' )
if [ "${startWithSlash}" -ne 0 ]; then
startWithHome=$( echo ${rmThis} | grep -c '^'$HOME )
if [ "${startWithHome}" -eq 0 ]; then
  printThis="Cannot rm as rmThis variable ${rmThis} points outside the local area ${HOME} in rm command \n ${rmCommand} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi  
fi    
    
}

isThisPublicFolderParsedFineAndMineToMeddle(){
# thisPublicFolder=
# thisPublicFolderName=

# This only works for FOLDERS (below we have extension also for files -  but that parse is not working properly)


if [ "${#thisPublicFolder}" -eq 0 ]; then
  printThis="The public folder ${thisPublicFolderName} folder name ${thisPublicFolder} has zero lenght \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${thisPublicFolder} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="The public folder ${thisPublicFolderName} folder name ${thisPublicFolder} contains only whitespace \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${thisPublicFolder}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="The public folder ${thisPublicFolderName} folder name '${thisPublicFolder}' contains '..' in the folder name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${thisPublicFolder}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="The public folder ${thisPublicFolderName} folder name '${thisPublicFolder}' contains '*' in the folder name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${thisPublicFolder}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="The public folder ${thisPublicFolderName} folder name contains these weird characters '${weirdCharacters}' in the folder name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi


# Next test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${thisPublicFolder}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="The public folder ${thisPublicFolderName} folder name '${thisPublicFolder}' contains whitespace in the middle of the folder name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Here two situations - whether we have folder or we have file.

if [ -d "${thisPublicFolder}" ]; then
{    
# Here safety check - that the person actually OWNS THIS FOLDER.
# If not, then refusing right here. (then it is actually not generated by a previous CCanalyser run ran by this very same person, for sure ! )
thisIsMineToMeddle=1
thisIsMineToMeddle=$(($( ls -l $(dirname ${thisPublicFolder}) | grep $(basename ${thisPublicFolder}) | sed 's/\s\s*/\t/g' | cut -f 3 | grep -c $(whoami) )))
if [ "${thisIsMineToMeddle}" -eq 0 ]; then
    printThis="The public folder ${thisPublicFolderName} ${thisPublicFolder} is not owned by $(whoami), so refusing to meddle with it ! \n EXITING!!  \n "$( ls -l $(dirname ${thisPublicFolder}) | grep $(basename ${thisPublicFolder}))
    if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi   
}

else
{    
# Here safety check - that the person actually OWNS THE FOLDER the file belongs to.
# If not, then refusing right here. (then it is actually not generated by a previous CCanalyser run ran by this very same person, for sure ! )
thisIsMineToMeddle=0
if [ "${thisIsMineToMeddle}" -eq 0 ]; then
    printThis="The public folder ${thisPublicFolderName} ${thisPublicFolder} does not exist, so cannot test if it is fine to meddle ! \n EXITING!! \n "
    if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi   
}   
    
fi
    
    
}

isThisLocalDataParsedFineAndMineToMeddle(){
# thisLocalData=
# thisLocalDataName=

if [ "${#thisLocalData}" -eq 0 ]; then
  printThis="The data ${thisLocalDataName} name ${thisLocalData} has zero lenght \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

whiteSpaceParsed=$(echo ${thisLocalData} | sed 's/\s*//g' )
if [ "${#whiteSpaceParsed}" -eq 0 ]; then
  printThis="The data ${thisLocalDataName} name ${thisLocalData} contains only whitespace \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsDots=$( echo "${thisLocalData}" |  grep -c '\.\.' )
if [ "${containsDots}" -ne 0 ]; then
  printThis="The data ${thisLocalDataName} name '${thisLocalData}' contains '..' in the name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

containsStars=$( echo "${thisLocalData}" |  grep -c '*' )
if [ "${containsStars}" -ne 0 ]; then
  printThis="The data ${thisLocalDataName} name '${thisLocalData}' contains '*' in the name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

weirdCharacters=$( echo "${thisLocalData}" | sed 's/[a-zA-Z0-9_-/.]*//g' )
if [ "${#weirdCharacters}" -ne 0 ]; then
  printThis="The data ${thisLocalDataName} name '${thisLocalData}' contains these weird characters '${weirdCharacters}' in the name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi

# Next test : whitespace in the middle of variable name !

stillContainsWhitespace=$( echo "${thisLocalData}" |  grep -c '\s' )
if [ "${stillContainsWhitespace}" -ne 0 ]; then
  printThis="The data ${thisLocalDataName} name '${thisLocalData}' contains whitespace in the middle of the name \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi
    
# Testing only, if we are having / in the beginning of the path ..

startWithSlash=$( echo ${thisLocalData} | grep -c '^/' )
if [ "${startWithSlash}" -ne 0 ]; then
startWithHome=$( echo ${thisLocalData} | grep -c '^'$HOME )
if [ "${startWithHome}" -eq 0 ]; then
  printThis="The data ${thisLocalDataName} name ${thisLocalData} points outside the local area ${HOME} \nEXITING"
  if [ "${thisIsTesterLoggerTest}" != "" ];then printToTesterLogFile; testerLooperSingleTestPassedOK=0; else printToLogFile; exit 1; fi
fi  
fi    
    
}

