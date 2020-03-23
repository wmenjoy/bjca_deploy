#!/bin/bash


##
## check if the snapshot files exsits in a directory or a zip compressed file
##
hasSnapshot(){
  local file=$1
  [ -z "$file" ] && echo "the checked file param is empty! Usage: hasSnapshot [$dir/$zip/$tar]" && return 2
  [ ! -f "$file" -a ! -d "$file" ] &&  echo "$file does not exists!" && return 3
  local currentDir=`cd $(dirname $file); pwd` 
  if [ -d "$file" ]; then
      local count=`find $currentDir -type f -name "*SNAPSHOT*.jar"|wc -l`
      [ $count -gt 0 ] && return 1
      return 0
  fi
  local currentFile=${currentDir}/$(basename $file)
  local suffix=${file##*.}
  ## zip or jar
  if [ "$suffix" = "zip" -o "$suffix" = "jar" -o "$suffix" = "war" ]; then
     local unzipFile=`which unzip`
     [ ! -x "$unzipFile" ] && echo "不支持zip，jar，war压缩包格式，请安装相关工具" && exit 4
     local count=`unzip -l $currentFile|grep "SNAPSHOT.jar"|wc -l`
     [ $count -gt 0 ] && return 1
     return 0
  fi
  ## 处理bz2 gz`  
  if [  "$suffix" = "bz2" -o "$suffix" = "gz"  ]; then
     local count=`tar -tzf $currentFile|grep "SNAPSHOT.jar"|wc -l`
     [ $count -gt 0 ] && return 1
     return 0
  fi
  # echo "不支持的格式$suffix for file: $cuurentFile"
  return 0
}



#
# print pom
#
getPomVersion(){
  local debug=${2:-0}
  local file=$1
  [ ! -f "$file" ] && return 1;
  local currentDir=`cd $(dirname $file); pwd`
  local currentFile=${currentDir}/$(basename $file)
  [ "$debug" = 1 ] && _getPomVersion $currentFile 0 1
  local version=`_getPomVersion $currentFile 0`
  # find the parent pom
  [ -z "$version" ] && version=`_getPomVersion $currentFile 1`
  [ -z "$version" ] && return 2;  
  echo  $version
}

#
# basic method to print the version of the current pom
#
_getPomVersion(){
   local file=$1
   local mode=${2:-0}
   local debug=${3:-0}
   local currentDir=`cd $(dirname $file); pwd`
   local currentFile="${currentDir}/$(basename $file)"
   [ ! -f "$currentFile" ] && return 1;
   [ "$debug" = 1 ]  && echo $mode
   cat $currentFile|awk -v modeway=$mode -v debug=$debug 'BEGIN {mode=0} /.*/{ if(debug==1){print mode,"=",$0}}  /<plugin>/{mode=3} /<[\\\\/]plugin>/{mode=0} /<parent>/{mode=1} /<[\\\\/]parent>/{mode=0} /<dependency>/{mode=2} /<[\\\\/]dependency>/{mode=0}  /<version>([^<]*)<[\\\\/]version>/ {if(mode==modeway) { match($1, "<version>([^<]*)<[\\\\/]version>",m) }} END {print m[1]}'
}

#
# print the parent pom version of the current pom
#
getPomParentVersion(){
     local debug=${2:-0}
     _getPomVersion $1 1 $debug
}



