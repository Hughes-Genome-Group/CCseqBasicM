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


writeParametersToCapcLogFile(){

echo "------------------------------" >> parameters_capc.log
echo "PARALLEL ${PARALLEL} (FALSE= 0 , F1-F2parallel= 1 , F3-F7parallel= 2)" >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "Output log file ${QSUBOUTFILE}" > parameters_capc.log
echo "Output error log file ${QSUBERRFILE}" >> parameters_capc.log
echo "useTMPDIRforThis ${useTMPDIRforThis} (use cluster memory instead of local data area) " >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "CaptureTopPath ${CaptureTopPath}" >> parameters_capc.log
echo "CapturePipePath ${CapturePipePath}" >> parameters_capc.log
echo "confFolder ${confFolder}" >> parameters_capc.log
echo "RunScriptsPath ${RunScriptsPath}" >> parameters_capc.log
echo "CaptureFilterPath ${CaptureFilterPath}" >> parameters_capc.log
echo "CaptureDigestPath ${CaptureDigestPath}" >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "Sample ${Sample}" >> parameters_capc.log
echo "Read1 ${Read1}" >> parameters_capc.log
echo "Read2 ${Read2}" >> parameters_capc.log
echo "GENOME ${GENOME}" >> parameters_capc.log
echo "GenomeIndex ${GenomeIndex}" >> parameters_capc.log
echo "OligoFile ${OligoFile}" >> parameters_capc.log
echo "onlyCis ${onlyCis}" >> parameters_capc.log
echo "REenzyme ${REenzyme}" >> parameters_capc.log
echo "ONLY_CC_ANALYSER ${ONLY_CC_ANALYSER}" >> parameters_capc.log
echo "ONLY_HUB ${ONLY_HUB} : ONLY_RE_DIGESTS ${ONLY_RE_DIGESTS} ONLY_DIVIDE_OLIGOS ${ONLY_DIVIDE_OLIGOS}" >> parameters_capc.log
echo "ONLY_BLAT ${ONLY_BLAT}" >> parameters_capc.log
echo "TILED ${TILED}" >> parameters_capc.log
echo "PARALLEL ${PARALLEL} : PARALLELSUBSAMPLE ${PARALLELSUBSAMPLE}" >> parameters_capc.log

echo "------------------------------" >> parameters_capc.log
echo "TRIM ${TRIM}  (TRUE=1, FALSE=0)" >> parameters_capc.log
echo "QMIN ${QMIN}  (default 20)" >> parameters_capc.log

echo "CUSTOMAD ${CUSTOMAD}   (TRUE=1, FALSE= -1)"  >> parameters_capc.log

if [ "${CUSTOMAD}" -ne -1 ]; then

echo "ADA31 ${ADA31}"  >> parameters_capc.log
echo "ADA32 ${ADA32}"  >> parameters_capc.log
   
fi

echo "------------------------------" >> parameters_capc.log
echo "FLASH ${FLASH}  (TRUE=1, FALSE=0)" >> parameters_capc.log
echo "flashOverlap ${flashOverlap} (default 10)"  >> parameters_capc.log
echo "flashErrorTolerance ${flashErrorTolerance} (default 0.25)"  >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "saveDpnGenome ${saveDpnGenome}  (TRUE=1, FALSE=0)" >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "BOWTIEMEMORY ${BOWTIEMEMORY}"  >> parameters_capc.log
echo "CAPITAL_M ${CAPITAL_M}" >> parameters_capc.log
echo "LOWERCASE_M ${LOWERCASE_M}" >> parameters_capc.log
echo "otherBowtieParameters ${otherBowtieParameters}"  >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "reuseBLATpath ${reuseBLATpath}" >> parameters_capc.log
echo "stepSize ${stepSize}" >> parameters_capc.log
echo "tileSize ${tileSize}" >> parameters_capc.log
echo "minScore ${minScore}" >> parameters_capc.log
echo "maxIntron ${maxIntron}" >> parameters_capc.log
echo "oneOff ${oneOff}" >> parameters_capc.log
echo "extend ${extend}"  >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "sonicationSize ${sonicationSize}"  >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "ploidyFilter ${ploidyFilter}"  >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "WINDOW ${WINDOW}" >> parameters_capc.log
echo "INCREMENT ${INCREMENT}" >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "PublicPath ${PublicPath}" >> parameters_capc.log
echo "ServerUrl ${SERVERADDRESS}" >> parameters_capc.log
echo "JamesUrl ${JamesUrl}" >> parameters_capc.log
echo "ServerAndPath ${ServerAndPath}" >> parameters_capc.log
echo "otherParameters ${otherParameters}" >> parameters_capc.log
echo "------------------------------" >> parameters_capc.log
echo "GenomeFasta ${GenomeFasta}" >> parameters_capc.log
echo "BowtieGenome ${BowtieGenome}" >> parameters_capc.log
echo "ucscBuild ${ucscBuild}" >> parameters_capc.log


}


#------------------------------------------------
# Bringing in the parameters and their default values ..

QSUBOUTFILE="qsub.out"
QSUBERRFILE="qsub.err"

OligoFile="UNDEFINED_OLIGOFILE"
TRIM=1
FLASH=1
GENOME="UNDEFINED_GENOME"
WINDOW=200
INCREMENT=20
CAPITAL_M=0
LOWERCASE_M=0
LOWERCASE_V=-1
BOWTIEMEMORY="256"
Sample="sample"
Read1="UNDEFINED_READ1"
Read2="UNDEFINED_READ2"

CUSTOMAD=-1
ADA31="no"
ADA32="no"

# Parallel run or not ?
PARALLEL=0
PARALLELSUBSAMPLE="notInUse"

# trimgalore default
QMIN=20

# bowtie default
BOWTIE=1

# flash defaults
flashOverlap=10
flashErrorTolerance=0.25

saveDpnGenome=0

ucscBuild="UNDEFINED_UCSCBUILD"
ucscBuildName="UNDEFINED_UCSC_GENOME_NAME"
otherBowtie1Parameters=""
otherBowtie2Parameters=""
bowtie1MismatchBehavior=""
bowtie2MismatchBehavior=""

otherParameters=""
PublicPath="UNDETERMINED"

ploidyFilter=""
extend=20000

sonicationSize=300

# If we have many oligos, the stuff can be eased up by analysing only in cis.
onlyCis=0

# Blat flags
stepSize=5 # Jon default - James used blat default, which is "tileSize", in this case thus 11 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
tileSize=11 # Jon, James default
minScore=10 # Jon new default. Jon default before2016 and CC4 default until 080916 minScore=30 - James used minScore=30 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
maxIntron=4000 # blat default 750000- James used maxIntron=4000 (this was the setting in CC2 and CC3 - i.e filter versions VS101 and VS102)
oneOff=0 # oneOff=1 would allow 1 mismatch in tile (blat default = 0 - that is also CC3 and CC2 default)

# Whether we reuse blat results from earlier run ..
# Having this as "." will search from the run dir when blat is ran - so file will not be found, and thus BLAT will be ran normally.
reuseBLATpath='.'

REenzyme="dpnII"

# Skip other stages - assume input from this run has been ran earlier - to construct to THIS SAME FOLDER everything else
# but as the captureC analyser naturally crashed - this will jump right to the beginning of that part..
ONLY_CC_ANALYSER=0
# Rerun public folder generation and filling. Will not delete existing folder, but will overwrite all files (and start tracks.txt from scratch).
ONLY_HUB=0
# Only generate RE digest and RE digest blacklist
ONLY_RE_DIGESTS=0
# Only run the blatting
ONLY_BLAT=0
# Only running oligo division - to parallelise F2-F6 in the runs
ONLY_DIVIDE_OLIGOS=0
# Run as first steps of TILED analysis
TILED=0

strandSpecificDuplicates=0

# SGE parameter ${TEMPDIR} to be used to store on-the-way analysis files or not - default no.
useTMPDIRforThis=0

