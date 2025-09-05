#!/bin/bash
set -e

# Claude Code Advanced Hooks - Global Installer
# This script downloads and installs the hook system globally in ~/.claude

echo "🚀 Installing Claude Code Advanced Hooks globally..."
echo "Repository: https://github.com/PeterJBurke/claude-code-advanced-hooks"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl not found. Please install curl first.${NC}"
    exit 1
fi

if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}⚠️  uv not found. Installing...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Try to source common shell configs
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    elif [ -f ~/.zshrc ]; then
        source ~/.zshrc
    fi
    
    # Check again
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}⚠️  Please restart your shell or run: source ~/.bashrc${NC}"
        echo -e "Then run this installer again."
        exit 1
    fi
fi

if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. This is optional but recommended for statusline.${NC}"
    echo -e "Install with: brew install node (macOS) or sudo apt install nodejs npm (Ubuntu)"
    echo ""
fi

# Create directory structure
echo -e "${BLUE}📁 Creating directory structure...${NC}"
mkdir -p ~/.claude/hooks/utils/{llm,tts}
mkdir -p ~/.claude/logs

# Define base URL
REPO_URL="https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main"

# Download function with error handling
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-$(basename "$output")}"
    
    echo -e "⬇️  Downloading ${description}..."
    
    if curl -fsSL "$url" -o "$output"; then
        echo -e "${GREEN}✅ Downloaded ${description}${NC}"
    else
        echo -e "${RED}❌ Failed to download ${description}${NC}"
        echo -e "URL: $url"
        return 1
    fi
}

# Download configuration files
echo -e "${BLUE}⚙️  Downloading configuration files...${NC}"
download_file "$REPO_URL/.claude/settings.json" ~/.claude/settings.json "settings.json"
download_file "$REPO_URL/.claude/CLAUDE.md" ~/.claude/CLAUDE.md "CLAUDE.md template"

# Download hook files
echo -e "${BLUE}🪝 Downloading hook scripts...${NC}"
cd ~/.claude/hooks

download_file "$REPO_URL/.claude/hooks/pyproject.toml" pyproject.toml "Python project config"
download_file "$REPO_URL/.claude/hooks/.env.example" .env.example "Environment template"

# Hook scripts array
declare -a hooks=("session_start.py" "pre_tool_use.py" "post_tool_use.py" "notification.py" "user_prompt_submit.py" "subagent_stop.py" "pre_compact.py" "stop.py")

for script in "${hooks[@]}"; do
    download_file "$REPO_URL/.claude/hooks/$script" "$script" "hook: $script"
done

# Download utilities
echo -e "${BLUE}🛠️  Downloading utility modules...${NC}"
download_file "$REPO_URL/.claude/hooks/utils/constants.py" utils/constants.py "constants.py"
download_file "$REPO_URL/.claude/hooks/utils/summarizer.py" utils/summarizer.py "summarizer.py"

# Download LLM modules
echo -e "${BLUE}🤖 Downloading AI integrations...${NC}"
download_file "$REPO_URL/.claude/hooks/utils/llm/anth.py" utils/llm/anth.py "Anthropic integration"
download_file "$REPO_URL/.claude/hooks/utils/llm/oai.py" utils/llm/oai.py "OpenAI integration"

# Download TTS modules
echo -e "${BLUE}🔊 Downloading TTS modules...${NC}"
download_file "$REPO_URL/.claude/hooks/utils/tts/elevenlabs_tts.py" utils/tts/elevenlabs_tts.py "ElevenLabs TTS"
download_file "$REPO_URL/.claude/hooks/utils/tts/openai_tts.py" utils/tts/openai_tts.py "OpenAI TTS"
download_file "$REPO_URL/.claude/hooks/utils/tts/pyttsx3_tts.py" utils/tts/pyttsx3_tts.py "pyttsx3 TTS"

# Make scripts executable
echo -e "${BLUE}🔐 Setting permissions...${NC}"
chmod +x *.py utils/**/*.py

# Install Python dependencies
echo -e "${BLUE}🐍 Installing Python dependencies...${NC}"
if uv sync; then
    echo -e "${GREEN}✅ Python dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install Python dependencies${NC}"
    echo -e "Try running: cd ~/.claude/hooks && uv sync"
fi

# Set up environment file
if [ ! -f ~/.claude/.env ]; then
    cp .env.example ~/.claude/.env
    echo -e "${GREEN}📝 Created ~/.claude/.env${NC}"
    echo -e "${YELLOW}⚠️  Please edit ~/.claude/.env with your API keys${NC}"
else
    echo -e "${YELLOW}⚠️  ~/.claude/.env already exists, skipping...${NC}"
fi

# Install ccusage if node is available
if command -v npm &> /dev/null; then
    echo -e "${BLUE}📊 Installing ccusage for statusline...${NC}"
    if npm install -g ccusage; then
        echo -e "${GREEN}✅ ccusage installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to install ccusage (non-critical)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping ccusage installation (Node.js not found)${NC}"
fi

# Final verification
echo -e "${BLUE}🔍 Verifying installation...${NC}"

# Check key files exist
if [ -f ~/.claude/settings.json ] && [ -f ~/.claude/hooks/session_start.py ]; then
    echo -e "${GREEN}✅ Core files installed successfully${NC}"
else
    echo -e "${RED}❌ Some core files are missing${NC}"
    exit 1
fi

# Test basic functionality
if cd ~/.claude/hooks && echo '{"session_id": "installer-test"}' | uv run session_start.py > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Basic hook execution works${NC}"
else
    echo -e "${YELLOW}⚠️  Hook execution test failed (may need API keys)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo ""
echo "Next steps:"
echo -e "${BLUE}1.${NC} Edit ~/.claude/.env with your API keys:"
echo "   - ANTHROPIC_API_KEY=your-key-here"
echo "   - OPENAI_API_KEY=your-key-here" 
echo "   - ELEVENLABS_API_KEY=your-key-here (optional)"
echo "   - ENGINEER_NAME=YourName"
echo ""
echo -e "${BLUE}2.${NC} Test the installation:"
echo "   echo '{\"session_id\": \"test\"}' | uv run ~/.claude/hooks/session_start.py --notify"
echo ""
echo -e "${BLUE}3.${NC} Start Claude Code in any project - hooks will activate automatically!"
echo "   claude"
echo ""
echo "📚 Documentation: https://github.com/PeterJBurke/claude-code-advanced-hooks"
echo "🐛 Issues: https://github.com/PeterJBurke/claude-code-advanced-hooks/issues"
echo ""
echo -e "${GREEN}Enjoy your enhanced Claude Code experience! 🚀${NC}"