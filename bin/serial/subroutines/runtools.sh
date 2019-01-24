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

# Here calling the after-bowtie-filtering subroutines ..

. ${CapturePipePath}/runtoolsAfterBowtieFilters.sh

################################################################
# Running capture-site (REfragment) list overlap to allowed digest sites dpnII generation

generateCapturesiteWhitelist(){
    
printThis="Preparing capture-site (REfragment) list overlap to allowed digest sites file for ${REenzyme} cut genome and capture-site (REfragment) file ${CapturesiteFile} .."
printToLogFile

rmCommand='rm -f genome_${REenzyme}_capturesite_overlap.bed'
rmThis="genome_${REenzyme}_capturesite_overlap.bed"
checkRemoveSafety
rm -f genome_${REenzyme}_capturesite_overlap.bed

# Capturesite file in bed format ..

cat ${CapturesiteFile} | cut -f 1-4 | awk '{print $2"\t"$3"\t"$4"\t"$1}'| sed 's/^/chr/' > capturesites.bed

testedFile="capturesites.bed"
doTempFileTesting

# List of chromosomes which have this capturesite ..
cut -f 1 capturesites.bed | uniq | sort -T $(pwd) | uniq > genome_${REenzyme}_capturesite_chromosomes.txt

# Plus/minus 300 bases to both directions are fine, rest is not. Using blacklist in subtracting ..

# ==> filea.bed <==
# chr1    1       20      kissa

# ==> fileb.bed <==
# chr1    2       19      koira

# [telenius@deva test]$ bedtools subtract -a filea.bed -b fileb.bed 
# chr1    1       2       kissa
# chr1    19      20      kissa

setStringentFailForTheFollowing
bedtools subtract -a capturesites.bed -b ${fullPathDpnBlacklist} > genome_${REenzyme}_capturesite_overlap.bed
stopStringentFailAfterTheAbove

testedFile="genome_${REenzyme}_capturesite_overlap.bed"
doTempFileTesting

fullPathCapturesiteWhitelist=$(pwd)"/genome_${REenzyme}_capturesite_overlap.bed"
fullPathCapturesiteWhitelistChromosomes=$(pwd)"/genome_${REenzyme}_capturesite_chromosomes.txt"

ls -lht

}

################################################################
# Running whole genome blacklist dpnII generation

generateReBlacklist(){
    
printThis="Preparing 'too far from RE cut sites' blacklist file for ${REenzyme} cut genome) .."
printToLogFile

rmCommand='rm -f genome_${REenzyme}_blacklist.bed'
rmThis="genome_${REenzyme}_blacklist.bed"
checkRemoveSafety
rm -f genome_${REenzyme}_blacklist.bed

# Plus/minus 300 bases to both directions
setStringentFailForTheFollowing
cat ${fullPathDpnGenome} | sed 's/:/\t/' | sed 's/-/\t/' | awk '{if(($3-$2)>(2*'${ampliconSize}')){print "chr"$1"\t"$2+'${ampliconSize}'"\t"$3-'${ampliconSize}'}}' > genome_${REenzyme}_blacklist.bed
stopStringentFailAfterTheAbove

testedFile="genome_${REenzyme}_blacklist.bed"
doTempFileTesting

doQuotaTesting

fullPathDpnBlacklist=$(pwd)"/genome_${REenzyme}_blacklist.bed"

ls -lht

}

generateReDigest(){

################################################################
# Running whole genome fasta dpnII digestion..

rmCommand='rm -f genome_${REenzyme}_coordinates.txt'
rmThis="genome_${REenzyme}_coordinates.txt"
checkRemoveSafety
rm -f genome_${REenzyme}_coordinates.txt

if [ -s ${CaptureDigestPath}/${ucscBuildName}.txt ] 
then
    
ln -s ${CaptureDigestPath}/${ucscBuildName}.txt genome_${REenzyme}_coordinates.txt
    
else
    
    
# Running the digestion ..
# dpnIIcutGenome.pl
# nlaIIIcutGenome.pl   

printThis="Running whole genome fasta ${REenzyme} digestion.."
printToLogFile

printThis="perl ${RunScriptsPath}/${REenzyme}cutGenome4.pl ${GenomeFasta}"
printToLogFile

setStringentFailForTheFollowing
perl ${RunScriptsPath}/${REenzyme}cutGenome4.pl "${GenomeFasta}"
stopStringentFailAfterTheAbove

testedFile="genome_${REenzyme}_coordinates.txt"
doTempFileTesting

doQuotaTesting

fi

dpnGenomeName=$( echo "${GenomeFasta}" | sed 's/.*\///' | sed 's/\..*//' )
# output file :
# ${GenomeFasta}_dpnII_coordinates.txt

fullPathDpnGenome=$(pwd)"/genome_${REenzyme}_coordinates.txt"

}

runFlash(){
    
if [[ ${FLASH} -eq "1" ]]; then
    
    echo
    echo "Running flash with parameters :"
    echo " m (minimum overlap) : ${flashOverlap}"
    echo " x (sum-of-mismatches/overlap-lenght) : ${flashErrorTolerance}"
    echo " p phred score min (33 or 64) : ${intQuals}"
    echo
    printThis="flash --interleaved-output -p ${intQuals} -m ${flashOverlap} -x ${flashErrorTolerance} READ1.fastq READ2.fastq > flashing.log"
    printToLogFile
    
    # flash --interleaved-output -p "${intQuals}" READ1.fastq READ2.fastq > flashing.log
    setStringentFailForTheFollowing
    flash --interleaved-output -p "${intQuals}" -m "${flashOverlap}" -x "${flashErrorTolerance}" READ1.fastq READ2.fastq > flashing.log 2> flashing.err
    stopStringentFailAfterTheAbove
    
    # This outputs these files :
    # flashing.log  FLASHED.fastq  out.hist  out.histogram  NONFLASHED.fastq  i.e. before name change : out.extendedFrags.fastq out.notCombined.fastq
    
else
    
    echo
    echo "Skipping flash - interleaving read files to look like flash output :"    
    
    cat READ1.fastq | paste - - - - > tempREAD1.txt
    cat READ2.fastq | paste - - - - | paste tempREAD1.txt - > out.notCombined.fastq
    rm -f tempREAD1.txt
    
fi

    ls | grep out*fastq

    if [[ ${FLASH} -eq "1" ]]; then
    echo "Read counts after flash :"
    else
    echo "Read counts after flash-mimicking output-generation (read interleaving) :"        
    fi
    
    flashedCount=0
    nonflashedCount=0
    
    if [ -s "out.extendedFrags.fastq" ] ; then
        flashedCount=$(( $( grep -c "" out.extendedFrags.fastq )/4 ))
    fi
    if [ -s "out.notCombined.fastq" ] ; then
        nonflashedCount=$(( $( grep -c "" out.notCombined.fastq )/4 ))
    fi
    
    mv -f out.extendedFrags.fastq FLASHED.fastq
    mv -f out.notCombined.fastq NONFLASHED.fastq
    
    echo "FLASHED.fastq (count of read pairs combined in flash) : ${flashedCount}"
    if [[ ${FLASH} -eq "1" ]]; then
    echo "NONFLASHED.fastq (not extendable via flash) : ${nonflashedCount}"
    else
    echo "NONFLASHED.fastq (not flashed, but mimicking flash output) : ${nonflashedCount}"        
    fi
}

generateParamsForFiltering(){

testedFile="${CapturesiteFile}"
doTempFileTesting

printThis="perl ${RunScriptsPath}/${CCscriptname} --onlyparamsforfiltering --CCversion ${CCversion} -o ${CapturesiteFile} --genome ${GENOME} --ucscsizes ${ucscBuild} ${otherParameters}"
printToLogFile

# remove parameter file from possible earlier run..
rm -f parameters_for_filtering.log

setStringentFailForTheFollowing
perl ${RunScriptsPath}/${CCscriptname} --onlyparamsforfiltering --CCversion "${CCversion}" -o "${CapturesiteFile}" --genome "${GENOME}" --ucscsizes "${ucscBuild}" ${otherParameters}
stopStringentFailAfterTheAbove

if [ "$?" -ne 0 ];then
    printThis="Filtering parameter generation run reported error !"
    printNewChapterToLogFile
    paramGenerationRunFineOK=0
else
    printThis="Filtering parameter generation succeeded !"
    printToLogFile    
fi

}

runCCanalyser(){
    
################################################################
# Running CAPTURE-C analyser for the aligned file..

#sampleForCCanalyser="RAW_${Sample}"
#samForCCanalyser="Combined_reads_REdig.sam"
#runDir=$( pwd )
#samDirForCCanalyser=${runDir}
#publicPathForCCanalyser="${PublicPath}/RAW"
#JamesUrlForCCanalyser="${JamesUrl}/RAW"


printThis="Running CAPTURE-C analyser for the aligned file.."
printToLogFile

testedFile="${CapturesiteFile}"
doTempFileTesting

if [ "${PARALLEL}" -ne 1 ]; then
mkdir -p "${publicPathForCCanalyser}"
fi

printThis="perl ${RunScriptsPath}/${CCscriptname} --CCversion ${CCversion} -f ${samDirForCCanalyser}/${samForCCanalyser} -o ${CapturesiteFile} -r ${fullPathDpnGenome} --pf ${publicPathForCCanalyser} --pu ${JamesUrlForCCanalyser} -s ${sampleForCCanalyser} --genome ${GENOME} --ucscsizes ${ucscBuild} -w ${WINDOW} -i ${INCREMENT} --flashed ${FLASHED} --duplfilter ${DUPLFILTER} ${otherParameters}"
printToLogFile

echo "-f Input filename "
echo "-r Restriction coordinates filename "
echo "-o Capturesitenucleotide position filename "
echo "-s Sample name (and the name of the folder it goes into)"
if [ "${PARALLEL}" -ne 1 ]; then
echo "--CCversion Cb3 or Cb4 or Cb5 (which version of the duplicate filtering we will perform)"
echo "--pf Your public folder"
echo "--pu Your public url"
echo "-w Window size (default = 2kb)"
echo "-i Window increment (default = 200bp)"
echo "--dump Print file of unaligned reads (sam format)"
echo "--snp Force all capture points to contain a particular SNP"
echo "--limit Limit the analysis to the first n reads of the file"
echo "--genome Specify the genome (mm9 / hg18)"
echo "--ucscsizes Chromosome sizes file path"
echo "--globin Combines the two captures from the gene duplicates (HbA1 and HbA2)"
echo "--flashed	1 or 0 (are the reads in input sam combined via flash or not ? - run out.extended with 1 and out.not_combined with 0)"
echo "--duplfilter 1 or 0 (will the reads be duplicate filtered)\n"
echo "--parp Filter artificial chromosome chrPARP out before visualisation"
echo "--stringent enforces additional stringency - forces all reported subfragments to be unique"
echo "--stranded To replicate the strand-specific (i.e. wrong) duplicate filter of CB3a/CC3 and CB4a/CC4"
echo "--umi Run contains UMI indices - alter the duplicate filter accordingly : ask Damien Downes how to prepare your files for pipeline, if you are interested in doing this"
echo "--wobble Wobble bin width. default 1(turned off). UMI runs recommendation 20, i.e. +/- 10bases wobble. to turn this off, set it to 1 base."
fi

runDir=$( pwd )

# Copy used capture-site (REfragment) file for archiving purposes..
cp ${CapturesiteFile} usedCapturesiteFile.txt

# remove parameter file from possible earlier run..
rm -f parameters_for_filtering.log

# HERE TESTING FOR bamDivideMappedReads.pl
# if [ "${PARALLEL}" -eq 1 ]; then
# echo perl ${RunScriptsPath}/bamDivideMappedReads.pl --CCversion "${CCversion}" -f "${samDirForCCanalyser}/${samForCCanalyser}" -s "${sampleForCCanalyser}"    
# perl ${RunScriptsPath}/bamDivideMappedReads.pl --CCversion "${CCversion}" -f "${samDirForCCanalyser}/${samForCCanalyser}" -s "${sampleForCCanalyser}"    
# else
perl ${RunScriptsPath}/${CCscriptname} --CCversion "${CCversion}" -f "${samDirForCCanalyser}/${samForCCanalyser}" -o "${CapturesiteFile}" -r "${fullPathDpnGenome}" --pf "${publicPathForCCanalyser}" --pu "${JamesUrlForCCanalyser}" -s "${sampleForCCanalyser}" --genome "${GENOME}" --ucscsizes "${ucscBuild}" -w "${WINDOW}" -i "${INCREMENT}" --flashed "${FLASHED}" --duplfilter "${DUPLFILTER}" ${otherParameters}
# fi

echo "Contents of run folder :"
ls -lht 

echo
echo "Contents of CCanalyser output folder ( ${sampleForCCanalyser}_${CCversion} ) "
ls -lht ${sampleForCCanalyser}_${CCversion}

if [ "${PARALLEL}" -ne 1 ]; then

echo
echo "Counts of output files - by file type :"

count=$( ls -1 ${publicPathForCCanalyser} | grep -c '\.bw$' )
echo
echo "${count} bigwig files (should be x2 the amount of capture-site (REfragment)s, if all had captures)"

count=$( ls -1 ${sampleForCCanalyser}_${CCversion} | grep -c '\.wig$' )
echo
echo "${count} wig files (should be x2 the amount of capture-site (REfragment)s, if all had captures)"

count=$( ls -1 ${sampleForCCanalyser}_${CCversion} | grep -c '\.gff$')
echo
echo "${count} gff files (should be x1 the amount of capture-site (REfragment)s, if all had captures)"

fi

echo
echo "Output log files :"
ls -1 ${sampleForCCanalyser}_${CCversion} | grep '\.txt$'

echo
echo "Sam files :"
ls -1 ${sampleForCCanalyser}_${CCversion} | grep '\.sam$'

   
}

runCCanalyserOnlyBlat(){
    
################################################################
# Running CAPTURE-C analyser for the aligned file..

printThis="Running onlyBlat CAPTURE-C analyser .."
printToLogFile

testedFile="${CapturesiteFile}"
doTempFileTesting

printThis="perl ${RunScriptsPath}/${CCscriptname} --onlyparamsforfiltering --CCversion ${CCversion} -o ${CapturesiteFile} --genome ${GENOME} --ucscsizes ${ucscBuild} ${otherParameters}"
printToLogFile

runDir=$( pwd )

# Copy used capture-site (REfragment) file for archiving purposes..
cp ${CapturesiteFile} usedCapturesiteFile.txt

# remove parameter file from possible earlier run..
rm -f parameters_for_filtering.log

setStringentFailForTheFollowing
perl ${RunScriptsPath}/${CCscriptname} --onlyparamsforfiltering --CCversion "${CCversion}" -o "${CapturesiteFile}" --genome "${GENOME}" --ucscsizes "${ucscBuild}" ${otherParameters}
stopStringentFailAfterTheAbove

if [ "$?" -ne 0 ];then
    printThis="Filtering parameter generation run reported error !"
    printNewChapterToLogFile
    paramGenerationRunFineOK=0
else
    printThis="Filtering parameter generation succeeded !"
    printToLogFile    
fi


echo "Contents of run folder :"
ls -lht

cat parameters_for_filtering.log
   
}

runCCanalyserOnlyCapturesites(){
    
################################################################
# Running CAPTURE-C analyser for the aligned file..

printThis="Running onlyCapturesites CAPTURE-C analyser .."
printToLogFile

testedFile="${CapturesiteFile}"
doTempFileTesting

printThis="perl ${RunScriptsPath}/${CCscriptname} -o ${CapturesiteFile} -s ${Sample} --onlycapturesitefile ${otherParameters}"
printToLogFile

echo "-o Capturesitenucleotide position filename "

runDir=$( pwd )

setStringentFailForTheFollowing
perl ${RunScriptsPath}/${CCscriptname} -o "${CapturesiteFile}"  -s "${Sample}" --onlycapturesitefile ${otherParameters}
stopStringentFailAfterTheAbove
if [ "$?" -ne 0 ];then
    printThis="Capturesite file bunching run reported error !"
    printNewChapterToLogFile
    capturesiteRunIsFine=0
fi


echo "Contents of run folder :"
ls -lht

echo
echo "Contents of CCanalyser output folder ( ${Sample}_${CCversion} ) "
ls -lht ${Sample}_${CCversion}
   
}



runF1folder(){
    
echo "FastqIn" > ${JustNowLogFile}
	
# Copy files over.. (move files if parallel run)

checkThis="${Read1}"
checkedName='Read1'
checkParse
checkThis="${Read2}"
checkedName='Read2'
checkParse

testedFile="${Read1}"
doInputFileTesting
testedFile="${Read2}"
doInputFileTesting

# cp ${Read1} Read1_safety1.fastq
# cp ${Read2} Read2_safety1.fastq

if [ "${PARALLEL}" -eq 1 ] ; then
printThis="Moving input file R1.."
printToLogFile

moveCommand='mv -f ${Read1} F1_beforeCCanalyser_${Sample}_${CCversion}/READ1.fastq'
moveThis="${Read1}"
moveToHere="F1_beforeCCanalyser_${Sample}_${CCversion}/READ1.fastq"
checkMoveSafety
mv -f "${Read1}" F1_beforeCCanalyser_${Sample}_${CCversion}/READ1.fastq

elif [ "${Read1}" != "READ1.fastq" ] ; then
printThis="Copying input file R1.."
printToLogFile
cp "${Read1}" F1_beforeCCanalyser_${Sample}_${CCversion}/READ1.fastq
else
printThis="Making safety copy of the original READ1.fastq : READ1.fastq_original.."
printToLogFile
cp "${Read1}" F1_beforeCCanalyser_${Sample}_${CCversion}/READ1.fastq_original
fi
doQuotaTesting

if [ "${PARALLEL}" -eq 1 ] ; then
printThis="Moving input file R2.."
printToLogFile

moveCommand='mv -f ${Read2} F1_beforeCCanalyser_${Sample}_${CCversion}/READ2.fastq'
moveThis="${Read2}"
moveToHere="F1_beforeCCanalyser_${Sample}_${CCversion}/READ2.fastq"
checkMoveSafety
mv -f "${Read2}" F1_beforeCCanalyser_${Sample}_${CCversion}/READ2.fastq

elif [ "${Read2}" != "READ2.fastq" ] ; then
printThis="Copying input file R2.."
printToLogFile
cp "${Read2}" F1_beforeCCanalyser_${Sample}_${CCversion}/READ2.fastq
else
printThis="Making safety copy of the original READ2.fastq : READ2.fastq_original.."
printToLogFile
cp "${Read2}" F1_beforeCCanalyser_${Sample}_${CCversion}/READ2.fastq_original
fi
doQuotaTesting

testedFile="F1_beforeCCanalyser_${Sample}_${CCversion}/READ1.fastq"
doTempFileTesting
testedFile="F1_beforeCCanalyser_${Sample}_${CCversion}/READ2.fastq"
doTempFileTesting

# Go into output folder..
cdCommand='cd F1_beforeCCanalyser_${Sample}_${CCversion}'
cdToThis="F1_beforeCCanalyser_${Sample}_${CCversion}"
checkCdSafety  
cd F1_beforeCCanalyser_${Sample}_${CCversion}

################################################################
#Check BOWTIE quality scores..

printThis="Checking the quality score scheme of the fastq files.."
printToLogFile
    
    bowtieQuals=""
    LineCount=$(($( grep -c "" READ1.fastq )/4))
    if [ "${LineCount}" -gt 100000 ] ; then
        bowtieQuals=$( perl ${RunScriptsPath}/fastq_scores_bowtie${BOWTIE}.pl -i READ1.fastq -r 90000 )
    else
        rounds=$((${LineCount}-10))
        bowtieQuals=$( perl ${RunScriptsPath}/fastq_scores_bowtie${BOWTIE}.pl -i READ1.fastq -r ${rounds} )
    fi
    
    echo "Flash, Trim_galore and Bowtie will be ran in quality score scheme : ${bowtieQuals}"

    # The location of "zero" for the filtering/trimming programs cutadapt, trim_galore, flash    
    intQuals=""
    if [ "${bowtieQuals}" == "--phred33-quals" ] || [ "${bowtieQuals}" == "--phred33" ]; then
        intQuals="33"
    else
        # Both solexa and illumina phred64 have their "zero point" in 64
        intQuals="64"
    fi

################################################################
# Fastq for original files..

echo "FastQC" > ${JustNowLogFile}

printThis="Running fastQC for input files.."
printToLogFile

printThis="${RunScriptsPath}/QC_and_Trimming.sh --fastqc"
printToLogFile

echo >fastqcRuns.out
echo "RAW untrimmed files " >fastqcRuns.out
echo >>fastqcRuns.out
echo >fastqcRuns.err
echo "RAW untrimmed files " >fastqcRuns.err
echo >>fastqcRuns.err

setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh --fastqc  --fastqcname $(basename $(dirname $(pwd)))_ORIGINAL 1>>fastqcRuns.out 2>>fastqcRuns.err
stopStringentFailAfterTheAbove

    # Changing names of fastqc folders to be "ORIGINAL"
    
    rm -rf READ1_fastqc_ORIGINAL
    rm -rf READ2_fastqc_ORIGINAL
    
    mkdir READ1_fastqc_ORIGINAL
    mkdir READ2_fastqc_ORIGINAL
    
    mv -f READ1_fastqc.html READ1_fastqc_ORIGINAL/fastqc_report.html
    mv -f READ2_fastqc.html READ2_fastqc_ORIGINAL/fastqc_report.html 
    mv -f READ1_fastqc.zip  READ1_fastqc_ORIGINAL.zip
    mv -f READ2_fastqc.zip  READ2_fastqc_ORIGINAL.zip
   
    ls -lht

################################################################
# Trimgalore for the reads..

if [[ ${TRIM} -eq "1" ]]; then
    
echo "Trim" > ${JustNowLogFile}

printThis="Running trim_galore for the reads.."
printToLogFile

date

printThis="${RunScriptsPath}/QC_and_Trimming.sh -q ${intQuals} --filter 3 --qmin ${QMIN}"
printToLogFile

setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh -q "${intQuals}" --filter 3 --qmin ${QMIN} 1>trimming.log 2>trimming.err
stopStringentFailAfterTheAbove

date

doQuotaTesting
ls -lht

testedFile="READ1.fastq"
doTempFileTesting
testedFile="READ2.fastq"
doTempFileTesting

# cp READ1.fastq Read1_safety2.fastq
# cp READ2.fastq Read2_safety2.fastq


################################################################
# Fastq for trimmed files..

echo "FastQC" > ${JustNowLogFile}

printThis="Running fastQC for trimmed files.."
printToLogFile

echo >>fastqcRuns.out
echo "Trimmed files " >>fastqcRuns.out
echo >>fastqcRuns.out
echo >>fastqcRuns.err
echo "Trimmed files " >>fastqcRuns.err
echo >>fastqcRuns.err


printThis="${RunScriptsPath}/QC_and_Trimming.sh --fastqc"
printToLogFile

setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh --fastqc  --fastqcname $(basename $(dirname $(pwd)))_TRIMMED 1>>fastqcRuns.out 2>>fastqcRuns.err
stopStringentFailAfterTheAbove

    # Changing names of fastqc folders to be "TRIMMED"
    
    rm -rf READ1_fastqc_TRIMMED
    rm -rf READ2_fastqc_TRIMMED
    
    mkdir READ1_fastqc_TRIMMED
    mkdir READ2_fastqc_TRIMMED
    
    mv -f READ1_fastqc.html READ1_fastqc_TRIMMED/fastqc_report.html
    mv -f READ2_fastqc.html READ2_fastqc_TRIMMED/fastqc_report.html 
    
    mv -f READ1_fastqc.zip READ1_fastqc_TRIMMED.zip
    mv -f READ2_fastqc.zip READ2_fastqc_TRIMMED.zip
    
fi
    
################################################################
# FLASH for trimmed files..
printThis="Running FLASH for trimmed files.."
printToLogFile

date

echo "Flash" > ${JustNowLogFile}

runFlash

date

ls -lht
doQuotaTesting

# cp READ1.fastq Read1_safety3.fastq
# cp READ2.fastq Read2_safety3.fastq


rm -f READ1.fastq READ2.fastq

################################################################
# Fastq for flashed files..

echo "FastQC" > ${JustNowLogFile}

printThis="Running fastQC for FLASHed and nonflashed files.."
printToLogFile

rm -rf FLASHED_fastqc
mkdir FLASHED_fastqc
setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh --fastqc --single 1 --basenameR1 FLASHED  --fastqcname $(basename $(dirname $(pwd)))_FLASHED 1>>fastqcRuns.out 2>>fastqcRuns.err
stopStringentFailAfterTheAbove
mv -f FLASHED_fastqc.html FLASHED_fastqc/fastqc_report.html

rm -rf NONFLASHED_fastqc
mkdir NONFLASHED_fastqc
setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh --fastqc --single 1 --basenameR1 NONFLASHED  --fastqcname $(basename $(dirname $(pwd)))_NONFLASHED 1>>fastqcRuns.out 2>>fastqcRuns.err
stopStringentFailAfterTheAbove
mv -f NONFLASHED_fastqc.html NONFLASHED_fastqc/fastqc_report.html


################################################################

# Running dpnII digestion for flashed file..

echo "REdig" > ${JustNowLogFile}

printThis="Running ${REenzyme} digestion for flashed file.."
printToLogFile

date

printThis="perl ${RunScriptsPath}/${REenzyme}cutReads4.pl FLASHED.fastq FLASHED"
printToLogFile

setStringentFailForTheFollowing
perl ${RunScriptsPath}/${REenzyme}cutReads4.pl FLASHED.fastq FLASHED > FLASHED_${REenzyme}digestion.log
stopStringentFailAfterTheAbove

date

cat FLASHED_${REenzyme}digestion.log
ls -lht
doQuotaTesting

testedFile="FLASHED_REdig.fastq"
doTempFileTesting

# cp FLASHED.fastq safety1FLASHED.fastq

rm -f FLASHED.fastq

# Running dpnII digestion for non-flashed file..
printThis="Running ${REenzyme} digestion for non-flashed file.."
printToLogFile

printThis="perl ${RunScriptsPath}/${REenzyme}cutReads4.pl NONFLASHED.fastq NONFLASHED"
printToLogFile

setStringentFailForTheFollowing
perl ${RunScriptsPath}/${REenzyme}cutReads4.pl NONFLASHED.fastq NONFLASHED > NONFLASHED_${REenzyme}digestion.log
stopStringentFailAfterTheAbove
cat NONFLASHED_${REenzyme}digestion.log

 ls -lht
 doQuotaTesting
 
testedFile="NONFLASHED_REdig.fastq"
doTempFileTesting
  
# cp NONFLASHED.fastq safety1NONFLASHED.fastq

rm -f NONFLASHED.fastq

################################################################
# Fastq for flashed files..

echo "FastQC" > ${JustNowLogFile}

printThis="Running fastQC for RE-digested files.."
printToLogFile

rm -rf FLASHED_REdig_fastqc
mkdir FLASHED_REdig_fastqc
setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh --fastqc --single 1 --basenameR1 FLASHED_REdig  --fastqcname $(basename $(dirname $(pwd)))_FLASHED_REdig 1>>fastqcRuns.out 2>>fastqcRuns.err
stopStringentFailAfterTheAbove
mv -f FLASHED_REdig_fastqc.html FLASHED_REdig_fastqc/fastqc_report.html

rm -rf NONFLASHED_REdig_fastqc
mkdir NONFLASHED_REdig_fastqc
setStringentFailForTheFollowing
${RunScriptsPath}/QC_and_Trimming.sh --fastqc --single 1 --basenameR1 NONFLASHED_REdig   --fastqcname $(basename $(dirname $(pwd)))_NONFLASHED_REdig 1>>fastqcRuns.out 2>>fastqcRuns.err
stopStringentFailAfterTheAbove
mv -f NONFLASHED_REdig_fastqc.html NONFLASHED_REdig_fastqc/fastqc_report.html



################################################################
# Running Bowtie for the digested file..

echo "BOWTIE_f" > ${JustNowLogFile}

printThis="Running Bowtie for the digested files.."
printToLogFile


printThis="Flashed reads Bowtie .."
printToLogFile

echo ${printThis} > bowties.log
echo >> bowties.log

echo "Beginning bowtie run (outputting run command after completion) .."
setMparameter

date

if [ "${BOWTIE}" -eq 2 ] ; then
setStringentFailForTheFollowing
bowtie2 -p 1 ${otherBowtie2Parameters} ${bowtieQuals} -x ${BowtieGenome} -U FLASHED_REdig.fastq > FLASHED_REdig_unfiltered.sam 2>>bowties.log
stopStringentFailAfterTheAbove
echo "bowtie2 -p 1 ${otherBowtie2Parameters} ${bowtieQuals} -x ${BowtieGenome} -U FLASHED_REdig.fastq"
else
setStringentFailForTheFollowing
bowtie -p 1 --chunkmb "${BOWTIEMEMORY}" ${otherBowtie1Parameters} ${bowtieQuals} ${mParameter} --best --strata --sam "${BowtieGenome}" FLASHED_REdig.fastq > FLASHED_REdig_unfiltered.sam 2>>bowties.log
stopStringentFailAfterTheAbove
fi

date

#bowtie -p 1 -m 2 --best --strata --sam --chunkmb 256 ${bowtieQuals} "${BowtieGenome}" Combined_reads_REdig.fastq Combined_reads_REdig.sam

testedFile="FLASHED_REdig_unfiltered.sam"
doTempFileTesting

doQuotaTesting

samtools view -SH FLASHED_REdig_unfiltered.sam | grep bowtie

flashstatus="FLASHED"

echo "countRds_f" > ${JustNowLogFile}

countReadsAfterBowtie
# above also sets TEMPintSizeForSort

# Make bigwig track of the raw file (100b bins - start of each fragment) ..
makeRawsamBigwig

echo "LOOP1_f" > ${JustNowLogFile}

if [ "${onlyCis}" -eq 1 ]; then
chrWiseMappedBamFiles
else
chrWiseMappedBamFilesSaveTransFrags   
fi

echo "LOOP2to5_f" > ${JustNowLogFile}

chrWiseFilteringLoops
chrWiseFilteringLoopsReports

printThis="After-bowtie read filtering complete for ${flashstatus} reads ! "
printNewChapterToLogFile
date

# -----------------------------------------------------------

echo "BOWTIE_nf" > ${JustNowLogFile}

printThis="Non-flashed reads Bowtie .."
printToLogFile
echo >> bowties.log
echo ${printThis} >> bowties.log
echo >> bowties.log

echo "Beginning bowtie run (outputting run command after completion) .."
setMparameter

date

if [ "${BOWTIE}" -eq 2 ] ; then
setStringentFailForTheFollowing
bowtie2 -p 1 ${otherBowtie2Parameters} ${bowtieQuals} -x ${BowtieGenome} -U NONFLASHED_REdig.fastq > NONFLASHED_REdig_unfiltered.sam 2>> bowties.log
stopStringentFailAfterTheAbove
echo "bowtie2 -p 1 ${otherBowtie2Parameters} ${bowtieQuals} -x ${BowtieGenome} -U NONFLASHED_REdig.fastq"
else
setStringentFailForTheFollowing
bowtie -p 1 --chunkmb "${BOWTIEMEMORY}" ${otherBowtie1Parameters} ${bowtieQuals} ${mParameter} --best --strata --sam "${BowtieGenome}" NONFLASHED_REdig.fastq > NONFLASHED_REdig_unfiltered.sam 2>> bowties.log
stopStringentFailAfterTheAbove
fi

date
echo ""
cat bowties.log
echo "" >> "/dev/stderr"
cat bowties.log >> "/dev/stderr"

#bowtie -p 1 -m 2 --best --strata --sam --chunkmb 256 ${bowtieQuals} "${BowtieGenome}" Combined_reads_REdig.fastq Combined_reads_REdig.sam

testedFile="NONFLASHED_REdig_unfiltered.sam"
doTempFileTesting

doQuotaTesting

samtools view -SH NONFLASHED_REdig_unfiltered.sam | grep bowtie


flashstatus="NONFLASHED"

echo "countRds_f" > ${JustNowLogFile}

countReadsAfterBowtie
# above also sets TEMPintSizeForSort

# Make bigwig track of the raw file (100b bins - start of each fragment) ..
makeRawsamBigwig

echo "LOOP1_f" > ${JustNowLogFile}

if [ "${onlyCis}" -eq 1 ]; then
chrWiseMappedBamFiles
else
chrWiseMappedBamFilesSaveTransFrags   
fi

echo "LOOP2to5_f" > ${JustNowLogFile}

chrWiseFilteringLoops
chrWiseFilteringLoopsReports

printThis="After-bowtie read filtering complete for ${flashstatus} reads ! "
printNewChapterToLogFile
date

# -----------------------------------

# Temporary exit ..

printThis="Reached tester end in runtools.sh"
printToLogFile
date
echo
exit 0

# -----------------------------------

echo "countRds" > ${JustNowLogFile}

# Cleaning up after ourselves ..

printThis="Finishing up the F1 run folder.."
printToLogFile

#ls -lht Combined_reads_REdig.bam
ls -lht FLASHED_REdig.sam
ls -lht NONFLASHED_REdig.sam

echo
echo "Read counts - in amplicon size filtered sam files : "
echo
flashstatus="FLASHED"
echo ${flashstatus}_REdig.sam
cat  ${flashstatus}_REdig.sam | grep -cv '^@'
echo
flashstatus="NONFLASHED"
echo ${flashstatus}_REdig.sam
cat  ${flashstatus}_REdig.sam | grep -cv '^@'
echo

cdCommand='cd ${runDir}'
cdToThis="${runDir}"
checkCdSafety  
cd ${runDir}
	
}

prepareForOnlyCCanalyserRun(){
 
 # Go into output folder..
cd F1_beforeCCanalyser_${Sample}_${CCversion}
	
# This is the "ONLY_CC_ANALYSER" end fi - if testrun, skipped everything before this point :
# assuming existing output on the above mentioned files - all correctly formed except captureC output !
echo
echo "RE-RUN ! - running only capC analyser script, and filtering (assuming previous pipeline output in the run folder)"
echo

# Here deleting the existing - and failed - capturec analysis directory. not touching public files.

    rmCommand='rm -rf ../F2_redGraphs_${Sample}_${CCversion}'
    rmThis="${Sample}_${CCversion}"
    checkRemoveSafety

    rm -rf "../F2_redGraphs_${Sample}_${CCversion}"
    rm -rf "../F2_dividedSams_${Sample}_${CCversion}"
    rm -rf "../F3_orangeGraphs_${Sample}_${CCversion}"
    rm -rf "../F4_blatPloidyFilteringLog_${Sample}_${CCversion}"
    rm -rf "../F5_greenGraphs_separate_${Sample}_${CCversion}"
    rm -rf "../F6_greenGraphs_combined_${Sample}_${CCversion}"
    rm -rf "../F7_summaryFigure_${Sample}_${CCversion}"
    
    rmCommand='../filteringLogFor_PREfiltered_${Sample}_${CCversion}'
    rmThis="${Sample}_${CCversion}"
    checkRemoveSafety
    rm -rf ../filteringLogFor_PREfiltered_${Sample}_${CCversion} ../RAW_${Sample}_${CCversion} ../PREfiltered_${Sample}_${CCversion} ../FILTERED_${Sample}_${CCversion} ../COMBINED_${Sample}_${CCversion}

    rm -f ../FLASHED_REdig.sam ../NONFLASHED_REdig.sam  
    
# Remove the malformed public folder for a new try..
    rm -rf ../PERMANENT_BIGWIGS_do_not_move
    
    checkThis="${PublicPath}"
    checkedName='${PublicPath}'
    checkParse
  
    thisPublicFolder="${PublicPath}"
    thisPublicFolderName='${PublicPath}'
    
    if [ -d "${thisPublicFolder}" ]; then
    isThisPublicFolderParsedFineAndMineToMeddle
    # Now we are satisfied, and actually delete it.
    rm -rf ${PublicPath}
    fi
    
    rm -rf ../PERMANENT_BIGWIGS_do_not_move
    
cd ..

}

prepareF1Sams(){

 # Go into output folder..
cd F1_beforeCCanalyser_${Sample}_${CCversion}
    
# Restoring the input sam files..

# Run crash : we will have SAM instead of bam - if we don't check existence here, we will overwrite (due to funny glitch in samtools 1.1 ) - we are already in samtools 1.3 but that may still be valid ?
if [ ! -s FLASHED_REdig.sam ]
then
    if [ -s FLASHED_REdig.bam ]
    then
        setStringentFailForTheFollowing
        samtools view -h FLASHED_REdig.bam > TEMP.sam
        stopStringentFailAfterTheAbove
        mv -f TEMP.sam FLASHED_REdig.sam
        if [ -s FLASHED_REdig.sam ]; then
            rm -f FLASHED_REdig.bam
        else
            echo "EXITING ! : Couldn't make FLASHED_REdig.sam from FLASHED_REdig.bam" >> "/dev/stderr"
            exit 1
        fi
    else
    echo "WARNING : Couldn't find FLASHED_REdig.bam/.sam - continuing without any flashed reads .. " >> "/dev/stderr"
    fi
fi

# Run crash : we will have SAM instead of bam - if we don't check existence here, we will overwrite (due to funny glitch in samtools 1.1 ) - we are already in samtools 1.3 but that may still be valid ?
if [ ! -s NONFLASHED_REdig.sam ]
then
    if [ -s NONFLASHED_REdig.bam ]
    then
        setStringentFailForTheFollowing
        samtools view -h NONFLASHED_REdig.bam > TEMP.sam
        stopStringentFailAfterTheAbove
        mv -f TEMP.sam NONFLASHED_REdig.sam
        if [ -s NONFLASHED_REdig.sam ]; then
            rm -f NONFLASHED_REdig.bam
        else
            echo "EXITING ! : Couldn't make NONFLASHED_REdig.sam from NONFLASHED_REdig.bam" >> "/dev/stderr"
            exit 1
        fi
    else
    echo "WARNING : Couldn't find NONFLASHED_REdig.bam/.sam - continuing without any nonflashed reads .. " >> "/dev/stderr"
    fi
fi

cd ${runDir}
    
}

