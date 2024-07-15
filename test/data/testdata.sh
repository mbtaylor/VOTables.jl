#!/bin/sh

# Creates some test tables using STILTS.
# See http://www.starlink.ac.uk/stilts/

nrow=10
coltypes=sf

test -r stilts.jar || curl -OL http://www.starlink.ac.uk/stilts/stilts.jar
for fmt in tabledata binary2 binary
do
   file=test-${fmt}.vot
   echo "Writing $file"
   Fmt=`echo $fmt | tr a-z A-Z`
   java -jar stilts.jar tpipe in=:test:${nrow},${coltypes} \
                              cmd='delcols f_string' \
                              ofmt="votable(format=$Fmt)" out=$file
done
