import os
import pandas as pd
import requests
import time
import argparse

# Constants
DEFAULT_HOST = "http://localhost:8001"
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_FILE = f"{ROOT_DIR}/asr/cv-valid-dev.csv"
OUTPUT_CSV = f"{ROOT_DIR}/asr/cv-valid-dev-updated.csv"


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Transcribe audio files using ASR API."
    )
    parser.add_argument(
        "--host",
        type=str,
        default=DEFAULT_HOST,
        help=f"API host address (default: {DEFAULT_HOST})",
    )
    return parser.parse_args()


def check_api_status(host):
    """Check if the API is running."""
    ping_url = f"{host}/ping"
    try:
        response = requests.get(ping_url)
        if response.status_code == 200 and response.text.strip('"') == "pong":
            print("API is running.")
            return True
        else:
            print(
                f"API responded with status {response.status_code} and content {response.text}"
            )
            return False
    except requests.exceptions.ConnectionError:
        print("Could not connect to the API. Make sure it's running.")
        return False


def transcribe_file(file_path, api_url):
    """Transcribe a single audio file using the API."""
    try:
        with open(file_path, "rb") as f:
            files = {"file": f}
            response = requests.post(api_url, files=files)

        if response.status_code == 200:
            result = response.json()
            return result.get("transcription", ""), result.get("duration", "")
        else:
            print(
                f"Error transcribing {file_path}: {response.status_code} - {response.text}"
            )
            return "", ""
    except Exception as e:
        print(f"Exception while transcribing {file_path}: {str(e)}")
        return "", ""


def main():
    # Parse command line arguments
    args = parse_arguments()
    host = args.host
    api_url = f"{host}/asr"

    # Check if the API is running
    if not check_api_status(host):
        return

    # Load the CSV file
    try:
        df = pd.read_csv(CSV_FILE)
        print(f"Loaded CSV file with {len(df)} entries.")
    except Exception as e:
        print(f"Error loading CSV file: {str(e)}")
        return

    # Add a new column for the generated text if it doesn't exist
    if "generated_text" not in df.columns:
        df["generated_text"] = ""

    # Process each file
    total_files = len(df)
    success_count = 0

    # Process files without tqdm
    for idx, row in df.iterrows():
        file_name = row["filename"]
        full_path = os.path.join(ROOT_DIR, file_name)

        # Check if the file exists
        if not os.path.exists(full_path):
            print(f"File not found: {full_path}")
            continue

        # Check if we already have a transcription for this file (in case of resuming)
        if (
            pd.notna(df.loc[idx, "generated_text"])
            and df.loc[idx, "generated_text"] != ""
        ):
            print(f"Skipping {file_name} as it already has a transcription.")
            success_count += 1
            continue

        # Transcribe the file
        print(f"Transcribing {file_name}...")
        transcription, duration = transcribe_file(full_path, api_url)

        # Save the transcription
        if transcription:
            df.loc[idx, "generated_text"] = transcription
            success_count += 1

            # Save after each successful transcription to avoid losing progress
            if idx % 10 == 0:
                df.to_csv(OUTPUT_CSV, index=False)
                print(f"Progress saved: {success_count}/{total_files} files processed.")

        # Add a small delay to avoid overwhelming the API
        time.sleep(0.5)

    # Save the final results
    df.to_csv(OUTPUT_CSV, index=False)
    print(
        f"Processing complete. Successfully transcribed {success_count}/{total_files} files."
    )
    print(f"Results saved to {OUTPUT_CSV}")


if __name__ == "__main__":
    main()
