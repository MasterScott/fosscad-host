#!/bin/sh
# megapackzip.sh - generates a zipped version of the megapack.
#

#gitrepoaddr=$(echo "https://github.com/maduce/defcad-repo.git")
#megapackzipfolder=$(echo ".")
#gitdirectory=$(echo "$megapackzipfolder/defcad-repo")
#gitziprepo=$(echo "$megapackzipfolder/zippedrepo")
#partlist=$(echo "$megapackzipfolder/.current_parts_list.lst")

#source ./config.cfg
#source ./lib/echoc.sh

#inputs folder $1 and partcategories $2 and outputs list of folders $3
function list_parts() {
local topfolder=$1
local categorylist=$2
local folderlist=$3
local tmp01=$(echo .cat$RANDOM)
local tmp02=$(echo .tmp02$RANDOM)


# generate categorylist (listted at bottom of $topfolder/README.md), delete old parts list.
cat $topfolder/README.md | sed -n "\:* Current Megapack Categories: {n;p;}" | sed 's/- //g' | sed 's/;//g' | sed 's/\s/\n/g' | sed '/^$/d' > $categorylist;
rm $folderlist > /dev/null 2>&1;

for line in $(cat $categorylist);
   do
      find $topfolder/$line -maxdepth 1 -mindepth 1 -type d >> $folderlist
   done

#remove the folders from the list that are just paths to categories and not parts
for line in $(cat $categorylist);
   do
      echo "$topfolder/$line" >> $tmp01
   done
#delete lines in .tmp01 from $folderlist
awk 'NR == FNR { list[tolower($0)]=1; next } { if (! list[tolower($0)]) print }' $tmp01 $folderlist > $tmp02 
mv $tmp02 $folderlist
rm $tmp01
}

#input $partslist output $zipfoldername. MUST use full paths.
function zipfromlist() {

local ziplist=$1;
local zipfolder=$2;
local topfolder=$3;

# create zipfolder
sudo su - $webuser -c "mkdir -p $zipfolder"

for line in $(cat $ziplist);
   do 
      local ziptarget=$(basename $line);
      local pathtopart=$(dirname $line);
      local partcategory=$(echo ${pathtopart#$topfolder/});
      local targetpath=$(echo $zipfolder/$partcategory);
      sudo su - $webuser -c "mkdir -p $targetpath"
      #clear
      echoc bluel "....Zipping $ziptarget"
      echo " from: $pathtopart"
      echo " to:   $targetpath"
      pushd $pathtopart > /dev/null 2>&1
      sudo su - $webuser -c "zip -r $targetpath/$ziptarget.zip $pathtopart/$ziptarget > /dev/null 2>&1"
      popd > /dev/null 2>&1
   done
}

# if category is deleted this will detect it and delete the corresponding zipfolder of said category 
function category_deletions() {

local oldcategorylist=$1
local newcategorylist=$2
local zipfolder=$3

local deletions=$(echo .tmp01$RANDOM)

textfile_complement $oldcategorylist $newcategorylist > $deletions
# Delete old category folders if $deletion is not empty
if [ -z "$(diff $newcategorylist $oldcategorylist)" ]; then
   echoc greenl "+No category changes detected."
else
   if [ -s "$deletions" ]; then
      echoc yellow "*Category changes detected."
      delete_blanks $deletions
      for line in $(cat $deletions);
      do
         echoc yellow "** Deleting $zipfolder/$line"
         sudo su - $webuser -c "rm -rf $zipfolder/$line"
      done
   else
      echoc greenl "+Categories have been updated :)"
   fi
fi

rm  $deletions

}

####test
#list_parts $gitdirectory $partcategories $partlist
#zipfromlist $partlist $gitziprepo $gitdirectory
#gitpullchanges $gitdirectory
