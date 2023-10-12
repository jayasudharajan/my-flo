#!/bin/bash

echo Go Jumpstart Init Script
echo # Space

read -p "Enter name of project: " fullname
read -p "Name this project $fullname? [y/N] " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo Aborting, goodbye
    exit 1
fi

echo # Space
echo Renaming...
echo # Space

# Rename folders and files
mv ./k8s/gojumpstart ./k8s/"$fullname"
mv ./gitlab-ci.yml.template ./.gitlab-ci.yml

# Go through all files and folders and replace 'gojumpstart' text with name of the project
LC_ALL=C find . -type f -name '*' ! -name "runonce*" ! -regex '.*/\..*' -exec sed -i '' s/gojumpstart/"$fullname"/ {} +

echo # Space
echo Done, you can delete this file now
echo # Space