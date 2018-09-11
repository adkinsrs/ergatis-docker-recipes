#!/bin/bash

print_usage()
{
    progname=`basename $0`
    cat << END
usage: $progname -i </path/to/input/dir> -p <HOST_IP>
END
    exit 1
}

grotto=0

while getopts "gi:o:p:" opt
do
    case $opt in
        g) grotto=1;;
        i) input_source=$OPTARG;;
        o) output_source=$OPTARG;;
        p) ip_host=$OPTARG;;
    esac
done

if [ $# != 1 -a $grotto -eq 0 ]
then
	usage
	exit 1
fi
rnaseq_cmd=$1

if [ -z "$ip_host" ]; then
    echo "Setting IP to 'localhost'"
    ip_host="localhost"
fi

if [ -z "$input_source" ]; then
    echo "Must provide 'input_source' option."
    print_usage
fi

if [ -z "$output_source" ]; then
    $output_source=""
fi
#########################
# MAIN
#########################

# Copy the template over to a production version of the docker-compose file
docker_compose=./docker_templates/docker-compose.yml
cp ${docker_compose}.tmpl $docker_compose

# If using Grotto, uncomment out some networks and volumes
if [ $grotto -eq 1 ]; then
    grotto_tmpl=./docker_templates/grotto.tmpl
    cat $grotto_tmpl >> $docker_compose

    perl -i -pe "s|###rabbitmq###|rabbitmq|" $docker_compose
    perl -i -pe "s|###bdbag_out_vol###|bdbag_out_vol|" $docker_compose
    perl -i -pe "s|###reports_out_vol###|reports_out_vol|" $docker_compose
    perl -i -pe "s|###- --start-web-server###|- start-web-server|" $docker_compose
    perl -i -pe "s|###- --keep-alive###|- --keep-alive|" $docker_compose
else
    perl -i -pe "s|###command:###|command: \"$rnaseq_cmd\"|" $docker_compose
fi

perl -i -pe "s|###INPUT_SOURCE###|$input_source|" $docker_compose
perl -i -pe "s|###IP_HOST###|$ip_host|" $docker_compose
if [[ -s $output_source ]]; then
    perl -i -pe "s|###OUTPUT_SOURCE###|$output_source|" $docker_compose
fi

# Remove leftover template ### lines from compose file
perl -i -ne 'print unless /###/;' $docker_compose

# Default docker_templates/docker-compose.yml was written to so no need to specify -f
printf  "\nGoing to build and run the Docker containers now.....\n"
dc=`which docker-compose`
$dc -f $docker_compose up -d

printf  "Docker container is done building!\n"
if [ $grotto -eq 1 ]; then
printf  "In order to start using the Grotto UI, please point your browser to http://${ip_host}:5000\n"
fi
printf  "To monitor pipelines, please point your browser to http://${ip_host}:8080/ergatis\n"

exit 0
