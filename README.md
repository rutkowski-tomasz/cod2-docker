# 🚢 cod2-docker

Docker image for your Call of Duty 2 server. Libcod included! 

All the tags can be found here: [docker hub](https://hub.docker.com/repository/docker/rutkowski/cod2/general).

# 🪧 Tagging convention

`rutkowski:cod2/<version>-server<cod2-version>[-mysql-variant][-speex-enabled][-unsafe-enabled]`

For example image tagged `rutkowski/cod2:2.5-server1.3-mysqlvoron-speex-unsafe`:
- is representation of 2.5 version of this repo, each image has libcod support
- `server1.3` - is built for CoD2 version 1.3
- `mysqlvoron` - has mysql support added, voron version [link](https://github.com/voron00/libcod)
- `speex` - has speex support added, required for dynamic loading and playing sounds [link](https://github.com/ibuddieat/zk_libcod)
- `unsafe` unsafe flag was enabled during libcod build (adding commands for system manipulation) [link](https://github.com/ibuddieat/zk_libcod)

Read more about libcod [here](https://github.com/ibuddieat/zk_libcod)

# 🚀 Features

This repo was created beacuse it seems that [cod2docker](https://github.com/Lonsofore/cod2docker) is not longer maintained. Also it includes following advancements:

- integrating with latest [libcod](https://github.com/ibuddieat/zk_libcod)
- speex integration for dynamic sound loading
- `unsafe` parametrized build for enabling functions like: `system`, `file_unlink`, `scandir` etc.
- github workflow martix build
- running container as non-root user
- making mounted main and library folders read-only
- update to latest ubuntu version
- update to latest packages versions
- other minor optimizations: removing not used packages

# 🙇🏻‍♂️ Known issues

- static creation of nl folder instead of dynamic

# 🤷🏻‍♂️ How to use?

Upload your main folder and fs_game of server to the machine running docker. Create `docker-compose.yml` from the template below.

```yml
# Remember to adjust the parameters to your needs
version: '3.7'
services:
  my-server:
    image: rutkowski/cod2:2.5-server1.3-mysqlvoron-speex
    container_name: my-server
    user: "1001:1002"
    restart: always
    stdin_open: true
    tty: true
    ports:
      - 28970:28970
      - 28970:28970/udp
    volumes:
      - ./my-server:/cod2/my-server
      - ~/cod2/main/1_3:/cod2/main:ro
      - ~/cod2/Library:/cod2/.callofduty2/my-server/Library:ro
    environment:
      PARAMS_BEFORE: "+exec server.cfg"
      COD2_SET_fs_homepath: "/cod2/.callofduty2/"
      COD2_SET_fs_game: "my-server"
      COD2_SET_dedicated: 2
      COD2_SET_net_port: 28970
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

# 🏠 Development

Any contribution is welcome.

To build locally you can use command `podman build --format=docker --build-arg cod2_patch=3 --build-arg mysql_variant=2 --build-arg speex=1 --build-arg enable_unsafe=1 -t cod2:local .`
