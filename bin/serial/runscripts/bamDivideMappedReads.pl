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

# Hardcoded parameters :
my $email = 'jelena.telenius@gmail.com';
my $version = "Cb5";

# Parameters with hardcoded default value :
my $sample = "CaptureC";
my $use_umi = 0; # whether this is UMI run or not, if yes, filter based on UMI indices : ask Damien Downes how to prepare your files for pipeline, if you are interested in doing this
my $use_dump =0; #whether to create an output file with all of the non-aligning sequences

# Code excecution start values :
my $analysis_read;
my $last_read="first";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(); #defines the start time of the script (printed out into the report file later on)

# Without default values - defined here for visibility reasons
my $input_filename_path="UNDEFINEDFILENAMEPATH";
my $input_path="UNDEFINEDPATH";
my $input_filename="UNDEFINEDFILENAME";
my $help=0;
my $man=0;

my $prefix_for_output="UNDEF"; # to set default.

# Arrays
my @samheadder; # contains the headder of the sam file

# Hashes
my %data; # contains the parsed data from the sam file
my %samhash; # contains the output data for a sam file
my %fraghash; # contains the output data for each fragment, which is used to generate a wig and a mig file
my %coords_hash=(); # contains a list of all the coordinates of the mapped reads to exclude duplicates
my %counters;  # contains the data for all the counters in the script, which is outputted into the report file

# Looper testers

my $analysedReads=0;
my $notlastFragments=0;

print STDOUT "\n" ;
print STDOUT "Capture C analyser - bam divide mapped reads - version $version !\n" ;
print STDOUT "Developer email $email\n" ;
print STDOUT "\n" ;


# The GetOptions from the command line
&GetOptions
(
 "f=s"=>\ $input_filename_path,          # -f Input filename 
 "s=s"=>\ $sample,                          # -s Sample name (and the name of the folder it goes into)
 "dump"=>\ $use_dump,                       # -dump Print file of unaligned reads (sam format)
 "umi"=>\ $use_umi,                         # -umi Run contains UMI indices - alter the duplicate filter accordingly : ask Damien Downes how to prepare your files for pipeline, if you are interested in doing this
 'h|help'=>\$help,                          # -h or -help Help - prints the manual
 'man'=>\$man,                              # -man prints the manual
 "CCversion=s"=>\ $version,                 # -CCversion Cb3 or Cb4 or Cb5 (will the reads be duplicate filtered CC3 or CC4 or CC5 style ? )

);

pod2usage(1) if $help;
pod2usage(-verbose=>2) if $man;

# Printing out the parameters in the beginning of run - Jelena added this 220515

print STDOUT "Starting run with parameters :\n" ;
print STDOUT "\n" ;

print STDOUT "sample $sample\n" ;
print STDOUT "version $version\n";

print STDOUT "input_filename_path $input_filename_path\n";

pod2usage(2) unless ($input_filename_path); 

print STDOUT "\n";
print STDOUT "Generating output folder.. \n";

# Creates a folder for the output files to go into - this will be a subdirectory of the file that the script is in
my $current_directory = cwd;
my $output_path= "$current_directory/$sample\_$version";

if (-d $output_path){
}
else {
mkdir $output_path
};

# ___________________________________________

# Data prefix print - depending on run type

print STDOUT "Opening input and output files.. \n";

#Splits out the filename from the path
$input_filename=$input_filename_path;
if ($input_filename =~ /(.*)\/(\V++)/) {$input_path = $1; $input_filename = $2};
unless ($input_filename =~ /(.*).sam/) {die"filename does not match .sam, stopped "};

# Creates files for the a report and a fastq file for unaligned sequences to go into
$prefix_for_output = $1;

# ___________________________________________

my $outputfilename = "$sample\_$version/$prefix_for_output";

# Prints the statistics into the report file
my $report_filename = $outputfilename."_report_$version.txt";
my $report2_filename = $outputfilename."_report2_$version.txt";
my $report3_filename = $outputfilename."_report3_$version.txt";
my $report4_filename = $outputfilename."_report4_$version.txt";

# For the rest of the script, adding the version to the end ..
$outputfilename = "$sample\_$version/$prefix_for_output\_$version";

if ($use_dump) {
unless (open(DUMPOUTPUT, ">$outputfilename\_dump.fastq")){die "Cannot open file $outputfilename\_dump.sam , stopped ";}
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
    
    if (($bitwise & 4 ) == 4)
    {
      $counters{"06 Unmapped fragments in SAM file:"}++;
    }
    else{
      $counters{"07 Mapped fragments:"}++;
      $data{$readname}{$pe}{$readno}{"whole line"}= $line;
      
      $data{$analysis_read}{$pe}{$readno}{"chr"}=$chr;
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
      $counters{"11 Total number of reads entering the analysis :"}++;
      
      #---------------------------------------------------------------------------------------
      # Resolving the identity of the capture fragments.
      
      my %capturenames;

      for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
      {
        for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
        {
          if (defined $data{$analysis_read}{$pe}{$readno}{"chr"} )
          {
            $capturenames{$data{$analysis_read}{$pe}{$readno}{"chr"}}++;
          }
          fi
        }
      }
      
      foreach my $foundcapturesite (sort keys %capturenames)
      {
        $capturename.="".$foundcapturesite."";
        $capturecomposition.=$foundcapturesite.":".$capturenames{$foundcapturesite}." " ;
      }
      
      # Resolving the identity of the capture fragments - DONE.
      #---------------------------------------------------------------------------------------
      
      # Now we need to take into account the "weird ones" which leak through and claim to  have composition ""
      
      $weAnalyseThisRead=1
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
      
      #---------------------------------------------------------------------------------------
      # Now, printing out what we have - after all the above filters
      if ($weAnalyseThisRead==1)
      {      
        $counters{"11e Total number of reads having chromosome composition $capturecomposition : "}++;
      
      #---------------------------------------------------------------------------------------
      
      if (scalar keys %capturenames > 1 )
      {
      $counters{"11g Total number of multi-chromosome reads (not filtered) :"}++;  
      $data{$analysis_read}{"captures"}="".$capturename."";
      }

#------------------------------------------------------------------------------------------------------------------
# THE REAL DEAL REPORTING FOR LOOPS - here the destiny of the reads is finally made..
#------------------------------------------------------------------------------------------------------------------
      foreach my $foundcapturesite (sort keys %capturenames)
      {
        my $this_bunch_filename = "$sample\_$version/DIVIDEDsams/$prefix_for_output\_chromosome_".$foundcapturesite."_$version.sam";    
        unless (open(BUNCHFH, ">>$this_bunch_filename")){die "Cannot open file $this_bunch_filename , stopped ";};
        
        for (my $pe=1;$pe<=2;$pe++)  # loops through PE1 and PE2 
        {
          for (my $readno=0; $readno<4; $readno++) # loops through up to 4 fragments in each paired end read
          {
            if (defined $data{$analysis_read}{$pe}{$readno}{"chr"} )
            {
            print BUNCHFH $data{$analysis_read}{$pe}{$readno}{"whole line"};
            print BUNCHFH "\n";
            }
            fi
          }
        }
        
        close BUNCHFH ;
        
      }
      
  delete $data{$analysis_read};
  
}


