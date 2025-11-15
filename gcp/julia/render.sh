#!/usr/bin/env bash
set -eu

pushd ${__DIR__}
case ${__MODE__} in
global)
    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config/
    ;;

local)
    DESTINATION=${__LOCAL_PATH__}
    LOC_MODULE_DIR=${DESTINATION}/modules

    mkdir -p ${DESTINATION}

    ${__PREFIX__}/opt/bin/simple-modules.ex sm-config/    \
        --destination=${DESTINATION}                      \
        --modules=${LOC_MODULE_DIR}
    ;;

*)
    echo "__MODE__=${__MODE__} is not a valid setting"
    popd
    exit 1
    ;;
esac
popd
