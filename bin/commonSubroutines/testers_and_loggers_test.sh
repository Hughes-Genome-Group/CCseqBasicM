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

# The tester - to be excecuted in the beginning of each script.
# If you want it to print all the errors - change the printout subroutine printToTesterLogFile() to not to print to /dev/null
  
# This tests only the RM MV CD testers.
# The file existence testers have been already tested in practise, and they work.
    

setMvCdRmTestVariables(){

# Tester variables, for tester subs !

whateverfolder=[]

whateverfolder[1]=""
whateverfolder[2]=" "
whateverfolder[3]="/whatever/this/is "
whateverfolder[4]=" /whatever/this/is"
whateverfolder[5]="/whatever/ this/is"
whateverfolder[6]="../whatever/this/is"
whateverfolder[7]="/whatever/../this/is"
whateverfolder[8]="/whatever/this/is/.."
whateverfolder[9]="*/whatever/this/is"
whateverfolder[10]="/whatever/*/this/is"
whateverfolder[11]="/whatever/this/is/*"
whateverfolder[12]="^/whatever/this/is"
whateverfolder[13]="/whatever/$/this/is"
whateverfolder[14]="/whatever/this/is/%"
whateverfolder[15]="/whatever/this/is"

whateverfile=[]

whateverfile[1]=""
whateverfile[2]=" "
whateverfile[3]="whatever "
whateverfile[4]=" whatever"
whateverfile[5]="what ever"
whateverfile[6]="/whatever/this/is"

}

# TESTING file existence, log file output general messages
testerSubsDir=$( echo $0 | sed 's/\/testers_and_loggers_test.sh$//' )
. ${testerSubsDir}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found for testing. Cannot continue ! \n EXITING !! "
    printToLogFile
    exit 1
fi

    
# Here all the lines we want to get printed :
# 
# [telenius@deva ~]$ cat  ~/CCseqBasic/CB5aDev/RELEASE/bin/testers_and_loggers.sh | grep printThis | sed 's/.*=\"//' | sed 's/\\n.*//' | grep -v echo
# 
# Input file not found or empty file : ${testedFile}  
# Temporary file not found or empty file : ${testedFile} 
# File not found or cannot be read or empty file : ${testedFile} 
# Parse fail - zero lenght variable ${checkedName} ! 
# Parse fail - variable ${checkedName} only contains whitespace ! 
# Parse fail - variable ${checkedName}='${checkThis}' contains whitespace in the middle of variable ! 
# Parse fail - zero lenght variable ${checkedName} ! 
# Parse fail - variable ${checkedName} only contains whitespace ! 
# Parse fail - variable ${checkedName}='${checkThis}' contains whitespace in the middle of variable ! 
# Parse fail - variable ${checkedName}='${checkThis}' contains slashes in the middle of variable  (i.e. is not a file only - but a PATH ) ! 
# Cannot move as moveThis variable has zero lenght in move command 
# Cannot move as moveThis variable contains only whitespace in move command 
# Cannot move as moveThis variable '${moveThis}' contains whitespace in the middle of variable name in move command 
# Cannot move as moveThis variable ${moveThis} points outside the local area ${HOME} in move command 
# Cannot move as moveToHere variable has zero lenght in move command 
# Cannot move as moveToHere variable contains only whitespace in move command 
# Cannot move as moveToHere variable '${moveToHere}' contains whitespace in the middle of variable name in move command 
# Cannot move as moveToHere variable ${moveToHere} points outside the local area ${HOME} in move command 
# Cannot cd as cdToThis variable has zero lenght in cd command 
# Cannot cd as cdToThis variable contains only whitespace in cd command 
# Cannot cd as cdToThis variable '${cdToThis}' contains whitespace in the middle of variable name in cd command 
# Cannot cd as cdToThis variable ${cdToThis} points outside the local area ${HOME} in cd command 
# Cannot rm as rmThis variable has zero lenght in rm command 
# Cannot rm as rmThis variable contains only whitespace in rm command 
# Cannot rm as rmThis variable '${rmThis}' contains whitespace in the middle of variable name in rm command 
# Cannot rm as rmThis variable ${rmThis} points outside the local area ${HOME} in rm command 
# The public folder ${thisPublicFolderName} folder name ${thisPublicFolder} has zero lenght 
# The public folder ${thisPublicFolderName} folder name ${thisPublicFolder} contains only whitespace 
# The public folder ${thisPublicFolderName} folder name '${thisPublicFolder}' contains whitespace in the middle of the folder name 
# The public folder ${thisPublicFolderName} ${thisPublicFolder} is not owned by $(whoami), so refusing to meddle with it ! 
# The public folder holding file ${thisPublicFolderName} ${thisPublicFolder} is not owned by $(whoami), so refusing to meddle with it ! 
# The data ${thisLocalDataName} name ${thisLocalData} has zero lenght 
# The data ${thisLocalDataName} name ${thisLocalData} contains only whitespace 
# The data ${thisLocalDataName} name '${thisLocalData}' contains whitespace in the middle of the folder name 
# The data ${thisLocalDataName} name ${thisLocalData} points outside the local area ${HOME} 
# 
# [telenius@deva ~]$ 

# Here all the subroutines we want to test :

# [telenius@deva ~]$ cat  ~/CCseqBasic/CB5aDev/RELEASE/bin/testers_and_loggers.sh | grep '()' | tr '(' ' ' | sed 's/\s.*//' 
# 
# doInputFileTesting
# doTempFileTesting
# fileTesting
# checkParse
# checkParseEnsureNoSlashes
# checkMoveSafety
# checkCdSafety
# checkRemoveSafety
# isThisPublicFolderParsedFineAndMineToMeddle
# isThisLocalDataParsedFineAndMineToMeddle
#
# [telenius@deva ~]$

# ---------------------------------------------------------------------    
    
# We want to keep this zero - we want all the test cases to fail.
sumOfNotCrashedCommands=0

# Total count of tests
totalCountOfTests=0

# ---------------------------------------------------------------------

whateverfolder=[]
whateverfile=[]

thisIsTesterLoggerTest=1

printThis="-----------------------------------"
printToTesterLogFile
printThis="thisIsTesterLoggerTest ${thisIsTesterLoggerTest}"
printToTesterLogFile

printThis="testerLooperSingleTestPassedOK ${testerLooperSingleTestPassedOK}"
printToTesterLogFile

setMvCdRmTestVariables

# EMPTY FOLDER NAME :                   whateverfolder[1]
# WHITESPACE-ONLY FOLDER NAME :         whateverfolder[2]
# ENDS WITH WITHESPACE FOLDER NAME :    whateverfolder[3]
# STARTS WITH WITHESPACE FOLDER NAME :  whateverfolder[4]
# WHITESPACE IN MIDDLE OF FOLDER NAME : whateverfolder[5]
# FOLDER NOT INSIDE HOME :              whateverfolder[6]

# EMPTY FILE NAME :                     whateverfile[1]
# WHITESPACE-ONLY FILE NAME :           whateverfile[2]
# ENDS WITH WITHESPACE FILE NAME :      whateverfile[3]
# STARTS WITH WITHESPACE FILE NAME :    whateverfile[4]
# WHITESPACE IN MIDDLE OF FILE NAME :   whateverfile[5]
# FILE NOT INSIDE HOME :                whateverfile[6]

# PARSE CONTAINS SLASHES :              whateverfile[6]


# ---------------------------------------------------------------------

# checkParse

# Parse fail - zero lenght variable ${checkedName} ! 
# Parse fail - variable ${checkedName} only contains whitespace ! 
# Parse fail - variable ${checkedName}='${checkThis}' contains whitespace in the middle of variable ! 

for i in `seq 1 14`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="checkParse folder $i : '${whateverfolder[$i]}' "
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1
checkThis="${whateverfolder[$i]}"
checkedName=$i
checkParse

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))

done


# checkParseEnsureNoSlashes

# Parse fail - zero lenght variable ${checkedName} ! 
# Parse fail - variable ${checkedName} only contains whitespace ! 
# Parse fail - variable ${checkedName}='${checkThis}' contains whitespace in the middle of variable ! 
# Parse fail - variable ${checkedName}='${checkThis}' contains slashes in the middle of variable  (i.e. is not a file only - but a PATH ) !

for i in `seq 1 15`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="checkParseEnsureNoSlashes folder $i  : '${whateverfolder[$i]}'"
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1
checkThis="${whateverfolder[i]}"
checkedName=$i
checkParseEnsureNoSlashes

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
    
done

# ---------------------------------------------------------------------

# checkMoveSafety

# Cannot move as moveThis variable has zero lenght in move command 
# Cannot move as moveThis variable contains only whitespace in move command 
# Cannot move as moveThis variable '${moveThis}' contains whitespace in the middle of variable name in move command 
# Cannot move as moveThis variable ${moveThis} points outside the local area ${HOME} in move command

for i in `seq 1 15`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="checkMoveSafety moveThis folder $i : ${whateverfolder[i]}"
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1
moveThis="${whateverfolder[i]}"
moveToHere="whateverfolder"
moveCommand=$i
checkMoveSafety

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
   
done

# Cannot move as moveToHere variable has zero lenght in move command 
# Cannot move as moveToHere variable contains only whitespace in move command 
# Cannot move as moveToHere variable '${moveToHere}' contains whitespace in the middle of variable name in move command 
# Cannot move as moveToHere variable ${moveToHere} points outside the local area ${HOME} in move command 

for i in `seq 1 15`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="checkMoveSafety moveToHere folder $i : ${whateverfolder[i]}"
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1
moveThis="whateverfolder"
moveToHere="${whateverfolder[i]}"
moveCommand=$i
checkMoveSafety

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
   
done

# ---------------------------------------------------------------------

# checkCdSafety

# Cannot cd as cdToThis variable has zero lenght in cd command 
# Cannot cd as cdToThis variable contains only whitespace in cd command 
# Cannot cd as cdToThis variable '${cdToThis}' contains whitespace in the middle of variable name in cd command 
# Cannot cd as cdToThis variable ${cdToThis} points outside the local area ${HOME} in cd command

for i in `seq 1 15`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="checkCdSafety folder $i"
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1

cdToThis="${whateverfolder[i]}"
cdCommand=$i
checkCdSafety

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
    
done


# ---------------------------------------------------------------------

# checkRemoveSafety

# Cannot rm as rmThis variable has zero lenght in rm command 
# Cannot rm as rmThis variable contains only whitespace in rm command 
# Cannot rm as rmThis variable '${rmThis}' contains whitespace in the middle of variable name in rm command 
# Cannot rm as rmThis variable ${rmThis} points outside the local area ${HOME} in rm command

for i in `seq 1 15`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="checkRemoveSafety folder $i : ${whateverfolder[i]}"
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1

rmToThis="${whateverfolder[i]}"
rmCommand=$i
checkRemoveSafety

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
    
done

# ---------------------------------------------------------------------

# isThisPublicFolderParsedFineAndMineToMeddle

# The public folder ${thisPublicFolderName} folder name ${thisPublicFolder} has zero lenght 
# The public folder ${thisPublicFolderName} folder name ${thisPublicFolder} contains only whitespace 
# The public folder ${thisPublicFolderName} folder name '${thisPublicFolder}' contains whitespace in the middle of the folder name 
# The public folder ${thisPublicFolderName} ${thisPublicFolder} is not owned by $(whoami), so refusing to meddle with it ! 
# The public folder holding file ${thisPublicFolderName} ${thisPublicFolder} is not owned by $(whoami), so refusing to meddle with it ! 

for i in `seq 1 15`
do

printThis="-----------------------------------"
printToTesterLogFile
printThis="isThisPublicFolderParsedFineAndMineToMeddle folder $i : ${whateverfolder[i]}"
printToTesterLogFile

 # we want this to go to zero
testerLooperSingleTestPassedOK=1

thisPublicFolder="${whateverfolder[i]}"
thisPublicFolderName=$i
isThisPublicFolderParsedFineAndMineToMeddle 

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
    
done

# ---------------------------------------------------------------------

# isThisLocalDataParsedFineAndMineToMeddle

# The data ${thisLocalDataName} name ${thisLocalData} has zero lenght 
# The data ${thisLocalDataName} name ${thisLocalData} contains only whitespace 
# The data ${thisLocalDataName} name '${thisLocalData}' contains whitespace in the middle of the folder name 
# The data ${thisLocalDataName} name ${thisLocalData} points outside the local area ${HOME}

for i in `seq 1 15`
do

 # we want this to go to zero
testerLooperSingleTestPassedOK=1

printThis="-----------------------------------"
printToTesterLogFile
printThis="isThisLocalDataParsedFineAndMineToMeddle folder $i : ${whateverfolder[i]}"
printToTesterLogFile

thisLocalData="${whateverfolder[i]}"
thisLocalDataName=$i
isThisLocalDataParsedFineAndMineToMeddle

sumOfNotCrashedCommands=$((${sumOfNotCrashedCommands}+${testerLooperSingleTestPassedOK}))
totalCountOfTests=$((${totalCountOfTests}+1))
    
done

    
# ---------------------------------------------------------------------

if [ "${sumOfNotCrashedCommands}" -ne 0 ]; then
    printThis="Safety subroutine test in testers_and_loggers.sh failed. \n ${sumOfNotCrashedCommands} / ${totalCountOfTests} of tests failed to notice something was wrong in test data. \n Cannot continue with malfunctioning safety features ! EXITING !!"
    printToTesterLogFile
    exit 1
fi


