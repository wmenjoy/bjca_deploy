# 部署相关的开发脚本

## 使用说明
1. 引入函数
```
. common.sh
```

## 函数

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
 ```
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
