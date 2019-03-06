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

runTempCommands(){
chmod u=rwx TEMP_commands.sh
echo
cat TEMP_commands.sh
echo >> "/dev/stderr"
echo "Running following commands :" >> "/dev/stderr"
cat TEMP_commands.sh >> "/dev/stderr"
echo "Possible error messages while running abovelisted commands :" >> "/dev/stderr"
echo >> "/dev/stderr"
setStringentFailForTheFollowing
./TEMP_commands.sh
stopStringentFailAfterTheAbove
rm -f TEMP_commands.sh    
}

#------------------------------------------

# Loading subroutines in ..

echo "Loading subroutines in .."

# /home/molhaem2/telenius/CCseqBasic/CCseqBasic4/bin/runscripts/filterArtifactMappers/filter.sh
CaptureTopPath="$( echo $0 | sed 's/\/runscripts\/filterArtifactMappers\/1_blat.sh//' )"

CapturePipePath="${CaptureTopPath}/subroutines"

# DEBUG SUBROUTINES - for the situations all hell breaks loose
# . ${CapturePipePath}/debugHelpers.sh

# TESTING file existence, log file output general messages
CaptureCommonHelpersPath=$( dirname ${CaptureTopPath} )"/commonSubroutines"
. ${CaptureCommonHelpersPath}/testers_and_loggers.sh
if [ "$?" -ne 0 ]; then
    printThis="testers_and_loggers.sh safety routines cannot be found in $0. Cannot continue without safety features turned on ! \n EXITING !! "
    printToLogFile
    exit 1
fi



#------------------------------------------


# This is the first blat-filter automaton - test code built 11/Sep/2015 by Jelena

#for capturesiteName in capturesiteFile
#this will be some kind of awk thing - commands generated via reading in the capture-site (REfragment) file..

# CapturePipePath="/home/molhaem2/telenius/CC2/norm/VS101"

PathForReuseBlatResults="."

CaptureFilterPath="UNDEFINED"

capturesitefile="UNDEFINED"
genomefasta="UNDEFINED"
recoordinatefile="UNDEFINED"
ucscBuild="UNDEFINED"
extend="20000"
onlyCis=0

# full path to parameter file
blatparams="UNDEFINED"

OPTS=`getopt -o o:,f:,r:,p:,u:,e: --long genomefasta:,capturesitefile:,refile:,pipepath:,ucscbuild:,extend:,blatparams:,reusefile:,onlyCis: -- "$@"`
if [ $? != 0 ]
then
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -o) capturesitefile=$2 ; shift 2;;
        -f) genomefasta=$2 ; shift 2;;
        -r) recoordinatefile=$2 ; shift 2;;
        -p) CaptureFilterPath=$2 ; shift 2;;
        -u) ucscBuild=$2 ; shift 2;;
        -e) extend=$2 ; shift 2;;        
        --capturesitefile) capturesitefile=$2 ; shift 2;;
        --genomefasta) genomefasta=$2 ; shift 2;;
        --refile) recoordinatefile=$2 ; shift 2;;
        --pipepath) CaptureFilterPath=$2 ; shift 2;;
        --ucscbuild) ucscBuild=$2 ; shift 2;;
        --extend) extend=$2 ; shift 2;;
        --blatparams) blatparams=$2 ; shift 2;;
        --reusefile) PathForReuseBlatResults=$2 ; shift 2;;
        --onlyCis) onlyCis=$2; shift 2;;
        --) shift; break;;
    esac
done

echo
echo "blatting with 1_blat.sh"
echo
echo "Starting run with parameters :"
echo

# ------------------------------------------
# Setting $HOME to the current dir
echo 'Turning on safety measures for cd rm and mv commands in $0 - restricting script to file operations "from this dir below" only :'
HOME=$(pwd)
echo $HOME
echo
# - to enable us to track mv rm and cd commands
# from taking over the world accidentally
# this is done in testers_and_loggers.sh subroutines, which are to be used
# every time something gets parsed, and after that when the parsed value is used to mv cd or rm anything
# ------------------------------------------
# Test the testers and loggers ..

printThis="Testing the tester subroutines in $0 .."
printToLogFile
printThis="${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err"
printToLogFile
   
${CaptureCommonHelpersPath}/testers_and_loggers_test.sh 1> testers_and_loggers_test.out 2> testers_and_loggers_test.err
# The above exits if any of the tests don't work properly.

# The below exits if the logger test sub wasn't found (path above wrong or file not found)
if [ "$?" -ne 0 ]; then
    printThis="Testing testers_and_loggers.sh safety routines failed in $0 . Cannot continue without testing safety features ! \n EXITING !! "
    printToLogFile
    exit 1
else
    printThis="Testing the tester subroutines completed - continuing ! "
    printToLogFile
fi

# Comment this out, if you want to save these files :
rm -f testers_and_loggers_test.out testers_and_loggers_test.err

#------------------------------------------

echo "capturesitefile ${capturesitefile}"
echo "genomefasta ${genomefasta}"
echo "recoordinatefile ${recoordinatefile}"
echo "CapturePipePath ${CapturePipePath}"
echo "CaptureFilterPath ${CaptureFilterPath}"
echo "ucscBuild ${ucscBuild}"
echo

#module unload bedtools
#module unload blat
#module load bedtools/2.17.0
#module load blat/35
module list 2>&1

echo
echo "Dividing the capture-site (REfragment) file to one-liners.."
echo "Dividing the capture-site (REfragment) file to one-liners.."  >> "/dev/stderr"
# Dividing the capture-site (REfragment) file to one-liners like :
# chr     str     stp (for the exclusion fragments in the capture-site (REfragment) coordinate file)

echo '#!/bin/bash ' > TEMP_commands.sh
echo "capturesitefile=${capturesitefile}"  >> TEMP_commands.sh
cat ${capturesitefile} | awk '{print "cat ${capturesitefile} | grep \"^"$1"\\s\" | awk * > TEMP_"$1"_coordinate.bed"}' | sed 's/*/*\{print \"chr\"$5\"\\t\"$6\"\\t\"$7\}*/' | tr "*" "'" >> TEMP_commands.sh
echo "" >> TEMP_commands.sh

# above results in lines like :
# cat ${capturesitefile} | grep Hba-1 | awk '{print "chr"$5"\t"$6"\t"$7}' > TEMP_Hba-1_coordinate.bed

runTempCommands

# Run fasta generation to all these exlusion fragment coordinates
echo
echo "Run fasta generation to all these exlusion fragment coordinates.."
echo "Run fasta generation to all these exlusion fragment coordinates.."  >> "/dev/stderr"

for file in TEMP*coordinate.bed
do

echo "bedtools getfasta -fi ${genomefasta} -bed ${file} -fo ${file}.fa"
setStringentFailForTheFollowing
bedtools getfasta -fi ${genomefasta} -bed ${file} -fo ${file}.fa
stopStringentFailAfterTheAbove
if [ "$?" -ne 0 ]; then
    printThis="bedtools getfasta failed for exclusion fragment file ${file} ! \n EXITING !! "
    printToLogFile
    exit 1
fi

done

rm -f TEMP*coordinate.bed

for file in TEMP*coordinate.bed.fa
do

sed -i 's/a/A/g' $file
sed -i 's/t/T/g' $file
sed -i 's/c/C/g' $file
sed -i 's/g/G/g' $file

done

# Running blat for these sequences (exclusion fragment sequences)
echo 
echo "Running blat for these sequences (exclusion fragment sequences).."
echo "Running blat for these sequences (exclusion fragment sequences).."  >> "/dev/stderr"

blatParams=$( cat ${blatparams} )

for file in TEMP*coordinate.bed.fa
do

basename=$( echo $file | sed 's/_coordinate.bed.fa//' )



# If cannot find the file - i.e. if this is the first run for these capture-site (REfragment)s,
#   or if the earlier run didn't find any blat hits (this is unintended consequence of the safety feature :
#   - we don't want to SKIP blat filter for all capture-site (REfragment)s BECAUSE OF FILE ADDRESS TYPO here.. )

weRunBLAT=1
blatFileIsEmpty=1
if [ -e ${PathForReuseBlatResults}/${basename}_blat.psl ]
then
weRunBLAT=0
fi
if [ -s ${PathForReuseBlatResults}/${basename}_blat.psl ]
then   
blatFileIsEmpty=0
fi

if [ "${weRunBLAT}" -eq "1" ]
then
    
    if [ "${onlyCis}" -eq "1" ]; then
        TEMPchr=$( head -n 1 ${file} | sed 's/^>//' | sed 's/^C/c/' | sed 's/:.*//' )
        echo "ONLY CIS BLAT : viewpoint ${basename} , Cis chromosome : ${TEMPchr}"
        cat ${ucscBuild} | grep '^'${TEMPchr}'\s' | awk '{print $1"\t0\t"$2}' > TEMP.bed
        setStringentFailForTheFollowing
        bedtools getfasta -fi ${genomefasta} -bed TEMP.bed -fo TEMP.fa
        stopStringentFailAfterTheAbove
        if [ "$?" -ne 0 ]; then
        printThis="bedtools getfasta failed for CIS chromosome genome gasta generation for cromosome ${TEMPchr} ! \n EXITING !! "
        printToLogFile
        exit 1
        fi
        
        sed -i 's/:.*//' TEMP.fa
        rm -f TEMP.bed
        echo "blat ${blatParams} TEMP.fa ${file} ${basename}_blat.psl"
        echo "blat ${blatParams} TEMP.fa ${file} ${basename}_blat.psl" >> "/dev/stderr"
        setStringentFailForTheFollowing
        blat ${blatParams} TEMP.fa ${file} ${basename}_blat.psl
        stopStringentFailAfterTheAbove
        if [ "$?" -ne 0 ]; then
        printThis="CIS blat failed for capture-site (REfragment) ${basename} ! \n EXITING !! "
        printToLogFile
        exit 1
        fi
        rm -f TEMP.fa
        
    else
    echo "blat ${blatParams} ${genomefasta} ${file} ${basename}_blat.psl"
    echo "blat ${blatParams} ${genomefasta} ${file} ${basename}_blat.psl" >> "/dev/stderr"
    setStringentFailForTheFollowing
    blat ${blatParams} ${genomefasta} ${file} ${basename}_blat.psl
    stopStringentFailAfterTheAbove
    if [ "$?" -ne 0 ]; then
    printThis="Blat failed for capture-site (REfragment) ${basename} ! \n EXITING !! "
    printToLogFile
    exit 1
    fi

    fi

else

echo "Found file ${PathForReuseBlatResults}/${basename}_blat.psl - skipping blat for that capture-site (REfragment), using the found file instead !"
echo "Found file ${PathForReuseBlatResults}/${basename}_blat.psl - skipping blat and that capture-site (REfragment), using the found file instead !" >> "/dev/stderr"

if [ "${blatFileIsEmpty}" -eq "1" ]
then
echo "WARNING ! Found file ${PathForReuseBlatResults}/${basename}_blat.psl - is EMPTY FILE. This means NO BLAT FILTERING will be done to this oligo (as no homology regions are listed) !"
echo "WARNING ! Found file ${PathForReuseBlatResults}/${basename}_blat.psl - is EMPTY FILE. This means NO BLAT FILTERING will be done to this oligo (as no homology regions are listed) !" >> "/dev/stderr"    
fi

cp ${PathForReuseBlatResults}/${basename}_blat.psl .
if [ "$?" -ne 0 ]; then
printThis="Couldn't copy readymade blat psl file for ${basename} ! \n EXITING !! "
printToLogFile
exit 1
fi

fi

done

rm -f TEMP*coordinate.bed.fa

# Works upto here.. (10/09/15)

# Remove the files which didn't get any results in blat - these exclusion regions won't thus need a blat filter!
echo 
echo "Removing the files which didn't get any results in blat - these exclusion regions won't thus need a blat filter!.."
echo "Removing the files which didn't get any results in blat - these exclusion regions won't thus need a blat filter!.."  >> "/dev/stderr"

for file in TEMP*blat.psl
do

if [ ! -s $file ]
then

rmCommand='rm -f $file'
rmThis="$file"
checkRemoveSafety
rm -f $file

fi

done

echo
echo "Files for blat filtering :"
ls -lht |  grep blat.psl

# Preparing the input files for the RE-fragment generation perl script
echo 
echo "Preparing the input files for the RE-fragment generation perl script.."
echo "Preparing the input files for the RE-fragment generation perl script.."  >> "/dev/stderr"


echo '#!/bin/bash ' > TEMP_commands.sh
echo "capturesitefile=${capturesitefile}"  >> TEMP_commands.sh
cat ${capturesitefile} | awk '{print "cat ${capturesitefile} | grep \"^"$1"\\s\" > TEMP_"$1"_capturesitecoordinate.txt"}' >> TEMP_commands.sh
echo "" >> TEMP_commands.sh

runTempCommands

#for file in TEMP*blat.psl
#do   

#cat ${file} | grep chr | sed 's/\s\s*/\t/' > TEMPFILE
# moveCommand='mv -f TEMPFILE ${file}'
# moveThis="TEMPFILE"
# moveToHere="${file}"
# checkMoveSafety  
# mv -f TEMPFILE ${file}

#done



# Running the psl parser - change blat output to RE fragment coordinates to be removed from the files..
echo 
echo "Running the psl parser - change blat output to RE fragment coordinates to be removed from the files.."
echo "Running the psl parser - change blat output to RE fragment coordinates to be removed from the files.."  >> "/dev/stderr"

for file in TEMP*blat.psl
do   

basename=$( echo $file | sed 's/_blat.psl//' )
echo
echo "-----------------------"
echo "perl ${CaptureFilterPath}/2_psl_parser.pl -f ${file} -o ${basename}_capturesitecoordinate.txt -a ${capturesitefile} -r ${recoordinatefile}"
echo "perl ${CaptureFilterPath}/2_psl_parser.pl -f ${file} -o ${basename}_capturesitecoordinate.txt -a ${capturesitefile} -r ${recoordinatefile}" >> "/dev/stderr"
echo
setStringentFailForTheFollowing
perl ${CaptureFilterPath}/2_psl_parser.pl -f ${file} -o ${basename}_capturesitecoordinate.txt -a ${capturesitefile} -r ${recoordinatefile}
stopStringentFailAfterTheAbove
if [ "$?" -ne 0 ]; then
printThis="Run filtering script (2_psl_parser.pl) for ${basename} crashed ! \n EXITING !! "
printToLogFile
exit 1
fi

done

rm -f TEMP*_capturesitecoordinate.txt

# To reuse the blat coordinates..
rm -rf REUSE_blat
mkdir REUSE_blat
mv -f TEMP*blat.psl REUSE_blat/.
if [ "$?" -ne 0 ]; then
printThis="Couldn't move generated psl files to folder REUSE_blat ! \n EXITING !! "
printToLogFile
exit 1
fi

# Saving only files which have content :

for file in *_blat_filter.gfc
do

if [ ! -s $file ]
then

rmCommand='rm -f $file'
rmThis="$file"
checkRemoveSafety
rm -f $file

fi

done

# Change names to not contain TEMP

for file in *_blat_filter.gfc
do
    
if [ -s $file ]
then

newname=$( echo $file | sed 's/TEMP_//' )

moveCommand='mv -f $file ${newname}'
moveThis="$file"
moveToHere="${newname}"
checkMoveSafety   
mv -f $file ${newname}
if [ "$?" -ne 0 ]; then
printThis="Couldn't rename output file $file to become ${newname} ! \n EXITING !! "
printToLogFile
exit 1
fi

fi

done

# Here we bedtools slop it - to extend 20 000 bases both directions..
echo
echo "Extending blat filter by ${extend} bases to both directions (default 20000 bases) .."
echo "Extending blat filter by ${extend} bases to both directions.."  >> "/dev/stderr"
echo

# Here we also transform our blat filter to gff file :
#[telenius@deva captureVS1_VS2comparison_030915]$ head testblatfilter/7thtry/TEMP_SOX2_blat_filter.gfc | sed 's/:/\tcol2\tcol3\t/' | sed 's/-/\t/' | sed 's/$/\t6\t7\t8\tfacet9=0/'
#chr8    col2    col3    12396275        12396506        6       7       8       facet9=0
#chr8    col2    col3    12396507        12396601        6       7       8       facet9=0

for file in *_blat_filter.gfc
do

if [ -s $file ]
then

newname=$( echo $file | sed 's/.gfc$//' )
cat ${file} | sed 's/:/\tcol2\tcol3\t/' | sed 's/-/\t/' | sed 's/$/\t.\t.\t.\tfacet=0/' > ${newname}.gff

setStringentFailForTheFollowing
bedtools slop -i ${newname}.gff -g ${ucscBuild} -b ${extend} > ${newname}_extendedBy${extend}b.gff
stopStringentFailAfterTheAbove
if [ "$?" -ne 0 ]; then
printThis="Bedtools slop to extend filtering coordinates failed for ${newname} ! \n EXITING !! "
printToLogFile
exit 1
fi

fi

done

echo
echo "Files for blat filtering :"
ls -lht |  grep "_extendedBy${extend}b.gff"





