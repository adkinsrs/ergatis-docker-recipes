#!/bin/bash

function quit_setup {
    printf "\nExiting setup.  Bye."
    exit 0
}

### COLORS ###
ESC_SEQ='\x1b['
COL_RESET=$ESC_SEQ'0m'
COL_GREEN=$ESC_SEQ'32;1m'
COL_BLUE=$ESC_SEQ'34;1m'

#########################
# MAIN
#########################

# Copy the template over to a production version of the docker-compose file
docker_compose=./docker_templates/docker-compose.yml
mongo_tmpl=./docker_templates/mongodb.tmpl
cp ${docker_compose}.tmpl $docker_compose

printf "\nWelcome to the LGTSeek Docker installer. Please follow the prompts below that will help the Docker container access your usable data.\n"

# Get Use-Case information to pare down setup options
printf "\nFirst, let's figure out which LGTSeek Use Case you wish to employ\n"
printf "Use Case 1 - Good donor reference and good LGT-free recipient reference\n"
printf "Use Case 2 - Good donor reference and good LGT-infected recipient reference\n"
printf "Use Case 3 - Good donor reference but unknown recipient reference\n"
printf "Use Case 4 - Good recipient reference but unknown donor reference\n"

PS3="Select a Use Case # (1-4 or 5 to quit) and press ENTER: "
options=("Use Case 1" "Use Case 2" "Use Case 3" "Use Case 4" "Exit Setup")
use_case=''
select opt in "${options[@]}"
do
   case $opt in
        "Use Case 1")
            echo "Use case 1 chosen"
             use_case=1
             break
            ;;
        "Use Case 2")
            echo "Use case 2 chosen"
            use_case=2
            break
            ;;
        "Use Case 3")
            echo "Use case 3 chosen"
            use_case=3
            break
            ;;
        "Use Case 4")
            echo "Use case 4 chosen"
            use_case=4
            break
            ;;
        "Exit Setup")
            quit_setup
            ;;
        *) echo "invalid option... choose again (1-4 or 5 to quit)."
            continue
            ;;
    esac
done

printf "\nNext it's time to specify where the reference and input files are located.\n"

# First ask for location of donor reference directory
if [[ $use_case == '1' ]] || [[ $use_case == '2' ]] || [[ $use_case == '3' ]]; then
	printf  "\nPlease specify the directory that the donor reference genome(s) is located.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[DONOR_DIRECTORY]$COL_RESET: "
	read donor_mnt
	while [[ -z $donor_mnt ]]; do
	    printf  "\nThe donor reference genome directory path is required.  Please enter one.\n$COL_GREEN[DONOR_DIRECTORY]$COL_RESET: " 
	    read donor_mnt
	done
	if [[ $donor_mnt == 'q' ]] || [[ $donor_mnt == 'quit' ]]; then
	    quit_setup
	fi
# Handle relative directory paths (file name has to be relative to docker-compose file location)
	if [[ $donor_mnt == ..* ]]; then 
		donor_mnt=../$donor_mnt
	elif [[ $donor_mnt == .* ]]; then
		donor_mnt=.$donor_mnt
	fi
# Make the in-place substitution using perl
	perl -i -pe "s|###DONOR_MNT###|$donor_mnt|" $docker_compose
fi

# Second ask for location of recipient reference directory
if [[ $use_case == '1' ]] || [[ $use_case == '2' ]] || [[ $use_case == '4' ]]; then
	printf  "\nPlease specify the directory that the recipient reference genome(s) is located.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[RECIPIENT_DIRECTORY]$COL_RESET: "
	read recipient_mnt
	while [[ -z $recipient_mnt ]]; do
	    printf  "\nThe recipient reference genome directory path is required.  Please enter one.\n$COL_GREEN[RECIPIENT_DIRECTORY]$COL_RESET: "
	    read recipient_mnt
	done
	if [[ $recipient_mnt == 'q' ]] || [[ $recipient_mnt == 'quit' ]]; then
	    quit_setup
	fi
	if [[ $recipient_mnt == ..* ]]; then 
		recipient_mnt=../$recipient_mnt
	elif [[ $recipient_mnt == .* ]]; then
		recipient_mnt=.$recipient_mnt
	fi
	perl -i -pe "s|###RECIPIENT_MNT###|$recipient_mnt|" $docker_compose
fi

# Third ask for location of Refseq reference directory
if [[ $use_case == '4' ]]; then
	printf  "\nPlease specify the directory that the RefSeq reference genomes are located.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[REFSEQ_DIRECTORY]$COL_RESET: "
	read refseq_mnt
	while [[ -z $refseq_mnt ]]; do
	    printf  "\nThe RefSeq reference genome directory path is required.  Please enter one.\n$COL_GREEN[REFSEQ_DIRECTORY]$COL_RESET: "
	    read refseq_mnt
	done
	if [[ $refseq_mnt == 'q' ]] || [[ $refseq_mnt == 'quit' ]]; then
	    quit_setup
	fi
	if [[ $refseq_mnt == ..* ]]; then 
		refseq_mnt=../$refseq_mnt
	elif [[ $refseq_mnt == .* ]]; then
		refseq_mnt=.$refseq_mnt
	fi
	perl -i -pe "s|###REFSEQ_MNT###|$refseq_mnt|" $docker_compose
fi

# Next, need to determine input format
printf "\nNext, which type of input do you plan to use?\n"
PS3="Select an input type (1-3 or 4 to quit) and press ENTER: "
options=("SRA" "FASTQ" "BAM" "Exit Setup")
input=''
select opt in "${options[@]}"
do
   case $opt in
        "SRA")
            echo "SRA input chosen"
            input='SRA'
            break
            ;;
        "FASTQ")
            echo "FASTQ input chosen"
            input='FASTQ'
            break
            ;;
        "BAM")
            echo "BAM input chosen"
            input='BAM'
            break
            ;;
        "Exit Setup")
            quit_setup
            ;;
        *) echo "invalid option... choose again (1-3 or 4 to quit)."
	    continue
	    ;;
    esac
done

if [[ $input == 'FASTQ' ]] || [[ $input == 'BAM' ]]; then
	printf  "\nPlease specify the directory that the ${input} file is located in?.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[INPUT_DIRECTORY]$COL_RESET: "
	read input_mnt
	while [[ -z $input_mnt ]]; do
	    printf  "\nThe ${input} file directory path is required.  Please enter one.\n$COL_GREEN[INPUT_DIRECTORY]$COL_RESET: "
	    read input_mnt
	done
	if [[ $input_mnt == 'q' ]] || [[ $input_mnt == 'quit' ]]; then
	    quit_setup
	fi
	if [[ $input_mnt == ..* ]]; then 
		input_mnt=../$input_mnt
	elif [[ $input_mnt == .* ]]; then
		input_mnt=.$input_mnt
	fi
	perl -i -pe "s|###INPUT_MNT###|$input_mnt|" $docker_compose
fi

# Append mongodb part of template to the main docker-compose file
cat $mongo_tmpl >> $docker_compose

if [[ $use_case == '2' ]] || [[ $use_case == '3' ]]; then
    # Copy template to production 
    blastn_plus_config=./docker_templates/blastn_plus.nt.config
    cp ${blastn_plus_config}.tmpl $blastn_plus_config
    # Next, figure out the BLAST db and if local/remote
    printf  "\nWhat reference database would you like to use for BLASTN querying?  Default is 'nt'\n"
    printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[BLAST_DATABASE]$COL_RESET: "
    read blast_db
    if [[ $blast_db == 'q' ]] || [[ $blast_db == 'quit' ]]; then
        quit_setup
    fi
    if [[ -z $blast_db ]]; then
        blast_db="nt"
    fi

    printf  "\nWould you like to query against a remote database from the NCBI servers?  Using a remote database saves you from having to have a pre-formatted database exist on your local machine, but is highly unrecommended due to the instability of the operation. Please enter 'Y' if you would like to use the remote NCBI database or 'N' (default) if you would prefer querying against a local database\n"
    printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[REMOTE_BLAST]$COL_RESET: "
    read y_n
    if [[ -z $y_n ]]; then
        remote=0
    fi

    while [[ ! $y_n =~ ^[YyNn]$ ]] && [[ ! $y_n =~ "^q*" ]]; do
        printf  "\nPlease enter 'yes' (Y) or 'no' (N).\n$COL_GREEN[REMOTE_BLAST]$COL_RESET: "
        read y_n
    done

    if [[ $y_n == 'q' ]] || [[ $y_n == 'quit' ]]; then
        quit_setup
    fi

    if [[ $y_n =~ ^[Yy]$ ]]; then
        remote=1
    else
        remote=0
    fi

    if [[ $remote == '1' ]]; then
        blast_dir=''
    else
        printf  "\nYou chose to use a local pre-formatted database.  Please provide the database path (leave out the database name).\n"
        printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[DB_DIRECTORY]$COL_RESET: "
        read blast_dir
        while [[ -z $blast_dir ]]; do
            printf  "\nThe directory path to the database is required.  Please enter one.\n$COL_GREEN[DB_DIRECTORY]$COL_RESET: "
            read blast_dir
        done
        if [[ $blast_dir == ..* ]]; then 
            blast_dir=../$blast_dir
        elif [[ $blast_dir == .* ]]; then
            blast_dir=.$blast_dir
        fi
    fi

    perl -i -pe "s|###REMOTE###|$remote|" $blastn_plus_config
    perl -i -pe "s|###BLAST_DB_DIR###|$blast_dir|" $docker_compose
    perl -i -pe "s|###BLAST_DB###|/mnt/blast/$blast_db|" $blastn_plus_config
fi

# Next, ask where the output data should be written to
printf  "\nNext, what directory should LGTSeek output be written to?  Note that if you close the Docker container, this output data may disappear, so it is recommended it be copied to a more permanent directory location.  If left blank, the output will be located at './output_data'\n"
printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[OUTPUT_DIRECTORY]$COL_RESET: "
read output_dir
if [[ $output_dir == 'q' ]] || [[ $output_dir == 'quit' ]]; then
    quit_setup
fi
if [[ -z $output_dir ]]; then
    output_dir='./output_data'
fi
if [[ $output_dir == ..* ]]; then 
    output_dir=../$output_dir
elif [[ $output_dir == .* ]]; then
    output_dir=.$output_dir
fi
perl -i -pe "s|###OUTPUT_DATA###|$output_dir|" $docker_compose

# Time to determine what Docker host will run the container
printf  "\nWhat IP is the docker host machine on?  Leave blank if you are using local resources for the host (localhost)\n"
printf  "Type 'quit' or 'q' to exit setup.\n$COL_GREEN[RUN_LOCALLY]$COL_RESET: "
read ip_address
if [[ $ip_address == 'q' ]] || [[ $ip_address == 'quit' ]]; then
    quit_setup
fi
if [[ -z $ip_address ]]; then
    ip_address='localhost'
fi
perl -i -pe "s|###IP_HOST###|$ip_address|" $docker_compose

# Remove leftover template ### lines from compose file
perl -i -ne 'print unless /###/;' $docker_compose

# Now, establish the following Docker containers:
# 1. ergatis_lgtseek_1
#  - Houses the Apache server and LGTview related code
# 2. ergatis_mongo_1
#  - Houses the MongoDB server
# 3. ergatis_mongodata_1
#  - A container to establish persistent MongoDB dataa

# Default docker_templates/docker-compose.yml was written to so no need to specify -f
printf  "\nGoing to build and run the Docker containers now.....\n"
docker-compose -f $docker_compose up -d

printf  "Docker container is done building!\n"
printf  "Next it's time to customize some things within the container\n\n";

# I don't like hard-coding this
docker cp $blastn_plus_config dockertemplates_ergatis_1:/opt/ergatis/pipeline_templates/LGT_Seek_Pipeline/

printf  "\nDocker container is ready for use!\n"
printf  "In order to build the LGTSeek pipeline please point your browser to $COL_BLUE http://${ip_address}:8080/pipeline_builder $COL_RESET\n"

exit 0
