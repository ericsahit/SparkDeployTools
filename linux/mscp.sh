#!/bin/bash


function usage() {
  echo "--------------------------------------------------------------------"
  echo "usage: ./mscp -conf conf -option sourcePath destDir"
  echo "    or using default conf: ./mscp -option sourcePath destDir"
  echo "    e.g. conf=./multi_copy_conf (The format of conf should be lines like username:host:password)"
  echo "    e.g. option=[untar|file|dir]"
  echo "    e.g. sourcePath=/home/eric/hadoop-2.2.0.tar.gz"
  echo "    e.g. destDir=/home/eric"
  echo "--------------------------------------------------------------------"
}

if [ $# -ne 3 -a $# -ne 5 ]; then
  usage
  exit
fi

if [ $# -eq 3 ]; then
	echo "Using default configure \"default_conf\""
fi

if [ $# -eq 5 ]; then
	if [ $1 = "-conf" ]; then
		shift
		CONF_PATH=$1
		shift
	else
		usage
		exit
	fi
fi

OPTION=$1
SOURCEPATH=$2
DESTDIR=$3

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
bin=`readlink -f $bin`

SERVER_WORKDIR=.sparkdeploytools/multicopy/temp
CLIENT_WORKDIR=$bin

SERVER_EXECUTABLE=multicopy_server.sh

SERVER_CONF=user_host_passwds
CLIENT_CONF=$SERVER_CONF

if [[ "$CONF_PATH" == "" ]]; then
	CONF_PATH=$CLIENT_WORKDIR/$CLIENT_CONF
fi

DEST_NAME=`basename $SOURCEPATH`
CONF_NAME=`basename $CONF_PATH`

case $OPTION in

  "-untar" ) # case -initial

	tarType=`echo $SOURCEPATH | grep -o "[^[:space:]]\{2\}[[:space:]]*$"`

	for p in $(sed 's/ //g' $CONF_PATH)
	do
        
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")
		
		SERVER_WORKDIR=/home/$USERNAME/$SERVER_WORKDIR
		SERVER_OPTIONS="$SERVER_WORKDIR/$CONF_NAME $OPTION $DESTDIR/$DEST_NAME $DESTDIR"

#spawn ssh $USERNAME@$HOSTNAME \"mkdir -p $DESTDIR\"
# expect {
#    \"*yes/no*\" {send \"yes\r\"; exp_continue}
#   \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
# }
		##contents##
		if [ $tarType == "gz" ]; then
			 expect -c "
			 set timeout 86400  
			  spawn scp $SOURCEPATH $USERNAME@$HOSTNAME:$DESTDIR/
			    expect {
			      \"*yes/no*\" {send \"yes\r\"; exp_continue}
			      \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			    }
			  spawn ssh $USERNAME@$HOSTNAME \"cd $DESTDIR; tar -zxvf $DESTDIR/$DEST_NAME \"
		      expect {
		        \"*yes/no*\" {send \"yes\r\"; exp_continue}
		        \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
		      }
		    spawn ssh $USERNAME@$HOSTNAME \"mkdir -p $SERVER_WORKDIR\"
		      expect {
		        \"*yes/no*\" {send \"yes\r\"; exp_continue}
		        \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
		      }
		    spawn scp $CLIENT_WORKDIR/$SERVER_EXECUTABLE $USERNAME@$HOSTNAME:$SERVER_WORKDIR/
			    expect {
			      \"*yes/no*\" {send \"yes\r\"; exp_continue}
			      \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			    }
			  spawn scp $CONF_PATH $USERNAME@$HOSTNAME:$SERVER_WORKDIR/
			    expect {
			      \"*yes/no*\" {send \"yes\r\"; exp_continue}
			      \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			    }
			  spawn ssh $USERNAME@$HOSTNAME \"chmod +x $SERVER_WORKDIR/$SERVER_EXECUTABLE; $SERVER_WORKDIR/$SERVER_EXECUTABLE $SERVER_OPTIONS; rm -rf $SERVER_WORKDIR\"
		      expect {
		        \"*yes/no*\" {send \"yes\r\"; exp_continue}
		        \"*password*\" {send \"$PASSWORD\r\"; exp_continue}
		      }
			  
			"
		else
			echo "please use *.tar.gz"
		fi
	
		break
  done # end for
  ;;
  ########################################################################
  "-file" )

	for p in $(sed 's/ //g' $CONF_PATH)
	do
        
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")
		
		SERVER_WORKDIR=/home/$USERNAME/$SERVER_WORKDIR
		SERVER_OPTIONS="$SERVER_WORKDIR/$CONF_NAME $OPTION $DESTDIR/$DEST_NAME $DESTDIR"

		##contents##
		expect -c "
		set timeout 86400
		spawn scp $SOURCEPATH $USERNAME@$HOSTNAME:$DESTDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn ssh $USERNAME@$HOSTNAME \"mkdir -p $SERVER_WORKDIR\"
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn scp $CLIENT_WORKDIR/$SERVER_EXECUTABLE $USERNAME@$HOSTNAME:$SERVER_WORKDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn scp $CONF_PATH $USERNAME@$HOSTNAME:$SERVER_WORKDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn ssh $USERNAME@$HOSTNAME \"chmod +x $SERVER_WORKDIR/$SERVER_EXECUTABLE; $SERVER_WORKDIR/$SERVER_EXECUTABLE $SERVER_OPTIONS; rm -rf $SERVER_WORKDIR\"
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}

		"
	
		break
  done # end for
  ;;
  
  #########################################################################
  "-dir" ) # case -initial

	for p in $(sed 's/ //g' $CONF_PATH)
	do
		      
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")

		SERVER_WORKDIR=/home/$USERNAME/$SERVER_WORKDIR
		SERVER_OPTIONS="$SERVER_WORKDIR/$CONF_NAME $OPTION $DESTDIR/$DEST_NAME $DESTDIR"
		
		expect -c "
		set timeout 86400 
		spawn scp -r $SOURCEPATH $USERNAME@$HOSTNAME:$DESTDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn ssh $USERNAME@$HOSTNAME \"mkdir -p $SERVER_WORKDIR\"
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn scp $CLIENT_WORKDIR/$SERVER_EXECUTABLE $USERNAME@$HOSTNAME:$SERVER_WORKDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn scp $CONF_PATH $USERNAME@$HOSTNAME:$SERVER_WORKDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		spawn ssh $USERNAME@$HOSTNAME \"chmod +x $SERVER_WORKDIR/$SERVER_EXECUTABLE; $SERVER_WORKDIR/$SERVER_EXECUTABLE $SERVER_OPTIONS; rm -rf $SERVER_WORKDIR\"
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}

		"
		break
  done # end for
  ;;
  *)
    echo "option $OPTION not support!"
    usage
    exit 1
  ;;
esac
        

