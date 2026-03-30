#!/bin/bash
conda env create -f environment.yml
conda activate robot-dev

if [ "$1" == "--gpu" ]; then
    pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
else
    pip install torch torchvision
fi