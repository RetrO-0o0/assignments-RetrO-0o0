#!/bin/bash

if [ $# -ne 2 ]
then
	echo "arguments are not specified"
	exit 1
fi

writestr="$2"
writefile="$1"

if [ -w "$writefile" ]
then
	echo $writestr > $writefile
else
	mkdir -p "$(dirname "$writefile")"
	if [ $? -ne 0 ]
	then
		echo "error creating the directory"
		exit 1
	fi

	echo $writestr > $writefile
	if [ $? -ne 0 ]
	then
		echo "error writing into the file"
		exit 1
	fi
fi

exit 0
