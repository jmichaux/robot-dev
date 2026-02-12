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

### Creating Virtual Environments

Recall that you can create a Python3.10 environment by running:
```shell
python3.10 -m venv rd-venv
```

And then you can activate the virtual environment with

```shell
source rd-venv/bin/activate
```

## Run Tests

```bash
pytest tests/ -v
```