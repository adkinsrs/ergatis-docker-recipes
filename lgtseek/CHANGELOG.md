# CHANGELOG

Note: This CHANGELOG is reflective of Docker versions, not the GitHub tags of the Ergatis-Docker repository

* Renamed setup\_container.sh to launch\_lgtseek.sh.  In addition, got rid of the interactive setup in favor of simple command line options instead.  Some options, such as use-case and input file location, were removed since they were redundant with those same options in the UI.
* The pipeline creation UI now accepts uploads instead of text boxes for file input.  Keep in mind this copies the file in the container, rather than accesses a mount.  I also realize that there may be some difficulty in uploading some big files, and I may make modifications depending on if this is ineffective, or if the PI wants me too :-)
* All 4 use-cases will run BLASTN on the various classifications of alignments (LGT, all-donor, all-recipient, etc.)

## v1.3 (March 8, 2017)
* Redesigned the pipeline creation UI to be more user friendly
* Redesigned the setup\_container.sh script
* Lots of modifications for the pipelines in the 3 currently working use cases

## v1.2
* LGTSeek pipeline code now is pulled from the ergatis-pipelines:lgtseek Github repo.  Any changes in files that need to occur for Docker to function happen in ./changed\_pipeline\_files
* Optimized Dockerfile to reduce number of layers, mostly by concatenating RUN commands

## v1.1
* Added new starting input - BAM file
  * This is an alternative to providing an SRA ID
* Added new component - gather\_lgtview\_files
  * This will collect SRA metadata and downstream blast files in one location to easily pass to LGTView
* Added headers to the blast\_lgt\_finder "by clone" output text file
* Various code bug fixes

## v1.0
* Initial working copy of LGTSeek Docker pipeline