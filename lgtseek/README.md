# LGTSeek pipeline

## Setting up volumes for input_data

```
cd ./lgtseek
ls input_data

donor_ref	host_ref	refseq_ref
```
These three directories are where you would place your donor reference, host reference, or RefSeq reference data respectively.  For each reference, a single fasta-formatted file will be accepted, or a list file containing the paths of fasta-formatted files in the same directory (the list file must end in .list) 

## Starting a Docker container using Docker Compose
These will use the LGTSeek pipeline as an example.

To run a docker container (from the "lgtseek" directory):
```
docker-compose up -d
```
Note that the container will run in detached mode (-d option), meaning it will run in the background.  The first time a container is created from a given image may take a little bit longer to execute, since Docker needs to pull the image from the Dockerhub registry first.

Verify the docker container is up by running:
```
docker ps
```
This should give you valuable information such as the container ID, time it has been running, among other things

The access the UI to create your pipeline, please go to
[http://localhost:8080/pipeline_builder/](http://localhost:8080/pipeline_builder/).

In your internet browser, you can access the Ergatis homepage by navigating to [http://localhost:8080/ergatis/](http://localhost:8080/ergatis/).

To stop the container, and free up valuable CPU and memory resources, run the following:
```
docker-compose down -v
```
