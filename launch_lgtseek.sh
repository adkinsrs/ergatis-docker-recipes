#!/bin/bash

print_usage() {
    progname=`basename $0`
    cat << END
usage: $progname -b </path/to/blast/db/dir> -i </path/to/input/samples> -o </path/to/store/output_repository> -p <HOST_IP> -d <DONOR_INPUT_DIRECTORY> -r <RECIPIENT_INPUT_DIRECTORY>

Note - at least one of a donor input directory (-d) or a recipient input directory (-r) must be provided.

REQUIRED FIELDS:
-a)  A directory path to both bacteria and eukaryotic accession lists
-o)  A directory to store the resulting output data files
-i)  Location of the input BAM or FASTQ file(s) if electing to use them instead of SRA
-b)  The path to an 'nt' BLAST database, stored locally

The required input directories is depending on the LGTSeek use case you wish to employ
Use Case 1 - Good donor reference and good LGT-free recipient reference
	-d and -r options required
Use Case 2 - Good donor reference and good LGT-infected recipient reference
	-d and -r options required
Use Case 3 - Good donor reference but unknown recipient reference
	-d  option required
Use Case 4 - Good recipient reference but unknown donor reference
	-r option required
END
    exit 1
}

while getopts ":b:B:d:r:R:i:o:p:" opt
do
    case $opt in
        b ) blast_db_dir=$OPTARG;;
        d ) donor_path=$OPTARG;;
        r ) recipient_path=$OPTARG;;
        i ) input_source=$OPTARG;;
        o ) output_source=$OPTARG;;
        p ) ip_host=$OPTARG;;
        \? )
          echo "Invalid option: $OPTARG" 1>&2
          print_usage;;
        : )
          echo "Invalid option: $OPTARG requires an argument" 1>&2
          print_usage;;
    esac
done
shift $((OPTIND -1))


if [ -z "$ip_host" ]; then
    echo "Setting IP to 'localhost'"
    ip_host="localhost"
fi

if [ -z "$blast_db_dir" ]; then
    echo "Must provide 'blast_db_dir' option."
    print_usage
fi

if [ -z "$input_source" ]; then
    echo "Did not provide 'input_source' option so you must use SRA input only."
    input_source=""
fi

if [ -z "$output_source" ]; then
    echo "Must provide 'output_source' option."
    print_usage
fi

if [[ -z $donor_path ]] && [[ -z $recipient_path ]]; then
    echo "All LGTSeek use-cases require either the -d or -r option, or both.  Neither were provided."
    print_usage
fi

if [[ -z $donor_path ]]; then
    donor_path=""
fi

if [[ -z $recipient_path ]]; then
    recipient_path=""
fi

#########################
# MAIN
#########################

unamestr=`uname`
# Directory name of current script
if [[ "$unamestr" == 'Darwin' ]]; then
  DIR="$(dirname "$(stat -f "$0")")"
else
  DIR="$(dirname "$(readlink -f "$0")")"
fi

# Copy the template over to a production version of the docker-compose file
docker_compose=${DIR}/docker_templates/docker-compose.yml
mongo_tmpl=${DIR}/docker_templates/mongodb.tmpl
cp ${docker_compose}.tmpl $docker_compose

# Append mongodb part of template to the main docker-compose file
cat $mongo_tmpl >> $docker_compose

perl -i -pe "s|###BLAST_DB_DIR###|$blast_db_dir|" $docker_compose
perl -i -pe "s|###OUTPUT_DATA###|$output_source|" $docker_compose
perl -i -pe "s|###IP_HOST###|$ip_host|" $docker_compose
if [[ -s $input_source ]]; then
    perl -i -pe "s|###INPUT_DATA###|$input_source|" $docker_compose
fi
if [[ -s $donor_path ]]; then
	perl -i -pe "s|###DONOR_MNT###|$donor_path|" $docker_compose
fi
if [[ -s $recipient_path ]]; then
	perl -i -pe "s|###RECIPIENT_MNT###|$recipient_path|" $docker_compose
fi

# Remove leftover template ### lines from compose file
perl -i -ne 'print unless /###/;' $docker_compose

# Now, establish the following Docker containers:
# 1. ergatis_lgtseek_1
#  - Houses the Apache server and LGTview related code
# 2. ergatis_mongo_1
#  - Houses the MongoDB server
# 3. ergatis_mongodata_1
#  - A container to establish persistent MongoDB dataa

# Default docker_templates/docker-compose.yml was written to so no need to specify -f
printf  "\nGoing to build and run the Docker containers now.....\n"
dc=`which docker-compose`
$dc -f $docker_compose up -d

printf  "Docker container is done building!\n"
printf  "Next it's time to customize some things within the container\n\n";

#replace_cores=$(find /opt/ergatis/pipeline_templates -type f -exec /usr/bin/perl -pi -e 's/\$;NODISTRIB\$;\s?=\s?0/\$;NODISTRIB\$;='$num_cores'/g' {} \;)
#docker exec ergatis_lgtseek_1 $replace_cores

printf  "\nDocker container is ready for use!\n"
printf  "In order to build the LGTSeek pipeline please point your browser to http://${ip_host}:8080/pipeline_builder\n"

exit 0
