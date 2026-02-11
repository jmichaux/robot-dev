# robot-dev: Complete Setup Guide

From zero to a working dev environment — local and RunPod.

---

## Step 1: SSH Keys

You need two key pairs (or reuse one for both).

### 1.1: Generate Keys (if you don't already have them)

```bash
# Check if you already have keys
ls ~/.ssh/id_ed25519*

# If not, generate one
ssh-keygen -t ed25519 -C "your@email.com"
# Press Enter for default location (~/.ssh/id_ed25519)
# Set a passphrase (recommended) or leave empty
```

### 1.2: Add Key to GitHub

```bash
# Copy your public key
cat ~/.ssh/id_ed25519.pub | pbcopy   # macOS
# or: cat ~/.ssh/id_ed25519.pub      # then copy manually
```

1. Go to https://github.com/settings/keys
2. Click **New SSH key**
3. Paste the public key, give it a name like "MacBook"
4. Click **Add SSH key**

Verify it works:
```bash
ssh -T git@github.com
# Should say: "Hi <username>! You've successfully authenticated..."
```

### 1.3: Add Key to RunPod

```bash
# Same public key
cat ~/.ssh/id_ed25519.pub
```

1. Go to https://www.runpod.io/console/user/settings
2. Find **SSH Public Keys**
3. Paste the key, save

### 1.4: Configure SSH Agent (for forwarding to RunPod)

Add to `~/.ssh/config`:
```
# GitHub
Host github.com
    IdentityFile ~/.ssh/id_ed25519

# RunPod pods (wildcard — adjust as needed)
Host runpod
    HostName <you'll fill this in per pod>
    Port <you'll fill this in per pod>
    User root
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent yes
```

Start the SSH agent and add your key:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

> **Why ForwardAgent?** When you SSH into a RunPod pod with `-A`, your local
> SSH key is forwarded. This lets you `git push` from the pod without storing
> any keys on the pod itself.

---

## Step 2: Create the Repo

### 2.1: Create on GitHub

1. Go to https://github.com/new
2. Name: `robot-dev`
3. Private (for now — you can make it public later)
4. Initialize with README: **No** (we'll push our own)
5. Click **Create repository**

### 2.2: Set Up Local Repo

```bash
mkdir robot-dev && cd robot-dev
git init
```

### 2.3: Create the Project Structure

```bash
# Core package
mkdir -p robot_dev/policies
mkdir -p robot_dev/envs
mkdir -p robot_dev/data
mkdir -p robot_dev/training

# Supporting dirs
mkdir -p scripts
mkdir -p tests
mkdir -p configs
mkdir -p docs/notes
mkdir -p docker
mkdir -p .github/workflows

# __init__.py files
touch robot_dev/__init__.py
touch robot_dev/policies/__init__.py
touch robot_dev/envs/__init__.py
touch robot_dev/data/__init__.py
touch robot_dev/training/__init__.py
```

### 2.4: Create `pyproject.toml`

This is the single source of truth for dependencies. Everyone uses this.

```toml
[project]
name = "robot-dev"
version = "0.1.0"
description = "Minimal robotics policy learning: ACT → smolVLA"
requires-python = ">=3.10"
dependencies = [
    "torch>=2.1",
    "torchvision>=0.16",
    "gymnasium>=0.29",
    "mujoco>=3.0",
    "dm_control>=1.0",
    "h5py>=3.10",
    "numpy>=1.24",
    "wandb>=0.16",
    "huggingface_hub>=0.20",
    "transformers>=4.36",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "ruff>=0.1",
    "ipython",
    "jupyter",
    "matplotlib",
]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.backends._legacy:_Backend"

[tool.ruff]
line-length = 100
target-version = "py310"

[tool.ruff.lint]
select = ["E", "F", "I", "W"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### 2.5: Create `robot_dev/policies/base.py`

```python
from abc import ABC, abstractmethod

import numpy as np
import torch


class BasePolicy(ABC):
    """Base class for all policies. Implement this to add a new policy."""

    @abstractmethod
    def predict_action(self, obs: dict[str, torch.Tensor]) -> np.ndarray:
        """Given observation dict, return action array."""
        ...

    @abstractmethod
    def compute_loss(self, batch: dict[str, torch.Tensor]) -> dict[str, torch.Tensor]:
        """Given training batch, return dict with 'loss' key and optional diagnostics."""
        ...

    @abstractmethod
    def save(self, path: str) -> None:
        ...

    @abstractmethod
    def load(self, path: str) -> None:
        ...
```

### 2.6: Create a Minimal Test

```python
# tests/test_smoke.py
def test_project_imports():
    import robot_dev
    from robot_dev.policies.base import BasePolicy


def test_base_policy_is_abstract():
    from robot_dev.policies.base import BasePolicy
    import pytest

    with pytest.raises(TypeError):
        BasePolicy()
```

### 2.7: Create `.gitignore`

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.eggs/

# Environments
.venv/
venv/
env/

# IDE
.vscode/
.idea/
*.swp

# Data & outputs (keep these on persistent storage, not in git)
data/
outputs/
checkpoints/
wandb/

# OS
.DS_Store
Thumbs.db

# Jupyter
.ipynb_checkpoints/
```

### 2.8: Create `README.md`

```markdown
# robot-dev

Minimal implementations of robotics policy learning methods: ACT → smolVLA.

## Status

🚧 Phase 0: Project setup

## Installation

```bash
# Create a Python 3.10 environment using whatever tool you prefer
# (conda, venv, uv — doesn't matter), then:
pip install -e ".[dev]"
```

## Run Tests

```bash
pytest tests/ -v
```
```

### 2.9: Create CI

```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request]
jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.10"
      - run: pip install -e ".[dev]"
      - run: ruff check .
      - run: pytest tests/ -v
```

### 2.10: First Commit and Push

```bash
git add -A
git commit -m "feat: initial project structure with BasePolicy and CI"
git branch -M main
git remote add origin git@github.com:<your-username>/robot-dev.git
git push -u origin main
```

### 2.11: Verify Locally

```bash
# Create your env (conda example — friends can use venv, uv, whatever)
conda create -n robotdev python=3.10 -y
conda activate robotdev
pip install -e ".[dev]"
pytest tests/ -v
# Should see 2 tests pass
```

---

## Step 3: Create the Docker Image

### 3.1: Install Docker (if you don't have it)

- **macOS:** Download Docker Desktop from https://docker.com/products/docker-desktop
- **Linux:** `sudo apt install docker.io` (or follow Docker's official docs)

Verify:
```bash
docker --version
```

### 3.2: Create a Docker Hub Account

1. Go to https://hub.docker.com and sign up
2. Remember your username — you'll need it as `<dockerhub-username>`

### 3.3: Write the Dockerfile

Create `docker/Dockerfile` in your repo:

```dockerfile
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

# ============================================================
# System setup
# ============================================================
ENV DEBIAN_FRONTEND=noninteractive
ENV MUJOCO_GL=egl
ENV PATH="/opt/conda/bin:$PATH"

# System dependencies for MuJoCo headless rendering + SSH
RUN apt-get update && apt-get install -y \
    git curl wget openssh-server \
    libegl1-mesa-dev libgl1-mesa-dev libgles2-mesa-dev \
    libglfw3 libglfw3-dev libosmesa6-dev \
    build-essential cmake \
    && rm -rf /var/lib/apt/lists/*

# SSH setup (RunPod injects your public key at launch)
RUN mkdir -p /var/run/sshd

# ============================================================
# Conda + Python
# ============================================================
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh \
    && conda clean -afy

# Create conda environment
RUN conda create -n ml python=3.10 -y
# All subsequent RUN commands use this env
SHELL ["conda", "run", "-n", "ml", "/bin/bash", "-c"]

# ============================================================
# Python dependencies (heavy stuff that rarely changes)
# ============================================================
# PyTorch with CUDA 12.1
RUN pip install --no-cache-dir \
    torch torchvision \
    --index-url https://download.pytorch.org/whl/cu121

# MuJoCo + Gymnasium
RUN pip install --no-cache-dir \
    gymnasium>=0.29 \
    mujoco>=3.0 \
    dm_control>=1.0

# ML tooling
RUN pip install --no-cache-dir \
    h5py numpy wandb \
    huggingface_hub transformers \
    matplotlib ipython jupyter

# Dev tools
RUN pip install --no-cache-dir \
    pytest ruff

# ============================================================
# Environment config
# ============================================================
WORKDIR /workspace

# Activate conda env on any login shell
RUN echo "conda activate ml" >> /root/.bashrc

# Keep the container running (RunPod expects this)
CMD ["sleep", "infinity"]
```

### 3.4: Build the Image

```bash
cd robot-dev

# Build (this takes 10-20 minutes the first time)
docker build -f docker/Dockerfile -t <dockerhub-username>/robot-dev:latest .

# Verify it built
docker images | grep robot-dev
```

> **Note for Apple Silicon (M1/M2/M3):** The image targets x86_64/CUDA.
> You can still build it for linux/amd64:
> ```bash
> docker build --platform linux/amd64 -f docker/Dockerfile -t <dockerhub-username>/robot-dev:latest .
> ```
> You won't be able to *run* it locally (no NVIDIA GPU), but you can push it and it'll work on RunPod.

### 3.5: (Optional) Test Locally

If you're on Linux with an NVIDIA GPU:
```bash
docker run --gpus all -it <dockerhub-username>/robot-dev:latest bash
# Inside the container:
python -c "import torch; print(torch.cuda.is_available())"
# Should print True
```

### 3.6: Push to Docker Hub

```bash
# Log in (once)
docker login
# Enter your Docker Hub username and password/token

# Push
docker push <dockerhub-username>/robot-dev:latest
```

This uploads the image. Takes a while the first time (image is several GB).

### 3.7: Automate Builds with GitHub Actions (Optional but Recommended)

Add this to your repo so the Docker image rebuilds automatically when you change the Dockerfile:

```yaml
# .github/workflows/docker.yml
name: Build Docker Image
on:
  push:
    branches: [main]
    paths: ["docker/**"]
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          file: docker/Dockerfile
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/robot-dev:latest
```

Add your Docker Hub credentials as GitHub repo secrets:
1. Go to your repo → Settings → Secrets and variables → Actions
2. Add `DOCKERHUB_USERNAME` (your Docker Hub username)
3. Add `DOCKERHUB_TOKEN` (create at https://hub.docker.com/settings/security → New Access Token)

---

## Step 4: RunPod Setup

### 4.1: Create a Network Volume (Do This First)

1. Go to https://www.runpod.io/console/user/storage
2. Click **New Network Volume**
3. Settings:
   - **Name:** `robot-dev-workspace`
   - **Region:** Pick one with good GPU availability (e.g., US-East, EU-RO)
   - **Size:** 50 GB (increase later if needed — can't decrease)
4. Click **Create**

> **Important:** Remember which region you chose. Your pods must be in the
> same region as the network volume.

### 4.2: Create Your Custom Template

1. Go to https://www.runpod.io/console/user/templates
2. Click **New Template**
3. Fill in:

| Field                   | Value                                        |
|-------------------------|----------------------------------------------|
| **Template Name**       | `robot-dev`                                  |
| **Container Image**     | `<dockerhub-username>/robot-dev:latest`      |
| **Container Disk**      | 20 GB                                        |
| **Volume Mount Path**   | `/workspace`                                 |
| **Expose HTTP Ports**   | `8888`                                       |
| **Expose TCP Ports**    | `22`                                         |
| **Environment Variables** | `MUJOCO_GL` = `egl`                       |

4. Click **Save Template**

> **Sharing with friends:** Your template will appear under "My Templates."
> If your Docker Hub image is public, your friends can create the same template
> on their own RunPod accounts by just entering the same container image path.
> Alternatively, you can make the template public in RunPod settings.

### 4.3: Launch a Pod

1. Go to https://www.runpod.io/console/pods
2. Click **+ Deploy**
3. Select your `robot-dev` template
4. Select a GPU (RTX 4090 or A100 are good choices)
5. **Attach Network Volume:** Select `robot-dev-workspace`
6. Make sure the region matches your network volume
7. Click **Deploy**

Wait ~1-2 minutes for the pod to start.

### 4.4: Connect to the Pod

Once the pod is running, click **Connect** to find the SSH details.

RunPod gives you something like:
```
ssh root@38.29.145.XX -p 43210 -i ~/.ssh/id_ed25519
```

Add the `-A` flag for agent forwarding:
```bash
ssh -A root@38.29.145.XX -p 43210 -i ~/.ssh/id_ed25519
```

Or update your `~/.ssh/config` for convenience:
```
Host runpod-robot
    HostName 38.29.145.XX
    Port 43210
    User root
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent yes
```

Then just:
```bash
ssh runpod-robot
```

### 4.5: First-Time Setup on the Pod (Once Per Network Volume)

```bash
# You're now on the pod, in /workspace
# Verify GPU
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, GPU: {torch.cuda.get_device_name(0)}')"

# Verify MuJoCo headless rendering
python -c "import mujoco; print(f'MuJoCo {mujoco.__version__}')"

# Verify SSH forwarding works (your GitHub key)
ssh -T git@github.com
# "Hi <username>! You've successfully authenticated..."

# Clone your repo onto the persistent network volume
cd /workspace
git clone git@github.com:<your-username>/robot-dev.git
cd robot-dev

# Install your package in editable mode
pip install -e ".[dev]"

# Run tests
pytest tests/ -v
```

Everything under `/workspace` persists. Next time you start a pod, it's all still there.

### 4.6: Daily Workflow on RunPod

```bash
# SSH in
ssh -A runpod-robot

# Your code is already there
cd /workspace/robot-dev
git pull                    # get latest from your team
pip install -e ".[dev]"     # only if pyproject.toml changed

# Work
python scripts/train.py --config configs/act.yaml

# Push your changes (uses forwarded SSH key)
git add -A
git commit -m "feat: implement CVAE encoder"
git push

# When done — stop the pod from RunPod console to stop billing
# (your /workspace data persists on the network volume)
```

### 4.7: VS Code / Cursor Remote Development

1. Install the **Remote - SSH** extension
2. Open Command Palette → **Remote-SSH: Connect to Host**
3. Select `runpod-robot` (from your SSH config)
4. VS Code opens a window connected to the pod
5. Open folder → `/workspace/robot-dev`
6. Terminal, debugger, extensions — everything works remotely

---

## Summary: What Lives Where

```
┌──────────────────────────────────────────────────────┐
│  Your Laptop                                         │
│  ├── ~/.ssh/id_ed25519        ← SSH key (never moves)│
│  ├── robot-dev/               ← local clone          │
│  └── Docker Desktop           ← builds images        │
├──────────────────────────────────────────────────────┤
│  GitHub                                              │
│  ├── robot-dev repo           ← source of truth      │
│  ├── CI (tests + lint)        ← runs on every PR     │
│  └── Docker CI (optional)     ← rebuilds image       │
├──────────────────────────────────────────────────────┤
│  Docker Hub                                          │
│  └── <you>/robot-dev:latest   ← the runtime image    │
├──────────────────────────────────────────────────────┤
│  RunPod                                              │
│  ├── Template: robot-dev      ← points to Docker Hub │
│  ├── Network Volume           ← persistent /workspace│
│  │   ├── robot-dev/           ← git repo clone       │
│  │   ├── data/                ← datasets             │
│  │   └── checkpoints/         ← training outputs     │
│  └── Pod (disposable)         ← GPU compute          │
└──────────────────────────────────────────────────────┘
```

---

## Quick Reference: What Your Friends Need To Do

### To develop locally (no RunPod needed):
```bash
git clone git@github.com:<your-username>/robot-dev.git
cd robot-dev
python3.10 -m venv .venv && source .venv/bin/activate  # or conda, or uv
pip install -e ".[dev]"
pytest tests/ -v
```

### To use RunPod with your template:
1. Create a RunPod account, add their SSH key
2. Create a network volume (same region as you, or their own)
3. Create a template with image `<dockerhub-username>/robot-dev:latest` (same settings as §4.2)
4. Deploy a pod, attach network volume
5. SSH in, clone repo, `pip install -e ".[dev]"`, work
