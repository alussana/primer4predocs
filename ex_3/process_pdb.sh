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
  mkdssp "${PDB_ID}.pdb" "$OUTPUT_DIR/${PDB_ID}.dssp"
  
  # Clean up PDB file
  rm "${PDB_ID}.pdb"
done
