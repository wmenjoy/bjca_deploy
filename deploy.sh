#!/bin/bash

ARGS=`getopt -o s:e:t:v:m --long src:,env:,type:, module:,version:,  -n 'deploy.sh' -- "$@"`

MVN=`which mvn`

if [ $? != 0 ]; then
   echo "参数错误 ./deploy.sh -n $name"
   exit 1
fi

# the directory which the script is located
# 脚本的位置
scriptDir=$(cd `dirname $0`; pwd)

# echo $ARGS
eval set -- "$ARGS"

while true
do
  case "$1" in
      -e|--env)
	env=$2
	shift 2
	;;
      -v|--version)
	version=$2
        shift 2
	;;
      -s|--src)
	src=$2
	shift 2
	;;
      -t|--type)
	type=$2
	shift 2
	;;
       -m|module)
	module=$2
	shift 2
	;;
      --)
        shift
        break
        ;;
      *)
        echo "不支持的参数 argument: $1，请检查"
        exit 1
        ;;
  esac
done

if [  "$#" -gt 0 ]; then
  echo "使用了多余的参数，请检查"
  for arg in $@
  do
    echo "processing $arg"
  done
  exit 1
fi

[ ! -d "$src" -o ! -f "$src/pom.xml" ] && echo "src请指向源代码地址" && exit 1

type=${type:-service}
[ ! "$type" = "service" -a ! "type" = "lib" -a ! "type" = "pom" ] && echo "type 参数必须是service, lib, pom三种" && exit 1

env=${env:-TEST}

. $scriptDir/common.sh

if [ "$env" == "TEST" ]; then
   replaceSnapshot $src TEST
else
   projectVersion=$version 
   if [ -z "$version" ]; then
  	projectVersion=`getPomVersion $src/pom.xml`
  	releaseVersion=`echo $projectVersion|sed 's/-SNAPSHOT//;'`
   fi
   ## 修改版本
   if [ $projectVersion != $version ]; then 
     $MVN  -U versions:set -DremoveSnapshot=true -DprocessAllModules=true -DnewVersion=$releaseVersion versions:use-releases   else
     $MVN -U versions:use-releases
   fi  
   
   ## 检查release
   $MVN enforcer:enforce -Drules=requireReleaseVersion   
fi

## pom 需要发版
if [ "$type" == "pom" ]; then
   $MVN -U  deploy || (echo "发布pom失败，请检查" && exit 1)
elif  [ "$type" == "pom" ]; then
   if [ -z "$module" ]; then
      $MVN -U deploy || (echo "发布jar失败，请检查" && exit 1)
   else 
      # 需要考虑重复编译某个模块的问题
      $MVN -U deploy -pl $module -am || (echo "发布jar失败，请检查" && exit 1)
   fi
else 
   $MVN -U package || (echo "发布service失败失败，请检查" && exit 1)
fi

