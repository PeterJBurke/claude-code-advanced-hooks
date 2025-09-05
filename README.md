# Claude Code Advanced Hook System

A comprehensive, production-ready hook system for Claude Code that provides intelligent monitoring, safety checks, AI-powered summaries, and multi-modal notifications.

## 🚀 Features

- **🛡️ Safety First**: Automatic detection and blocking of dangerous commands (like `rm -rf`)
- **🔊 Multi-Modal TTS**: Audio notifications via ElevenLabs, OpenAI, or offline pyttsx3
- **🤖 AI Summaries**: LLM-powered event summarization using Claude or GPT models
- **📊 Usage Tracking**: Integrated statusline with ccusage for API usage monitoring
- **🌐 Web Integration**: Browser MCP server for enhanced web interactions
- **📝 Comprehensive Logging**: Detailed session logs with structured JSON data
- **🔄 8 Hook Types**: Complete lifecycle coverage from session start to stop

## 📁 Project Structure

```
ClaudeHelloWorld/
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
└── README.md                      # This file
```

## 🛠️ Quick Start

### 1. Prerequisites

```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Node.js (for ccusage statusline)
brew install node  # macOS
# or download from nodejs.org
```

### 2. Clone and Setup

```bash
git clone https://github.com/yourusername/claude-code-hooks.git
cd claude-code-hooks

# Setup Python environment
cd .claude/hooks
uv sync

# Configure environment variables
cp .env.example .env
# Edit .env with your API keys (see Environment section)
```

### 3. API Keys Setup

Create `.claude/hooks/.env`:
```bash
# Required for AI features
ANTHROPIC_API_KEY=your-claude-api-key
OPENAI_API_KEY=your-openai-api-key

# Optional for premium TTS
ELEVENLABS_API_KEY=your-elevenlabs-key

# Personalization
ENGINEER_NAME=YourName
```

### 4. Test Installation

```bash
# Test hook execution
echo '{"session_id": "test"}' | uv run .claude/hooks/session_start.py --notify

# Test TTS (if configured)
uv run .claude/hooks/utils/tts/elevenlabs_tts.py "Hello World"

# Start Claude Code to activate hooks
claude
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

### AI Integration

- **Smart Summaries**: Context-aware event descriptions
- **Model Selection**: Optimized for speed (Claude Haiku, GPT-4 Mini)
- **Fallback System**: Graceful degradation without API keys
- **Cost Optimization**: Token-efficient prompting strategies

## 🌐 Global Installation

For system-wide installation across all projects, see [`claude-code-global-setup.md`](./claude-code-global-setup.md) - a comprehensive 400+ line guide covering:

- Global `~/.claude` configuration
- Path migration strategies  
- Dependencies management
- Testing procedures
- Troubleshooting guide

## 🎛️ Configuration

### Core Settings (`.claude/settings.json`)

```json
{
  "permissions": {
    "allow": [
      "Bash(find:*)", "Bash(python:*)", "Bash(git:*)",
      "Read(/Users/$USER/**)", "WebFetch(domain:ccusage.com)"
    ]
  },
  "hooks": {
    "SessionStart": [{"type": "command", "command": "uv run .claude/hooks/session_start.py --notify"}],
    "PreToolUse": [{"type": "command", "command": "uv run .claude/hooks/pre_tool_use.py"}]
  },
  "statusLine": {
    "type": "command",
    "command": "npx -y ccusage statusline"
  }
}
```

### Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `ANTHROPIC_API_KEY` | Claude API access | For AI summaries |
| `OPENAI_API_KEY` | GPT API access | Alternative AI |
| `ELEVENLABS_API_KEY` | Premium TTS | For best audio |
| `ENGINEER_NAME` | Personalization | Optional |
| `CLAUDE_HOOKS_LOG_DIR` | Custom log location | Optional |

## 🎵 Text-to-Speech System

### Provider Priority
1. **ElevenLabs** (Premium, natural voices)
2. **OpenAI TTS** (High quality, cost-effective)  
3. **pyttsx3** (Offline fallback)

### Voice Customization
```python
# Edit .claude/hooks/utils/tts/elevenlabs_tts.py
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

## 🧪 Development

### Adding New Hooks

1. Create hook script following uv format:
```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = ["python-dotenv"]
# ///
```

2. Add to `.claude/settings.json`
3. Test with sample JSON input

### Custom Utilities

Add modules to `utils/` directory:
- Follow consistent import patterns
- Include error handling
- Document dependencies in script headers

### Testing

```bash
# Test individual hooks
echo '{"session_id": "test"}' | uv run .claude/hooks/your_hook.py

# Test utilities
uv run .claude/hooks/utils/your_utility.py "test input"

# Integration test
claude  # Hooks activate automatically
```

## 🔍 Troubleshooting

### Common Issues

**Hooks not executing:**
```bash
# Check permissions
chmod +x .claude/hooks/*.py

# Verify uv installation
uv --version

# Test hook directly
uv run .claude/hooks/session_start.py
```

**TTS not working:**
```bash
# Check API key
cat .claude/hooks/.env | grep ELEVENLABS

# Test TTS directly  
uv run .claude/hooks/utils/tts/elevenlabs_tts.py "test"

# Check audio system
# macOS: System Preferences > Sound
# Linux: pulseaudio/alsa configuration
```

**Missing dependencies:**
```bash
cd .claude/hooks
uv sync  # Reinstall all dependencies
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Follow existing code patterns and documentation
4. Test thoroughly across hook types
5. Submit pull request with detailed description

### Code Standards
- Use uv script headers for dependencies
- Include comprehensive error handling
- Document environment variables
- Follow consistent logging patterns
- Test with and without API keys

## 📜 License

MIT License - feel free to use, modify, and distribute.

## 🙏 Acknowledgments

- **Claude Code Team** for the excellent hook system architecture
- **uv Team** for fast Python package management
- **ccusage** for API usage tracking capabilities
- **ElevenLabs** for premium TTS integration

---

**⚡ Ready to supercharge your Claude Code experience?** Follow the setup guide and enjoy intelligent, safe, and delightful AI interactions!

For questions, issues, or feature requests, please open a GitHub issue.