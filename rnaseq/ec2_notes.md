# Notes on operating the Grotto UI and RNAseq container on Amazon EC2

As a prerequisite, one must have a valid Amazon EC2 instance set up, along with any associated volumes.  Please refer to [this documentation](https://github.com/IGS/Chiron/blob/master/docs/amazon_aws_setup.md) for more information on how to do this.

## After EC2 instance is set up and user has SSH'ed into it...

The next step would be to clone this git repository into the EC2 instance.  You should currently be in the home directory as user 'ubuntu'

```
mkdir git; cd git
git clone https://github.com/adkinsrs/ergatis-docker-recipes.git
```
