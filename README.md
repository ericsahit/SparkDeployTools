# Spark自动部署工具

**本工具有一些需要Expect工具的支持实现SSH用户名和密码自动登录。**

##  1. linux\mscp
一键多节点拷贝，使用expect进行远程ssh登陆。可以实现自动解压缩tar文件，自动递归拷贝目录。会调用`multicopy_server.sh`，在远程实现分发拷贝。

原理：先拷贝到远程的一个节点，在从这个节点往其他节点拷贝，节省流量。

使用方法：```./mscp.sh [-conf conf_file_name] -option sourcePath destDir```

例如，在本地修改一个Spark-env.sh之后，将其上传到Spark目录的conf目录，覆盖原有的配置：
```
./mscp.sh -conf ./user_host_passwds -file ~/develop/conf/spark-env.sh /data/hadoopspark/spark-1.1.0-bin-hadoop2.3/conf/
```

例如拷贝Spark，需要先在本地解压缩，然后修改下列文件：

    conf/slaves（Standalone模式指定工作节点）
    conf/spark-env.sh（Standalone模式指定master IP）
    conf/hive-site.xml（如果需要hive支持）
	spark-defaults.conf（配置spark-submit时候的参数，例如指定master参数，序列化类，是否记录历史日志，Driver的内存等等）

然后拷贝Spark目录到远程节点：

```
./mscp.sh -conf ./user_host_passwds -dir /home/hadoop/develop/spark-original/spark-1.3.0-bin-hadoop2.3 /data/hadoopspark/
```

版本切换：
如果存在多个Spark版本，例如原始版本，和修改过的版本，两个版本之间需要经常切换测试。


##  2. linux\mrm.sh
一键删除多节点文件，跟mscp原理差不多，使用expect进行远程ssh登陆和自动填充密码。

##  3. linux\setenv.sh
实现了多节点的远程Download文件，远程Upload文件，远程`yum_install`.

使用方法：
```
./setenv.sh [-conf conf_file_name] option[-download/-upload/-yum_install] [download-file-name|upload-file-path|yum-install-name]
```

例如，先把服务器的`/etc/profile`下载到本地：
```
./setenv.sh -conf ./user_host_passwds-root -download /etc/profile
```

然后进行修改，例如我对`$SPARK_HOME`进行了修改，修改完毕之后，上传到服务器节点，会自动将本地的`profile`文件上传到多个节点的`/etc/profile`：
```
./setenv.sh -conf ./user_host_passwds-root -upload /etc/profile
```

如果需要远程进行`yum_intall`，例如安装java，可以：
```
./setenv.sh -conf ./user_host_passwds-root -yum_install java
```

##  4. spark/switch-spark.sh

如果修改了Spark代码，使用mscp可以将代码部署到多台节点。

如果有多个版本的Spark，例如1.1, 1.2, 1.3, 以及修改后的版本，这个工具可以迅速的进行切换。

使用方法：`switch-spark 1.1|1.2|1.3|smspark|reset|check`

例如：

```
./switch-spark.sh 1.1
```

注意设置一下下列参数：
```
#Spark所在目录
SPARK_HOME_DIR=/data/hadoopspark
#对切换的节点列表
CONF_FILE=$thisdir/user_host_passwds
```

###  5. 日志分析工具
