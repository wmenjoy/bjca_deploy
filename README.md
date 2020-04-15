# 部署相关的开发脚本

## 使用说明
1. 引入函数
```bash
## 函数生效的方法
. common.sh
```

## 函数
### replaceSnapshot
1. usage
   replaceSnapshot $target $to_value
2. 说明
   用于替换pom的version
   $target可以是具体的pom文件，也可以是包含有pom的目录，可以自动替换子目录
   $to_value 表示要增加的值，比如to_value=test 那么 SNAPSHOT最后替换为test-SNAPSHOT
3. 返回值
   - 0: 表示成功
   - -1: 表示文件不存在
4. example
``` bash
#比如替换SNAPSHOT为 TEST-SNAPSHOT
replaceSnapshot  /home/var/project TEST
```
###  hasSnapshot
1. usage
   hasSnapshot $target
2. 说明
   用于检查目录或者压缩包中是否包含SNAPSHOT
   target 可以是个目录或者压缩文件
3. 返回值：
  - 0: 表示不包含
  - 1：包含
  - 2：参数为空
  - 3：文件不存在
  - 4：相关工具不存在
  - 5：不支持的文件格式
4. example
``` bash
  value=$(hasSnapshot /hello-demo/lib/hello-demo.zip)
  [ $value == 0 ] && echo "zip包不包含snapshot的jar包依赖"
```

### getPomVersion
1. usage
   getPomVersion $pomFile
2. 说明
    用于获取pom的版本号，如果没有version，取parent的pom
3. 返回值
   - 1: pom文件不存在
   - 0: 成功
   - 2: 没有version
    结果会print 
4. demo
 ```bash
  getPomVersion  /hello-demo/pom.xml
 ```
    
### replaceProperties
1. usage
   replaceProperties $workerDir
2. 说明
    使用pom里的properties替换dependency里面的version引用，便于versions:release插件操作
3. 返回值
   - 0: 成功
4. demo
``` bash
replaceProperties  /hello-demo/
```

# deploy.sh 脚本
## Usage
   deploy.sh [-s|--src] $workDir [-e|--env]环境变量 [-t|--type] [lib|serivice|pom] 
## 说明
   简单的支持pom，lib，service的编译以及发版本到maven仓库
## 例子
```bash
# 发布指定目录下，所有的jar包以及pom
deploy.sh --type "lib"  --env TEST --src $workdir 
# 发布lib下指定module test的jar包
deploy.sh --type "lib" --module test --env TEST --src $workdir 
# 发布pom文件
deploy.sh --type pom --env TEST --src $workdir 
# 发布service，只是打包
deploy.sh --type service --env TEST --src $workdir 

```


