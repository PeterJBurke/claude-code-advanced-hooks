# Claude Code Global Setup Guide

This guide will automatically download and install the Claude Code advanced hook system globally in your `~/.claude` directory so it works across all projects.

## 🚀 Quick Installation (Recommended)

### One-Line Installer

```bash
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/install-global.sh | bash
```

This installer is **smart** and preserves your existing Claude Code configuration:

✅ **Intelligent Merging**: Merges hook configuration with existing `settings.json`  
✅ **Automatic Backups**: Creates timestamped backups of all existing files  
✅ **Environment Handling**: Adds missing API keys to existing `.env` files  
✅ **Non-Destructive**: Never deletes existing configurations  
✅ **Permission Preservation**: Keeps your existing permission settings
✅ **ccusage Integration**: Automatically installs and configures statusline

## 📁 Global Directory Structure

After installation, your `~/.claude` directory will have the following structure:

```
~/.claude/
├── settings.json                   # Global Claude Code configuration (merged)
├── CLAUDE.md                      # Global instructions for all projects  
├── .env                           # API keys and environment variables (CRITICAL LOCATION)
├── logs/                          # Session logs (auto-generated)
│   ├── session-id-1/              # Individual session logs
│   │   ├── session_start.json
│   │   ├── pre_tool_use.json
│   │   ├── post_tool_use.json
│   │   ├── notification.json
│   │   └── stop.json
│   └── session-id-2/              # Another session's logs
└── hooks/                         # Complete hook system
    ├── pyproject.toml             # Python dependencies (uv project)
    ├── .env.example               # Environment template
    ├── session_start.py           # 🎬 Session initialization + TTS welcome
    ├── pre_tool_use.py            # 🛡️ Safety checks (blocks dangerous commands)
    ├── post_tool_use.py           # ✅ Post-execution processing + notifications
    ├── notification.py            # 🔔 System notifications + AI summaries
    ├── user_prompt_submit.py      # 📝 User interaction tracking
    ├── subagent_stop.py           # 🤖 Subagent lifecycle management  
    ├── pre_compact.py             # 🗜️ Memory optimization hooks
    ├── stop.py                    # 👋 Session termination + farewell TTS
    └── utils/                     # Utility modules
        ├── constants.py           # 📋 Configuration constants and paths
        ├── summarizer.py          # 🤖 AI-powered event summarization
        ├── llm/                   # AI integrations
        │   ├── anth.py           # 🧠 Anthropic Claude API integration
        │   └── oai.py            # 🧠 OpenAI GPT API integration
        └── tts/                   # Text-to-speech integrations
            ├── elevenlabs_tts.py  # 🔊 Premium ElevenLabs voice synthesis
            ├── openai_tts.py      # 🔊 OpenAI text-to-speech
            └── pyttsx3_tts.py     # 🔊 Offline fallback TTS
```

**🚨 CRITICAL**: The `.env` file MUST be in `~/.claude/.env` (root of .claude directory), NOT in `~/.claude/hooks/.env`. This is the most common cause of TTS failures.

**Key Features by Directory:**

- **Root (`~/.claude/`)**: Global configuration that applies to all your Claude Code projects
- **`hooks/`**: Complete hook system with all 8 lifecycle hooks and utilities  
- **`utils/llm/`**: AI integrations for intelligent event summarization
- **`utils/tts/`**: Multi-provider text-to-speech for audio notifications
- **`logs/`**: Comprehensive session logging with structured JSON data

## 📋 Manual Installation

### Prerequisites

1. **uv** (Python package manager)
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   source ~/.bashrc  # or ~/.zshrc
   ```

2. **Node.js and npm** (for statusline)
   ```bash
   # macOS with Homebrew
   brew install node
   
   # Ubuntu/Debian
   sudo apt update && sudo apt install nodejs npm
   
   # Or download from nodejs.org
   ```

3. **ccusage** (for API usage monitoring)
   ```bash
   npm install -g ccusage
   ```
   
   **Note**: You may see Node.js version warnings like:
   ```
   npm WARN EBADENGINE Unsupported engine {
   npm WARN EBADENGINE   package: 'ccusage@16.2.4',
   npm WARN EBADENGINE   required: { node: '>=20.19.4' },
   npm WARN EBADENGINE   current: { node: 'v18.19.1', npm: '9.2.0' }
   npm WARN EBADENGINE }
   ```
   These warnings can be safely ignored - ccusage works with older Node.js versions.

### Step 1: Create Directory Structure

```bash
# Create the global Claude directory structure
mkdir -p ~/.claude/hooks/utils/{llm,tts}
mkdir -p ~/.claude/logs
cd ~/.claude
```

### Step 2: Download Configuration Files

```bash
# Download main settings
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/settings.json -o ~/.claude/settings.json

# Download project template (optional)  
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/CLAUDE.md -o ~/.claude/CLAUDE.md
```

### Step 3: Download Hook System

```bash
cd ~/.claude/hooks

# Download Python project configuration
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/pyproject.toml -o pyproject.toml
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/.env.example -o .env.example

# Download all hook scripts
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/session_start.py -o session_start.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/pre_tool_use.py -o pre_tool_use.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/post_tool_use.py -o post_tool_use.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/notification.py -o notification.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/user_prompt_submit.py -o user_prompt_submit.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/subagent_stop.py -o subagent_stop.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/pre_compact.py -o pre_compact.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/stop.py -o stop.py

# Download utility modules
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/constants.py -o utils/constants.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/summarizer.py -o utils/summarizer.py

# Download LLM integrations
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/llm/anth.py -o utils/llm/anth.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/llm/oai.py -o utils/llm/oai.py

# Download TTS integrations  
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/tts/elevenlabs_tts.py -o utils/tts/elevenlabs_tts.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/tts/openai_tts.py -o utils/tts/openai_tts.py
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/hooks/utils/tts/pyttsx3_tts.py -o utils/tts/pyttsx3_tts.py

# Make scripts executable
chmod +x *.py utils/**/*.py
```

### Step 4: Bulk Download Alternative

Instead of downloading files individually, you can use this faster approach:

```bash
# Create a temporary directory and clone the repository
cd /tmp
git clone https://github.com/PeterJBurke/claude-code-advanced-hooks.git
cd claude-code-advanced-hooks

# Copy the .claude directory to your home directory
cp -r .claude ~/.claude

# Clean up
cd ~ && rm -rf /tmp/claude-code-advanced-hooks

# Make scripts executable
chmod +x ~/.claude/hooks/*.py ~/.claude/hooks/utils/**/*.py
```

### Step 5: Initialize Python Environment

```bash
cd ~/.claude/hooks

# Initialize and install dependencies
uv sync

# Create your environment file in the CORRECT location
cp .env.example ~/.claude/.env  # NOTE: Move to parent directory, NOT hooks/.env
```

### Step 6: Configure Environment Variables

🚨 **CRITICAL**: Edit `~/.claude/.env` (note: this file should be in the root .claude directory, not hooks):

```bash
# Edit with your favorite editor
nano ~/.claude/.env
# or
vim ~/.claude/.env
```

Add your API keys:
```bash
# Required for AI features
ANTHROPIC_API_KEY=your-anthropic-api-key-here
OPENAI_API_KEY=your-openai-api-key-here

# Optional for premium TTS
ELEVENLABS_API_KEY=your-elevenlabs-api-key-here

# Personalization
ENGINEER_NAME=YourName
```

### Step 7: Verify Environment File Location

This is the most critical step for TTS functionality:

```bash
# Verify .env is in the correct location
ls -la ~/.claude/.env          # ✅ Should exist here
ls -la ~/.claude/hooks/.env    # ❌ Should NOT exist here

# If you have a .env file in the hooks directory, remove it:
rm -f ~/.claude/hooks/.env

# Test environment loading
cd ~/.claude/hooks
uv run python -c "import os; from dotenv import load_dotenv; load_dotenv('../.env'); print(f'ELEVENLABS_API_KEY loaded: {bool(os.getenv(\"ELEVENLABS_API_KEY\"))}')"
```

### Step 8: Install StatusLine Dependencies

```bash
# Install ccusage globally for usage tracking
npm install -g ccusage

# Test statusline (will show "No input provided" - this is expected)
npx -y ccusage statusline
```

## 🔧 Advanced Setup Options

### Automated Installation Script

Create your own installer script with better error handling:

```bash
cat > install-claude-hooks.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Installing Claude Code Advanced Hooks globally..."

# Check prerequisites
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source ~/.bashrc
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Install ccusage first
echo "📊 Installing ccusage for statusline..."
npm install -g ccusage

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p ~/.claude/hooks/utils/{llm,tts}
mkdir -p ~/.claude/logs

# Define base URL
REPO_URL="https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main"

# Download function
download_file() {
    local url="$1"
    local output="$2"
    echo "⬇️  Downloading $(basename "$output")..."
    if ! curl -fsSL "$url" -o "$output"; then
        echo "❌ Failed to download $(basename "$output")"
        exit 1
    fi
}

# Download configuration files
download_file "$REPO_URL/.claude/settings.json" ~/.claude/settings.json
download_file "$REPO_URL/.claude/CLAUDE.md" ~/.claude/CLAUDE.md

# Download hook files
cd ~/.claude/hooks
download_file "$REPO_URL/.claude/hooks/pyproject.toml" pyproject.toml
download_file "$REPO_URL/.claude/hooks/.env.example" .env.example

# Download all hook scripts
for script in session_start.py pre_tool_use.py post_tool_use.py notification.py user_prompt_submit.py subagent_stop.py pre_compact.py stop.py; do
    download_file "$REPO_URL/.claude/hooks/$script" "$script"
done

# Download utilities
download_file "$REPO_URL/.claude/hooks/utils/constants.py" utils/constants.py
download_file "$REPO_URL/.claude/hooks/utils/summarizer.py" utils/summarizer.py

# Download LLM modules
download_file "$REPO_URL/.claude/hooks/utils/llm/anth.py" utils/llm/anth.py
download_file "$REPO_URL/.claude/hooks/utils/llm/oai.py" utils/llm/oai.py

# Download TTS modules
download_file "$REPO_URL/.claude/hooks/utils/tts/elevenlabs_tts.py" utils/tts/elevenlabs_tts.py
download_file "$REPO_URL/.claude/hooks/utils/tts/openai_tts.py" utils/tts/openai_tts.py
download_file "$REPO_URL/.claude/hooks/utils/tts/pyttsx3_tts.py" utils/tts/pyttsx3_tts.py

# Make executable
chmod +x *.py utils/**/*.py

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
uv sync

# Set up environment in the CORRECT location
if [ ! -f ~/.claude/.env ]; then
    cp .env.example ~/.claude/.env
    echo "📝 Created ~/.claude/.env - please edit with your API keys"
else
    echo "📝 Environment file already exists at ~/.claude/.env"
fi

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.claude/.env with your API keys"
echo "2. Test with: echo '{\"session_id\": \"test\"}' | uv run ~/.claude/hooks/session_start.py --notify"
echo "3. Start Claude Code in any project!"
EOF

chmod +x install-claude-hooks.sh
```

## 🧪 Testing the Installation

### Basic Functionality Tests

```bash
# Test hook execution
echo '{"session_id": "test-global"}' | uv run ~/.claude/hooks/session_start.py --notify

# Test AI integration (requires API key)
uv run ~/.claude/hooks/utils/llm/anth.py "Hello from global installation"

# Test TTS (requires API key) - Should use ElevenLabs, not pyttsx3
uv run ~/.claude/hooks/utils/tts/elevenlabs_tts.py "Global installation test"

# Test statusline
echo '{"test": "data"}' | npx -y ccusage statusline
```

### TTS Verification Tests

The most common issue is TTS not working correctly. Use these tests:

```bash
# Verify environment file location
ls -la ~/.claude/.env  # Must exist
ls -la ~/.claude/hooks/.env  # Must NOT exist

# Test environment loading in hooks context
cd ~/.claude/hooks
uv run python << EOF
import os
from pathlib import Path
from dotenv import load_dotenv

# Test the correct path that hooks should use
env_path = Path(__file__).parent / ".env"
print(f"Looking for .env at: {env_path}")
print(f"File exists: {env_path.exists()}")

# This should find ~/.claude/.env
if env_path.exists():
    load_dotenv(env_path)
    print(f"ELEVENLABS_API_KEY loaded: {bool(os.getenv('ELEVENLABS_API_KEY'))}")
else:
    print("❌ .env file not found - TTS will not work properly")
EOF

# Test TTS selection with debug
DEBUG_NOTIFICATIONS=1 echo '{"session_id": "test", "payload": {"message": "TTS test", "title": "Testing"}}' | uv run ~/.claude/hooks/notification.py --notify
```

### Integration Test

```bash
# Create a test project
mkdir ~/test-claude-project
cd ~/test-claude-project

# Start Claude Code (hooks should activate automatically)
claude
```

## 🔍 Verification

After installation, verify everything is working:

```bash
# Check directory structure
ls -la ~/.claude/
ls -la ~/.claude/hooks/

# Check Python environment
cd ~/.claude/hooks && uv run --version

# Check permissions
ls -la ~/.claude/hooks/*.py | head -5

# Test configuration
cat ~/.claude/settings.json | head -10

# CRITICAL: Verify environment file location
echo "Environment file location check:"
[ -f ~/.claude/.env ] && echo "✅ ~/.claude/.env exists" || echo "❌ ~/.claude/.env missing"
[ -f ~/.claude/hooks/.env ] && echo "❌ ~/.claude/hooks/.env exists (should not)" || echo "✅ ~/.claude/hooks/.env correctly absent"
```

## 🔧 Troubleshooting

### Most Common Issues

**1. TTS Not Working / Using Wrong Voice (Most Common Issue)**

This is almost always due to incorrect environment file location:

```bash
# Check environment file location
ls -la ~/.claude/.env          # ✅ Should exist
ls -la ~/.claude/hooks/.env    # ❌ Should NOT exist

# If .env is in wrong location, move it:
if [ -f ~/.claude/hooks/.env ]; then
    echo "Moving .env to correct location..."
    mv ~/.claude/hooks/.env ~/.claude/.env
fi

# Verify all hooks load .env from correct path
grep -n "load_dotenv" ~/.claude/hooks/*.py | grep -v ".env.example"

# Should show patterns like:
# load_dotenv(Path(__file__).parent / ".env")
# NOT: load_dotenv(Path(__file__).parent.parent.parent / ".env")

# Test TTS directly
cd ~/.claude/hooks
uv run utils/tts/elevenlabs_tts.py "TTS test message"

# If you hear pyttsx3 (robotic voice) instead of ElevenLabs, environment loading is broken
```

**2. Multiple TTS Voices Playing Simultaneously**

This happens when some hooks use ElevenLabs while others fall back to pyttsx3:

```bash
# Enable debug mode to see which TTS is being selected
DEBUG_NOTIFICATIONS=1 echo '{"session_id": "test", "payload": {"message": "Debug test", "title": "Testing"}}' | uv run ~/.claude/hooks/notification.py --notify

# Look for output like:
# DEBUG: ELEVENLABS_API_KEY present: True
# DEBUG: ElevenLabs script exists: True
# DEBUG: Selecting ElevenLabs: /home/peter/.claude/hooks/utils/tts/elevenlabs_tts.py

# If you see "ELEVENLABS_API_KEY present: False", the environment file is not loading
```

**3. StatusLine Not Working**

```bash
# Check ccusage installation
npm list -g ccusage

# Reinstall if needed
npm uninstall -g ccusage
npm install -g ccusage

# Test statusline manually
echo '{"test": "data"}' | npx -y ccusage statusline

# Check settings.json has statusLine configuration
grep -A5 statusLine ~/.claude/settings.json
```

**4. Permission Denied Errors**
   ```bash
   chmod +x ~/.claude/hooks/*.py
   find ~/.claude/hooks -name "*.py" -exec chmod +x {} \;
   ```

**5. Python Dependencies Not Installing**
   ```bash
   cd ~/.claude/hooks
   uv sync --reinstall
   ```

**6. API Keys Not Working**
   ```bash
   # Check environment file location (most common issue)
   ls -la ~/.claude/.env
   
   # Test loading
   cd ~/.claude/hooks
   uv run python -c "import os; from dotenv import load_dotenv; load_dotenv('../.env'); print('Keys loaded:', {k: bool(v) for k, v in os.environ.items() if 'API_KEY' in k})"
   ```

**7. Hooks Not Executing**
   ```bash
   # Check settings file
   cat ~/.claude/settings.json | grep -A10 hooks
   
   # Test direct execution
   echo '{"session_id": "debug"}' | uv run ~/.claude/hooks/session_start.py
   ```

**8. Download Failures**
   ```bash
   # Test connectivity
   curl -I https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/settings.json
   
   # Use git clone as backup
   git clone https://github.com/PeterJBurke/claude-code-advanced-hooks.git /tmp/claude-hooks
   cp -r /tmp/claude-hooks/.claude ~/
   ```

### Debug Mode

Enable comprehensive debugging for TTS and notification issues:

```bash
# Test notification system with full debug output
DEBUG_NOTIFICATIONS=1 echo '{"session_id": "test", "payload": {"message": "Would you like to continue?", "title": "Input Required"}}' | uv run ~/.claude/hooks/notification.py --notify

# Check debug files
ls -la ~/.claude/hooks/debug_*.txt
tail -f ~/.claude/hooks/debug_*.txt

# Test each TTS provider individually
echo "Testing ElevenLabs TTS..."
uv run ~/.claude/hooks/utils/tts/elevenlabs_tts.py "ElevenLabs test"

echo "Testing OpenAI TTS..."
uv run ~/.claude/hooks/utils/tts/openai_tts.py "OpenAI test"

echo "Testing pyttsx3 TTS..."
uv run ~/.claude/hooks/utils/tts/pyttsx3_tts.py "pyttsx3 test"
```

### Environment File Checklist

The most critical verification for proper TTS functionality:

| Check | Status | Action |
|-------|--------|--------|
| `.env` in `~/.claude/.env` | ✅ Must exist | Create if missing |
| `.env` in `~/.claude/hooks/.env` | ❌ Must NOT exist | Delete if present |
| Hook scripts load from parent directory | ✅ Required | Fix load_dotenv() calls |
| ELEVENLABS_API_KEY is set | ✅ For premium TTS | Add to .env file |
| ccusage installed globally | ✅ For statusline | `npm install -g ccusage` |

### Path Updates Required

When using the global installation, all path references are automatically updated to:

| Component | Global Path |
|-----------|-------------|
| Settings | `~/.claude/settings.json` |
| Environment | `~/.claude/.env` (CRITICAL) |
| Hook Scripts | `~/.claude/hooks/*.py` |
| Utilities | `~/.claude/hooks/utils/` |
| Logs | `~/.claude/logs/` |

## 🎯 Features Enabled

With this global setup, you get across ALL your projects:

- ✅ **Comprehensive Logging**: All interactions logged to `~/.claude/logs/`
- ✅ **Safety Checks**: Dangerous commands blocked automatically  
- ✅ **Context-Aware TTS**: Smart audio notifications that tell you exactly what's needed:
  - 🚨 "Your input is needed" when user decisions are required
  - ⚠️ "Error occurred, check Claude" for warnings and issues  
  - ✅ "Task completed" for successful operations
- ✅ **AI Summarization**: Intelligent event descriptions
- ✅ **Usage Tracking**: StatusLine integration with ccusage
- ✅ **Browser Integration**: MCP server support
- ✅ **Global Consistency**: Same experience everywhere

## 📚 Resources

- **GitHub Repository**: https://github.com/PeterJBurke/claude-code-advanced-hooks
- **Project-Specific Setup**: See repository README.md
- **Claude Code Documentation**: https://docs.anthropic.com/en/docs/claude-code
- **Issues/Support**: https://github.com/PeterJBurke/claude-code-advanced-hooks/issues

## 🤝 Contributing

Found an issue or want to improve the installation process? 

1. Report bugs at https://github.com/PeterJBurke/claude-code-advanced-hooks/issues
2. Suggest improvements for this installation guide
3. Help test the TTS functionality across different environments

### Testing Checklist for Contributors

Before submitting changes, verify:

- ✅ `.env` file loads from `~/.claude/.env` (not hooks subdirectory)
- ✅ TTS works with ElevenLabs (not pyttsx3 fallback)
- ✅ StatusLine displays usage information
- ✅ Hooks execute without errors
- ✅ API keys are properly loaded
- ✅ No multiple TTS systems playing simultaneously
- ✅ ccusage is installed and working
- ✅ All hook scripts use correct environment loading paths

---

**🎉 Ready to experience Claude Code with advanced hooks globally? Follow the installation steps above and enjoy enhanced AI interactions across all your projects!**

**Most Important**: If TTS doesn't work, check that your `.env` file is in `~/.claude/.env` (NOT in the hooks subdirectory). This fixes 90% of TTS issues.