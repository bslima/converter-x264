#!/bin/bash -x

echo "Batch Converter Script ..."

if test $# -lt 1; then
	echo "Usage: $0 DIR_PATH"
	exit 1
else
	source_dir=$1	
fi

echo "Discovering files (*.avi) in $source_dir …"

find ${source_dir} -type f -name '*.mkv' -print0 | xargs -0 ls | \
	while read objs; do
	 objs="\"$objs\""
	 eval file $objs
	 echo "Calling converter to => $objs"
	 if eval [ -f $objs ]; then
	 	echo "It is a valid file"
	 else
	 	echo "NOT VALID"
	 fi
	 #eval "./converter_mp4.sh $objs"
	done

