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

# This file fetches the fastqs in plateScreen96.sh style, the way that code was 21Feb2018

# Plate96screen code states this : The subs below are copied from GEObuilder (as it was 20Feb2017) - and modified here.

fastqParameterFileReader(){
    
    nameList=($( cut -f 1 ./PIPE_fastqPaths.txt ))
    
    # Check how many columns we have.
    test=0
    if [ "${SINGLE_END}" -eq 0 ] ; then  
    test=$( cut -f 4 ./PIPE_fastqPaths.txt | grep -vc "^\s*$" )
    else
    test=$( cut -f 3 ./PIPE_fastqPaths.txt | grep -vc "^\s*$" )
    fi

    # If we have 3 columns paired end, or 2 columns single end :
    if [ "${test}" -eq "0" ]; then

    fileList1=($( cut -f 2 ./PIPE_fastqPaths.txt ))
    
    if [ "${SINGLE_END}" -eq 0 ] ; then
    fileList2=($( cut -f 3 ./PIPE_fastqPaths.txt ))
    fi
    
    # If we have 4 columns paired end, or 3 columns single end :
    else

    if [ "${SINGLE_END}" -eq 0 ] ; then
    cut -f 2,4 ./PIPE_fastqPaths.txt | awk '{ print $2"\t"$1 }' | tr "," "\t" | awk '{for (i=2;i<=NF;i++) printf "%s/%s,",$1,$i; print ""}' | sed 's/,$//' | sed 's/\/\//\//' > forRead1.txt
    cut -f 3,4 ./PIPE_fastqPaths.txt | awk '{ print $2"\t"$1 }' | tr "," "\t" | awk '{for (i=2;i<=NF;i++) printf "%s/%s,",$1,$i; print ""}' | sed 's/,$//' | sed 's/\/\//\//'  > forRead2.txt
    
    fileList1=($( cat ./forRead1.txt ))
    fileList2=($( cat ./forRead2.txt ))
    else
    cut -f 2,3 ./PIPE_fastqPaths.txt | awk '{ print $2"\t"$1 }' | tr "," "\t" | awk '{for (i=2;i<=NF;i++) printf "%s/%s,",$1,$i; print ""}' | sed 's/,$//' | sed 's/\/\//\//' > forRead1.txt
    fileList1=($( cat ./forRead1.txt ))
    fi
    
    fi

    rm -f forRead1.txt forRead2.txt
    
    
}

