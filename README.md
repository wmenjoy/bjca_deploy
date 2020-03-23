# 部署相关的开发脚本

## 使用说明
1. 引入函数
```
. common.sh
```

## 函数

###  hasSnapshot
1. usage
   hasSNapshot $target
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

