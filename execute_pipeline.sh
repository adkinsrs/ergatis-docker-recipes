#!/bin/bash

usage() {

	echo "Usage: $0 [OPTIONS] file"
	echo "  -k, --keep-alive                   keep alive"
	echo "  --sleep=N                          pause number seconds before exiting"
	#echo "  -t N, --threads N, --threads=N     set number of threads"
	echo "  -h, --help                         display this help and exit"
}

create_rnaseq_command() {

	# Example JSON
	# {
	#   "sample_file":"/opt/input/sample.info", 
	#   "config_file":"/opt/input/euk_rnaseq.config", 
	#   "reffile":"/opt/input/referense.fasta",
	#   "quality":"40",    # 'No' if not using qual value
	#   "gtffile":"/opt/input/annotation.gtf",
	#   "build_indexes":"yes",
	#   "quality_stats":"no",
	#   "quality_trimming":"no",
	#   "split":"no",  
	#   "alignment":"yes",
	#   "idxfile":"no",     # Filepath if wanting to use idxfile
	#   "visualization":"yes",
	#   "rpkm_analysis":"no",
	#   "annotation_format":"gtf", 
	#   "diff_gene_expr":"yes",
	#   "comparison_groups":"experiementvscontrol",
	#   "count":"no", 
	#   "file_type":"SAM",    # 'No' if not needed
	#   "sorted":"position",    # 'No' if not needed
	#   "isoform_analysis":"yes",
	#   "include_novel":"yes",
	#   "diff_isoform_analysis":"yes",
	#   "use_ref_gtf":"no", 
	#   "repository_root":"/opt/projects/rnaseq",    # Constant
	#   "ergatis_ini":"/var/www/html/ergatis/cgi/ergatis.ini",     # Constant
	#   "outdir":"/opt/projects/rnaseq",     # Constant
	#   "template_dir":"/opt/projects/ergatis/package-rnaseq/pipeline_templates/Eukaryotic_RNA_Seq_Analysis",    # Constant... either Euk path or Prok path
	#   "cufflinks_legacy":"no",
	#   "tophat_legacy":"no"
	# }

	# Assign file types from directory to variables
	sample_info=$(find $1 -type f -name "*.info")
	config_file=$(find $1 -type f -name "*.config")
	reference=$(find $1 -type f \(-name "*.fasta" -o -name "*.fa" -o -name "*.fsa" -o -name "*.fna"\) )
	annotation=$(find $1 -type f \(-name "*.gtf" -o -name "*.gff" -o -name "*.gff3"\) )
	json_file=$(find $1 -type f -name "*.json")

	# Parse JSON file with python JSON module
	json_opts=$(echo $json_file | python -mjson.tool | grep ":" | grep -ve "\"no\"")

	rnaseq_cmd=""
	# Does template dir have Prok or Euk?
	if [[ $json_optis =~ .*Prok.* ]]; then
		rnaseq_cmd="/opt/ergatis/package-rnaseq/bin/create_prok_rnaseq_config.pl"
	else
		rnaseq_cmd="/opt/ergatis/package-rnaseq/bin/create_euk_rnaseq_config.pl"
	fi

	while read -r line; do
		param=$(echo $line | cut -f1 -d:)
		val=$(echo $line | cut -f2 -d:)
		rnaseq_cmd+=" --$param"
		# If param has a value, add value to cmd
		if [[ ! $val =~ .*yes.* && ! $val =~ .*Yes.* ]]; then
			rnaseq_cmd+="=$val"
		fi
	done <<< $json_opts
	
	return $rnaseq_cmd
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
	--aws-secret|-S)
		if [ "$2" ]
		then
			secret=$2
			shift
		else
			echo "$0: missing argument to '$1' option"
			usage
			exit 1
		fi
		;;
	--aws-key|-K)
		if [ "$2" ]
		then
			key=$2
			shift
		else
			echo "$0: missing argument to '$1' option"
			usage
			exit 1
		fi
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

# Either S3 bucket or a local directory of input
input_dir=$1

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
		mkdir -p /opt/input
	fi

	if [ ! -d /opt/output ]
	then
		mkdir -p /opt/output
	fi
fi

#--------------------------------------------------------------------------------
# Amazon EC2 host instance

if [ $host_type = "ec2" ]
then
	# Download input files

	cd /opt/input

	AWS_SECRET_ACCESS_KEY=$secret
	AWS_ACCESS_KEY_ID=$key

	aws --no-sign-request s3 cp --recursive --quiet $input_dir .
	retcode=$?

	if [ $retcode -ne 0 ]
	then
		echo "$0: aws s3 cp failed: aws return code: $retcode"
		exit 1
	fi

	input_dir=/opt/input
fi

#--------------------------------------------------------------------------------
# Local host instance

if [ $host_type = "local" ]
then
	# If going this route, ensure input_dir is mounted via volume
	input_dir=/opt/input/
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
create_rnaseq_command "$input_dir"
# Some last minute modifications before running the cmd would go here
rnaseq_cmd+=" --block"
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
