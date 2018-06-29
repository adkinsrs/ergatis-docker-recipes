#!/bin/bash

print_usage()
{
    progname=`basename $0`
    cat << END
usage: $progname -i </path/to/input/dir> -p <HOST_IP>
END
    exit 1
}

while getopts "i:p:" opt
do
    case $opt in
        i) input_source=$OPTARG;;
        p) ip_host=$OPTARG;;
    esac
done

if [ -z "$ip_host" ]; then
    echo "Setting IP to 'localhost'"
    ip_host="localhost"
fi

if [ -z "$input_source" ]; then
    echo "Must provide 'input_source' option."
    print_usage
fi

#########################
# MAIN
#########################

# Copy the template over to a production version of the docker-compose file
docker_compose=./docker_templates/docker-compose.yml
cp ${docker_compose}.tmpl $docker_compose

perl -i -pe "s|###INPUT_SOURCE###|$input_source|" $docker_compose
perl -i -pe "s|###IP_HOST###|$ip_host|" $docker_compose

# Remove leftover template ### lines from compose file
perl -i -ne 'print unless /###/;' $docker_compose

# Default docker_templates/docker-compose.yml was written to so no need to specify -f
printf  "\nGoing to build and run the Docker containers now.....\n"
dc=`which docker-compose`
$dc -f $docker_compose up -d

printf  "Docker container is done building!\n"
printf  "In order to start using the Grotto UI, please point your browser to http://${ip_host}:5000\n"
printf  "To monitor pipelines, please point your browser to http://${ip_host}:8080/ergatis\n"

exit 0
