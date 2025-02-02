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

setPloidyPath(){
    
ploidyPath="UNDETERMINED"
    
for g in $( seq 0 $((${#genomesWhichHaveBlacklist[@]}-1)) ); do

# echo ${supportedGenomes[$g]}

if [ "${genomesWhichHaveBlacklist[$g]}" == "${GENOME}" ]; then
    ploidyPath="${BLACKLIST[$g]}"
fi

done 
    
if [ "${ploidyPath}" == "UNDETERMINED" ]; then
  echo
  echo "NOTE !! Genome build " ${GENOME} " is not supported in BLACKLIST FILTERING - turning blacklist filtering off !"
  echo
  echo  >&2
  echo "NOTE !! Genome build " ${GENOME} " is not supported in BLACKLIST FILTERING - turning blacklist filtering off !"  >&2
  echo  >&2
  
  weHavePloidyFile=0;

else 
  weHavePloidyFile=1;
fi

# Check that the file exists, and informing user that the path was set ..
if [ "${weHavePloidyFile}" -eq 1 ] ; then

if [ ! -e "${ploidyPath}" ] || [ ! -r "${ploidyPath}" ] || [ ! -s "${ploidyPath}" ]; then
  echo "Blacklisted regions file not found - for genome " ${GENOME} " - file ${ploidyPath} not found or empty file - aborting !"  >&2
  exit 1     
fi

echo
echo "Set BLACKLIST FILTERING file : ${ploidyPath}"

fi

}

