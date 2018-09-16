#!/bin/bash

# This script deletes all files which are not any more needed,
# if the run succeeded.

# Run instructions :

# nohup nice ./E_cleanupScript_toUse_afterSuccesfull_Run.sh > E_cleanup.log &

# See also step (2) below - if you want to also delete the main output BAM files of the run.

#_________________________________________________________

echo
echo "CM5 cleanup after a succesfull run .."
echo
echo
hostname
echo
pwd
echo
echo $0
echo
date
echo

#_________________________________________________________
# (1)
# FASTQ-wise analysis stage (folderB) : Delete whole folders where the sams are :
#_________________________________________________________

echo ''
echo 'FASTQ-wise analysis stage (folderB) : Delete whole folders where the sams are :'
echo 'rm -rf B_mapAndDivideFastqs/fastq_*/F1_beforeCCanalyser_*/LOOP5_filteredSams'

rm -rf B_mapAndDivideFastqs/fastq_*/F1_beforeCCanalyser_*/LOOP5_filteredSams

#_________________________________________________________
# (2)
# Oligo-wise bam files : Delete the main bams of the run.
#_________________________________________________________

# These are the main bams which are needed for --onlyCCanalyser runs.
# If you are sure you will not rerun your data (with different CCanalyser parameters) using --onlyCCanalyser,
# uncomment the lines below to delete these files.

# ####################################

# echo ''
# echo 'Oligo-wise bam files : Delete the main bams of the run.'
# echo 'rm -f C_combineOligoWise/chr*/*/*FLASHED_REdig.bam'
# rm -f C_combineOligoWise/chr*/*/*FLASHED_REdig.bam

# ####################################

#_________________________________________________________
# (3)
# CCanalyser bam files : Delete the header-only bam files (to avoid giving false impression)
#_________________________________________________________

# After the CCanalyser steps we already delete all bams.
# The combining stage (F6) does not to write the bams at all (except header lines) - these header-only bams are there just as a reminder,
# that a simple oneliner change within CCanalyser script can make them to be printed again. Inform Jelena if that is what you wish for the future
# and these will be real bam files again.

# CCanalyser stages : Delete the header-only bam files (to not to give false impression of their existence) :

echo ''
echo 'CCanalyser stages : Delete the header-only bam files (to not to give false impression of their existence) :'
rm -f D_analyseOligoWise/chr*/*/F6_greenGraphs_combined_*/COMBINED_*.bam

#_________________________________________________________
echo
date
echo
echo 'All done ! '
echo

