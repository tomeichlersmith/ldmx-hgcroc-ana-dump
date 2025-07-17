_default:
    @just --list --justfile {{ justfile() }}

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

