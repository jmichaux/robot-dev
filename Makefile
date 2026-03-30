env-cpu:
    conda env create -f environment.yml

env-gpu:
    conda env create -f environment.yml
    conda run -n robot-dev pip install torch torchvision \
        --index-url https://download.pytorch.org/whl/cu121