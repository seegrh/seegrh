#!/bin/bash
FILENAME=$1
NOTE_NAME=`echo $FILENAME | sed 's/.*\///'`
NOTE_PATH=`echo $FILENAME | sed 's/'$NOTE_NAME'//'`
LOG_PATH=''

#echo -e "pwd `pwd`\nfilename $FILENAME\nnote_path $NOTE_PATH\nnote_name $NOTE_NAME"

gnsync --path $NOTE_PATH --mask $NOTE_NAME $2 $3 
#--logpath $LOG_PATH


