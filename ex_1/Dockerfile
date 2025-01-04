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
