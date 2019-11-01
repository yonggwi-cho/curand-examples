#!/bin/bash

export CUDA=/usr/local/cuda-8.0

INCLUDE="-I${CUDA}/include"
LIB="-L${CUDA}/lib64 -lcurand"

nvcc $INCLUDE $LIB example.cu -o test
