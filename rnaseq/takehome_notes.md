# Requirements

The following tools are required in order to run Grotto;

* Docker (https://docs.docker.com/engine/installation/)
* docker-compose (https://docs.docker.com/compose/install/)
* git (https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Also it is worth noting that Grotto has only been tested in the Mac and Linux OS environments.  It may not work on a Windows environment.

# Getting the RNAseq GitHub repository

The first step is to use 'git' to clone the "ergatis-docker-recipes" GitHub repository, which houses information and scripts for the "rnaseq" Docker image.  For this example, the following will take place in the user's home directory

```
cd ~
mkdir git; cd git
git clone https://github.com/adkinsrs/ergatis-docker-recipes.git
cd ergatis-docker-recipes
```

Within the 'ergatis-docker-recipes', the only directory that is of importance is the 'rnaseq' directory... the other directories can be ignored.

### Setting up the input and output areas
Next, input and output areas for the "rnaseq" Docker container to read from and write to, respectively, will need to created.  For this example, we will create them in the home directory (~). The input and output directories will be mounted as volumes within the Docker container, so that the container can access them to read and write to.

NOTE:  This step is important, as the Ergatis pipeline will fail if the input_data directory is not created beforehand.

```
mkdir ~/input_data
mkdir -m 0777 ~/output_repository
```

At this point you should now move or copy the pipeline input_data to the "/opt/input_data" directory.

### Start the Docker containers

Now it's time to start the Grotto and RNAseq Docker containers.  The following script will run docker-compose to set up both the Grotto and RNAseq containers.  This also mounts volumes from the local machine to the Docker container for passing in input data and for collecting output data.

NOTE: for the -i and the -o options, make sure to specify the FULL PATH

```
cd ~/git/ergatis-docker-recipes/rnaseq
sh launch_rnaseq.sh -i ~/input_data -o ~/output_repository
```

The first time that launch_rnaseq.sh is run should take a few minutes, as Docker needs to pull the images down the Dockerhub repository.  Subsequent executions of the command should be much quicker.

Next, in your web browser, navigate to *localhost:5000* to bring up the Grotto UI.  Follow the instructions to set up your pipeline noting the key differences.
* When filling out the text fields, you will need to point to the /mnt/input_data location of the file, as that will be the location of the file within the "ergatis" Docker container.  So if your file on the EC2 container is /opt/input_data/test.fsa, then it will need to filled in as /mnt/input_data/test.fsa
* Uploaded files, such as the "sample info file", should have their FASTQ paths pointing to /mnt/input_data as well.
* On the 'Pipeline Options' page, the repository root needs to point to /opt/projects/rnaseq as this is where it is in the RNASeq docker image.  This should be pointed there by default.

After the pipeline is made, the "Pipeline Status" page should appear.  This page, has a "Refresh" button that can be hit to get the current status of the pipeline and its components.  There is also a "View Pipeline" link that will take the user to the pipeline in Ergatis.  When the pipeline is first created, it does not run automatically, so the user needs to first click "View Pipeline" to bring the pipeline up in Ergatis, and then hit the "Rerun" button to start it.

Pipeline output should be written to /opt/output_repository.

### Starting additional pipelines

In order to create additional pipelines in Grotto, the user must click the "Grotto" logo at the top of the page, which will navigate to the "Sample Info File" page again.  This clears all information stored about the previous pipeline, which allows for a new pipeline to be created.  The previous pipeline will still be accessible on the Ergatis page (localhost:8080) and still will be running if it currently is.

## Powering down the containers

When you have finished your pipelines, you can shut down the containers with the following commands:

```
cd ~/git/ergatis-docker-recipes/rnaseq
docker-compose -f docker_templates/docker-compose.yml down -v
```

Note that this will remove all the pipeline data that was created within the containers, so be sure to migrate the data you want before running these commands.  If you do not want the volume storing the pipeline output to be destroyed, remove the "-v" option from the docker-compose command.  However, do note that specifying this directory as the output source upon running "launch_rnaseq.sh" for a second time can cause problems, such as overwriting of existing output files.
