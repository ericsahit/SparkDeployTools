#!/bin/bash

function usage() {
  echo "--------------------------------------------------------------------"
  echo "usage: ./mrm -conf v -option destFile|destDir"
  echo "    or using default conf_file_name: ./mscp -option destFile|destDir"
  echo "    e.g. conf=./user_host_passwds (The format of conf should be lines like username:host:passwordOfTheUser)"
  echo "    e.g. option=[file|dir]"
  echo "    e.g. destFile=/home/eric/Downloads/a_file"
  echo "    e.g. destDir=/home/eric/a_dir"
  echo "--------------------------------------------------------------------"
}

if [ $# -ne 2 -a $# -ne 4 ]; then
  usage
  exit
fi

if [ $# -eq 2 ]; then
	echo "Using default configure \"default_conf\""
fi

if [ $# -eq 4 ]; then
	if [ $1 = "-conf" ]; then
		shift
		CONF_PATH=$1
		shift
	else
		usage
		exit
	fi
fi

CLIENT_CONF=default_conf_mrm

OPTION=$1
DEST=$2

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
bin=`readlink -f $bin`

CLIENT_WORKDIR=$bin

if [ -z $CONF_PATH ]; then
	CONF_PATH=$CLIENT_WORKDIR/$CLIENT_CONF
fi

case $OPTION in

	#########################################################################
  "-file" )

	for p in $(sed 's/ //g' $CONF_PATH)
	do
        
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")
		
		expect -c "
		set timeout 3600
		spawn ssh $USERNAME@$HOSTNAME \"rm $DEST\"
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		"
  done # end for
  ;;
  
  #########################################################################
  "-dir" ) # case -dir

	for p in $(sed 's/ //g' $CONF_PATH)
	do
		      
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")

		expect -c "
		set timeout 3600
		spawn ssh $USERNAME@$HOSTNAME \"rm -rf $DEST\"
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		"

  done # end for
  ;;
esac
        

