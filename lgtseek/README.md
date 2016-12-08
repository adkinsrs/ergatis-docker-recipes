# LGTSeek pipeline

## Setting up volumes for input_data

```
cd ./lgtseek
ls input_data

donor_ref	host_ref	refseq_ref
```
These three directories are where you would place your donor reference, host reference, or RefSeq reference FASTA data respectively.  For each reference, a single fasta-formatted file will be accepted, or a list file containing the paths of fasta-formatted files in the same directory (the list file must end in .list). The donor_ref or host_ref can remain empty if you wish to not align against that particular reference, but the refseq_ref directory is required to have RefSeq sequences.

## Setup and start a Docker container via shell
If you wish to both configure and start a Docker container, then run 
```
setup_container.sh
```

This script will prompt you on various ways to set up your mounted volumes, and configure a couple components in the LGTSeek pipeline, mainly BLAST-related components.  These changes are written to a docker-compose file which is then used to start the container.

## Starting a Docker container using Docker Compose
To run a Docker container (from within the "lgtseek" directory):
```
docker-compose up -d
```
Note that the container will run in detached mode (-d option), meaning it will run in the background.  The first time a container is created from a given image may take a little bit longer to execute, since Docker needs to pull the image from the Dockerhub registry first.

## After the container starts...

Verify the docker container is up by running:
```
docker ps
```
This should give you valuable information such as the container ID, time it has been running, among other things

The access the UI to create your pipeline, please go to
[http://localhost:8080/pipeline_builder/](http://localhost:8080/pipeline_builder/).

In your internet browser, you can access the Ergatis homepage by navigating to [http://localhost:8080/ergatis/](http://localhost:8080/ergatis/).  This is where you can view monitor pipelines that have already been started

To stop the container, and free up valuable CPU and memory resources, run the following:
```
docker-compose down -v
```
