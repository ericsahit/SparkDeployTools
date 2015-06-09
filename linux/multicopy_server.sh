#!/bin/bash

if [ $# -lt 4 ]; then
  echo "--------------------------------------------------------------------"
  echo "usage: ./multicopy_server.sh conf -option sourcePath destDir"
  echo "    e.g. conf=./server_conf"
  echo "    e.g. option=[untar|file|dir]"
  echo "    e.g. sourcePath=/home/eric/Downloads/hadoop-2.2.0.tar.gz"
  echo "    e.g. destDir=/home/eric"
  echo "--------------------------------------------------------------------"
  exit
fi


SERVER_CONF=$1
OPTION=$2
SOURCEPATH=$3
DESTDIR=$4

		
THISHOST=`hostname`


case $OPTION in

  "-untar" )

	tarType=`echo $SOURCEPATH | grep -o "[^[:space:]]\{2\}[[:space:]]*$"`
	DEST_NAME=`basename $SOURCEPATH`

	for p in $(sed 's/ //g' $SERVER_CONF)
	do
		      
		if [ ${p:0:1} == "#" ]; then
			continue
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")

		if [[ "x$HOSTNAME" == "x$THISHOST" ]]; then
			continue
		fi

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
			"
		else
			echo "please use \$HADOOP_TAR_DIR/hadoop-*.tar.gz"
		fi
  done # end for
  ;;
  
  ################################################################################
  "-file" )

	DEST_NAME=`basename $SOURCEPATH`

	for p in $(sed 's/ //g' $SERVER_CONF)
	do
        
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")
		
		if [[ "x$HOSTNAME" == "x$THISHOST" ]]; then
			continue
		fi

		##contents##
		expect -c "
		set timeout 86400
		spawn scp $SOURCEPATH $USERNAME@$HOSTNAME:$DESTDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		"
  done # end for
  ;;
  
  #################################################################################
  "-dir" ) # case -initial

	DEST_NAME=`basename $SOURCEPATH`

	for p in $(sed 's/ //g' $SERVER_CONF)
	do
		      
		if [ ${p:0:1} == "#" ]; then
			continue;
		fi

		USERNAME=$(echo "$p"|cut -f1 -d":")
		HOSTNAME=$(echo "$p"|cut -f2 -d":")
		PASSWORD=$(echo "$p"|cut -f3 -d":")

		if [[ "x$HOSTNAME" == "x$THISHOST" ]]; then
			continue
		fi
		
		expect -c "
		set timeout 86400 
		spawn scp -r $SOURCEPATH $USERNAME@$HOSTNAME:$DESTDIR/
			expect {
				\"*yes/no*\" {send \"yes\r\"; exp_continue}
				\"*password*\" {send \"$PASSWORD\r\"; exp_continue}
			}
		"
  done # end for
  ;;
  
esac
        

