#!/bin/bash

set -e # Exit on error

# Overview:
#   - Unzips the lovejs compilation
#   - moves contents from inner folder to root of web build
#   - replaces auto-generated index.html with a more minimal one
#

name="$1"
build_dir="../build/lovejs"
folder="${build_dir}/${name}"
zipfile="${folder}-lovejs.zip"

unzip "$zipfile" -d "$build_dir"
rm -f "$zipfile"

mv ${folder}/* "$build_dir"
rmdir ${folder}

cp index.html "${build_dir}/index.html"
