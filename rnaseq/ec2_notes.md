# Notes on operating the Grotto UI and RNAseq container on Amazon EC2

As a prerequisite, one must have a valid Amazon EC2 instance set up, along with any associated volumes.  Please refer to [this documentation](https://github.com/IGS/Chiron/blob/master/docs/amazon_aws_setup.md) for more information on how to do this.  Make sure that you create and attach a volume to your EC2 instance, and that all steps in "Final Steps" are followed.

Differences
* You may not have the proper security group to use with this instance, so you may have to create your own.  In security group settings open up Custom Rule TCP ports 5000 and 8080 to 0.0.0.0/0, and open up SSH port 22 to 0.0.0.0/0

## After EC2 instance is set up and user has SSH'ed into it...

The next step would be to clone this git repository into the EC2 instance.  You should currently be in the home directory as user 'ubuntu'

```
mkdir git; cd git
git clone https://github.com/adkinsrs/ergatis-docker-recipes.git
cd ergatis-docker-recipes
```

Within the 'ergatis-docker-recipes', the only directory that is of importance is the 'rnaseq' directory.  The only file of importance is the "docker-compose.yml" file, which will allow for the "grotto" and "rnaseq" containers to become linked.

### Setting up the input area
Next create an input area to copy input files over to.  This will take advantage of the attached volume from earlier (which should be mounted to /opt)

```
mkdir /opt/input_data
```

The area should be ready for the user to 'scp' or 'rsync' files over.  When using the Grotto UI, you will need to point to the /mnt/input_data location of the file, as that will be the location of the file within the "ergatis" Docker container.

In addition, the ~/git/ergatis-docker-recipes/rnaseq/docker-compose.yml will need the following line switched:
```
  - ./input_data:/mnt/input_data
to
  - /opt/input_data:/mnt/input_data
```

### Install Docker Compose

By default Docker Compose is not installed on the EC2 instance.  To install, do the following command:
```
sudo apt install docker-compose
```

### Start the Docker containers

Now it's time to start the Grotto and RNAseq Docker containers.  The following script will run docker-compose to set up both the Grotto and RNAseq containers.  This also mounts volumes from the EC2 host to the Docker container for passing in input data and for collecting output data.

```
cd ~/git/ergatis-docker-recipes/rnaseq
sh launch_rnaseq.sh -i </path/to/input/dir> -o </path/to/store/output_repository> -p "<EC2_IP>"
```

Next, navigate to <EC2_IP>:5000 to bring up the Grotto UI.  Follow the instructions to set up your pipeline noting the key differences.
* You will need to point to the /mnt/input_data location of the file, as that will be the location of the file within the "ergatis" Docker container.  So if your file on the EC2 container is /opt/input_data/test.fsa, then it will need to filled in as /mnt/input_data/test.fsa
* Currently the link to view a running pipeline within Ergatis is not correct.  To view this pipeline, after clicking the "View Pipeline" link on the "Pipeline Status" page, replace the word "localhost" in the URL with the IP address of the EC2 instance you are in.

## Powering down the containers

When you have finished your pipelines, you can shut down the containers with the following commands:

```
cd ~/git/ergatis-docker-recipes/rnaseq
docker-compose down -v
```

Note that this will remove all the pipeline data that was created within the containers, so be sure to migrate the data you want before running these commands.

## To use more than 4 processes in a pipeline

Currently the "rnaseq" pipeline will only utilize 4 processors, since the Docker image was built to do that.  However, if your Amazon EC2 instance has more than 4 processes and you wish to utilize them, do the following.

```
cd ~/git/ergatis-docker-recipes/rnaseq
docker build --no-cache -t adkinsrs/rnaseq .
```

This should take a few minutes.
