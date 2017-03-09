# LGTSeek pipeline

## Setting up volumes for input_data

Before running the pipeline, you must know the directory paths of your input data and of your reference data, as these directories will be mounted with the LGTSeeek container in order to share information from the host to the container.  What needs to be passed in is dependent on which LGTSeek use-case you wish to use:

### Use Case 1 - Good donor reference and good LGT-free host reference
* Donor reference (FASTA)
* Host referenc (FASTA)e

### Use Case 2 - Good donor reference but unknown host reference
* Donor reference (FASTA)

### Use Case 3 - Good host reference but unknown donor reference
* Host reference (FASTA)
* RefSeq reference (FASTA)

### Use Case 4 - Good donor reference but LGT-infected host reference - (coming soon)

For each reference, a single fasta-formatted file will be accepted, or a list file containing the paths of fasta-formatted files in the same directory (the list file must end in .list). 

### Input Data
In addition, the input file data can come from three sources.  These are: 
* The SRA ID provided is downloaded from the Sequence Read Archive. This field can be any of the following:
  * SRP - Study ID
  * SRR - Run ID
  * SRS - Sample ID
  * SRX - Experiment ID
* A FASTQ input file for a single sample. Passed in one of the following ways:
  * FASTQ file path for a single-end read. Can be compressed with GZIP
  * A file with the extension ".pair", which will find the two paired-end files with the same basename located in the same directory as the ".pair" file.
  * A list file containing a single file path to either of the previously mentioned files, or two file paths for each mate of a paired-end FASTQ set. These files should end in "_1.fastq"/"_2.fastq" or "R1.fastq"/"R2.fastq". In the case of the single-end or paired-end FASTQ paths, they can be compressed with GZIP.
* A BAM input file. Passed in one of the following ways:
  * One BAM input file. Can be compressed with GZIP.
  * A list file containing the file paths of one or more BAM files. If multiple BAM files are in the list file, then all BAM files will be merged prior to performing the first BWA alignment. BAM files can be compressed with GZIP.

##  Setup and start a Docker container via shell
If you wish to both configure and start a Docker container, then run 
```
setup_container.sh
```

This script will ask various questions, such as where your input data and reference data sources are located, and how to configure BLAST.  This helps with mounting the correct directories for Docker to read, and to  configure a couple components in the LGTSeek pipeline.  These changes are written to a custom docker-compose file which the shell script will then use to create containers from a few Docker images.

## After the container starts...

Verify the docker container is up by running:
```
docker ps
```
This should give you valuable information such as the container ID, time it has been running, among other things

The access the UI to create your pipeline, please go to
[http://localhost:8080/pipeline_builder/](http://localhost:8080/pipeline_builder/).

In your internet browser, you can access the Ergatis homepage by navigating to [http://localhost:8080/ergatis/](http://localhost:8080/ergatis/).  This is where you can view monitor pipelines that have already been started

##Pausing and unpausing the container bundle
To stop and save progress
```
docker-compose -f docker_templates/docker_compose.yml stop
```
To start back up and resume progress
```
docker-compose -f docker_templates/docker_compose.yml start
```

NOTE:  The setup_container.sh shell script created a custom docker_compose.yml file in the ./docker_templates directory.  If you do not wish to use the -f option to provide the path to this file, you can simply “cd” into the docker_templates directory and run docker_compose without the -f option.

## Stopping the container
To stop the container, and free up valuable CPU and memory resources, run the following:
```
docker-compose -f docker_templates/docker-compose.yml down -v
```

## More detailed instructions
For a more detailed set of instructions, please visit [https://docs.google.com/document/d/13ZQ2eNf3HPPNXuexkLK203dKZzjHdm12DP2yF1PLdDY/edit?usp=sharing](the LGTSeek Docker image Google Doc page)

## Pending issues/concerns
Pending issues
* Currently the setup\_container.sh script filters questions by use-case, and writes the corresponding docker-compose based on the chosen use-case.  So the resulting LGTSeek Docker container is designed for the chosen use-case in mind.  If a user wants to run a pipeline using  “use-case 1” and then wants to another pipeline using “use-case 3”, the user will need to run setup\_container.sh again
* Currently choosing “Y” (for yes) to perform a NCBI BlastN query against the remote “nt” database, is very unstable and may not even work.  NCBI will restrict the number of queries and can cut off access to the server to the user if they feel that user is overloading their servers.  It is highly recommended right now to select “N” (for no) and provide a path to a database stored locally.
* Not all components in the pipelines are optimized for multithreading.

