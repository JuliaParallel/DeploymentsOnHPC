#!/usr/bin/env bash
set -eu

OPTIND=1 # Reset in case getopts has been used previously in the shell.
__MODE__="global"
unset -v __LOCAL_PATH__ # Ensure __LOCAL_PATH__ is only set by the -l optarg

while getopts "h?l:" opt; do
    case "$opt" in
    h|\\?)
        echo "Usage: $0 [-l local_path] <script> [args...]"
        echo "Sets the __PREFIX__ variable to the parent directory of $0 and __DIR__ to the directory of <script>"
        echo "If -l is provided, then __LOCAL_PATH__ is set to the value of <local_path>, and __MODE__ is set to 'local'"
        exit 0
        ;;
    l)  __LOCAL_PATH__=$OPTARG
        __MODE__="local"
        shift
        shift
        ;;
    *)  echo "Error parsing input argument: $opt"
        exit 1
        ;;
    esac
done

# Get the absolute path of this script
__get_script_dir() {
    local source="$1"
    echo "$(dirname "$(realpath "$source")")"
}

# Get the current directory => __PREFIX__
export __PREFIX__=$(__get_script_dir ${BASH_SOURCE[0]})
export __MODE__
export __LOCAL_PATH__

# Get the script to run
script="${__PREFIX__}/$1"
shift

# Get the directory of the called script => __DIR__
export __DIR__=$(__get_script_dir $script)

# Execute the script with remaining arguments
exec "$script" "$@"
