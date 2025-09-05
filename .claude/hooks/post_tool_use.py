#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "python-dotenv",
# ]
# ///

import json
import os
import sys
import subprocess
import random
from pathlib import Path
from datetime import datetime
from utils.constants import ensure_session_log_dir

try:
    from dotenv import load_dotenv
    
    # Load .env from the project root (parent directory of .claude)
    env_path = Path(__file__).parent.parent.parent / ".env"
    load_dotenv(env_path)
except ImportError:
    pass  # dotenv is optional


def get_tts_script_path():
    """
    Determine which TTS script to use based on available API keys.
    Priority order: ElevenLabs > OpenAI > pyttsx3
    """
    # Get current script directory and construct utils/tts path
    script_dir = Path(__file__).parent
    tts_dir = script_dir / "utils" / "tts"
    
    # Check for ElevenLabs API key (highest priority)
    if os.getenv('ELEVENLABS_API_KEY'):
        elevenlabs_script = tts_dir / "elevenlabs_tts.py"
        if elevenlabs_script.exists():
            return str(elevenlabs_script)
    
    # Check for OpenAI API key (second priority)
    if os.getenv('OPENAI_API_KEY'):
        openai_script = tts_dir / "openai_tts.py"
        if openai_script.exists():
            return str(openai_script)
    
    # Fall back to pyttsx3 (no API key required)
    pyttsx3_script = tts_dir / "pyttsx3_tts.py"
    if pyttsx3_script.exists():
        return str(pyttsx3_script)
    
    return None


def get_completion_messages():
    """Return list of friendly task completion messages."""
    return [
        "Task complete!",
        "Done!",
        "Finished!",
        "All set!",
        "Ready!",
    ]


def is_task_completion(input_data):
    """
    Detect if this tool use represents a task completion.
    
    Args:
        input_data: The hook input data containing tool information
        
    Returns:
        bool: True if this appears to be a task completion
    """
    try:
        # Check if TodoWrite tool was used with completed tasks
        tool_name = input_data.get('tool_name', '')
        if tool_name == 'TodoWrite':
            tool_response = input_data.get('tool_response', {})
            new_todos = tool_response.get('newTodos', [])
            
            # Check if any todos were marked as completed
            for todo in new_todos:
                if todo.get('status') == 'completed':
                    return True
        
        return False
        
    except (KeyError, TypeError, AttributeError):
        return False


def announce_task_completion():
    """Announce task completion using the best available TTS service."""
    try:
        tts_script = get_tts_script_path()
        if not tts_script:
            return  # No TTS scripts available
        
        # Get random completion message
        completion_messages = get_completion_messages()
        message = random.choice(completion_messages)
        
        # Call the TTS script with the completion message
        subprocess.run([
            "uv", "run", tts_script, message
        ], 
        capture_output=True,  # Suppress output
        timeout=10  # 10-second timeout
        )
        
    except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError):
        # Fail silently if TTS encounters issues
        pass
    except Exception:
        # Fail silently for any other errors
        pass


def main():
    try:
        # Parse command line arguments
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('--notify', action='store_true', help='Enable TTS notifications')
        args = parser.parse_args()
        
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        
        # Extract session_id
        session_id = input_data.get('session_id', 'unknown')
        
        # Ensure session log directory exists
        log_dir = ensure_session_log_dir(session_id)
        log_path = log_dir / 'post_tool_use.json'
        
        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, 'r') as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []
        
        # Append new data
        log_data.append(input_data)
        
        # Write back to file with formatting
        with open(log_path, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        # Create a debug file to confirm hook is running  
        debug_file = Path(__file__).parent / "debug_post_tool_use.txt"
        debug_file.write_text(f"PostToolUse hook ran at {datetime.now()}\n")

        # Announce completion after every tool use (only if --notify flag is set)
        if args.notify:
            # Always announce, not just for completed tasks
            try:
                tts_script = get_tts_script_path()
                if tts_script:
                    messages = get_completion_messages()
                    message = random.choice(messages)
                    subprocess.run(["uv", "run", tts_script, message], timeout=10)
            except Exception:
                pass
        
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Exit cleanly on any other error
        sys.exit(0)

if __name__ == '__main__':
    main()