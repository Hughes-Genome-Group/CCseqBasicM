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

# Debugging possibilities .. (good to have these turned off when in production, but can be turned on while still building ..)

# To be used when it is hard to find where in the code exactly the error originates from "cannot make dir already existing".
# Will lose the actual error message (the above "cannot make dir") - but instead will print the LINE and FILE where the error came from.

# This sub needs to be brough in to "somewhere" - and it will act on that script and all its children.
# do this by
# . debugHelpers.sh

# (more details and musings below)

# ------------------------------

# In-code error checking can also be done like this :

# set -e
# commandToBeTested
# set +e

# That checks only the command, and stops checking after that.

# ------------------------------

# To locate all instances of anything (here "runB" ) in all the codes (here only the .sh ),
# and printing the script full path and the matching lines :

# for file in $(find /home/molhaem2/telenius/CCseqBasic/CB5aDev/RELEASE -name '*.sh'); do echo $file; cat $file | grep 'runB' | grep -v '^\s*#'; done | grep -B 1 'runB'

# ------------------------------

# The below are taken from :
# https://stackoverflow.com/questions/64786/error-handling-in-bash

set -o pipefail  # trace ERR through pipes (the first error in pipe is reported. if not set, only last command of pipe is checked for error)
set -o errtrace  # trace ERR through 'time command' and other functions (jelena doesn't know what exactly this does)
set -o errexit   # set -e : exit the script if any statement returns a non-true return value

# set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
# The above is more trouble than it's worth as everything evaluated within $() block becomes unbound.
# And as bash is pretty good in giving "expecting numeric value" when these enter if comparisons, I don't think I need to worry about this.
# Also my coding practise is pretty solid in this.


# Usage of above and below :

# wherever you put the above, and the below sub err_report()
# you get that script failing in any 1) pipefail - piped commands failing, giving error of the first failed pipe
# 2) i-dont-know-what-exactly 3) at all normal errors
# So it doesn't glide through errors as it normally does.
# The below will report the line and script where it fails.
# But you will lose the actual error "directory kissa wasn't found",
# so the above is good to find stuff you don't know where originates from.
# Also it is a bit stupid as many commands report "fail" when the result goes to zero (like grep -c "whatever" ) or file is empty (even file testers report nonzero if file not found,
# even though that is the whole point of file tester)

# bringing this sub into any script with
# . debugHelpers.sh
# will give the 1) name of the code which failed 2) line number where command or any-point-of-piped-command gave non-zero exit status

# caveat : many of these commands give intentionally non-zero (like grep -c "" when the phrase is not found) - and thus will cry wolf.
#

# The musings about these topics are here :
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
# http://linuxcommand.org/lc3_wss0140.php

# Jelena's own musings about it are in :
# /home/molhaem2/telenius/WorkingDiaries/working_diary65.txt



err_report() {
echo
echo "RUN CRASHED ! - check qsub.err to see why !"
echo
echo "If your run passed folder1 (F1) succesfully - i.e. you have F2 or later folders formed correctly - you can restart in same folder, same run.sh :"
echo "Just add --onlyCCanalyser to the end of run command in run.sh, and start the run normally, in the same folder you crashed now (this will overrwrite your run from bowtie output onwards)."
echo
echo "If you are going to rerun a crashed run without using --onlyCCanalyser , copy your run script to a NEW EMPTY FOLDER,"
echo "and remember to delete your malformed /public/ hub-folders (especially the tracks.txt files) to avoid wrongly generated data hubs (if you are going to use same SAMPLE NAME as in the crashed run)" 
echo  
    
  echo "errexit on line $(caller)" >&2
  echo $1  >&2
  echo $2  >&2
  echo $3  >&2
  echo "$@" >&2
}

trap err_report ERR

