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

use strict;
use Cwd;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

# Testing purposes - subs in different file ..
# require "./subseparate.pl";  # assuming it's in the current directory
# require "./analysisloopsub.pl";  # assuming it's in the current directory

#use List::MoreUtils 'true';

=head1 NAME

 CCanalyser.pl

=head1 SYNOPSIS

  This script uses a sam file as input.  This needs to have been generated as follows:
  1. Perform adaptor trimming of the raw fastq files if this has not been performed by the sequencer.  I tend to use trim_galore to do this with the paired settings.   For example: nohup trim_galore --paired Paired_end_1.fastq Paired_end_2.fastq&

  2. If you are using 150 bp paired end reads from the Miseq then the overlapping reads need to be merged.  I use FLASH to do this.  For example
    module load flash
    nohup flash --interleaved-output Paired_end_1.fq Paired_end_2.fq&
    Then concatenate the separate files of merged and unmerged reads:
    cat out.notCombined.fastq out.extendedFrags.fastq -> Combined_reads.fastq
    
  3. If you sequence the data with reads that are shorter than the fragments then you may not need to merge the reads with flash but you will need to merge the reads from the PE1 and PE2 by interleaving them making sure that the order of the reads is maintained.
 
  4. I normally align the fastq files with bowtie using one processor only because it is crucial that the reads are kept in strict order otherwise the script will not function properly.
    If you use more than one processor then it is crucial the reads are sorted so that they are ordered by name.
    The script only parses the first digit in the cigar string, which should be fine with bowtie but be careful with other aligners (it will only take the first digit if the cigar is 20M29M
    I tend to use m2, best and strata � but this is partly because m2 is needed otherwise all of the reads for alpha globin will be thrown (because of the gene duplication) so you may well want to use your own setting.
    I would use 'best' so that each read can only align once otherwise each read could be counted many times. 
    For example:
    nohup bowtie -p 1 -m 2 --best --strata --sam --chunkmb 256 --sam /databank/indices/bowtie/mm9/mm9 Sample_REdig.fastq Sample_REdig.sam &
    
  The script needs to have two other input files:
  1. A file of all of the restriction enzyme fragments in the genome.  This is best made using the script dpngenome.pl.
    The coordinates are of the middle of the restriction fragment in the format chr:start-stop
  
  2. A file of the input coordinates of the capture capturesitenucleotides it needs to in the following 9 column tab separated format.
    Be careful to ensure the /n new line is used rather than /r (as can be inserted by excel for example).
          1. Name of capture (avoid spaces in the names please)
          2. Chromosome of capture fragment
          3. Start coordinate of capture fragment
          4. End of capture fragment
          5. Chromosome of proximity exclusion
          6. Start coordinate of proximity exclusion
          7. End coordinated of proximity exclusion
          8. Position of SNP
          9. Base of SNP

  The script requires the perl modules Data::Dumper; Getopt::Long and Pod::Usage and it needs wigToBigWig.
  Depending on your system setup you may need to load wigToBigWig BEFORE running this script with the command module load ucsctools
  
  This script will create a subdirectory (of the directory the script is in) named after the sample and it will put into this wig, windowed wig and sam files of all of the reads that are to be reported
  It also outputs a sam file of all of the reads mapping to the capture region.
  In addition it outputs 2 report files.  One containing the statistics and the other containing the data relating to exclusion of duplicates.
  The script will convert the wig files to bigwig, copy them to your public folder and generate a track hub so that all you need to do is paste the url
  for the track hub into the UCSC genome browser to see the data.

=head1 EXAMPLE

 CCanalyser.pl -f input_sam_file.sam -o input_capturesite_file.txt -r input_restriction_enzyme_coordinates_file.txt -s short_sample_name -pf public_folder -pu public_url
 

=head1 OPTIONS

 -f             Input filename 
 -r             Restriction coordinates filename 
 -o             Capturesitenucleotide position filename 
 -pf            Your public folder (e.g. /hts/data0/public/username)
 -pu            Your public url (e.g. sara.molbiol.ox.ac.uk/public/username)
 -s             Sample name (and the name of the folder it goes into)
 -w             Window size (default = 2kb)
 -i             Window increment (default = 200bp)
 -dump          Print file of unaligned reads (sam format)
 -snp           Force all capture points to contain a particular SNP
 -limit         Limit the analysis to the first n reads of the file
 -genome        Specify the genome (mm9 / hg18)
 -globin        Combines the two captures from the gene duplicates (HbA1 and HbA2)
 -flashed       1 or 0 (are the reads in input sam combined via flash or not ? - run out.extended with 1 and out.not_combined with 0)
 -duplfilter    1 or 0 (will the reads be duplicate diltered or not ? )
 -ucscsizes     Genome sizes file
 -symlinks      To make symbolic links to bigwigs into the public area, instead of actually storing the bigwigs there. The symlink data folder is first part of $sample name (before first underscore)
 -stringent     enforces additional stringency - forces all reported subfragments to be unique
 -CCversion     Cb3 or Cb4 or Cb5 (will the reads be duplicate filtered CC3 or CC4 or CC5 style ? )
 -stranded      To replicate the strand-specific (i.e. wrong) duplicate filter of CB3a/CC3 and CB4a/CC4
 -umi           Run contains UMI indices - alter the duplicate filter accordingly : ask Damien Downes how to prepare your files for pipeline, if you are interested in doing this
 -wobble 1      Wobble bin width. default 1(turned off). UMI runs recommendation 20, i.e. +/- 10bases wobble. to turn this off, set it to 1 base.
 -tiled         Tiled capture analysis : do not filter stuff which contains only capture fragments (each tile is to be given as one region) - these are valid fragments
  
=head1 AUTHOR

 Original release written by James Davies June 2014 (CC2)
 Next release was by Jelena Telenius October 2015 (CC3),
 and further to new release (CC4) by Jelena Telenius March 2016
 and further to new release (CF5) by Jelena Telenius Nov 2017
 and further to new release (CS5) by Jelena Telenius Nov 2017
 and further to new release (CB5) by Jelena Telenius Nov 2017
 and further to this release (CP5) by Jelena Telenius Feb 2018
 

=cut

# Hardcoded parameters :
my $email = 'jelena.telenius@gmail.com';
my $version = "CM5";

# Obligatory parameters :
my $capturesite_filename = "UNDEFINED";

my $exclusion_filename = "UNDEFINED";

# The bigwig_folder is overwritten below if -ucscsizes input parameter is given : this is not "really" hardcoded (pipeline use of this code overwrites the below automatically)
my $bigwig_folder = "/t1-data/user/config/bigwig";
# If we don't set this via the command line argument, we will set it just after
my $ucscsizes="UNDEFINED";

my $restriction_enzyme_coords_file ="UNDEFINED";#Specifies filename of restriction coordinates (file made by dpngenome2.pl)
my $genome = "UNDEFINED";

# Optional parameters :
my $public_folder = "DATA_FOR_PUBLIC_FOLDER";
my $public_url = "UNDETERMINED_SERVER/DATA_FOR_PUBLIC_FOLDER";

# Parameters with hardcoded default value :
my $window = 2000;
my $increment = 200;
my $sample = "CaptureC";
my $use_dump =0; #whether to create an output file with all of the non-aligning sequences
my $use_snp=0; #whether to use the SNP specified in the the input file
my $use_stranded=0; # whether we do the brain fart strand specific duplicate filter or not (CB4 CB3 CC3 CC4 do it strand specific)
my $use_limit=0; #whether to limit the script to analysing the first n lines
my $use_symlinks=0; #whether to use symlinks to store bigwigs or not
my $globin = 0; #whether to include the part of the script that combines the HbA1 and 2 tracks
my $stringent = 0;
my $flashed = 1;
my $duplfilter = 1;
my $use_parp = 0; # whether this is parp run or not (parp artificial chromosome to be filtered before visualisation files)
my $use_umi = 0; # whether this is UMI run or not, if yes, filter based on UMI indices : ask Damien Downes how to prepare your files for pipeline, if you are interested in doing this
my $wobble_bin_width = 20 ; # wobble bin width. default 1(turned off). UMI runs recommendation 20, i.e. +/- 10bases wobble. to turn this off, set it to 1 base.
my $only_cis = 0 ; # analysing only cis-reads (easing up the computational load for many-capturesite samples which continue straight to PeakC which is essentially a cis program)
my $capturesites_per_bunch = 100; # How many capturesites we have per folder, per one thread of the parallel run, per .. (shortly : the parallelisation unit)
my $cutter_type = "fourcutter"; # If we have fourcutter (symmetric fourcutter like dpnII or nlaIII), if we have sixcutter (asymmetric sixcutter 1:5 like hindIII)

# If most things are to be skipped (only generating bams for output - parallel run first stage) ..
my $only_divide_bams = 0;

# If only generating blat filter parameter file :
my $only_filtering_params = 0;
# If only generating capturesite division listing for blat runs parallelisation :
my $only_divide_capturesites = 0;

# If first step of tiled analysis :
my $tiled_analysis = 0;

# If the normalised bigwigs are to be generated as well - parallel run last stage.
my $normalised_tracks = 0;

# Code excecution start values :
my $analysis_read;
my $last_read="first";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(); #defines the start time of the script (printed out into the report file later on)

# Without default values - defined here for visibility reasons
my $input_filename_path="UNDEFINEDFILENAMEPATH";
my $input_path="UNDEFINEDPATH";
my $input_filename="UNDEFINEDFILENAME";
my $store_bigwigs_here_folder="UNDETERMINED_BIGWIG_FOLDER";
my $help=0;
my $man=0;

my $prefix_for_output="UNDEF"; # to set default.

# Arrays
my @capturesite_data; # contains the data for the positions of the capturesites and the exclusion limits - or only the capturesite in question (for parallel runs last step)
my @exclusion_data; # contains the data for the positions of the capturesites and the exclusion limits - parallel runs last step only
my @samheadder; # contains the headder of the sam file

# Hashes of arrays
my %dpn_data; # contains the list of DpnII fragments in the genome

# Hashes
my %data; # contains the parsed data from the sam file
my %samhash; # contains the output data for a sam file
my %fraghash; # contains the output data for each fragment, which is used to generate a wig and a mig file
my %coords_hash=(); # contains a list of all the coordinates of the mapped reads to exclude duplicates
my %counters;  # contains the data for all the counters in the script, which is outputted into the report file
my %finalcounters;  # contains the data for all the counters in the script, which is outputted into the report file
my %finalrepcounters;  # contains the data for all the counters in the script, which is outputted into the report file
my %nonflashedcounters;  # contains the counter for non-flashed-reads coordinate reassignment
my %counter_helpers; # contains some counters, for which values are iterated over the while loop, and then in the end added ot %counters hash for printing
my %cap_samhash;
my %duplicates;
my %capturesite_bunch_numbers;

# Looper testers

my $analysedReads=0;
my $notlastFragments=0;

print STDOUT "\n" ;
print STDOUT "Capture C analyser - version $version !\n" ;
print STDOUT "Developer email $email\n" ;
print STDOUT "\n" ;


# The GetOptions from the command line
&GetOptions
(
 "f=s"=>\ $input_filename_path,          # -f Input filename 
 "r=s"=>\ $restriction_enzyme_coords_file,  # -r Restriction coordinates filename 
 "o=s"=>\ $capturesite_filename,                  # -o Capturesitenucleotide position filename : all capturesites (normal runs), only a single capturesite (parallel runs last step)
 "e=s"=>\ $exclusion_filename,              # -e Capturesitenucleotide position filename : the "other capturesites" (parallel runs last step)
 "pf=s"=>\ $public_folder,                  # -pf Your public folder (e.g. /hts/data0/public/username)
 "pu=s"=>\ $public_url,                     # -pu Your public url (e.g. sara.molbiol.ox.ac.uk/public/username)
 "s=s"=>\ $sample,                          # -s Sample name (and the name of the folder it goes into)
 "w=i"=>\ $window,                          # -w Window size (default = 2kb)
 "i=i"=>\ $increment,                       # -i Window increment (default = 200bp)
 "dump"=>\ $use_dump,                       # -dump Print file of unaligned reads (sam format)
 "snp"=>\ $use_snp,                         # -snp Force all capture points to contain a particular SNP
 "parp"=>\ $use_parp,                       # -parp Run contains artificial chromosome PARP, which is to be removed before visualisation
 "umi"=>\ $use_umi,                         # -umi Run contains UMI indices - alter the duplicate filter accordingly : ask Damien Downes how to prepare your files for pipeline, if you are interested in doing this
 "onlycis"=>\ $only_cis,                    # -onlycis analysing only cis-reads (easing up the computational load for many-capturesite samples which continue straight to PeakC which is essentially a cis program)
 "wobble=i"=>\ $wobble_bin_width,           # -wobble This is the wobble bin width. UMI runs recommendation 20, i.e. +/- 10bases wobble. to turn this off, set it to 1 base.
 "limit=i"=>\ $use_limit,                   # -limit Limit the analysis to the first n reads of the file
 "stranded"=>\ $use_stranded,               # -stranded To replicate the strand-specific (i.e. wrong) duplicate filter of CB3a/CC3 and CB4a/CC4
 "genome=s"=>\ $genome,                     # -genome Specify the genome (mm9 / hg18)
 "ucscsizes=s"=>\ $ucscsizes,               # -ucscsizes Genome sizes file ( if not taken from the default location with the fancy naming scheme )
 "globin=i"=>\ $globin,                     # -globin Combines the two captures from the gene duplicates (HbA1 and HbA2=1 ; Both alpha and beta globin =2)
 'h|help'=>\$help,                          # -h or -help Help - prints the manual
 'man'=>\$man,                              # -man prints the manual
 'stringent'=>\$stringent,                  # -stringent enforces additional stringency - forces all reported subfragments to be unique
 "flashed=i"=>\ $flashed,                   # -flashed 1 or 0 (are the reads in input sam combined via flash or not ? - run out.extended with 1 and out.not_combined with 0)
 "duplfilter=i"=>\ $duplfilter,             # -duplfilter 1 or 0 (will the reads be duplicate diltered or not ? )
 "CCversion=s"=>\ $version,                 # -CCversion Cb3 or Cb4 or Cb5 (will the reads be duplicate filtered CC3 or CC4 or CC5 style ? )
 "onlycapturesitebunches"=>\ $only_divide_bams,   # Just mark the fragments belonging to different capturesite bunch - parallel run first step
 "onlyparamsforfiltering"=>\ $only_filtering_params,   # Just generate parameters for filtering run.
 "onlycapturesitefile"=>\ $only_divide_capturesites,    # Just mark the capturesites belonging to different capturesite bunch - parallel run blat preparation
 "tiled"=>\ $tiled_analysis,                # Tiled capture analysis : do not filter stuff which contains only capture fragments (each tile is to be given as one region) - these are valid fragments 
 "capturesitesperbunch=i"=>\ $capturesites_per_bunch,   # When the above $only_divide_bams is in action - how many capturesites per visualisation unit (i.e. parallelisation unit i.e. output folder). Default 100.
 "normalisedtracks"=>\ $normalised_tracks,  # Make also normalised bigwigs - parallel run last step
 "symlinks"=>\ $use_symlinks,	            # -symlinks	To make symlinks to bigwigs into the public area, instead of actually storing the bigwigs there.
 "cutter=s"=>\ $cutter_type,	            # If we have fourcutter (symmetric fourcutter like dpnII or nlaIII - this is default), if we have sixcutter (asymmetric sixcutter 1:5 like hindIII)

);

pod2usage(1) if $help;
pod2usage(-verbose=>2) if $man;

# If symlinks were requested, setting stuff ..
if ($use_symlinks)
{
$store_bigwigs_here_folder="PERMANENT_BIGWIGS_do_not_move";
}
else
{
$store_bigwigs_here_folder=$public_folder;
}

# Printing out the parameters in the beginning of run - Jelena added this 220515

print STDOUT "Starting run with parameters :\n" ;
print STDOUT "\n" ;

print STDOUT "capturesite_filename $capturesite_filename\n";
print STDOUT "sample $sample\n" ;
print STDOUT "version $version\n";

# If we just generate the filtering params, we don't care about other output (even to the log files) ..
if ( ( ! $only_filtering_params ) && ( ! $only_divide_capturesites ) ){

# Fetching the genome sizes elsewhere .. (if ucscsizes was not defined ..)
if ( ($ucscsizes eq "UNDEFINED") && ($use_parp==1)){
  $bigwig_folder = "/t1-data/user/hugheslab/telenius/GENOMES/PARP";
}

# Getting rid of the last hard-coded parameter with this, but still allowing the "fancy auto-setter" below, should somebody want to run this as stand-alone script :
if ( $ucscsizes eq "UNDEFINED"){
  $ucscsizes="$bigwig_folder/$genome\_sizes.txt"
}

print STDOUT "store_bigwigs_here_folder $store_bigwigs_here_folder \n" ;
print STDOUT "public_folder $public_folder \n" ;
print STDOUT "public_url $public_url \n";
print STDOUT "ucscsizes $ucscsizes\n" ;
print STDOUT "email $email\n" ;

print STDOUT "input_filename_path $input_filename_path\n";
print STDOUT "flashed $flashed (1 or 0 - if this is sam file from out.extended (1) or out.not_combined (0) )\n";
print STDOUT "duplfilter $duplfilter (1 or 0)\n";
print STDOUT "duplicate filtering style : $version \n" ;
print STDOUT "restriction_enzyme_coords_file $restriction_enzyme_coords_file \n";
print STDOUT "window $window \n";
print STDOUT "increment $increment \n";
print STDOUT "use_dump $use_dump\n";
print STDOUT "use_snp $use_snp\n";
print STDOUT "use_stranded $use_stranded\n";
print STDOUT "use_limit $use_limit\n";
print STDOUT "genome $genome\n";
print STDOUT "globin $globin \n"; 
print STDOUT "stringent $stringent \n";
print STDOUT "only_cis $only_cis \n";
print STDOUT "use_umi $use_umi \n";
print STDOUT "wobble_bin_width $wobble_bin_width \n";
print STDOUT "normalised_tracks $normalised_tracks \n";

}

print STDOUT "only_divide_bams $only_divide_bams \n";
print STDOUT "only_divide_capturesites $only_divide_capturesites \n";
print STDOUT "capturesites_per_bunch $capturesites_per_bunch \n";

my $parameter_filename = "parameters_for_filtering.log";
unless (open(PARAMETERLOG, ">$parameter_filename")){die "Cannot open file $parameter_filename $! , stopped "};

print PARAMETERLOG "public_folder $public_folder \n" ;
print PARAMETERLOG "capturesite_filename $capturesite_filename\n";

if ( $exclusion_filename != "UNDEFINED" ){
print PARAMETERLOG "exclusion_filename $exclusion_filename\n";  
}

print PARAMETERLOG "sample $sample\n" ;
print PARAMETERLOG "restriction_enzyme_coords_file $restriction_enzyme_coords_file \n";
print PARAMETERLOG "version $version\n";
print PARAMETERLOG "genome $genome\n";
print PARAMETERLOG "globin $globin \n";

# If we just generate the filtering params, we don't care about other output (even to the log files) ..
if ( ( ! $only_filtering_params ) && ( ! $only_divide_capturesites ) ){

pod2usage(2) unless ($input_filename_path); 

# Check parameters - fail if obligatory ones not given :

pod2usage(2) unless ($input_filename_path);
if ( ($capturesite_filename eq "UNDEFINED") or ($restriction_enzyme_coords_file eq "UNDEFINED") or ($genome eq "UNDEFINED") ) { pod2usage(2);}

}

print STDOUT "\n";
print STDOUT "Generating output folder.. \n";

# Creates a folder for the output files to go into - this will be a subdirectory of the file that the script is in
my $current_directory = cwd;
my $output_path= "$current_directory/$sample\_$version";

print PARAMETERLOG "datafolder $output_path \n";

if (!$only_filtering_params){
if (-d $output_path){}
else {mkdir $output_path};
# We don't want to chdir - as otherwise RELATIVE file paths will not work.
#chdir $output_path;
}

if ( $only_divide_bams ){
my $bunches_output_path= "$current_directory/$sample\_$version/DIVIDEDsams";
print STDOUT "divided_datafolder $bunches_output_path \n";
if (-d $bunches_output_path){}
else {mkdir $bunches_output_path};
}


if ( $only_divide_bams || $only_divide_capturesites ){
my $bunches_capturesites_output_path= "$current_directory/$sample\_$version/DIVIDEDcapturesites";
print STDOUT "divided_capturesitefolder $bunches_capturesites_output_path \n";

if (-d $bunches_capturesites_output_path){
# Remove existing files (flashed and nonflashed update same files)
unlink glob $bunches_capturesites_output_path."/*";
}
else {mkdir $bunches_capturesites_output_path}; 
}


# ___________________________________________

if ( (!$only_divide_bams) && (!$only_divide_capturesites) ) {

# If user did not define public folder - setting public files to be saved in the output folder :
if ( $public_folder eq "DATA_FOR_PUBLIC_FOLDER" )
{
  mkdir "$output_path/DATA_FOR_PUBLIC_FOLDER"; 
  #print STDOUT "\nPublic url and/or public folder location not set - printing visualisation files to output directory $output_path/VISUALISATION_FILES\n";
  print STDOUT "\nPublic folder location not set - printing visualisation files to output directory $output_path/DATA_FOR_PUBLIC_FOLDER\n";
  $public_folder="$output_path/DATA_FOR_PUBLIC_FOLDER";
}


# Make the upper folder for bigwigs
if (!$only_filtering_params){
  
if (-d $store_bigwigs_here_folder){}
else {mkdir $store_bigwigs_here_folder};

# Make the inner folder for bigwigs
if ($use_symlinks)
{
# RAW FILTERED etc are the first part of the name, before first underscore.
my @splitted_sample = split /_/,$sample ;
my $bigwig_subfolder = $splitted_sample[0];
$store_bigwigs_here_folder=$store_bigwigs_here_folder."/".$bigwig_subfolder;
if (-d $store_bigwigs_here_folder){}
else {mkdir $store_bigwigs_here_folder};
}
}

}
# ___________________________________________

# Data prefix print - depending on run type

print STDOUT "Opening input and output files.. \n";

if ( (!$only_filtering_params) && (!$only_divide_capturesites) ){
  
#Splits out the filename from the path
$input_filename=$input_filename_path;
if ($input_filename =~ /(.*)\/(\V++)/) {$input_path = $1; $input_filename = $2};
unless ($input_filename =~ /(.*).sam/) {die"filename does not match .sam, stopped "};
# Creates files for the a report and a fastq file for unaligned sequences to go into
$prefix_for_output = $1;

print PARAMETERLOG "dataprefix $prefix_for_output\_$version \n";

}

print PARAMETERLOG "foldername $sample\_$version \n";

close PARAMETERLOG ;

# ___________________________________________

# Early exit for $only_filtering_params
if ($only_filtering_params){

exit ;

}

# ___________________________________________

my $outputfilename = "$sample\_$version/$prefix_for_output";

# Prints the statistics into the report file
my $report_filename = $outputfilename."_report_$version.txt";
my $report2_filename = $outputfilename."_report2_$version.txt";
my $report3_filename = $outputfilename."_report3_$version.txt";
my $report4_filename = $outputfilename."_report4_$version.txt";

my $capturesite_bunch_count_filename = $outputfilename."_capturesitebunchCount_".$version.".txt";
my $header_sam_filename = $outputfilename."_header_".$version.".sam";
my $all_sam_filename = $outputfilename."_all_capture_reads_".$version.".sam";
# my $all_typed_sam_filename = $outputfilename."_all_typed_reads_$version.sam";
my $cap_sam_filename = $outputfilename."_reported_capture_reads_".$version.".sam";
my $coord_filename = $outputfilename."_coordstring_$version.txt";

# For the rest of the script, adding the version to the end ..
$outputfilename = "$sample\_$version/$prefix_for_output\_$version";


if ($use_dump) {
unless (open(DUMPOUTPUT, ">$outputfilename\_dump.fastq")){die "Cannot open file $outputfilename\_dump.sam , stopped ";}
}
# unless (open(ALLSAMFH, ">$all_sam_filename")){die "Cannot open file $all_sam_filename , stopped ";};
# unless (open(ALLTYPEDSAMFH, ">$all_typed_sam_filename")){die "Cannot open file $all_sam_filename , stopped ";}

if ( !($only_divide_bams) && !($only_divide_capturesites) ){
unless (open(CAPSAMFH, ">$cap_sam_filename")){die "Cannot open file $cap_sam_filename , stopped ";}; 
# unless (open(COORDSTRINGFH, ">$coord_filename")){die "Cannot open file $coord_filename , stopped ";};
}

print STDOUT "Loading in capturesite coordinate file.. \n";

# Uploads coordinates of capture capturesites and exclusion regions into the array @capturesite_data
# 0=name; 1=capture chr; 2 = capture start; 3 = capture end; 4= exclusion chr; 5 = exclusion start; 6 = exclusion end; 7 = snp position; 8 = SNP sequence
open(CAPTURESITEFH, $capturesite_filename) or die "Cannot open file $capturesite_filename , stopped ";
#Splits out the filename from the path
my $capturesite_file=$capturesite_filename; my $capturesite_path;
if ($capturesite_file =~ /(.*)\/(\V++)/) {$capturesite_path = $1; $capturesite_file = $2};
unless ($capturesite_file =~ /(.*)\.(.*)/) {die"Cant regex capturesite filename"};
my $capturesite_basename = $1;
my $capturesite_bed_out_filename = "$sample\_$version/".$capturesite_basename.".bed";

# ___________________________________________
if ( !($only_divide_bams) && !($only_divide_capturesites) ){
unless (open(CAPTURESITEBED, ">$capturesite_bed_out_filename")){die "Cannot open capturesite_bed out file $capturesite_bed_out_filename\n";}
print CAPTURESITEBED "track name=CaptureC_capturesites description=CaptureC_capturesites visibility=1 itemRgb=On\n";

if ($use_snp)
{
print STDOUT "\nname\tchr\tstr\tstp\tchr\tstr\tstp\tpos\tbase\tcapturesiteLinesIn\tcapturesiteLinesSaved\n";
}
else
{
print STDOUT "\nname\tchr\tstr\tstp\tchr\tstr\tstp\tcapturesiteLinesIn\tcapturesiteLinesSaved\n";
}
}
# ___________________________________________


my $temp_line_counter=0;
my $temp_capturesite_bunch_number=1;
while ( my $wholeline = <CAPTURESITEFH> )
{
  chomp $wholeline;
  
  my @line = split /\s++/, $wholeline;
  push @capturesite_data, [ @line ];
  $temp_line_counter++;
  $counters{"01 Number of capture sites loaded:"}++;
  
	
  # And now - check for existence for all columns..
  unless (defined($line[0]) && defined($line[1]) && exists($line[2]) &&  exists($line[3]) && defined($line[4]) && exists($line[5]) && exists($line[6])) {die "Cannot parse capturesite coordinate file (cannot find the 7 first columns)\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  if ($use_snp) {
    unless ( exists($line[7]) && defined($line[8])) {die "Cannot parse SNP columns of capturesite coordinate file \n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  }
  # File format check and cleanup for wrong kind of data :
  # Capturesite file format is :
  # 0    1   2   3   4   5   6   7   8
  # name chr str stp chr str stp pos base
  
  #str stp str stp
  if ( ! ( ($line[2] =~ /^\d+$/) || ($line[2] == 0) ) ) {die "Capturesite RE fragment start coordinate (3rd column) not numeric\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  if ( ! ( ($line[3] =~ /^\d+$/) || ($line[3] == 0) ) ) {die "Capturesite RE fragment end coordinate (4th column) not numeric\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  if ( ! ( ($line[5] =~ /^\d+$/) || ($line[5] == 0) ) ) {die "Exclusion region start coordinate (6th column) not numeric\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";} 
  if ( ! ( ($line[6] =~ /^\d+$/) || ($line[6] == 0) ) ) {die "Exclusion region end coordinate (7th column) not numeric\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  
  # chr chr
  #if ( ! ($line[1] =~ /^chr\w+$/) ) {die "Chromosome name of RE fragment (2nd column) not proper format \n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  #if ( ! ($line[4] =~ /^chr\w+$/) ) {die "Chromosome name of exclusion region(5th column) not proper format In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  if ( ! ( ($line[1] =~ /^\w+$/)) ) {die "Chromosome name of RE fragment (2nd column) not proper format \n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  if ( ! ( ($line[4] =~ /^\w+$/)) ) {die "Chromosome name of exclusion region(5th column) not proper format In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  
  if ( ! ($line[1] eq $line[4]) ) {die "Chromosome of RE fragment and its exclusion (2nd column and 5th column) are different chromosomes - not allowed ! \n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}

  # name - all weird characters plus whitespace is worth of death :)
  if ( !($line[0] =~ /^[a-zA-Z0-9\-\_]+$/ )  ) {die "Capturesite name contains whitespace or weird characters. Only allowed to have numbers[0-9], letters[a-zA-Z] and underscore [_] \n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  
  if ($use_snp) {
    if ( ! ( ($line[7] =~ /^\d+$/) || ($line[7] == 0) ) ) {die "SNP coordinate (8th column) not numeric\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
    if ( !($line[8] =~ /^[ATCG]$/) ) {die "SNP base (9th column) is not [ATCG]\n In file:\n".$capturesite_path."/".$capturesite_file." , stopped ";}
  }

  # bunch_numbers{capturesitename}=1 (writing down which bunch the capturesite belongs to)
  $capturesite_bunch_numbers{$line[0]} = $temp_capturesite_bunch_number;
  
# ___________________________________________
if ( (!$only_divide_bams) && (!$only_divide_capturesites) ){
  print CAPTURESITEBED "chr$line[1]\t".($line[2]-1)."\t$line[3]\t$line[0]\t1\t+\t$line[2]\t$line[3]\t133,0,122\n";
  print CAPTURESITEBED "chr$line[4]\t".($line[5]-1)."\t$line[6]\t$line[0]\t1\t+\t$line[5]\t$line[6]\t133,0,0\n";
  
 print STDOUT "\nCapturesite number : $temp_line_counter ------------------------------------------------------------------";
  if ($use_snp)
  {
  print STDOUT "\n$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$line[7]\t$line[8]\t$temp_line_counter\t".scalar(@capturesite_data)."\n";
  }
  else
  {
  print STDOUT "\n$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t$line[6]\t$temp_line_counter\t".scalar(@capturesite_data)."\n";
  }
  print STDOUT "---------------------------------------------------------------------------------------------------";
 }
else{
  unless (open(BUNCHFILE, ">>$sample\_$version/DIVIDEDcapturesites/$capturesite_basename\_BUNCH_$temp_capturesite_bunch_number\.txt")){die "Cannot open file $capturesite_basename\_BUNCH_$temp_capturesite_bunch_number\.txt , stopped ";};
  print BUNCHFILE $wholeline."\n";
  close BUNCHFILE ;   
}
# ___________________________________________

  # For parallel code, we need to know how manyeth capturesite bunch we are dealing with.
  # This is done also for serial run, as this hash is small.
  if ( $temp_line_counter%$capturesites_per_bunch == 0 ){
   $temp_capturesite_bunch_number++;
  }

};
close CAPTURESITEFH ;
close CAPTURESITEBED ;

# Parallel runs last step - exclusions defined in a different manner !


if ( $exclusion_filename ne "UNDEFINED" ){
my $exclusion_file;my $exclusion_path;my $exclusion_basename;
# Uploads coordinates of capture capturesites and exclusion regions into the array @exclusion_data
# 0=name; 1=capture chr; 2 = capture start; 3 = capture end; 4= exclusion chr; 5 = exclusion start; 6 = exclusion end; 7 = snp position; 8 = SNP sequence
open(EXCLUSIONFH, $exclusion_filename) or die "Cannot open file $exclusion_filename , stopped ";
#Splits out the filename from the path
$exclusion_file=$exclusion_filename; 
if ($exclusion_file =~ /(.*)\/(\V++)/) {$exclusion_path = $1; $exclusion_file = $2};
unless ($exclusion_file =~ /(.*)\.(.*)/) {die"Cant regex capturesite filename"};
$exclusion_basename = $1;
my $exclusion_bed_out_filename = "$sample\_$version/".$exclusion_basename.".bed";

unless (open(EXCLUSIONBED, ">$exclusion_bed_out_filename")){die "Cannot open capturesite_bed out file $exclusion_bed_out_filename\n";}
print EXCLUSIONBED "track name=CaptureC_exclusions description=CaptureC_exclusions visibility=1 itemRgb=On\n";

while ( my $wholeline = <EXCLUSIONFH> )
{
  chomp $wholeline;
  
  my @line = split /\s++/, $wholeline;
  push @exclusion_data, [ @line ];
  $counters{"01 Number of exclusion sites loaded:"}++;
  
	
  # And now - check for existence for all columns..
  unless (defined($line[0]) && defined($line[1]) && exists($line[2]) &&  exists($line[3]) && defined($line[4]) && exists($line[5]) && exists($line[6])) {die "Cannot parse capturesite coordinate file (cannot find the 7 first columns)\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  if ($use_snp) {
    unless ( exists($line[7]) && defined($line[8])) {die "Cannot parse SNP columns of capturesite coordinate file \n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  }
  # File format check and cleanup for wrong kind of data :
  # Capturesite file format is :
  # 0    1   2   3   4   5   6   7   8
  # name chr str stp chr str stp pos base
  
  #str stp str stp
  if ( ! ( ($line[2] =~ /^\d+$/) || ($line[2] == 0) ) ) {die "Capturesite RE fragment start coordinate (3rd column) not numeric\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  if ( ! ( ($line[3] =~ /^\d+$/) || ($line[3] == 0) ) ) {die "Capturesite RE fragment end coordinate (4th column) not numeric\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  if ( ! ( ($line[5] =~ /^\d+$/) || ($line[5] == 0) ) ) {die "Exclusion region start coordinate (6th column) not numeric\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";} 
  if ( ! ( ($line[6] =~ /^\d+$/) || ($line[6] == 0) ) ) {die "Exclusion region end coordinate (7th column) not numeric\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  
  # chr chr
  #if ( ! ($line[1] =~ /^chr\w+$/) ) {die "Chromosome name of RE fragment (2nd column) not proper format \n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  #if ( ! ($line[4] =~ /^chr\w+$/) ) {die "Chromosome name of exclusion region(5th column) not proper format In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  if ( ! ( ($line[1] =~ /^\w+$/)) ) {die "Chromosome name of RE fragment (2nd column) not proper format \n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  if ( ! ( ($line[4] =~ /^\w+$/)) ) {die "Chromosome name of exclusion region(5th column) not proper format In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  
  if ( ! ($line[1] eq $line[4]) ) {die "Chromosome of RE fragment and its exclusion (2nd column and 5th column) are different chromosomes - not allowed ! \n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}

  # name - all weird characters plus whitespace is worth of death :)
  if ( !($line[0] =~ /^[a-zA-Z0-9\-\_]+$/ )  ) {die "Capturesite name contains whitespace or weird characters. Only allowed to have numbers[0-9], letters[a-zA-Z] and underscore [_] \n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  
  if ($use_snp) {
    if ( ! ( ($line[7] =~ /^\d+$/) || ($line[7] == 0) ) ) {die "SNP coordinate (8th column) not numeric\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
    if ( !($line[8] =~ /^[ATCG]$/) ) {die "SNP base (9th column) is not [ATCG]\n In file:\n".$exclusion_path."/".$exclusion_file." , stopped ";}
  }
  
# ___________________________________________
  print EXCLUSIONBED "chr$line[1]\t".($line[2]-1)."\t$line[3]\t$line[0]\t1\t+\t$line[2]\t$line[3]\t133,0,122\n";
  # print EXCLUSIONBED "chr$line[4]\t".($line[5]-1)."\t$line[6]\t$line[0]\t1\t+\t$line[5]\t$line[6]\t133,0,0\n";

};
close EXCLUSIONFH ;
close EXCLUSIONBED ;
  
}

# --------------------------------------

if ( $only_divide_bams ){
unless (open(BUNCHLOGFH, ">$capturesite_bunch_count_filename")){die "Cannot open file $capturesite_bunch_count_filename , stopped ";};
print BUNCHLOGFH $temp_capturesite_bunch_number."\n";
close BUNCHLOGFH ;
}

my $capturesite_bunch_total_count=$temp_capturesite_bunch_number;

# ___________________________________________

# Early exit for $only_divide_capturesites
if ($only_divide_capturesites){

exit ;

}

# ___________________________________________

# print Dumper (\@capturesite_data);

print STDOUT "\nLoading in in-silico restriction enzyme digested genome.. \n";

# Opens the file of dpnII fragment coordinates and puts them into the hash of arrays %dpn_data, which is of the format dpn_data{chr}[fragment_start1....]
# The dpnII coordinates are generated by the script dpngenome2.pl.  This file is in the format chr:start-stop
# NB. The start and stop sequences are in the middle of the restriction enzyme fragments (the binary search function will need to be altered if you change to a 6 cutter)
open(DPNFH, "$restriction_enzyme_coords_file") or die "Cannot find restriction enzyme data file:$restriction_enzyme_coords_file , stopped ";

# These two temp things are needed to bring in the end coordinate of the last fragment per chromosome.
my $temp_chr="undef";
my $temp_prev_end=0;
while (my $line = <DPNFH>)
{
  if ($line =~ /(.*):(\d++)-(\d++)/)
  {
   
    # The 3 lines below take care of the last fragment per chromosome
    if(($1 ne $temp_chr) && ($temp_chr ne "undef")){ push @{$dpn_data{$temp_chr}}, $temp_prev_end;$counters{"02 Restriction enzyme last fragments for each chromosome loaded:"}++;}
    $temp_prev_end = $3;
    $temp_chr = $1;
     
    push @{$dpn_data{$1}}, $2;  #generates a hash of arrays in the format dpn_data{chr}[all dpn II frag start positions in ascending order]
    
    
    $counters{"02 Restriction enzyme fragments loaded:"}++
  }
  else {$counters{"02e lines from Restriction enzyme data failing to load:"}++;}
};
close DPNFH ;

# Sorts the restriction enzyme coordinates in ascending numerical order 
my @chr_index = keys %dpn_data;
foreach my $chr(@chr_index) {@{$dpn_data{$chr}} = sort {$a <=> $b} @{$dpn_data{$chr}};}

# TESTERS FOR RE INPUT FILE INTEGRITY :

#my $coord_sizes_filename = "$bigwig_folder/$genome\_sizes.txt";
#my $coord_sizes_filename = "$bigwig_folder";
#my $coord_sizes_filename= $ucscsizes

unless (open(GENOMESIZESFH, "$ucscsizes")){die "Cannot open chromosome sizes file $ucscsizes for genome $genome , stopped "; }; print REPORTFH "\n\nStatistics\n";
my $chr_count=0;
while (my $line = <GENOMESIZESFH>)
{
  if (($line =~ /chr/) and ($line =~ /random/i))
  {
    $chr_count++;
  }
}
close GENOMESIZESFH ;

# print out how many chrs were found, and which chrs they were.
print STDOUT "\nRed in restriction enzyme fragments:\n";
if (keys %dpn_data) {
  my $temp_size = keys %dpn_data;
  print STDOUT "Found data in ". $temp_size ."chromosomes.\n";
  # Warn about suspiciously small amount of chromosomes :
  if ($temp_size < $chr_count) {
    print STDOUT "WARNING : Found data in only ". $temp_size ."chromosomes! (There are $chr_count non-random-scaffold chromosomes in $genome genome). - Are you sure your RE fragment file is not corrupted ?\n";
  }
  else
  {
  print STDOUT "Found data in ". $temp_size ."chromosomes.\n";
  }
  
  print STDOUT "\nChr\tFragment count\n";
  foreach my $chr (sort keys %dpn_data)
  {
    my $temp_size = @{$dpn_data{$chr}};
    print STDOUT "chr$chr\t". $temp_size."\n";
  }
  
}
else
{
  die "Cannot find any data in restriction enzyme coordinate file:$restriction_enzyme_coords_file, stopped ";
}


print STDOUT "\n";
print STDOUT "Starting the main loop - over the SAM file, analysing the data on the fly.. \n";
print STDOUT "\n";

# Opens input sam file 
unless (open(INFH, "$input_path\/$input_filename")) {die "Cannot open file $input_path\/$input_filename , stopped ";};

my $samDataLineCounter=0;

# Opening empty block for the WHILE variables - we have to call them outside the while once,
# to deal with the fragments of the last read.
{

my $saveLine; my $saveReadname; my $saveUmi;
  
while (my $line = <INFH>)  #loops through all the lines of the sam file
{
    chomp $line;
    # Saving this for the last read - being handled outside the while loop
    $saveLine=$line;
    
    
  if ($line =~ /^(@.*)/){push @samheadder, $line;
      # print ALLSAMFH $line."\n";
      if ( !($only_divide_bams) && !($only_divide_capturesites) ){
      print CAPSAMFH $line."\n";
      }
      if ($only_divide_bams){
        # Get the header to all subfiles too ..
        for (my $i=1; $i < ($capturesite_bunch_total_count); $i++){
          my $this_bunch_filename = "$sample\_$version/DIVIDEDsams/$prefix_for_output\_capturesiteBunch_".$i."_$version.sam";
          unless (open(BUNCHFH, ">>$this_bunch_filename")){die "Cannot open file $this_bunch_filename , stopped ";};           
          print BUNCHFH $line."\n";
          close BUNCHFH ;
        }
      }
      
      $counters{"03 Lines in sam file header:"}++; next} #removes headder of sam file and stores it in the arragy @samheadder
 
   if ( $samDataLineCounter == 0) {
    my $tempPrinter=$counters{"03 Lines in sam file header:"};
    print STDOUT "Sam header red - found $tempPrinter header lines.\n";
  }
  
  # Informing user every time we have analysed a million reads
  $counters{"04 Data lines in sam file:"}++;
  $samDataLineCounter++;
  if ( $samDataLineCounter % 1000000 == 0) {
    my $millionReads= $samDataLineCounter/1000000;
    print STDOUT "$millionReads 000 000 sam data lines red and analysed ..\n";
  }
  
  
  my ($name, $bitwise, $chr, $readstart, $mapq, $cigar, $cola, $colb, $colc, $sequence, $qscore, $resta, $restb, $restc) = split /\t/, $line;   # splits the line of the sam file
  # Saving these for the last read - being handled outside the while loop
  
  # If we have wrongly parsing read name, we have to skip the line (our CUSTOM NAME FORMAT is needed for read parsing ) :
  if ( not ($name =~ /(.*):PE(\d++):(\d++):(\d++)$/ ) )
  {
    if ($use_dump eq 1){print DUMPOUTPUT $line."\n";} #"$name\n$sequence\n+\n$qscore\n"};
    $counters{"05 Discarded fragments with wrongly parsing SAM file name:"}++; next
  }
  else
  #if (($chr =~ /chr(.*)/) and ($cigar =~/(\d++)(.*)/) and ($name =~ /(.*):PE(\d++):(\d++)$/)) # checks that the sam file matches the name, cigar string etc (non aligned reads will not do this)
  {
    
    # Setting the "data" hash up along our custom sam read-name format :
    
    $name =~ /(.*):PE(\d++):(\d++):(\d++)$/; 
    my $readname=$1; my $pe = $2; my $readno= $3; my $islastfrag= $4;
    
    my $UMI="";
    if ($use_umi){
    # UMI support :
    
    # Inputing "Damien Downes" UMI format :
    # M01913:214:000000000-BGF65:1:1101:10004CTTTGCTTAT:18787:PE1:0:2
    # Where the original illumina read identifier was :
    # M01913:214:000000000-BGF65:1:1101:10004:18787 index:CTTTGCTTAT
    # Where CTTTGCTTAT is the UMI id.
    # The :PE1:0:2 is added in RE cut perl scripts just as in non-umi reads
    
    # Now read name looks like this :
    # M01913:214:000000000-BGF65:1:1101:10004CTTTGCTTAT:18787
    
    $readname =~ /(.*):(\d++)([[:upper:]]++):(.*)$/;;
    
    # Taking out the UMI ..
    $UMI=$3;
    # Reconstructing the read name (for debugging purposes) ..
    # $readname = $1.":".$2.":".$4    
    
    }
    
    # Saving this for the last read - being handled outside the while loop
    $saveReadname=$readname;
    # This just for printing out just after exiting the loop (not used in the analysis)
    $saveUmi=$UMI;    

    #-----------------------------------------------------------------------------------------
    # If we have introns in CIGAR or non-mapping read, we save the read for duplicate filter, but discard it otherwise.

    if (($bitwise & 4 ) == 4)
    {
      $counters{"06 Unmapped fragments in SAM file:"}++;
      #push @{$data{$readname}{"coord array"}}, "unmapped";
      if ($use_dump eq 1){print DUMPOUTPUT $line."\n"} #"$name\n$sequence\n+\n$qscore\n"};
    }
    
    # Now as bowtie2 is supported, this can be commented out ..
    # elsif ( $cigar =~/\d++\w++\d++/ )
    # {
    #   $counters{"06e Fragments with CIGAR strings failing to parse (containing introns or indels) :"}++;
    #   #push @{$data{$readname}{"coord array"}}, "cigarfail";
    #   if ($use_dump eq 1){print DUMPOUTPUT $line."\n"} #"$name\n$sequence\n+\n$qscore\n"};     
    # }
    
    #-----------------------------------------------------------------------------------------
    
    # The rest of the reads are now parse-able :
    else{
    
            $counters{"07 Mapped fragments:"}++;
        
            #Checks that the read name matches the end of the read name has been altered by the script that performs the in silico digestion of the DpnII file
            #This gives the reads names in the format PE1:0 ... PE2:4 depending on which paired end read and how many times the read has been digested
            
            #The hash structure is a little complex but follows what is happening in the reads it is as follows:
            
            #Where the data needs to be stored for each split / paired end read it is done as follows:
            #	$data{$readname}{$pe}{$readno}{"seqlength"}
            #	$data{$readname}{$pe}{$readno}{"readstart"}
            #	$data{$readname}{$pe}{$readno}{"readlength"}
            #	$data{$readname}{$pe}{$readno}{"sequence"}
            #Things are also stored for the whole group of reads as follows:
            #	$data{$readname}{"captures"}
            #	$data{$readname}{"number of captures"}
            #	@{data{$readname}{"coordinate array"}} - it is necessary to use a hash of arrays because the duplicate reads from the forward and reverse strands need to be excluded
            #	and the order of the reads changes depending on which strand the reads come from.
            
            # Assigns the entire line of the sam file to the hash
            $data{$readname}{$pe}{$readno}{"whole line"}= $line;       
            
            # Parses the chromosome from the $chr - nb without the chr in front
            $chr =~ /chr(.*)/; $chr = $1;
            $data{$readname}{$pe}{$readno}{"chr"} = $1;
            
            # Parses out the original strand from the "bitwise" flag
            # - if it was reverse complemented in sam (meaning that the read in fastq mapped in minus strand), it should  have bit "10" lit.
            # This is needed for the duplicate filter later (it is not duplicate if the fragment is the same but reverse complement)
            if ($bitwise & 0x0010) { $data{$readname}{$pe}{$readno}{"strand"} = "minus";}
            else { $data{$readname}{$pe}{$readno}{"strand"} = "plus";}
            
            #This adds the start of the sequence and the end of the read to the hash
            $cigar =~/(\d++)(.*)/;
            
            $data{$readname}{$pe}{$readno}{"seqlength"} = $1;
            $data{$readname}{$pe}{$readno}{"readstart"} = $readstart;
            
              
            # Setting the read end - old way (without bowtie2 support)
            # $data{$readname}{$pe}{$readno}{"readend"} = $readstart+length($sequence)-1; #minus1 due to 1 based sam file input.
            
            # Setting the read end - with bowtie2 support (full cigar parsing)
            
            # Here adding bowtie2 support :
            # https://samtools.github.io/hts-specs/SAMv1.pdf
            # Op 	BAM Description 			ConsumesQuery ConsumesReference
            # 
            # M 0 	alignment match (or mismatch) 		yes 		yes
            # I 1 	insertion to the reference 		yes 		no
            # D 2 	deletion from the reference 		no 		yes
            # N 3 	skipped region from the reference 	no 		yes
            # S 4 	soft clipping (present in SEQ) 		yes 		no
            # H 5 	hard clipping (NOT present in SEQ) 	no 		no
            # P 6 	padding (silent deletion) 		no 		no
            # = 7 	sequence match 				yes 		yes
            # X 8 	sequence mismatch 			yes 		yes
            # 
            # all possible : [MIDNSHP=X]
            # 
            # Op 	BAM Description 			ConsumesQuery ConsumesReference
            # 
            # M 0 	alignment match (or mismatch) 		yes 		yes
            # D 2 	deletion from the reference 		no 		yes
            # N 3 	skipped region from the reference 	no 		yes
            # = 7 	sequence match 				yes 		yes
            # X 8 	sequence mismatch 			yes 		yes
            # 
            # counting towards reference end point : [MDN=X]
            
            # This adds the start of the sequence and the end of the read to the hash
            
            # Setting lenght to zero before the cigar parse.
            $data{$readname}{$pe}{$readno}{"readend"}=$data{$readname}{$pe}{$readno}{"readstart"}-1; #minus1 due to 1 based sam file input.
            # Sequence - empty before entering CIGAR parsing ..
            $data{$readname}{$pe}{$readno}{"sequence"} = "";

            # Empty block for temp cigar
            {
            my $TEMPcigar=$cigar;
            while ($TEMPcigar =~ /(\d++)([MIDNSHP=X])(.*)/) 
            {
              my $number=$1;
              my $ident=$2;
              
              $TEMPcigar=$3;
              
              if ($ident =~ /^([MDN=X])$/)
                {
                  $data{$readname}{$pe}{$readno}{"readend"}+=$number;
                }
            }
            }
            
            # ___________________________________________
            if ( ! $only_divide_bams ){
            
            # Setting the sequence : this is only used in the snpcaller subroutine (so "ordinary runs" do not use this)
            
            # Old way of doing this (before bowtie2 support)
            # $data{$readname}{$pe}{$readno}{"sequence"} = $sequence;
            
            # Here adding bowtie2 support (full cigar parsing)
            # Op 	BAM Description 			ConsumesQuery ConsumesReference
            # 
            # These count normally
            # M 0 	alignment match (or mismatch) 		yes 		yes
            # = 7 	sequence match 				yes 		yes
            # X 8 	sequence mismatch 			yes 		yes
            # 
            # These are "skipped" - moving in seq coordinates, not printing anything 
            # I 1 	insertion to the reference 		yes 		no
            # S 4 	soft clipping (present in SEQ) 		yes 		no
            # 
            # These are "added" - not moving in seq coordinates, printing x-characters
            # D 2 	deletion from the reference 		no 		yes
            # N 3 	skipped region from the reference 	no 		yes
            # 
            # Ignoring these
            # H 5 	hard clipping (NOT present in SEQ) 	no 		no
            # P 6 	padding (silent deletion) 		no 		no
            
            # Initialising the sequence as empty string ..
            $data{$readname}{$pe}{$readno}{"sequence"}="";
            # Empty block for temp cigar and temp sequence
           {
           my $TEMPsequence=$sequence;
           my $TEMPcigar=$cigar;
           
           while ($TEMPcigar =~ /(\d++)([MIDNSHP=X])(.*)/)
           {
               my $addThis="";
               
               my $number=$1;
               my $ident=$2;
               $TEMPcigar=$3;
                
               # These count normally
               if ($ident =~ /^([M=X])$/)
               {
                 $addThis=substr($TEMPsequence,0,$number);
                 $TEMPsequence=substr($TEMPsequence,$number);
               }
                
               # These are "skipped" - moving in seq coordinates, not printing anything 
               if ($ident =~ /^([IS])$/)
               {
                 $addThis="";
                 $TEMPsequence=substr($TEMPsequence,$number);
               }
                
               # These are "added" - not moving in seq coordinates, printing x-characters
               if ($ident =~ /^([DN])$/)
               {
                 $addThis="";
                 for (my$i=0; $i< $number; $i++)
                 {
                   $addThis=$addThis."x";
                 }
                
               }
                
               # Ignoring these (silent in both reference and sequence)
               # [HP]
                
               # In the end actually adding ..
               $data{$readname}{$pe}{$readno}{"sequence"}=$data{$readname}{$pe}{$readno}{"sequence"}.$addThis;
              
           }
           }
           
           }
            # ___________________________________________

            
            #Generates a string of the coordinates of all the split paired end reads to allow duplicates to be excluded
            $data{$readname}{"number of reads"}++;
            
            # Planning what we will push into the coord_array ..
            my $CHR_for_coord_array=$data{$readname}{$pe}{$readno}{"chr"};
            my $START_for_coord_array=0;
            my $STOP_for_coord_array=0;
            
            # To be able to replicate Jelena's brain fart from CB3 and CB4 pipes :D - also storing this :
            my $STRAND_for_coord_array=$data{$readname}{$pe}{$readno}{"strand"};
            
            
            #################################################
            # CC3 style duplicate filter
            #################################################
            if ($version eq "CM3" ){
            
            $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
             $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};
            
            }
            
            #################################################
            # CC4 style duplicate filter
            #################################################
            
            elsif ($version eq "CM4" ){
            
            # Normal stuff - all flash-combined reads
            if ($flashed==1){
              $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
               $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};
            }
            # Also normal - NON-flashed middle fragment (3)
               elsif ($islastfrag==3){
              $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
               $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};
             
            $nonflashedcounters{"03 Fragment has RestrictionEnzyme cuts on both LEFT and RIGHT side (forward coordinates)"}++;
            }
            # Special cases - certain reads of NON-FLASHED file. (islastfragment values 0,1,2 for non-flashed file)
            else {
              
              my $chr = $data{$readname}{$pe}{$readno}{"chr"};
              my ($NEWstart, $NEWend) = binary_search(\@{$dpn_data{$chr}}, $data{$readname}{$pe}{$readno}{"readstart"}, $data{$readname}{$pe}{$readno}{"readend"}, \%nonflashedcounters);
      
              if (($NEWstart eq "error") or ($NEWend eq "error"))
              {
              $nonflashedcounters{"04 Error in Reporter fragment assignment to in silico digested genome (see 25ee for details)"}++;					 
              }
              else 
              {
                # Asking if this read coincides on either end..
                if (($NEWstart-2)==$data{$readname}{$pe}{$readno}{"readstart"}) {
                  $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
                   $STOP_for_coord_array=$NEWend;
                  
                  $nonflashedcounters{"01 Fragment has RestrictionEnzyme cut on LEFT side (forward coordinates)"}++;
                }
                elsif (($NEWend+2)==$data{$readname}{$pe}{$readno}{"readend"}) {
                  $START_for_coord_array=$NEWstart;
                   $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};
                  
                  $nonflashedcounters{"02 Fragment has RestrictionEnzyme cut on RIGHT side (forward coordinates)"}++;
                }
                else {
                  $START_for_coord_array=$NEWstart;
                   $STOP_for_coord_array=$NEWend;
                   
                  $nonflashedcounters{"00 Fragment has NEITHER right or left side at Restriction Enzyme cut site"}++;
                }
                
              }
              
              
            }
            
            }
            #################################################
            # CC5 style duplicate filter
            #################################################
            
            elsif ($version eq "CM5" ){
            
            # Normal stuff - all flash-combined reads
            if ($flashed==1){
              $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
               $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};	    }
            
            # Also normal - NON-flashed middle fragment (3)
               elsif ($islastfrag==3){
              $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
               $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};
               
              $nonflashedcounters{"03 Fragment has RestrictionEnzyme cuts on both sides"}++;
            }
            # Also normal - NON-flashed first fragment (2)
               elsif ($islastfrag==2){
              $START_for_coord_array=$data{$readname}{$pe}{$readno}{"readstart"};
               $STOP_for_coord_array=$data{$readname}{$pe}{$readno}{"readend"};
              
              $nonflashedcounters{"02 Fragment is First Fragment of R1 or R2, and has RestrictionEnzyme cut in the END of the fragment (fastq coordinates)"}++;
            }
            # Special cases - certain reads of NON-FLASHED file. (islastfragment values 0,1 for non-flashed file)
               else {
              
              my $chr = $data{$readname}{$pe}{$readno}{"chr"};
              my ($NEWstart, $NEWend) = binary_search(\@{$dpn_data{$chr}}, $data{$readname}{$pe}{$readno}{"readstart"}, $data{$readname}{$pe}{$readno}{"readend"}, \%nonflashedcounters);
              
              if (($NEWstart eq "error") or ($NEWend eq "error"))
              {
              $nonflashedcounters{"04 Error in Reporter fragment assignment to in silico digested genome (see 24ee for details)"}++;					 
              }
              else 
              {
                # Save coords first, count second
                  $START_for_coord_array=$NEWstart;
                  $STOP_for_coord_array=$NEWend;
                  
                if ($islastfrag==1){
                $nonflashedcounters{"01 Fragment is Last Fragment of R1 or R2, and has no RestrictionEnzyme cut in the END of the fragment (fastq coordinates)"}++;
                }
                else {
                # Rest of them have to be 0
                $nonflashedcounters{"00 Fragment has no RestrictionEnzyme cut on either side"}++;		
                }
              }
              
            }
            
            }
            #################################################
            # Duplicate filtering style wrong.
            #################################################
            
            else
            {
             die "Cannot find duplicate filtering style --CCversion $version, stopped ";
            }
            
            #################################################
            # If we have umi, we put the bin over it. Or otherwise too, if requested !
            $START_for_coord_array  = int $START_for_coord_array/$wobble_bin_width;
            $STOP_for_coord_array = int $STOP_for_coord_array/$wobble_bin_width;
            
            #################################################
            # Then we push it into coord_array :
            
            # If we are idiots and want to do the wrong way (old way CC3 CB3a  CC4 CB4a)
            if ($use_stranded) {
            push @{$data{$readname}{"coord array"}},$CHR_for_coord_array.":".$START_for_coord_array."-". $STOP_for_coord_array."-".$STRAND_for_coord_array;
            }
            # If we are clever and do it the way it should be done .. (reverting back to CC and CC2 style)
            else{
            push @{$data{$readname}{"coord array"}},$CHR_for_coord_array.":".$START_for_coord_array."-". $STOP_for_coord_array;	      
            }
            
            $data{$readname}{$pe}{$readno}{"Proximity_exclusion"}="no";
            
#------------------------------------------------------------------------------------------------------------------
# CAPTURESITE FILE FOR LOOPS - whether our fragment is a CAPTURE or EXCLUSION fragment
#------------------------------------------------------------------------------------------------------------------

#This part of the code defines whether the read is a capture or reporter read or whether it is proximity excluded

            my $captureFlag=0;
            my $exclusionFlag=0;
            
            # Parallel runs last step
            if ( $exclusion_filename != "UNDEFINED" ){
              
              #Loops through the @capturesite_data array to see whether the fragment meets the criteria to be a capture fragment
              for (my$i=0; $i< scalar (@capturesite_data); $i++)
              {
                  #Defines if the fragment lies within the exclusion limits around the capture
                  if ($data{$readname}{$pe}{$readno}{"chr"} eq $capturesite_data[$i][4] and $data{$readname}{$pe}{$readno}{"readstart"}>=$capturesite_data[$i][5] and $data{$readname}{$pe}{$readno}{"readend"}<=$capturesite_data[$i][6]) 
                  {
                    $exclusionFlag=1;
                  }
                  # Defines if the fragment lies within the capture region (trumping the exclusion limits)
                  # NB this version of the script requires the whole read to be contained within the capture area
                  #print"Outside if:$i\t$capturesite_data[$i][1]\t$capturesite_data[$i][2]\t$capturesite_data[$i][3]\n";
                  if (($data{$readname}{$pe}{$readno}{"chr"} eq $capturesite_data[$i][1]) and ($data{$readname}{$pe}{$readno}{"readstart"}>=$capturesite_data[$i][2] and $data{$readname}{$pe}{$readno}{"readend"}<=$capturesite_data[$i][3])) 
                  {
                    if ($use_snp ==1) #checks if the specified snp is in the capture read
                    {
                      if (snp_caller($data{$readname}{$pe}{$readno}{"chr"}, $data{$readname}{$pe}{$readno}{"readstart"}, $data{$readname}{$pe}{$readno}{"sequence"},$capturesite_data[$i][1], $capturesite_data[$i][7], $capturesite_data[$i][8]) eq "Y")
                      {
                      $captureFlag=1;
                      # setting cis chromosome
                      $data{$readname}{"cis_chr"}=$data{$readname}{$pe}{$readno}{"chr"};
                      # setting capturesite name
                      $data{$readname}{"capturesite"}=$capturesite_data[$i][0];
                      }
                    }
                    else #if SNP is not specified
                    {
                      $captureFlag=1;
                      # setting cis chromosome
                      $data{$readname}{"cis_chr"}=$data{$readname}{$pe}{$readno}{"chr"};		    
                      # setting capturesite name
                      $data{$readname}{"capturesite"}=$capturesite_data[$i][0];
                    }
                    
                  # If found, break loop here :
                  if (($captureFlag == 1) || ($exclusionFlag == 1))
                    {
                    last;
                    }
                  
                  }
                  
              }
              
              #Loops through the @exclusion_data array to see whether the fragment meets the criteria to be an exclusion fragment
              if (($captureFlag != 1) && ($exclusionFlag != 1))
              {
              for (my$i=0; $i< scalar (@exclusion_data); $i++)
              {
                  #Defines if the fragment lies within the exclusion limits around the capture
                  if ($data{$readname}{$pe}{$readno}{"chr"} eq $exclusion_data[$i][4] and $data{$readname}{$pe}{$readno}{"readstart"}>=$exclusion_data[$i][5] and $data{$readname}{$pe}{$readno}{"readend"}<=$exclusion_data[$i][6]) 
                  {
                    $exclusionFlag=1;
                  }
                    
                  # If found, break loop here :
                  if ($exclusionFlag == 1)
                    {
                    last;
                    }
                  
              }
              }
            
            }
            
            # All other run types except parallel runs last step
            else {
              #Loops through the @capturesite_data array to see whether the fragment meets the criteria to be a capture or exclusion fragment
              for (my$i=0; $i< scalar (@capturesite_data); $i++)
              {
                  #Defines if the fragment lies within the exclusion limits around the capture
                  if ($data{$readname}{$pe}{$readno}{"chr"} eq $capturesite_data[$i][4] and $data{$readname}{$pe}{$readno}{"readstart"}>=$capturesite_data[$i][5] and $data{$readname}{$pe}{$readno}{"readend"}<=$capturesite_data[$i][6]) 
                  {
                    $exclusionFlag=1;
                  }
                  # Defines if the fragment lies within the capture region (trumping the exclusion limits)
                  # NB this version of the script requires the whole read to be contained within the capture area
                  #print"Outside if:$i\t$capturesite_data[$i][1]\t$capturesite_data[$i][2]\t$capturesite_data[$i][3]\n";
                  if (($data{$readname}{$pe}{$readno}{"chr"} eq $capturesite_data[$i][1]) and ($data{$readname}{$pe}{$readno}{"readstart"}>=$capturesite_data[$i][2] and $data{$readname}{$pe}{$readno}{"readend"}<=$capturesite_data[$i][3])) 
                  {
                    if ($use_snp ==1) #checks if the specified snp is in the capture read
                    {
                      if (snp_caller($data{$readname}{$pe}{$readno}{"chr"}, $data{$readname}{$pe}{$readno}{"readstart"}, $data{$readname}{$pe}{$readno}{"sequence"},$capturesite_data[$i][1], $capturesite_data[$i][7], $capturesite_data[$i][8]) eq "Y")
                      {
                      $captureFlag=1;
                      # setting cis chromosome
                      $data{$readname}{"cis_chr"}=$data{$readname}{$pe}{$readno}{"chr"};
                      # setting capturesite name
                      $data{$readname}{"capturesite"}=$capturesite_data[$i][0];
                      }
                    }
                    else #if SNP is not specified
                    {
                      $captureFlag=1;
                      # setting cis chromosome
                      $data{$readname}{"cis_chr"}=$data{$readname}{$pe}{$readno}{"chr"};		    
                      # setting capturesite name
                      $data{$readname}{"capturesite"}=$capturesite_data[$i][0];
                    }
                    
                  # If found, break loop here :
                  if (($captureFlag == 1) || ($exclusionFlag == 1))
                    {
                    last;
                    }
                  
                  }
                  
              }
            }


# If we found a capture
if ($captureFlag == 1) {
 $data{$readname}{$pe}{$readno}{"type"}="capture";
 $data{$readname}{"number of capture fragments"}++;
}

# If we found proximity exclusion
elsif ($exclusionFlag ==1) {

  $data{$readname}{$pe}{$readno}{"type"} = "proximity exclusion";
  $counters{"09 Proximity exclusion fragments (Pre PCR duplicate removal):"}++;
  $data{$readname}{"number of exclusions"}++;  
}
else
# If neither of the above, marking it as reporter.
{
  $data{$readname}{$pe}{$readno}{"type"}="reporter";
  $data{$readname}{"number of reporters"}++;
  $counters{"10 Reporter fragments (Pre PCR duplicate removal):"}++;

}

}

#------------------------------------------------------------------------------------------------------------------
# COMBINING ALL ligated FRAGMENTS within a single sequenced READ, under a common name, into the storage hash
#------------------------------------------------------------------------------------------------------------------

# Changed upto here JT 220615

#------------------------------------------------------------------------------------------------------------------
# COMBINING ALL ligated FRAGMENTS within a single sequenced READ, under a common name, into the storage hash
#------------------------------------------------------------------------------------------------------------------


# Checks whether the name of the read has changed compared to the last one.  If there is no change it continues to loop through all the fragments of the read until it changes.
# If the readname has changed it loads the data into the output hashes and deletes the lines from the %data hash.

    if ($last_read eq "first"){$last_read=$readname} #deals with the first read
    
    if($readname ne $last_read){
      #checks whether the read name has changed and moves on to the next line in the sam file if the read names are the same

      # This whole thing is done in a big fat subroutine, as it needs to be repeated after the loop - otherwise the LAST READ of sam file gets un-analysed..
      # The parameter is needed to feed the $line to the data dumper (debugger) 
      # All the analysed data is hashed to a global hash - so, all that stuff is available to the sub automatically.
      $analysis_read = $last_read;
      &readAnalysisLoop($line);
      $last_read = $readname;
      $analysedReads++;
    }
  else  {
    $notlastFragments++;
  } # this is the end else of "last fragment of this read" - the if in the beginning was empty to make "next", i.e. the else is the "real deal analysis" when we did change read name.
  } # this is the readname parser else end - the if in the beginning was to skip over wrongly parsing read names.
LOOP_END:    
unless ($use_limit ==0){if ($counters{"02 Aligning sequences:"}) { if ($counters{"02 Aligning sequences:"}>$use_limit){last}  }}   # This limits the script to the first n lines
} # this is the main SAM file while end

close INFH ;

# Analysing last read of sam file !
#my $saveLine; my $saveReadname;
#All other variables are inside hashes - and thus already available to the subroutines
$analysis_read = $saveReadname;
print STDOUT "Last read analysis. Enter analysis round. Analysis read name : ".$analysis_read."\n";
if ($use_umi){
print STDOUT "UMI name : ".$saveUmi."\n";
}
&readAnalysisLoop($saveLine);

# Closing the empty block - making inside-while variables invisible again : my $saveLine; my $saveChr; my $saveReadstart; my $saveReadname; 
}

PRINTOUT:
#print Dumper(\%data); #used for debugging
#print Dumper(\%coords_hash); #used for debugging
#print Dumper(\%fraghash); #used for debugging
#print Dumper(\%cap_samhash); #used for debugging


# Prints the statistics into the report file

unless (open(REPORTFH, ">$report_filename")){die "Cannot open file $report_filename, stopped "}; print REPORTFH "\nFull report\n\n";
unless (open(REPORT2FH, ">$report2_filename")){die "Cannot open file $report2_filename, stopped "}; print REPORT2FH "\nRE cut report\n\n";
unless (open(REPORT3FH, ">$report3_filename")){die "Cannot open file $report3_filename, stopped "}; print REPORT3FH "\nFinal counts\n\n";
unless (open(REPORT4FH, ">$report4_filename")){die "Cannot open file $report4_filename, stopped "}; print REPORT4FH "\nFinal reporter counts\n\n";

my $inputFileInfo="\nSample name: $sample \nScript version:$version \n\nInput path/file: $input_path/$input_filename\nRestriction enzyme coords file: $restriction_enzyme_coords_file\nCapturesite coordinate input file: $capturesite_filename\nPublic folder: $public_folder\nPublic URL: $public_url\n";
my $scriptStartInfo="Script started at: $mday/$mon/$year $hour:$min\n\n";

print REPORTFH $inputFileInfo;
print REPORTFH $scriptStartInfo;
print REPORT2FH $inputFileInfo;
print REPORT2FH $scriptStartInfo;
print REPORT3FH $inputFileInfo;
print REPORT3FH $scriptStartInfo;
print REPORT4FH $inputFileInfo;
print REPORT4FH $scriptStartInfo;

output_hash(\%counters, \*REPORTFH);
output_hash(\%nonflashedcounters, \*REPORT2FH);
output_hash(\%finalcounters, \*REPORT3FH);
output_hash(\%finalrepcounters, \*REPORT4FH);
# output_hash(\%coords_hash, \*COORDSTRINGFH);
# output_hash(\%duplicates, \*COORDSTRINGFH);

close REPORTFH;
close REPORT2FH;
close REPORT3FH;
close REPORT4FH;

# ___________________________________________
if ( ! $only_divide_bams ){

#makes the sam files using the subroutines
for (my $i=0; $i< (scalar (@capturesite_data)); $i++)
{
output_hash_sam(\%samhash, $outputfilename."_".$capturesite_data[$i][0],$capturesite_data[$i][0],\@samheadder);
}

for (my $i=0; $i< (scalar (@capturesite_data)); $i++)
{
output_hash_sam(\%cap_samhash, $outputfilename."_capture_".$capturesite_data[$i][0],$capturesite_data[$i][0],\@samheadder)
}
 
#makes the mig, wig files using the subroutines wigout and wigtobigwig
for (my $i=0; $i< (scalar (@capturesite_data)); $i++)
{
frag_to_wigout(\%fraghash, $outputfilename."_".$capturesite_data[$i][0],"full",$capturesite_data[$i][0]);
cisfrag_to_wigout(\%fraghash, $outputfilename."_".$capturesite_data[$i][0],"full",$capturesite_data[$i][0],$capturesite_data[$i][1]);

print $counters{$capturesite_data[$i][0]." 17a Reporter fragments (final count) :"};
print $counters{$capturesite_data[$i][0]." 17b Reporter fragments CIS (final count) :"};
frag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$capturesite_data[$i][0],"full",$capturesite_data[$i][0],$counters{$capturesite_data[$i][0]." 17a Reporter fragments (final count) :"});
cisfrag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$capturesite_data[$i][0],"full",$capturesite_data[$i][0],$counters{$capturesite_data[$i][0]." 17a Reporter fragments (final count) :"},$capturesite_data[$i][1]);
frag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$capturesite_data[$i][0]."_CIS","full",$capturesite_data[$i][0],$counters{$capturesite_data[$i][0]." 17b Reporter fragments CIS (final count) :"});
cisfrag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$capturesite_data[$i][0]."_CIS","full",$capturesite_data[$i][0],$counters{$capturesite_data[$i][0]." 17b Reporter fragments CIS (final count) :"},$capturesite_data[$i][1]);

frag_to_windowed_wigout(\%fraghash, $outputfilename."_".$capturesite_data[$i][0],"full",$capturesite_data[$i][0], $window, $increment);
frag_to_migout(\%fraghash, $outputfilename."_".$capturesite_data[$i][0],"full",$capturesite_data[$i][0]);
# frag_to_migout(\%fraghash, $outputfilename."_".$capturesite_data[$i][0]."_CIS","cis",$capturesite_data[$i][0]);
}

#makes a combined track of HbA1 and A2 
if ($globin ==1 or $globin == 2)
{

my @tracks_to_combine = qw(Hba-1 Hba-2);
my $combined_name = "HbaCombined";
my @combined_name = ("HbaCombined", 11, 320000, 330000, 11, 320000, 320000);
push @capturesite_data, [@combined_name];
my $norm_value=0;
my $cis_norm_value=0;

foreach my $storedChr(sort keys %{$fraghash{"full"}{$tracks_to_combine[0]}})
    {
    foreach my $storedposition(sort keys %{$fraghash{"full"}{$tracks_to_combine[0]}{$storedChr}})
        {         
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"value"}=$fraghash{"full"}{$tracks_to_combine[0]}{$storedChr}{$storedposition}{"value"};
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"end"}=$fraghash{"full"}{$tracks_to_combine[0]}{$storedChr}{$storedposition}{"end"};
              $norm_value=$counters{$tracks_to_combine[0]." 17a Reporter fragments (final count) :"};
              $cis_norm_value=$counters{$tracks_to_combine[0]." 17a Reporter fragments (final count) :"};
        }
    }

foreach my $storedChr(sort keys %{$fraghash{"full"}{$tracks_to_combine[1]}})
    {
    foreach my $storedposition(sort keys %{$fraghash{"full"}{$tracks_to_combine[1]}{$storedChr}})
        {         
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"value"}+=$fraghash{"full"}{$tracks_to_combine[1]}{$storedChr}{$storedposition}{"value"};
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"end"}=$fraghash{"full"}{$tracks_to_combine[1]}{$storedChr}{$storedposition}{"end"};
              $norm_value=$norm_value+$counters{$tracks_to_combine[1]." 17a Reporter fragments (final count) :"};
              $cis_norm_value=$norm_value+$counters{$tracks_to_combine[1]." 17a Reporter fragments (final count) :"};
        }
    }
frag_to_wigout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name);
cisfrag_to_wigout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name,"11");
frag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name,$norm_value);
cisfrag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name,$norm_value,"11");
frag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name."_CIS","full",$combined_name,$cis_norm_value);
cisfrag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name."_CIS","full",$combined_name,$cis_norm_value,"11");
frag_to_windowed_wigout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name, $window, $increment);
frag_to_migout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name);
}

#makes a combined track of HbB1 and B2 
if ($globin ==2)
{
my @tracks_to_combine = qw(Hbb-b1 Hbb-b2);
my $combined_name = "HbbCombined";
my @combined_name = ("HbbCombined", 7, 110961967, 110962817, 7, 110961967, 110962817);
push @capturesite_data, [@combined_name];
my $norm_value=0;
my $cis_norm_value=0;

foreach my $storedChr(sort keys %{$fraghash{"full"}{$tracks_to_combine[0]}})
    {
    foreach my $storedposition(sort keys %{$fraghash{"full"}{$tracks_to_combine[0]}{$storedChr}})
        {         
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"value"}=$fraghash{"full"}{$tracks_to_combine[0]}{$storedChr}{$storedposition}{"value"};
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"end"}=$fraghash{"full"}{$tracks_to_combine[0]}{$storedChr}{$storedposition}{"end"};
              $norm_value=$counters{$tracks_to_combine[0]." 17a Reporter fragments (final count) :"};
              $cis_norm_value=$counters{$tracks_to_combine[0]." 17a Reporter fragments (final count) :"};
        }
    }

foreach my $storedChr(sort keys %{$fraghash{"full"}{$tracks_to_combine[1]}})
    {
    foreach my $storedposition(sort keys %{$fraghash{"full"}{$tracks_to_combine[1]}{$storedChr}})
        {         
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"value"}+=$fraghash{"full"}{$tracks_to_combine[1]}{$storedChr}{$storedposition}{"value"};
              $fraghash{"full"}{$combined_name}{$storedChr}{$storedposition}{"end"}=$fraghash{"full"}{$tracks_to_combine[1]}{$storedChr}{$storedposition}{"end"};
              $norm_value=$norm_value+$counters{$tracks_to_combine[1]." 17a Reporter fragments (final count) :"};
              $cis_norm_value=$norm_value+$counters{$tracks_to_combine[1]." 17a Reporter fragments (final count) :"};
        }
    }
frag_to_wigout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name);
cisfrag_to_wigout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name,"7");
frag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name,$norm_value);
cisfrag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name,$norm_value,"7");
frag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name."_CIS","full",$combined_name,$cis_norm_value);
cisfrag_to_wigout_normto10k(\%fraghash, $outputfilename."_".$combined_name."_CIS","full",$combined_name,$cis_norm_value,"7");
frag_to_windowed_wigout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name, $window, $increment);
frag_to_migout(\%fraghash, $outputfilename."_".$combined_name,"full",$combined_name);
}

#########################################################################################################################################################################
# Creates a track hub in my public folder - clearly this will need to be changed to allow the public folder to be specified
unless (open(TRACKHUBA, ">$public_folder/$sample\_$version\_hub.txt")){die "Cannot open file $public_folder/$sample\_$version\_tracks.txt, stopped ";}
unless (open(TRACKHUBB, ">$public_folder/$sample\_$version\_genomes.txt")){die "Cannot open file $public_folder/$sample\_$version\_tracks.txt, stopped ";}
unless (open(TRACKHUBC, ">>$public_folder/$sample\_$version\_tracks.txt")){die "Cannot open file $public_folder/$sample\_$version\_tracks.txt, stopped ";}

print TRACKHUBA "hub $sample\_$version
shortLabel $sample\_$version
longLabel $sample\_$version\_CaptureC
genomesFile $sample\_$version\_genomes.txt
email $email";

print TRACKHUBB "genome $genome
trackDb $sample\_$version\_tracks.txt";

print REPORTFH "\nThe track hub can be found at:
http://$public_url/$sample\_$version\_hub.txt
This URL just needs to be pasted into the UCSC genome browser\n\n";

# Loops throught the different capture points and converts the wig to a bigwig if the file is over 1000 bytes and updates the track hub tracks.txt file
for (my$i=0; $i< (scalar (@capturesite_data)); $i++)
{
  my $filename_out = $outputfilename."_".$capturesite_data[$i][0].".wig";
  my $filesize = 0;
  if ( -f $filename_out ){ $filesize = -s $filename_out; }# checks the filesize
  print "$filename_out\t$filesize\n";
  
  #if ($filesize >1000)	# ensures that wigtobigwig is not run on files containing no data
  if ($filesize >0)	# ensures that wigtobigwig is not run on files containing no data
  {
    wigtobigwig($outputfilename."_".$capturesite_data[$i][0], \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");
    wigtobigwig($outputfilename."_".$capturesite_data[$i][0]."_CISonly", \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");
    wigtobigwig($outputfilename."_".$capturesite_data[$i][0]."_win", \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");

    if ($normalised_tracks) {
      wigtobigwig($outputfilename."_".$capturesite_data[$i][0]."_normTo10k", \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");
      wigtobigwig($outputfilename."_".$capturesite_data[$i][0]."_normTo10k_CISonly", \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");
      wigtobigwig($outputfilename."_".$capturesite_data[$i][0]."_CIS_normTo10k", \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");
      wigtobigwig($outputfilename."_".$capturesite_data[$i][0]."_CIS_normTo10k_CISonly", \*REPORTFH, $store_bigwigs_here_folder, $public_folder, $public_url, "CaptureC_gene_$capturesite_data[$i][0]");
    }
    
    my $short_filename = $outputfilename."_".$capturesite_data[$i][0];
    
    if ($short_filename =~ /(.*)\/(\V++)/) {$short_filename = $2};
    my $flashstatus="_NOTSET";
    if ($flashed==1) { $flashstatus="_FLASHED"}
    elsif ($flashed==-1) { $flashstatus=""}
    else{$flashstatus="_NOTFLASHED"}
    
    
    
    print TRACKHUBC
"track $sample\_$capturesite_data[$i][0]$flashstatus
type bigWig
longLabel CC_$sample\_$capturesite_data[$i][0]$flashstatus
shortLabel $sample\_$capturesite_data[$i][0]$flashstatus
bigDataUrl $public_folder/$short_filename.bw
visibility hide
priority 200
color 0,0,0
autoScale on
alwaysZero on

track cis_$sample\_$capturesite_data[$i][0]$flashstatus
type bigWig
longLabel CC_cis_$sample\_$capturesite_data[$i][0]$flashstatus
shortLabel cis_$sample\_$capturesite_data[$i][0]$flashstatus
bigDataUrl $public_folder/$short_filename\_CISonly.bw
visibility hide
priority 200
color 0,0,0
autoScale on
alwaysZero on

track win_$sample\_$capturesite_data[$i][0]$flashstatus
type bigWig
longLabel CC_win_$sample\_$capturesite_data[$i][0]$flashstatus
shortLabel win_$sample\_$capturesite_data[$i][0]$flashstatus
bigDataUrl $public_folder/$short_filename\_win.bw
visibility hide
priority 200
color 0,0,0
autoScale on
alwaysZero on

";

if ($normalised_tracks) {

    print TRACKHUBC
"track norm10k_$sample\_$capturesite_data[$i][0]$flashstatus
type bigWig
longLabel CC_norm10k_$sample\_$capturesite_data[$i][0]$flashstatus
shortLabel norm10k_$sample\_$capturesite_data[$i][0]$flashstatus
bigDataUrl $public_folder/$short_filename\_norm10k.bw
visibility hide
priority 200
color 0,0,0
autoScale on
alwaysZero on

track norm10k_CIS_$sample\_$capturesite_data[$i][0]$flashstatus
type bigWig
longLabel CC_CISnorm10k_$sample\_$capturesite_data[$i][0]$flashstatus
shortLabel CIS_norm10k_$sample\_$capturesite_data[$i][0]$flashstatus
bigDataUrl $public_folder/$short_filename\_CIS_norm10k.bw
visibility hide
priority 200
color 0,0,0
autoScale on
alwaysZero on

track cisOnly_norm10k_CIS_$sample\_$capturesite_data[$i][0]$flashstatus
type bigWig
longLabel CC_cisonly_CISnorm10k_$sample\_$capturesite_data[$i][0]$flashstatus
shortLabel cisonly_CIS_norm10k_$sample\_$capturesite_data[$i][0]$flashstatus
bigDataUrl $public_folder/$short_filename\_CIS_normTo10k_CISonly.bw
visibility hide
priority 200
color 0,0,0
autoScale on
alwaysZero on

"
}

  }

}

}
# ___________________________________________

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(); print REPORTFH "Script finished at: $mday/$mon/$year $hour:$min \n";

print REPORTFH "Analysed reads (last fragments): $analysedReads, not-last-fragments :$notlastFragments \n";

exit;

#########################################################################################################################################################################

# MAIN READ ANALYSIS LOOP - as a subroutine, as it needs to be repeated once after the last read (otherwise last SAM read never gets analysed)

# These variables need to go in as parameters (all other stuff is accessible via the hashes already)
# $line
# $chr
# $readstart
# $readname

sub readAnalysisLoop
{
      my ($line) = @_;
      my %reporter_dpn = ();
      
      $counters{"11 Total number of reads entering the analysis :"}++;
      
      my $weHaveCaptures=0;
      if (defined $data{$analysis_read}{"number of capture fragments"} and $data{$analysis_read}{"number of capture fragments"}>0 )
      {
        if ( $tiled_analysis )
        {
          $counters{"11b Total number of reads with within-tile fragments, entering the analysis :"}++;
        }
        else
        {
          $counters{"11b Total number of capture-containing reads entering the analysis :"}++;          
        }
        $weHaveCaptures=1;
      }
      
      my $weHaveReporters=0;
      if (defined $data{$analysis_read}{"number of reporters"} and $data{$analysis_read}{"number of reporters"}>0 )
      {
      $weHaveReporters=1;
      }
      
      my $weAnalyseThisRead=0;
      if ( $tiled_analysis )
      {
        # If we are tiled, we care if we have more than 1 fragment. Valid fragments should all be named "capture" in this case.
        if ( ($weHaveCaptures==1) and ( $data{$analysis_read}{"number of capture fragments"} > 1  ))
        {
        $weAnalyseThisRead=1;
        $counters{"11c Total number of at-least-2-fragment-containing tiled reads entering the analysis :"}++;
        }
        else
        {
        $counters{"11d Total number of reads not containing at least 2 fragments in tiled read, excluded from the analysis :"}++;
        }
      
      }
      else
      {
        # Normal analysis : have to have captures and reporters
        if ($weHaveCaptures==1 and $weHaveReporters==1 )
        {
        $weAnalyseThisRead=1;
        $counters{"11c Total number of capture-and-reporter-containing reads entering the analysis :"}++;
        }
        else
        {
        $counters{"11d Total number of reads lacking either captures or reporters, excluded from the analysis :"}++;
        }
      
      }
      
      my $exclusioncount=0;
      my $reportercount=0;
      my $capturename="";
      my $capturecomposition="";
      my %capturenames;
      
      if ($weAnalyseThisRead==1)
      {
      #---------------------------------------------------------------------------------------
      # Resolving the identity of the capture fragments.
      
      for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
      {
        for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
        {
          if (defined $data{$analysis_read}{$pe}{$readno}{"type"})
          {
          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "capture")
          {
            for (my $capturesite=0; $capturesite< (scalar (@capturesite_data)); $capturesite++)
            {
              if (($data{$analysis_read}{$pe}{$readno}{"chr"} eq $capturesite_data[$capturesite][1]) and ($data{$analysis_read}{$pe}{$readno}{"readstart"}>=$capturesite_data[$capturesite][2] and $data{$analysis_read}{$pe}{$readno}{"readend"}<=$capturesite_data[$capturesite][3]))
              {
              my $tempname="".$capturesite_data[$capturesite][0]."";
              $capturenames{$tempname}++;
              }
            }
          }
          }
          
        }
      }
      
      # Resolving the count of exclusion fragments.
      
      for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
      {
        for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
        {
          if (defined $data{$analysis_read}{$pe}{$readno}{"type"})
          {
          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "proximity exclusion")
          {
              $exclusioncount++;
          }
          }
          
        }
      }
      
      # Resolving the count of reporter fragments.
      
      for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
      {
        for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
        {
          if (defined $data{$analysis_read}{$pe}{$readno}{"type"})
          {
          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "reporter")
          {
              $reportercount++;
          }
          }
          
        }
      }
      
      foreach my $foundcapturesite (sort keys %capturenames)
      {
        $capturename.="".$foundcapturesite."";
        $capturecomposition.=$foundcapturesite.":".$capturenames{$foundcapturesite}." " ;
      }
      
      }
      
      # Resolving the identity of the capture fragments - DONE.
      #---------------------------------------------------------------------------------------
      
      # Now we need to take into account the "weird ones" which leak through and claim to  have composition ""
      
      # If we have only whitespace in $capturename..
      if ($capturename =~ /^\s*$/)
      {
        $weAnalyseThisRead=0;
      }
      
      # If we have only "" in $capturename..
      if ($capturename eq '')
      {
        $weAnalyseThisRead=0;
      }
      
      # Then we take care of the ones which leak through and have 0 reporter fragments
      
      if ($reportercount==0)
      {
        if ( !$tiled_analysis )
        {
        $weAnalyseThisRead=0;
        }
      }
      
      #---------------------------------------------------------------------------------------
      # Now, printing out what we have - after all the above filters
      if ($weAnalyseThisRead==1)
      {
      
        if ( $tiled_analysis )
        {
          $counters{"11e Total number of reads having tiles in composition $capturecomposition : "}++;
          $counters{"11ee Total number of reads having tiles in composition $capturecomposition , having $reportercount outside-all-tiles fragments and $exclusioncount exclusion fragments : "}++;  
        }
        else
        {
          $counters{"11e Total number of reads having captures in composition $capturecomposition : "}++;
          $counters{"11ee Total number of reads having captures in composition $capturecomposition , having $reportercount reporters and $exclusioncount exclusion fragments : "}++;
        }
        
      #---------------------------------------------------------------------------------------
      # Last filter before analysis : double captures are excluded :
      
      # Now we check again, if we REALLY want to analyse this read - if it is a double capture, we kick it out now.
      # We allow for reads which have multicapture in SAME capture capturesite, though.
      
      if (scalar keys %capturenames == 1 )
      {
      $weAnalyseThisRead=1;
      
        if ( $tiled_analysis )
        {
          $counters{"11f Total number of all-capturefragments-within-a-single-tile reads included to the analysis :"}++;        
        }
        else
        {
          $counters{"11f Total number of single-capture reads included to the analysis :"}++;
        }
      
      $data{$analysis_read}{"captures"}="".$capturename."";
      }
      else
      {
      
      # If we planned to analyse - but it was double capture after all, we count these in separate counter
        if ( $tiled_analysis )
        {
          $counters{"11g Total number of multi-capture reads excluded from the analysis :"}++;
        }
        else
        {
          $counters{"11g Total number of fragments-from-multiple-tiles reads excluded from the analysis :"}++;          
        }
        
      # We set in any case, that none of these continue in analysis.
      $weAnalyseThisRead=0;
      }
      }
      
    ##########################################################################################################
    # So, the rest of the things are done only to fragments, which have at least one capture, and one reporter.
    ##########################################################################################################
    
    if ($weAnalyseThisRead==1)
      {
    $counters{"12 Total number of reads entering duplicate-filtering  - should be same count as 11f :"}++;
    
    # If we have some data in the read - i.e. something else than "unknown" fragments due to unmapping reads or unparse-able cigar strings.
    # my $count = true { /pattern/ } @list_of_strings;
    
    # The line below does not work, as List:MoreUtils did not load properly - genmailed that, and now need to write a manual for loop for this.
    #my $countOfUnknowns = true { /^unknown$/ } @{$data{$analysis_read}{"coord array"}}
    
    # Manual loop over array 0 as List::MoreUtils fails to load :
    my $countOfUnknowns = 0;
    foreach (@{$data{$analysis_read}{"coord array"}})
    {
      my $thisRound=$_;
      if (($thisRound eq "unmapped") || ($thisRound eq "cigarfail" )){ $countOfUnknowns++;}
    }
    
    # Counters for fragment lenght distribution :
    my $tempSize= scalar(@{$data{$analysis_read}{"coord array"}});
    $counters{"14a Reads having $tempSize fragments:"}++;
    $tempSize=$tempSize-$countOfUnknowns;
    $counters{"14b Reads having $tempSize informative fragments:"}++;
    
    foreach (@{$data{$analysis_read}{"coord array"}}) {$counters{"13 Count of fragments in Reads having at least one informative fragment :"}++;};
   
#------------------------------------------------------------------------------------------------------------------
# DUPLICATE FILTER - requires same ligation order and same strand of all fragments, before gets marked duplicate.
#------------------------------------------------------------------------------------------------------------------
      
# ___________________________________________
if ( ! $only_divide_bams ){

      # We generate coordinate join. This is purely for duplicate filtering.
      # (if all fragments are in same order, and same strand, this is a duplicate entry).
      
      # 2 arrays : "coordinate string" (coordinates and strand for all ligation fragments within this sequenced read)
      #            "reverse coord string" (the same - but to the other direction. same ligation fragment - red from the "other end")
      
      #-----------------------------------------------------------------------------------------
      # Making the "coordinate string"
      
      # We get rid of this fanciness - as we do the "original duplicate filter" here..
      
      s/-plus$// for @{$data{$analysis_read}{"coord array"}};
      s/-minus$// for @{$data{$analysis_read}{"coord array"}};
      
      # Here the old duplicate filter. this over-rules the above "VS2 duplicate filter".
      $data{$analysis_read}{"coord string"}= join( "_", sort {$a cmp $b} @{$data{$analysis_read}{"coord array"}}); #this line sorts the array in the hash and converts it into a string with the sequences in ascending order

      
      #$data{$analysis_read}{"coord string"}= join( "_", @{$data{$analysis_read}{"coord array"}}); #we don't want to sort, as ligation order is important to us
      
      #-----------------------------------------------------------------------------------------
      # Making the "reverse coordinate string"
      
      # Now we make the coord string upside down :
      #s/oldtext/newtext/ for @config;
      
      #s/_plus$/_TEMP/ for @{$data{$analysis_read}{"coord array"}};
      #s/_minus$/_plus/ for @{$data{$analysis_read}{"coord array"}};
      #s/_TEMP$/_minus/ for @{$data{$analysis_read}{"coord array"}};
      
      #$data{$analysis_read}{"reverse coord string"}= join( "_", reverse @{$data{$analysis_read}{"coord array"}}); #we don't want to sort, as ligation order is important to us
      
      # We return the coord array to original order (if we want to print it out later and not be confused)
      #s/_plus$/_TEMP/ for @{$data{$analysis_read}{"coord array"}};
      #s/_minus$/_plus/ for @{$data{$analysis_read}{"coord array"}};
      #s/_TEMP$/_minus/ for @{$data{$analysis_read}{"coord array"}};
      
      #-----------------------------------------------------------------------------------------
      # Now - using the coordinate strings to jump over duplicates in the analysis :
      
      #if (defined $coords_hash{$data{$analysis_read}{"coord string"}} or defined $coords_hash{$data{$analysis_read}{"reverse coord string"}}) 
      #{$coords_hash{$data{$analysis_read}{"coord string"}}++; $counters{"15 Duplicate reads:"}++;
      # if ($use_dump eq 1){print DUMPOUTPUT $line."\n"} #"$name\n$sequence\n+\n$qscore\n"};
      #}
      #-----------------------------------------------------------------------------------------
      
      
}
# ___________________________________________

      my $weNeedToFilterThis=0;

      # We count the duplicates (in any case)

# ___________________________________________
if ( ! $only_divide_bams ){

      if (exists $coords_hash{$data{$analysis_read}{"cis_chr"}}){
      if (exists $coords_hash{$data{$analysis_read}{"cis_chr"}}{$data{$analysis_read}{"capturesite"}}){
      if (exists $coords_hash{$data{$analysis_read}{"cis_chr"}}{$data{$analysis_read}{"capturesite"}}{$data{$analysis_read}{"coord string"}}){
        $coords_hash{$data{$analysis_read}{"cis_chr"}}{$data{$analysis_read}{"capturesite"}}{$data{$analysis_read}{"coord string"}}++;
        if ( $duplfilter == 1 ) {       
                 $counters{"16c Duplicate reads:"}++ ; $weNeedToFilterThis=1 }
               else {
                 $counters{"16c Duplicate reads (not filtered) :"}++ } 
      }}}

}
# ___________________________________________
      
#------------------------------------------------------------------------------------------------------------------
# REPORTING THE COUNTS AFTER DUPLICATE FILTER - only for reads which made it this far..
#------------------------------------------------------------------------------------------------------------------
      
      if ( $weNeedToFilterThis == 0 )
      {
        
# ___________________________________________
if ( ! $only_divide_bams ){

          $coords_hash{$data{$analysis_read}{"cis_chr"}}{$data{$analysis_read}{"capturesite"}}{$data{$analysis_read}{"coord string"}}++;
          $counters{"16 Non-duplicated reads:"}++;
          
          $counters{"16b Non-duplicated reads having captures in composition $capturecomposition : "}++;
          $counters{"16bb Non-duplicated reads having captures in composition $capturecomposition , having $reportercount reporters and $exclusioncount exclusion fragments : "}++;
          
          #Counters for informative and un-informative fragments :
          my $informativeCounter=0;
          my $allFragCounter=0;	  
          
          # Counters for capture and exclusion fragments after duplicate-removal
          for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
                    {
                      for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
                      {
                        
                        
                        $allFragCounter++;
                        if (defined $data{$analysis_read}{$pe}{$readno}{"type"})
                        {
                          $informativeCounter++;
                          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "capture"){$counters{"16b Capture fragments (After PCR duplicate removal):"}++;}
                          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "proximity exclusion"){$counters{"16c Proximity exclusion fragments (After PCR duplicate removal):"}++;}
                          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "reporter"){$counters{"16d Reporter fragments (After PCR duplicate removal):"}++;}  
                        }
                      }
                    }
          
          $counters{"16g Reads having ".$informativeCounter." informative fragments (after PCR duplicate whole-read removal):"}++;
          $counters{"16f Total fragment count (after PCR duplicate removal):"}++;

}
# ___________________________________________

#------------------------------------------------------------------------------------------------------------------
# THE REAL DEAL REPORTING FOR LOOPS - here the destiny of the reads is finally made..
#------------------------------------------------------------------------------------------------------------------

for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
{
 for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
 {
  # if (defined $data{$analysis_read}{$pe}{$readno}{"whole line"}){print ALLSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"}."\n";}
    if (defined $data{$analysis_read}{$pe}{$readno}{"type"}) # checks that the fragment is not CIGAR parse error or unmapped read
    {
     # print ALLTYPEDSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"}."\n";
      
      
     # For only divide bams we print here - and update the counters below normally (but don't print anything in there any more
     if ( $only_divide_bams ){
      
	  # Uncomment below, for debugging purposes
	  
          # All reads to a single file ..
          # print CAPSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
          # print CAPSAMFH "\tCO:Z:capturesiteBunch_";
          # print CAPSAMFH $capturesite_bunch_numbers{$data{$analysis_read}{"captures"}};
          # print CAPSAMFH "\n";
          
          # Reads belonging to this bunch of capturesites ..
          
          my $this_bunch_filename = "$sample\_$version/DIVIDEDsams/$prefix_for_output\_capturesiteBunch_".$capturesite_bunch_numbers{$data{$analysis_read}{"captures"}}."_$version.sam";
          
          unless (open(BUNCHFH, ">>$this_bunch_filename")){die "Cannot open file $this_bunch_filename , stopped ";};           
          print BUNCHFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
          print BUNCHFH "\n";
          close BUNCHFH ;
          
          if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "reporter")
          {
            
          }
          
          
          
     }
    
# ___________________________________________
if ( ! $only_divide_bams ){
#------------------------------------------------------------------------------------------------------------------
# ANALYSING THE REPORTER FRAGMENTS - step 1) - if clauses to restrict to non-duplicates (if STRINGENT requested)
#------------------------------------------------------------------------------------------------------------------
    
    my $duplicate_string;
    
    # Tiled support - we go into the loop, if we have Reporter OR Capture (tiled), or only when we have Reporter (normal run)
    
    my $continue_to_final_filters=0;
    
    # Continue - if we are normal run, and we have a reporter
    if (($data{$analysis_read}{$pe}{$readno}{"type"} eq "reporter") && ( !$tiled_analysis ))
    {
      $continue_to_final_filters=1
    }
    
    # Continue - if we are a tiled run, and we have a reporter OR capture
    if ( $tiled_analysis )
    {
    if (($data{$analysis_read}{$pe}{$readno}{"type"} eq "reporter") || ($data{$analysis_read}{$pe}{$readno}{"type"} eq "capture"))
    {
      $continue_to_final_filters=1
    }
    }
    
    # --------------------------
    
    # Now entering the final filters ..
    if ($continue_to_final_filters == 1)
    {
      $counters{"23 Reporters before final filtering steps"}++ ;
      $counters{$data{$analysis_read}{"captures"}." 12 Reporters before final filtering steps"}++ ;
      
            $duplicate_string = $data{$analysis_read}{"captures"}.$data{$analysis_read}{$pe}{$readno}{"chr"}.":".$data{$analysis_read}{$pe}{$readno}{"readstart"}."-".$data{$analysis_read}{$pe}{$readno}{"readend"} ;
      
      if (defined $duplicates{$duplicate_string})
      {
        $counters{"24 Duplicate reporters (duplicate-excluded if stringent was on)"}++ ;
        $counters{$data{$analysis_read}{"captures"}." 13 Duplicate reporters (duplicate-excluded if stringent was on)"}++ ;
      }
      
      
      if(($stringent ==1) and (defined $duplicates{$duplicate_string}))
      {
        # We jump over duplicates if we have stringent on.
        $duplicates{$duplicate_string}++;
        
        if ( ! $only_divide_bams ){
        print CAPSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
        print CAPSAMFH "\tCO:Z:";
        print CAPSAMFH $data{$analysis_read}{"captures"};
        print CAPSAMFH "_REPDUPSTR\n";
        }
        
      }
      else
      {
        # This is not only ++ but also "make this to exist" - the counterpart of the above if exists duplicates{duplString}
        $duplicates{$duplicate_string}++;
        
#------------------------------------------------------------------------------------------------------------------
# ANALYSING THE REPORTER FRAGMENTS - step 2) - comparing to DpnII fragments, and reporting those.
#------------------------------------------------------------------------------------------------------------------

        
        #print COORDSTRINGFH "$pe:$readno\t".$analysis_read."\t".$data{$analysis_read}{"captures"}."\t".$data{$analysis_read}{$pe}{$readno}{"type"}."\n"; #For debugging reads that are reported
        #print "$pe:$readno\t".$analysis_read."\t".$data{$analysis_read}{"captures"}."\t".$data{$analysis_read}{$pe}{$readno}{"type"}."\n";
      
        #This maps the fragment onto the dpnII fragment using the binary search subroutine, which returns the position of the matching fragment in the
        #hash of arrays %dpn_data - which is in the format %dpn_data{chromosome}[start position]
      
        my $chr = $data{$analysis_read}{$pe}{$readno}{"chr"};
        my $readstart = $data{$analysis_read}{$pe}{$readno}{"readstart"};
        my ($start, $end) = binary_search(\@{$dpn_data{$chr}}, $data{$analysis_read}{$pe}{$readno}{"readstart"}, $data{$analysis_read}{$pe}{$readno}{"readend"}, \%counters);
      
        #print "returned values: $start-$end\t";
      
        if (($start eq "error") or ($end eq "error"))
        {
          $counters{"25e Error in Reporter fragment assignment to in silico digested genome (see 24ee for details)"}++;
          $counters{$data{$analysis_read}{"captures"}." 14e Error in Reporter fragment assignment to in silico digested genome (see 25ee for details)"}++;					 
        }
        elsif (defined $reporter_dpn{"$chr:$start-$end"})
        {
          $reporter_dpn{"$chr:$start-$end"}++; $counters{"25 Reporter fragments reporting the same RE fragment within a single read (duplicate-excluded)"}++;
          $counters{$data{$analysis_read}{"captures"}." 14 Reporter fragments reporting the same RE fragment within a single read (duplicate-excluded)"}++;
          
          if ( ! $only_divide_bams ){
          print CAPSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
          print CAPSAMFH "\tCO:Z:";
          print CAPSAMFH $data{$analysis_read}{"captures"};
          print CAPSAMFH "_REPDUP\n";
          }
          
        }
        else
        {
        $reporter_dpn{"$chr:$start-$end"}++;
        
        $data{$analysis_read}{$pe}{$readno}{"fragstart"} = $start;
        $data{$analysis_read}{$pe}{$readno}{"fragend"} = $end;
              
        #This transfers the positions of the dpnII fragments into the hash %fraghash
        # 				%fraghash{"full"}{chromosome}{fragment start}{"value"}= value
        # 				%fraghash{"full"}{chromosome}{fragment start}{"end"}= fragment end
      
        $fraghash{"full"}{$data{$analysis_read}{"captures"}}{$data{$analysis_read}{$pe}{$readno}{"chr"}}{$data{$analysis_read}{$pe}{$readno}{"fragstart"}}{"value"}++;
        $fraghash{"full"}{$data{$analysis_read}{"captures"}}{$data{$analysis_read}{$pe}{$readno}{"chr"}}{$data{$analysis_read}{$pe}{$readno}{"fragstart"}}{"end"}= $data{$analysis_read}{$pe}{$readno}{"fragend"};
        # If we are cis ..
        # if ($data{$analysis_read}{$pe}{$readno}{"chr"} eq $data{$analysis_read}{"cis_chr"}){
        # $fraghash{"cis"}{$data{$analysis_read}{"captures"}}{$data{$analysis_read}{$pe}{$readno}{"chr"}}{$data{$analysis_read}{$pe}{$readno}{"fragstart"}}{"value"}++;
        # $fraghash{"cis"}{$data{$analysis_read}{"captures"}}{$data{$analysis_read}{$pe}{$readno}{"chr"}}{$data{$analysis_read}{$pe}{$readno}{"fragstart"}}{"end"}= $data{$analysis_read}{$pe}{$readno}{"fragend"};
        # }
        
        #This puts the data for the matching lines into the %samhash
        
        # If we report both cis and trans .. , or we report only cis and ARE cis.
        if ( (! $only_cis) || (($data{$analysis_read}{$pe}{$readno}{"chr"} eq $data{$analysis_read}{"cis_chr"}))  ){
        
        push @{$samhash{$data{$analysis_read}{"captures"}}}, $data{$analysis_read}{$pe}{$readno}{"whole line"};
        
          if ( ! $only_divide_bams ){
          print CAPSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
          print CAPSAMFH "\tCO:Z:";
          print CAPSAMFH $data{$analysis_read}{"captures"};
          }
     
        # If we are cis ..
        if ($data{$analysis_read}{$pe}{$readno}{"chr"} eq $data{$analysis_read}{"cis_chr"}){
          
        if ( ! $only_divide_bams ){  
        print CAPSAMFH "_CISREP\n";
        }
        $counters{"26b Actual reported CIS fragments :"}++;
        $counters{$data{$analysis_read}{"captures"}." 17b Reporter fragments CIS (final count) :"}++;
        $finalcounters{"1b Actual reported CIS fragments :"}++;
        $finalcounters{$data{$analysis_read}{"captures"}." 3b Reporter fragments CIS (final count) :"}++;					
        $finalrepcounters{"1b Actual reported CIS fragments :"}++;
        $finalrepcounters{$data{$analysis_read}{"captures"}." 3b Reporter fragments CIS (final count) :"}++;
        }
        else{
        if ( ! $only_cis ){
          
        if ( ! $only_divide_bams ){
        print CAPSAMFH "_TRANSREP\n";
        }
        $counters{"26c Actual reported TRANS fragments :"}++;
        $counters{$data{$analysis_read}{"captures"}." 17c Reporter fragments TRANS (final count) :"}++;					
        $finalcounters{"1c Actual reported TRANS fragments :"}++;
        $finalcounters{$data{$analysis_read}{"captures"}." 3c Reporter fragments TRANS (final count) :"}++;
        $finalrepcounters{"1c Actual reported TRANS fragments :"}++;
        $finalrepcounters{$data{$analysis_read}{"captures"}." 3c Reporter fragments TRANS (final count) :"}++;
        }
        else{
        $counters{"26c Filtered TRANS fragments :"}++;
        $counters{$data{$analysis_read}{"captures"}." 17c Reporter fragments TRANS filtered (final count) :"}++;					
        $finalcounters{"1c Filtered TRANS fragments :"}++;
        $finalcounters{$data{$analysis_read}{"captures"}." 3c Reporter fragments TRANS filtered (final count) :"}++;
        $finalrepcounters{"1c Filtered TRANS fragments :"}++;
        $finalrepcounters{$data{$analysis_read}{"captures"}." 3c Reporter fragments TRANS filtered (final count) :"}++;
        }
        }
        
        $counters{"26a Actual reported fragments :"}++;
        $counters{$data{$analysis_read}{"captures"}." 17a Reporter fragments (final count) :"}++;
        $finalcounters{"1a Actual reported fragments :"}++;
        $finalcounters{$data{$analysis_read}{"captures"}." 3a Reporter fragments (final count) :"}++;					
        $finalrepcounters{"1a Actual reported fragments :"}++;
        $finalrepcounters{$data{$analysis_read}{"captures"}." 3a Reporter fragments (final count) :"}++;
          
          
        }
        
        
        }
      }
    }
#------------------------------------------------------------------------------------------------------------------
# ANALYSING THE CAPTURE FRAGMENTS (only non-tiled, as tiled get these into reporters above ..)
#------------------------------------------------------------------------------------------------------------------
    if (($data{$analysis_read}{$pe}{$readno}{"type"} eq "capture") && ( !$tiled_analysis ))
    {
      push @{$cap_samhash{$data{$analysis_read}{"captures"}}}, $data{$analysis_read}{$pe}{$readno}{"whole line"};
      $counters{$data{$analysis_read}{"captures"}." 15 Capture fragments (final count):"}++;
      $finalcounters{$data{$analysis_read}{"captures"}." 1 Capture fragments (final count):"}++;
      $finalrepcounters{$data{$analysis_read}{"captures"}." 1 Capture fragments (final count):"}++;
      push @{$samhash{$data{$analysis_read}{"captures"}}}, $data{$analysis_read}{$pe}{$readno}{"whole line"}; $counters{"Counters with reporters"}++;
      
      if ( ! $only_divide_bams ){    
      print CAPSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
      print CAPSAMFH "\tCO:Z:";
      print CAPSAMFH $data{$analysis_read}{"captures"};
      print CAPSAMFH "_CAP\n";
      }
      
    }
#------------------------------------------------------------------------------------------------------------------
# ANALYSING THE PROXIMITY EXCLUSION FRAGMENTS 
#------------------------------------------------------------------------------------------------------------------
    if ($data{$analysis_read}{$pe}{$readno}{"type"} eq "proximity exclusion")
    {
      $counters{$data{$analysis_read}{"captures"}." 16 Proximity exclusions (final count):"}++;
      $counters{$data{$analysis_read}{"captures"}." 2 Proximity exclusions (final count):"}++;
      $counters{$data{$analysis_read}{"captures"}." 2 Proximity exclusions (final count):"}++;
      
      if ( ! $only_divide_bams ){
      print CAPSAMFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
      print CAPSAMFH "\tCO:Z:";
      print CAPSAMFH $data{$analysis_read}{"captures"};
      print CAPSAMFH "_EXC\n";
      }
      
    }

#------------------------------------------------------------------------------------------------------------------
# The "end elses" for RESTRICTING ANALYSIS to only reads and fragments of interest - various if clauses to dig deeper only if we really want to..
#------------------------------------------------------------------------------------------------------------------

} # This is the if-not-only-filter-bams end

                                  } # This is the if any informative fragments in read loop end 			    
                            } # This is the FRAGMENTS for loop end 			    
                    } # This is the PE for loop end 
} # We passed duplicate filter
    

      
#------------------------------------------------------------------------------------------------------------------
# The ends of the rest of the main loops / ifs..
#------------------------------------------------------------------------------------------------------------------
      
    } # this is the end of else "no data in this read" - we need to have at least one capture and one reporter in order to avoid failing here..
  
  # In the end - we clear the data from the hash, avoiding to take the whole sam file into the memory..
  delete $data{$analysis_read};
  
}


#########################################################################################################################################################################
#Subroutines

sub snp_caller
{
my ($chr, $read_start, $sequence, $snp_chr, $snp_position, $snp) = @_;
if ($chr ne $snp_chr){return "out"};
if ($read_start>$snp_position or $snp_position > ($read_start + (length $sequence))){return "out"}

my $snp_read_pos = $snp_position - $read_start;
my $base_at_snp_pos = substr($sequence, $snp_read_pos,1);

if ($snp eq $base_at_snp_pos)
  {
    #print "Y\t$base_at_snp_pos\t".substr($sequence, $snp_read_pos-4,9)."\n";
    return "Y"
  }
else
  {
    #print "N\t$base_at_snp_pos\t".substr($sequence, $snp_read_pos-4,9)."\n";
    return $base_at_snp_pos
  }  
}


# This performs a binary search of a sorted array returning the start and end coordinates of the fragment 1 based - using the midpoints of the RE cut site
sub binary_search
{
    my ($arrayref, $start, $end, $counter_ref) = @_;
    #print "\n searching for $start - $end\t";
    my $value = ($start + $end)/2;
    my $array_position_min = 0;
    my $array_position_max = scalar @$arrayref-1; #needs to be -1 for the last element in the array
    my $counter =0;
    if (($value < $$arrayref[$array_position_min]) or ($value > $$arrayref[$array_position_max])){$$counter_ref{"25ee Binary search error - search outside range of restriction enzyme coords:"}++; return ("error", "error")}
    
    # Here setting the overlaps for different cutters
    
    my $start_extra=0;
    my $stop_extra=0;
    
    if ($cutter_type eq "fourcutter") {
      # This is symmertric fourcutter like dpnII or nlaIII
      $start_extra=2;
      $stop_extra=2;     
    }
    elsif ($cutter_type eq "sixcutter") {
      # This is 1:5 asymmetric sixcutter like hindIII
      $start_extra=1;
      $stop_extra=5;     
    }
    else {
      die "Unsupported cutter type --cuttertype ${cutter_type} . Stopping ! ";
    }
    
    
    for (my $i=0; $i<99; $i++)
    {
    my $mid_search = int(($array_position_min+$array_position_max)/2);
    
    if ($$arrayref[$mid_search]>$$arrayref[$mid_search+1]){$$counter_ref{"25ee Binary search error - restriction enzyme array coordinates not in ascending order:"}++; return ("error", "error")}
    

    if (($$arrayref[$mid_search] <= $value) and  ($$arrayref[$mid_search+1] > $value)) # maps the mid point of the read to a fragment
    {
      if (($$arrayref[$mid_search] <= $start+$start_extra) and  ($$arrayref[$mid_search+1] >= $end-$stop_extra)) # checks the whole read is on the fragment +/-2 to allow for the dpnII overlaps
        {
          return ($$arrayref[$mid_search], $$arrayref[$mid_search+1]-1)
        }
      else{$$counter_ref{"25ee Binary search error - fragment overlapping multiple restriction sites:"}++; return ("error", "error");}
    }
    
    elsif ($$arrayref[$mid_search] > $value){$array_position_max = $mid_search-1}    
    elsif ($$arrayref[$mid_search] < $value){$array_position_min = $mid_search+1}
    else {$$counter_ref{"25ee Binary search error - end of loop reached:"}++}
    }
    $$counter_ref{"25ee Binary search error - couldn't map read to fragments:"}++;
    return ("error", "error")
}



# This subroutine generates a gff file from the data 
sub frag_to_migout  
{
    my ($hashref, $filenameout, $fragtype, $capture) = @_;
    my %bins;
    
    if (keys %{$$hashref{$fragtype}{$capture}})
    {
      
    unless (open(MIGOUTPUT, ">$filenameout.gff")){print STDERR "Cannot open file $filenameout.gff\n";}
    foreach my $storedChr (sort keys %{$$hashref{$fragtype}{$capture}})  #{ $hash{$b} <=> $hash{$a} }  { {$hash{$storedChr}{$b}} <=> {$hash{$storedChr}{$a}} }
    {
    foreach my $storedposition (sort keys %{$$hashref{$fragtype}{$capture}{$storedChr}})
        {         
              print MIGOUTPUT "chr$storedChr\t$version\t$capture\t$storedposition\t".$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"end"}."\t".$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"value"}."\t+\t0\t.\n"
        }
    }
    
    }
}

#This subroutine generates a windowed wig track based on using the midpoint of the fragment to represent all of the reads mapping to that fragment
sub frag_to_windowed_wigout  
{
    my ($hashref, $filenameout, $fragtype, $capture, $window_size, $window_incr) = @_;
    my %bins;
    
    if (keys %{$$hashref{$fragtype}{$capture}})
    {
    
    unless (open(WIGOUTPUT, ">$filenameout\_win.wig")){print STDERR "Cannot open file $filenameout.wig\n";}
    foreach my $storedChr (sort keys %{$$hashref{$fragtype}{$capture}})  #{ $hash{$b} <=> $hash{$a} }  { {$hash{$storedChr}{$b}} <=> {$hash{$storedChr}{$a}} }
    {
    foreach my $storedposition (sort keys %{$$hashref{$fragtype}{$capture}{$storedChr}})
        {   
        
              my $startsamm = $storedposition +(($$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"end"}-$storedposition)/2);  #finds the midpoint of the fragment / half fragment
              my $int = int($startsamm / $window_size);
              my $start_bin = ($int * $window_size);
              my $diff = $startsamm - $start_bin;
              my $incr = (int(($window_size - $diff) / $window_incr) * $window_incr);
              $start_bin -= $incr;
        
                for (my $bin=$start_bin; $bin<($start_bin+$window_size); $bin+=$window_incr)
                {
                        #unless (($storedChr =~ /M|m/)||($storedChr =~ /PARP/)||($bin <= 0))
                        unless (($storedChr =~ /M|m/)||($bin <= 0))
                        {
                        $bins{$storedChr}{$bin} += $$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"value"};
                        }
                }
        }
    }       
    foreach my $storedChr (sort keys %bins)  #{ $hash{$b} <=> $hash{$a} }  { {$hash{$storedChr}{$b}} <=> {$hash{$storedChr}{$a}} }
    {
    print WIGOUTPUT "variableStep  chrom=chr$storedChr  span=$window_incr\n";
    foreach my $storedposition (sort keys %{$bins{$storedChr}})
        {   
            print WIGOUTPUT "$storedposition\t".$bins{$storedChr}{$storedposition}."\n";
        }
    }
    
    close WIGOUTPUT ;
    
    }
}



# This subroutine outputs the data from a hash of dpnII fragments of format %hash{$fragtype}{$capture}{$chr}{$fragment_start}{"end"/"value"} to wig format
sub frag_to_wigout  
{
    my ($hashref, $filenameout, $fragtype, $capture) = @_;
    
    if (keys %{$$hashref{$fragtype}{$capture}})
    {
    
    unless (open(WIGOUTPUT, ">$filenameout.wig")){print STDERR "Cannot open file $filenameout.wig\n";}
    foreach my $storedChr (sort keys %{$$hashref{$fragtype}{$capture}})  
    {
    
    print WIGOUTPUT "variableStep  chrom=chr$storedChr\n";
    
    foreach my $storedposition (sort keys %{$$hashref{$fragtype}{$capture}{$storedChr}})
        {   
        for (my $i=$storedposition; $i<=$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"end"}; $i++)
            {
            print WIGOUTPUT "$i\t".$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"value"}."\n";
            }
        }
    }
    
    close WIGOUTPUT ;
    
    }
}

# This subroutine outputs the data from a hash of dpnII fragments of format %hash{$fragtype}{$capture}{$chr}{$fragment_start}{"end"/"value"} to wig format
sub cisfrag_to_wigout  
{
    my ($hashref, $filenameout, $fragtype, $capture, $cis) = @_;
    
    if (keys %{$$hashref{$fragtype}{$capture}})
    {
    
    unless (open(WIGOUTPUT, ">$filenameout\_CISonly.wig")){print STDERR "Cannot open file $filenameout\_CISonly.wig\n";}
    my $storedChr=$cis;
    {
    
    print WIGOUTPUT "variableStep  chrom=chr$storedChr\n";
    
    foreach my $storedposition (sort keys %{$$hashref{$fragtype}{$capture}{$storedChr}})
        {   
        for (my $i=$storedposition; $i<=$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"end"}; $i++)
            {
            print WIGOUTPUT "$i\t".$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"value"}."\n";
            }
        }
    }
    
    close WIGOUTPUT ;
    
    }
}


# This subroutine outputs the data from a hash of dpnII fragments of format %hash{$fragtype}{$capture}{$chr}{$fragment_start}{"end"/"value"} to wig format
sub frag_to_wigout_normto10k  
{
    my ($hashref, $filenameout, $fragtype, $capture, $fragCountToNorm) = @_;
    
    print "fragCountToNorm $fragCountToNorm";
    
    if (keys %{$$hashref{$fragtype}{$capture}})
    {
    
    unless (open(WIGOUTPUT, ">$filenameout\_normTo10k.wig")){print STDERR "Cannot open file $filenameout\_normTo10k.wig\n";}
    foreach my $storedChr (sort keys %{$$hashref{$fragtype}{$capture}})  
    {
    
    print WIGOUTPUT "variableStep  chrom=chr$storedChr\n";
    
    foreach my $storedposition (sort keys %{$$hashref{$fragtype}{$capture}{$storedChr}})
        {   
        for (my $i=$storedposition; $i<=$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"end"}; $i++)
            {
            my $normalisedValue=0;
            if ($fragCountToNorm != 0)
              {
              $normalisedValue=sprintf "%.3f" , ((int($$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"value"})*1.0)/($fragCountToNorm*1.0))*10000 ;
              }
            print WIGOUTPUT "$i\t".$normalisedValue."\n";
            }
        }
    }
    
    close WIGOUTPUT ;
    
    }
}

# This subroutine outputs the data from a hash of dpnII fragments of format %hash{$fragtype}{$capture}{$chr}{$fragment_start}{"end"/"value"} to wig format
sub cisfrag_to_wigout_normto10k  
{
    my ($hashref, $filenameout, $fragtype, $capture, $fragCountToNorm, $cis) = @_;
    
    print "fragCountToNorm $fragCountToNorm";
    
    if (keys %{$$hashref{$fragtype}{$capture}})
    {
    
    unless (open(WIGOUTPUT, ">$filenameout\_normTo10k_CISonly.wig")){print STDERR "Cannot open file $filenameout\_normTo10k_CISonly.wig\n";}
    my $storedChr=$cis;
    {
    
    print WIGOUTPUT "variableStep  chrom=chr$storedChr\n";
    
    foreach my $storedposition (sort keys %{$$hashref{$fragtype}{$capture}{$storedChr}})
        {   
        for (my $i=$storedposition; $i<=$$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"end"}; $i++)
            {
            my $normalisedValue=0;
            if ($fragCountToNorm != 0)
              {
              $normalisedValue=sprintf "%.3f" , ((int($$hashref{$fragtype}{$capture}{$storedChr}{$storedposition}{"value"})*1.0)/($fragCountToNorm*1.0))*10000 ;
              }
            print WIGOUTPUT "$i\t".$normalisedValue."\n";
            }
        }
    }
    
    close WIGOUTPUT ;
    
    }
}

# This subroutine generates a mig/gff file (hash reference, reference to the array of the information for the 9th column, output filename)
sub migout
{
    my ($hashref, $refarray, $filenameout) = @_;
    
    #if (keys %{$$hashref{$fragtype}{$capture}})
    #{
    
    unless (open(MIGOUTPUT, ">$filenameout.gff")){print STDERR "Cannot open file $filenameout.gff\n";}
    foreach my $storedChr (sort keys %$hashref)  #{ $hash{$b} <=> $hash{$a} }  { {$hash{$storedChr}{$b}} <=> {$hash{$storedChr}{$a}} }
    {
    foreach my $storedposition (sort keys %{$$hashref{$storedChr}})
        {   
        print MIGOUTPUT "Chr$storedChr\tMIG\tsequence_feature\t$storedposition\t".$$hashref{$storedChr}{$storedposition}{"fragend"}."\t.\t.\t.\t";
        for (my $i=0; $i<scalar(@$refarray); $i++)
            {
                print MIGOUTPUT $$refarray[$i]."=".$$hashref{$storedChr}{$storedposition}{$$refarray[$i]}.";";
            }
        print MIGOUTPUT "\n"    
        }
    }
    
    close MIGOUTPUT ;
    
    #}
    
}

#This subroutine generates a mig/gff file (hash reference, reference to the array of the information for the 9th column, output filename)
sub fragtable_out
{
    my ($hashref, $refarray, $refgenomehash, $sample, $filenameout) = @_;
    unless (open(OUTPUT, ">$filenameout.txt")){print STDERR "Cannot open file $filenameout.txt\n";}
    foreach my $storedChr (sort keys %$refgenomehash)  #{ $hash{$b} <=> $hash{$a} }  { {$hash{$storedChr}{$b}} <=> {$hash{$storedChr}{$a}} }
    {
    foreach my $storedposition (sort keys %{$$hashref{$storedChr}})
        {   
        print OUTPUT "Chr$storedChr\tMIG\tsequence_feature\t$storedposition\t".$$hashref{$storedChr}{$storedposition}{"fragend"}."\t.\t.\t.\t";
        for (my $i=0; $i<scalar(@$refarray); $i++)
            {
                print OUTPUT $$refarray[$i]."=".$$hashref{$storedChr}{$storedposition}{$$refarray[$i]}.";";
            }
        print OUTPUT "\n"    
        }
    }
    close OUTPUT ;
    
}



#wigtobigwig (Filename (filename without the .wig extension), Filename for report (full filename), Description for UCSC)
#This subroutine converts a wig file into big wig format and copies it into the public folder.  It also generates a small file with the line to paste into UCSC
#if this fails to work try running: module add ucsctools  at the unix command line
sub wigtobigwig 
{
    my ($filename, $report_filehandle, $store_bigwigs_here_folder, $public_folder, $public_url, $description) = @_;
    print $report_filehandle "track type=bigWig name=\"$filename\" description=\"$description\" bigDataUrl=http://$public_url/$filename.bw\n";
    print "track type=bigWig name=\"$filename\" description=\"$description\" bigDataUrl=http://$public_url/$filename.bw\n";
    
    system ("wigToBigWig -clip $filename.wig $ucscsizes $filename.bw") == 0 or print STDOUT "couldn't bigwig $genome file $filename\n";
    my $short_filename = $filename.".bw";
    if ($short_filename =~ /(.*)\/(\V++)/) {$short_filename = $2};
    system ("mv $filename.bw $store_bigwigs_here_folder/$short_filename") == 0 or print STDOUT "couldn't move $genome file $filename\n";		
    # system ("chmod 755 $public_folder/$short_filename") == 0 or print STDOUT "couldn't chmod $genome file $filename\n";
    
    # If these are not the same - we have symlink run
    if ( $store_bigwigs_here_folder ne $public_folder )
    {
      print STDOUT "ln -fs \$\(pwd\)/$store_bigwigs_here_folder/$short_filename $public_folder/$short_filename\n";
      system("ln -fs \$\(pwd\)/$store_bigwigs_here_folder/$short_filename $public_folder/$short_filename") == 0 or print STDOUT "couldn't symlink $genome file $filename\n";
      system("ls -lh $public_folder/$short_filename") == 0 or print STDOUT "couldn't list generated symlink $genome file $public_folder/$short_filename\n";
    }
}

#This ouputs a the hash of arrays in the format: samhash{name of capture}[line of sam file]
#It uses the an array taken from the top of the input sam file to generate the headder of the sam file

sub output_hash_sam
{
  my ($hashref, $filenameout, $capture, $samheadder_arrayref) = @_;
  unless (open(HASHOUTPUT, ">$filenameout.sam")){print STDERR "Cannot open file $filenameout.sam\n";}
  for (my $i=0; $i < scalar @$samheadder_arrayref; $i++){print HASHOUTPUT $$samheadder_arrayref[$i]."\n";}  #Prints out the headder from the original sam file
    foreach my $value (@{$$hashref{$capture}})
    {
      print HASHOUTPUT $value."\n";
    }
  close HASHOUTPUT;
}

#This ouputs a 2column hash to a file
sub output_hash
{
    my ($hashref, $filehandleout_ref) = @_;
    foreach my $value (sort keys %$hashref)
    {
    print $filehandleout_ref "$value\t".$$hashref{$value}."\n";
    }        
}


#James Davies 2014
