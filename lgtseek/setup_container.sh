#!/bin/bash

function quit_setup {
    printf "\nExiting setup.  Bye."
    exit 0
}

#########################
# MAIN
#########################

# Copy the template over to a production version of the docker-compose file
cp docker-compose.tmpl.yml docker-compose.prod.yml

printf "\nWelcome to the LGTSeek Docker installer. Please follow the prompts below that will help the Docker container access your usable data.\n"

# Get Use-Case information to pare down setup options
printf "\nFirst, let's figure out which LGTSeek Use Case you wish to employ\n"

PS3="Select a Use Case # (1-3) or 4 to Quit): "
options=("Use Case 1 - Good donor reference and good LGT-free host reference" "Use Case 2 - Good donor reference but unknown host reference" "Use Case 3 - Good host reference but unknown donor reference" "Quit setup")
use_case=''
select opt in "${options[@]}"
do
   case $opt in
        "1")
            echo "Use case 1 chosen"
             use_case=1
            ;;
        "2")
            echo "Use case 2 chosen"
            use_case=2
            ;;
        "3")
            echo "Use case 3 chosen"
            use_case=3
            ;;
        "4")
            quit_setup
            ;;
        *) echo "invalid option... choose again (1-3 or 'q' to quit)."
	    continue
	    ;;
    esac
done

printf "\nNext it's time to specify where the reference and input files are located\n"

# First ask for location of donor reference directory
if [[ $use_case == '1' ]] || [[ $use_case == '2' ]]; then
	printf  "\nPlease specify the directory that the donor reference genome(s) is located.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n[DONOR_DIRECTORY]: "
	read donor_mnt
	while [[ -z $donor_mnt ]]; do
	    printf  "\nThe donor reference genome directory path is required.  Please enter one.\n[DONOR_DIRECTORY]: "
	    read donor_mnt
	done
	if [[ $donor_mnt == 'q' ]] || [[ $donor_mnt == 'quit' ]]; then
	    quit_setup
	fi
	sed -i.bak "s|###DONOR_MNT###|$donor_mnt|" docker-compose.prod.yml
fi

# Second ask for location of host reference directory
if [[ $use_case == '1' ]] || [[ $use_case == '3' ]]; then
	printf  "\nPlease specify the directory that the host reference genome(s) is located.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n[HOST_DIRECTORY]: "
	read host_mnt
	while [[ -z $host_mnt ]]; do
	    printf  "\nThe host reference genome directory path is required.  Please enter one.\n[HOST_DIRECTORY]: "
	    read host_mnt
	done
	if [[ $host_mnt == 'q' ]] || [[ $host_mnt == 'quit' ]]; then
	    quit_setup
	fi
	sed -i.bak "s|###HOST_MNT###|$host_mnt|" docker-compose.prod.yml
fi

# Third ask for location of Refseq reference directory
if [[ $use_case == '3' ]]; then
	printf  "\nPlease specify the directory that the RefSeq reference genomes are located.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n[REFSEQ_DIRECTORY]: "
	read refseq_mnt
	while [[ -z $refseq_mnt ]]; do
	    printf  "\nThe RefSeq reference genome directory path is required.  Please enter one.\n[REFSEQ_DIRECTORY]: "
	    read refseq_mnt
	done
	if [[ $refseq_mnt == 'q' ]] || [[ $refseq_mnt == 'quit' ]]; then
	    quit_setup
	fi
	sed -i.bak "s|###REFSEQ_MNT###|$refseq_mnt|" docker-compose.prod.yml
fi

# Next, need to determine input format
printf "\nNext, which type of input do you plan to use?\n"
PS3="Select an input type(1-3 or 'q' to quit): "
options=("SRA" "FASTQ" "BAM" "Quit setup")
input=''
select opt in "${options[@]}"
do
   case $opt in
        "1")
            echo "SRA input chosen"
            input='SRA'
            ;;
        "2")
            echo "FASTQ input chosen"
            input='FASTQ'
            ;;
        "3")
            echo "BAM input chosen"
            input='BAM'
            ;;
        "4")
            quit_setup
            ;;
        *) echo "invalid option... choose again (1-3 or 'q' to quit)."
	    continue
	    ;;
    esac
done

if [[ $input == 'FASTQ' ]] || [[ $input == 'BAM' ]]; then
	printf  "\nPlease specify the directory that the ${input} file is located in?.\n"
	printf  "Type 'quit' or 'q' to exit setup.\n[INPUT_DIRECTORY]: "
	read input_mnt
	while [[ -z $input_mnt ]]; do
	    printf  "\nThe ${input} file directory path is required.  Please enter one.\n[INPUT_DIRECTORY]: "
	    read input_mnt
	done
	if [[ $input_mnt == 'q' ]] || [[ $input_mnt == 'quit' ]]; then
	    quit_setup
	fi
	sed -i.bak "s|###INPUT_MNT###|$input_mnt|" docker-compose.prod.yml
fi

# Next, ask where the output data should be written to
printf  "\nNext, what directory should LGTView output be written to?  Note that if you close the Docker container, this output data may disappear, so it is recommended it be copied to a more permanent directory location.  If left blank, the output will be located at './output_data'\n"
printf  "Type 'quit' or 'q' to exit setup.\n[OUTPUT_DIRECTORY]: "
read output_dir
if [[ $output_dir == 'q' ]] || [[ $output_dir == 'quit' ]]; then
    quit_setup
fi
if [[ -z $output_dir ]]; then
    output_dir='./output_data'
fi
sed -i.bak "s|###OUTPUT_DATA###|$output_dir|" docker-compose.prod.yml

# Time to determine what Docker host will run the container
#printf  "\nWhat IP is the docker host machine on?  Leave blank if you are using local resources for the host (localhost)\n"
#printf  "Type 'quit' or 'q' to exit setup.\n[RUN_LOCALLY]: "
#read ip_address
#if [[ $ip_address == 'q' ]] || [[ $ip_address == 'quit' ]]; then
#    quit_setup
#fi
#if [[ -z $ip_address ]]; then
    ip_address='localhost'
#fi
sed -i.bak "s|###IP_HOST###|$ip_address|" docker-compose.prod.yml


# Next, figure out the BLAST db and if local/remote
printf  "\nWhat reference database would you like to use for BLASTN querying?  Default is 'nt'\n"
printf  "Type 'quit' or 'q' to exit setup.\n[BLAST_DATABASE]: "
read blast_db
if [[ $blast_db == 'q' ]] || [[ $blast_db == 'quit' ]]; then
    quit_setup
fi
if [[ -z $blast_db ]]; then
    blast_db="nt"
fi

printf  "\nWould you like to query against a remote database from the NCBI servers?  Using a remote database saves you from having to have a pre-formatted database exist on your local machine, but is not recommended if you anticipate a lot of queries or have sensitive data. Please enter 'Y' (default) if you would like to use the remote NCBI database or 'N' if you would prefer querying against a local database\n"
printf  "Type 'quit' or 'q' to exit setup.\n[REMOTE_BLAST]: "
read y_n
if [[ -z $y_n ]]; then
    remote=1
fi

while [[ ! $y_n =~ ^[YyNn]$ ]] && [[ ! $y_n =~ "^q*" ]]; do
    printf  "\nPlease enter 'yes' (Y) or 'no' (N).\n[REMOTE_BLAST]: "
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

if [[ $remote ]]; then
    blast_path=''
fi
if [[ ! $remote ]]; then
    printf  "\nYou chose to use a local pre-formatted database.  Please provide the database path (leave out the database name).\n"
    printf  "Type 'quit' or 'q' to exit setup.\n[DB_DIRECTORY]: "
    read blast_path
    while [[ -z $blast_path ]]; do
        printf  "\nThe directory path to the database is required.  Please enter one.\n[DB_DIRECTORY]: "
        read blast_path
    done
fi

sed -i.bak "s|###BLAST_PATH###|$blast_path|" docker-compose.prod.yml
sed -i.bak "s|###BLAST_DB###|$blast_db|" docker-compose.prod.yml

sed -i.bak "s|###REMOTE###|$remote|" docker-compose.prod.yml

printf  "\nGoing to build and run the Docker containers now....."

# Now, establish the following Docker containers:
# 1. ergatis_lgtseek_1
#  - Houses the Apache server and LGTview related code
# 2. ergatis_mongo_1
#  - Houses the MongoDB server
# 3. ergatis_mongodata_1
#  - A container to establish persistent MongoDB data

docker-compose -f docker-compose.prod.yml up -d

printf  "Docker container is done building!\n"
printf  "Next it's time to customize some things within the container\n\n";

### TODO:
# 1) Use Blast DB information to fix blast-plus template configs
# 2) Use docker host IP in the blast_lgt_finder, blast2lca, and sam2lca template configs

printf  "\nDocker container is ready for use!\n"
printf  "In order to build the LGTSeek pipeline please point your browser to http://${ip_address}:8080/pipeline_builder\n"

rm docker-compose.prod.yml.bak

exit 0
