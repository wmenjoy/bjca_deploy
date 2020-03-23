#!/bin/bash


##
## check if the snapshot files exsits in a directory or a zip compressed file
##
hasSnapshot(){
  file=$1
  [ -z "$file" ] && echo "the checked file param is empty! Usage: hasSnapshot [$dir/$zip/$tar]" && return 2
  [ ! -f "$file" -a ! -d "$file" ] &&  echo "$file does not exists!" && return 3
  currentDir=`cd $(dirname $file); pwd` 
  if [ -d "$file" ]; then
      count=`find $currentDir -type f -name "*SNAPSHOT*.jar"|wc -l`
      [ $count -gt 0 ] && return 1
      return 0
  fi
  currentFile=${currentDir}/$(basename $file)
  suffix=${file##*.}
  ## zip or jar
  if [ "$suffix" = "zip" -o "$suffix" = "jar" -o "$suffix" = "war" ]; then
     unzipFile=`which unzip`
     [ ! -x "$unzipFile" ] && echo "不支持zip，jar，war压缩包格式，请安装相关工具" && exit 4
     count=`unzip -l $currentFile|grep "SNAPSHOT.jar"|wc -l`
     [ $count -gt 0 ] && return 1
     return 0
  fi
  
  if [  "$suffix" = "bz2" -o "$suffix" = "gz"  ]; then
     count=`tar -tzf $currentFile|grep "SNAPSHOT.jar"|wc -l`
     [ $count -gt 0 ] && return 1
     return 0
  fi
  # echo "不支持的格式$suffix for file: $cuurentFile"
  return 0
}
