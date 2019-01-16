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

# These are helper subs called in by runtools.sh F1 subroutine,
# to perform filtering of mapped sam files, before they enter ccanalyser hashes

################################################################

makeRawsamBigwig(){
# ---------------------------------
# Make bigwig track of the raw file (100b bins - start of each fragment) ..

thisIsWhereIam=$( pwd )
printThis="Starting to sort ${flashstatus}_REdig_unfiltered.sam BIG time - will save temporary files in ${thisIsWhereIam}"
printToLogFile

cat ${flashstatus}_REdig_unfiltered.sam | grep -v '^@' | cut -f 3,4 | grep '^chr' > intoSorting.txt

sortParams='-k1,1 -k2,2n'
sortIn1E6bunches
# needs these to be set :
# thisIsWhereIam=$( pwd )
# sortParams="-k1,1 -k2,2n"  or sortParams="-n" etc
# input in intoSorting.txt
# outputs TEMPsortedMerged.txt

# If all went well, we delete original file. If not, we complain here (but will not die).
sortResultInfo
rm -f intoSorting.txt

# echo
# echo 1
# head TEMPsortedMerged.txt \
# | awk '{print $1"\t"(int($2/100)*100)}' | uniq -c | sed 's/^\s\s*//' | sed 's/\s\s*/\t/g'
# echo
# echo 2
# head TEMPsortedMerged.txt \
# | awk '{print $1"\t"(int($2/100)*100)}' | uniq -c | sed 's/^\s\s*//' | sed 's/\s\s*/\t/g' \
# | awk '{if($3==0){print $2"\t0\t1\t"$1}else{print $2"\t"$3-1"\t"$3"\t"$1}}'
# echo

cat TEMPsortedMerged.txt \
| awk '{print $1"\t"(int($2/100)*100)}' | uniq -c | sed 's/^\s\s*//' | sed 's/\s\s*/\t/g' \
| awk '{if($3==0){print $2"\t0\t1\t"$1}else{print $2"\t"$3-1"\t"$3"\t"$1}}' \
> ${flashstatus}_REdig_unfiltered.bdg
rm -f TEMPsortedMerged.txt

bedGraphToBigWig ${flashstatus}_REdig_unfiltered.bdg ${ucscBuild} ${flashstatus}_REdig_unfiltered.bw
rm -f ${flashstatus}_REdig_unfiltered.bdg

}

countReadsAfterBowtie(){

echo
echo "Read count - in ${flashstatus} bowtie output sam file : "
echo
echo ${flashstatus}_REdig_unfiltered.sam
TEMPtempcount=$(($(cat  ${flashstatus}_REdig_unfiltered.sam | grep -cv '^@' )))
echo ${TEMPtempcount}
TEMPintSizeForSort=$(($(echo ${TEMPtempcount} | awk '{print length($1)}')))
checkThis=${TEMPintSizeForSort}
checkedName=${TEMPintSizeForSort}
checkParse
echo


}

chrWiseMappedBamFiles(){

# This whole thing is built to get rid of "as many reads as quickly as possible",
# so that we don't need to use the expensive "which capture this thingie possibly belongs to"
# subs inside CCanalyser or run bedtools intersect for the stuff which never will have a chance to be reported.

# The output of this sub continues to further filtering in subroutine prefilterBams
    
# This monster below has the following structure :

# 1) LOOP 1 : all reads together
#
# print into chr-separated files with the ucscbuild chromosome list and awk magic
#
# the above files continue to LOOP2 in subroutine chrWisefilterUnmappedAndOneOneFragMapped .

# ---------------------------------

printThis="LOOP1 ${flashstatus} : chrWiseMappedBamFiles "
printNewChapterToLogFile
date

# ---------------------------------

# The caller subroutine provides us with these starting parameters :
echo
echo "ucscBuild ${ucscBuild}"
echo "flashstatus ${flashstatus}"
echo

# ---------------------------------
# Test the input files are OK. Delete fastq.

testedFile="${flashstatus}_REdig_unfiltered.sam"
doTempFileTesting

rmCommand='rm -f ${flashstatus}_REdig.fastq'
rmThis="${flashstatus}_REdig.fastq"
checkRemoveSafety

rm -f ${flashstatus}_REdig.fastq

TEMPtestthisname="${flashstatus}_REdig_unfiltered.sam" 
echo
echo "tail -n 3 ${TEMPtestthisname} (without seq and qual columns)"
echo 
tail -n 3 ${TEMPtestthisname} | cut -f 10-11 --complement
echo

# ---------------------------------
# Set pre-requisites for the loop ..

rmCommand='rm -f ${flashstatus}_REdig_onlyOneFragment.txt'
rmThis="${flashstatus}_REdig_onlyOneFragment.txt"
checkRemoveSafety
rm -f LOOP1_${flashstatus}_REdig_onlyOneFragment.txt
rm -f LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt

checkThis=${flashstatus}
checkedName=${flashstatus}
checkParse
rm -f ${flashstatus}_*_REdig_prefiltered.sam

samtools view -H ${flashstatus}_REdig_unfiltered.sam > TEMPheading.sam
TEMPheadLineCount=$(($( cat TEMPheading.sam | grep -c "" )))
checkThis=${TEMPheadLineCount}
checkedName=${TEMPheadLineCount}
checkParse
echo "TEMPheadLineCount ${TEMPheadLineCount}"

# ---------------------------------
# Boldly he goes - here comes the monster loop
# (explanations above - the most mystical parts explained in detail below the loop)
# time-of-making-it code testing notes in : /home/molhaem2/telenius/WorkingDiaries/working_diary67.txt

# ------------------------
# To crash whenever anything withing this monster breaks ..
set -e -o pipefail
# ------------------------

# Here line-by-line notes :

# 1)  samtools   filter out unmapped reads
# 2) awk BEGIN
# 3) cut -f 1   read in the ucsc build chromosomes inside awk in format chr1=0;chr2=0;chr3=0;chr4=0; to set default valuse for counters - see below for Further Details
# 4) '}\
# 5) if (subs   heading if clause starts
# 6) '\
# 7) cut -f 1   print heading to all chr files - see below for Further Details
# 8) '\
# 9) }\
# 10) else\      normal lines printing starts
# 11) {\
# 12) print $0   print the normal line into the chr file
# 13) }\
# 14) }
# 15) END {'
# 16) cut -f 1   print all the chr counters to LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt log file - see below for Further Details
# 17) '}'
#
# continues below the code ..

# ------------------------

cut -f 1 ${ucscBuild} > TEMPucscChrs.txt
cat TEMPucscChrs.txt | sed 's/^/CHRS["/' | sed 's/$/"]=0\;/' > TEMPcommands0.txt
cat TEMPucscChrs.txt | sed 's/^/print \$0 >> \"LOOP1_'${flashstatus}'_/' | sed 's/$/_REdig_prefiltered.sam\"\;/' > TEMPcommands1.txt
paste TEMPucscChrs.txt TEMPucscChrs.txt | sed 's/\s/\\t" CHRS["/' | sed 's/^/print "/' | sed 's/$/\"] >> \"LOOP1_'${flashstatus}'_REdig_prefiltered_ChrCounts.txt\"\;/' | tr '%' '"' > TEMPcommands2.txt

# ------------------------

# The mystery lines above explained :
#
# INITIALISE ALL CHR COUNTERS IN THE BEGIN BLOCK (TEMPcommands0.txt)
# CHRS["chr1"]=0;
# CHRS["chr2"]=0;
# CHRS["chrX"]=0;
#
# PRINT HEADING TO ALL CHROMOSOMES' SAMS (TEMPcommands1.txt)
# print $0 >> "FLASHED_chr1_REdig_prefiltered.sam";
# print $0 >> "FLASHED_chr2_REdig_prefiltered.sam";
# print $0 >> "FLASHED_chrX_REdig_prefiltered.sam";
# 
# PRINT ALL CHR COUNTERS IN THE END BLOCK (TEMPcommands2.txt)
# print "chr1\t" CHRS["chr1"] >> "LOOP1_FLASHED_REdig_prefiltered_ChrCounts.txt";
# print "chr2\t" CHRS["chr2"] >> "LOOP1_FLASHED_REdig_prefiltered_ChrCounts.txt";
# print "chrX\t" CHRS["chrX"] >> "LOOP1_FLASHED_REdig_prefiltered_ChrCounts.txt";

# ------------------------

# Here generate the script to be ran ..

echo 'BEGIN{' > LOOP1_${flashstatus}.awk
cat TEMPcommands0.txt  >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk
echo '{' >> LOOP1_${flashstatus}.awk
echo 'if(substr($1,1,1)=="@"){' >> LOOP1_${flashstatus}.awk
cat TEMPcommands1.txt  >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk
echo 'else{print $0 >> "LOOP1_'${flashstatus}'_"$3"_REdig_prefiltered.sam";CHRS[$3]=CHRS[$3]+1' >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk
echo 'END {' >> LOOP1_${flashstatus}.awk
cat TEMPcommands2.txt  >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk

# ------------------------

# For debugging purposes - printing to user, where this script is ..

printThis="Will now run awk script $(pwd)/LOOP1_${flashstatus}.awk "
printToLogFile

# Now actually running it ..

chmod u+x LOOP1_${flashstatus}.awk
samtools view -h -F 4 ${flashstatus}_REdig_unfiltered.sam | awk -f LOOP1_${flashstatus}.awk

# ------------------------

# Remove temp files

rm -f TEMPcommands*.txt
rm -f TEMPucscChrs.txt

# -----------------------

# Revert to normal (+e : don't crash when a command fails. +o pipefail takes it back to "only monitor the last command of a pipe" )
set +e +o pipefail
# ------------------------

# Delete the ones with just the heading ..

for file in LOOP1_${flashstatus}_*_REdig_prefiltered.sam
do
    tempChr=$( echo $file | sed 's/^LOOP1_'${flashstatus}'_//' | sed 's/_REdig_prefiltered.sam//' )
    tempChrCountline=$( cat LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt | grep '^'${tempChr}'\s' )
    if [ "$(($( cat LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt | grep '^'${tempChr}'\s' | cut -f 2 )))" -eq 0 ];
    then
        echo -e "$file \thad no mapped reads - was deleted"
        rmCommand='rm -f $file'
        rmThis="$file"
        checkRemoveSafety
        rm -f $file
    else
        echo -ne $( ls -lht $file | sed 's/\s\s*/\t/g' | cut -f 1-4 --complement | awk '{print $5"\\t"$4" "$3" "$2" "$1}' )
        echo -e "\t"${tempChrCountline}" mapped reads saved"
        # echo "example line (printed without sequence and qscores) in $file :"
        # head -n 100 $file | tail -n 1 | cut -f 10,11 --complement
        testedFile="$file"
        doTempFileTesting
    fi
done

# ------------------------

# Reporting ..

echo
echo "Chromosome division counts - LOOP1_'${flashstatus}'_REdig_prefiltered_ChrCounts.txt : "
echo
cat LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt
echo

# ------------------------

# Delete the ones we don't need any more ..

rmCommand='rm -f ${flashstatus}_REdig_unfiltered.sam'
rmThis="${flashstatus}_REdig_unfiltered.sam"
checkRemoveSafety
rm -f ${flashstatus}_REdig_unfiltered.sam

# ------------------------

}


chrWiseMappedBamFilesSaveTransFrags(){

# This whole thing is built to get rid of "as many reads as quickly as possible",
# so that we don't need to use the expensive "which capture this thingie possibly belongs to"
# subs inside CCanalyser or run bedtools intersect for the stuff which never will have a chance to be reported.

# The output of this sub continues to further filtering in subroutine prefilterBams
    
# This monster below has the following structure :

# 1) LOOP 1 : all reads together
#
# print into chr-separated files with the ucscbuild chromosome list and awk magic
#
# the above files continue to LOOP2 in subroutine chrWisefilterUnmappedAndOneOneFragMapped .

# ---------------------------------

printThis="LOOP1 ${flashstatus} : chrWiseMappedBamFilesSaveTransFrags "
printNewChapterToLogFile
date

# ---------------------------------

# The caller subroutine provides us with these starting parameters :
echo
echo "ucscBuild ${ucscBuild}"
echo "flashstatus ${flashstatus}"
echo

# ---------------------------------
# Test the input files are OK. Delete fastq.

testedFile="${flashstatus}_REdig_unfiltered.sam"
doTempFileTesting

rmCommand='rm -f ${flashstatus}_REdig.fastq'
rmThis="${flashstatus}_REdig.fastq"
checkRemoveSafety

rm -f ${flashstatus}_REdig.fastq

TEMPtestthisname="${flashstatus}_REdig_unfiltered.sam" 
echo
echo "tail -n 3 ${TEMPtestthisname} (without seq and qual columns)"
echo 
tail -n 3 ${TEMPtestthisname} | cut -f 10-11 --complement
echo

# ---------------------------------
# Set pre-requisites for the loop ..

rmCommand='rm -f ${flashstatus}_REdig_onlyOneFragment.txt'
rmThis="${flashstatus}_REdig_onlyOneFragment.txt"
checkRemoveSafety
rm -f LOOP1_${flashstatus}_REdig_onlyOneFragment.txt
rm -f LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt

checkThis=${flashstatus}
checkedName=${flashstatus}
checkParse
rm -f ${flashstatus}_*_REdig_prefiltered.sam

samtools view -H ${flashstatus}_REdig_unfiltered.sam > TEMPheading.sam
TEMPheadLineCount=$(($( cat TEMPheading.sam | grep -c "" )))
checkThis=${TEMPheadLineCount}
checkedName=${TEMPheadLineCount}
checkParse
echo "TEMPheadLineCount ${TEMPheadLineCount}"

# ---------------------------------
# Boldly he goes - here comes the monster loop
# (explanations above - the most mystical parts explained in detail below the loop)
# time-of-making-it code testing notes in : /home/molhaem2/telenius/WorkingDiaries/working_diary67.txt

# ------------------------
# To crash whenever anything withing this monster breaks ..
set -e -o pipefail
# ------------------------

# Here line-by-line notes :

# 1)  samtools   filter out unmapped reads
# 2) awk BEGIN
# 3) cut -f 1   read in the ucsc build chromosomes inside awk in format chr1=0;chr2=0;chr3=0;chr4=0; to set default valuse for counters - see below for Further Details
# 4) '}\
# 5) if (subs   heading if clause starts
# 6) '\
# 7) cut -f 1   print heading to all chr files - see below for Further Details
# 8) '\
# 9) }\
# 10) else\      normal lines printing starts
# 11) {\
# 12) print $0   print the normal line into the chr file
# 13) }\
# 14) }
# 15) END {'
# 16) cut -f 1   print all the chr counters to LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt log file - see below for Further Details
# 17) '}'
#
# continues below the code ..

# ------------------------

cut -f 1 ${ucscBuild} > TEMPucscChrs.txt
cat TEMPucscChrs.txt | sed 's/^/CHRS["/' | sed 's/$/"]=0\;/' > TEMPcommands0.txt
cat TEMPucscChrs.txt | sed 's/^/print \$0 >> \"LOOP1_'${flashstatus}'_/' | sed 's/$/_REdig_prefiltered.sam\"\;/' > TEMPcommands1.txt
paste TEMPucscChrs.txt TEMPucscChrs.txt | sed 's/\s/\\t" CHRS["/' | sed 's/^/print "/' | sed 's/$/\"] >> \"LOOP1_'${flashstatus}'_REdig_prefiltered_ChrCounts.txt\"\;/' | tr '%' '"' > TEMPcommands2.txt

# ------------------------

# The mystery lines above explained :
#
# INITIALISE ALL CHR COUNTERS IN THE BEGIN BLOCK (TEMPcommands0.txt)
# CHRS["chr1"]=0;
# CHRS["chr2"]=0;
# CHRS["chrX"]=0;
#
# PRINT HEADING TO ALL CHROMOSOMES' SAMS (TEMPcommands1.txt)
# print $0 >> "FLASHED_chr1_REdig_prefiltered.sam";
# print $0 >> "FLASHED_chr2_REdig_prefiltered.sam";
# print $0 >> "FLASHED_chrX_REdig_prefiltered.sam";
# 
# PRINT ALL CHR COUNTERS IN THE END BLOCK (TEMPcommands2.txt)
# print "chr1\t" CHRS["chr1"] >> "LOOP1_FLASHED_REdig_prefiltered_ChrCounts.txt";
# print "chr2\t" CHRS["chr2"] >> "LOOP1_FLASHED_REdig_prefiltered_ChrCounts.txt";
# print "chrX\t" CHRS["chrX"] >> "LOOP1_FLASHED_REdig_prefiltered_ChrCounts.txt";

# ------------------------

# Here generate the script to be ran (headings only) ..

echo '{' >> LOOP1_${flashstatus}_head.awk
cat TEMPcommands1.txt  >> LOOP1_${flashstatus}_head.awk
echo '}' >> LOOP1_${flashstatus}_head.awk

# -------------------------

# Print the headings only ..

printThis="Will now print headings to sam files with awk script $(pwd)/LOOP1_${flashstatus}_head.awk "
printToLogFile

chmod u+x LOOP1_${flashstatus}_head.awk
samtools view -H ${flashstatus}_REdig_unfiltered.sam | awk -f LOOP1_${flashstatus}_head.awk

# ------------------------

# Now the real deal ..
# (see nomenclature notes below the code snippet)

echo 'l[1]=c[1];m=2;' > TEMPcommands3.txt
# this loop checks if we have more than 1 fragment saved. if we have, we check which chromosomes.
# if we only have 1 fragment, we set it above, and are happy with it.
# If we have more than 1 fragment, we make list l, which contains all the chr-names seen in this read,
# so that we can print all the fragments to all these chromosomes
# m=how-manyeth-new-chromosome-we-are-looking-for (one more than the count of found chromosomes)
# other nomenclature below
echo 'for(i=2;i<=n;i++)' >> TEMPcommands3.txt
echo '{' >> TEMPcommands3.txt
echo 'f=0;' >> TEMPcommands3.txt
echo 'for(j=1;j<=i;j++){if(l[j]==c[i]){f=1}}' >> TEMPcommands3.txt
echo 'if(f==0){l[m]=c[i];m=m+1}' >> TEMPcommands3.txt
echo '}' >> TEMPcommands3.txt
echo 'for(k=1;k<m;k++){for(i=1;i<n;i++){' >> TEMPcommands3.txt
echo 'print a[i] >> "LOOP1_'${flashstatus}'_"l[k]"_REdig_prefiltered.sam";CHRS[l[k]]=CHRS[l[k]]+1;' >> TEMPcommands3.txt
echo '}}' >> TEMPcommands3.txt

# The above are the printing loops
# Below the if clauses to direct the use of the above.

# Nomenclature as following :

# a="all" ($0, i.e. array of read names) - set below in BEGIN box
# c=chromosome names list - as they are red in (non-unique)
# p=previous read name (without :PE1:x:x part)
# n=how-manyeth-fragment-in-this-read
# m=how-manyeth-chromosome-we-are-looking-for (one more than the count of found chromosomes)
# 
# looper names as following :
# i : loop over n (fragments in read)
# j : loop over already-passed-first-i fragments (to check if new chromosome found)
# k : loop over all found chromosomes (m-1) to print all fragments a[i] to all of them

# ------------------------

# Here generate the script to be ran ..
# (see nomenclature notes above)

# BEGIN loop 
echo 'BEGIN{' > LOOP1_${flashstatus}.awk
# echo 'a=[];c=[];n=1;p="UNDEF"' >> LOOP1_${flashstatus}.awk
echo 'n=1;p="UNDEF"' >> LOOP1_${flashstatus}.awk
cat TEMPcommands0.txt >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk

# INNER loop
echo '{' >> LOOP1_${flashstatus}.awk

# CONTINUE - only save values, no printing
echo 'if((n==1)||(p==$1))' >> LOOP1_${flashstatus}.awk
echo '{' >> LOOP1_${flashstatus}.awk
echo 'a[n]=$2;' >> LOOP1_${flashstatus}.awk
echo 'for (f=3; f<=NF; f++){a[n]=a[n]"\t"$f};' >> LOOP1_${flashstatus}.awk
echo 'c[n]=$4;p=$1;n=n+1;' >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk
# PRINT - and zero values
echo 'else' >> LOOP1_${flashstatus}.awk
echo '{' >> LOOP1_${flashstatus}.awk
cat TEMPcommands3.txt >> LOOP1_${flashstatus}.awk
# echo 'a=[];c=[];n=1;p="UNDEF"' >> LOOP1_${flashstatus}.awk
echo 'delete a;delete c;n=1;p="UNDEF"' >> LOOP1_${flashstatus}.awk
# CONTINUE - only save values, no printing (for next round - to not to lose the fragment we saw this round)
echo 'a[n]=$2;' >> LOOP1_${flashstatus}.awk
echo 'for (f=3; f<=NF; f++){a[n]=a[n]"\t"$f};' >> LOOP1_${flashstatus}.awk
echo 'c[n]=$4;p=$1;n=n+1;' >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk

# END loop
echo 'END {' >> LOOP1_${flashstatus}.awk
cat TEMPcommands2.txt  >> LOOP1_${flashstatus}.awk
cat TEMPcommands3.txt >> LOOP1_${flashstatus}.awk
echo '}' >> LOOP1_${flashstatus}.awk

# ------------------------

# For debugging purposes - printing to user, where this script is ..

printThis="Will now run awk script $(pwd)/LOOP1_${flashstatus}.awk "
printToLogFile

# Now actually running it ..

chmod u+x LOOP1_${flashstatus}.awk
samtools view -F 4 ${flashstatus}_REdig_unfiltered.sam | awk '{print $0"\t"$1 }'\
| rev | sed 's/:/\t/' | sed 's/:/\t/' | sed 's/:/\t/' | cut -f 1-3 --complement | awk '{print $0"\t"$1 }' | cut -f 1 --complement | rev \
| awk -f LOOP1_${flashstatus}.awk

# ------------------------

# Remove temp files

rm -f TEMPcommands*.txt
rm -f TEMPucscChrs.txt

# -----------------------

# Revert to normal (+e : don't crash when a command fails. +o pipefail takes it back to "only monitor the last command of a pipe" )
set +e +o pipefail
# ------------------------

# Delete the ones with just the heading ..

for file in LOOP1_${flashstatus}_*_REdig_prefiltered.sam
do
    tempChr=$( echo $file | sed 's/^LOOP1_'${flashstatus}'_//' | sed 's/_REdig_prefiltered.sam//' )
    tempChrCountline=$( cat LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt | grep '^'${tempChr}'\s' )
    if [ "$(($( cat LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt | grep '^'${tempChr}'\s' | cut -f 2 )))" -eq 0 ];
    then
        echo -e "$file \thad no mapped reads - was deleted"
        rmCommand='rm -f $file'
        rmThis="$file"
        checkRemoveSafety
        rm -f $file
    else
        echo -ne $( ls -lht $file | sed 's/\s\s*/\t/g' | cut -f 1-4 --complement | awk '{print $5"\\t"$4" "$3" "$2" "$1}' )
        echo -e "\t"${tempChrCountline}" mapped reads saved"
        # echo "example line (printed without sequence and qscores) in $file :"
        # head -n 100 $file | tail -n 1 | cut -f 10,11 --complement
        testedFile="$file"
        doTempFileTesting
    fi
done

# ------------------------

# Reporting ..

echo
echo "Chromosome division counts - LOOP1_'${flashstatus}'_REdig_prefiltered_ChrCounts.txt : "
echo
cat LOOP1_${flashstatus}_REdig_prefiltered_ChrCounts.txt
echo

# ------------------------

# Delete the ones we don't need any more ..

rmCommand='rm -f ${flashstatus}_REdig_unfiltered.sam'
rmThis="${flashstatus}_REdig_unfiltered.sam"
checkRemoveSafety
rm -f ${flashstatus}_REdig_unfiltered.sam

# ------------------------

}

chrWiseFilteringLoops(){

# ------------------------

printThis="Preparing for LOOPs 2-3-4-5 ${flashstatus}.. "
printNewChapterToLogFile
date

# ------------------------
# Making heading and heading line count
# TEMPheading.sam
# ${TEMPheadLineCount}

tempFile=$( ls LOOP1_${flashstatus}_*_REdig_prefiltered.sam | head -n 1 )   
samtools view -H ${tempFile} > TEMPheading.sam

TEMPheadLineCount=$(($( cat TEMPheading.sam | grep -c "" )))

checkThis=${TEMPheadLineCount}
checkedName='${TEMPheadLineCount}'
checkParse
echo "TEMPheadLineCount ${TEMPheadLineCount}"

# ------------------------
# Report files delete before LOOP2-3-4 ..

checkThis=${flashstatus}
checkedName='${flashstatus}'
checkParse

rm -f LOOP2_${flashstatus}.log
rm -f LOOP3_${flashstatus}.log    
rm -f LOOP4_${flashstatus}.log
rm -f LOOP5_${flashstatus}.log

rm -f LOOP2_${flashstatus}_REdig_onlyOneFragment.txt
rm -f LOOP3_${flashstatus}_multicaptures.txt
rm -f LOOP4_${flashstatus}_join.txt
rm -f LOOP5_${flashstatus}_filter.txt

# ---------------------------------

printThis="LOOP 2-3-4-5 ${flashstatus} "
printNewChapterToLogFile

echo  "Full logs in : "
echo  $(pwd)"/LOOP2_${flashstatus}.log"
echo  $(pwd)"/LOOP3_${flashstatus}.log"
echo  $(pwd)"/LOOP4_${flashstatus}.log"
echo  $(pwd)"/LOOP5_${flashstatus}.log"
echo
echo  "Summary counts are updated into files :"
echo  $(pwd)"/LOOP2_${flashstatus}_REdig_onlyOneFragment.txt"
echo  $(pwd)"/LOOP3_${flashstatus}_multicaptures.txt"
echo  $(pwd)"/LOOP4_${flashstatus}_join.txt"
echo  $(pwd)"/LOOP5_${flashstatus}_filter.txt"
echo
echo  "Once whole loop 2-3-4-5 is ran for all chromosomes, the above are used to generate summary tables :"
echo  $(pwd)"/LOOP2_${flashstatus}_REdig_onlyOneFragment_table.txt"
echo  $(pwd)"/LOOP3_${flashstatus}_multicaptures_table.txt"
echo  $(pwd)"/LOOP4_${flashstatus}_join_table.txt"
echo  $(pwd)"/LOOP5_${flashstatus}_filter_table.txt"
echo

# ------------------------

echo
echo  "Will be running LOOP 2-3-4-5 ${flashstatus} for the following sam files :"
echo
for thisSamFile1 in LOOP1_${flashstatus}_*_REdig_prefiltered.sam
do
{
    thisChr=$( echo ${thisSamFile1} | sed 's/^LOOP1_'${flashstatus}'_//' | sed 's/_REdig_prefiltered.sam//' )
    checkThis=${thisChr}
    checkedName='${thisChr}'
    checkParse
    echo "${thisChr}   ${thisSamFile1}"
}
done
echo

echo
echo  "Starting runs for LOOP 2-3-4-5 ${flashstatus} .."
echo

for thisSamFile1 in LOOP1_${flashstatus}_*_REdig_prefiltered.sam
do
{
    thisChr=$( echo ${thisSamFile1} | sed 's/^LOOP1_'${flashstatus}'_//' | sed 's/_REdig_prefiltered.sam//' )
    checkThis=${thisChr}
    checkedName='${thisChr}'
    checkParse
    
    printThis="LOOPs 2,3,4,5 ${flashstatus} : for chromosome ${thisChr}"
    printNewChapterToLogFile

    # Check if we have capturesites in this chromosome ..
    if [ $(($(cat ${fullPathCapturesiteWhitelistChromosomes} | grep -c '^'${thisChr}'$'))) -eq 0 ]; then
        echo "${thisChr} has no capture capturesites - whole chromosome will now be removed from further analysis .."
        
        rmCommand='rm -f ${thisSamFile1}'
        rmThis="${thisSamFile1}"
        checkRemoveSafety
        rm -f ${thisSamFile1}
        
        # Break this round of loop, start next chromosome ..
        continue
    fi    
    
    {
    tempDATE=$(date)
    # ############################################################################
    printThis="LOOP2 ${flashstatus} ${thisChr} : chrWisefilterOnlyOneFragMapped ${tempDate}"
    # ############################################################################
    printToLogFile

    thisSamFile="${thisSamFile1}"
    chrWisefilterOnlyOneFragMapped >> LOOP2.log
    
    # ------------------------
    # Delete the ones with just the heading ..
    thisSamFile2="LOOP2_${flashstatus}_${thisChr}_REdig_prefiltered_ChrCounts.sam"
    tempLineCount=$(($(head -n $((${TEMPheadLineCount}+10)) ${thisSamFile2} | grep -c "")))
    if [ "${tempLineCount}" -le "${TEMPheadLineCount}" ];
    then
        echo -e "${thisSamFile2} \thad no more-than-one-fragment reads - was deleted"
        rmCommand='rm -f ${thisSamFile2}'
        rmThis="${thisSamFile2}"
        checkRemoveSafety
        rm -f ${thisSamFile2}
    else
        echo -e $( ls -lht ${thisSamFile2} | sed 's/\s\s*/\t/g' | cut -f 1-4 --complement | awk '{print $5"\\t"$4" "$3" "$2"\\tMultifragment reads saved, file size now "$1}' )
        testedFile="${thisSamFile2}"
        doTempFileTesting
    fi
    
    # ############################################################################
    }
    
    # -----------------------------------------------
    # If file exists now - continuing to LOOP3 ..
    thisCapFile3="LOOP3_${flashstatus}_${thisChr}_possibleCaptures.txt"
    if [ -f "${thisSamFile2}" ]; then
    {
    tempDATE=$(date) 
    # ############################################################################
    printThis="LOOP3 ${flashstatus} ${thisChr} : capturesitelistOverlapBams ${tempDate}"
    # ############################################################################
    printToLogFile
    
    thisSamFile=${thisSamFile2}
    thisCapFile=${thisCapFile3}
    capturesitelistOverlapBams >> LOOP3_${flashstatus}.log
    
    # ------------------------
    # Delete the ones with no captures ..
    echo
    tempLineCount=$(($(head ${thisCapFile} | grep -c "")))
    if [ "${tempLineCount}" -eq 0 ];
    then
        echo -e "${thisCapFile}  \thad no possible captures - was deleted"
        rmCommand='rm -f ${thisCapFile}'
        rmThis="${thisCapFile}"
        checkRemoveSafety
        rm -f ${thisCapFile} 
    else
        echo -e $( ls -lht ${thisCapFile}  | sed 's/\s\s*/\t/g' | cut -f 1-4 --complement | awk '{print $5"\\t"$4" "$3" "$2"\\tPotentially-Capture-containing reads saved, file size now "$1}' )
        testedFile="${thisCapFile}"
        doTempFileTesting
    fi
    # ------------------------
    
    # ############################################################################
    }
    fi
    
    # -----------------------------------------------
    # If file exists now - continuing to LOOP4 ..    
    # Final loop, to actually join the files
    if [ -f "${thisCapFile3}" ]; then
    {
    # ---------------------------------------
    
    {
    tempDATE=$(date)
    # ############################################################################
    printThis="LOOP4 ${flashstatus} : joinCapturesAndSam ${tempDate} "
    # ############################################################################
    printToLogFile

    thisSamFile=${thisSamFile2}
    thisCapFile=${thisCapFile3}

    thisCapReadCount=$(($( cat LOOP3_${flashstatus}_multicaptures.txt | grep '^'${thisChr}'\s' | grep 'Remaining reads (after join)' | sed 's/.*\s:\s//' )))
    checkThis=${thisCapReadCount}
    checkedName='LOOP4 ${thisCapReadCount}'
    
    thisSamReadCount=$(($( cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep '^'${thisChr}'\s' | grep "Remaining reads"     | sed 's/.*\s:\s//' )))
    checkThis=${thisSamReadCount}
    checkedName='LOOP4 ${thisSamReadCount}'
    checkParse
    
    thisSamFragCount=$(($( cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep '^'${thisChr}'\s' | grep "Remaining fragments" | sed 's/.*\s:\s//' )))
    checkThis=${thisSamFragCount}
    checkedName='LOOP4 ${thisSamFragCount}'
    checkParse
    
    joinCapturesAndSam >> LOOP4_${flashstatus}.log
    # ############################################################################
    }
    
    {
    tempDATE=$(date)
    # ############################################################################
    printThis="LOOP5 ${flashstatus} : prefilterBams ${tempDate} "
    # ############################################################################
    printToLogFile
    
    cat ${fullPathDpnBlacklist} | grep '^'${thisChr}'\s' > LOOP5_${thisChr}_blacklist.txt
    thisBedFile="LOOP5_${thisChr}_blacklist.txt"
    
    if [ ! -d LOOP5_filteredSams ]; then
        mkdir LOOP5_filteredSams
    fi
    if [ ! -d "LOOP5_filteredSams/${thisChr}" ]; then
        mkdir LOOP5_filteredSams/${thisChr}
    fi
    checkThis="${flashstatus}/${thisChr}"
    checkedName='${flashstatus}/${thisChr}'
    checkParse
    rm -f LOOP5_filteredSams/${thisChr}/${flashstatus}_*_possibleCaptures.bam
    
    prefilterBams >> LOOP5_${flashstatus}.log
    
    rmdir LOOP4_dividedSams
    
    # ############################################################################
    }
    
    # ----------------------------------
    }
    fi
    
}
done

}
    
chrWiseFilteringLoopsReports(){

printThis="Preparing reports for LOOPs 2-3-4-5 ${flashstatus}.. "
printNewChapterToLogFile
date

echo
echo  "Now whole loop 2-3-4-5 is ran for all chromosomes, and we will generate these summary tables :"
echo  $(pwd)"LOOP2_${flashstatus}_REdig_onlyOneFragment_table.txt"
echo  $(pwd)"LOOP3_${flashstatus}_multicaptures_table.txt"
echo  $(pwd)"LOOP4_${flashstatus}_join_table.txt"
echo  $(pwd)"LOOP5_${flashstatus}_filter_table.txt"
echo

# -----------------------

# Make also table format output counts file ..

# chr10 Total reads : 32
# chr10 Total fragments : 82
# chr10 Only one fragment in read (filtered) : 0
# chr10 Remaining reads : 32
# chr10 Remaining fragments : 82
# chr10 Heading line count : 24

cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Total reads"         | sed 's/\s.*//' > TEMP.chr
cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Total reads"         | sed 's/.*Total reads\s:\s//' > TEMP.totalR
cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Total fragments"     | sed 's/.*Total fragments\s:\s//' > TEMP.totalF
cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Only one fragment"   | sed 's/.*Only one fragment.*\s:\s//' > TEMP.oneF
cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Remaining reads"     | sed 's/.*Remaining reads\s:\s//' > TEMP.remR
cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Remaining fragments" | sed 's/.*Remaining fragments\s:\s//' > TEMP.remF
cat LOOP2_${flashstatus}_REdig_onlyOneFragment.txt | grep "Heading"             | sed 's/.*Heading line count\s:\s//' > TEMP.headR

echo -e "chr\tRdIn\tFgIn\tFilt\tRdOut\tFgOut\tHead" > TEMP.tableheading

paste TEMP.chr TEMP.totalR TEMP.totalF TEMP.oneF TEMP.remR TEMP.remF TEMP.headR | cat TEMP.tableheading - > LOOP2_${flashstatus}_REdig_onlyOneFragment_table.txt
rm -f TEMP.chr TEMP.totalR TEMP.totalF TEMP.oneF TEMP.remR TEMP.remF TEMP.headR       TEMP.tableheading

# ------------------------

# Reporting ..

echo
echo '-----------------------------------------------------------------------------------------------------------------'
echo 'Chr-wise counts for filtering only-1-fragment reads ( 'LOOP2_${flashstatus}_REdig_onlyOneFragment_table.txt' ) : '
echo
cat LOOP2_${flashstatus}_REdig_onlyOneFragment_table.txt
echo
echo 'chr   : chromosome'
echo 'RdIn  : total reads (before filtering only-one-frag-per-read containing ones)'
echo 'FgIn  : total fragments (before filtering only-one-frag-per-read containing ones)'
echo 'Filt  : filtered only-one-frag-per-read containing reads'
echo 'RdOut : remaining reads (after filtering)'
echo 'FgOut : remaining fragments (after filtering)'
echo 'Head  : sam heading lines'
echo

echo '( same data in non-table format in here : 'LOOP2_${flashstatus}_REdig_onlyOneFragment.txt' )'

# ------------------------


# Make also table format output counts file ..

# chr11 All capture-containing reads : 75204
# chr11 Multicaptures (removed) : 25
# chr11 Remaining reads : 75179
# chr11 Remaining reads (after join) - should be same as above : 75179

cat LOOP3_${flashstatus}_multicaptures.txt | grep "All"               | sed 's/\s.*//' > TEMP.chr
cat LOOP3_${flashstatus}_multicaptures.txt | grep "All"               | sed 's/.*All.*\s:\s//' > TEMP.totalR
cat LOOP3_${flashstatus}_multicaptures.txt | grep "Multicaptures"     | sed 's/.*Multicaptures.*\s:\s//' > TEMP.multiC
cat LOOP3_${flashstatus}_multicaptures.txt | grep 'Remaining reads :' | sed 's/.*Remaining reads :\s//' > TEMP.remR
cat LOOP3_${flashstatus}_multicaptures.txt | grep 'Remaining reads (after join)' | sed 's/.*Remaining reads (after join).*\s:\s//' > TEMP.remRJ

echo -e "chr\tRdIn\tmultiC\tRdOut\tRdOutJoined" > TEMP.tableheading

paste TEMP.chr TEMP.totalR TEMP.multiC TEMP.remR TEMP.remRJ | cat TEMP.tableheading - > LOOP3_${flashstatus}_multicaptures_table.txt
rm -f TEMP.chr TEMP.totalR TEMP.multiC TEMP.remR TEMP.remRJ       TEMP.tableheading

# ------------------------

echo
echo '-----------------------------------------------------------------------------------------------------------------'
echo "Multicaptures - these were filtered out - LOOP3_${flashstatus}_multicaptures_table.txt : "
echo
cat LOOP3_${flashstatus}_multicaptures_table.txt
echo
echo 'chr    : chromosome'
echo 'RdIn   : total reads (before filtering only-one-frag-per-read containing ones)'
echo 'multiC : filtered only-one-frag-per-read containing reads'
echo 'RdOut  : remaining reads (after filtering)'
echo 'RdOutJoined  : remaining fragments (after filtering and joining) - should be the same as above'
echo

echo '( same data in non-table format in here : 'LOOP3_${flashstatus}_multicaptures.txt' )'

# ------------------------

# Make also table format output counts file ..

cat LOOP4_${flashstatus}_join.txt | grep "Read count of SAM file when entering" | sed 's/\s.*//'    > TEMP.chr
cat LOOP4_${flashstatus}_join.txt | grep "Read count of SAM file when entering" | sed 's/.*\s:\s//' > TEMP.samRin
cat LOOP4_${flashstatus}_join.txt | grep "Frag count of SAM file when entering" | sed 's/.*\s:\s//' > TEMP.samFin
cat LOOP4_${flashstatus}_join.txt | grep "Frag count of SAM file within"        | sed 's/.*\s:\s//' > TEMP.samFwithin
cat LOOP4_${flashstatus}_join.txt | grep "Read count of CAP file when entering" | sed 's/.*\s:\s//' > TEMP.capIn
cat LOOP4_${flashstatus}_join.txt | grep "Frag count of SAM file after join"    | sed 's/.*\s:\s//' > TEMP.samJoin

echo -e "chr\tsamRin\tsamFin\tsamFwithin\tsamRout\tsamFjoined" > TEMP.tableheading

paste TEMP.chr TEMP.samRin TEMP.samFin TEMP.samFwithin TEMP.capIn TEMP.samJoin | cat TEMP.tableheading - > LOOP4_${flashstatus}_join_table.txt
rm -f TEMP.chr TEMP.samRin TEMP.samFin TEMP.samFwithin TEMP.capIn TEMP.samJoin       TEMP.tableheading

# ------------------------

echo
echo '-----------------------------------------------------------------------------------------------------------------'
echo "Joined sam reads - these sam reads most probably contain a specific single capture site - LOOP4_${flashstatus}_join_table.txt : "
echo
cat LOOP4_${flashstatus}_join_table.txt
echo
echo 'chr         : chromosome'
echo 'samRin      : total SAM reads in (before filtering for capture-containing ones)'
echo 'samFin      : total SAM fragments in (before filtering_'
echo 'samFwithin  : total SAM reads within the loop (should be the same as above)'
echo 'samRout     : reads marked as containing a single capture site (based on LOOP3 output)'
echo 'samFjoined  : fragments in the single capture site reads ( within samRout reads)'
echo

echo '( more data - including CAPTURE-wise counts, in non-table format in here : 'LOOP4_${flashstatus}_join.txt' )'

# ------------------------

# Delete the ones we don't need any more ..

# rm -f TEMPheading.sam
mv -f TEMPheading.sam headingForFutureSams.sam

# ---------------------------------
# Make also table format output counts file ..

cat LOOP5_${flashstatus}_filter.txt | sed 's/^\s\s*//' | grep "Frag count of SAM file when entering" | sed 's/\s.*\s:\s/\t/' | awk '{print $2 >> "TEMPcounts1_"$1".txt"}'
cat LOOP5_${flashstatus}_filter.txt | sed 's/^\s\s*//' | grep "Filtered SAM fragment count"          | sed 's/\s.*\s:\s/\t/' | awk '{print $2 >> "TEMPcounts2_"$1".txt"}'

echo -e "chr\tsamFin\tsamFout" > LOOP5_${flashstatus}_filter_table.txt

for file in TEMPcounts1_*.txt
do
    file2=$(echo $file | sed 's/^TEMPcounts1_/TEMPcounts2_/')
    tempname=$(echo $file | sed 's/^TEMPcounts1_//' | sed 's/\.txt$//')
    tempcount1=$(cat ${file} | tr '\n' '+' | sed 's/\+$/\n/' | bc -l)
    tempcount2=$(cat ${file2} | tr '\n' '+' | sed 's/\+$/\n/' | bc -l)
    echo -e "${tempname}\t${tempcount1}\t${tempcount2}" >> LOOP5_${flashstatus}_filter_table.txt
done

rm -f TEMPcounts1_*.txt TEMPcounts2_*.txt TEMP.tableheading

# ------------------------

# Reporting ..

echo
echo '-----------------------------------------------------------------------------------------------------------------'
echo "Filtered sam reads - these reads are now filtered from father-away-from RE cut sites than +/- ${ampliconSize} : "
echo
cat LOOP5_${flashstatus}_filter_table.txt
echo
echo 'chr         : chromosome'
echo 'samFin      : total SAM fragments in (before filtering) '
echo 'samFjoined  : total SAM fragments out (after filtering) '
echo

echo '( more data - including CAPTURE-wise counts, in non-table format in here : 'LOOP5_${flashstatus}_filter.txt' )'
echo

# ------------------------

# Summary of all of them ..

cat LOOP2_${flashstatus}_REdig_onlyOneFragment_table.txt | cut -f 1,2,5 | sort -T $(pwd) -k1,1 | sed 's/RdOut/MultifragRds/'                               > tempLOOP2.txt 
cat LOOP3_${flashstatus}_multicaptures_table.txt         | cut -f 1,2,5 | sort -T $(pwd) -k1,1 | sed 's/RdIn/RdHasCap/' | sed 's/RdOutJoined/RdSingleCap/' > tempLOOP3.txt 
cat LOOP5_${flashstatus}_filter_table.txt                               | sort -T $(pwd) -k1,1 | sed 's/samFin/FragInSingleCapRds/' | sed 's/samFout/FragWithinSonicSize/'> tempLOOP5.txt

join -a 1 tempLOOP2.txt tempLOOP3.txt | \
join -a 1 -             tempLOOP5.txt | \
sed 's/\s\s*/\t/g' | sed 's/$/\t0\t0\t0\t0\t0\t0/' | cut -f 1-7 > LOOPs1to5_${flashstatus}_table.txt

rm -f tempLOOP2.txt tempLOOP3.txt tempLOOP5.txt

head -n 1  LOOPs1to5_${flashstatus}_table.txt > LOOPs1to5_${flashstatus}_total.txt
tail -n +2 LOOPs1to5_${flashstatus}_table.txt \
 | awk 'BEGIN{a=0;b=0;c=0;d=0;e=0;f=0}{a=a+$2;b=b+$3;c=c+$4;d=d+$5;e=e+$6;f=f+$7}END{print a"\t"b"\t"c"\t"d"\t"e"\t"f}' \
>> LOOPs1to5_${flashstatus}_total.txt

# ------------------------
  
}

chrWisefilterOnlyOneFragMapped(){

# This whole thing is built to get rid of "as many reads as quickly as possible",
# so that we don't need to use the expensive "which capture this thingie possibly belongs to"
# subs inside CCanalyser or run bedtools intersect for the stuff which never will have a chance to be reported.

# This sub gets its input from the subroutine filterUnmappedAndOneOneFragMapped
# and output of this sub continues to further filtering in subroutine prefilterBams
    
# This monster below has the following structure :

# 2) LOOP 2 : chromosome-wise loops (repeating the above to get rid of trans reads where only one fragment in cis)
#
# for chr-separated files
# a- read file in with cat
# b- uniq -c column generation (to allow awk to know if we have only one fragment mapped for a read : can be discarded)
# c- feed (a) and (b) via paste to awk : separate only-one-fragment-present, count them
# d- in grep : remove only-one-fragment-present and heading
# e- add heading back in

# and output of this sub continues to further filtering in subroutine preprefilterBams

# ---------------------------------

# The caller subroutine provides us with these starting parameters :
echo
echo '************************************************************************************************'
echo "thisChr ${thisChr}"
echo '************************************************************************************************'
echo
echo "flashstatus ${flashstatus}"
echo
echo "thisSamFile ${thisSamFile}"
echo -n "TEMPheadLineCount ${TEMPheadLineCount} , i.e. "
cat TEMPheading.sam | grep -c ""
echo "TEMPintSizeForSort ${TEMPintSizeForSort}"
echo
ls -lht ${thisSamFile}
TEMPtestthisname="${thisSamFile}" 
echo "tail -n 1 ${TEMPtestthisname} (without seq and qual columns)"
tail -n 1 ${TEMPtestthisname} | cut -f 10-11 --complement
echo

# ------------------------
# To crash whenever anything withing this monster breaks ..
set -e -o pipefail
# ------------------------

# Here line-by-line notes :

# 1)  cat   filter out unmapped reads
# 2)  cut -f 1   generate read name (without the dpnII cutter extra parts) - read name shared by all RE cut fragments within a sequencing read
# 3)  uniq -c    count the fragments withing read
# 4)  awk 'BE    set the count of only-one-mapped-frag-per-read (c) count-of-heading-lines (h) count-of-col1-uniq-heading-lines (hl) fragment count (f) to zero
# 5)  {p=NR-     first for all lines : p(to-be-printed) set to count of NR-uniqheadinglinecount
# 6)  if(sub     overwrite the default set in (5) above, if we are still in heading. Now p=-1
# 7)  else{if    overwrite the default set in (5) above, if we are only-one-mapped-frag-per-read. Now p=-1
# 8)  for (i=0   loop over the uniq-c count - print each time : results in printing "uniq -c" times the same line
# 9)  {
# 10) printf     print the uniq-c count , with needed amount of leading zeroes (to allow sort to see this as sorted)
# 11 }
# 12 }
# 13) END        print the counters into TEMP_REdig_onlyOneFragment.txt
# 14) paste      bring in the original file : combine to the newly generated counters. delete lines which got p=-1 in awk (now start with -1). add heading back in
# 15) >>         print the sam output file
#
# continues below the code ..

# ------------------------

cat ${thisSamFile} \
| cut -f 1 | rev | tr ':' '\t' | cut -f 1-3 --complement | tr '\t' ':' | rev \
| uniq -c | sed 's/^\s*//' | sed 's/\s\s*/\t/g' \
| awk 'BEGIN{c=0;f=0;h=0;hl=0}\
{\
p=NR-hl;\
if(substr($2,1,1)=="@"){h=h+$1;p=-1;hl=hl+1}\
else{if ($1 <=1){p=-1;c=c+1}}\
for (i=0;i<$1;i++){ printf("%0'${TEMPintSizeForSort}'d\n", p);f=f+1 }\
}\
END{print "'${thisChr}' Total reads : " NR "\n'${thisChr}' Total fragments : " f "\n'${thisChr}' Only one fragment in read (filtered) : " c "\n'${thisChr}' Remaining reads : " NR-hl-c "\n'${thisChr}' Remaining fragments : " f-h-c "\n'${thisChr}' Heading line count : " h "\n" >> "LOOP2_'${flashstatus}'_REdig_onlyOneFragment.txt"}' \
| paste - ${thisSamFile} | tail -n +$((${TEMPheadLineCount}+1)) | awk '{if($1>0){print $1":"$2"\t"$0} }' | cut -f 2-3 --complement | cat TEMPheading.sam - \
> LOOP2_${flashstatus}_${thisChr}_REdig_prefiltered_ChrCounts.sam

# ------------------------
# Revert to normal (+e : don't crash when a command fails. +o pipefail takes it back to "only monitor the last command of a pipe" )
set +e +o pipefail
# ------------------------

# Print to log file 

ls -lht LOOP2_${flashstatus}_${thisChr}_REdig_prefiltered_ChrCounts.sam
TEMPtestthisname="LOOP2_${flashstatus}_${thisChr}_REdig_prefiltered_ChrCounts.sam" 
echo "tail -n 1 ${TEMPtestthisname} (without seq and qual columns)"
tail -n 1 ${TEMPtestthisname} | cut -f 10-11 --complement
echo

# ------------------------

# Delete the ones we don't need any more ..

rmCommand='rm -f ${thisSamFile}'
rmThis="${thisSamFile}"
checkRemoveSafety
rm -f ${thisSamFile}

# ------------------------

}

capturesitelistOverlapBams(){

# This whole thing is built to get rid of "as many reads as quickly as possible",
# so that we don't need to use the expensive "which capture this thingie possibly belongs to"
# subs inside CCanalyser or run bedtools intersect for the stuff which never will have a chance to be reported.

# the output of this sub continues to further filtering in subroutine prefilterBams

# ---------------------------------

# The caller subroutine provides us with these starting parameters :
echo
echo "------------------"
echo "thisChr ${thisChr}"
echo
echo "thisSamFile ${thisSamFile}"
echo "fullPathCapturesiteWhitelist ${fullPathCapturesiteWhitelist}"
echo "flashstatus ${flashstatus}"
echo

cat ${fullPathCapturesiteWhitelist} | grep '^'${thisChr}'\s' > ${thisChr}_capturesiteWhitelist.bed
testedFile="${thisChr}_capturesiteWhitelist.bed"
doTempFileTesting

# ------------------------
# To crash whenever anything withing this monster breaks ..
set -e -o pipefail
# ------------------------

TEMPtestthisname="${thisSamFile}" 
echo
echo "tail -n 1 ${TEMPtestthisname} (without seq and qual columns)"
echo 
tail -n 1 ${TEMPtestthisname} | cut -f 10-11 --complement
echo

# ------------------------

samtools view -hb ${thisSamFile} | bedtools bamtobed -i stdin | cut -f 1-4 \
| bedtools intersect -wb -a stdin -b ${thisChr}_capturesiteWhitelist.bed \
| cut -f 4,8 | sed 's/:/\t/' | awk '{print $1"\t"$3}' | uniq \
> LOOP3_${flashstatus}_${thisChr}_temp.txt

# The multicaptures have same read number more than once ..
cut -f 1 LOOP3_${flashstatus}_${thisChr}_temp.txt \
| uniq -c | sed 's/^\s*//' | sed 's/\s\s*/\t/g' \
| awk 'BEGIN{c=0;}\
{if($1>1){c=c+1}else{print $2}}\
END{print "'${thisChr}' All capture-containing reads : "NR"\n'${thisChr}' Multicaptures (removed) : "c"\n'${thisChr}' Remaining reads : "NR-c >> "LOOP3_'${flashstatus}'_multicaptures.txt" }'\
| join -j 1 - LOOP3_${flashstatus}_${thisChr}_temp.txt | sed 's/\s\s*/\t/g'\
| awk '{print $0}END{print "'${thisChr}' Remaining reads (after join) - should be same as above : "NR >> "LOOP3_'${flashstatus}'_multicaptures.txt" }'\
> LOOP3_${flashstatus}_${thisChr}_possibleCaptures.txt

# ------------------------
# Revert to normal (+e : don't crash when a command fails. +o pipefail takes it back to "only monitor the last command of a pipe" )
set +e +o pipefail
# ------------------------


# Testing that join went fine ..

temp1=$(($( cat LOOP3_${flashstatus}_multicaptures.txt | grep '^'${thisChr}'\s' | grep 'Remaining reads :' | sed 's/.*Remaining reads :\s//' )))
temp2=$(($( cat LOOP3_${flashstatus}_multicaptures.txt | grep '^'${thisChr}'\s' | grep 'Remaining reads (after join)' | sed 's/.*Remaining reads (after join).*\s:\s//' )))

if [ "${temp1}" -ne "${temp2}" ];
then
  printThis="Join failed in LOOP3 - crashing the whole script, as read integrity is now compromised ! (report this to Jelena)"
  printToLogFile
  
  printThis="Joined reads count : "$(($(cat test2.txt | grep -c "")))", should be the same as not-multicapture-reads count : "$(($(cat test1.txt | grep -c "")))" (but it isn't so something went wrong). "
  printToLogFile

  exit 1
else
  printThis="Join succeeded in LOOP3 - continuing .."
  printToLogFile    
fi

rm -f test1.txt test2.txt

# ------------------------------

rmCommand='rm -f LOOP3_${flashstatus}_${thisChr}_temp.txt'
rmThis="LOOP3_${flashstatus}_${thisChr}_temp.txt"
checkRemoveSafety
rm -f LOOP3_${flashstatus}_${thisChr}_temp.txt

}

joinCapturesAndSam(){
    
# Joining the made list of potential capture reads and the sam reads. Updating the read names to include also capture site name.

echo
echo "------------------"
echo "thisChr ${thisChr}"
echo
echo "thisCapFile ${thisCapFile}"
echo "thisSamFile ${thisSamFile}"
echo "thisCapReadCount ${thisCapReadCount}"
echo "thisSamReadCount ${thisSamReadCount}"
echo "thisSamFragCount ${thisSamFragCount}"
echo "flashstatus ${flashstatus}"
echo -n "TEMPheadLineCount ${TEMPheadLineCount} , i.e. "
cat TEMPheading.sam | grep -c ""
echo

echo "tail -n 1 ${thisSamFile} (without the seq and qual columns)"
tail -n 1 ${thisSamFile} | cut -f 10-11 --complement

echo "${thisChr} Read count of CAP file when entering the loop : ${thisCapReadCount}" >> "LOOP4_${flashstatus}_join.txt"
echo "${thisChr} Read count of SAM file when entering the loop : ${thisSamReadCount}" >> "LOOP4_${flashstatus}_join.txt"
echo "${thisChr} Frag count of SAM file when entering the loop (no heading lines) : "$((${thisSamFragCount}-${TEMPheadLineCount})) >> "LOOP4_${flashstatus}_join.txt"

rm -f TEMPjointester.txt
if [ ! -d LOOP4_dividedSams ]; then
    mkdir LOOP4_dividedSams
fi
if [ ! -d "LOOP4_dividedSams/${thisChr}" ]; then
    mkdir LOOP4_dividedSams/${thisChr}
fi
checkThis="${flashstatus}/${thisChr}"
checkedName='${flashstatus}/${thisChr}'
checkParse
rm -f LOOP4_dividedSams/${thisChr}/${flashstatus}_*_possibleCaptures.sam

cat ${thisSamFile} | grep -v '^@' | sed 's/:/\t/'\
| awk '{print $0}END{print "'${thisChr}' Frag count of SAM file within the loop : "NR >> "LOOP4_'${flashstatus}'_join.txt" }'\
| join -j 1 ${thisCapFile} - | sed 's/\s\s*/\t/g' \
| awk '{print $0 >> "LOOP4_dividedSams/'${thisChr}'/'${flashstatus}'_"$2"_possibleCaptures.samISH" ; print $1 >> "TEMPjointester.txt"}END{print "'${thisChr}' Frag count of SAM file after join with CAP file : "NR >> "LOOP4_'${flashstatus}'_join.txt" }'\

echo "tail -n 1 LOOP4_dividedSams/${thisChr}/${flashstatus}_*_possibleCaptures.samISH (without the seq and qual columns)"
tail -n 1 LOOP4_dividedSams/${thisChr}/${flashstatus}_*_possibleCaptures.samISH | cut -f 12-13 --complement

# Testing if join went fine :

if [ $(($(cat TEMPjointester.txt | uniq | grep -c ""))) -ne "${thisCapReadCount}" ];
then
  printThis="Join failed in LOOP4 for ${flashstatus} ${thisChr} - crashing the whole script, as read integrity is now compromised ! (report this to Jelena)"
  printToLogFile
  printThis="Joined reads count : "$(($(cat TEMPjointester.txt | uniq | grep -c "")))", should be the same as capture-containing read count : ${thisCapReadCount} (but it isn't so something went wrong). "
  printToLogFile
  exit 1
else
  printThis="Join succeeded in LOOP4 for ${flashstatus} ${thisChr} - continuing .."
  printToLogFile    
fi

rm -f TEMPjointester.txt
   

# ------------------------

# Delete the ones we don't need any more ..

rmCommand='LOOP4  rm -f ${thisSamFile}'
rmThis="${thisSamFile}"
checkRemoveSafety
rm -f ${thisSamFile}

rmCommand='LOOP4  rm -f ${thisCapFile}'
rmThis="${thisCapFile}"
checkRemoveSafety
rm -f ${thisCapFile}

# ------------------------
# Sam to bam transform ..

for file in LOOP4_dividedSams/${thisChr}/${flashstatus}_*_possibleCaptures.samISH;
do

ls -lht ${file}
bamname=$(echo $file | sed 's/\.samISH$/.bam/')
testThis="${bamname}"
testedName='LOOP4 ${bamname} in Sam to bam transform'
checkParse
capname=$(basename $file | sed 's/'${flashstatus}'_//' | sed 's/_'possibleCaptures.samISH'//')
testThis="${capname}"
testedName='LOOP4 ${capname} in Sam to bam transform'
checkParse

cut -f 1-2 --complement ${file} | cat TEMPheading.sam - | samtools view -bh > ${bamname}

ls -lht ${bamname}
TEMPcount=$(samtools view -c ${bamname})
echo "${thisChr} ${capname} Frag count of SAM file after the join : ${TEMPcount}" >> "LOOP4_${flashstatus}_join.txt"

testedFile="${bamname}"
doTempFileTesting
doQuotaTesting

rmCommand='LOOP4 rm -f ${file}'
rmThis="${file}"
checkRemoveSafety
rm -f ${file}

done

}

prefilterBams(){

echo
echo '************************************************************************************************'
echo "thisChr ${thisChr}"
echo '************************************************************************************************'
echo
echo "flashstatus ${flashstatus}"
echo "thisBedFile ${thisBedFile}"
ls -lht ${thisBedFile}

for file in LOOP4_dividedSams/${thisChr}/${flashstatus}_*_possibleCaptures.bam;
do
    capname=$(basename $file | sed 's/'${flashstatus}'_//' | sed 's/_'possibleCaptures.bam'//')
    testThis="${capname}"
    testedName='LOOP5 ${capname}'
    checkParse
    
    thisSamFragCount=$(($( cat LOOP4_${flashstatus}_join.txt | grep '^'"${thisChr} ${capname}"'\s' | grep "Frag count of SAM file after the join" | sed 's/.*\s:\s//' )))
    checkThis=${thisSamFragCount}
    checkedName='LOOP5 ${thisSamFragCount}'
    checkParse
    
    newbasename=$(basename ${file})

    echo "${thisChr} ${capname} Frag count of SAM file when entering the loop : ${thisSamFragCount}" >> LOOP5_${flashstatus}_filter.txt
    
    echo "bedtools intersect -v -abam ${file} -b ${thisBedFile} > LOOP5_filteredSams/${thisChr}/${newbasename}"
    bedtools intersect -v -abam ${file} -b ${thisBedFile} > LOOP5_filteredSams/${thisChr}/${newbasename}

    ls -lht LOOP5_filteredSams/${thisChr}/${newbasename}

    testedFile="LOOP5_filteredSams/${thisChr}/${newbasename}"
    doTempFileTesting
    doQuotaTesting

    echo
    echo -n "${thisChr} ${capname} Filtered SAM fragment count : " >> LOOP5_${flashstatus}_filter.txt
    samtools view -c LOOP5_filteredSams/${thisChr}/${newbasename} >> LOOP5_${flashstatus}_filter.txt

    # -----------------------------------------------
    
    # Delete the ones we don't need any more ..
    
    rmCommand='LOOP5 rm -f ${file}'
    rmThis="${file}"
    checkRemoveSafety
    rm -f ${file}

done

rmdir LOOP4_dividedSams/${thisChr}

rmCommand='LOOP5 rm -f ${thisBedFile}'
rmThis="${thisBedFile}"
checkRemoveSafety
rm -f ${thisBedFile}

# ------------------------

}

