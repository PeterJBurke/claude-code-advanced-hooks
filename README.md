# Claude Code Advanced Hook System

A comprehensive, production-ready hook system for Claude Code that provides intelligent monitoring, safety checks, AI-powered summaries, and multi-modal notifications.

## 🚀 Features

- **🛡️ Safety First**: Automatic detection and blocking of dangerous commands (like `rm -rf`)
- **🔊 Context-Aware TTS**: Smart audio notifications that adapt to different scenarios:
  - 🚨 "Your input is needed" when Claude requires user decisions
  - ⚠️ "Error occurred, check Claude" for warnings and issues
  - ✅ "Task completed" for successful operations
- **🤖 AI Summaries**: LLM-powered event summarization using Claude or GPT models
- **📊 Usage Tracking**: Integrated statusline with ccusage for API usage monitoring
- **🌐 Web Integration**: Browser MCP server for enhanced web interactions
- **📝 Comprehensive Logging**: Detailed session logs with structured JSON data
- **🔄 8 Hook Types**: Complete lifecycle coverage from session start to stop

## 🏗️ Architecture Overview

This repository provides two deployment strategies:

1. **Project-Specific**: Hook system works only in this project directory
2. **Global Installation**: Hook system works across all Claude Code projects (recommended)

## 📁 Project Structure

```
claude-code-advanced-hooks/
├── .claude/
│   ├── settings.json              # Main Claude Code configuration
│   ├── settings.local.json        # Local permissions overrides  
│   ├── CLAUDE.md                  # Project-specific instructions
│   └── hooks/                     # Hook system directory
│       ├── pyproject.toml         # Python dependencies
│       ├── .python-version        # Python version spec
│       ├── .env.example          # Environment template
│       ├── session_start.py       # Session lifecycle hooks
│       ├── stop.py               
│       ├── pre_tool_use.py        # Safety and monitoring hooks
│       ├── post_tool_use.py
│       ├── notification.py        # Notification hooks
│       ├── subagent_stop.py
│       ├── pre_compact.py
│       ├── user_prompt_submit.py
│       └── utils/                 # Utility modules
│           ├── constants.py       # Configuration constants
│           ├── summarizer.py      # AI summarization
│           ├── llm/              # LLM integrations
│           │   ├── anth.py       # Anthropic Claude
│           │   └── oai.py        # OpenAI GPT
│           └── tts/              # Text-to-speech
│               ├── elevenlabs_tts.py
│               ├── openai_tts.py
│               └── pyttsx3_tts.py
├── logs/                          # Session logs (auto-generated)
├── claude-code-global-setup.md    # Global installation guide
├── install-global.sh             # Automated global installer
└── README.md                      # This file
```

**Important**: The environment file (`.env`) should be placed in the root `.claude/` directory, NOT in the `hooks/` subdirectory. This is critical for proper TTS functionality.

## 🛠️ Installation Options

### Option 1: Global Installation (Recommended)

#### Quick Setup
```bash
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/install-global.sh | bash
```

This installer is **smart** and preserves your existing Claude Code configuration:

✅ **Intelligent Merging**: Merges hook configuration with existing `settings.json`  
✅ **Automatic Backups**: Creates timestamped backups of all existing files  
✅ **Environment Handling**: Adds missing API keys to existing `.env` files  
✅ **Non-Destructive**: Never deletes existing configurations  
✅ **ccusage Integration**: Automatically installs and configures statusline

#### Manual Global Setup
For detailed manual installation, see the **[Global Setup Guide](./claude-code-global-setup.md)**.

### Option 2: Project-Specific Setup (For Testing)

#### 1. Prerequisites
```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Node.js (for statusline)
brew install node  # macOS
# or download from nodejs.org

# Install ccusage globally for statusline
npm install -g ccusage
```

#### 2. Clone and Setup
```bash
git clone https://github.com/PeterJBurke/claude-code-advanced-hooks.git
cd claude-code-advanced-hooks

# Setup Python environment
cd .claude/hooks
uv sync

# Configure environment variables (IMPORTANT: Place in parent directory)
cp .env.example ../.env  # Note: Move to .claude/.env, not hooks/.env
cd ..
nano .env  # Edit with your API keys
```

#### 3. Test the Installation
```bash
# Test hook execution
echo '{"session_id": "test"}' | uv run hooks/session_start.py --notify

# Test TTS (if configured)
uv run hooks/utils/tts/elevenlabs_tts.py "Hello World"

# Test statusline
npx -y ccusage statusline

# Start Claude Code to activate hooks
claude
```

## 🔑 API Keys Setup

**CRITICAL**: The `.env` file must be in `~/.claude/.env` (global) or `.claude/.env` (project), NOT in the hooks subdirectory.

Create the environment file:
```bash
# For global installation
nano ~/.claude/.env

# For project-specific installation  
nano .claude/.env
```

Add your API keys:
```bash
# Required for AI features
ANTHROPIC_API_KEY=your-claude-api-key
OPENAI_API_KEY=your-openai-api-key

# Optional for premium TTS
ELEVENLABS_API_KEY=your-elevenlabs-key

# Personalization
ENGINEER_NAME=YourName
```

## 🔧 Hook System Overview

### Core Hooks

| Hook | Purpose | Features |
|------|---------|----------|
| `SessionStart` | Session initialization | Welcome TTS, logging setup |
| `PreToolUse` | Pre-execution safety | Dangerous command blocking |
| `PostToolUse` | Post-execution processing | Success/failure TTS notifications |
| `UserPromptSubmit` | User interaction tracking | Prompt logging, context awareness |
| `Notification` | System notifications | AI summarization, audio alerts |
| `PreCompact` | Memory optimization | Pre-cleanup notifications |
| `SubagentStop` | Subagent lifecycle | Completion notifications |
| `Stop` | Session termination | Farewell TTS, session summary |

### Safety Features

- **Command Analysis**: Real-time scanning of bash commands
- **Pattern Detection**: Advanced regex matching for dangerous operations
- **Path Protection**: Safeguards for system directories (`/`, `/home`, `/usr`, etc.)
- **Recursive Deletion Prevention**: Blocks `rm -rf` variations
- **Override Protection**: Prevents `--force` flag combinations

## 🎛️ Configuration

### Core Settings (`.claude/settings.json`)

```json
{
  "permissions": {
    "allow": [
      "Bash(uv run:*)", "Bash(python3:*)", "Bash(git:*)",
      "Read(/home/$USER/**)", "WebFetch(domain:ccusage.com)",
      "Bash(npx -y ccusage:*)"
    ]
  },
  "hooks": {
    "SessionStart": [{"type": "command", "command": "uv run ~/.claude/hooks/session_start.py --notify"}],
    "PreToolUse": [{"type": "command", "command": "uv run ~/.claude/hooks/pre_tool_use.py"}],
    "PostToolUse": [{"type": "command", "command": "uv run ~/.claude/hooks/post_tool_use.py --notify"}],
    "Notification": [{"type": "command", "command": "uv run ~/.claude/hooks/notification.py --notify"}],
    "UserPromptSubmit": [{"type": "command", "command": "uv run ~/.claude/hooks/user_prompt_submit.py"}],
    "SubagentStop": [{"type": "command", "command": "uv run ~/.claude/hooks/subagent_stop.py --notify"}],
    "PreCompact": [{"type": "command", "command": "uv run ~/.claude/hooks/pre_compact.py --notify"}],
    "Stop": [{"type": "command", "command": "uv run ~/.claude/hooks/stop.py --notify"}]
  },
  "statusLine": {
    "type": "command",
    "command": "npx -y ccusage statusline"
  }
}
```

## 🎵 Text-to-Speech System

### Provider Priority
1. **ElevenLabs** (Premium, natural voices)
2. **OpenAI TTS** (High quality, cost-effective)  
3. **pyttsx3** (Offline fallback)

### Voice Customization
```python
# Edit ~/.claude/hooks/utils/tts/elevenlabs_tts.py
voice="Rachel"  # Change to preferred voice
model="eleven_multilingual_v2"  # Or eleven_turbo_v2 for speed
```

## 📊 Usage Monitoring

The statusline integration provides real-time insights:
- API usage across providers
- Cost tracking
- Request/response timing
- Error rate monitoring

Install with:
```bash
npm install -g ccusage
```

**Note**: You may see Node.js version warnings - these can be ignored as ccusage works with older versions.

## 🔍 Troubleshooting

### Common Issues

**1. TTS Not Working (Most Common)**

This usually indicates incorrect environment file location:

```bash
# Check if .env is in the correct location
ls -la ~/.claude/.env  # For global installation
ls -la .claude/.env    # For project installation

# If it's in hooks/.env, move it:
mv ~/.claude/hooks/.env ~/.claude/.env

# Test TTS directly
cd ~/.claude/hooks
uv run utils/tts/elevenlabs_tts.py "Test message"

# Enable debug mode
DEBUG_NOTIFICATIONS=1 echo '{"session_id": "test", "payload": {"message": "Test", "title": "Debug"}}' | uv run ~/.claude/hooks/notification.py --notify
```

**2. Multiple TTS Voices Playing**

This happens when hooks have inconsistent environment loading:

```bash
# Check all hooks load .env from correct path
grep -n "load_dotenv" ~/.claude/hooks/*.py

# Should show: load_dotenv(Path(__file__).parent / ".env")
# NOT: load_dotenv(Path(__file__).parent.parent.parent / ".env")
```

**3. StatusLine Not Working**

```bash
# Check ccusage installation
npm list -g ccusage

# Install if missing
npm install -g ccusage

# Test manually
echo '{"test": "data"}' | npx -y ccusage statusline

# Check settings.json has statusLine configuration
grep -A3 statusLine ~/.claude/settings.json
```

**4. Hooks Not Executing**

```bash
# Check permissions
chmod +x ~/.claude/hooks/*.py

# Verify uv installation
uv --version

# Test hook directly
echo '{"session_id": "test"}' | uv run ~/.claude/hooks/session_start.py
```

**5. Python Dependencies Missing**

```bash
cd ~/.claude/hooks
uv sync --reinstall

# Check environment
uv run python --version
```

**6. API Keys Not Loading**

```bash
# Verify .env location (common issue)
ls -la ~/.claude/.env  # Should exist here
ls -la ~/.claude/hooks/.env  # Should NOT exist here

# Test environment loading
cd ~/.claude/hooks
uv run python -c "import os; from dotenv import load_dotenv; load_dotenv('../.env'); print('ELEVENLABS_API_KEY' in os.environ)"
```

### Debug Mode

Enable comprehensive debugging:

```bash
# Test notification system with debug output
DEBUG_NOTIFICATIONS=1 echo '{"session_id": "test", "payload": {"message": "Debug test", "title": "Testing"}}' | uv run ~/.claude/hooks/notification.py --notify

# Check debug logs
tail -f ~/.claude/hooks/debug_*.txt
```

### Environment File Verification

The most critical issue is environment file location. Use this checklist:

- ✅ `.env` file is in `~/.claude/.env` (global) or `.claude/.env` (project)
- ❌ `.env` file is NOT in `~/.claude/hooks/.env`
- ✅ All hook scripts load from `Path(__file__).parent / ".env"`
- ✅ API keys are properly formatted in .env file
- ✅ ccusage is installed globally with npm

## 🧪 Development

### Testing New Hooks

```bash
# Test individual hooks with debug
DEBUG_NOTIFICATIONS=1 echo '{"session_id": "test"}' | uv run ~/.claude/hooks/your_hook.py --notify

# Verify environment loading
uv run ~/.claude/hooks/utils/tts/elevenlabs_tts.py "Environment test"

# Check logs
ls -la ~/.claude/logs/
```

## 📚 Repository Information

**GitHub Repository:** https://github.com/PeterJBurke/claude-code-advanced-hooks  
**Issues/Support:** https://github.com/PeterJBurke/claude-code-advanced-hooks/issues

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Follow existing code patterns and documentation
4. Test thoroughly (especially TTS and environment loading)
5. Submit pull request with detailed description

### Testing Checklist for Contributors

- ✅ `.env` file loads from correct location
- ✅ TTS works with ElevenLabs (not pyttsx3 fallback)
- ✅ StatusLine displays usage information
- ✅ Hooks execute without errors
- ✅ API keys are properly loaded
- ✅ No multiple TTS systems playing simultaneously

## 📜 License

MIT License - feel free to use, modify, and distribute.

## 🙏 Acknowledgments

- **Claude Code Team** for the excellent hook system architecture
- **uv Team** for fast Python package management
- **ccusage** for API usage tracking capabilities
- **ElevenLabs** for premium TTS integration

---

**⚡ Ready to supercharge your Claude Code experience?** Use the global installer for the most robust setup:

```bash
curl -fsSL https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main/install-global.sh | bash
```

For questions, issues, or if TTS isn't working, check the troubleshooting section or open a GitHub issue.