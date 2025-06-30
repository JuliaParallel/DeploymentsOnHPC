#!/bin/bash

set -eu

cat $CUDA_HOME/version.json | jq -r .cuda.version | cut -d '.' -f 1-2
