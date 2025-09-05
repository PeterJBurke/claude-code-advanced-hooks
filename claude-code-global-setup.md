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

### Step 1: Create Directory Structure

```bash
# Create the global Claude directory structure
mkdir -p ~/.claude/hooks/utils/{llm,tts}
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

# Create your environment file
cp .env.example .env
```

### Step 6: Configure Environment Variables

Edit `~/.claude/.env` (note: this file should be in the root .claude directory, not hooks):

```bash
# Move .env to the correct location
mv ~/.claude/hooks/.env ~/.claude/.env

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

### Step 7: Install StatusLine Dependencies

```bash
# Install ccusage globally for usage tracking
npm install -g ccusage

# Test statusline
npx -y ccusage statusline
```

## 🔧 Advanced Setup Options

### Automated Installation Script

Create your own installer script:

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

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p ~/.claude/hooks/utils/{llm,tts}

# Define base URL
REPO_URL="https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main"

# Download function
download_file() {
    local url="$1"
    local output="$2"
    echo "⬇️  Downloading $(basename "$output")..."
    curl -fsSL "$url" -o "$output"
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

# Set up environment
if [ ! -f ~/.claude/.env ]; then
    cp .env.example ~/.claude/.env
    echo "📝 Created ~/.claude/.env - please edit with your API keys"
fi

# Install ccusage
echo "📊 Installing ccusage for statusline..."
npm install -g ccusage

echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.claude/.env with your API keys"
echo "2. Test with: echo '{\"session_id\": \"test\"}' | uv run ~/.claude/hooks/session_start.py"
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

# Test TTS (requires API key)
uv run ~/.claude/hooks/utils/tts/elevenlabs_tts.py "Global installation test"

# Test statusline
npx -y ccusage statusline
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
```

## 🔧 Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   ```bash
   chmod +x ~/.claude/hooks/*.py
   find ~/.claude/hooks -name "*.py" -exec chmod +x {} \;
   ```

2. **Python Dependencies Not Installing**
   ```bash
   cd ~/.claude/hooks
   uv sync --reinstall
   ```

3. **API Keys Not Working**
   ```bash
   # Check environment file location
   ls -la ~/.claude/.env
   
   # Test loading
   cd ~/.claude/hooks
   uv run python -c "import os; from dotenv import load_dotenv; load_dotenv('../.env'); print('ANTHROPIC_API_KEY' in os.environ)"
   ```

4. **Hooks Not Executing**
   ```bash
   # Check settings file
   cat ~/.claude/settings.json | grep -A5 hooks
   
   # Test direct execution
   echo '{"session_id": "debug"}' | uv run ~/.claude/hooks/session_start.py
   ```

5. **Download Failures**
   ```bash
   # Test connectivity
   curl -I https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/.claude/settings.json
   
   # Use git clone as backup
   git clone https://github.com/PeterJBurke/claude-code-advanced-hooks.git /tmp/claude-hooks
   cp -r /tmp/claude-hooks/.claude ~/
   ```

### Path Updates Required

When using the global installation, all path references are automatically updated to:

| Component | Global Path |
|-----------|-------------|
| Settings | `~/.claude/settings.json` |
| Environment | `~/.claude/.env` |
| Hook Scripts | `~/.claude/hooks/*.py` |
| Utilities | `~/.claude/hooks/utils/` |
| Logs | `~/.claude/logs/` |

## 🎯 Features Enabled

With this global setup, you get across ALL your projects:

- ✅ **Comprehensive Logging**: All interactions logged to `~/.claude/logs/`
- ✅ **Safety Checks**: Dangerous commands blocked automatically  
- ✅ **TTS Notifications**: Audio feedback for all sessions
- ✅ **AI Summarization**: Intelligent event descriptions
- ✅ **Usage Tracking**: StatusLine integration
- ✅ **Browser Integration**: MCP server support
- ✅ **Global Consistency**: Same experience everywhere

## 📚 Resources

- **GitHub Repository**: https://github.com/PeterJBurke/claude-code-advanced-hooks
- **Project-Specific Setup**: See repository README.md
- **Claude Code Documentation**: https://docs.anthropic.com/en/docs/claude-code

## 🤝 Contributing

Found an issue or want to improve the installation process? 

1. Report bugs at https://github.com/PeterJBurke/claude-code-advanced-hooks/issues
2. Suggest improvements for this installation guide
3. Help create the automated installer script

---

**🎉 Ready to experience Claude Code with advanced hooks globally? Follow the installation steps above and enjoy enhanced AI interactions across all your projects!**