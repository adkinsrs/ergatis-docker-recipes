#!/bin/bash

usage() {

	echo "Usage: $0 [OPTIONS] file"
	echo "  -k, --keep-alive                   keep alive"
	echo "  --sleep=N                          pause number seconds before exiting"
	#echo "  -t N, --threads N, --threads=N     set number of threads"
	echo "  -h, --help                         display this help and exit"
}

#--------------------------------------------------------------------------------
# Process parameters

opt_a=0
opt_k=0
opt_s=0
#opt_t=0

max_threads=1

while true
do
	case $1 in

	--help|-h)
		usage
		exit
		;;
	--start-web-server)
		opt_a=1
		;;
	--keep-alive|-k)
		opt_k=1
		;;
	--sleep=?*)
		opt_s=1
		seconds=${1#*=}
		;;
	--sleep|sleep=)
		echo "$0: missing argument to '$1' option"
		usage
		exit 1
		;;
	# --threads=?*)
	# 	opt_t=1
	# 	threads=${1#*=}
	# 	;;
	# --threads=)
	# 	echo "$0: missing argument to '$1' option"
	# 	usage
	# 	exit 1
	# 	;;
	# --threads|-t)
	# 	if [ "$2" ]
	# 	then
	# 		opt_t=1
	# 		threads=$2
	# 		shift
	# 	else
	# 		echo "$0: missing argument to '$1' option"
	# 		usage
	# 		exit 1
	# 	fi
	# 	;;
	--)
		shift
		break
		;;
	-?*)
		echo "$0: invalid option: $1"
		usage
		exit 1
		;;
	*)
		break
	esac

	shift
done

if [ $# != 1 -a $opt_a -eq 0 ]
then
	usage
	exit 1
fi
rnaseq_cmd=$1

#--------------------------------------------------------------------------------
# Verify sleep seconds

if [ $opt_s -eq 1 ]
then
	if [ $seconds -lt 1 ]
	then
		echo "$0: invalid sleep number: $seconds"
		exit 1
	fi
fi

#--------------------------------------------------------------------------------
# Verify threads

# if [ $opt_t -eq 1 ]
# then
# 	if [ $threads -lt 1 ]
# 	then
# 		echo "$0: invalid thread number: $threads"
# 		exit 1
# 	fi

# 	max_threads=${threads}
# fi

#--------------------------------------------------------------------------------
# Detect host environment

if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` == ec2 ]
then
	host_type=ec2
else
	host_type=local
fi

#--------------------------------------------------------------------------------
# Verify input/output/database directories

if [ $host_type = "ec2" -o $host_type = "local" ]
then
	if [ ! -d /opt/input ]
	then
		echo "$0: directory not found: /opt/input"
		exit 1
	fi

	if [ ! -d /opt/output ]
	then
		echo "$0: directory not found: /opt/output"
		exit 1
	fi
fi

#--------------------------------------------------------------------------------
# Amazon EC2 host instance

if [ $host_type = "ec2" ]
then
	# Do stuff
fi

#--------------------------------------------------------------------------------
# Local host instance

if [ $host_type = "local" ]
then
	# Do stuff
fi

#--------------------------------------------------------------------------------
# Start apache

if [ $opt_a -eq 1 ]
then
	/usr/sbin/apachectl start
fi

#--------------------------------------------------------------------------------
# Configure/run rnaseq pipeline

export PERL5LIB=/opt/ergatis/lib/perl5

# Some last minute modifications before running the cmd would go here
rnaseq_cmd=$(echo "$rnaseq_cmd --block")
`rnaseq_cmd`

status=$?

if [ $status -ne 0 ]
then
	echo "$0: pipeline error: $status"
fi

#--------------------------------------------------------------------------------
# Verify sleep and keep-alive options - mutually exclusive

if [ $opt_s -eq 1 -a $opt_k -eq 1 ]
then
	echo "$0: specifying both sleep and keep-alive options not allowed"
	exit 1
fi

#--------------------------------------------------------------------------------
# Sleep

if [ $opt_s -eq 1 ]
then
	echo "sleeping $seconds seconds before exiting..."
	sleep $seconds
fi

#--------------------------------------------------------------------------------
# Keepalive

if [ $opt_k -eq 1 ]
then
	echo "keep alive..."
	while true
	do
		sleep 60
	done
fi

#--------------------------------------------------------------------------------
# Exit

exit $status
