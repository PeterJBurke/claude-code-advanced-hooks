#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "elevenlabs",
#     "python-dotenv",
# ]
# ///

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from project directory
project_env = Path(__file__).parent.parent.parent.parent / ".env"
if project_env.exists():
    load_dotenv(project_env)
else:
    load_dotenv()  # Fallback to current directory

# Get API key from environment
api_key = os.getenv('ELEVENLABS_API_KEY')
if not api_key:
    sys.exit(1)

def play_text(text):
    """Generate and play text using ElevenLabs with personalized name."""
    try:
        from elevenlabs.client import ElevenLabs
        from elevenlabs import play
        
        # Initialize client
        client = ElevenLabs(api_key=api_key)
        
        # Get engineer name from environment or use default
        engineer_name = os.getenv("ENGINEER_NAME", "Peter")
        
        # Personalize the message
        # personalized_text = f"{text}, {engineer_name}"  # Commented out - remove name from TTS message
        personalized_text = text
        
        # Generate audio with ElevenLabs Turbo v2.5
        audio = client.text_to_speech.convert(
            text=personalized_text,
            voice_id="cgSgspJ2msm6clMCkdW9",
            model_id="eleven_turbo_v2_5",
            output_format="mp3_44100_128",
        )
        
        # Play the audio directly
        play(audio)
        
    except Exception as e:
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        text = " ".join(sys.argv[1:])
        play_text(text)
    else:
        sys.exit(1)