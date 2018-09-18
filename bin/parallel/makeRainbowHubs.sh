#!/bin/bash

# The color setting subroutines and track making subroutines

# echo $0

thisScriptName=$(echo $0 | sed 's/\s.*//')
. $(dirname ${thisScriptName})/bashHelpers/rainbowHubHelpers.sh

# -----------------------

# Folders RAW and PREfiltered would be done like this
# folder=$1
# subfolder=$2

# COMBINED has only one run - so can skip folder (didn't make subs to differentiate as COMBINED is only one we want)
# and we don't have subfolder any more.

hubsamplename=$1
parentname=$2
ucscBuildName=$3

doGenomeAndHub



