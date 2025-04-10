#!/usr/bin/env python
"""
Script to index Common Voice dataset CSV into Elasticsearch.
Usage: python cv-index.py [--es-host HOST]
"""

import os
import argparse
import pandas as pd
from elasticsearch import Elasticsearch, helpers
import logging
import sys
from tqdm import tqdm

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Index Common Voice CSV into Elasticsearch"
    )
    parser.add_argument(
        "--es-host", default="http://localhost:9200", help="Elasticsearch host URL"
    )
    return parser.parse_args()


def create_es_index(es_client, index_name):
    """Create Elasticsearch index with appropriate mappings."""
    # Check if index already exists
    if es_client.indices.exists(index=index_name):
        logger.info(f"Index '{index_name}' already exists, deleting it...")
        es_client.indices.delete(index=index_name)

    # Define index mappings for our fields
    mappings = {
        "mappings": {
            "properties": {
                "generated_text": {"type": "text", "analyzer": "english"},
                "original_text": {"type": "text", "analyzer": "english"},
                "duration": {"type": "float"},
                "age": {
                    "type": "text",
                    "fields": {"keyword": {"type": "keyword", "ignore_above": 256}},
                },
                "gender": {
                    "type": "text",
                    "fields": {"keyword": {"type": "keyword", "ignore_above": 256}},
                },
                "accent": {
                    "type": "text",
                    "fields": {"keyword": {"type": "keyword", "ignore_above": 256}},
                },
                "path": {"type": "keyword"},
            }
        },
        "settings": {"number_of_shards": 2, "number_of_replicas": 1},
    }

    # Create the index with the defined mappings
    es_client.indices.create(index=index_name, body=mappings)
    logger.info(f"Created index '{index_name}' with mappings")


def generate_documents(csv_data):
    """Generate Elasticsearch documents from CSV data."""
    for _, row in csv_data.fillna("").iterrows():
        doc = {
            "generated_text": row.get("generated_text", ""),
            "original_text": row.get("sentence", ""),
            "duration": float(row.get("duration", 0)) if row.get("duration") else 0,
            "age": row.get("age", ""),
            "gender": row.get("gender", ""),
            "accent": row.get("accent", ""),
            "path": row.get("path", ""),
        }
        logger.info(f"Document: {doc}")
        yield doc


def bulk_index_data(es_client, index_name, csv_data):
    """Bulk index the data into Elasticsearch."""
    # Create the actions for bulk operation
    actions = [
        {"_index": index_name, "_source": doc} for doc in generate_documents(csv_data)
    ]

    # Perform bulk indexing
    success, failed = 0, 0
    for ok, item in tqdm(
        helpers.streaming_bulk(es_client, actions, raise_on_error=True),
        total=len(csv_data),
        desc="Indexing documents",
    ):
        if ok:
            success += 1
        else:
            failed += 1
            logger.error(f"Failed to index document: {item}")

    logger.info(f"Indexing complete: {success} succeeded, {failed} failed")


def main():
    """Main function to execute the indexing process."""
    args = parse_args()

    # Define default values for removed arguments
    csv_path = os.path.join(ROOT_DIR, "asr", "cv-valid-dev-updated.csv")
    index_name = "cv-transcriptions"

    # Connect to Elasticsearch
    try:
        es = Elasticsearch([args.es_host])
        if not es.ping():
            logger.error("Could not connect to Elasticsearch. Is it running?")
            return
        logger.info(f"Connected to Elasticsearch at {args.es_host}")
    except Exception as e:
        logger.error(f"Failed to connect to Elasticsearch: {str(e)}")
        return

    # Load the CSV data
    try:
        logger.info(f"Loading CSV from {csv_path}")
        df = pd.read_csv(csv_path)
        logger.info(f"Loaded {len(df)} records from CSV")
    except Exception as e:
        logger.error(f"Failed to load CSV: {str(e)}")
        return

    # Create the index
    try:
        create_es_index(es, index_name)
    except Exception as e:
        logger.error(f"Failed to create index: {str(e)}")
        return

    # Index the data
    try:
        bulk_index_data(es, index_name, df)
    except Exception as e:
        logger.error(f"Failed during indexing: {str(e)}")
        # log errors in e.errors
        for error in e.errors:
            logger.error(f"Error: {error}")
        return

    # Get index stats
    try:
        stats = es.indices.stats(index=index_name)
        doc_count = stats["indices"][index_name]["total"]["docs"]["count"]
        logger.info(f"Total documents indexed: {doc_count}")
    except Exception as e:
        logger.error(f"Failed to get index stats: {str(e)}")

    logger.info("Indexing process completed")


if __name__ == "__main__":
    main()
