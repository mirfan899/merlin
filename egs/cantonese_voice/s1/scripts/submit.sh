#!/bin/bash -e

## Generic script for submitting any Theano job to GPU
# usage: submit.sh [scriptname.py script_arguments ... ]

src_dir=$(dirname $1)

# Source install-related environment variables
source ${src_dir}/setup_env.sh

use_gpu_lock=true

if [ "$use_gpu_lock" = true ]; then
    # Try to lock a GPU...
    gpu_id=$(python ${src_dir}/gpu_lock.py --id-to-hog)

    # Run the input command (run_merlin.py) with its arguments
    if [ $gpu_id -gt -1 ]; then
        echo "Running on GPU id=$gpu_id ..."
        THEANO_FLAGS="mode=FAST_RUN,device=gpu$gpu_id,"$MERLIN_THEANO_FLAGS
        export THEANO_FLAGS
    
    { # try  
            python $@
            python ${src_dir}/gpu_lock.py --free $gpu_id
    } || { # catch   
            python ${src_dir}/gpu_lock.py --free $gpu_id
    }
    else
        echo "No GPU is available! Running on CPU..."

        THEANO_FLAGS="floatX=float32,mode=FAST_RUN,device=cpu"
        export THEANO_FLAGS
    
        python $@
    fi
else
    # Assign GPU manually...
    gpu_id=0

    # Run the input command (run_merlin.py) with its arguments
    THEANO_FLAGS="mode=FAST_RUN,device=gpu$gpu_id,"$MERLIN_THEANO_FLAGS
    export THEANO_FLAGS
 
    python $@
    RETURNVAL=$?
    exit $RETURNVAL
fi

