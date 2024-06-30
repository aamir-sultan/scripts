#!/bin/bash

# change directory to the folder containing the files
cd ./dev-wsl

# loop through files with numbers 1 to 10
for i in {1..9}; do
  # construct the filename using the current loop index
  filename="CentOS7.z0${i}"

  # check if the file exists
  if [ -e "$filename" ]; then
    # add the file to Git
    echo "=================================================="
    echo "Committing File Number ${i}: Filename: $filename"
    git add "$filename"

    # commit the file with a commit message indicating the file number
    git commit -m "chore: Add/Commit wsl file chunk number ${i}: Filename: $filename"

    # print a message indicating the file has been committed
    echo "File ${i} Committed, Filename: $filename"
    echo "--------------------------------------------------"
    git push
    echo "File ${i} Pushed, Filename: $filename"
    echo "=================================================="
  else
    # print a message indicating the file does not exist
    echo "File # ${i} does not exist, Filename: $filename"
    echo "=================================================="
  fi
done

