#!/bin/bash

if [[ "$1" == "" ]] ; then
   echo "
   Usage: ./RUNME.bash folder [max_jobs [clipper]]

   folder	Path to the folder containing the raw reads. The raw reads must be in FastQ format,
   		and filenames must follow the format: <name>.<sis>.fastq, where <name> is the name
		of the sample, and <sis> is 1 or 2 indicating which sister read the file contains.
		Use only '1' as <sis> if you have single reads.
   max_jobs	(optional) Maximum number of jobs to run in parallel. This number can be increased,
   		but bear in mind that this process is highly I/O-intensive, and likely to crash or
		significantly slow down the hard drive if many jobs are running simultaneously. By
		default: 5.
   clipper	(optional) One of: trimmomatic, scythe, or none.
   " >&2 ;
   exit 1 ;
fi ;
if [[ "$2" == "" ]] ; then
   MAX=5 ;
else
   let MAX=$2+0 ;
fi ;
CLIPPER=$3
if [[ "$CLIPPER" == "" ]] ; then
   CLIPPER="trimmomatic"
fi ;

dir=$(readlink -f $1) ;
pac=$(dirname $(readlink -f $0)) ;
cwd=$(pwd) ;

cd $dir ;
for i in 01.raw_reads 02.trimmed_reads 03.read_quality 04.trimmed_fasta 05.assembly ; do
   if [[ ! -d $i ]] ; then mkdir $i ; fi ;
done ;

k=0 ;
for i in $dir/*.1.fastq ; do
   EXTRA="" ;
   EXTRA_MSG="" ;
   if [[ $k -ge $MAX ]] ; then
      let prek=$k-$MAX ;
      EXTRA="-l depend=afterany:${jids[$prek]}" ;
      EXTRA_MSG=" (waiting for ${jids[$prek]})"
   fi ;
   b=$(basename $i .1.fastq) ;
   mv $b.[12].fastq 01.raw_reads/ ;
   jids[$k]=$(msub -v "SAMPLE=$b,FOLDER=$dir,CLIPPER=$CLIPPER" -N "Trim-$b" $pac/run.pbs $EXTRA | grep .) ;
   echo "$b: ${jids[$k]}$EXTRA_MSG" ;
   let k=$k+1 ;
done ;

