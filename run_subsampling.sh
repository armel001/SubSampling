#!/bin/bash

##########
# SCRIPT TO SUBSAMPLING SARS-CoV-2 DATASET
##########

# Description:
# This script processes SARS-CoV-2 sequence and metadata files for different variants.
# It performs indexing, subsampling, and extraction of sequence IDs, and metadata.
# Ensure that the dataset folder contains a subfolder for each variant.
# All files should start with the variant name, e.g., 'zota.fasta' or 'zota.metadata.tsv'.

# Usage Instructions:
# 0. Install dependencies AUGUR and SEQKIT using conda install 
# 1. Make sure you have a folder for each variant inside the 'dataset' folder.
# 2. Each folder should contain files with names starting with the variant name.
#    For example, 'zota.fasta' and 'zota.metadata.tsv'.
# 3. Run this script to process the dataset. The script will:
#    - Index the sequences.
#    - Perform subsampling based on provided parameters.
#    - Extract sequence IDs from the subsampled sequences.
#    - Extract metadata corresponding to the subsampled sequences.


##########

# AUTHOR: Thibaut Armel Chérif GNIMADI

# Exit immediately if a command exits with a non-zero status


set -e

dataset_folder="dataset"
variant_names=("ba2")

for variant in "${variant_names[@]}"; do
  echo "Processing variant: $variant"

  # Sequence and metadata paths specific 

  sequence_files=("$dataset_folder/$variant"/*"$variant".fasta)
  metadata_files=("$dataset_folder/$variant"/*.metadata.tsv)

  # Check if there are any fasta files in the variant directory
  
  if [ -e "${sequence_files[0]}" ]; then

    for sequence_file in "${sequence_files[@]}"; do

      echo "INDEXING: $sequence_file"

      # Construct the output for the indexed sequence
      index_output="${sequence_file%.fasta}.index.fasta"

      augur index -s "$sequence_file" -o "$index_output"

      # Handle existing directory: remove it if it exists, then create it
      index_dir="${sequence_file%.fasta}_index"
      if [ -d "$index_dir" ]; then
        rm -rf "$index_dir"
      fi
      mkdir "$index_dir"

      # Move the indexed sequence to the index directory
      mv "$index_output" "$index_dir"

      index_path="$index_dir/$(basename "$index_output")"

      echo "SUBSAMPLING: $sequence_file"

      # Construct the output path for the subsampled sequences
  
      subsampled_output="${sequence_file%.fasta}.subsampled_sequences.fasta"

      augur filter \
        --sequences "$sequence_file" \
        --sequence-index "$index_path" \
        --metadata "${metadata_files[0]}" \
        --min-date 2019 \
        --group-by country \
        --subsample-max-sequences 500 \
        --probabilistic-sampling \
        --include-where country=Guinea \
        --output "$subsampled_output" \
        --subsample-seed 10 


      echo "EXTRACTING SEQUENCES ID: $subsampled_output"

      # Construct output path for sequence IDs
      ids_output="${subsampled_output%.fasta}_sequences_ids.txt"
      seqkit seq -n "$subsampled_output" > "$ids_output"

      echo "EXTRACTING METADATA USING SeqID: $ids_output"

      # Extract metadata for the subsampled sequences
      subsampled_metadata_output="$dataset_folder/$variant/"$variant".subsampled_metadata.tsv"
      grep -F -f "$ids_output" "${metadata_files[0]}" > "$subsampled_metadata_output"

    done 
  else
    echo "No .fasta files found for variant: $variant"
  fi

done

