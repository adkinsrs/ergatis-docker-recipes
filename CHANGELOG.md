# CHANGELOG

Note: This CHANGELOG is reflective of Docker versions, not the GitHub tags of the Ergatis-Docker repository

## v1.7 (November 19, 2018)
* Adding .lst as a valid extension for a list file besides .list.  The "bwa-aln" wrapper script will now accept that extension
* Corrected typo in accession file name in pipeline UI
* Put "lgtseek" into its own branch in the "ergatis-docker-recipes" Github repo.  Users should not have to worry about downloading repositories for other Ergatis Docker images.

## v1.6 (September 27, 2018)
* Added default bacterial and metazoan accession IDs lists for use in the new BLAST search setup within the Docker image.
* Incorporating improvments based on internal review of the Docker pipeline with a 'naive' end-user

## v1.5 (April 13, 2018)
* Modified pipelines
  * All not run extra analyses for non-putative-LGT reads (such as all-donor, all-recipient)
  * Putative LGT reads will be validated acros two BLASTN searches, one against metazoan accessions, and one against bacterial accessions
  * LGT will be validated if one read has hit to bacteria and other read has hit to metazoa
  * This should speed up the back end of the pipeline
* Removed Refseq reference requirement for recipient-only use case
* 'nt' BLAST database will be required, stored locally.

## v1.4 (November 14, 2017)
* Renamed setup\_container.sh to launch\_lgtseek.sh.  In addition, got rid of the interactive setup in favor of simple command line options instead.  Some options, such as use-case and input file location, were removed since they were redundant with those same options in the UI.
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
