# Docker Docs

## Basic Commands

### Version

I. To get the version of the docker server engine:

```bash
docker -v
```

II. To get the version of the docker client and server:

```bash
docker version
```

III. To get the info of the docker server engine:

```bash
docker info
```

### Listing

IV. To get the list of the running containers:

```bash
docker ps (use -a to get all containers)
```

V. To get the list of the images:

```bash
docker images
```

VI. To get the list of the volumes:

```bash
docker volume ls
```

VII. To get the list of the networks:

```bash
docker network ls
```

### Container Management

I. To start a container:

```bash
docker start <container_name>
```

II. To stop a container:

```bash
docker stop <container_name>
```

III. To restart a container:

```bash
docker restart <container_name>
```

IV. To remove a container:

```bash
docker rm <container_name>
```

V. Start a container from an image:

```bash
docker run <image_name>
```

VI. To get the logs of a container:

```bash
docker logs <container_name>
```

VII. To get the stats of a container:

```bash
docker stats <container_name>
```

VIII. To get the top of a container:

```bash
docker top <container_name>
```

IX. To get the inspect of a container:

```bash
docker inspect <container_name>
```

X. To get the diff of a container:

```bash
docker diff <container_name>
```

XI. To get the port of a container:

```bash
docker port <container_name>
```

XII. To get the stats of a container:

```bash
docker stats <container_name>
```

### Setting up SQL Server

II. Is needed to run the following command to set the permissions:

```bash
VOLUMENAME=/home/jamerrq/sqlvolumes
docker run --rm --user root \
    -v $VOLUMENAME:/data \
    mcr.microsoft.com/mssql/server:2022-latest \
    bash -c "chown -R mssql /data"
```

I. To run a container with SQL Server:

```bash
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=74l,\3KS;Fci' \
-p 1433:1433 \
-v /home/jamerrq/sqlvolumes/data:/var/opt/mssql/data \
-v /home/jamerrq/sqlvolumes/log:/var/opt/mssql/log \
-v /home/jamerrq/sqlvolumes/secrets:/var/opt/mssql/secrets \
-d mcr.microsoft.com/mssql/server:2022-latest
```
