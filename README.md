# 🚢 cod2-docker

Docker image for your Call of Duty 2 server. Libcod included! 

All the tags can be found here: [docker hub](https://hub.docker.com/repository/docker/rutkowski/cod2/general).

# 🪧 Tagging convention

`rutkowski:cod2/<version>-server<cod2-version>[-mysql-variant][-speex-enabled][-unsafe-enabled]`

For example image tagged `rutkowski/cod2:2.5-server1.3-mysqlvoron-speex-unsafe`:
- is representation of 2.5 version of this repo
- each image has libcod suppor
  - versions 1.x are integrated with [voron's libcod](https://github.com/voron00/libcod)
  - versions 2.x are integrated with [iBuddie's zk_libcod](https://github.com/ibuddieat/zk_libcod)
- `server1.3` - is built for CoD2 version 1.3
- `mysqlvoron` - has mysql support added, voron version
- `speex` - has speex support added, required for dynamic loading and playing sounds
- `unsafe` unsafe flag was enabled during libcod build (adding commands for system manipulation)

For libcod docs check [here](https://github.com/ibuddieat/zk_libcod)

# 🚀 Features

This repo was created beacuse it seems that [cod2docker](https://github.com/Lonsofore/cod2docker) is not longer maintained. Also it includes following advancements:

- integrating with latest [zk_libcod](https://github.com/ibuddieat/zk_libcod)
- speex integration for dynamic sound loading
- `unsafe` parametrized build for enabling functions like: `system`, `file_unlink`, `scandir` etc.
- github workflow martix build
- running container as non-root user
- making mounted main and library folders read-only
- update to latest ubuntu version
- update to latest packages versions
- other minor optimizations: removing not used packages

# 🤷🏻‍♂️ How to use?

Upload your main folder and fs_game of server to the machine running docker. Create `docker-compose.yml` from the template below.

```yml
# Remember to adjust the parameters to your needs
version: '3.7'
services:
  my-server:
    image: rutkowski/cod2:2.9-server1.3-mysql-unsafe
    container_name: my-server
    user: "1001:1002" # you can skip, this is set by default
    restart: always
    stdin_open: true
    tty: true
    ports:
      - 28970:28970
      - 28970:28970/udp
    volumes:
      - ./my-server:/cod2/my-server:ro
      - ~/cod2/main/1_3:/cod2/main:ro
      - ~/cod2/Library:/cod2/library:ro
    environment:
      PARAMS_BEFORE: "+exec server.cfg"
      COD2_SET_fs_homepath: "/cod2/home"
      COD2_SET_fs_library: "/cod2/library"
      COD2_SET_fs_game: "my-server"
      COD2_SET_dedicated: 2
      COD2_SET_net_port: 28970
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"

networks:
  default:
    external:
      name: my_network
```

# 🏠 Development

Any contribution is welcome.

To build locally you can use command `podman build --format=docker --build-arg cod2_patch=3 --build-arg mysql_variant=2 --build-arg speex=1 --build-arg enable_unsafe=1 -t cod2:local .`

# 📦 New version

Update [libcod_commit and version](https://github.com/rutkowski-tomasz/cod2-docker/blob/master/.github/workflows/build-push.yml#L23) 
