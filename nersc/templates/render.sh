#!/usr/bin/env bash
set -eu


# An implementation of realpath for systems which don't have it, or a different
# implementation of it. This will attempt traverse the path and read any
# relative redirection using modern bash language only. This will not resolve
# symlinks as they could be relative or absolute symlinks. Usage:
#
#    $ __real_path /path/to/../folder/./with/relative/bits
#    $ /path/to/folder/with/relative/bits
#
__real_path () {
    # Redefined IFS to treat "/" as a separator.
    IFS="/" read -ra input_path <<< "$1";

    # Define 'real'
    local real=""
    # Iterate over path elements using "/" (set above) as a separator
    for elt in ${input_path[@]}
    do
        # Resolve relative path punctuation.
        if [[ "$elt" == "." || -z "$elt" ]]
        then
            # "." is a noop
            continue
        elif [[ "$elt" == ".." ]]
        then 
            # ".." => remove the last element
            real="${real%%/${real##*/}}"
            continue
        else
            # advance to the next directory
            real="${real}/${elt}"
        fi
    done

    echo "$real"
}


# Returns the parent directory path of the first argument. Usage:
#
#    $ __dir_name /path/to/script.sh
#    $ /path/to
#
__dir_name () {
    echo "${1%/*}"
}


# Holds the script prefix -- this is an array with the last element
# corresponding to the current script
if ! [[ -v __PREFIX ]]
then
    export __PREFIX=()
fi
# Add current script's directory to prefix
__PREFIX+=($(                                  \
    __dir_name $(                              \
        __real_path "${PWD}/${BASH_SOURCE[0]}" \
    )                                          \
))


pushd ${__PREFIX[-1]}
    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        aocc_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        aocc_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        cray_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        cray_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        gnu_settings.toml                                                      \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        gnu_settings.toml                                                      \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        intel_settings.toml                                                    \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        intel_settings.toml                                                    \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        nvidia_settings.toml                                                   \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        nvidia_settings.toml                                                   \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        llvm_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        llvm_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ../../opt/bin/simple-templates.ex                                          \
        environment/LocalPreferences.toml                                      \
        openmpi_settings.toml                                                  \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ../../opt/bin/simple-templates.ex                                          \
        environment/Project.toml                                               \
        openmpi_settings.toml                                                  \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"
popd

