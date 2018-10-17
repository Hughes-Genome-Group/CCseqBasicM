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

# This is to divide the run, in same order as the parallel run
# But for serial excecution.
# All the actual stuff is done in scripts which are called from here (which all import their own accessory scripts)
# to keep it lightweight on the parallelisation level.

# The sister script doing exactly the same, but with nextFlow parallelisation
# is CCseqBasic5parallel.sh

# ------------------------------------------------------

# The serial execution order is :

# 1) check forbidden flags (not allowing sub-level flags --onlyREdigest, --parallel 1 --parallel 2 --R1 --R2 --outfile --errfile)
# 2) sort oligo file, check fastq integrity
# 3) mainRunner.sh --onlyREdigest
# 4) for each fastq in the list : mainRunner.sh --parallel 1
# 5) combine results
# 6) mainRunner.sh --onlyBlat
# 7) for each oligo bunch in the list : mainRunner.sh --parallel 2
# 8) visualise

# For eachof these 8 steps the main script needs to be an EXCECUTABLE SCRIPT (so that the logic is exactly parallel to that what will be in the parallel nextFlow run )

# Steps 1-2 will be in same script "prepare.sh"

# ------------------------------------------

. ${CaptureParallelPath}/bashHelpers/rainbowHubHelpers.sh

. ${CaptureCommonHelpersPath}/genomeSetters.sh

# From where to call the CONFIGURATION script..
confFolder="${MainScriptPath}/conf"

. ${confFolder}/genomeBuildSetup.sh
. ${confFolder}/loadNeededTools.sh

# ------------------------------------------

makeBowtie1Summaries(){
# ------------------------------------------

# Bowtie1 and bowtie2 reports differ :
# 1_b2	7160726 reads; of these:
# 2_b2	  7160726 (100.00%) were unpaired; of these:
# 3_b2	    43688 (0.61%) aligned 0 times
# 4_b2	    6546174 (91.42%) aligned exactly 1 time
# 5_b2	    570864 (7.97%) aligned >1 times
# 6_b2	99.39% overall alignment rate
# 
# 1_b1	# reads processed: 44369755
# 2_b1	# reads with at least one reported alignment: 36772576 (82.88%)
# 3_b1	# reads that failed to align: 713963 (1.61%)
# 4_b1	# reads with alignments suppressed due to -m: 6883216 (15.51%)
# 5_b1	Reported 36772576 alignments to 1 output stream(s)

# Bowtie1 reports
if [ "${flashstatus}" == "FLASHED" ]; then
    
 # FLASHED
head -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads with at least one reported alignment' | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_mappedPerc.txt
head -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads that failed to align'                 | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_unmappedPerc.txt
head -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads with alignments suppressed due to -m' | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_mFiltered.txt

else

# NONFLASHED
tail -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads with at least one reported alignment' | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_mappedPerc.txt
tail -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads that failed to align'                 | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_unmappedPerc.txt
tail -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads with alignments suppressed due to -m' | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_mFiltered.txt

fi

paste temp_mappedPerc.txt temp_unmappedPerc.txt temp_mFiltered.txt > temp_mapping.txt
rm -f temp_mappedPerc.txt temp_unmappedPerc.txt temp_mFiltered.txt    

echo -e 'mappedRds\tunmappedRds\tmFilteredRds' > ${flashstatus}_bowtiePerc.txt
cat   temp_mapping.txt | awk 'BEGIN{a=0;b=0;c=0}{a=a+$1;b=b+$2;c=c+$3}END{print (a/NR)"\t"(b/NR)"\t"(c/NR)}' >> ${flashstatus}_bowtiePerc.txt
rm -f temp_mapping.txt

if [ "${flashstatus}" == "FLASHED" ]; then

    # FLASHED
    head -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads processed' | sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' >    FLASHEDreadsEnteringBowtie_readcount.txt

else

    # NONFLASHED
    tail -n 8 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads processed' | sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > NONFLASHEDreadsEnteringBowtie_readcount.txt
 
fi

# ------------------------------------------
}

# ------------------------------------------

makeBowtie2Summaries(){
# ------------------------------------------

# Bowtie1 and bowtie2 reports differ :
# 1_b2	7160726 reads; of these:
# 2_b2	  7160726 (100.00%) were unpaired; of these:
# 3_b2	    43688 (0.61%) aligned 0 times
# 4_b2	    6546174 (91.42%) aligned exactly 1 time
# 5_b2	    570864 (7.97%) aligned >1 times
# 6_b2	99.39% overall alignment rate
# 
# 1_b1	# reads processed: 44369755
# 2_b1	# reads with at least one reported alignment: 36772576 (82.88%)
# 3_b1	# reads that failed to align: 713963 (1.61%)
# 4_b1	# reads with alignments suppressed due to -m: 6883216 (15.51%)
# 5_b1	Reported 36772576 alignments to 1 output stream(s)

if [ "${flashstatus}" == "FLASHED" ]; then
    
 # FLASHED
head -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'aligned exactly 1 time' | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_mappedPerc.txt
head -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'aligned 0 times'        | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_unmappedPerc.txt
head -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'aligned >1 times'       | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_multimapped.txt

else

# NONFLASHED
tail -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'aligned exactly 1 time' | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_mappedPerc.txt
tail -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'aligned 0 times'        | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_unmappedPerc.txt
tail -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'aligned >1 times'       | tr '(' '_' | tr ')' ' ' | sed 's/.*_//' | sed 's/\%.*//' > temp_multimapped.txt

fi

paste temp_mappedPerc.txt temp_unmappedPerc.txt temp_multimapped.txt > temp_mapping.txt
rm -f temp_mappedPerc.txt temp_unmappedPerc.txt temp_multimapped.txt    

echo -e 'uniqMappedRds\tunmappedRds\tmultiMappedRds' > ${flashstatus}_bowtiePerc.txt
cat   temp_mapping.txt | awk 'BEGIN{a=0;b=0;c=0}{a=a+$1;b=b+$2;c=c+$3}END{print (a/NR)"\t"(b/NR)"\t"(c/NR)}' >> ${flashstatus}_bowtiePerc.txt
rm -f temp_mapping.txt

if [ "${flashstatus}" == "FLASHED" ]; then

    # FLASHED
    head -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads' | grep 'of these' | sed 's/\s.*//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' >    FLASHEDreadsEnteringBowtie_readcount.txt

else

    # NONFLASHED
    tail -n 9 fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep 'reads' | grep 'of these' | sed 's/\s.*//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > NONFLASHEDreadsEnteringBowtie_readcount.txt
 
fi

# ------------------------------------------
}

# ------------------------------------------

makeFastqrunSummaries(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs

# ###############################
# LOOPs summary table
# ###############################

head -n 1 fastq_1/F1_beforeCCanalyser_${samplename}_${CCversion}/LOOPs1to5_${flashstatus}_total.txt | sed 's/^chr\s\s*//' > ${flashstatus}_summaryCounts.txt
cat fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/LOOPs1to5_${flashstatus}_total.txt | grep -v '^chr\s' \
 | awk 'BEGIN{a=0;b=0;c=0;d=0;e=0;f=0}{a=a+$1;b=b+$2;c=c+$3;d=d+$4;e=e+$5;f=f+$6}END{print a"\t"b"\t"c"\t"d"\t"e"\t"f}' >> ${flashstatus}_summaryCounts.txt

echo -e 'mappedReadsAs100perc\tmultifrag\thasCap\tsingleCap\twithinSonicSize' > ${flashstatus}_summaryPerc.txt
cat fastq_*/F1_beforeCCanalyser_${samplename}_${CCversion}/LOOPs1to5_${flashstatus}_total.txt | grep -v '^chr\s' \
| awk 'BEGIN{a=0;b=0;c=0;d=0;e=0;f=0}{a=a+$1;b=b+$2;c=c+$3;d=d+$4;e=e+$5;f=f+$6}\
END{\
if(a==0){print "0\t0\t0\t0\t0"}\
else if(e==0){print (a/a)*100"\t"(b/a)*100"\t"(c/a)*100"\t"(d/a)*100"\t0"}\
else{print (a/a)*100"\t"(b/a)*100"\t"(c/a)*100"\t"(d/a)*100"\t"(f/e)*(d/a)*100}\
}' >> ${flashstatus}_summaryPerc.txt

# ###############################
# BOWTIEs summary oneliners
# ###############################


weHaveBowtie1=$(($( head -n 8 fastq_1/F1_beforeCCanalyser_${samplename}_${CCversion}/bowties.log | grep -c 'reads with at least one reported alignment' )))

if [ "${weHaveBowtie1}" -ne 0 ]; then
makeBowtie1Summaries
else
makeBowtie2Summaries
fi

# ###############################
# RE cut reports, flashing reports.
# ###############################

# --------------------------------
# RE cut reports (full reports - combining all fastqs)

rm -rf TMP_makingdigestLogs
mkdir TMP_makingdigestLogs

for folder in fastq_*
do
cat ${folder}/F1_beforeCCanalyser_${samplename}_${CCversion}/${flashstatus}_${REenzyme}digestion.log \
| sed 's/.*command run on file: //' | sed 's/\s\s*/\t/' | cut -f 1 | sed 's/^[a-zA-Z].*//' > TMP_makingdigestLogs/${folder}.txt
done

paste TMP_makingdigestLogs/* | sed 's/\s/+/g' | sed 's/^++*$/0/' | bc | sed 's/^0$//' > TMPnumbers.txt

# Heading part ..
cat fastq_1/F1_beforeCCanalyser_${samplename}_${CCversion}/${flashstatus}_${REenzyme}digestion.log | sed 's/^[1234567890]*//' > TEMPheading.txt

paste TMPnumbers.txt TEMPheading.txt | tr '\t' ' ' | sed 's/^\s\s*//' > ${flashstatus}_${REenzyme}digestion.log

rm -rf TMP_makingdigestLogs TEMPheading.txt TMPnumbers.txt


cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

# ------------------------------------------

makeGeneralFastqrunSummaries(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs

# --------------------------------
# Flashing counts - summary over all fastqs

# Both old and new versions of flash say
# [FLASH] Read combination statistics:
# (the deviation is in the 3 lines which follow this) - so we can just grep -A based on this

rm -rf TMP_makingflashLog
mkdir TMP_makingflashLog
rm -rf TMP_makingflashLogPerc
mkdir TMP_makingflashLogPerc

for folder in fastq_*
do
cat ${folder}/F1_beforeCCanalyser_${samplename}_${CCversion}/flashing.log | grep -A 4 'Read combination statistics'\
| head -n 4 \
| sed 's/.*\s\s*//' | sed 's/^[a-zA-Z].*//' > TMP_makingflashLog/${folder}.txt
cat ${folder}/F1_beforeCCanalyser_${samplename}_${CCversion}/flashing.log | grep -A 4 'Read combination statistics'\
| tail -n 1 \
| sed 's/.*\s\s*//' | sed 's/^[a-zA-Z].*//' | sed 's/%$//'> TMP_makingflashLogPerc/${folder}.txt

done

paste TMP_makingflashLog/* | sed 's/\s/+/g' | sed 's/^++*$/0/' | bc | sed 's/^0$//' > TMPnumbers.txt
cat TMP_makingflashLogPerc/* | awk 'BEGIN{s=0}{s=s+$1}END{print s/NR"%"}' >> TMPnumbers.txt

# Heading part ..
cat fastq_1/F1_beforeCCanalyser_${samplename}_${CCversion}/flashing.log | grep -A 4 'Read combination statistics'\
| sed 's/[1234567890][1234567890].*//' > TEMPheading.txt

paste TEMPheading.txt TMPnumbers.txt | tr '\t' ' ' | sed 's/^\s\s*//' > flashing.log

rm -rf TMP_makingflashLog TMP_makingflashLogPerc TEMPheading.txt TMPnumbers.txt


# ###############################
# Usage reports
# ###############################

if [ "${useWholenodeQueue}" -eq 1 ]; then 

mkdir usageReports
mkdir usageReports/makingOf
cp qsubLogFiles/wholerun* usageReports/makingOf/.
cp qsubLogFiles/allRunsRUNTIME.log usageReports/.

cat usageReports/makingOf/wholerunTasks.txt | sed 's/\s\s*/\t/g' \
| sed 's/_f//g' | sed 's/_nf//g' \
| sed 's/countRds/LOOPs/g' | sed 's/LOOP1/LOOPs/g' | sed 's/LOOP2to5/LOOPs/g' \
| sed 's/fetchFastq/FastqIn/g'  | sed 's/inspectFastq/FastqIn/g'  | sed 's/SetParams/FastqIn/g' \
> usageReports/makingOf/wholerunTasksParsed.txt

cat usageReports/makingOf/wholerunUsage.txt | sed 's/M\s/\t/g' | sed 's/M$//'> usageReports/wholerunUsageForExcel.txt
cat usageReports/makingOf/wholerunTasksParsed.txt \
|  awk '{a["FastqIn"]=0;a["FastQC"]=0;a["Trim"]=0;a["Flash"]=0;a["REdig"]=0;a["BOWTIE"]=0;a["LOOPs"]=0;\
for(i=2;i<=NF;i++){a[$i]=a[$i]+1}; \
print $1"\tFastqIn\t"a["FastqIn"]"\tFastQC\t"a["FastQC"]"\tTrim\t"a["Trim"]"\tFlash\t"a["Flash"]"\tREdig\t"a["REdig"]"\tBOWTIE\t"a["BOWTIE"]"\tLOOPs\t"a["LOOPs"]}' \
> usageReports/wholerunTasksForExcel.txt

fi

# notes for future purposes :
# --------------------------------
# Flashing counts - for description page

# All reads
# Old versions of Flash say "Total reads" when counting total read pairs. New versions of Flash say "Total pairs".
# all=$(($( cat ${targetDir}/F1_beforeCCanalyser_${Sample}_${CCversion}/flashing.log | grep "Total [rp][ea][ai][dr]s:" | sed 's/.*:\s*//' )))

# Flashed (see notes for "All reads" above)

#    TEMPcountAllflashed=$(($( cat   flashing.log | grep "Combined [rp][ea][ai][dr]s:" | sed 's/.*:\s*//' )))
# TEMPcountAllnonflashed=$(($( cat flashing.log | grep "Uncombined [rp][ea][ai][dr]s:" | sed 's/.*:\s*//' )))

# --------------------------------
# RE cut counts - for description page

#    TEMPcountREflashed=$(($( cat    FLASHED_${REenzyme}digestion.log | grep "had at least one ${REenzyme} site in them" | sed 's/\s.*//' )))
# TEMPcountREnonflashed=$(($( cat NONFLASHED_${REenzyme}digestion.log | grep "had at least one ${REenzyme} site in them" | sed 's/\s.*//' )))
# --------------------------------


cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

# ------------------------------------------

makeCombinedBamVisualisation(){
# ------------------------------------------

printThis="Making combined statistics counters and summary figure .. "
printNewChapterToLogFile

rm -rf C_visualiseCombined
mkdir C_visualiseCombined

weWereHereDir=$(pwd)
cd C_visualiseCombined

step8middir=$(pwd)

# Here the command

# publicfolder
# samplename
# CCversion
# REenzyme

# For the time being, not doing this ..

echo
echo "SKIPPING THE FOLLOWING : summary fastq visualisations (as these not supported without the pre-round CCanalyser ..)"
echo

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}
 

# ------------------------------------------
}

# ------------------------------------------

makeCombinedOligorunSummaries(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd D_analyseOligoWise

# ###############################
# Oligo final counts master table
# ###############################

# All counts - just a list, not in table format
cat chr*/*/F6_greenGraphs_combined_${samplename}_${CCversion}/COMBINED_report_${CCversion}.txt | grep '(final count)' > COMBINED_allFinalCounts.txt

# 3110002H16Rik_L_R 15 Capture fragments (final count):   1039
# 3110002H16Rik_L_R 17a Reporter fragments (final count) :        812
# 3110002H16Rik_L_R 17b Reporter fragments CIS (final count) :    461
# 3110002H16Rik_L_R 17c Reporter fragments TRANS (final count) :  351

if [ "${tiled}" -eq 0 ];then

echo -e "oligo\tCaptureFrags\tRepFragsTotal\tRepFragsCIS\tRepFragsTRANS" > COMBINED_allFinalCounts_table.txt
cat COMBINED_allFinalCounts.txt | sed 's/\s/\t/' | rev | sed 's/\s/\t/' | rev | paste - - - - | cut -f 1,3,6,9,12 >> COMBINED_allFinalCounts_table.txt

else
    
echo -e "oligo\tRepFragsTotal\tRepFragsCIS\tRepFragsTRANS" > COMBINED_allFinalCounts_table.txt
cat COMBINED_allFinalCounts.txt | sed 's/\s/\t/' | rev | sed 's/\s/\t/' | rev | paste - - - | cut -f 1,3,6,9,12 >> COMBINED_allFinalCounts_table.txt

fi

if [ "${tiled}" -eq 0 ];then

tail -n +2 COMBINED_allFinalCounts_table.txt | \
awk 'BEGIN{cap=0;r=0;c=0;t=0;cap2=0;r2=0;c2=0;t2=0;N=0}\
{ N+=1; cap+=$2; r+=$3; c+=$4; t+=$5; cap2+=$2*$2; r2+=$3*$3; c2+=$4*$4; t2+=$5*$5;}\
END{\
capM=cap/N;rM=r/N;cM=c/N;tM=t/N;\
print"Mean   CaptureFrags count :\t"capM"\t with std of :\t"sqrt((cap2-capM*capM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
print"Mean Total repFrags count :\t"rM"\t with std of :\t"sqrt((r2-rM*rM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
print"Mean   CIS repFrags count :\t"cM"\t with std of :\t"sqrt((c2-cM*cM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
print"Mean TRANS repFrags count :\t"tM"\t with std of :\t"sqrt((t2-tM*tM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
}' \
> TEMP_meansAndStds.txt

else

tail -n +2 COMBINED_allFinalCounts_table.txt | \
awk 'BEGIN{r=0;c=0;t=0;cap2=0;r2=0;c2=0;t2=0;N=0}\
{ N+=1; r+=$3; c+=$4; t+=$5; r2+=$3*$3; c2+=$4*$4; t2+=$5*$5;}\
END{\
rM=r/N;cM=c/N;tM=t/N;\
print"Mean Total repFrags count :\t"rM"\t with std of :\t"sqrt((r2-rM*rM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
print"Mean   CIS repFrags count :\t"cM"\t with std of :\t"sqrt((c2-cM*cM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
print"Mean TRANS repFrags count :\t"tM"\t with std of :\t"sqrt((t2-tM*tM*N)/(N-1))"\tand min/lowerQuart/median/upperQuart/max of:";\
}' \
> TEMP_meansAndStds.txt
    
fi


# Median and quartiles - this is not exact, but close enough.

oligoCountHalf=$(($(($(tail -n +2 COMBINED_allFinalCounts_table.txt | grep -c "")))/2))
oligoCountOneFourth=$(($(($(tail -n +2 COMBINED_allFinalCounts_table.txt | grep -c "")))/4))

tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 2 | sort -n | head -n 1 >  TEMP_min.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 3 | sort -n | head -n 1 >> TEMP_min.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 4 | sort -n | head -n 1 >> TEMP_min.txt
if [ "${tiled}" -eq 0 ];then
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 5 | sort -n | head -n 1 >> TEMP_min.txt
fi

tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 2 | sort -n | tail -n 1 >  TEMP_max.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 3 | sort -n | tail -n 1 >> TEMP_max.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 4 | sort -n | tail -n 1 >> TEMP_max.txt
if [ "${tiled}" -eq 0 ];then
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 5 | sort -n | tail -n 1 >> TEMP_max.txt
fi

tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 2 | sort -n | head -n ${oligoCountHalf} | tail -n 1 >  TEMP_medians.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 3 | sort -n | head -n ${oligoCountHalf} | tail -n 1 >> TEMP_medians.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 4 | sort -n | head -n ${oligoCountHalf} | tail -n 1 >> TEMP_medians.txt
if [ "${tiled}" -eq 0 ];then
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 5 | sort -n | head -n ${oligoCountHalf} | tail -n 1 >> TEMP_medians.txt
fi

tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 2 | sort -n | head -n ${oligoCountOneFourth} | tail -n 1 >  TEMP_lower.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 3 | sort -n | head -n ${oligoCountOneFourth} | tail -n 1 >> TEMP_lower.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 4 | sort -n | head -n ${oligoCountOneFourth} | tail -n 1 >> TEMP_lower.txt
if [ "${tiled}" -eq 0 ];then
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 5 | sort -n | head -n ${oligoCountOneFourth} | tail -n 1 >> TEMP_lower.txt
fi

tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 2 | sort -n | tail -n ${oligoCountOneFourth} | head -n 1 >  TEMP_upper.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 3 | sort -n | tail -n ${oligoCountOneFourth} | head -n 1 >> TEMP_upper.txt
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 4 | sort -n | tail -n ${oligoCountOneFourth} | head -n 1 >> TEMP_upper.txt
if [ "${tiled}" -eq 0 ];then
tail -n +2 COMBINED_allFinalCounts_table.txt | cut -f 5 | sort -n | tail -n ${oligoCountOneFourth} | head -n 1 >> TEMP_upper.txt
fi

paste TEMP_meansAndStds.txt TEMP_min.txt TEMP_lower.txt TEMP_medians.txt TEMP_upper.txt TEMP_max.txt > COMBINED_meanStdMedian_overOligos.txt
rm -f TEMP_meansAndStds.txt TEMP_min.txt TEMP_lower.txt TEMP_medians.txt TEMP_upper.txt TEMP_max.txt


# ###############################
# Usage reports
# ###############################

if [ "${useWholenodeQueue}" -eq 1 ]; then 

mkdir usageReports
mkdir usageReports/makingOf
cp qsubLogFiles/wholerun* usageReports/makingOf/.
cp qsubLogFiles/allRunsRUNTIME.log usageReports/.

cat usageReports/makingOf/wholerunTasks.txt | sed 's/\s\s*/\t/g' | \
sed 's/_fl//g' | sed 's/_nonfl//g' \
| sed 's/publicFiles/public/g' | sed 's/ReDigest/prepF1/g' | sed 's/SetParams/prepF1/g' \
| sed 's/bamToSam/prepF1/g' | sed 's/F6_cc/F6/g' | sed 's/F6_samcomb/F6/g' \
> usageReports/makingOf/wholerunTasksParsed.txt

cat usageReports/makingOf/wholerunUsage.txt | sed 's/M\s/\t/g' | sed 's/M$//'> usageReports/wholerunUsageForExcel.txt
cat usageReports/makingOf/wholerunTasksParsed.txt \
|  awk '{a["prepF1"]=0;a["F2"]=0;a["F3"]=0;a["F5"]=0;a["F6"]=0;a["public"]=0;for(i=2;i<=NF;i++){a[$i]=a[$i]+1}; \
print $1"\tprepF1\t"a["prepF1"]"\tF2\t"a["F2"]"\tF3\t"a["F3"]"\tF5\t"a["F5"]"\tF6\t"a["F6"]"\tpublic\t"a["public"]}' \
> usageReports/wholerunTasksForExcel.txt

fi
 
cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}
 
# ------------------------------------------
}

# ------------------------------------------

makeOligorunSummaries(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd D_analyseOligoWise

# ###############################
# Duplicate filtering oneliners
# ###############################

cat chr*/*/F3_orangeGraphs_${samplename}_${CCversion}/${flashstatus}_REdig_report_${CCversion}.txt | grep '11 Total number of reads entering the analysis' \
| sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > TMP_allRds.txt
cat chr*/*/F3_orangeGraphs_${samplename}_${CCversion}/${flashstatus}_REdig_report_${CCversion}.txt | grep '16 Non-duplicated reads' \
| sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > TMP_nondupRds.txt

# if [ "${tiled}" -eq 0 ];then
cat chr*/*/F3_orangeGraphs_${samplename}_${CCversion}/${flashstatus}_REdig_report_${CCversion}.txt | grep '26a Actual reported fragments' \
| sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > TMP_repFragTotal.txt
cat chr*/*/F3_orangeGraphs_${samplename}_${CCversion}/${flashstatus}_REdig_report_${CCversion}.txt | grep '26b Actual reported CIS fragments' \
| sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > TMP_repFragCis.txt
cat chr*/*/F3_orangeGraphs_${samplename}_${CCversion}/${flashstatus}_REdig_report_${CCversion}.txt | grep '26c Actual reported TRANS fragments' \
| sed 's/.*\s//' | awk 'BEGIN{a=0}{a=a+$1}END{print a}' > TMP_repFragTrans.txt
# else
# echo
# fi
    
if [ "${tiled}" -eq 0 ];then
echo -e "allRds\tnondupRds\trepFragTotal\trepFragCis\trepFragTrans" > ${flashstatus}_dupFiltStats.txt
else
echo -e "allRds\tnondupRds" > ${flashstatus}_dupFiltStats.txt    
fi

# if [ "${tiled}" -eq 0 ];then
paste TMP_allRds.txt TMP_nondupRds.txt TMP_repFragTotal.txt TMP_repFragCis.txt TMP_repFragTrans.txt >> ${flashstatus}_dupFiltStats.txt
rm -f TMP_allRds.txt TMP_nondupRds.txt TMP_repFragTotal.txt TMP_repFragCis.txt TMP_repFragTrans.txt
# else
# paste TMP_allRds.txt TMP_nondupRds.txt >> ${flashstatus}_dupFiltStats.txt
# rm -f TMP_allRds.txt TMP_nondupRds.txt 
# fi

echo 'Nondup reads %' > ${flashstatus}_percentages.txt
tail -n 1 ${flashstatus}_dupFiltStats.txt | cut -f 1-2 | awk '{print ($2/$1)*100}' >>${flashstatus}_percentages.txt
echo '' >> ${flashstatus}_percentages.txt

# if [ "${tiled}" -eq 0 ];then
echo 'Total cisreps/allrepfrags  %' >>${flashstatus}_percentages.txt
tail -n 1 ${flashstatus}_dupFiltStats.txt | cut -f 3-4 | awk '{print ($2/$1)*100}' >>${flashstatus}_percentages.txt
echo '' >> ${flashstatus}_percentages.txt
echo 'Average reporter fragment count per read (final count)' >>${flashstatus}_percentages.txt
tail -n 1 ${flashstatus}_dupFiltStats.txt | cut -f 2-3 | awk '{print ($2/$1)}' >>${flashstatus}_percentages.txt
echo '' >> ${flashstatus}_percentages.txt
# fi

cat ${flashstatus}_percentages.txt ${flashstatus}_dupFiltStats.txt > ${flashstatus}_percentagesAndFinalCounts.txt
 
# ###############################
# Usage reports
# ###############################

if [ "${useWholenodeQueue}" -eq 1 ]; then 

mkdir usageReports
mkdir usageReports/makingOf
cp qsubLogFiles/wholerun* usageReports/makingOf/.
cp qsubLogFiles/allRunsRUNTIME.log usageReports/.

cat usageReports/makingOf/wholerunTasks.txt | sed 's/\s\s*/\t/g' | \
sed 's/_fl//g' | sed 's/_nonfl//g' \
| sed 's/publicFiles/public/g' | sed 's/ReDigest/prepF1/g' | sed 's/SetParams/prepF1/g' \
| sed 's/bamToSam/prepF1/g' | sed 's/F6_cc/F6/g' | sed 's/F6_samcomb/F6/g' \
> usageReports/makingOf/wholerunTasksParsed.txt

cat usageReports/makingOf/wholerunUsage.txt | sed 's/M\s/\t/g' | sed 's/M$//'> usageReports/wholerunUsageForExcel.txt
cat usageReports/makingOf/wholerunTasksParsed.txt \
|  awk '{a["prepF1"]=0;a["F2"]=0;a["F3"]=0;a["F5"]=0;a["F6"]=0;a["public"]=0;for(i=2;i<=NF;i++){a[$i]=a[$i]+1}; \
print $1"\tprepF1\t"a["prepF1"]"\tF2\t"a["F2"]"\tF3\t"a["F3"]"\tF5\t"a["F5"]"\tF6\t"a["F6"]"\tpublic\t"a["public"]}' \
> usageReports/wholerunTasksForExcel.txt

fi
 
cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}
 
# ------------------------------------------
}

# ------------------------------------------

checkRunCrashes(){
# ------------------------------------------

# If we crashed uncontrollably, we will have runJustNow_*.log file(s) for the crashed run(s) still present.

howManyCrashes=0
howManyCrashes=$(($( ls -1 runJustNow_*.log 2>/dev/null | grep -c "" )))
checkThis="${howManyCrashes}"
checkedName='${howManyCrashes}'
checkParse

if [ "${howManyCrashes}" -ne 0 ]; then
  
  printThis="Some runs crashed UNCONTROLLABLY during the analysis \n ( this is most probably a bug - save your crashed output files and report to Jelena )."
  printNewChapterToLogFile
  
  printThis="In total ${howManyCrashes} of your ${fastqOrOligo} runs crashed."
  printToLogFile
  
  printThis="These ${fastqOrOligo}s crashed :"
  printToLogFile

  printThis=$( ls -1 runJustNow_*.log | sed 's/runJustNow_//' | sed 's/.log//' | tr '\n' ' ') 
  printToLogFile
  
  printThis="They crashed in these steps :"
  printToLogFile

  printThis=$( cat runJustNow_*.log | sort | uniq -c ) 
  printToLogFile  
  
  weWillExitAfterThis=1
    
else
  printThis="OK - Checked for run crashes (due to bugs in code) - found none. Continuing. "
  printToLogFile   
fi

# ------------------------------------------
}

# ------------------------------------------

checkFastqRunErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs

# Check that no run crashes.

weWillExitAfterThis=0;
checkRunCrashes


# Double check that no crashes ..

TEMPoriginalCount=$(($( cat ../PIPE_fastqPaths.txt | grep -c "" )))
TEMPfinishedFineCount=$(($( cat fastq_*/fastqRoundSuccess.log | grep -c "^prepareOK 1 runOK 1$" )))
folderCountOK=1

if [ "${TEMPoriginalCount}" -ne "${TEMPfinishedFineCount}" ]; then
   
  folderCountOK=0 

  printThis="Some FASTQs crashed during first steps of analysis. (details below)"
  printNewChapterToLogFile
  
  printThis="We had ${TEMPoriginalCount} fastqs starting the run.\nBut only ${TEMPfinishedFineCount} of them report finishing fine :"
  printToLogFile
  
  cat fastq_*/fastqRoundSuccess.log | uniq -c 
  cat fastq_*/fastqRoundSuccess.log | uniq -c >> "/dev/stderr"
  
  echo ""
  echo ""  >> "/dev/stderr"
  
fi

# Check that no errors.

rm -f fastqRoundSuccess.log
for file in fastq_*/fastqRoundSuccess.log
do
    cat ${file} | sed 's/^/'$(dirname ${file})'\t/' >> fastqRoundSuccess.log
done

howManyErrors=$(($( cat fastqRoundSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ] || [ "${folderCountOK}" -eq 0 ]  ; then
  
  printThis="Some fastqs crashed during first steps of analysis ( possibly quota issues ? )."
  printNewChapterToLogFile
  
  printThis="These samples had runtime errors :"
  printToLogFile
  cat fastqRoundSuccess.log | grep -v '^#' | grep -v '\s1$'
  cat fastqRoundSuccess.log | grep -v '^#' | grep -v '\s1$' >> "/dev/stderr"
  echo ""
  echo "" >> "/dev/stderr"
  
  head -n 1 fastqRoundSuccess.log > failedFastqsList.log
  cat fastqRoundSuccess.log | grep -v '^#' | grep -v '\s1$' >> failedFastqsList.log
  
  printThis="Check which samples failed : $(pwd)/failedFastqsList.log ! "
  printToLogFile
  printThis="Detailed error logs in files : B_mapAndDivideFastqs/fastq_*/run.err "
  printToLogFile
  printThis="Detailed rerun instructions (to rescue failed fastqs and restart the run) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  weWillExitAfterThis=1
    
else
  printThis="All fastqs finished first steps of analysis ! - moving on to analyse sam files .."
  printNewChapterToLogFile   
fi

if [ "${weWillExitAfterThis}" -eq 1 ]; then
  printThis="EXITING ! "
  printToLogFile  
  exit 1
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

prepareFastqRun(){
# ------------------------------------------
# 4) for each fastq in the list : prepare for main run, mainRunner.sh --parallel 1

printThis="Prepare parameter files and fastq-folders for the runs .. "
printNewChapterToLogFile

# Generating possibly-existing output folder - aborting if exists (not supporting any of that stuff yet)

if [ -d B_mapAndDivideFastqs ];then
    printThis="Found existing folder $(pwd)/B_mapAndDivideFastq ! \n Refusing to overwrite ! \n EXITING !! "
    printToLogFile
    exit 1    
fi

mkdir B_mapAndDivideFastqs

weWereHereDir=$(pwd)
cd B_mapAndDivideFastqs
bfolderDirForTestCase=$(pwd)
JustNowFile=$(pwd)/runJustNow

echo
echo $( cat ../PIPE_fastqPaths.txt | grep -c "" )" fastq file pairs found ! "
echo

echo > fastqrunfolderPrepare.log
echo $( cat ../PIPE_fastqPaths.txt | grep -c "" )" fastq file pairs found ! " >> fastqrunfolderPrepare.log
echo >> fastqrunfolderPrepare.log

fastqCounter=1;
for (( i=1; i<=$(($( cat ../PIPE_fastqPaths.txt | grep -c "" ))); i++ ))
do {
    
    printThis="Parameters for ${fastqCounter}th row of of PIPE_fastqPaths.txt , i.e. folder fastq_${fastqCounter}"
    printToLogFile
   
    mkdir fastq_${fastqCounter}
    cat ../PIPE_fastqPaths.txt | tail -n +${fastqCounter} | head -n 1 | awk '{print $1"_"$2"_"$3"\t"$0}' > fastq_${fastqCounter}/PIPE_fastqPaths.txt
    
    downloadLogBasename="$(pwd)/fastq${fastqCounter}_download"
    # in prepareSampleForCCanalyser.sh this file will be in $(pwd), while download in progress :
    # ${downloadLogBasename}_inProgress.log
    # i.e. $(pwd)/fastq${fastqCounter}_download_inProgress.log
    
    cdCommand='cd fastq_${fastqCounter}'
    cdToThis="fastq_${fastqCounter}"
    checkCdSafety
    tempHere=$(pwd)
    cd fastq_${fastqCounter}
    
    echo ${CaptureParallelPath}/prepareSampleForCCanalyser.sh ${downloadLogBasename} ${JustNowFile}_${fastqCounter}.log > prepareFastqs.sh
    chmod u+x prepareFastqs.sh
    
    echo ${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${oligofile} --R1 READ1.fastq --R2 READ2.fastq --parallel 1 --parallelSubsample fastq_${fastqCounter} --${REenzymeShort} --pf ${publicfolder} --monitorRunLogFile ${JustNowFile}_${fastqCounter}.log ${parameterList}  > runFastqs.sh
    chmod u+x runFastqs.sh 
    
    echo 
    echo '_______________________________________' >> ../fastqrunfolderPrepare.log
    echo "fastq_${fastqCounter} in folder $(pwd)" >> ../fastqrunfolderPrepare.log    
    echo >> ../fastqrunfolderPrepare.log
    echo "Generated run commands : " >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    echo "prepareFastqs.sh -----------------------" >> ../fastqrunfolderPrepare.log
    cat prepareFastqs.sh >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    echo "runFastqs.sh ---------------------------" >> ../fastqrunfolderPrepare.log
    cat runFastqs.sh >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    
    # Wholenodequeue needs only one copy - and it can already be copied there, as this runs with ONE qsub job only
    # and parallelises "manually" to 24 processes
    if [ "${useWholenodeQueue}" -eq 1 ]; then

        tempHereWeAre="$(pwd)/"

        # Normal user case : using tmpdir.
        if [ "${useTMPDIRforThis}" -eq 1 ]; then
        cd $TMPDIR
        # not using tmpdir - for testing purposes only.    
        else
        echo "Using wholenode queue WITHOUT tmpdir : testing purposes only ! "
        cd ..
        fi
        
        # If we didn't do this already (i.e. if we are the first fastq to be prepared)
        if [ ! -d A_commonForAll ]; then
            mkdir A_commonForAll
            cd A_commonForAll
            cp ${reGenomeFilePath} .
            cp ${reBlacklistFilePath} .
            cp ${reWhitelistFilePath} .
        else
            cd A_commonForAll
        fi
        
        pwd >> ${tempHereWeAre}../fastqrunfolderPrepare.log
        ls -lht >> ${tempHereWeAre}../fastqrunfolderPrepare.log
        
        cdCommand='cd ${tempHereWeAre} in making A_commonForAll in TMPDIR'
        cdToThis="${tempHereWeAre}"
        checkCdSafety
        cd ${tempHereWeAre}
        pwd >> ../fastqrunfolderPrepare.log
        
        
    # Task-job gets symlinks to each file - in each fastq.
    # Also making the runtime TMPDIR monitoring script
    else
        ln -s ${reGenomeFilePath} .
        ln -s ${reBlacklistFilePath} .
        ln -s ${reWhitelistFilePath} .
        
        if [ "${useTMPDIRforThis}" -eq 1 ];then
        # TMPDIR memory usage ETERNAL loop into here, as cannot be done outside the node ..
        echo 'while [ 1 == 1 ]; do' > tmpdirMemoryasker.sh
        echo 'du -sm ${2} | cut -f 1 2>> /dev/null > ${3}runJustNow_${1}.log.tmpdir' >> tmpdirMemoryasker.sh                
        echo 'sleep 60' >> tmpdirMemoryasker.sh
        echo 'done' >> tmpdirMemoryasker.sh
        echo  >> tmpdirMemoryasker.sh
        chmod u+x ./tmpdirMemoryasker.sh        
        fi

    fi

    cp ${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh .
    chmod u+x echoer_for_SunGridEngine_environment.sh
    ls -lht >> ../fastqrunfolderPrepare.log
    echo >> ../fastqrunfolderPrepare.log
    
    fastqCounter=$((${fastqCounter}+1))
    cdCommand='cd ${tempHere}'
    cdToThis="${tempHere}"
    checkCdSafety
    cd ${tempHere}

    }
    done

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}
    
}

checkBamprepcombineErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cdCommand='cd ${checkBamsOfThisDir}'
cdToThis="${checkBamsOfThisDir}"
checkCdSafety  
cd ${checkBamsOfThisDir}

# Double check that no crashes ..

TEMPoriginalCount=$(($( ls -1 ../A_prepareForRun/OLIGOSindividualFiles/*/* | grep -c oligoFileOneliner.txt )))
TEMPfinishedFineCount=$(($( cat bamcombineprepSuccess.log | grep -v '^#' | cut -f 2 | grep -c '^1$' )))
folderCountOK=1

if [ "${TEMPoriginalCount}" -ne "${TEMPfinishedFineCount}" ]; then
   
  folderCountOK=0 

  printThis="Some oligos crashed when preparing the BAM file combining. (details below)"
  printNewChapterToLogFile
  
  printThis="We had ${TEMPoriginalCount} oligos starting the combine preparation.\nBut only ${TEMPfinishedFineCount} of them report finishing fine :"
  printToLogFile
  
  cat bamcombineprepSuccess.log | grep -v '^#' | sort | uniq -c 
  cat bamcombineprepSuccess.log | grep -v '^#' | sort | uniq -c >> "/dev/stderr"
  
  echo ""
  echo ""  >> "/dev/stderr"
  
fi

# Check that no errors.

howManyErrors=$(($( cat bamcombineprepSuccess.log | grep -v '^#' | cut -f 2 | grep -cv '^1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ] || [ "${folderCountOK}" -eq 0 ]; then
  
  printThis="Couldn't prepare some oligos in ${checkBamsOfThisDir} for the bam combining."
  printNewChapterToLogFile
  
  echo "These oligos had errors :"
  echo
  cat bamcombineprepSuccess.log | grep -v '^#' | grep -v '\s1\s'
  echo

  cat bamcombineprepSuccess.log | grep -v '^#' | grep -v '\s1\s' >> failedBamcombineprepList.log
  
  printThis="Check which oligos failed, and why : $(pwd)/failedBamcombineprepList.log ! "
  printToLogFile
  printThis="Detailed rerun instructions (to rescue failed oligos and restart the run) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All bamcombining preparations of ${checkBamsOfThisDir} were made ! - moving to actually combining the bam files .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

bamCombinePrepareRun(){

# ------------------------------------------

weWereHereDir=$(pwd)
cd C_combineOligoWise

echo "# Bam combine - preparing for run - 1 (prepare finished without errors) , 0 (prepare finished with errors)" > bamcombineprepSuccess.log

# We are supposed to have oneliner oligo files of structure :
# C_combineOligoWise/chr1/Hba-1/oligoFileOneliner.txt

# Copy over the folder structure - for the log files
mkdir bamlistings
cp -r * bamlistings/. 2> "/dev/null"
rmdir bamlistings/bamlistings
rm -f bamlistings/bamcombineprepSuccess.log

mkdir runlistings

F1foldername="F1_beforeCCanalyser_${samplename}_${CCversion}"
B_subfolderWhereBamsAre="${F1foldername}/LOOP5_filteredSams"

printThis="B_FOLDER_PATH ${B_FOLDER_PATH}\nB_subfolderWhereBamsAre ${B_subfolderWhereBamsAre}\nF1foldername ${F1foldername}"
printToLogFile

oligofileCount=1
for oligoFolder in chr*/*
do
{
    printThis="${oligoFolder}"
    printToLogFile
    thisOligoName=$( basename ${oligoFolder} )
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    thisChr=$( dirname ${oligoFolder} )
    checkThis="${thisChr}"
    checkedName='${thisChr}'
    checkParse
    echo -n "${thisChr}_${thisOligoName}" >> bamcombineprepSuccess.log
    thisBunchIsFine=1
    thisBunchAlreadyReportedFailure=0
    
    inputbamstringFlashed="${B_FOLDER_PATH}/fastq_*/${B_subfolderWhereBamsAre}/${thisChr}/FLASHED_${thisOligoName}_possibleCaptures.bam"
    inputbamstringNonflashed="${B_FOLDER_PATH}/fastq_*/${B_subfolderWhereBamsAre}/${thisChr}/NONFLASHED_${thisOligoName}_possibleCaptures.bam"
    firstflashedfile=$( ls -1 ${inputbamstringFlashed} | head -n 1 )
    firstnonflashedfile=$( ls -1 ${inputbamstringNonflashed} | head -n 1 )
    outputbamsfolder="${thisChr}/${thisOligoName}"
    outputlogsfolder="."
    
    bamCombineInnerSub
    
    # Run list update
    echo "${thisChr}/${thisOligoName}" >> runlist.txt
    echo "${thisChr}/${thisOligoName}" > runlistings/oligo${oligofileCount}.txt
    
    oligofileCount=$((${oligofileCount}+1))

}
done

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

checkBamcombineErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cdCommand='cd ${checkBamsOfThisDir}'
cdToThis="${checkBamsOfThisDir}"
checkCdSafety  
cd ${checkBamsOfThisDir}

# Check that no run crashes.

weWillExitAfterThis=0;
checkRunCrashes


# Double check that no crashes ..

TEMPoriginalCount=$(($( ls -1 ../A_prepareForRun/OLIGOSindividualFiles/*/* | grep -c oligoFileOneliner.txt )))
TEMPfinishedFineCount=$(($( cat chr*/*/bamcombineSuccess.log | grep -c '\s1$' )))
folderCountOK=1

if [ "${TEMPoriginalCount}" -ne "${TEMPfinishedFineCount}" ]; then
   
  folderCountOK=0 

  printThis="Some oligos crashed during the BAM file combining. (details below)"
  printNewChapterToLogFile
  
  printThis="We had ${TEMPoriginalCount} oligos starting the combine.\nBut only ${TEMPfinishedFineCount} of them report finishing fine :"
  printToLogFile
  
  cat chr*/*/bamcombineSuccess.log | sed 's/.* runOK/runOK/' | sort | uniq -c  
  cat chr*/*/bamcombineSuccess.log | sed 's/.* runOK/runOK/' | sort | uniq -c >> "/dev/stderr"
  
  echo ""
  echo ""  >> "/dev/stderr"
  
fi

# Check that no errors.

rm -f bamcombineSuccess.log
for file in chr*/*/bamcombineSuccess.log
do
    
    thisOligoName=$( basename $( dirname ${file} ))
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    thisChr=$( basename  $( dirname $( dirname ${file} )))
    checkThis="${thisChr}"
    checkedName='${thisChr}'
    checkParse
    echo -en "${thisChr}_${thisOligoName}\t" >> bamcombineSuccess.log    
    cat $file >> bamcombineSuccess.log

done

howManyErrors=$(($( cat bamcombineSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some oligo bunches in ${checkBamsOfThisDir} crashed during the combining process ( possibly quota issues ? )."
  printNewChapterToLogFile
  
  echo "These oligo bunches had errors :"
  echo
  cat bamcombineSuccess.log | grep -v '^#' | grep -v '\s1$'
  echo

  cat bamcombineSuccess.log | grep -v '^#' | grep -v '\s1$' >> failedBamcombineList.log
  
  printThis="Check which samples failed, and why : $(pwd)/failedBamcombineList.log ! "
  printToLogFile
  printThis="Detailed rerun instructions (to rescue failed fastqs and restart the run) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  weWillExitAfterThis=1

    
else
  printThis="All bams of ${checkBamsOfThisDir} were combined ! - moving to bam-wise analysis steps .."
  printNewChapterToLogFile   
fi

if [ "${weWillExitAfterThis}" -eq 1 ]; then
  printThis="EXITING ! "
  printToLogFile  
  exit 1
fi


cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

bamCombineChecksSaveThisForFuturePurposes(){
    
# This sub is not used (but saved for possible later scavenging purposes)
    
    ls -lht ${outputbamsfolder}/FLASHED_REdig.bam
    if [ $? != 0 ]; then thisBunchIsFine=0;fi
    # ls -lht ${outputbamsfolder}/NONFLASHED_REdig.bam
    if [ $? != 0 ]; then thisBunchIsFine=0;fi

    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\tsamtools_cat_output_bams_dont_exist" >> ${outputlogsfolder}/bamcombineSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    if [ ! -s "${outputbamsfolder}/FLASHED_REdig.bam" ]
    then thisBunchIsFine=0;fi
    if [ ! -s "${outputbamsfolder}/NONFLASHED_REdig.bam" ]
    then thisBunchIsFine=0;fi
    
    if [ "${thisBunchAlreadyReportedFailure}" -eq 0 ];then
    
    if [ "${thisBunchIsFine}" -eq 0 ]; then
    {
     echo -e "\t0\tsamtools_cat_output_bams_are_empty_files" >> ${outputlogsfolder}/bamcombineSuccess.log
    }
    else
    {
     echo -en "\t1\tbamCombine_succeeded" >> ${outputlogsfolder}/bamcombineSuccess.log
     
     TEMPflashedCount=$( samtools view -c ${outputbamsfolder}/FLASHED_REdig.bam )
     TEMPnonflashedCount=$( samtools view -c ${outputbamsfolder}/NONFLASHED_REdig.bam )
     
     echo -e "\tFlashedreadCount:${TEMPflashedCount}\tNonflashedreadCount:${TEMPnonflashedCount}" >> ${outputlogsfolder}/bamcombineSuccess.log
     
     # Globin combining doesn't get the very detailed counters - so asking if detailed counters folder exists ..
     if [ -d  bamlistings ];then
     echo -e "Combined count :\t${TEMPflashedCount}" >> bamlistings/bamlisting_FLASHED_chr${thisOligoName}.txt
     echo -e "Combined count :\t${TEMPnonflashedCount}" >> bamlistings/bamlisting_NONFLASHED_chr${thisOligoName}.txt
     fi 
     
    }
    fi
    
    fi
    
}

bamCombineInnerSub(){

    echo "thisChr/thisOligoName ${thisChr}/${thisOligoName}"
    echo "firstflashedfile ${firstflashedfile}"
    echo "firstnonflashedfile ${firstnonflashedfile}"
    echo "inputbamstringFlashed ${inputbamstringFlashed}"
    echo "inputbamstringNonflashed ${inputbamstringNonflashed}"
    echo "outputbamsfolder ${outputbamsfolder}"
    echo "outputlogsfolder ${outputlogsfolder}"
    
    echo "ls -lht ${inputbamstringFlashed} > ${outputlogsfolder}/bamlistings/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt"
    ls -lht ${inputbamstringFlashed} > ${outputlogsfolder}/bamlistings/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt
    TEMPfine=$?
    echo "ls -lht ${inputbamstringNonflashed} > ${outputlogsfolder}/bamlistings/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt"
    ls -lht ${inputbamstringNonflashed} > ${outputlogsfolder}/bamlistings/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt
    TEMPfine2=$?
    if [ "${TEMPfine}" -ne 0 ] && [ "${TEMPfine2}" -ne 0 ];then thisBunchIsFine=0;fi

    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ] ; then {
     echo -e "\t0\tcannot_find_files_in_ls" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi  
    
    if [ "${thisBunchIsFine}" -eq 1 ]; then
    {
    samtools view -H ${firstflashedfile} > ${outputbamsfolder}/TEMP_FLASHED.head 2> TEMP.err
    # The above is necessary, as samtools/1.3 does not give output status 1 if it fails. But it writes to error stream, so using that instead.
    if [ $? != 0 ] || [ -s TEMP.err ]; then
        thisBunchIsFine=0
        cat TEMP.err >> "/dev/stderr" 
    fi
    rm -f TEMP.err
    
    samtools view -H ${firstnonflashedfile} > ${outputbamsfolder}/TEMP_NONFLASHED.head 2> TEMP.err
    if [ $? != 0 ] || [ -s TEMP.err ]; then
        thisBunchIsFine=0
        cat TEMP.err >> "/dev/stderr"
    fi
    rm -f TEMP.err
    }
    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\tcannot_make_sam_headers" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi    
    
    if [ "${thisBunchIsFine}" -eq 1 ]; then
    {
    echo "echo Read counts" > ${outputbamsfolder}/bamCombineRun.sh    
    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo "TEMPcountFtotal=0" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "for tempfile in ${inputbamstringFlashed}" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "do" >> ${outputbamsfolder}/bamCombineRun.sh    
    echo 'TEMPcountF=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ -s "${tempfile}" ]; then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountF=$( samtools view -c ${tempfile} )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountFtotal=$((${TEMPcountFtotal}+${TEMPcountF}))' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcountF}\t${tempfile}" >> '$(cd ${outputlogsfolder};pwd)"/bamlistings/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh    
    echo 'echo ${TEMPcountF} >> FLASHEDbamINcounts.txt' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "done" >> ${outputbamsfolder}/bamCombineRun.sh

    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo "TEMPcountNFtotal=0" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "for tempfile in ${inputbamstringNonflashed}" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "do" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountNF=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ -s "${tempfile}" ]; then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountNF=$( samtools view -c ${tempfile} )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcountNFtotal=$((${TEMPcountNFtotal}+${TEMPcountNF}))' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcountNF}\t${tempfile}" >> '$(cd ${outputlogsfolder};pwd)"/bamlistings/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo ${TEMPcountNF} >> NONFLASHEDbamINcounts.txt' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "done" >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo  >> ${outputbamsfolder}/bamCombineRun.sh
    
    echo "echo Samtools cat" >> ${outputbamsfolder}/bamCombineRun.sh
    echo  >> ${outputbamsfolder}/bamCombineRun.sh

    # Flashed - if we have bams ..
    echo 'if [ "${TEMPcountFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "date" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "samtools cat -h TEMP_FLASHED.head ${inputbamstringFlashed} > FLASHED_REdig.bam 2> samtoolsCat.err" >> ${outputbamsfolder}/bamCombineRun.sh 
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    # Nonflashed - if we have bams ..
    echo 'if [ "${TEMPcountNFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo "date" >> ${outputbamsfolder}/bamCombineRun.sh
    echo "samtools cat -h TEMP_NONFLASHED.head ${inputbamstringNonflashed} > NONFLASHED_REdig.bam 2>> samtoolsCat.err" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    echo  >> ${outputbamsfolder}/bamCombineRun.sh

    # Counts ..
    echo 'TEMPcount=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ "${TEMPcountFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcount=$( samtools view -c FLASHED_REdig.bam )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcount}\t"$(pwd)"/FLASHED_REdig.bam" >> '$(cd ${outputlogsfolder};pwd)"/bamlistings/${thisChr}/${thisOligoName}/bamlisting_FLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    echo 'echo ${TEMPcount} >> FLASHEDbamOUTcount.txt' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcount=0' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'if [ "${TEMPcountNFtotal}" -ne 0 ];then' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'TEMPcount=$( samtools view -c NONFLASHED_REdig.bam )' >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'echo -e "${TEMPcount}\t"$(pwd)"/NONFLASHED_REdig.bam" >> '$(cd ${outputlogsfolder};pwd)"/bamlistings/${thisChr}/${thisOligoName}/bamlisting_NONFLASHED.txt" >> ${outputbamsfolder}/bamCombineRun.sh
    echo 'fi' >> ${outputbamsfolder}/bamCombineRun.sh   
    echo 'echo ${TEMPcount} >> NONFLASHEDbamOUTcount.txt' >> ${outputbamsfolder}/bamCombineRun.sh

    if [ ! -s ${outputbamsfolder}/bamCombineRun.sh ]; then thisBunchIsFine=0;fi
    
    }    
    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\trunscript_generation_failed" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    chmod u+x ${outputbamsfolder}/bamCombineRun.sh
    if [ $? != 0 ]; then
        thisBunchIsFine=0
    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\trunscript_chmod_failed" >> ${outputlogsfolder}/bamcombineprepSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    if [ "${thisBunchIsFine}" -eq 1 ];then
     rm -f TEMP_FLASHED.head TEMP_NONFLASHED.head
     echo -e "\t1\tbamCombinePrep_succeeded" >> ${outputlogsfolder}/bamcombineprepSuccess.log
    fi
    
    cp ${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh ${outputbamsfolder}/.
    chmod u+x ${outputbamsfolder}/echoer_for_SunGridEngine_environment.sh

    
}

checkParallelCCanalyserErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd D_analyseOligoWise

# Check that no run crashes.

weWillExitAfterThis=0;
checkRunCrashes


# Check that no errors.

rm -f oligoRoundSuccess.log
for file in */*/oligoRoundSuccess.log
do
    
    thisOligoName=$( basename $( dirname ${file} ))
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    thisChr=$( basename  $( dirname $( dirname ${file} )))
    checkThis="${thisChr}"
    checkedName='${thisChr}'
    checkParse
    echo -en "${thisChr}_${thisOligoName}\t" >> oligoRoundSuccess.log 
    cat $file >> oligoRoundSuccess.log

done

howManyErrors=$(($( cat oligoRoundSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some CC runs crashed ."
  printNewChapterToLogFile
  
  echo "These oligo bunches had problems in blat :"
  echo
  cat oligoRoundSuccess.log | grep -v '^#' | grep -v '\s1$'
  echo
  
  cat oligoRoundSuccess.log | grep -v '^#' | grep -v '\s1$' > failedOligorunsList.log
  
  printThis="Check which oligo bunches failed, and why : $(pwd)/failedOligorunsList.log ! "
  printToLogFile
  printThis="Detailed rerun instructions : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  weWillExitAfterThis=1
    
else
  printThis="All oligo-bunch-wise runs finished - moving on .."
  printNewChapterToLogFile   
fi

if [ "${weWillExitAfterThis}" -eq 1  ]; then
  printThis="EXITING ! "
  printToLogFile  
  exit 1
fi


cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

prepareParallelCCanalyserRun(){
# ------------------------------------------    

BLAT_FOLDER_PREFIX=$(pwd)"/BLAT/reuseblatFolder"
F1foldername="F1_beforeCCanalyser_${samplename}_${CCversion}"

# Copying the existing structure ..

rm -rf D_analyseOligoWise
mkdir D_analyseOligoWise
mkdir D_analyseOligoWise/runlistings

oligofileCount=1
weSawGlobins=0
for file in $(pwd)/C_combineOligoWise/*/*/oligoFileOneliner.txt 
do
    printThis="Oligono ${oligofileCount} --------------------- "
    printToLogFile
    thisOligoName=$( basename $( dirname $file ))
    thisOligoChr=$( basename $( dirname $( dirname $file ))) 
    thisChrFolder=$( dirname $( dirname $file ))
    
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    
    checkThis="${thisOligoChr}"
    checkedName='${thisOligoChr}'
    checkParse
    
    checkThis="${thisChrFolder}"
    checkedName='${thisChrFolder}'
    checkParse
    
    # For testing purposes
    echo "${thisOligoName} with oligo file ${file}"

    if [ ! -d D_analyseOligoWise/${thisOligoChr} ]; then
        mkdir D_analyseOligoWise/${thisOligoChr}
    fi
    
    # Copy over the folder structure - for the log files
    mkdir -p D_analyseOligoWise/bamlistings/${thisOligoChr}/${thisOligoName}
    
    # If we enter the printing loops for this oligo - by default we do, if we already did that globin, we don't.
    wePrepareThisOligo=1
    # If this oligo is globin oligo - by default no.
    thisIsGlobinRound=0
  
    # ######################################################################    
    # For first round testing - turning the globin combining off !
    # ######################################################################
    
#    # TO BE ADDED : we need to know if we have --globin set so we don't do this so that we duplicate the tracks.
#
#    # Hard coding the globin oligos ..    
#    if [ "${thisOligoName}" == "Hba-1" ] || [ "${thisOligoName}" == "Hba-2" ]; then
#        thisOligoName="HbaCombined"
#    elif [ "${thisOligoName}" == "Hbb-b1" ] || [ "${thisOligoName}" == "Hbb-b2" ]; then
#        thisOligoName="HbbCombined"
#    fi
#
#    rm -f D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh
#    
#    # Hard coding the globin captures here ..
#    if [ "${thisOligoName}" == "HbaCombined" ] || [ "${thisOligoName}" == "HbbCombined" ]; then
#        weSawGlobins=1
#        thisIsGlobinRound=1
#        
#        # We enter these oligos twice, naturally, so doing them only if they aren't there yet ..
#        if [ -d D_analyseOligoWise/${thisOligoChr}/${thisOligoName} ];then
#            wePrepareThisOligo=0
#        fi
#    fi

   # ######################################################################    

    
    # Doing the globin, if need be ..
    if [ "${thisIsGlobinRound}" -eq 1 ]; then
        if [ "${wePrepareThisOligo}" -eq 1 ]; then 
            
            printThis="Combining globines - preparing ${thisOligoName} for Capture analysis"
            printToLogFile
            
            echo -n "${thisChr}_${thisOligoName}" >> D_analyseOligoWise/bamcombineSuccess.log
            thisBunchIsFine=1
            thisBunchAlreadyReportedFailure=0
            
            mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}
            mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/${F1foldername}        
            
            globin1="UNDEF"
            globin2="UNDEF"
            
            if [ "${thisOligoName}" == "HbaCombined" ]; then
                globin1="Hba-1"
                globin2="Hba-2"                    
            fi    
            if [ "${thisOligoName}" == "HbbCombined" ]; then
                globin1="Hbb-b1"
                globin2="Hbb-b2"                    
            fi                
            
            # Oligo list - hard coding the globin captures here  ..
            cat ${thisChrFolder}/${globin1}/oligoFileOneliner.txt ${thisChrFolder}/${globin2}/oligoFileOneliner.txt > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/oligoFileOneliner.txt
            # Exclusion list - hard coding the globin captures here  ..
            cat  A_prepareForRun/OLIGOFILE/oligofile_sorted.txt | grep -v '^'${globin1}'\s' | grep -v '^'${globin2}'\s' > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/exclusions.txt
            
            # Catenating the globins to single file ..
            
            if [ ! -d  D_analyseOligoWise/runlistings ]; then mkdir D_analyseOligoWise/runlistings; fi
            
            firstflashedfile="${thisChrFolder}/${globin1}/FLASHED_REdig.bam"
            firstnonflashedfile="${thisChrFolder}/${globin1}/NONFLASHED_REdig.bam"
            inputbamstringFlashed="${thisChrFolder}/${globin1}/FLASHED_REdig.bam ${thisChrFolder}/${globin2}/FLASHED_REdig.bam"
            inputbamstringNonflashed="${thisChrFolder}/${globin1}/NONFLASHED_REdig.bam ${thisChrFolder}/${globin2}/NONFLASHED_REdig.bam"
            outputbamsfolder="D_analyseOligoWise/${thisOligoChr}/${thisOligoName}"
            outputlogsfolder="D_analyseOligoWise"
            
            bamCombineInnerSub
            
            # Run list update (in here this is for log purposes only - not used in the run below)
            echo "${thisOligoChr}/${thisOligoName}" >> D_analyseOligoWise/runlist.txt
            
            tempGlobinUpperDir=$(pwd)
            cd D_analyseOligoWise/${thisOligoChr}/${thisOligoName}
            
            printThis="Combining globin BAMS ${globin1} and ${globin2} too become ${thisOligoName}"
            printToLogFile 
            
            # The below are copied from oneBamcombineWholenodeWorkdir.sh
            echo "bam combining started : $(date)"
              
              fCount=0
              nfCount=0
              runOK=1
              ./bamCombineRun.sh
              if [ $? != 0 ] || [ -s samtoolsCat.err ]; then
              {
                runOK=0    
        
                printThis="Bam-combining failed ! "
                printToLogFile
                
              }
              else
              {
                rm -r TEMP_FLASHED.head TEMP_NONFLASHED.head
                fCount=$(cat FLASHEDbamOUTcount.txt)
                nfCount=$(cat NONFLASHEDbamOUTcount.txt)
              }
              fi  
        
            if [ -s samtoolsCat.err ]; then
                printThis="This was samtools cat crash : error messages in "$(pwd)/samtoolsCat.err
                printToLogFile
            else
                rm -f samtoolsCat.err
            fi
            
            # doQuotaTesting
            
            mkdir ${F1foldername}
            mv FLASHED_REdig.bam ${F1foldername}/.
            mv NONFLASHED_REdig.bam ${F1foldername}/.
            
            printThis="FLASHEDcount ${fCount} NONFLASHEDcount ${nfCount} runOK ${runOK}"
            printToLogFile
            echo "FLASHEDcount ${fCount} NONFLASHEDcount ${nfCount} runOK ${runOK}" > bamcombineSuccess.log
            
            cdCommand="cd ${tempGlobinUpperDir}"
            cdToThis="${tempGlobinUpperDir}"
            checkCdSafety
            cd ${tempGlobinUpperDir}
         
        fi
        
    else
        # Normal captures (no globins)
        mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}
        mkdir D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/${F1foldername} 
        # Oligo itself ..
        cp $file D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.
        # Exclusion list - all but the actual oligo itself ..
        cat  A_prepareForRun/OLIGOFILE/oligofile_sorted.txt | grep -v '^'${thisOligoName}'\s' > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/exclusions.txt
        
        # Not using symlinks - as the mainrunner.sh code will meddle with these files - and thus making restarts potentially quite hard to troubleshoot
        # ln -s ../../../../C_combineOligoWise/${thisOligoChr}/${thisOligoName}/${F1foldername} D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.
        
        # True copy of the bams is made only run-time (to avoid messing up symlinked bams if something goes wrong, and avoid memory peaks before they are needed
        # - this results in saving the bams essentially twice, once in C folder, once in D folder - but for the time being keeping it like it is as assuming a lot of restart needs )
        echo "cp -r $(pwd)/C_combineOligoWise/${thisOligoChr}/${thisOligoName}/*.bam ${F1foldername}/." > D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh
        
    fi
    
    # All runs (globins or not)
    
    if [ "${wePrepareThisOligo}" -eq 1 ]; then
    
    # lister ..
    cp ${CaptureParallelPath}/echoer_for_SunGridEngine_environment.sh D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.
    chmod u+x D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/echoer_for_SunGridEngine_environment.sh
    
    # RE fragments ..
    ln -s ${reGenomeFilePath} D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/.        
    
    # All runs (globins or not) - get the same run.sh - except normal oligos get the copy of the F1 folder, but globins already have true copy so don't need this.
    JustNowFile=$(pwd)/D_analyseOligoWise/runJustNow
    
    # echo "${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --parallel 2 --BLATforREUSEfolderPath ${BLAT_FOLDER_PREFIX} --pf ${publicfolder}/bunchWise/bunch_${thisOligoName} --monitorRunLogFile ${JustNowFile}_${oligofileCount}.log ${parameterList} "
    echo "${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --parallel 2 --BLATforREUSEfolderPath ${BLAT_FOLDER_PREFIX} --pf ${publicfolder}/bunchWise/bunch_${thisOligoName} --monitorRunLogFile ${JustNowFile}_${oligofileCount}.log ${parameterList}" >> D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh
    
    chmod u+x D_analyseOligoWise/${thisOligoChr}/${thisOligoName}/run.sh

    # Run list update
    echo "${thisOligoChr}/${thisOligoName}" >> D_analyseOligoWise/runlist.txt
    echo "${thisOligoChr}/${thisOligoName}" >> D_analyseOligoWise/runlistings/oligo${oligofileCount}.txt
    oligofileCount=$((${oligofileCount}+1))
    
    # If we go thread-wise in TMPDIR, we need to monitor the memory inside there ..
    if [ "${useWholenodeQueue}" -eq 0 ] &&[ "${useTMPDIRforThis}" -eq 1 ];then
        # TMPDIR memory usage ETERNAL loop into here, as cannot be done outside the node ..
        echo 'while [ 1 == 1 ]; do' > tmpdirMemoryasker.sh
        echo 'du -sm ${2} | cut -f 1 2>> /dev/null > ${3}runJustNow_${1}.log.tmpdir' >> tmpdirMemoryasker.sh                
        echo 'sleep 60' >> tmpdirMemoryasker.sh
        echo 'done' >> tmpdirMemoryasker.sh
        echo  >> tmpdirMemoryasker.sh
        chmod u+x ./tmpdirMemoryasker.sh  
    fi
    
    fi
    
    
done

# If we had globins in design, now checking that those got combined no problem ..

if [ "${weSawGlobins}" -eq 1 ]; then

checkBamsOfThisDir="D_analyseOligoWise"
checkBamcombineErrors

fi

# ------------------------------------------    
}

prepareBlatFolder(){

printThis="Preparing BLAT folder .. "
printToLogFile

if [ -e BLAT ]; then
    printThis="Found existing BLAT folder. Refusing to overwrite. "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1  
fi

mkdir BLAT

# If we have previous blats.
if [ "${isReuseBlatPathGiven}" -eq 1 ]; then

ls ${reuseblatpath} >> "/dev/null"
if [ $? -ne 0 ];then
    printThis="Cannot find the BLAT results folder --BLATforREUSEfolderPath ${reuseblatpath} . Check your run command ! "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi

pslFilesFound=$(($( ls -1 ${reuseblatpath} | grep -c ".psl$" )))
if [ "${pslFilesFound}" -eq 0 ];then
    printThis="No .psl files found in the BLAT results folder --BLATforREUSEfolderPath ${reuseblatpath} . Check your run REUSE_blat folder ! "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi

ln -s ${reuseblatpath} BLAT/reuseblatFolder
ls -l BLAT | grep reuseblatFolder

fi

# ------------------------------

# Here we would do blat - but that is wishful thinking, as very impractical,
# so forcing people to provide blat paths ..

if [ "${isReuseBlatPathGiven}" -eq 0 ] && [ "${onlyblat}" -eq 0 ]; then

printThis="Reuse blat paths were not given - exiting ! ( parallel runs have to have --BLATforREUSEfolderPath set )"
printToLogFile
printThis="Generate the REUSEfolder by using --onlyBlat in your run command"
printToLogFile

exit 1

fi

# ------------------------------

# If we have previous blats, and we are not to generate more (i.e. normal run not BLAT only run)

if [ "${isReuseBlatPathGiven}" -eq 1 ] && [ "${onlyblat}" -eq 0 ]; then

blatwarningsCount=0
blatwarningOligoList=""
for file in A_prepareForRun/OLIGOSindividualFiles/*/*/oligoFileOneliner.txt 
do

    thisOligoName=$( basename $( dirname $file ))
    thisOligoChr=$( basename $( dirname $( dirname $file ))) 

    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse

    checkThis="${thisOligoChr}"
    checkedName='${thisOligoChr}'
    checkParse
    
    ls BLAT/reuseblatFolder | grep TEMP_${thisOligoName}_blat.psl >> "/dev/null"
    if [ $? -ne 0 ];then
        blatwarningsCount=$((${blatwarningsCount}+1))
        blatwarningOligoList="${blatwarningOligoList} ${thisOligoChr}/${thisOligoName}"
    fi
    
done

if [ "${blatwarningsCount}" -eq "${pslFilesFound}" ];then
    printThis="None of the ${pslFilesFound} oligos had .psl files in the BLAT results folder --BLATforREUSEfolderPath ${reuseblatpath} . Maybe you are using wrong REUSE_blat folder ? "
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi
if [ "${blatwarningsCount}" -ne 0 ];then
    printThis="EXITING : ${blatwarningsCount} of the oligos didn't have BLAT results .psl file in folder --BLATforREUSEfolderPath ${reuseblatpath} . \t(Even no-homology-regions generates heading lines into the .psl file - assuming failed or missing BLAT run). "
    printToLogFile
    printThis="The psl files in the folder need to be named like this : TEMP_{thisOligoName}_blat.psl \nwhere {thisOligoName} is the oligo name from the oligo file"
    printToLogFile
    printThis="List of the missing oligos below : \n ${blatwarningOligoList}"
    printToLogFile
    printThis="EXITING "
    printToLogFile
    exit 1
fi

fi

}

checkBlatErrors(){
# ------------------------------------------

weWereHereDir=$(pwd)
cd BLAT

# Check that no errors.

howManyErrors=$(($( cat blatSuccess.log | grep -v '^#' | cut -f 2 | grep -cv '^1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some blat runs crashed ."
  printNewChapterToLogFile
  
  echo "These oligos had problems in blat :"
  echo
  cat blatSuccess.log | grep -v '^#' | grep -v '\s1\s'
  echo

  head -n 1 failedBlatsList.log > failedBlatsList.log
  cat failedBlatsList.log | grep -v '^#' | grep -v '\s1$' >> failedBlatsList.log
  
  printThis="Check which oligos failed, and why : $(pwd)/failedBlatsList.log ! "
  printToLogFile
  printThis="To rerun only BLAT runs use --onlyBlat"
  printToLogFile
  printThis="Detailed rerun instructions (if you want to continue automatically to folderC and D generation) : $(pwd)/rerunInstructions.txt "
  printToLogFile
  
  writeRerunInstructionsFile
  # writes rerunInstructions.txt to $pwd

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  printThis="EXITING ! "
  printToLogFile  
  exit 1
    
else
  printThis="All files finished BLAT - moving on .."
  printNewChapterToLogFile   
fi

cdCommand='cd ${weWereHereDir}'
cdToThis="${weWereHereDir}"
checkCdSafety  
cd ${weWereHereDir}

# ------------------------------------------
}

blatRun(){
    
# ------------------------------------------
    
step6topdir=$(pwd)

printThis="Starting the BLAT runs .. "
printNewChapterToLogFile

rm -rf BLAT
mkdir BLAT
BLAT_FOLDER="$(pwd)/BLAT"
cd BLAT

step6middir=$(pwd)

echo "# Blat round run statuses - 1 (finished without errors) , 0 (finished with errors)" > blatSuccess.log

for file in ${oligoBunchesFolder}/* 
do   
    printThis="Blat for oligo bunch file $file"
    printToLogFile
    thisOligoName=$( basename $file | sed 's/^oligofile_sorted_chr//' | sed 's/\.txt$//' )
    checkThis="${thisOligoName}"
    checkedName='${thisOligoName}'
    checkParse
    
    echo -n "chr${thisOligoName}" >> blatSuccess.log
    thisBunchIsFine=1
    thisBunchAlreadyReportedFailure=0
    
    
    rmCommand='rm -rf oligoBunch_${thisOligoName}'
    rmThis="oligoBunch_${thisOligoName}"
    checkRemoveSafety
    rm -rf oligoBunch_${thisOligoName}
    mkdir oligoBunch_${thisOligoName}
    
    cdCommand='cd oligoBunch_${thisOligoName}'
    cdToThis="oligoBunch_${thisOligoName}"
    checkCdSafety
    cd oligoBunch_${thisOligoName}
    
    ln -s ${reGenomeFilePath} .
    if [ $? != 0 ]; then thisBunchIsFine=0;fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     echo -e "\t0\tcannot_symlink_REgenome_file" >> blatSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    printThis="${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --onlyBlat --BLATforREUSEfolderPath ${reuseblatpath} --pf ${publicfolder}/bunchWise ${parameterList} --outfile runBLAT.out --errfile runBLAT.err"
    printToLogFile
    printThis="You can follow the run progress from error and out files :\nBLAT/oligoBunch_${thisOligoName}/runBLAT.out\nBLAT/oligoBunch_${thisOligoName}/runBLAT.err"
    printToLogFile
    ${CaptureSerialPath}/mainRunner.sh --CCversion ${CCversion} --genome ${inputgenomename} -s ${samplename} -o ${file} --${REenzymeShort} --onlyBlat --BLATforREUSEfolderPath ${reuseblatpath} --pf ${publicfolder}/bunchWise ${parameterList} --outfile runBLAT.out --errfile runBLAT.err 1> runBLAT.out 2> runBLAT.err
    if [ $? != 0 ]; then thisBunchIsFine=0;fi
    
    if [ "${thisBunchIsFine}" -eq 0 ] && [ "${thisBunchAlreadyReportedFailure}" -eq 0 ]; then
    {
     # Here better parse ? - should make the filter.sh to report a little better to a log file which we can parse here ..
     echo -e "\t0\tfilter.sh_run_crashed" >> blatSuccess.log
     thisBunchAlreadyReportedFailure=1
    }
    fi
    
    if [ "${thisBunchAlreadyReportedFailure}" -eq 0 ];then
    
    if [ "${thisBunchIsFine}" -eq 0 ]; then
    {
     echo -e "\t0\tblatting_failed_sorryDidntCatchTheReason_checkOutputErrorLogs" >> blatSuccess.log
    }
    else
    {
     echo -e "\t1\tblatting_succeeded" >> blatSuccess.log
    }
    fi  

    fi
    
    if [ "${thisBunchIsFine}" -eq 0 ]; then
      printThis="Blat filter generation failed for oligo bunch ${thisOligoName} ! "
      printToLogFile
        
      # Print some mainrunner error messages here ..
      cat runBLAT.err | grep -v '^\s*$' | grep -B 1 EXITING >&2
      cat runBLAT.err | grep 'refusing to overwrite' >&2

      cat runBLAT.err | grep -v '^\s*$' | grep -B 1 EXITING
      cat runBLAT.err | grep 'refusing to overwrite'
       
      printThis="More details of the crash in file : $(pwd)/runBLAT.err"
      printToLogFile
     
    fi
    
    cdCommand='cd ${step6middir}'
    cdToThis="${step6middir}"
    checkCdSafety  
    cd ${step6middir}
done
cdCommand='cd ${step6topdir}'
cdToThis="${step6topdir}"
checkCdSafety  
cd ${step6topdir}
    
# ------------------------------------------    
}

# ------------------------------------------    

symlinkBigwigsFlashSeparated(){
# ------------------------------------------

echo -n "- ${thisHubSubfolder} ${flashstatus} "
echo -n "- ${thisHubSubfolder} ${flashstatus} " >> "/dev/stderr"
mkdir ${folder}/${thisHubSubfolder}_${flashstatus}
cd ${folder}/${thisHubSubfolder}_${flashstatus}
ln -s ../../../${folder}/*/PERMANENT_BIGWIGS_do_not_move/${thisHubSubfolder}/${flashstatus}*.bw .
cd ${weWereHereDir}

# ------------------------------------------    
}

# ------------------------------------------    

prepareIndexforJavascript(){
# ------------------------------------------

# copies the javascripts, 
# , and adds to the <head> the subroutines to draw the inline pie charts and bar graphs

cp -r ${CaptureParallelPath}/javascriptHelpers .
chmod -R a+x javascriptHelpers

echo ''                                                                                             >> index.html
echo '<!--   ------------------------------------------------------------------------------------------------------------------------------           -->' >> index.html
echo '<!--   This code is based on example code taken (04Oct2018) from : https://omnipotent.net/jquery.sparkline/#s-docs                              -->' >> index.html
echo '<!--   Thie original example code is available in :  javascriptHelpers/example.html                                                             -->' >> index.html
echo '<!--   jquery is MIT licensed and jquery.sparkline is BSD-3-Clause licensed. They both can be added to GPL3 licensed codes such as CCseqBasicM. -->' >> index.html
echo '<!--   jquery (C) the jquery foundation : http://jquery.com . Code available (also in) GitHub : https://github.com/jquery/jquery                -->' >> index.html
echo '<!--   jquery.sparkline (C) Gareth Watts, Splunk Inc. Code available (also in) GitHub : https://github.com/gwatts/jquery.sparkline              -->' >> index.html
echo '<!--   ------------------------------------------------------------------------------------------------------------------------------           -->' >> index.html
echo ''                                                                                             >> index.html
echo '<!--   All available finetuning flags for the sparklines are available here : https://omnipotent.net/jquery.sparkline/assets/index.js           -->' >> index.html
echo ''                                                                                             >> index.html
echo '<!--   ------------------------------------------------------------------------------------------------------------------------------           -->' >> index.html
echo ''                                                                                             >> index.html
echo '    <script type="text/javascript" src="javascriptHelpers/jquery-3.2.1.min.js"></script>'     >> index.html
echo '    <script type="text/javascript" src="javascriptHelpers/jquery.sparkline.min.js"></script>' >> index.html
echo ''                                                                                             >> index.html

# The functions to bring the stuff alive ..
echo '    <script type="text/javascript">'                                       >> index.html
echo '    $(function() {'                                                        >> index.html
echo ''                                                                          >> index.html        
echo '        /** This code runs when everything has been loaded on the page */' >> index.html
echo '        /* Use 'html' instead of an array of values to pass options '      >> index.html
echo '        to a sparkline with data in the tag */'                            >> index.html
echo ''        
echo '        $'"('.bluebar').sparkline('html', {type: 'bar', barColor: 'blue', height: '100', barWidth: '20', chartRangeMin: '0' } );"       >> index.html
echo '        $'"('.orangebar').sparkline('html', {type: 'bar', barColor: 'orange', height: '100', barWidth: '20', chartRangeMin: '0' } );"   >> index.html
echo '        $'"('.blueorangepie').sparkline('html', {type: 'pie', sliceColors: ['blue','orange'], height: '100', width: '100' } );"         >> index.html
echo '        $'"('.bluesilverpie').sparkline('html', {type: 'pie', sliceColors: ['blue','lightsteelblue'], height: '100', width: '100' } );" >> index.html
echo '        $'"('.orangesilverpie').sparkline('html', {type: 'pie', sliceColors: ['orange','wheat'], height: '100', width: '100' } );"      >> index.html
echo '        $'"('.orangebrownpie').sparkline('html', {type: 'pie', sliceColors: ['peru','orange'], height: '100', width: '100' } );"        >> index.html
echo '        $'"('.bluesilverwhitepie').sparkline('html', {type: 'pie', sliceColors: ['blue','lightsteelblue','azure'], height: '100', width: '100', borderColor: 'steelblue', borderWidth: '1' } );" >> index.html
echo '        $'"('.orangesilverwhitepie').sparkline('html', {type: 'pie', sliceColors: ['orange','wheat','ivory'], height: '100', width: '100', borderColor: 'goldenrod', borderWidth: '1' } );"      >> index.html
echo '        $'"('.boxplotprecalculated').sparkline('html', {type:'box', raw: true, showOutliers:false, height: '70', width: '500', target: '30000'});"           >> index.html

echo '    });'                                                                   >> index.html
echo '    </script>'                                                             >> index.html
echo ''                                                                          >> index.html

}

# ------------------------------------------    

testStatsWithJavascriptToIndex(){
# Add to the index.html - the main stats with javascript inline figures ..

echo '<hr />' >> index.html
echo '<h2>THE BELOW IS EXAMPLE DATA (for testing the visualisations) </h2> - see the above text file of statistics for REAL values of your experiment !' >> index.html
echo '<hr />' >> index.html

echo '' >> index.html
echo '<p>' >> index.html
echo 'Flashing' >> index.html
echo '<span class="blueorangepie">1,3</span>  ' >> index.html                                       
echo '</p>' >> index.html
echo '' >> index.html
echo '<p>' >> index.html
echo 'In-silico RE-digestion' >> index.html
echo '<span class="bluesilverpie">1,3</span> <span class="orangebrownpie">1,3</span>' >> index.html
echo '</p>' >> index.html
echo '' >> index.html
echo '<p>' >> index.html
echo 'Mapping' >> index.html
echo '<span class="bluesilverwhitepie">1,3,4</span> <span class="orangesilverwhitepie">1,3,4</span>' >> index.html
echo '</p>' >> index.html
echo '' >> index.html
echo '<p>' >> index.html
echo 'FLASHED Pre-filtering (mapped, multifrag, hascap, singlecap, sonicSize)' >> index.html
echo '<span class="bluebar">1,3,4,5,3,5</span>   ' >> index.html                           
echo '</p>' >> index.html
echo '' >> index.html
echo '<p>' >> index.html
echo 'NONFLASHED Pre-filtering (mapped, multifrag, hascap, singlecap, sonicSize)' >> index.html
echo '<span class="orangebar">1,3,4,5,3,5</span>' >> index.html
echo '</p>' >> index.html
echo '' >> index.html
echo '<p>' >> index.html
echo 'Duplicates' >> index.html
echo '<span class="bluesilverpie">1,3</span> <span class="orangesilverpie">1,3</span>      ' >> index.html        
echo '</p>' >> index.html
echo '' >> index.html
echo '<p>' >> index.html
echo 'Cis/trans reporters' >> index.html
echo '<span class="bluesilverpie">1,3</span> <span class="orangesilverpie">1,3</span>   ' >> index.html           
echo '</p>' >> index.html
echo '' >> index.html

    
# ------------------------------------------    
}


# ------------------------------------------    

addStatsWithJavascriptToIndex(){
# Add to the index.html - the main stats with javascript inline figures ..

# -----------------------
# Flashing counts ..

echo '<hr />' >> index.html
echo '<h3>Flashing counts (read PAIRS) </h3>' >> index.html
echo '<pre>' >> index.html
cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/flashing.log >> index.html
echo '</pre>' >> index.html

  fcountIN=$(($(cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/flashing.log | grep 'Combined'   | sed 's/.*\s//')))
 nfcountIN=$(($(cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/flashing.log | grep 'Uncombined' | sed 's/.*\s//')))

echo '<p>' >> index.html
echo '<span class="blueorangepie">'${fcountIN}','${nfcountIN}'</span>  ' >> index.html                                       
echo '</p>' >> index.html
echo '' >> index.html

echo '<b style="color:blue">' >> index.html
echo 'FLASHED ' >> index.html
echo '</b>' >> index.html
echo '<b style="color:orange">' >> index.html
echo 'NONFLASHED ' >> index.html
echo '</b>' >> index.html
echo '</br>(hover over to see the counts)' >> index.html

# -----------------------
# RE digest counts ..

echo '<hr />' >> index.html
echo '<h3>In-silico RE digestion counts :</h3>' >> index.html

flashstatus="FLASHED"
echo '<h4>'${flashstatus}_${REenzyme}'digestion.log</h4>' >> index.html
echo '<pre style="color:blue">' >> index.html
cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/${flashstatus}_${REenzyme}digestion.log >> index.html
echo '</pre>' >> index.html


flashstatus="NONFLASHED"
echo '<h4>'${flashstatus}_${REenzyme}'digestion.log</h4>' >> index.html
echo '<pre style="color:orange">' >> index.html
cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/${flashstatus}_${REenzyme}digestion.log >> index.html
echo '</pre>' >> index.html

  fcountIN=$(($(cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/FLASHED_${REenzyme}digestion.log    | grep 'fragments was found'    | sed 's/\s.*//')))
 nfcountIN=$(($(cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/NONFLASHED_${REenzyme}digestion.log | grep 'fragments was found'    | sed 's/\s.*//')))
 fcountOUT=$(($(cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/FLASHED_${REenzyme}digestion.log    | grep 'fragments were printed' | sed 's/\s.*//')))
nfcountOUT=$(($(cat ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/NONFLASHED_${REenzyme}digestion.log | grep 'fragments were printed' | sed 's/\s.*//')))

echo '<p>' >> index.html
echo '<span class="bluesilverpie">'${fcountIN}','${fcountOUT}'</span> <span class="orangesilverpie">'${nfcountIN}'',${nfcountOUT}'</span>' >> index.html
echo '</p>' >> index.html
echo '' >> index.html

echo '<b style="color:blue">' >> index.html
echo 'FLASHED ' >> index.html
echo '</b>' >> index.html
echo '(BLUE fragments continue to mapping, light-blue fragments - too short or no RE cut - filtered at this stage)' >> index.html
echo '<br/><b style="color:orange">' >> index.html
echo 'NONFLASHED ' >> index.html
echo '</b>' >> index.html
echo '(ORANGE fragments continue to mapping, light-orange fragments - too short -  filtered at this stage)' >> index.html

# -----------------------
# Reads entering mapping ..

echo '<hr />' >> index.html
echo '<h3>Fragments entering mapping </h3>' >> index.html

echo '<p>' >> index.html
echo '<span class="blueorangepie">'${fcountOUT}','${nfcountOUT}'</span>  ' >> index.html                                       
echo '</p>' >> index.html
echo '' >> index.html

echo '<b style="color:blue">' >> index.html
echo 'FLASHED ' >> index.html
echo '</b>' >> index.html
echo '<b style="color:orange">' >> index.html
echo 'NONFLASHED ' >> index.html
echo '</b>' >> index.html
echo '</br>(hover over to see the counts)' >> index.html

# -----------------------
# Mapping counts ..

echo '<hr />' >> index.html
echo '<h3>Mapping counts :</h3>' >> index.html

echo '<h4>Reads entering mapping</h4>' >> index.html
echo '<pre>' >> index.html
head ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/*FLASHEDreadsEnteringBowtie_readcount.txt | sed 's/\/.*\///' >> index.html
echo '</pre>' >> index.html

echo '<h4>Mapping percentages</h4>' >> index.html
echo '<pre>' >> index.html
head ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/*FLASHED_bowtiePerc.txt | sed 's/\/.*\///' >> index.html
echo '</pre>' >> index.html

  fcountIN=$(tail -n 1 ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/FLASHED_bowtiePerc.txt    | tr '\t' ',')
 nfcountIN=$(tail -n 1 ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/NONFLASHED_bowtiePerc.txt | tr '\t' ',')

echo '<p>' >> index.html
echo '<span class="bluesilverwhitepie">'${fcountIN}'</span> <span class="orangesilverwhitepie">'${nfcountIN}'</span>' >> index.html
echo '</p>' >> index.html
echo '' >> index.html

echo '<b style="color:blue">' >> index.html
echo 'FLASHED ' >> index.html
echo '</b>' >> index.html
head -n 1 ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/FLASHED_bowtiePerc.txt | sed 's/^/BLUE=/' | sed 's/\s/,SILVER=/' | sed 's/\s/,WHITE=/' | sed 's/,/, /g' >> index.html
echo '<br/><b style="color:orange">' >> index.html
echo 'NONFLASHED ' >> index.html
echo '</b>' >> index.html
head -n 1 ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/FLASHED_bowtiePerc.txt | sed 's/^/ORANGE=/' | sed 's/\s/,lightORANGE=/' | sed 's/\s/,WHITE=/' | sed 's/,/, /g' >> index.html

# -----------------------
# Pre-filtering counts ..

echo '<hr />' >> index.html
echo '<h3>Pre-filtering counts (before CCanalysers) :</h3>' >> index.html

echo '<h4>Read counts</h4>' >> index.html
echo '<pre>' >> index.html
head ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/*FLASHED_summaryCounts.txt | sed 's/\/.*\///' >> index.html
echo '</pre>' >> index.html

echo '<h4>Read percentages</h4>' >> index.html
echo '<pre>' >> index.html
head ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/*FLASHED_summaryPerc.txt | sed 's/\/.*\///' >> index.html
echo '</pre>' >> index.html

  fcountIN=$(tail -n 1 ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/FLASHED_summaryCounts.txt    | tr '\t' ',')
 nfcountIN=$(tail -n 1 ${rainbowRunTOPDIR}/B_mapAndDivideFastqs/NONFLASHED_summaryCounts.txt | tr '\t' ',')

echo '<p style="color:blue">' >> index.html
echo 'FLASHED pre-filtering' >> index.html
echo '<span style="color:black"></br>(hover over to see the counts)</span>' >> index.html
echo '<br/><span class="bluebar">'${fcountIN}'</span>   ' >> index.html                           
echo '<br/> mappedR, multifragR, hascapR, singlecapF, withinSonicSizeF' >> index.html
echo '</p>' >> index.html
echo '' >> index.html
echo '<p style="color:orange">' >> index.html
echo 'NONFLASHED pre-filtering' >> index.html
echo '<span style="color:black"></br>(hover over to see the counts)</span>' >> index.html
echo '<br/><span class="orangebar">'${nfcountIN}'</span>' >> index.html
echo '<br/> mappedR, multifragR, hascapR, singlecapF, withinSonicSizeF' >> index.html
echo '</p>' >> index.html
echo '' >> index.html

capSiteName="capture site"
if [ "${tiled}" -eq 1 ]; then
    capSiteName="tile"
fi

echo '<pre>' >> index.html
echo 'Abbreviations :' >> index.html
echo '' >> index.html
echo '         mappedR = mapped reads' >> index.html
echo '      multifragR = reads with more than 1 fragment (can potentially report interaction)' >> index.html
echo '         hascapR = reads containing fragment(s) overlapping any of the '${capSiteName}'s (within +/- sonicationSize from RE cut sites)' >> index.html
echo '      singlecapF = fragment count in reads which can be resolved to a single '${capSiteName}' (not reporting multiple different '${capSiteName}'s within same read)' >> index.html
echo 'withinSonicSizeF = fragments within +/- sonicationSize from RE cut sites (filters out mapping errors)' >> index.html
echo '</pre>' >> index.html
echo '' >> index.html


echo '</pre>' >> index.html

# -----------------------
# CCanalyser counters ..

echo '<hr />' >> index.html
echo '<h3>CCanalyser runs (duplicate filtering, final counts) :</h3>' >> index.html

echo '<pre>' >> index.html
head -n 20 ${rainbowRunTOPDIR}/D_analyseOligoWise/*FLASHED_percentagesAndFinalCounts.txt | sed 's/\/.*\///' >> index.html
echo '</pre>' >> index.html

  fcountIN=$(head -n 2 ${rainbowRunTOPDIR}/D_analyseOligoWise/FLASHED_percentagesAndFinalCounts.txt    | tail -n 1)
 nfcountIN=$(head -n 2 ${rainbowRunTOPDIR}/D_analyseOligoWise/NONFLASHED_percentagesAndFinalCounts.txt | tail -n 1)
 fcountOUT=$(echo ${fcountIN}  | awk '{print 100.0-$1}')
nfcountOUT=$(echo ${nfcountIN} | awk '{print 100.0-$1}')

 echo '<h4>Duplicates</h4>' >> index.html
echo '<p>' >> index.html
echo '<span class="bluesilverpie">'${fcountOUT}','${fcountIN}'</span> <span class="orangesilverpie">'${nfcountOUT}','${nfcountIN}'</span>      ' >> index.html        
echo '</p>' >> index.html
echo '' >> index.html

echo '<b style="color:blue">' >> index.html
echo 'FLASHED ' >> index.html
echo '</b>' >> index.html
echo 'BLUE reads continue, light-blue reads are duplicates (filtered at this stage)' >> index.html
echo '<br/><b style="color:orange">' >> index.html
echo 'NONFLASHED ' >> index.html
echo '</b>' >> index.html
echo 'ORANGE reads continue, light-orange reads are duplicates (filtered at this stage)' >> index.html

# if [ "${tiled}" -ne 0 ]; then

  fcountIN=$(cat ${rainbowRunTOPDIR}/D_analyseOligoWise/FLASHED_percentagesAndFinalCounts.txt    | grep -v '^\s*$' | tail -n 1 | cut -f 4,5 | sed 's/\t/,/')
 nfcountIN=$(cat ${rainbowRunTOPDIR}/D_analyseOligoWise/NONFLASHED_percentagesAndFinalCounts.txt | grep -v '^\s*$' | tail -n 1 | cut -f 4,5 | sed 's/\t/,/')

echo '<h4>Cis/trans reporters</h4>' >> index.html
if [ "${tiled}" -eq 1 ]; then
    echo '( tiled reporters = all fragments - except exclusion zone fragments - within reads where at least one frag within the tile )' >> index.html
fi
echo '<p>' >> index.html
echo '<span class="bluesilverpie">'${fcountIN}'</span> <span class="orangesilverpie">'${nfcountIN}'</span>   ' >> index.html           
echo '</p>' >> index.html
echo '' >> index.html
echo '<b style="color:blue">' >> index.html
echo 'FLASHED ' >> index.html
echo '</b>' >> index.html
echo '<b style="color:orange">' >> index.html
echo 'NONFLASHED ' >> index.html
echo '</b>' >> index.html
echo '</br>DARK color : cis reporters. LIGHT color : trans reporters.' >> index.html

# fi

echo '</br>(hover over to see the counts)' >> index.html

# -----------------------
# Quantile ranges ..

echo '<hr />' >> index.html
echo '<h3>CCanalyser runs (duplicate filtering, final counts) :</h3>' >> index.html

if [ "${tiled}" -eq 1 ]; then
    echo '( tiled reporters = all fragments - except exclusion zone fragments - within reads where at least one frag within the tile )' >> index.html
fi

echo '<pre>' >> index.html
cat ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt >> index.html
echo '</pre>' >> index.html

oligoStringName="oligo"
if [ "${tiled}" -eq 1 ]; then
    oligoStringName="tile"
fi

# if [ "${tiled}" -ne 0 ]; then

countIN=$(head -n 2 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | tail -n 1 | sed 's/.*max of:\s*//' | tr '\t' ',')
echo '<h4>Reported fragments (total), '${oligoStringName}'-wise distribution</h4>' >> index.html
echo '(hover over to see the counts)' >> index.html
echo '<p>' >> index.html
echo '<span class="boxplotprecalculated">'${countIN}'</span> ' >> index.html           
echo '</p>' >> index.html
echo '<pre>' >> index.html
tail -n 3 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | head -n 1 | sed 's/and\s/<br>/' | sed 's/max of:\s/max<br>/' >> index.html
echo '</pre>' >> index.html
echo '' >> index.html

countIN=$(head -n 3 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | tail -n 1 | sed 's/.*max of:\s*//' | tr '\t' ',')
echo '<h4>Reported fragments ( CIS ), '${oligoStringName}'-wise distribution</h4>' >> index.html
echo '(hover over to see the counts)' >> index.html
echo '<p>' >> index.html
echo '<span class="boxplotprecalculated">'${countIN}'</span> ' >> index.html           
echo '</p>' >> index.html
echo '<pre>' >> index.html
tail -n 2 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | head -n 1 | sed 's/and\s/<br>/' | sed 's/max of:\s/max<br>/' >> index.html
echo '</pre>' >> index.html
echo '' >> index.html

countIN=$(tail -n 1 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | sed 's/.*max of:\s*//' | tr '\t' ',')
echo '<h4>Reported fragments ( TRANS ), '${oligoStringName}'-wise distribution</h4>' >> index.html
echo '(hover over to see the counts)' >> index.html
echo '<p>' >> index.html
echo '<span class="boxplotprecalculated">'${countIN}'</span> ' >> index.html           
echo '</p>' >> index.html
echo '<pre>' >> index.html
tail -n 1 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | sed 's/and\s/<br>/' | sed 's/max of:\s/max<br>/' >> index.html
echo '</pre>' >> index.html
echo '' >> index.html

# fi

if [ "${tiled}" -eq 0 ]; then

countIN=$(head -n 1 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | sed 's/.*max of:\s*//' | tr '\t' ',')

echo '<h4>Capture fragments in reported reads (intra-read duplicates not filtered yet in these counts), distribution over all capture sites</h4>' >> index.html
echo '(hover over to see the counts)' >> index.html
echo '<p>' >> index.html
echo '<span class="boxplotprecalculated">'${countIN}'</span> ' >> index.html           
echo '</p>' >> index.html
echo '<pre>' >> index.html
head -n 1 ${rainbowRunTOPDIR}/D_analyseOligoWise/COMBINED_meanStdMedian_overOligos.txt | sed 's/and\s/<br>/' | sed 's/max of:\s/max<br>/' >> index.html
echo '</pre>' >> index.html
echo '' >> index.html

fi

# -----------------------
# Some emptylines ..

echo '</br>' >> index.html
echo '</br>' >> index.html
echo '<hr />' >> index.html
echo '</br>' >> index.html
echo '</br>' >> index.html
    
# ------------------------------------------    
}

# ------------------------------------------    
makeAllTheHubs(){
# ------------------------------------------    

echo "cisTypeSuffix '${cisTypeSuffix}'"

thisIsFirstRound=1
for folder in ${listOfChromosomes}
do
{
pwd
echo -en "${folder}\t"
echo -en "${folder}\t" >> "/dev/stderr"

thisHubSubfolder="COMBINED"
bigwigPrefix="COMBINED"

# only first time around we print parent for cis tracks (to become the combined hub)
# In any case the parent of cis tracks will have shorter name (no chr in name)
parentOrNot=""
if [ "${cisTypeSuffix}" != "" ]; then
    if [ "${thisIsFirstRound}" -ne 1 ] ; then
        parentOrNot="noparent"
    else
        parentOrNot="wholegenparent"
    fi
fi
thisIsFirstRound=0

# Setting suffix (or any of these flags) to 'none' turns it off, i.e. sets it to ""
if [ "${cisTypeSuffix}" == "" ]; then bigwigSuffix="none"; else bigwigSuffix="${cisTypeSuffix}";fi
trackAbbrev="COMB"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "full" ${CCversion} ${parentOrNot}
bigwigSuffix="_normTo10k${cisTypeSuffix}"
trackAbbrev="COMBnorm"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "full" ${CCversion} ${parentOrNot}
bigwigSuffix="_CIS_normTo10k${cisTypeSuffix}"
trackAbbrev="COMBnormCIS"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "full" ${CCversion} ${parentOrNot}

flashstatus="FLASHED"
bigwigPrefix="FLASHED_REdig"
if [ "${cisTypeSuffix}" == "" ]; then bigwigSuffix="none"; else bigwigSuffix="${cisTypeSuffix}";fi
trackAbbrev="filtF"
thisHubSubfolder="FILTERED_${flashstatus}"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "hide" ${CCversion} ${parentOrNot}
trackAbbrev="prefiltF"
thisHubSubfolder="PREfiltered_${flashstatus}"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "hide" ${CCversion} ${parentOrNot}
trackAbbrev="rawF"
thisHubSubfolder="RAW_${flashstatus}"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "hide" ${CCversion} ${parentOrNot}

flashstatus="NONFLASHED"
bigwigPrefix="NONFLASHED_REdig"
if [ "${cisTypeSuffix}" == "" ]; then bigwigSuffix="none"; else bigwigSuffix="${cisTypeSuffix}";fi
trackAbbrev="filtNF"
thisHubSubfolder="FILTERED_${flashstatus}"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "hide" ${CCversion} ${parentOrNot}
trackAbbrev="prefiltNF"
thisHubSubfolder="PREfiltered_${flashstatus}"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "hide" ${CCversion} ${parentOrNot}
trackAbbrev="rawNF"
thisHubSubfolder="RAW_${flashstatus}"
${CaptureParallelPath}/makeRainbowTracks.sh ${folder} ${thisHubSubfolder} ${bigwigPrefix} ${bigwigSuffix} ${trackAbbrev} "hide" ${CCversion} ${parentOrNot}

rm -rf ${folder}/makingOfTracks${cisTypeSuffix}
mkdir ${folder}/makingOfTracks${cisTypeSuffix}
mv ${folder}_*_tracks.txt ${folder}/makingOfTracks${cisTypeSuffix}/.
cat ${folder}/makingOfTracks${cisTypeSuffix}/* > ${folder}${cisTypeSuffix}_tracks.txt

if [ "${cisTypeSuffix}" == "" ]; then

echo -n "- hubAndGenome "
echo -n "- hubAndGenome " >> "/dev/stderr"
${CaptureParallelPath}/makeRainbowHubs.sh ${samplename} ${folder}${cisTypeSuffix} ${ucscBuildName}
    
fi

echo ''
echo '' >> "/dev/stderr"

}
done

if [ "${cisTypeSuffix}" != "" ]; then
    rm -rf makingOfCisTracks
    mkdir makingOfCisTracks
    mv chr*${cisTypeSuffix}_tracks.txt makingOfCisTracks/.
    cat makingOfCisTracks/chr*${cisTypeSuffix}_tracks.txt > wholegenome${cisTypeSuffix}_tracks.txt
    
    ${CaptureParallelPath}/makeRainbowHubs.sh ${samplename} wholegenome${cisTypeSuffix} ${ucscBuildName}
    
    
fi

# ------------------------------------------    
}

# ------------------------------------------    

generateDataHub(){
# ------------------------------------------

printThis="This is subroutine generateDataHub .."
printToLogFile

# This needs access to UCSC genome sizes, as well as UCSCtools tool locations ..

echo
echo "confFolder ${confFolder}"
echo

supportedGenomes=()
UCSC=()

setPathsForPipe
setGenomeLocations

GENOME="UNDEFINDED"
GENOME=${inputgenomename}
echo "GENOME ${GENOME}"

# If the visualisation genome name differs from the asked genome name : masked genomes
setUCSCgenomeName
# Visualisation genome sizes file
setUCSCgenomeSizes

echo "ucscBuildName ${ucscBuildName}"
echo "ucscBuild ${ucscBuild}"

# --------------------------------------

listOfChromosomes=$( ls A_prepareForRun/OLIGOSindividualFiles )
checkThis="${listOfChromosomes}"
checkedName='${listOfChromosomes}'
checkParse

cd D_analyseOligoWise

rm -rf data_hubs
mkdir data_hubs
cd data_hubs

hubTopDir=$(pwd)

printThis="Making description html page .."
printToLogFile

echo '<h2>Run '${samplename}/${CCversion}_${REenzyme}' </h2>' > description.html
echo '<p><h3>' >> description.html
echo 'Summary statistics available in this page : </br>' >> description.html
echo '<a target=_blank href="http://userweb.molbiol.ox.ac.uk/'${publicfolder}/${samplename}/${CCversion}_${REenzyme}'/data_hubs/index.html" >( '${samplename}/${CCversion}_${REenzyme}' statistics page )</a>' >> description.html
echo '</h3></p>' >> description.html
echo '<hr />' >> description.html


echo "<!DOCTYPE HTML PUBLIC -//W3C//DTD HTML 4.01//EN" > index.html
echo "http://www.w3.org/TR/html4/strict.dtd" >> index.html
echo ">" >> index.html
echo " <html lang=en>" >> index.html
echo " <head>" >> index.html
echo " <title> ${hubNameList[0]} data hub in ${GENOME} </title>" >> index.html

prepareIndexforJavascript
# copies the javascripts, 
# , and adds to the <head> the subroutines to draw the inline pie charts and bar graphs

echo " </head>" >> index.html
echo " <body>" >> index.html

# Generating TimeStamp 
TimeStamp=($( date | sed 's/[: ]/_/g' ))
DateTime="$(date)"

echo "<p>Data produced ${DateTime} with CapC pipeline (coded by James Davies, pipelined and parallelised by Jelena Telenius, located in ${MainScriptPath} )</p>" >> index.html

echo "<hr />" >> index.html
echo "Restriction enzyme and genome build : ( ${REenzyme} ) ( ${inputgenomename} )" >> index.html
echo "<hr />" >> index.html
echo "Data located in : ${HOME}" >> index.html
echo "<hr />" >> index.html

ln -s ../../E_hubAddresses.txt .

echo "All data hubs : <br>" >> index.html
echo "<a target="_blank" href=\"E_hubAddresses.txt\" >E_hubAddresses.txt</a>" >> index.html
echo "<hr />" >> index.html

mkdir description_page_files

ln -s ../../COMBINED_allFinalCounts.txt description_page_files/.
ln -s ../../COMBINED_allFinalCounts_table.txt description_page_files/.
ln -s ../../../B_mapAndDivideFastqs/multiqcReports description_page_files/.

echo 'Oligo-wise counts (table) : <br>' >> index.html
echo '<a target="_blank" href="description_page_files/COMBINED_allFinalCounts_table.txt" >COMBINED_allFinalCounts_table.txt</a>' >> index.html
echo '<hr />' >> index.html
echo 'Oligo-wise counts (raw list) : <br>' >> index.html
echo '<a target="_blank" href="description_page_files/COMBINED_allFinalCounts.txt" >COMBINED_allFinalCounts.txt</a>' >> index.html
echo '<hr />' >> index.html
echo 'Run output log (main log) : <br>' >> index.html
echo '<a target="_blank" href="../qsub.out" >qsub.out</a>' >> index.html
echo '<hr />' >> index.html
echo 'Run error log (main log) : <br>' >> index.html
echo '<a target="_blank" href="../qsub.err" >qsub.err</a>' >> index.html
echo '<hr />' >> index.html
echo '<h4>FastQC reports along the run :</h4>' >> index.html
echo '<ol>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/READ1_unmodified/multiqc_report.html" >ummodified READ1</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/READ2_unmodified/multiqc_report.html" >unmodified READ2</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/READ1_trimmed/multiqc_report.html" >adaptor-trimmed READ1</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/READ2_trimmed/multiqc_report.html" >adaptor-trimmed READ2</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/FLASHED/multiqc_report.html" >FLASHED reads</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/NONFLASHED/multiqc_report.html" >NONFLASHED reads</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/FLASHED_REdig/multiqc_report.html" >FLASHED reads, RE-digested</a></li>' >> index.html
echo '<li><a target="_blank" href="description_page_files/multiqcReports/NONFLASHED_REdig/multiqc_report.html" >NONFLASHED_reads, RE-digested</a></li>' >> index.html
echo '</ol>' >> index.html
echo '<hr />' >> index.html

echo > description_page_files/statslisting.txt
echo 'The statistics below are for the WHOLE experiment - over all chromosomes' >> description_page_files/statslisting.txt
echo '' >> description_page_files/statslisting.txt
cat ../../B_fastqSummaryCounts.txt >> description_page_files/statslisting.txt
echo  >> description_page_files/statslisting.txt
echo  >> description_page_files/statslisting.txt
cat ../../D_analysisSummaryCounts.txt >> description_page_files/statslisting.txt
echo  >> description_page_files/statslisting.txt
echo  >> description_page_files/statslisting.txt

echo 'Text file of the main statistics : <br>' >> index.html
echo '<a target="_blank" href="description_page_files/statslisting.txt" >statslisting.txt</a>' >> index.html
echo '<hr />' >> index.html

# Test the javascript functions ..
# testStatsWithJavascriptToIndex
# (uncomment the above, if the javascript functions need to be debugged for some reason)

# Add to the index.html - the main stats with javascript inline figures ..
addStatsWithJavascriptToIndex

# ----------------------------------

printThis="Raw mapped reads bigwigs and hub .."
printToLogFile

mkdir rawMappedReads
weWereHereDir=$(pwd)
cd rawMappedReads

for folder in ../../../B_mapAndDivideFastqs/fastq_*
do
    fastqName=$(basename ${folder})
    ln -s ${folder}/F1_beforeCCanalyser_${samplename}_${CCversion}/FLASHED_REdig_unfiltered.bw ${fastqName}_FLASHED_REdig_unfiltered.bw
    ln -s ${folder}/F1_beforeCCanalyser_${samplename}_${CCversion}/NONFLASHED_REdig_unfiltered.bw ${fastqName}_NONFLASHED_REdig_unfiltered.bw
done

cd ${weWereHereDir}

thisHubSubfolder="rawMappedReads"
echo -en "${thisHubSubfolder}\t"
echo -en "${thisHubSubfolder}\t" >> "/dev/stderr"
bigwigSuffix="_FLASHED_REdig_unfiltered"
trackAbbrev="rawSam_FLASHED"
${CaptureParallelPath}/makeRawsamTracks.sh ${thisHubSubfolder} ${bigwigSuffix} ${trackAbbrev} "full"
bigwigSuffix="_NONFLASHED_REdig_unfiltered"
trackAbbrev="rawSam_NONFLASHED"
${CaptureParallelPath}/makeRawsamTracks.sh ${thisHubSubfolder} ${bigwigSuffix} ${trackAbbrev} "full" "noparent"

# combining these to the final tracks.txt

cat rawSam_FLASHED_tracks.txt rawSam_NONFLASHED_tracks.txt > ${thisHubSubfolder}_tracks.txt
mkdir ${thisHubSubfolder}/makingOfTracks
mv rawSam_FLASHED_tracks.txt ${thisHubSubfolder}/makingOfTracks/.
mv rawSam_NONFLASHED_tracks.txt ${thisHubSubfolder}/makingOfTracks/.

echo -n "- hubAndGenome "
echo -n "- hubAndGenome " >> "/dev/stderr"
${CaptureParallelPath}/makeRainbowHubs.sh ${samplename} ${thisHubSubfolder} ${ucscBuildName}
   
# ----------------------------------

printThis="Making folders for each chromosome .."
printToLogFile

mkdir ${listOfChromosomes}

printThis="Symlinks to bigwig files .."
printToLogFile

weWereHereDir=$(pwd)

for folder in ${listOfChromosomes}
do
{
echo -en "${folder}\t"
echo -en "${folder}\t" >> "/dev/stderr"
pwd

thisHubSubfolder="COMBINED"
echo -n "- ${thisHubSubfolder} "
echo -n "- ${thisHubSubfolder} " >> "/dev/stderr"
mkdir ${folder}/${thisHubSubfolder}
cd ${folder}/${thisHubSubfolder}
ln -s ../../../${folder}/*/PERMANENT_BIGWIGS_do_not_move/${thisHubSubfolder}/*.bw .
cd ${weWereHereDir}

thisHubSubfolder="FILTERED"
flashstatus="FLASHED"
symlinkBigwigsFlashSeparated
flashstatus="NONFLASHED"
symlinkBigwigsFlashSeparated

thisHubSubfolder="PREfiltered"
flashstatus="FLASHED"
symlinkBigwigsFlashSeparated
flashstatus="NONFLASHED"
symlinkBigwigsFlashSeparated

thisHubSubfolder="RAW"
flashstatus="FLASHED"
symlinkBigwigsFlashSeparated
flashstatus="NONFLASHED"
symlinkBigwigsFlashSeparated

echo ""
echo "" >> "/dev/stderr"

}
done

# ---------------------------------------

# Color key and tracks, hub, genomes ..

#------------------------------------------

# Now preparing for hub generation ..

cd ${hubTopDir}

cat ../../A_prepareForRun/OLIGOFILE/oligofile_sorted.txt | sort -k2,2 -k3,3n > oligofile_sorted.txt

# ------------------------

printThis="Color key generation : bed track for oligos and exclusions .."
printToLogFile

# making the key (excl and oligo added to the bed and last bigbed

rm -f oligoExclColored_allReps.bed


for folder in ${listOfChromosomes}
do
{
color=(); oligolist=(); olistrlist=(); olistplist=(); excstrlist=(); excstplist=()

oligoListSetter
echo -n "${#oligolist[@]} oligos found "
setRainbowColors
echo -n "using ${#color[@]} colors "

counter=1
for (( i=0; i<${#oligolist[@]}; i++ ))
do
doOneBedExclOligo
done
}
done

echo

# making bigbed ..

sort -k1,1 -k2,2n oligoExclColored_allReps.bed > oligoExclColored_allReps_sorted.bed
bedToBigBed -type=bed9 -tab oligoExclColored_allReps_sorted.bed ${ucscBuild} oligosAndExclusions_allReps.bb

# -----------------------------------------

printThis="Tracks, hub and genomes files .."
printToLogFile

weWereHereDir=$(pwd)

# -----------------------
# Master hub (whole genome hub) ..

printThis="Master hub (whole genome hub) .."
printToLogFile

cisTypeSuffix="_CISonly"
makeAllTheHubs


# -----------------------
# Chromosome-wise hubs ..

printThis="Chromosome-wise hubs .."
printToLogFile

cisTypeSuffix=""
makeAllTheHubs

# -----------------------

# Symlink to all hub files into public ..
cd ${hubTopDir}

if [ ! -d "${publicfolder}/${samplename}/${CCversion}_${REenzyme}" ];then
  mkdir -p ${publicfolder}/${samplename}/${CCversion}_${REenzyme}  
fi
cd  ${publicfolder}/${samplename}/${CCversion}_${REenzyme}/
rm -f data_hubs
ln -s ${hubTopDir} .

for file in  data_hubs/hub_chr*.txt         ; do echo 'http://userweb.molbiol.ox.ac.uk'$(fp $file); done > ${hubTopDir}/hubAddresses.txt
for file in  data_hubs/hub_raw*.txt         ; do echo 'http://userweb.molbiol.ox.ac.uk'$(fp $file); done > ${hubTopDir}/rawHubAddress.txt
for file in  data_hubs/hub_wholegenome*.txt ; do echo 'http://userweb.molbiol.ox.ac.uk'$(fp $file); done > ${hubTopDir}/allChrsHubAddress.txt
for file in  data_hubs/index.html           ; do echo 'http://userweb.molbiol.ox.ac.uk'$(fp $file); done > ${hubTopDir}/descriptionAddress.txt

trackDescriptionLine='track type=bigBed name="CaptureC_oligos" description="CaptureC_oligos" visibility="pack" itemRgb=On exonArrows=off bigDataUrl='
echo ${trackDescriptionLine}'http://userweb.molbiol.ox.ac.uk'$( fp data_hubs/oligosAndExclusions_allReps.bb) > ${hubTopDir}/hubColorKeyBigbed.txt

cd ${hubTopDir}

printThis="Hub addresses generated"
printToLogFile

echo
echo > E_hubAddresses.txt
echo "DATA HUB ADDRESSES"
echo "DATA HUB ADDRESSES" >> E_hubAddresses.txt

echo
echo >> E_hubAddresses.txt
echo "Color key (oligo and exclusion coordinates track) :"
echo "Color key (oligo and exclusion coordinates track) :" >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt
cat hubColorKeyBigbed.txt
cat hubColorKeyBigbed.txt >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt
echo "(load the above as UCSC custom track)"
echo "(load the above as UCSC custom track)" >> E_hubAddresses.txt

echo
echo >> E_hubAddresses.txt
echo
echo '_______________________________' >> E_hubAddresses.txt
echo '_______________________________'
echo >> E_hubAddresses.txt

echo "Combined data hub (all chromosomes) - the main hub for small designs ( upto ~ 200 oligos or so ) :"
echo "Combined data hub (all chromosomes) - the main hub for small designs ( upto ~ 200 oligos or so ) :" >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt

cat allChrsHubAddress.txt
cat allChrsHubAddress.txt >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt

echo "(for big design visualisation - use the chr-wise hubs below, to avoid crashing the UCSC browser)"
echo "(for big design visualisation - use the chr-wise hubs below, to avoid crashing the UCSC browser)" >> E_hubAddresses.txt

echo
echo >> E_hubAddresses.txt
echo
echo '_______________________________' >> E_hubAddresses.txt
echo '_______________________________'
echo >> E_hubAddresses.txt

echo "Description html page (also auto-loads with the data hubs) :"
echo "Description html page (also auto-loads with the data hubs) :" >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt

cat descriptionAddress.txt
cat descriptionAddress.txt >> E_hubAddresses.txt

echo
echo >> E_hubAddresses.txt
echo
echo '_______________________________' >> E_hubAddresses.txt
echo '_______________________________'
echo >> E_hubAddresses.txt

echo "Raw mapped Sam fragments -hub (for troubleshooting and QC of the analysis) :"
echo "Raw mapped Sam fragments -hub (for troubleshooting and QC of the analysis) :" >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt

cat rawHubAddress.txt
cat rawHubAddress.txt >> E_hubAddresses.txt

echo
echo >> E_hubAddresses.txt
echo
echo '_______________________________' >> E_hubAddresses.txt
echo '_______________________________'
echo >> E_hubAddresses.txt

echo "Chromosome-wise data hubs (for visualising larger than ~ 200 oligos designs) :"
echo "Chromosome-wise data hubs (for visualising larger than ~ 200 oligos designs) :" >> E_hubAddresses.txt
echo
echo >> E_hubAddresses.txt

cat hubAddresses.txt
cat hubAddresses.txt >> E_hubAddresses.txt

echo
echo >> E_hubAddresses.txt

mv -f E_hubAddresses.txt ${rainbowRunTOPDIR}/.

cdCommand='cd ${rainbowRunTOPDIR} where rainbowRunTOPDIR is '${rainbowRunTOPDIR}
cdToThis="${rainbowRunTOPDIR}"
checkCdSafety  
cd ${rainbowRunTOPDIR}

    
# ------------------------------------------        
}