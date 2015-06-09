#!/bin/bash

if [ $# -lt 1 ]; then
  echo "No parameter, please enter \"switch-spark 1.1|1.2|1.3|smspark|reset|check\" !"
  exit
fi

this="${BASH_SOURCE-$0}"
thisdir=$(cd -P -- "$(dirname -- "$this")" && pwd -P)

OPTION=$1

if [ $OPTION != "1.1" -a $OPTION != "1.2" -a $OPTION != "1.3" -a $OPTION != "smspark" -a $OPTION != "reset" -a $OPTION != "check" ]; then
	echo "Wrong parameter, please enter \"switch-spark 1.1|1.2|1.3|smspark|reset|check\" !"
	exit
fi

#Spark所在目录
SPARK_HOME_DIR=/data/hadoopspark
#对切换的节点列表
CONF_FILE=$thisdir/user_host_passwds

############# DO NOT EDIT ##############
RUNNING_SPARK=spark-hadoop2.3
OO_SPARK=spark-hadoop2.3-1.1
OT_SPARK=spark-hadoop2.3-1.2
OTT_SPARK=spark-hadoop2.3-1.3
SM_SPARK=spark-hadoop2.3-smspark
SPARK_VERSION_TOKEN=sparkversion
########################################
total=0
counter=0

for p in $(sed 's/ //g' $CONF_FILE)
do
  if [ ${p:0:1} == "#" ]; then
		continue
	fi
	let total++
done
	
for p in $(sed 's/ //g' $CONF_FILE)
do
	      
	if [ ${p:0:1} == "#" ]; then
		continue
	fi
	
	USERNAME=$(echo "$p"|cut -f1 -d":")
	HOSTNAME=$(echo "$p"|cut -f2 -d":")
	#PASSWORD=$(echo "$p"|cut -f3 -d":")
	
	#如果设置检查Spark是否正在运行
	if [[ "$CHECKED" != "true" ]]; then
		isSparkRunning=$(ssh $HOSTNAME "ps aux | grep -E \"[M]aster|[W]orker\"")
		if [[ $isSparkRunning != "" ]]; then
			echo "SPARK is still running. Please shut it down first!!!"
			exit
		else
		  CHECKED="true"
		fi
	fi
	
	#
	if [[ "$OPTION" != "check" ]]; then
		let counter++
		if [ $counter -lt $total ]; then
			echo -n -e "\b\b\b\b\b\b\b\b\b[$counter/$total]"
		else
			echo -e "\b\b\b\b\b\b\b\b\b[$counter/$total]"
		fi
	fi

	#查看当前目录下存在的Spark版本
	allContent=`ssh $USERNAME@$HOSTNAME "ls $SPARK_HOME_DIR|grep $RUNNING_SPARK"`
	has_running=null
	has_oo=null
	has_ot=null
	has_ott=null
	has_smspark=null
	for p in $allContent
	do
		if [[ $p == $RUNNING_SPARK ]]; then
			has_running=$p
		fi
		if [[ $p == $OO_SPARK ]]; then
			has_oo=$p
		fi
		if [[ $p == $OT_SPARK ]]; then
			has_ot=$p
		fi
		if [[ $p == $OTT_SPARK ]]; then
			has_ott=$p
		fi
		if [[ $p == $SM_SPARK ]]; then
			has_smspark=$p
		fi
	done

#$has_oo 
#$OO_SPARK

function change_version() {
			if [[ $1 == "null" ]]; then
				echo "There is no $2 on $HOSTNAME"
				continue
			else
				if [[ $has_running == "null" ]]; then
					# directly rename the origional to running
					ssh $USERNAME@$HOSTNAME "mv $SPARK_HOME_DIR/$2 $SPARK_HOME_DIR/$RUNNING_SPARK"
				else
					# find who is the running one
					name=$(ssh $USERNAME@$HOSTNAME "ls $SPARK_HOME_DIR/$RUNNING_SPARK | grep \"$SPARK_VERSION_TOKEN\" | cut -f2 -d \"_\"")
					# rename the running one back and the original to running
					if [ -n "$name" ]; then
						ssh $USERNAME@$HOSTNAME "mv $SPARK_HOME_DIR/$RUNNING_SPARK $SPARK_HOME_DIR/$name; mv $SPARK_HOME_DIR/$2 $SPARK_HOME_DIR/$RUNNING_SPARK"
					else
						echo "No $SPARK_VERSION_TOKEN for $has_running on $HOSTNAME. Cannot rename"
						continue
					fi				
				fi
			fi
}

	
	case $OPTION in
		"1.1" )
			change_version $has_oo $OO_SPARK
		;;
		
		"1.2" )
			change_version $has_ot $OT_SPARK
		;;

		"1.3" )
			change_version $has_ott $OTT_SPARK
		;;
		
		"smspark" )
			change_version $has_smspark $SM_SPARK
		;;
		
		"reset" )
			if [[ $has_running == "null" ]]; then
			  echo "No running one to reset on $HOSTNAME"
			else
				# find who is the running one
				name=$(ssh $USERNAME@$HOSTNAME "ls $SPARK_HOME_DIR/$RUNNING_SPARK | grep \"$SPARK_VERSION_TOKEN\" | cut -f2 -d \"_\"")
				# rename the running one back.
				if [ -n "$name" ]; then
					ssh $USERNAME@$HOSTNAME "mv $SPARK_HOME_DIR/$RUNNING_SPARK $SPARK_HOME_DIR/$name"
				else
					echo "No $SPARK_VERSION_TOKEN for $has_running on $HOSTNAME. Cannot rename"
					continue
				fi	
			fi
		;;
		
		"check" )
			# find who is the running one
			name=$(ssh $USERNAME@$HOSTNAME "ls $SPARK_HOME_DIR/$RUNNING_SPARK | grep \"$SPARK_VERSION_TOKEN\" | cut -f2 -d \"_\"")
			# rename the running one back and the ADMP to running
			opt=$(echo $name | cut -f3 -d "-")
			echo $opt
			break
		;;
		
		* )
			echo "option <$OPTION> not support."
		;;

	esac

done


