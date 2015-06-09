#!/bin/bash

function usage() {
  echo "--------------------------------------------------------------------"
  echo "[usage]: ./setenv.sh -conf conf_file_name option[-download/-upload/-yum_install] [download-file-name|upload-file-path|yum-install-name]"
  echo "usage: ./setenv.sh -conf conf_file_name -option download-file-name|upload-file-path|yum-install-name"
  echo "    or using default conf: ./setenv.sh -option download-file-name|upload-file-path|yum-install-name"
  echo "    e.g. default conf=./user_host_passwds (The format of conf should be lines like username:host:password)"
  echo "--------------------------------------------------------------------"
}


if [ $# -ne 2 -a $# -ne 4 ]; then
  usage
  exit
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

CLIENT_CONF=user_host_passwds

OPTION=$1
ENV_PATH=$2
ENV_NAME=`basename $ENV_PATH`
ENV_DIR=`dirname $ENV_PATH`


bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
bin=`readlink -f $bin`

CLIENT_WORKDIR=$bin

if [ -z $CONF_PATH ]; then
	CONF_PATH=$CLIENT_WORKDIR/$CLIENT_CONF
fi

case $OPTION in


"-download" )

	if [ ! -f ./envFiles ]; then
	  mkdir ./envFiles
	fi
	# download ~/$ENV_PATH

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
	  spawn scp $USERNAME@$HOSTNAME:$ENV_PATH ./envFiles/
	    expect {
	      \"*yes/no*\" {send \"yes\r\"; exp_continue}
	      \"*password:*\" {send \"$PASSWORD\r\"; exp_continue}
	    }
	"

	if [ -f "./envFiles/$ENV_NAME" ]; then
	  break;
	fi

	done
;;

"-upload" )
	# upload ~/$ENV_PATH
	if [ -f ./envFiles/$ENV_NAME ]; then
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
		  spawn scp ./envFiles/$ENV_NAME $USERNAME@$HOSTNAME:$ENV_DIR/
		    expect {
		      \"*yes/no*\" {send \"yes\r\"; exp_continue}
		      \"*password:*\" {send \"$PASSWORD\r\"; exp_continue}
		    }
		  spawn ssh $USERNAME@$HOSTNAME \"source $ENV_PATH\"
		    expect {
		      \"*yes/no*\" {send \"yes\r\"; exp_continue}
		      \"*password:*\" {send \"$PASSWORD\r\"; exp_continue}
		    }
		"

		done
	else
	  echo "No $ENV_NAME in the dir!"
	fi
;;

"-yum_install" )
	# install glibc.i686
	for p in $(sed 's/ //g' $CONF_PATH)
	do

	if [ ${p:0:1} == "#" ]; then
	  continue;
	fi

	USERNAME=$(echo "$p"|cut -f1 -d":")
	HOSTNAME=$(echo "$p"|cut -f2 -d":")
	PASSWORD=$(echo "$p"|cut -f3 -d":")

	expect -c "
	  spawn ssh $USERNAME@$HOSTNAME \"yum -y install $ENV_PATH\"
	    expect {
	      \"*yes/no*\" {send \"yes\r\"; exp_continue}
	      \"*password:*\" {send \"$PASSWORD\r\"; exp_continue}
	    }
	" &

	done
;;

esac

