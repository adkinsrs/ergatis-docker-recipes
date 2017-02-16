############################################################
# Dockerfile to build container rnaseq pipeline image
# Builds off of the Ergatis core Dockerfile
############################################################

FROM adkinsrs/ergatis:latest

MAINTAINER Shaun Adkins <sadkins@som.umaryland.edu>

EXPOSE 80

# The project name
ARG PROJECT=rnaseq

#--------------------------------------------------------------------------------
# SOFTWARE

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

#--------------------------------------------------------------------------------
# PIPELINE_CHANGES - Files that need to deviate from the installed lgtseek pipeline in order to function in Docker

#--------------------------------------------------------------------------------
# SCRIPTS -- Any addition post-setup scripts that need to be run

# Lastly change to root directory
WORKDIR /
# ... and start apache as root
USER root
CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
