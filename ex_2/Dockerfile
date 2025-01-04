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
