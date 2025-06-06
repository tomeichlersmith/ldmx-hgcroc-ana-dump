_default:
    @just --list --justfile {{ justfile() }}

# initialize analysis venv
init-ana:
    #!/bin/bash
    set -euo pipefail
    python3 -m venv venv --prompt hgcroc-ana
    . venv/bin/activate
    pip install -r requirements.txt

# run a command in the python venv
python *command:
    #!/bin/bash
    set -euo pipefail
    . venv/bin/activate
    {{ command }}

# open jupyter lab
jupyter-lab *args: (python "jupyter" "lab" args)

# mount the data directory on the ZCU here
mount zcu="zcu":
    sshfs \
      --debug \
      -o reconnect \
      -o ServerAliveInterval=15 \
      -o compression=yes \
      {{ zcu }}:pflib/data pflib/data

# unmount the data directory on the ZCU
unmount:
    fusermount -u pflib/data

