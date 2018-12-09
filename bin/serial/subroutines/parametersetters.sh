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

setMparameter(){
   
mParameter=""

if [ "${CAPITAL_M}" -eq 0 ] ; then
    mParameter="-m ${LOWERCASE_M}"
else
    mParameter="-M ${CAPITAL_M}"
fi 
    
}

setParameters(){

#----------------------------------------------
# Listing current limitations, exiting if needed :

if [ "${LOWERCASE_M}" -ne 0 ] && [ "${CAPITAL_M}" -ne 0 ];
then
    printThis="Both -m and -M parameters cannot be set at the same time\nEXITING"
    printToLogFile
  exit 1
fi

#----------------------------------------------

if [ "${LOWERCASE_V}" -ne -1 ] && [ "${bowtie1MismatchBehavior}" != "" ]
then
    printThis="Bowtie1 does not allow setting -v with any other mismatch-reporting altering parameters ( --seedmms --seedlen --maqerr ) \nUse only -v, or (any) combination of --seedmms --seedlen --maqerr\nEXITING"
    printToLogFile
  exit 1
fi

if [ "${bowtie1MismatchBehavior}" != "" ]
then
    otherBowtie1Parameters="${otherBowtie1Parameters} ${bowtie1MismatchBehavior}"
fi

if [ "${LOWERCASE_V}" -ne -1 ]
then
    otherBowtie1Parameters="${otherBowtie1Parameters} -v ${LOWERCASE_V}"
fi


otherBowtie2Parameters="${otherBowtie2Parameters} ${bowtie2MismatchBehavior}"

#----------------------------------------------
#Setting the m and M parameters..

if [ "${LOWERCASE_M}" -ne 0 ] ;
then
   CAPITAL_M=0 
fi

if [ "${CAPITAL_M}" -ne 0 ];
then
   LOWERCASE_M=0
fi

if [ "${LOWERCASE_M}" -eq 0 ] && [ "${CAPITAL_M}" -eq 0 ];
then
    LOWERCASE_M=2
fi

#------------------------------------------------
# Custom adapter sequences..

if [ "${ADA31}" != "no"  ] || [ "${ADA32}" != "no" ] || [ "${ADA51}" != "no" ] || [ "${ADA52}" != "no" ] 
    then
    CUSTOMAD=1
fi

# ----------------------------------------------

# Setting the duplicate filter style !



if [ "${CCversion}" == "CM5" ] ; then
    echo
    echo "Duplicate filtering style CM5 selected ! "
    echo
elif [ "${CCversion}" == "CM3" ] ; then
    echo
    echo "Duplicate filtering style CM3 selected ! "
    echo
elif [ "${CCversion}" == "CM4" ] ; then
    echo
    echo "Duplicate filtering style CM4 selected ! "
    echo
else
   # Crashing here !
    printThis="Duplicate filtering style given wrong ! Give either --CCversion CM3 or --CCversion CM4 ( or default --CCversion CM5 )"
    printToLogFile
    printThis="You gave --CCversion ${CCversion}"
    printToLogFile
    printThis="EXITING ! "
    printToLogFile
    exit 1
fi


# ----------------------------------------------

# Setting the cutter type (fourcutter = default = fourcutter symmetric, like NlaIII or DpnII. sixcutter = sixcutter 1:5 asymmetric like HindIII)

if [ "${REenzyme}" == "hindIII" ] ; then
    otherParameters="$otherParameters --cutter sixcutter";
fi

}

testParametersForParseFailures(){
    
checkThis="${LOWERCASE_M}"
checkedName='LOWERCASE_M'
checkParse

checkThis="${CAPITAL_M}"
checkedName='CAPITAL_M'
checkParse

checkThis="${CapturesiteFile}"
checkedName='CapturesiteFile'
checkParse

checkThis="${WINDOW}"
checkedName='WINDOW'
checkParse

checkThis="${INCREMENT}"
checkedName='INCREMENT'
checkParse

checkThis="${Sample}"
checkedName='Sample'
checkParse

# This is not necessarily non-empty. not testing, thus.
# checkThis="${LOWERCASE_V}"
# checkedName='LOWERCASE_V'
# checkParse

checkThis="${CCversion}"
checkedName='CCversion'
checkParse

checkThis="${REenzyme}"
checkedName='REenzyme'
checkParse

checkThis="${ONLY_CC_ANALYSER}"
checkedName='ONLY_CC_ANALYSER'
checkParse

checkThis="${ONLY_HUB}"
checkedName='ONLY_HUB'
checkParse

checkThis="${ONLY_BLAT}"
checkedName='ONLY_BLAT'
checkParse

checkThis="${ONLY_DIVIDE_CAPTURESITES}"
checkedName='ONLY_DIVIDE_CAPTURESITES'
checkParse

checkThis="${ONLY_RE_DIGESTS}"
checkedName='ONLY_RE_DIGESTS'
checkParse

checkThis="${Read1}"
checkedName='Read1'
checkParse

checkThis="${Read2}"
checkedName='Read2'
checkParse

checkThis="${BOWTIE}"
checkedName='BOWTIE'
checkParse

checkThis="${BOWTIEMEMORY}"
checkedName='BOWTIEMEMORY'
checkParse

checkThis="${PARALLEL}"
checkedName='PARALLEL'
checkParse

checkThis="${saveDpnGenome}"
checkedName='saveDpnGenome'
checkParse

checkThis="${TRIM}"
checkedName='TRIM'
checkParse

checkThis="${GENOME}"
checkedName='GENOME'
checkParse

checkThis="${ADA31}"
checkedName='ADA31'
checkParse

checkThis="${ADA32}"
checkedName='ADA32'
checkParse

checkThis="${extend}"
checkedName='extend'
checkParse

checkThis="${sonicationSize}"
checkedName='sonicationSize'
checkParse

checkThis="${PublicPath}"
checkedName='PublicPath'
checkParse

checkThis="${QMIN}"
checkedName='QMIN'
checkParse

checkThis="${reuseBLATpath}"
checkedName='reuseBLATpath'
checkParse

checkThis="${FLASH}"
checkedName='FLASH'
checkParse

checkThis="${flashOverlap}"
checkedName='flashOverlap'
checkParse

checkThis="${flashErrorTolerance}"
checkedName='flashErrorTolerance'
checkParse

checkThis="${stepSize}"
checkedName='stepSize'
checkParse

checkThis="${tileSize}"
checkedName='tileSize'
checkParse

checkThis="${minScore}"
checkedName='minScore'
checkParse

checkThis="${maxIntron}"
checkedName='maxIntron'
checkParse

checkThis="${oneOff}"
checkedName='oneOff'
checkParse

checkThis="${QSUBOUTFILE}"
checkedName='QSUBOUTFILE'
checkParse

checkThis="${QSUBERRFILE}"
checkedName='QSUBERRFILE'
checkParse

    
}
