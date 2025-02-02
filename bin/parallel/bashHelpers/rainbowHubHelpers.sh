#!/bin/bash

doGenomeAndHub(){

echo "hub ${hubsamplename}_${parentname}" > hub_${parentname}.txt
echo "shortLabel ${hubsamplename}_${parentname}" >> hub_${parentname}.txt
echo "longLabel ${hubsamplename}_${parentname}" >> hub_${parentname}.txt
echo "genomesFile genomes_${parentname}.txt" >> hub_${parentname}.txt
echo 'email jelena.telenius@gmail.com' >> hub_${parentname}.txt

echo "genome ${ucscBuildName}" > genomes_${parentname}.txt
echo "trackDb ${parentname}_tracks.txt" >> genomes_${parentname}.txt

}

doOneParent(){

echo track ${parentname} >> ${trackfilename}_tracks.txt
echo shortLabel ${parentname} >> ${trackfilename}_tracks.txt
echo longLabel ${parentname} >> ${trackfilename}_tracks.txt
echo type bigWig >> ${trackfilename}_tracks.txt
echo container multiWig >> ${trackfilename}_tracks.txt
echo aggregate transparentOverlay >> ${trackfilename}_tracks.txt
echo showSubtrackColorOnUi on >> ${trackfilename}_tracks.txt
echo visibility ${visibility} >> ${trackfilename}_tracks.txt
echo windowingFunction maximum >> ${trackfilename}_tracks.txt
echo html description >> ${trackfilename}_tracks.txt
echo autoScale on >> ${trackfilename}_tracks.txt
echo alwaysZero on >> ${trackfilename}_tracks.txt
echo priority 120  >> ${trackfilename}_tracks.txt
echo   >> ${trackfilename}_tracks.txt


}

doOneRawsamChild(){

# FLASHED_REdig_CM5_1190007I07Rik_L_R.bw
# track_symlinks/${folder}/${subfolder}_REdig_CM5_${capturesitelist[i]}.bw

name=$(basename ${fastqBwfile})

echo track ${name} >> ${trackfilename}_tracks.txt
echo parent ${parentname} >> ${trackfilename}_tracks.txt
echo bigDataUrl ${fastqBwfile} >> ${trackfilename}_tracks.txt
echo shortLabel ${name} >> ${trackfilename}_tracks.txt
echo longLabel ${name} >> ${trackfilename}_tracks.txt
echo type bigWig >> ${trackfilename}_tracks.txt
echo 'color 0,0,0' >> ${trackfilename}_tracks.txt
echo   >> ${trackfilename}_tracks.txt

}

doOneChild(){

# FLASHED_REdig_CM5_1190007I07Rik_L_R.bw
# track_symlinks/${folder}/${subfolder}_REdig_CM5_${capturesitelist[i]}.bw

name="${capturesitelist[i]}_${abbrev}_${folder}"

echo track ${name} >> ${trackfilename}_tracks.txt
echo parent ${parentname} >> ${trackfilename}_tracks.txt
echo bigDataUrl ${folder}/${subfolder}/${bwprefix}_${ccversion}_${capturesitelist[i]}${bwsuffix}.bw >> ${trackfilename}_tracks.txt
echo shortLabel ${name} >> ${trackfilename}_tracks.txt
echo longLabel ${name} >> ${trackfilename}_tracks.txt
echo type bigWig >> ${trackfilename}_tracks.txt

echo color ${color[$((i%19+1))]} >> ${trackfilename}_tracks.txt

echo -n color[$((i%19+1))]

echo   >> ${trackfilename}_tracks.txt

}

capturesiteListSetter(){

# FLASHED_REdig_CM5_1190007I07Rik_L_R.bw

# Ddx3y_R Y       621870  623257  Y       620870  624257  1       A

folderWithoutChr=$(echo "${folder}" | sed 's/^chr//')

# For the bigwig tracks 
capturesitelist=($(cut -f 1,2 capturesitefile_sorted.txt | grep '\s'${folderWithoutChr}'$' | cut -f 1))

# For matching the colors of the capturesite and exclusion zone tracks too.
olistrlist=($(cut -f 2,3 capturesitefile_sorted.txt | grep '^'${folderWithoutChr}'\s' | cut -f 2 | awk '{print $1-1}'))
olistplist=($(cut -f 2,4 capturesitefile_sorted.txt | grep '^'${folderWithoutChr}'\s' | cut -f 2))
excstrlist=($(cut -f 2,6 capturesitefile_sorted.txt | grep '^'${folderWithoutChr}'\s' | cut -f 2 | awk '{print $1-1}'))
excstplist=($(cut -f 2,7 capturesitefile_sorted.txt | grep '^'${folderWithoutChr}'\s' | cut -f 2))
    
}

doOneBedExclCapturesite(){

name=${capturesitelist[i]}
chr=${folder}
# for making the key - the capturesite coordinates (for bed file)
olistr=${olistrlist[i]}
olistp=${olistplist[i]}
excstr=${excstrlist[i]}
excstp=${excstplist[i]}

# Making the key - i.e. the bed lines of the capturesite and exclusion with the same color that was given above ..
# chrY    621869  623257  Ddx3y_R 1       +       621869  623257  133,0,122

# For testing purposes :
# echo "${chr} ${olistr} ${olistp} CAPTURESITE_${name} 1 + ${olistr} ${olistp} ${color[$((i%19+1))]}" | tr ' ' '\t'

echo "${chr} ${olistr} ${olistp} CAPTURESITE_${name} 1 + ${olistr} ${olistp} ${color[$((i%19+1))]}" | tr ' ' '\t' >> capturesiteExclColored_allReps.bed
echo "${chr} ${excstr} ${excstp} EXCL_${name} 1 + ${excstr} ${excstp} ${color[$((i%19+1))]}" | tr ' ' '\t' >> capturesiteExclColored_allReps.bed
}

setRainbowColors(){

# -----------------------
#  1 violet    color 162,57,91
#  2 red       color 193,28,23
#  3 orange    color 222,80,3 
#  4 orange    color 226,122,29

#  5 yellow    color 239,206,16
#  6 green     color 172,214,42
#  7 green     color 76,168,43
#  8 green     color 34,139,34

#  9 green     color 34,159,110
# 10 turqoise  color 32,178,170

# 11 blue      color 96,182,202
# 12 blue      color 127,145,195
# 13 violet    color 87,85,151

# 14 violet    color 80,46,114

# 15 violet    color 128,82,154
# 16 violet    color 166,112,184 
# 17 violet    color 166,80,160 

# 18 violet    color 166,53,140 
# 19 violet    color 166,53,112 

color[1]='162,57,91'
color[2]='193,28,23'
color[3]='222,80,3'
color[4]='226,122,29'

color[5]='239,206,16'
color[6]='172,214,42'
color[7]='76,168,43'
color[8]='34,139,34'

color[9]='34,159,110'
color[10]='32,178,170'

color[11]='96,182,202'
color[12]='127,145,195'
color[13]='87,85,151'

color[14]='80,46,114'

color[15]='128,82,154'
color[16]='166,112,184' 
color[17]='166,80,160'

color[18]='166,53,140'
color[19]='166,53,112' 

}

