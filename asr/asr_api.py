import os
import tempfile
from contextlib import asynccontextmanager

import torch
import librosa
from pydub import AudioSegment
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor

# Global variables for model and processor
processor = None
model = None
device = "cuda" if torch.cuda.is_available() else "cpu"


# Define lifespan context manager
@asynccontextmanager
async def lifespan(app):
    # Load model during startup
    global processor, model
    print(f"Using device: {device}")

    try:
        model_name = "facebook/wav2vec2-large-960h"
        processor = Wav2Vec2Processor.from_pretrained(model_name)
        model = Wav2Vec2ForCTC.from_pretrained(model_name).to(device)
        print(f"Model {model_name} loaded successfully")
    except Exception as e:
        print(f"Error loading model: {str(e)}")

    yield  # Application runs here

    # Clean up during shutdown (if needed)
    print("Shutting down the application")


# Initialize FastAPI app with lifespan
app = FastAPI(
    title="ASR API",
    description="API for Automatic Speech Recognition",
    lifespan=lifespan,
)


# Ping endpoint to check if service is running
@app.get("/ping")
async def ping():
    return "pong"


# ASR endpoint to transcribe audio files
@app.post("/asr")
async def transcribe(file: UploadFile = File(...)):
    # Check if file is an audio file
    if not file.filename.lower().endswith((".mp3", ".wav", ".m4a", ".ogg")):
        raise HTTPException(
            status_code=400, detail="File must be an audio file (mp3, wav, m4a, ogg)"
        )

    temp_file_path = None
    try:
        # Create a temporary file to save the uploaded audio
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as temp_file:
            contents = await file.read()
            if not contents:
                raise HTTPException(status_code=400, detail="Uploaded file is empty")

            temp_file.write(contents)
            temp_file_path = temp_file.name

        # Get the duration of the audio file
        try:
            audio = AudioSegment.from_mp3(temp_file_path)
            duration_seconds = len(audio) / 1000.0  # Convert milliseconds to seconds
        except Exception as e:
            raise HTTPException(
                status_code=400, detail=f"Could not process audio file: {str(e)}"
            )

        # Convert MP3 to WAV and resample to 16kHz
        try:
            audio_array, _ = librosa.load(temp_file_path, sr=16000)
        except Exception as e:
            raise HTTPException(
                status_code=400, detail=f"Could not load audio file: {str(e)}"
            )

        # Preprocess the audio data
        input_values = processor(
            audio_array, sampling_rate=16000, return_tensors="pt"
        ).input_values.to(device)

        # Perform inference
        with torch.no_grad():
            logits = model(input_values).logits

        # Get the predicted ids
        predicted_ids = torch.argmax(logits, dim=-1)

        # Convert ids to text
        transcription = processor.batch_decode(predicted_ids)[0]

        # Return the transcription and duration
        return JSONResponse(
            content={
                "transcription": transcription,
                "duration": str(round(duration_seconds, 1)),
            }
        )

    except HTTPException as he:
        # Re-raise HTTP exceptions
        raise he
    except Exception as e:
        # Handle generic exceptions
        return JSONResponse(
            status_code=500, content={"error": f"An error occurred: {str(e)}"}
        )

    finally:
        # Always clean up the temporary file
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
            except Exception as e:
                print(f"Error removing temporary file: {str(e)}")


# Run the app with uvicorn
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
