#!/usr/bin/env bash
set -eu


pushd ${__DIR__}
    #---------------------------------------------------------------------------
    # Julia Environments
    #---------------------------------------------------------------------------
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        aocc_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        aocc_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        cray_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        cray_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        gnu_settings.toml                                                      \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        gnu_settings.toml                                                      \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        intel_settings.toml                                                    \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        intel_settings.toml                                                    \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        nvidia_settings.toml                                                   \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        nvidia_settings.toml                                                   \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        llvm_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        llvm_settings.toml                                                     \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/LocalPreferences.toml                                      \
        openmpi_settings.toml                                                  \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/LocalPreferences.toml"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        environment/Project.toml                                               \
        openmpi_settings.toml                                                  \
        "../rendered/{{prg_env}}.{{mpi_mod}}.cuda{{cuda_version}}/Project.toml"

    #---------------------------------------------------------------------------
    # Jupyter NERSC-JULIA Kernels
    #---------------------------------------------------------------------------

    # WARNING: this requires the jupyter_settings.toml/nersc_resource_dir to be
    # set correctly. TODO: automate in the future.
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        jupyter/kernel.json                                                    \
        jupyter_settings.toml                                                  \
        "../kernels/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_cudnn}}-cudnn{{/use_cudnn}}{{#use_latest}}-beta{{/use_latest}}/kernel.json"
    ${__PREFIX__}/opt/bin/simple-templates.ex                                  \
        jupyter/kernel-helper.sh                                               \
        jupyter_settings.toml                                                  \
        "../kernels/rendered/nersc-julia-{{julia_thread_ct}}-{{julia_version}}{{#use_cudnn}}-cudnn{{/use_cudnn}}{{#use_latest}}-beta{{/use_latest}}/kernel-helper.sh"
    for target in $(/bin/ls ../kernels/rendered/)
    do 
        chmod u+x ../kernels/rendered/$target/kernel-helper.sh
        cp jupyter/logo-32x32.png ../kernels/rendered/$target/
        cp jupyter/logo-64x64.png ../kernels/rendered/$target/
    done
popd
