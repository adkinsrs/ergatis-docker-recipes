#!/bin/bash

function quit_setup {
    printf "\nExiting setup.  Bye."
    exit 0
}

### COLORS ###
ESC_SEQ='\x1b['
COL_RESET=$ESC_SEQ'0m'
COL_GREEN=$ESC_SEQ'32;1m'
COL_BLUE=$ESC_SEQ'34;1m'

#########################
# MAIN
#########################

# Copy the template over to a production version of the docker-compose file
docker_compose=./docker_templates/docker-compose.yml
mongo_tmpl=./docker_templates/mongodb.tmpl
cp ${docker_compose}.tmpl $docker_compose

printf "\nWelcome to the LGTSeek Docker installer. Please follow the prompts below that will help the Docker container access your usable data.\n"

# Append mongodb part of template to the main docker-compose file
cat $mongo_tmpl >> $docker_compose

# Copy template to production 
blastn_plus_config=./docker_templates/blastn_plus.nt.config
cp ${blastn_plus_config}.tmpl $blastn_plus_config

# Next, figure out the BLAST db
printf  "\nPlease provide the BLAST database path (leave out the database name).\n"
printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[DB_DIRECTORY]$COL_RESET: "
read blast_dir
while [[ -z $blast_dir ]]; do
    printf  "\nThe directory path to the database is required.  Please enter one.\n$COL_GREEN[DB_DIRECTORY]$COL_RESET: "
    read blast_dir
done
if [[ $blast_dir == ..* ]]; then 
    blast_dir=../$blast_dir
elif [[ $blast_dir == .* ]]; then
    blast_dir=.$blast_dir
fi

printf  "\nWhat reference database would you like to use for BLASTN querying?  Default is 'nt'\n"
printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[BLAST_DATABASE]$COL_RESET: "
read blast_db
if [[ $blast_db == 'q' ]] || [[ $blast_db == 'quit' ]]; then
    quit_setup
fi
if [[ -z $blast_db ]]; then
    blast_db="nt"
fi


remote=0
perl -i -pe "s|###REMOTE###|$remote|" $blastn_plus_config
perl -i -pe "s|###BLAST_DB_DIR###|$blast_dir|" $docker_compose
perl -i -pe "s|###BLAST_DB###|/mnt/blast/$blast_db|" $blastn_plus_config

# Next, ask where the output data should be written to
printf  "\nNext, what directory should LGTSeek output be written to?  Note that if you close the Docker container, this output data may disappear, so it is recommended it be copied to a more permanent directory location.  If left blank, the output will be located at './output_data'\n"
printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[OUTPUT_DIRECTORY]$COL_RESET: "
read output_dir
if [[ $output_dir == 'q' ]] || [[ $output_dir == 'quit' ]]; then
    quit_setup
fi
if [[ -z $output_dir ]]; then
    output_dir='./output_data'
fi
if [[ $output_dir == ..* ]]; then 
    output_dir=../$output_dir
elif [[ $output_dir == .* ]]; then
    output_dir=.$output_dir
fi
perl -i -pe "s|###OUTPUT_DATA###|$output_dir|" $docker_compose

# Time to determine what Docker host will run the container
printf  "\nWhat IP is the docker host machine on?  Leave blank if you are using local resources for the host (localhost)\n"
printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[RUN_LOCALLY]$COL_RESET: "
read ip_address
if [[ $ip_address == 'q' ]] || [[ $ip_address == 'quit' ]]; then
    quit_setup
fi
if [[ -z $ip_address ]]; then
    ip_address='localhost'
fi
perl -i -pe "s|###IP_HOST###|$ip_address|" $docker_compose

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
docker-compose -f $docker_compose up -d

printf  "Docker container is done building!\n"
printf  "Next it's time to customize some things within the container\n\n";

docker cp $blastn_plus_config dockertemplates_ergatis_1:/opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/

printf  "\nDocker container is ready for use!\n"
printf  "In order to build the LGTSeek pipeline please point your browser to $COL_BLUE http://${ip_address}:8080/pipeline_builder $COL_RESET\n"

exit 0
