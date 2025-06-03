_default:
    @just --list --justfile {{ justfile() }}

# initialize analysis venv
init-ana:
    #!/bin/bash
    set -euo pipefail
    python3 -m venv venv --prompt hgcroc-ana
    . venv/bin/activate
    pip install -r requirements.txt

# open jupyter lab
jupyter-lab *args:
    #!/bin/bash
    set -euo pipefail
    . venv/bin/activate
    jupyter lab {{ args }}

# mount the data directory on the ZCU here
mount zcu="zcu":
    sshfs {{ zcu }}:pflib/data pflib/data
