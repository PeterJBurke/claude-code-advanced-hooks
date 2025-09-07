#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "python-dotenv",
# ]
# ///

import json
import sys
import re
import subprocess
import os
from pathlib import Path
from utils.constants import ensure_session_log_dir

try:
    from dotenv import load_dotenv
    
    # Load .env from the project root (parent directory of .claude)
    env_path = Path(__file__).parent.parent.parent / ".env"
    load_dotenv(env_path)
except ImportError:
    pass  # dotenv is optional

def is_dangerous_rm_command(command):
    """
    Detection of only the most dangerous rm commands.
    Focus on system-critical paths to prevent catastrophic damage.
    """
    # Normalize command by removing extra spaces and converting to lowercase
    normalized = ' '.join(command.lower().split())
    
    # Only check for the most dangerous rm -rf patterns on critical system paths
    # Use more precise patterns to avoid false positives
    critical_system_patterns = [
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/$',              # rm -rf / (root only)
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/\*$',             # rm -rf /* (root contents only) 
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/usr(/\*?)?$',     # rm -rf /usr or /usr/*
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/etc(/\*?)?$',     # rm -rf /etc or /etc/*
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/boot(/\*?)?$',    # rm -rf /boot or /boot/*
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/sys(/\*?)?$',     # rm -rf /sys or /sys/*
        r'\brm\s+(-[rf]+|-r\s+-f|-f\s+-r|--recursive\s+--force|--force\s+--recursive)\s+/proc(/\*?)?$',    # rm -rf /proc or /proc/*
    ]
    
    # Only block the most critical system-destroying commands
    for pattern in critical_system_patterns:
        if re.search(pattern, normalized):
            return True
    
    return False

# File access restrictions have been completely removed
# The hook now only blocks the most dangerous system-destroying commands


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


def announce_pre_tool_use():
    """Announce pre-tool use event using TTS."""
    try:
        tts_script = get_tts_script_path()
        if not tts_script:
            return  # No TTS scripts available
        
        message = "Processing tool request"
        
        # Call the TTS script
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
        
        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        
        # Only check for system-destroying commands - all file access is now allowed
        # Check for dangerous rm commands on critical system paths
        if tool_name == 'Bash':
            command = tool_input.get('command', '')
            
            # Only block the most dangerous system-destroying rm commands
            if is_dangerous_rm_command(command):
                print("BLOCKED: System-critical rm command detected and prevented", file=sys.stderr)
                print("Command would destroy critical system directories", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Extract session_id
        session_id = input_data.get('session_id', 'unknown')
        
        # Ensure session log directory exists
        log_dir = ensure_session_log_dir(session_id)
        log_path = log_dir / 'pre_tool_use.json'
        
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
        
        # Announce pre-tool use via TTS only if --notify flag is set
        if args.notify:
            announce_pre_tool_use()
        
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Gracefully handle JSON decode errors
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)

if __name__ == '__main__':
    main()