############################################################
# Dockerfile to build container rnaseq pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:devel

MAINTAINER Shaun Adkins <sadkins@som.umaryland.edu>

EXPOSE 80

# The project name
ARG PROJECT=rnaseq

#--------------------------------------------------------------------------------
# SOFTWARE

# Installed via apt-get 
#ARG BEDTOOLS_VERSION=2.25.0-1
#ARG CUMMERBUND_VERSION=2.12.0-1
#ARG FASTQC_VERSION=0.11.4+dfsg-3
#ARG FASTX_TOOLKIT_VERSION=0.0.14-1build1
#ARG HTSEQ_VERSION=0.5.4p3-2
#ARG PYTHON_VERSION=2.7
#ARG SAMTOOLS_VERSION=0.1.19-1ubuntu1
#ARG TOPHAT_VERSION=2.1.0+dfsg-1build1

ARG BOWTIE_VERSION=0.12.19

ARG CUFFLINKS_VERSION=2.0.2

ARG DESEQ_VERSION=1.10.1

ARG EDGER_VERSION=2.4.6

ARG IGV_VERSION=2.3.32

ARG R_VERSION_NEW=2.15.2
ARG R_VERSION_OLD=2.14.1

ARG UCSC_UTILS

# Lets install some packages

RUN apt-get -q update && apt-get -q install -y --no-install-recommends software-properties-common \
	bedtools=2.25.0-1 \
	fastqc=0.11.4+dfsg-3 \
	fastx-toolkit=0.0.14-1build1 \
	libmagic-dev \
	libxml2 \
	python2.7 \
	python-htseq=0.5.4p3-2 \
	r-bioc-cummerbund=2.12.0-1 \
	samtools=0.1.19-1ubuntu1 \
	tophat=2.1.0+dfsg-1build1 \
	&& apt-get -q clean autoclean \
	&& apt-get -q autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& ln -s /usr/bin/python2.7 /usr/bin/python

# Create directories needed for installs (putting here to reduce layers created)
RUN mkdir -p /usr/src/bowtie \
	&& mkdir -p /usr/src/samtools

#--------------------------------------------------------------------------------
# PROJECT REPOSITORY SETUP

# Have ergatis.ini point to new project so we can quickly access it
RUN sed -i.bak "s/CUSTOM/$PROJECT/g" /var/www/html/ergatis/cgi/ergatis.ini

USER www-data

COPY project.config /tmp/.
RUN mkdir -p /opt/projects/$PROJECT \
	&& mkdir -m 0777 /opt/projects/$PROJECT/output_repository \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/lock_files \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/project_id_repository \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/runtime \
	&& mkdir -m 0777 /opt/projects/$PROJECT/workflow/runtime/pipeline \
	&& touch /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& chmod 0666 /opt/projects/$PROJECT/workflow/project_id_repository/valid_id_repository \
	&& cp /tmp/project.config /opt/projects/$PROJECT/workflow/.

# Making this as a volume in case we'd like to pass this data to another image
VOLUME /opt/projects/$PROJECT/output_repository

# Run last bits as root
USER root
#--------------------------------------------------------------------------------
# INSTALL PIPELINE
COPY build_$PROJECT.pl /tmp/.
RUN /usr/bin/perl /tmp/build_$PROJECT.pl /opt/ergatis \ 
	&& ln -s /opt/ergatis/pipeline_builder /var/www/html/pipeline_builder

#--------------------------------------------------------------------------------
# PIPELINE_CHANGES - Files that need to deviate from the installed lgtseek pipeline in order to function in Docker

# Set number of parallel runs for changed files
RUN num_cores=$(grep -c ^processor /proc/cpuinfo) \
	&& find /opt/ergatis/pipeline_templates -type f -exec /usr/bin/perl -pi -e 's/\$;NODISTRIB\$;\s?=\s?0/\$;NODISTRIB\$;='$num_cores'/g' {} \;
#--------------------------------------------------------------------------------
# SCRIPTS -- Any addition post-setup scripts that need to be run

# Lastly change to root directory
WORKDIR /
CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
