#!/bin/bash -x
PROGRAM_NAME="Handbreak CLI Converter"
PROGRAM_VERSION='$Id: converter_mp4.sh,v 0.9 2011/01/04 bslima Exp $'
AUTHORS='Bruno Lima'
BUGS_TO='bslima19@gmail.com'

# Version string (printed when --version is given).
version_string="\
$PROGRAM_VERSION
Written by $AUTHORS."

# Current working directory.
cwd=$(pwd)

# Log file name.
log_file="$cwd/converter.log"

# Argv[0] -- initialized at main().
program_name=""
source=""
dest="${cwd}/target.mp4"
target=$dest
removeFile="false"
verbose="-v 1"
dir_batch=""
#debug= "--stop-at duration:30"
debug=""
#Halt on any error
set -e

# func_info() MESSAGE
# Print a message to stdout and sends a copy to log_file.
func_info()
{
    local message="$1"
    echo "$message" | tee -a "$log_file"
}

# func_error STATUS MESSAGE
# Print a message to stderr.
# If STATUS is nonzero, terminate the program with `exit STATUS'.
func_error()
{
    local status=$1
    local message=$2

    echo "$PROGRAM_NAME: $message" 1>&2
    if test $status -ne 0; then
        exit $status
    fi
}

func_usage() 
{
     local status=$1
     echo "\
		Usage: $program_name SOURCE_FILE [DEST_FILE] [OPTIONS]
		Convert a SOURCE_FILE into a DEST_FILE using x264

		
		Options:
		  --help               print this help and exit
		  --version            print version information and exit
		
		  -r, --remove         remove the SOURCE_FILE after converted
		  -d, --dir=DIR        batch conversion on DIR
		  -l, --log-file=FILE  log FILE name (defaults to \`build.log')
		  -v, --verbose        show debug output"
		
	 exit $status
}

func_converter()
{

	HandBrakeCLI -i $source -o $target $verbose $debug -e x264 -2 -T -b 386 -B 96 -R Auto -X 624 --keep-display-aspect -s 1 --subtitle-burn 1 -x ref=2:bframes=2:subq=6:mixed-refs=0:trellis=0:b-pyramid=strict
	
	if [ $? != 0 ]
    then
        func_info "$source had problems" 
    fi

	if test $removeFile == 'true'; then
		func_info "Removing $source as requested"
		rm -rf $source
	fi
	
}

func_converter_batch() 
{
	
	func_info "Discovering files (*.avi) in $dir_batch …"

	find ${dir_batch} -type f -name "*.avi" | while read objs; 
		do
		 echo "Calling converter to => "$objs
		 source=$objs
		 target="${source%.*}.mp4"
		 
		 echo "" | func_converter
	
		done
}



func_parse_args() 
{
	if test "${1}set"  == "set" ; then
	  func_usage 1
	elif test -f $1 ; then
	  source="$1"	
	  shift
	  func_info "Source file set to $source "
	  target="${source%.*}.mp4"
	  func_info "Target File set to $target "
	elif test ! "${1:0:1}" = '-'; then
	  func_error 1 "File $1 does not exit. Exiting ..."
	fi
	
	# Parse options.
    while test $# -gt 0; do
        case "$1" in
            --help)
                func_usage 0
                ;;

            --version)
                echo "$version_string"
                exit 0
                ;;
            
            -r | --remove)
            	removeFile='true'            	
            	shift
            	;;    

            -v | --verbose)
                verbose='-v 2'
                shift
                ;;
                
            -l | --log-file)
                shift
                log_file="$1"
                if test -z "$log_file" -o "${log_file:0:1}" = '-'; then
                    func_error 0 "option requires an argument -- '-l'"
                    func_usage 1
                fi
                # Path is relative, prefix cwd.
                if test ! "${log_file:0:1}" = '/'; then
                    log_file="$cwd/$log_file"
                fi
                shift
                ;; 
            
            -d | --dir)
                shift
                dir_batch="$1"
                if test -z "$dir_batch" -o "${dir_batch:0:1}" = '-'; then
                    func_error 0 "option requires an argument -- '-d'"
                    func_usage 1
                fi
				if ! test -d $dir_batch; then
					func_error 1 "This is not a valid directory"
				fi
				func_info "Batching DIR => $dir_batch"
                shift
                ;;        

            --) # Stop option processing.
                shift; break
                ;;

            -*)
                func_error 0 "unknown option \`$1'"
                func_usage 1
                ;;

            *)
                #Must be a DEST_FILE
				param=$1
				# IF Path is relative, prefix cwd.
                if test ! "${param:0:1}" = '/'; then
                    param="$cwd/$param"
                fi
				top_dir=${param%/*}
				if test -d $top_dir; then
					#if test -f $1; then
					#	func_error 1 "File $1 already exists"
					#fi	
					target=$param
					func_info "Target file set to: $target"
				else
					func_error 1 "The directory $top_dir doesn't exists"	
				fi
                shift
                ;;
        esac
    done
}

func_main() 
{
	program_name="$0"
	func_parse_args "$@"
	
	if test -z $dir_batch; then
		func_converter
	else
		func_converter_batch
	fi
	
	echo "Done ? ..."
}	

# Run main. with all arguments
func_main "$@"

