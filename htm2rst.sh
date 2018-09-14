#!/bin/bash

# Run this from the top level of the Flare project directory, at the same level
# as the Flare Project (flrprj) file, above the Content directory.

# The big idea here is to copy an entire Flare project's Content directory
# and change all of the Box (admonition) p-tags to tags that RST can parse.
# After this, the file is passed to htm2rst.sh for conversion to RST.



rsync -a ./Content ./Interim_source

cd ./Interim_source

printf "Removing ChapNum.\n"
find ./ -name *.htm -exec sed -i 's#<p\ class=\"ChapterNumber\">*<\/p># #g' {} +

printf "Looking for various Note tags.\n"
find ./ -name *.htm -exec sed -i 's#<p\ class=\"Note\">#<p>..\ note::\ #g' {} +
find ./ -name *.htm -exec sed -i 's#<p\ class=\"NoteUnder\">#<p>..\ note::\ #g' {} +
find ./ -name *.htm -exec sed -i 's#<p\ class=\"BoxNote\">#<p>..\ note::\ #g' {} +

printf "Looking for Tips.\n"
find ./ -name *.htm -exec sed -i 's#<p\ class=\"BoxTip\">#<p>..\ tip::\ #g' {} +

printf "Looking for BoxImportant.\n"
find ./ -name *.htm -exec sed -i 's#<p\ class=\"BoxIMPORTANT\">#<p>..\ important::\ #g' {} +
find ./ -name *.htm -exec sed -i 's#<p\ class=\"Alert\">#<p>..\ important::\ #g' {} +
printf "Looking for Warnings.\n"
find ./ -name *.htm -exec sed -i 's#<p\ class=\"BoxWARNING\">#<p>..\ warning::\ #g' {} +
find ./ -name *.htm -exec sed -i 's#<p\ class=\"EmphasisCRITICAL\">#<p>..\ warning::\ #g' {} +

#Housekeeping: if there is no RST directory, build one:
cd ..

    if [ -d RST ] ;
    then
        printf "Getting rid of old RST directory...\n"
	rm -rf ./RST
	fi

  printf "Making a new RST directory\n"

# This part converts the MadCap
# Flare source files to ReStructured Text files, and directs the output to the
# RST folder. The script then scans this folder for all mentions of images (any
# reference to .png, .svg, jpg, or .gif files) and copies all requested files
# to the relative pathname requested in the link.

printf "Converting...\n"

find ./Interim_source/Content -name '*.htm' -print > FileList.txt;

while read line ;
do
    # Pattern-match $line forward to the last slash. Back-match to the period
    # (throw out ".htm"). What's left is the filename.
    filename=${line##*/}
    filename=${filename%.*}

    # Backwards pattern match $line to the last slash (the first one it runs
    # into). What's left is the dirname. It's probably better to do all this
    # with dirname and basename commands, but I know this works.
    dirname=${line%/*}

    # If there is no directory name in the RST output that matches the current
    # dirname, then build one.
    if [ ! -d "RST/$dirname" ] ;
    then
	mkdir -p RST/"$dirname"
	fi ;

    # pandoc-convert $filename from htm to rst.
    # Output the results to ./RST/$dirname/$filename.rst
   pandoc -f html -t rst "$dirname/$filename.htm" > "RST/$dirname/$filename.rst"

done < FileList.txt

printf "Tidying up.\n"

rm FileList.txt

printf "Done with RST conversion.\n"

# Now, image files. Grep for anything in the RST that asks for a graphic file.
# Store the results in img_list.txt
printf "Searching RST files for image references.\n"

egrep -ri "*.png" ./RST/Content/* --exclude-dir=./RST/Content/Resources > img_list.txt
egrep -ri "*.svg" ./RST/Content/* --exclude-dir=./RST/Content/Resources >> img_list.txt
egrep -ri "*.jpg" ./RST/Content/* --exclude-dir=./RST/Content/Resources >> img_list.txt
egrep -ri "*.gif" ./RST/Content/* --exclude-dir=./RST/Content/Resources >> img_list.txt


while read line;
do
    # Pattern-match img_list.txt until you have just the paths and file names
    # (dirname and basename).
    # Output it to another list, pathlist.txt.

    path=${line##*Resources/Images}
    printf "$path\n" >> pathlist.txt
#    printf "path = $path\n"
done < img_list.txt

printf "Building Images directory.\n"

# if there's no directory structure already built, build it.
if [ ! -d "./RST/Content/Resources/Images" ] ;
then mkdir -p "./RST/Content/Resources/Images"
fi

 # From pathlist.txt, read the path and the file name, and write it to
 # the RST Images directory.
 printf "Copying the images.\n"
while read img_path;
do

    if [ ! -d "./RST/Content/Resources/Images/$(dirname $img_path)" ] ;
    then
    mkdir -p  "./RST/Content/Resources/Images/$(dirname $img_path)"
  fi
cp -R ./Content/Resources/Images/$(dirname $img_path)/$(basename $img_path) ./RST/Content/Resources/Images/$(dirname $img_path)/
done < pathlist.txt

printf "Tidying up.\n"

rm pathlist.txt
rm img_list.txt

printf "Done.\n"
