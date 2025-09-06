#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "python-dotenv",
# ]
# ///

import argparse
import json
import os
import sys
import subprocess
import random
from pathlib import Path
from utils.constants import ensure_session_log_dir

try:
    from dotenv import load_dotenv
    load_dotenv()
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


def get_notification_message(notification_data):
    """
    Generate an appropriate TTS message based on notification content.
    """
    engineer_name = os.getenv('ENGINEER_NAME', '').strip()
    name_prefix = f"{engineer_name}, " if engineer_name else ""
    
    # Extract notification content
    payload = notification_data.get('payload', {})
    notification_type = payload.get('type', '')
    message = payload.get('message', '')
    title = payload.get('title', '')
    
    # Check for user input/decision requests
    user_input_indicators = [
        'input', 'decision', 'choose', 'select', 'confirm', 'approve',
        'would you like', 'do you want', 'please', 'permission',
        'continue?', 'proceed?', 'yes/no', 'y/n'
    ]
    
    full_text = f"{title} {message}".lower()
    
    # Debug output if enabled
    if os.getenv('DEBUG_NOTIFICATIONS'):
        print(f"Analyzing notification text: '{full_text}'", file=sys.stderr)
    
    # Check if this looks like a user input request
    matched_indicators = [indicator for indicator in user_input_indicators if indicator in full_text]
    if matched_indicators:
        messages = [
            f"{name_prefix}Your input is needed",
            f"{name_prefix}Claude needs your decision", 
            f"{name_prefix}Please check Claude",
            f"{name_prefix}User input required"
        ]
        selected_message = random.choice(messages)
        if os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"Matched user input indicators: {matched_indicators}", file=sys.stderr)
            print(f"Selected TTS message: '{selected_message}'", file=sys.stderr)
        return selected_message
    
    # Check for error/warning notifications
    if 'error' in full_text or 'warning' in full_text or 'failed' in full_text:
        messages = [
            f"{name_prefix}Error occurred, check Claude",
            f"{name_prefix}Something needs attention",
            f"{name_prefix}Check for issues"
        ]
        selected_message = random.choice(messages)
        if os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"Matched error/warning indicators", file=sys.stderr)
            print(f"Selected TTS message: '{selected_message}'", file=sys.stderr)
        return selected_message
    
    # Check for completion/success notifications
    completion_words = ['complete', 'finished', 'done', 'success']
    matched_completion = [word for word in completion_words if word in full_text]
    if matched_completion:
        messages = [
            f"{name_prefix}Task completed",
            f"{name_prefix}Claude is done",
            f"{name_prefix}Work finished"
        ]
        selected_message = random.choice(messages)
        if os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"Matched completion indicators: {matched_completion}", file=sys.stderr)
            print(f"Selected TTS message: '{selected_message}'", file=sys.stderr)
        return selected_message
    
    # Default message for other notifications
    default_message = f"{name_prefix}Notification from Claude"
    if os.getenv('DEBUG_NOTIFICATIONS'):
        print(f"No specific indicators matched, using default TTS message: '{default_message}'", file=sys.stderr)
    return default_message


def announce_notification(notification_data):
    """Announce notification with context-aware TTS message."""
    try:
        tts_script = get_tts_script_path()
        if not tts_script:
            return  # No TTS scripts available
        
        # Get context-aware message
        notification_message = get_notification_message(notification_data)
        
        # Call the TTS script with the notification message
        result = subprocess.run([
            "uv", "run", tts_script, notification_message
        ], 
        capture_output=True,  # Suppress output
        timeout=10,  # 10-second timeout
        text=True
        )
        
        # For debugging - check if we should show errors
        if result.returncode != 0 and os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"TTS Error: {result.stderr}", file=sys.stderr)
            print(f"TTS Message was: {notification_message}", file=sys.stderr)
        
    except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError) as e:
        # For debugging - check if we should show errors
        if os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"TTS Exception: {e}", file=sys.stderr)
        pass
    except Exception as e:
        # For debugging - check if we should show errors  
        if os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"TTS Unexpected error: {e}", file=sys.stderr)
        pass


def main():
    try:
        # Parse command line arguments
        parser = argparse.ArgumentParser()
        parser.add_argument('--notify', action='store_true', help='Enable TTS notifications')
        args = parser.parse_args()
        
        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())
        
        # Extract session_id
        session_id = input_data.get('session_id', 'unknown')
        
        # Ensure session log directory exists
        log_dir = ensure_session_log_dir(session_id)
        log_file = log_dir / 'notification.json'
        
        # Read existing log data or initialize empty list
        if log_file.exists():
            with open(log_file, 'r') as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []
        
        # Append new data
        log_data.append(input_data)
        
        # Write back to file with formatting
        with open(log_file, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        # Debug: Log notification content if debugging is enabled
        if os.getenv('DEBUG_NOTIFICATIONS'):
            print(f"Notification received: {json.dumps(input_data, indent=2)}", file=sys.stderr)
        
        # Announce notification via TTS only if --notify flag is set
        if args.notify:
            announce_notification(input_data)
        
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)

if __name__ == '__main__':
    main()