# LGTSeek pipeline

First things first...
```
git clone https://github.com/adkinsrs/ergatis-docker-recipes.git
cd ./ergatis-docker-recipes/lgtseek
```
## Requisite input files for each use case
### Use Case 1 - Good donor reference and good LGT-free recipient reference
* Donor reference (FASTA)
* Recipient reference (FASTA)

### Use Case 2 - Good donor reference but LGT-infected recipient reference
* Donor reference (FASTA)
* Recipient reference (FASTA)

### Use Case 3 - Good donor reference but unknown recipient reference
* Donor reference (FASTA)

### Use Case 4 - Good recipient reference but unknown donor reference
* Recipient reference (FASTA)

For each reference, one or more fasta-formatted files will be accepted.

### Input Data
In addition, the input file data can come from three sources.  These are: 
* The SRA ID provided is downloaded from the Sequence Read Archive. This field can be any of the following:
  * SRP - Study ID
  * SRR - Run ID
* A FASTQ input file or files associated with a single sample.  If passing paired-end files, these files should end in "\_1.fastq"/"\_2.fastq" or "R1.fastq"/"R2.fastq".  Can be compressed with GZIP before uploading
* A BAM input file or files.  Can be compressed with GZIP before uploading

#### Special note for SRS (sample) or SRX (experiment) IDs
Normally the way SRA files are acquired is by using a 'wget' command on the NCBI Trace FTP site.  However they have removed the SRS and SRX IDs from the FTP directory due to the growing size of the SRA database.  So these IDs must be converted into either SRP (study) or SRR (run) IDs which can be accomplished by searching for the SRS or SRX ID from the Run Selector at https://trace.ncbi.nlm.nih.gov/Traces/study/?go=home and using that as the input.

### BLASTN database
For all use-cases, the pipeline will perform pairwise BLASTN analysis using NCBI-blast+.  While any database can be specified to be BLASTed against, the ‘nt’ database is the recommended choice.  If you plan on running one of these use-cases, then you need to have a database on your local machine that has already been prepped with either ‘formatdb’ or ‘blastdbcmd’, so that can be mounted to a directory in the Docker container.

## Setup and start a Docker container via shell
If you wish to both configure and start a Docker container, then run 
```
./launch_lgtseek.sh -b </path/to/blast/db/dir> -B <db_prefix> -o </path/to/store/output_repository> -p <HOST_IP> -d <DONOR_INPUT_DIRECTORY> -r <RECIPIENT_INPUT_DIRECTORY>
```

This script will pass these options to a custom docker-compose file which the shell script will then use to create containers from a few Docker images.  For the -b, -d, -r, -R and the -o arguments, make sure you specify the FULL PATH.  If you are running locally, then the <HOST_IP> for -p can be set to "localhost" or the argument can be omitted entirely

### If running on Amazon EC2...
If LGTSeek is to be run on an Amazon EC2 instance, the IP host to be provided should be the public IPv4 or hostname, not the private one. 

## After the containers start...

Verify the 2 docker containers are up by running:
```
docker ps
```
This should give you valuable information such as the container ID, time it has been running, among other things

The access the UI to create your pipeline, please go to
http://<HOST_IP>:8080/pipeline_builder/.  

In your internet browser, you can access the Ergatis homepage by navigating to http://<HOST_IP>:8080/ergatis/.  This is where you can view monitor pipelines that have already been started

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
For a more detailed set of instructions (which includes the information here), please visit [the LGTSeek Docker image Google Doc page](https://docs.google.com/document/d/13ZQ2eNf3HPPNXuexkLK203dKZzjHdm12DP2yF1PLdDY/edit?usp=sharing)

## Code for the LGTSeek pipeline
Code for the LGTSeek pipeline itself can be found at https://github.com/adkinsrs/ergatis-pipelines/tree/lgtseek

## Pending issues/concerns
Pending issues
* Not all components in the pipelines are optimized for multithreading.
