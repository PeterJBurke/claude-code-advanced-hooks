# Claude Code Global Setup Guide

This guide will set up Claude Code with comprehensive hooks, statusline, and MCP servers globally in your `~/.claude` directory so they work across all projects.

## Overview

This setup includes:
- **Comprehensive hook system** with logging, TTS notifications, and safety checks
- **StatusLine integration** with ccusage for usage tracking  
- **MCP servers** for browser integration
- **AI-powered features** using Anthropic and OpenAI APIs
- **Text-to-speech notifications** with multiple TTS providers

## Prerequisites

### Required Software

1. **uv** (Python package manager)
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Node.js and npm** (for ccusage and MCP servers)
   ```bash
   # macOS with Homebrew
   brew install node
   
   # Or download from nodejs.org
   ```

3. **Python 3.13+** (will be managed by uv)
   ```bash
   # uv will handle Python installation automatically
   ```

## Setup Instructions

### 1. Create Global Claude Directory Structure

```bash
mkdir -p ~/.claude/hooks/utils/{llm,tts,utils}
cd ~/.claude
```

### 2. Create Main Configuration Files

#### `~/.claude/settings.json`
```json
{
  "permissions": {
    "allow": [
      "Bash(find:*)",
      "Bash(python:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(timeout:*)",
      "Bash(xdg-open:*)",
      "Bash(git checkout:*)",
      "Bash(uv run:*)",
      "Read(/Users/$USER/.claude/**)",
      "Read(/Users/$USER/**)",
      "Read(/Users/$USER/.config/**)",
      "Bash(sudo:*)",
      "Bash(claude --version)",
      "Bash(uv:*)",
      "Bash(source .env)",
      "Bash(source:*)",
      "Bash(echo:*)",
      "WebFetch(domain:ccusage.com)",
      "Bash(bun x ccusage:*)",
      "Bash(npx -y ccusage:*)",
      "Bash(grep:*)"
    ],
    "deny": [],
    "ask": []
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/pre_tool_use.py"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/post_tool_use.py"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/notification.py"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/subagent_stop.py --notify"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/pre_compact.py --notify"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/user_prompt_submit.py --notify"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/session_start.py --notify"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run ~/.claude/hooks/stop.py --notify"
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "npx -y ccusage statusline",
    "padding": 0
  },
  "mcpServers": {
    "browser-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@browser-mcp/mcp-server"
      ],
      "env": {
        "BROWSER_MCP_PORT": "3000",
        "BROWSER_HEADLESS": "false"
      }
    }
  }
}
```

### 3. Environment Variables

Create `~/.claude/.env`:
```bash
# Required API Keys
ANTHROPIC_API_KEY=your-anthropic-api-key-here
OPENAI_API_KEY=your-openai-api-key-here
ELEVENLABS_API_KEY=your-elevenlabs-api-key-here

# Engineer Name (for personalization)
ENGINEER_NAME=YourName

# Optional: Custom log directory
CLAUDE_HOOKS_LOG_DIR=~/.claude/logs

# Optional: Additional integrations
MAVLINK_HOST=192.168.1.100
```

**🔑 API Key Setup:**
- **Anthropic:** Get from https://console.anthropic.com/
- **OpenAI:** Get from https://platform.openai.com/api-keys  
- **ElevenLabs:** Get from https://elevenlabs.io/app/speech-synthesis (optional, for TTS)

### 4. Python Configuration

#### `~/.claude/hooks/pyproject.toml`
```toml
[project]
name = "claude-hooks"
version = "0.1.0"
description = "Global Claude Code Hooks"
readme = "README.md"
requires-python = ">=3.13"
dependencies = [
    "python-dotenv",
    "anthropic",
    "openai",
    "elevenlabs",
    "pyttsx3"
]
```

#### `~/.claude/hooks/.python-version`
```
3.13
```

### 5. Core Hook Scripts

#### `~/.claude/hooks/utils/constants.py`
```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

"""
Constants for Claude Code Hooks.
"""

import os
from pathlib import Path

# Base directory for all logs - now in ~/.claude
LOG_BASE_DIR = os.environ.get("CLAUDE_HOOKS_LOG_DIR", str(Path.home() / ".claude" / "logs"))

# LLM Model Selections
OPENAI_MODEL = "gpt-4o-mini"  # Fast, cost-effective OpenAI model
ANTHROPIC_MODEL = "claude-3-5-haiku-20241022"  # Fast Anthropic model

def get_session_log_dir(session_id: str) -> Path:
    """Get the log directory for a specific session."""
    return Path(LOG_BASE_DIR) / session_id

def ensure_session_log_dir(session_id: str) -> Path:
    """Ensure the log directory for a session exists."""
    log_dir = get_session_log_dir(session_id)
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir
```

#### `~/.claude/hooks/utils/llm/anth.py`
```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "anthropic",
#     "python-dotenv",
# ]
# ///

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Add parent directory to path to import constants
sys.path.insert(0, str(Path(__file__).parent.parent))
from constants import ANTHROPIC_MODEL

def prompt_llm(prompt_text):
    """Base Anthropic LLM prompting method using fastest model."""
    load_dotenv(Path.home() / ".claude" / ".env")
    
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return None
        
    try:
        import anthropic
        client = anthropic.Anthropic(api_key=api_key)
        
        response = client.messages.create(
            model=ANTHROPIC_MODEL,
            max_tokens=150,
            temperature=0,
            messages=[{"role": "user", "content": prompt_text}]
        )
        
        return response.content[0].text if response.content else None
        
    except Exception as e:
        print(f"LLM Error: {e}", file=sys.stderr)
        return None

if __name__ == "__main__":
    if len(sys.argv) > 1:
        result = prompt_llm(sys.argv[1])
        if result:
            print(result)
```

#### `~/.claude/hooks/utils/tts/elevenlabs_tts.py`
```python
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

# Load environment variables from ~/.claude/.env
load_dotenv(Path.home() / ".claude" / ".env")

# Get API key from environment
api_key = os.getenv('ELEVENLABS_API_KEY')
if not api_key:
    sys.exit(1)

def play_text(text):
    """Generate and play text using ElevenLabs with personalized name."""
    try:
        from elevenlabs.client import ElevenLabs
        from elevenlabs import play, stream
        
        client = ElevenLabs(api_key=api_key)
        
        # Get engineer name for personalization
        engineer_name = os.getenv('ENGINEER_NAME', 'Engineer')
        personalized_text = text.replace('Engineer', engineer_name)
        
        audio = client.generate(
            text=personalized_text,
            voice="Rachel",  # or your preferred voice
            model="eleven_multilingual_v2"
        )
        
        play(audio)
        
    except Exception as e:
        print(f"ElevenLabs TTS Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    text = sys.argv[1] if len(sys.argv) > 1 else "Hello from ElevenLabs!"
    play_text(text)
```

### 6. Main Hook Scripts

#### `~/.claude/hooks/session_start.py`
```python
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
from pathlib import Path
from datetime import datetime
from utils.constants import ensure_session_log_dir

try:
    from dotenv import load_dotenv
    load_dotenv(Path.home() / ".claude" / ".env")
except ImportError:
    pass

def log_session_start(session_id, input_data):
    """Log session start event to session directory."""
    log_dir = ensure_session_log_dir(session_id)
    log_file = log_dir / 'session_start.json'
    
    if log_file.exists():
        with open(log_file, 'r') as f:
            try:
                log_data = json.load(f)
            except (json.JSONDecodeError, ValueError):
                log_data = []
    else:
        log_data = []
    
    log_data.append(input_data)
    
    with open(log_file, 'w') as f:
        json.dump(log_data, f, indent=2)

def notify_session_start():
    """Send notification about session start."""
    try:
        engineer_name = os.getenv('ENGINEER_NAME', 'Engineer')
        tts_script = Path.home() / ".claude" / "hooks" / "utils" / "tts" / "elevenlabs_tts.py"
        
        if tts_script.exists() and os.getenv('ELEVENLABS_API_KEY'):
            subprocess.run([
                "uv", "run", str(tts_script), 
                f"Hello {engineer_name}, Claude session started!"
            ], check=False)
    except Exception:
        pass

def main():
    parser = argparse.ArgumentParser(description='Session Start Hook')
    parser.add_argument('--notify', action='store_true', help='Enable notifications')
    args = parser.parse_args()
    
    try:
        input_data = json.load(sys.stdin)
        session_id = input_data.get('session_id')
        
        if session_id:
            log_session_start(session_id, input_data)
            
        if args.notify:
            notify_session_start()
            
    except Exception as e:
        print(f"Session Start Hook Error: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
```

#### `~/.claude/hooks/pre_tool_use.py`
```python
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
    load_dotenv(Path.home() / ".claude" / ".env")
except ImportError:
    pass

def is_dangerous_rm_command(command):
    """Comprehensive detection of dangerous rm commands."""
    normalized = ' '.join(command.lower().split())
    
    patterns = [
        r'\brm\s+.*-[a-z]*r[a-z]*f',
        r'\brm\s+.*-[a-z]*f[a-z]*r', 
        r'\brm\s+--recursive\s+--force',
        r'\brm\s+--force\s+--recursive',
        r'\brm\s+-r\s+.*-f',
        r'\brm\s+-f\s+.*-r',
    ]
    
    for pattern in patterns:
        if re.search(pattern, normalized):
            return True
    
    dangerous_paths = [
        '/', '/home', '/usr', '/var', '/etc', '/boot', '/sys', '/proc',
        '~', '$HOME', '${HOME}', '/Users', '/Applications'
    ]
    
    if re.search(r'\brm\s+.*-r', normalized):
        for path in dangerous_paths:
            if path in command:
                return True
                
    return False

def main():
    try:
        input_data = json.load(sys.stdin)
        session_id = input_data.get('session_id')
        
        if session_id:
            log_dir = ensure_session_log_dir(session_id)
            log_file = log_dir / 'pre_tool_use.json'
            
            if log_file.exists():
                with open(log_file, 'r') as f:
                    try:
                        log_data = json.load(f)
                    except (json.JSONDecodeError, ValueError):
                        log_data = []
            else:
                log_data = []
            
            log_data.append(input_data)
            
            with open(log_file, 'w') as f:
                json.dump(log_data, f, indent=2)
        
        # Safety check for dangerous commands
        tool_name = input_data.get('tool_name')
        if tool_name == 'Bash':
            command = input_data.get('payload', {}).get('command', '')
            if is_dangerous_rm_command(command):
                print("BLOCKED: Dangerous rm command detected", file=sys.stderr)
                print(json.dumps({"block": True, "reason": "Dangerous rm command detected"}))
                return
        
        print(json.dumps({"block": False}))
        
    except Exception as e:
        print(f"Pre Tool Use Hook Error: {e}", file=sys.stderr)
        print(json.dumps({"block": False}))

if __name__ == "__main__":
    main()
```

### 7. Initialize the Setup

```bash
cd ~/.claude/hooks

# Initialize Python environment
uv init
uv add python-dotenv anthropic openai elevenlabs pyttsx3

# Make scripts executable
chmod +x *.py
chmod +x utils/**/*.py

# Create log directory
mkdir -p ~/.claude/logs

# Test the setup
echo '{"session_id": "test"}' | uv run session_start.py --notify
```

### 8. Install StatusLine Dependencies

```bash
# Install ccusage globally
npm install -g ccusage

# Test statusline
npx -y ccusage statusline
```

## Key Path Changes for Global Setup

When adapting the scripts, the following paths need to be changed:

### Original Project Paths → Global Paths

| Original Path | Global Path | Notes |
|---------------|-------------|-------|
| `./.claude/hooks/` | `~/.claude/hooks/` | Hook scripts location |
| `./.claude/.env` | `~/.claude/.env` | Environment file |
| `./logs/` | `~/.claude/logs/` | Log directory |
| Project-specific imports | Absolute imports | Utils module imports |

### Environment Loading Changes

Update all `.env` loading in Python scripts:
```python
# OLD: Relative to project
env_path = Path(__file__).parent.parent.parent / ".env"

# NEW: Global location  
load_dotenv(Path.home() / ".claude" / ".env")
```

### Import Path Changes

Update utility imports in hook scripts:
```python
# Add to beginning of each hook script
import sys
from pathlib import Path
sys.path.insert(0, str(Path.home() / ".claude" / "hooks"))

# Now imports work globally
from utils.constants import ensure_session_log_dir
```

## Testing the Setup

### 1. Test Basic Functionality
```bash
# Test environment loading
uv run ~/.claude/hooks/utils/llm/anth.py "Hello world"

# Test TTS (if ElevenLabs key configured)
uv run ~/.claude/hooks/utils/tts/elevenlabs_tts.py "Testing TTS"

# Test hook execution
echo '{"session_id": "test-123"}' | uv run ~/.claude/hooks/session_start.py
```

### 2. Test Claude Code Integration
```bash
# Start Claude Code in any project
claude

# Hooks should now execute automatically
# Check logs in ~/.claude/logs/
```

### 3. Verify StatusLine
The statusline should appear at the bottom of your Claude Code interface showing usage statistics.

## Troubleshooting

### Common Issues

1. **uv not found**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   source ~/.bashrc  # or ~/.zshrc
   ```

2. **Python dependencies not installing**
   ```bash
   cd ~/.claude/hooks
   uv sync
   ```

3. **Permission denied errors**
   ```bash
   chmod +x ~/.claude/hooks/*.py
   chmod +x ~/.claude/hooks/utils/**/*.py
   ```

4. **API key errors**
   - Verify keys in `~/.claude/.env`
   - Test with: `cat ~/.claude/.env | grep API_KEY`

5. **TTS not working**
   - Check ElevenLabs API key validity
   - Test with: `uv run ~/.claude/hooks/utils/tts/elevenlabs_tts.py "test"`

6. **Logs not appearing**
   - Check directory permissions: `ls -la ~/.claude/logs/`
   - Verify log path in constants.py

## Features Enabled

With this setup, you get:

- ✅ **Comprehensive Logging**: All Claude interactions logged to `~/.claude/logs/`
- ✅ **Safety Checks**: Dangerous `rm` commands blocked automatically  
- ✅ **TTS Notifications**: Audio feedback for session events
- ✅ **AI Summarization**: LLM-powered event summaries
- ✅ **Usage Tracking**: StatusLine integration with ccusage
- ✅ **Browser Integration**: MCP server for web interactions
- ✅ **Global Configuration**: Works across all projects automatically

## Customization

### Adding New Hooks
Create new hook scripts in `~/.claude/hooks/` following the uv script format, then add them to `settings.json`.

### Changing TTS Voice
Edit the voice parameter in `elevenlabs_tts.py`:
```python
voice="Rachel"  # Change to your preferred voice
```

### Custom Log Directory
Set environment variable:
```bash
export CLAUDE_HOOKS_LOG_DIR="/path/to/custom/logs"
```

### Adding New APIs
1. Add API keys to `~/.claude/.env`
2. Add dependencies to `pyproject.toml` 
3. Create utility scripts in `utils/`
4. Reference in hook scripts

This setup provides a robust, feature-rich Claude Code environment that works consistently across all your projects!