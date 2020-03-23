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
     [ ! -x "$unzipFile" ] && echo "不支持zip，jar，war压缩包格式，请安装相关工具" && return 4
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


#
# replaceProperties
#
replaceProperties(){
  local workDir=$1
  local level=${2:-0}
  echo "操作 $workDir $level"
  local result=`echo $level|sed -n 's/[0-9]*//g'`
  [ ! -z "$result" ] && echo " replaceProperties $@ 参数错误" && return 3;
  [ ! -d $workDir ] && echo "参数必须存在" && return 1;
  [ ! -f "$workDir/pom.xml" ] && echo "$workDir/pom.xml 不存在" && return 2
  local workDir=$(cd $workDir;pwd)
 
  _replaceProperties $workDir/pom.xml  $workDir
  local result=$?
  [ ! "$result" = 0 ] && echo "更新properties失败:$workDir/pom.xml, $result" && return 1
  
  local cDir=$workDir
  for (( i=$level; i>0; i-- ))
  do
      cDir=$(cd $cDir;cd ..;pwd)
#      "更新$cDir
       echo "$cDir ====>"
       if [ -f "$cDir/pom.xml" ]; then
          _replaceProperties $cDir/pom.xml  $workDir
       else
          echo "$cDir/pom.xml文件不存在"
        fi
   done
 
  level=$(($level + 1))
  for subdir in $(ls $workDir)
  do
    # echo "操作 $subdir"
    subWorkDir=$workDir/${subdir}
    if [ "$subdir" != "." -a "$subdir" != ".." -a  -f "$subWorkDir/pom.xml" ]; then
         echo "操作$subWorkDir"
         replaceProperties $subWorkDir $level
    fi 
 done
}

resetProperties(){
 local workDir=$1
  [ ! -d $workDir ] && echo "参数必须存在" && return 1;
   local workDir=$(cd $workDir;pwd)
  [ -f "$workDir/pom.properties.xml.bak" ] && rm -rf $workDir/pom.properties.xml.bak 
  for subdir in $(ls $workDir)
  do
    # echo "操作 $subdir"
    subWorkDir=$workDir/${subdir}
    if [ "$subdir" != "." -a "$subdir" != ".." -a  -f "$subWorkDir/pom.properties.xml.bak" ]; then
         echo "操作$subWorkDir"
         repsetProperties $subWorkDir 
    fi
 done
}

_replaceProperties(){
	local pomFile=$1
	[ ! -f "$pomFile" -o ! -d "$2" ] && echo "参数错误$pomFile $2" && return 1;
	local workDir=${2//\//\\\/}
	echo "=======> replace for $pomFile:$2=========="
         localscript=`cat  "$pomFile"| awk 'in_comment&&/-->/{sub(/([^-]|-[^-])*--+>/,"");in_comment=0}in_comment{next} {gsub(/<!--+([^-]|-[^-])*--+>/,"");in_comment=sub(/<!--+.*/,"");print}'|sed '/^[[:space:]]*$/d'|awk ' mode && /<[\\\\/]properties>/ {mode=0; }  { if (mode == 1) {match($1, "<([^>]+)>([^<]+)<[^>]+>", m);if(m[2] ~ /^[0-9a-zA-Z_\-\.]+$/) {{printf "s/\\\\${%s}/%s/g;",m[1], m[2];}}}} /<properties>/{mode=1}'|sed "s/^/sed \'/;s/$/\' < ${workDir}\/pom.xml > ${workDir}\/temple.swap/"`
        localscript=`echo $localscript|sed '/^[[:blank:]]*$/d'`
        if  [ ! -z "$localscript" -o -n "$localscript" ]; then 
            echo $localscript|sh
            result=$?
            if [ -f "$2/temple.swap" -a "$result" = 0 ] ; then
                [ ! -f "$2/pom.properties.xml.bak" ]  mv $2/pom.xml $2/pom.properties.xml.bak 
                mv $2/temple.swap $2/pom.xml
            fi
            [ $result != 0 ] && echo $localscript
            return $result 
      else
          echo "empty properties"
          return 0;
       fi
}
#
# changeVersionToRelease
#
changeVersionToRelease(){
  local workDir=$1
  local releaseVersion=$2
  local mavenFile=`which mvn`
  [ -x "$mavenFile" ] && echo "没有配置maven路径" && return 2;  
  cd $workDir
  if [ -z "$releaseVersion" ]; then
  	projectVersion=`getPomVersion ./pom.xml`
  	releaseVersion=`echo $projectVersion|sed 's/-SNAPSHOT//;'`
  fi

  if [ $projectVersion != $releaseVersion ]; then 
      $mavenFile -U org.codehaus.mojo:versions-maven-plugin:2.1:set -DremoveSnapshot=true -DprocessAllModules=true -DnewVersion=$releaseVersion versions:use-releases 
   else
     $mavenFile -U versions:use-releases
   fi  
   
   for subdir in $(ls .)
   do
     #echo "操作 $subdir"
     if [ "$subdir" != "." -a "$subdir" != ".." ]; then 
	echo ${subdir}/pom.xml      
       		
        [ -f "${subdir}/pom.xml" ] && changeVersionToRelease $subdir $releaseVersion
        
     fi
   done
    [ $? = 0 ] && echo "执行成功" && return 0
    return 1;
}

