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

# This is the legacy excecution of CB5 pipe.
# ( will be the main user case until the new versions _serial.sh and _parallel.sh are built and tested )

# The code will differ ONLY within this main analyser script from the _serial.sh and _parallel.sh
# All underlying scripts and their changes are fully affecting the functioning of this legacy run type as well.
# (some of the user cases of those and some codes in  their entirety are of course not used in this legacy version)

# --> the point of this run type is to get testing for the code changes "early on" to catch bugs and issues not to do with parallelisation itself
# (to catch the bugs which may happen just because the codes are meddled to make parallelisation support possible)

# The pipe will run exactly as before in CB5 : input fastq with --R1 and --R2 flags, unpacked combined files only, and oligo file treated as single entity (no oligo bunches)
# we will also not generate the "fancy" output hub, at least in the first stage. Depending how it is decided to do with the visualisation, this may change,
# and also the legacy run may gain the nice new overlay track as a separate hub.

# A significant plus of this temporary stage of development is, that it natively supports run mode --onlyBlat

# ------------------------------------------

CCversion="CM5"
captureScript="analyseMappedReads"
CCseqBasicVersion="CCseqBasic5"

# -----------------------------------------

MainScriptPath="$( echo $0 | sed 's/\/'${CCseqBasicVersion}'.sh$//' )"

CaptureAnalysisPath="${MainScriptPath}/bin/serial"

# -----------------------------------------

# Help-only run type ..

if [ $# -eq 1 ]
then
parameterList=$@
if [ ${parameterList} == "-h" ] || [ ${parameterList} == "--help" ]
then
. ${CaptureAnalysisPath}/subroutines/usageAndVersion.sh
usage
exit

fi
fi

#------------------------------------------

mainScriptParameterList=$@

${CaptureAnalysisPath}/mainRunner.sh ${mainScriptParameterList}

#------------------------------------------

exit 0


