# primer4predocs

2025-01-15

[Alessandro Lussana](http://alussana.xyz), [EMBL-EBI](https://www.ebi.ac.uk)

## Containers

Notes and exercises about [Docker](https://www.docker.com) and [Apptainer](https://apptainer.org) (formerly Singularity) for the 2025 Primer for predocs course.

Docker is required for exercises 1, 2, and 4; both Docker and Apptainer are required for exercise 3.

### 1) Run a basic Docker container

Let's build a container that runs a specific Python version in a specific operating system.

> Topics:
>
> * Dockerfile syntax
> * Building images
> * Running containers
> * DockerHub

Find the relevant files in the exercise directory

```bash
cd ex_1
```

#### Write a dummy script

We want to execute this particular script, `hello.py`, inside the container

```python
import sys

print(f"Hello from Python {sys.version} inside the Docker container!")
```

#### Create a Dockerfile

Saved as `Dockerfile`

```docker
# Use Debian Bookworm as the base image
FROM debian:bookworm

# Set an environment variable to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for Python and the desired Python version
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Add a simple Python script
COPY hello.py .

# Command to run Python on container start
CMD ["python3", "hello.py"]
```

#### Build the Docker image

```bash
docker build -t python-debian-bookworm .
```

`-t python-debian-bookworm` assigns the tag python-debian-bookworm to the image.

#### Run the Docker Container

```bash
docker run --rm python-debian-bookworm
```

`--rm` tells the Docker deamon to remove the container once it is stopped

#### Explore the Container

We can run the container interactively by overriding the `CMD` command

```bash
docker run -it --rm python-debian-bookworm bash
```

#### Push the image to Docker Hub

[Docker Hub](https://hub.docker.com) is a public registry where you can find, get, and share Docker images. Images specificed in the `FROM` section of a Dockerfile can be pulled from Docker Hub at build time. User can access Docker Hub after creating an account.

Login by entering your Docker Hub username and password when prompted

```bash
docker login
```

Docker Hub uses specific tags to identify images. Replace <your_dockerhub_username> with your actual DockerHub username:

```bash
docker tag python-debian-bookworm <your_dockerhub_username>/python-debian-bookworm:latest
```

Push the image to Docker Hub

```bash
docker push <your_dockerhub_username>/python-debian-bookworm:latest
```

Others can now pull and use your image

```bash
docker pull <your_dockerhub_username>/python-debian-bookworm:latest
```

```bash
docker run --rm <your_dockerhub_username>/python-debian-bookworm
```

#### Clean up

List the available docker images

```bash
docker images
```

Optionally remove the image

```bash
docker rmi python-debian-bookworm
```

### 2) Run a less basic Docker container

We want to create a container to perform the following: take in input an arbitrary list of [PDB](https://www.rcsb.org) IDs; download the atomic coordinates for each ID; compute secondary structure parameters (with the [DSSP algorithm](https://en.wikipedia.org/wiki/DSSP_(algorithm))) for each entity; save the results on disk. Containers are *ephemeral* (i.e. temporary and stateless): to store the results of our workflow persistently we can use *Docker volumes*.

> Topics:
>
> * Docker volumes
> * Containerized workflows
> * `CMD` vs `ENTRYPOINT`

Find the relevant files in the exercise directory

```bash
cd ex_2
```

#### Write a Bash script

Saved as `process_pdb.sh`

```bash
#!/bin/bash

# Check if proper arguments are passed
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <pdb_ids_comma_separated> <output_directory>"
  exit 1
fi

# Input arguments
PDB_IDS=$1
OUTPUT_DIR=$2

# Create the output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Loop over PDB IDs, fetch files, and compute DSSP
IFS=',' read -r -a PDB_ARRAY <<< "$PDB_IDS"
for PDB_ID in "${PDB_ARRAY[@]}"
do
  echo "Processing PDB ID: $PDB_ID"
  
  # Download the PDB file
  URL="https://files.rcsb.org/download/${PDB_ID}.pdb.gz"
  wget -q $URL -O "${PDB_ID}.pdb.gz"
  
  # Decompress the PDB file
  gunzip -f "${PDB_ID}.pdb.gz"
  
  # Run DSSP to compute secondary structure
  mkdssp "${PDB_ID}.pdb" -o "$OUTPUT_DIR/${PDB_ID}.dssp"
  
  # Clean up PDB file
  rm "${PDB_ID}.pdb"
done
```

#### Create a Dockerfile

Saved as `Dockerfile`

```dockerfile
# Use a minimal base image with necessary utilities
FROM debian:bullseye-slim

# Set working directory
WORKDIR /app

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    gzip \
    dssp \
    && rm -rf /var/lib/apt/lists/*

# Script to download PDB and compute DSSP
COPY process_pdb.sh .

# Make the script executable
RUN chmod +x process_pdb.sh

# Set entrypoint to the script
ENTRYPOINT ["./process_pdb.sh"]
```

Note that `CMD` and `ENTRYPOINT` may in some cases have the same behaviour, but serve different purposes:

| Feature     | CMD                               | ENTRYPOINT                             |
| ----------- | --------------------------------- | -------------------------------------- |
| Primary Use | Default command or arguments      | Mandatory command to execute           |
| Overridable | Yes, easily                       | Only with `--entrypoint`               |
| Flexibility | Less rigid, acts as a fallback    | Enforces a specific behavior           |
| Combination | Can be overridden by `ENTRYPOINT` | Works with `CMD` for default arguments |

#### Build the Docker image

```bash
docker build -t pdb-dssp .
```

#### Run the container

```bash
docker run --rm -v $(pwd)/output:/app/output pdb-dssp "7QU4,7R08" /app/output
```

`-v` specifies the creation of a Docker volume, making a location on the host file system accessible by the container

The arguments `"7QU4,7R08"` and `/app/output` are concatenated to the `ENTRYPOINT`

### 3) Build an Apptainer image from a Docker image

> Topics:
>
> * Docker vs Apptainer
> * Building Apptainer images from Docker images
> * Running Apptainer containers

Docker is an industry standard for containerization but it needs root privileges, which is often incompatible with multi-user environments. Apptainer is a different technology that doesn't have this requirement and is designed for use cases that involve HPC and scientific research rather than DevOps and microservices.

Here's an excellent table generated by ChatGPT that helps to understand the main high-level differences between Docker and Apptainer:

| Feature                | Docker                     | Apptainer               |
| ---------------------- | -------------------------- | ----------------------- |
| Target Environment     | Cloud, DevOps              | HPC, Research           |
| Security               | Root-required (by default) | Rootless (by default)   |
| Image Format           | Layered                    | Single-file (SIF)       |
| Daemon                 | Required                   | Not required            |
| Multi-user Suitability | Limited                    | Excellent               |
| Ecosystem              | Large, general-purpose     | Niche, research-focused |

Find the relevant files in the exercise directory

```bash
cd ex_3
```

#### Build the Docker image

We are using the Docker image from the [previous exercise](#spawn-more-advanced-docker-containers)

```bash
docker build -t pdb-dssp .
```

#### Build the Apptainer image

This is only one of multiple ways to achieve it

```bash
apptainer build pdb-dssp.sif docker-daemon://pdb-dssp:latest
```

#### Run the container

Execute a command in the containerized environment

```bash
apptainer exec pdb-dssp.sif bash process_pdb.sh "7QU4,7R08" output
```

A quick reference of some useful Apptainer commands

| Task                               | Command                                                      |
| ---------------------------------- | ------------------------------------------------------------ |
| Build SIF from local Docker image  | `apptainer build <output_file>.sif docker-daemon://<image_name>:<tag>` |
| Run SIF                            | `apptainer run <output_file>.sif`                            |
| Execute commands in SIF            | `apptainer exec <output_file>.sif <command>`                 |
| Use a definition file to build SIF | `apptainer build <output_file>.sif <definition_file>.def`    |
| Debug or open shell                | `apptainer shell <output_file>.sif`                          |

### 4) Bonus: networking and Docker

We can deploy any service or workflow with containers. Let's build our own web server!

> Topics:
>
> * Explore different base images
> * Port mapping

Find the relevant files in the exercise directory

```bash
cd ex_4
```

#### Create a Custom HTML Page

Write a simple `index.html` 

```html
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Nginx!</title>
</head>
<body>
    <h1>Hello from Nginx running in Docker!</h1>
</body>
</html>
```

#### Write Nginx configuration file

Saved as `nginx.conf`

```nginx
events {

}

http {
  index    index.html;
  include  /etc/nginx/mime.types;

  server {
    server_name localhost;
    listen 80;
    root /usr/share/nginx/html/www;

    location /files/ {
      root    /usr/share/nginx/html;
      autoindex    on;
    }

    ## allow POST requests globally with static files
    error_page  405    =200 $uri;

  }
}
```

#### Write some dummy files to be served

```bash
mkdir -p files
echo "ciao!" > files/ciao.txt
echo "hello!" > files/hello.txt
```

#### Create a Dockerfile

Saved as `Dockerfile`

```dockerfile
# Use the official Nginx image as the base image
FROM nginx:latest

# Copy the custom Nginx config file to the container
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the index.html file to the Nginx HTML directory
COPY index.html /usr/share/nginx/html/www/index.html

# Expose port 80 for the Nginx server
EXPOSE 80
```

#### Build the Docker image

```bash
docker build -t nginx-docker .
```

#### Run the Docker container

```bash
docker run -d -v $(pwd)/files:/usr/share/nginx/html/files -p 8080:80 -t nginx-docker
```

`-d` runs the container in detached mode.

`-p 8080:80` maps port 8080 on your host to port 80 in the container.

#### Access the web server

Open your browser and navigate to

``````
http://localhost:8080
``````

Files in the mounted Docker volume are served at

```
http://localhost:8080/files
```

#### Clean up

List the running containers

```bash
docker ps
```

Find the CONTAINER ID for the running container and stop it

```bash
docker stop <CONTAINER_ID>
```

Remove the container

```bash
docker rm <CONTAINER_ID>
```

You can also remove the image

```bash
docker rmi nginx-docker
```

### Further learning

#### Integration with workflow managers

Workflow managers are essential tools to develop computational projects. See how containers seamlessly integrate with both [Snakemake](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html#running-jobs-in-containers) and [Nextflow](https://www.nextflow.io/docs/latest/container.html) to achieve reproducibility and portability of your projects.

See [https://github.com/alussana/nf-project-template](https://github.com/alussana/nf-project-template) for a well-tested project template that you can use to start, grow, share, and publish bioinformatics/data science projects of any size. 

#### Compose and Swarm

[Docker Compose](https://docs.docker.com/compose/) allows to run applications depending on different containers working together.

[Docker Swarm](https://docs.docker.com/engine/swarm/) allows to orchestrate containers running on different nodes.

#### Apptainer definitions

You can define and build Apptainer images from a [definition](https://apptainer.org/docs/user/main/definition_files.html) (`.def`) file, in a similar way the Docker images can be defined and built from a Dockerfile.