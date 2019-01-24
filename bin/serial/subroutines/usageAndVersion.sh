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


  writeRerunInstructionsFile(){
  echo "" > rerunInstructions.txt
  echo "PARALLEL/RAINBOW pipe Rerun instructions :" >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "If you only have small amount of input fastqs, easiest is to delete all output (also the public folder), and restart from beginning." >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "If you have many succeeded fastqs, and had problems only in a subset of them, you need to use --repairBrokenFastqs flag," >> rerunInstructions.txt
  echo "and before that, editing your PIPE_fastqPaths.txt so, that the repair run knows what to do." >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "Never remove lines from PIPE_fastqPaths.txt  or change line order in it (see instructions below) ." >> rerunInstructions.txt
  echo "  " >> rerunInstructions.txt
  echo "The repair with --repairBrokenFastqs can be ran multiple times, each time affecting only the fastqs still being broken (or wished to be altered)," >> rerunInstructions.txt
  echo "until finally all that remains are intact results for all wished fastq files." >> rerunInstructions.txt
  echo " " >> rerunInstructions.txt
  echo "------------------------------------------------------------" >> rerunInstructions.txt
  echo "How to use --repairBrokenFastqs in different fastq problems :" >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "1) quota issues (or recoverable corrupted files)" >> rerunInstructions.txt
  echo "2) typo in PIPE_fastqPaths.txt" >> rerunInstructions.txt
  echo "3) removing some fastqs from the run (unrecoverable corrupted files etc)" >> rerunInstructions.txt
  echo "4) adding fastqs into the run" >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "5) smoother troubleshooting : combining this to --stopAfterFolderB  and --startAfterFolderB " >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "in all the below : Do not change delete lines, or change line order in your PIPE_fastqPaths.txt . " >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "------------------------------------------------------------" >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "1) QUOTA ISSUES " >> rerunInstructions.txt
  echo "If you failed because of quota issues, just restart the run with flag --repairBrokenFastqs ." >> rerunInstructions.txt
  echo "This will re-run the fastqs which failed, and after that continue the run normally." >> rerunInstructions.txt
  echo "The same goes, if you have broken fastqs, but are able to rescue them, so that the files are now uncorrupted." >> rerunInstructions.txt
  echo "  " >> rerunInstructions.txt
  echo "2) TYPO IN   PIPE_fastqPaths.txt" >> rerunInstructions.txt
  echo "If you had a typo in your PIPE_fastqPaths.txt you can correct that, and the corrected path will be red in in the "fixing run" . The earlier results for that fastq pair will be overwritten." >> rerunInstructions.txt
  echo "Do not change line order in your PIPE_fastqPaths.txt . " >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "3) REMOVING FASTQS FROM THE RUN" >> rerunInstructions.txt
  echo "If you want to remove some fastqs from the analysis (because your files are corrupted, or you accidentally mixed fastqs from multiple samples to a same run)," >> rerunInstructions.txt
  echo "do NOT delete these lines from the PIPE_fastq_Paths.txt ." >> rerunInstructions.txt
  echo "Instead, you need to write word "REMOVE" to the beginning of the corresponding line in PIPE_fastqPaths.txt (the line can be otherwise empty, or contain the file paths as before)." >> rerunInstructions.txt
  echo "This leads the fastqs in question to be skipped in the analysis and all their results from previous run(s) to be deleted." >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "4) ADDING FASTQS INTO THE RUN" >> rerunInstructions.txt
  echo "If you want to ADD some fastqs - just add a new line to the end of PIPE_fastqPaths.txt normally, this will be added in." >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo "5) SMOOTHER TROUBLESHOOTING WITH   --stopAfterFolderB  AND --startAfterFolderB" >> rerunInstructions.txt
  echo "You may wish to combine the troubleshooting with --repairBrokenFastqs to flags --stopAfterFolderB (which stops the run just after the analysis and combining of the fastq files)" >> rerunInstructions.txt
  echo "- to inspect your rerun results before moving on in the analysis. After you have had a successfull rerun with --repairBrokenFastqs --stopAfterFolderB ," >> rerunInstructions.txt
  echo "you can then continue with flag --startAfterFolderB  which skips over folders A and B (assumes properly formed output) and continues on in the analysis." >> rerunInstructions.txt
  echo "Remember to not to delete output folders A and B output if using --startAfterFolderB , as all 'check if this file exists' tests are skipped when using it." >> rerunInstructions.txt
  echo "The flag --startAfterFolderB can used also if you crash within BLAT generation or CAPTURESITEbunches generation." >> rerunInstructions.txt
  echo "" >> rerunInstructions.txt
  echo " "  >> rerunInstructions.txt
  }

version(){
    pipesiteAddress="http://userweb.molbiol.ox.ac.uk/public/telenius/NGseqBasicManual/outHouseUsers/"
    
    versionInfo="\n${CCversion} pipeline, running ${CCseqBasicVersion}.sh \nUser manual, updates, bug fixes, etc in : ${pipesiteAddress}\n"

}


usage(){
    
    version
    echo -e ${versionInfo}
    
echo 
echo "FOR PAIRED END SEQUENCING DATA"
echo
echo "fastq --> fastqc --> trimming  --> fastqc again --> flashing --> fastqc again --> in silico RE fragments --> bowtie1 -->  in silico genome digestion --> captureC analyser --> data hub generation"
echo
echo "Is to be ran in the command line like this :"
echo "qsub -cwd -o qsub.out -e qsub.err -N MyPipeRun < ./run.sh"
echo "Where run.sh is oneliner like : '${DNasePipePath}/${nameOfScript} RunOptions' "
echo "where RunOptions are the options given to the pipe - listed below"
echo
echo "Run the script in an empty folder - it will generate all the files and folders it needs."
echo
echo "OBLIGATORY FLAGS FOR THE PIPE RUN :"
echo
echo "-c /path/to/capturefragment/file.txt : the file containing the RE-fragments within which the BIOTINYLATED CAPTURESITES reside, and their proximity exclusions (standard practise : 1000bases both directions), and possible SNP sites (see pipeline manual how to construct this file : ${manualURLpath} )"
echo "-o (synonymous to -c above)"
echo "--R1 /path/to/read1.fastq : fastq file from miseq or hiseq run (in future also .gz packed will be supported)"
echo "--R2 /path/to/read2.fastq : fastq file from miseq or hiseq run (in future also .gz packed will be supported)"
echo "--genome mm9 : genome to use to map and analyse the sample (supports most WIMM genomes - mm9,mm10,hg18,hg19 - report to Jelena if some genomes don't seem to work ! )"
echo "--pf /public/username/location/for/UCSC/visualisation/files : path to a folder where you want the data hub to be generated. Does not need to exist - pipeline will generate it for you."
echo "-s SampleName : the name of the sample - no weird characters, no whitespace, no starting with number, only characters azAz_09 allowed (letters, numbers, underscore)"
echo
echo "THE MINIMAL RUN COMMAND :"
echo "${RunScriptsPath}/${nameOfScript} -o /path/to/capturesite/file.txt --R1 /path/to/read1.fastq --R2 /path/to/read2.fastq --genome mm9 --pf /public/username/location/for/UCSC/visualisation/files"
echo "where genome (f.ex 'mm9')is the genome build the data is to be mapped to."
echo
echo "The above command expanded (to show the default settings) :"
echo "${RunScriptsPath}/${nameOfScript} -o /path/to/capturesite/file.txt --R1 /path/to/read1.fastq --R2 /path/to/read2.fastq --genome mm9 --pf /public/username/location/for/UCSC/visualisation/files"
echo "   -s sample --maxins 250 -m 2 --chunkmb 256 --trim -w 200 -i 20"
echo
echo "OPTIONAL FLAGS FOR TUNING THE PIPE RUN :"
echo
echo "HELP"
echo "-h, --help : prints this help"
echo
echo "OUTPUT LOG FILE NAMES"
echo "--outfile qsub.out (the STDOUT log file name in your RUN COMMAND - see above )"
echo "--errfile qsub.err (the STDERR log file name in your RUN COMMAND - see above )"
echo ""
echo "GENERATING TILED-CAPTURE COMPATIBLE BAM FILES WITH RAINBOW PIPE"
echo "(1) Run rainbow pipe normally, with flags : "
echo "  --tiled --stopAfterBamCombining --capturesitesPerBunch 1 "
echo "(2) In your capture-site (REfragment) file - give one tiled region per line (not one RE fragment per line). "
echo "  Give zero lenght exclusion fragments (copy the first three columns to the exclusion coordinates."
echo "  Like this :"
echo "  Globin  16 	0	1500000	16	0	1500000	1	A"
echo ""
echo "RE-RUNNING PARTS OF THE PIPE (in the case something went wrong)"
echo
echo "--stopAfterFolderB      : RAINBOW runs only - stop the run after fastq-wise analysis (don't proceed to bam combining and capture-site (REfragment)-wise analysis)"
echo "--startAfterFolderB     : RAINBOW runs only - restart the run from folder C onwards. "
echo "--stopAfterBamCombining : RAINBOW runs only - stop after folder C (bam combining). don't proceed to capture-site (REfragment)-wise analysis "
echo
echo "--onlyBlat : Don't analyse the fastq data, or generate public hubs. hust run the blat generation based on the capture-site (REfragment) coordinate file and genome build. "
echo "--onlyCCanalyser : Start the analysis from the CCanalyser script (deletes folders F2 --> and the output public folder, and restarts the run from there "
echo "     : assumes fully completed F1 folder with intact sam files ) . In RAINBOW runs this reruns folder D and data hub. "
echo
echo "--BLATforREUSEfolderPath /full/path/to/previous/F4_blatPloidyFilteringLog_CC4/BlatPloidyFilterRun/REUSE_blat folder"
echo "    if run crashes during or after blatting : point to the crashed folder's blat results, and avoid running blat again ! "
echo "    Remember to check (if you crashed during blat) - that all your blat output (psl) files are intact. Safest is to delete the last one of them (check which, with ls -lht)"
echo "    NOTE !!! if you combine this with --onlyCCanalyser : As the blat results live inside folder F4, --onlyCCanalyser will delete these files before re-starting the run (all folders but F1 get deleted)."
echo "        you need to COPY the REUSE_blat folder outside the original run folder, and point to that copied folder here. "
echo
echo "--onlyHub  : generates the summary counts, description html page and data hubs (overwrites existing ones). Should be ran in 1 processor only. "
echo
echo "PARALLEL RUN OPTIONS (only for RAINBOW pipe runs)"
echo
echo "-p 2 : parallel threads (processors) the run will ask in the queue. Run the job normally. "
echo
echo "--wholenode24 : special run mode - only to be used with 'qsub -q wholenodeq' . Turns on the run in 'wholenode mode' - a highly optimised run mode for 24 processors."
echo "--useClusterDiskArea : if you have --wholenode24 set (see above), you can use the node's own disk area to store the temporary files : this speeds up the run. "
echo "     Make sure your fastq.gz files are each ~ 1G in size : larger files may cause some of your fastqs crash during the run. "

echo
echo "RESTRICTION ENZYME SETTINGS"
echo "--dpn  (default) : dpnII is the RE of the experiment"
echo "--nla  : nlaIII is the RE of the experiment"
echo "--hind : hindIII is the RE of the experiment"
echo
echo "BOWTIE SETTINGS"
echo "--bowtie1 / --bowtie2 (default is bowtie1 - decide if bowtie1 or bowtie2 is to be used. bowtie2 is better to long reads - read lenght more than 70b, amplicon fragment lenght more than 350b)"
echo "--chunkmb "${BOWTIEMEMORY}" - memory allocated to Bowtie, defaults to 256mb "
echo "-M 2 run with bowtie parameter M=2 (if maps more than M times, report one alignment in random) - only affects bowtie1 run"
echo "-m 2 run with bowtie parameter m=2 (if maps more than m times, do not report any alignments) - only affects bowtie1 run"
echo "-m and -M are mutually exclusive."
echo "--trim3 0 : trim the reads this many bases from the 3' end when mapping in bowtie"
echo "--trim5 0 : trim the reads this many bases from the 5' end when mapping in bowtie"
echo "-v 3 : allow up-to-this-many total mismatches per read (ignore base qualities for these mismatches). "
echo "       cannot be combined to --seedlen, --seedmms or --maqerr (below)."
echo "--seedlen 28 - alignment seed lenght (minimum 5 bases) . Seed is the high-quality bases in the 5' end of the read. Default 28 (bowtie1), 20 (bowtie2)."
echo "--seedmms 2 - max mismatches within the seed (see the 'seed' above). Allowed 0,1,2,3 mismatches in bowtie1 - default 2, allowed 0,1 in bowtie2 (per each multi-seed alignment) - default 0. "
echo "--maqerr 70 - only in Bowtie1 - max total quality values at all mismatched read positions throughout the entire alignment (not just in seed)"
echo ""
echo "ADAPTER TRIMMING SETTINGS"
echo "--trim/noTrim** (run/do-not-run TrimGalore for the data - Illumina PE standard adapter filter, trims on 3' end)"
echo "**) NOTE : use --noTrim with caution - the data will go through FLASH : this can result in combining reads on the sites of ADAPTERS instead of the reads themselves."
echo "--ada3read1 SEQUENCE --ada3read2 SEQUENCE  : custom adapters 3' trimming, R1 and R2 (give both) - these adapters will be used instead of Illumina default / atac adapters. SEQUENCE has to be in CAPITAL letters ATCG"
echo "--ada5read1 SEQUENCE --ada5read2 SEQUENCE  : custom adapters 5' trimming, R1 and R2 (give both) - these adapters will be used instead of Illumina default / atac adapters. SEQUENCE has to be in CAPITAL letters ATCG"
echo ""
echo "QUALITY TRIMMING SETTINGS"
echo "--qmin 20 (trim low quality reads up-to this phred score) - sometimes you may want to rise this to 30 or so"
echo ""
echo "FLASH SETTINGS"
echo "--flashBases 10 (when flashing, has to overlap at least this many bases to combine)"
echo "--flashMismatch 0.25 (when flashing, max this proportion of the overlapped bases are allowed to be MISMATCHES - defaults to one in four allowed to be mismatch, i.e. 0.25 )"
echo "                      sometimes you may want to lower this to 0.1 (one in ten) or 0.125 (one in eight) or so"
echo ""
echo "SAVE IN-SILICO DIGESTED WHOLE-GENOME FILE"
echo "--saveGenomeDigest"
echo "(to save time in your runs : add the output file to your digests folder, and update your conf/config.sh  !)"
echo ""
echo "AMPLICON LENGHT"
echo "--ampliconSize 300 (how far from RE enzyme cut site reach the 'valid fragments'. This is the max expected library fragment size after amplicon.)"
echo "--sonicationSize 300 (synonymous to --ampliconSize)"
echo
echo "CAPTURE-C ANALYSER OPTIONS"
echo "--useSymbolicLinks (use symbolic links between run directory and public directory to store bigwig files, "
echo "   instead of storing the bigwigs straight in the public directory)"
echo "--onlyCis (to analyse only cis-mapping reporters : this flag also affects BLAT OUTPUT FILES, see below)"
echo "-s Sample name (and the name of the folder it goes into)"
echo "--snp : snp-specific run (check your capture-site (REfragment) coordinates file that you have defined the SNPs there)"
echo "--globin : combine captures globin capture sites :"
echo "  To combine ONLY alpha globin  :  --globin 1 (name your globin capture sites Hba-1 and Hba-2)"
echo "-s Sample name (and the name of the folder it goes into)"
echo
echo "WINDOWING IN CAPTUREC ANALYSER SCRIPT"
echo "Default windowing is 200b window and 20b increment"
echo "-w 200   or   --window 200  : custom window size (instead of default 200b)."
echo "-i 20    or   --increment 20 : custom window increment (instead of default 20b). "
echo
echo "BLAT FILTERING - blat parameters :"
echo "blat -oneOff=0 -minScore=10 -maxIntron=4000 -tileSize=11 -stepSize=5 -minIdentity=70 -repMatch=999999"
echo
echo "BLAT OPTIONS :"
echo "--onlyCis (to generate blat-filtering files for only cis chromosomes : this flag also affects CAPTURE-C ANALYSER, see above)"
echo "--stepSize 5 (spacing between tiles). if you want your blat run faster, set this to 11."
echo "--tileSize 11 (the size of match that triggers an alignment)"
echo "--minScore 10 (minimum match score)"
echo "--maxIntron 4000 (to make blat run quicker) (blat default value is 750000) - max intron size"
echo "--oneOff 0 (set this to 1, if you want to allow one mismatch per tile. Setting this to 1 will make blat slow.)"
echo "--BLATforREUSEfolderPath /full/path/to/previous/F4_blatPloidyFilteringLog_CC4/BlatPloidyFilterRun/REUSE_blat folder"
echo "   (enables previously ran BLAT for the same capture-site (REfragment)s, to be re-used in the run)"
echo
echo "CAPTURE-C BLAT + PLOIDY FILTERING OPTIONS"
echo "--extend 20000  Extend the Blat-filter 20000bases both directions from the psl-file regions outwards. (default 20 000)"
echo "--noPloidyFilter  Do not filter for ploidy regions (Hughes lab peak call for mm9/mm10, Duke Uni blacklisted for hg18/hg19, other genomes don't have ploidy track provided in pipeline)"
echo
echo "CAPTURE-C DUPLICATE FILTERING OPTIONS"
echo "--CCversion CM5 : Which duplicate filtering is to be done : CM3 (for short sequencing reads), CM4 (long reads), CM5 (any reads). "
echo "--strandSpecificDuplicates : To replicate the strand-specific (i.e. wrong) duplicate filter of CB3a/CC3 and CB4a/CC4"
echo "--UMI : Use UMI-style duplicate filtering."
echo "--wobblyEndBinWidth 20 : to set bin width for non-exact fragment-end coordinates."
echo "   To turn wobbly ends off, set this to 1 ( --wobblyEndBinWidth 1 )."
echo "   Especially if using --UMI , --wobblyEndBinWidth 20 is recommended."
echo "   For example : --wobblyEndBinWidth 20 means : bin of 20 bases for duplicate filter :"
echo "   if all fragment coordinates are the same +/- 10 bases, ( and if --UMI is used : UMI is the same), reads are duplicates."
echo
echo "CAPTURE-C ANALYSER DEVELOPER OPTIONS"
echo "--dump : Print file of unaligned reads (sam format)"
echo "--limit n  : only analyse the first 'n' reads - for testing purposes "
echo

#echo "More info : hands-on tutorial : http://userweb.molbiol.ox.ac.uk/public/telenius/MANUAL_for_pipe_030214/DnaseCHIPpipe_TUTORIAL.pdf, comprehensive user manual : http://userweb.molbiol.ox.ac.uk/public/telenius/MANUAL_for_pipe_030214/DNasePipeUserManual_VS_100_180215.pdf , and comment lines (after the subroutine descriptions) in the script ${DNasePipePath}/DnaseAndChip_pipe_1.sh"
echo 
 

 
 exit 0
    
}

