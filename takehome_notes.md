# Grotto Transcriptomics Pipeline Takehome Notes

This document expands on the Grotto workshop notes, and walks you through how to use Grotto on your personal computer.  

Keep in mind that this interface has only recently been developed and is still under active development.  If you have any questions, comments, or suggestions feel free to send an e-mail to Shaun Adkins (sadkins@som.umaryland.edu)

## Requirements

The following tools are required in order to run Grotto;

* Docker (https://docs.docker.com/engine/installation/)
* docker-compose (https://docs.docker.com/compose/install/)
  * Typically Docker-Compose comes installed with Docker with more recent versions, but this is helpful if you find that is not the case.
* git (https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Also it is worth noting that Grotto has only been tested in the Mac and Linux OS environments.  It may not work on a Windows environment.

## Getting the RNAseq GitHub repository

The first step is to use 'git' to clone the "ergatis-docker-recipes" GitHub repository, which houses information and scripts for the "rnaseq" Docker image.  For this example, the following will take place in the user's home directory

```bash
cd ~
mkdir git; cd git
git clone https://github.com/adkinsrs/ergatis-docker-recipes.git
git checkout rnaseq
cd ergatis-docker-recipes
```

### Setting up the input area

Next, input and output areas for the "rnaseq" Docker container to read from and write to, respectively, will need to created.  For this example, we will create them in the home directory (~). The input and output directories will be mounted as volumes within the Docker container, so that the container can access them to read and write to.

NOTE:  This step is important, as the Ergatis pipeline will fail if the input_data directory is not created beforehand.

```bash
mkdir ~/input_data
```

At this point you should now move or copy the pipeline input_data to the "~/input_data" directory.

## Start the Docker containers

Now it's time to start the Grotto and RNAseq Docker containers.  The following script will run docker-compose to set up both the Grotto and RNAseq containers.  This also mounts volumes from the local machine to the Docker container for passing in input data and for collecting output data.

NOTE: for the -i and the -o options, make sure to specify the FULL PATH

```bash
cd ~/git/ergatis-docker-recipes
sh launch_rnaseq.sh -i ~/input_data
```

The first time that launch_rnaseq.sh is run should take a few minutes, as Docker needs to pull the images down the Dockerhub repository.  Subsequent executions of the command should be much quicker.

Next, in your web browser, navigate to *localhost:5000* to bring up the Grotto UI.  

### Small note before getting into it

Please do not hit the 'Back' button in the browser, as that can cause some unintended side effects.  If you make a mistake, there will be an 'edit' button for each section on the Summary page that will take you back to that section to make corrections.

## Once Grotto is up...

Follow the instructions (as per the workshop notes) to set up your pipeline noting the key differences.

* When filling out the text fields, you will need to point to the /mnt/input_data location of the file, as that will be the location of the file within the "ergatis" Docker container.  So if your filepath is ~/input_data/test.fsa, then it will need to filled in as /mnt/input_data/test.fsa
* Uploaded files, such as the "sample info file", should have their FASTQ (or SAM/BAM) paths pointing to /mnt/input_data as well.  If submitting a SAM/BAM file (in cases where you already have alignments for samples but only want analyses), place that in the "File1" section and leave "File2" blank.
* On the 'Pipeline Options' page, the repository root needs to point to /opt/projects/rnaseq as this is where it is in the RNASeq docker image.  This should be pointed there by default so do not change it.

### Acquiring configuration files for future runs

On the Summary page, each section has a "Download" link that will create a "sample_info" file or a "config form" file that can be uploaded on subsequent runs, which makes it easy to repeat samples or repeat conditions.  You can also download a "pipeline options" file but it currently cannot be uploaded at this time.

### After submitting the pipeline...

After the pipeline is made, the "Pipeline Status" page should appear.  This page, has a "Refresh" button that can be hit to get the current status of the pipeline and its components.  There is also a "View Pipeline" link that will take the user to the pipeline in Ergatis.  When the pipeline is first created, it does not run automatically, so the user needs to first click "View Pipeline" to bring the pipeline up in Ergatis, and then hit the "Rerun" button to start it.

Pipeline output should be written to /opt/output_repository.

## Starting additional pipelines

In order to create additional pipelines in Grotto, the user must click the "Grotto" logo at the top of the page, which will navigate to the "Sample Info File" page again.  This clears all information stored about the previous pipeline, which allows for a new pipeline to be created.  The previous pipeline will still be accessible on the Ergatis page (localhost:8080) and still will be running if it currently is.

## Downloading pipeline data

On Grotto's "Pipeline Status" page, when a pipeline successfully completes, the "Create BDBag" button will be enabled (from gray to blue).  Clicking that will create a BDBag object in zip format, which houses key output from the pipeline.  From here, you can either download the output as is with the "Download Bag" button, or generate reports that will be added to the BDBag with the "Generate Report" button.  If you elect to generate the reports, you can download the new BDBag object with the "Download Bag" button.

## Powering down the containers

When you have finished your pipelines, you can shut down the containers with the following commands:

```bash
cd ~/git/ergatis-docker-recipes
docker-compose down -v
```