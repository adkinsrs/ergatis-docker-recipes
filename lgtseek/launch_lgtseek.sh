#!/bin/bash

function print_usage {
    progname=`basename $0`
    cat << END
usage: $progname -b </path/to/blast/db/dir> -d <db_prefix> -o </path/to/store/output_repository> -p <HOST_IP>
END
    exit 1
}

while getopts "b:d:o:p:" opt
do
    case $opt in
        b) blast_db_dir=$OPTARG;;
        d) blast_db=$OPTARG;;
        o) output_source=$OPTARG;;
        p) ip_host=$OPTARG;;
    esac
done

if [ -z "$ip_host" ]; then
    echo "Setting IP to 'localhost'"
    ip_host="localhost"
fi

if [ -z "$blast_db" ]; then
    echo "Setting BLASTN database to 'nt'"
    blast_db="nt"
fi

if [ -z "$blast_dir" ]; then
    echo "Must provide 'blast_db_dir' option."
    print_usage
fi

if [ -z "$output_source" ]; then
    echo "Must provide 'output_source' option."
    print_usage
fi

#########################
# MAIN
#########################

# Copy the template over to a production version of the docker-compose file
docker_compose=./docker_templates/docker-compose.yml
mongo_tmpl=./docker_templates/mongodb.tmpl
cp ${docker_compose}.tmpl $docker_compose

# Append mongodb part of template to the main docker-compose file
cat $mongo_tmpl >> $docker_compose

# Copy template to production 
blastn_plus_config=./docker_templates/blastn_plus.nt.config
cp ${blastn_plus_config}.tmpl $blastn_plus_config

remote=0 #For now, hardcoding to 0
perl -i -pe "s|###REMOTE###|$remote|" $blastn_plus_config
perl -i -pe "s|###BLAST_DB_DIR###|$blast_db_dir|" $docker_compose
perl -i -pe "s|###BLAST_DB###|/mnt/blast/$blast_db|" $blastn_plus_config
perl -i -pe "s|###OUTPUT_DATA###|$output_source|" $docker_compose
perl -i -pe "s|###IP_HOST###|$ip_host|" $docker_compose

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

docker cp $blastn_plus_config dockertemplates_ergatis_1:/opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/

printf  "\nDocker container is ready for use!\n"
printf  "In order to build the LGTSeek pipeline please point your browser to http://${ip_address}:8080/pipeline_builder\n"

exit 0
