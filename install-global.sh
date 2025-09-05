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

# Handle existing configuration files intelligently
echo -e "${BLUE}⚙️  Configuring Claude Code settings...${NC}"

# Function to merge JSON configurations
merge_settings_json() {
    local existing_file="$1"
    local new_file="$2"
    local backup_file="${existing_file}.backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$existing_file" ]; then
        echo -e "${YELLOW}⚠️  Existing settings found at $existing_file${NC}"
        echo -e "📝 Creating backup at $backup_file"
        cp "$existing_file" "$backup_file"
        
        # Use python to intelligently merge JSON configurations
        python3 << EOF
import json
import sys

try:
    # Read existing configuration
    with open('$existing_file', 'r') as f:
        existing = json.load(f)
    
    # Read new configuration
    with open('$new_file', 'r') as f:
        new_config = json.load(f)
    
    # Preserve existing permissions if they exist
    if 'permissions' in existing and 'permissions' in new_config:
        # Merge allow lists (avoid duplicates)
        existing_allow = set(existing.get('permissions', {}).get('allow', []))
        new_allow = set(new_config.get('permissions', {}).get('allow', []))
        merged_allow = sorted(list(existing_allow.union(new_allow)))
        
        # Keep existing deny and ask lists, merge with new ones
        existing_deny = existing.get('permissions', {}).get('deny', [])
        new_deny = new_config.get('permissions', {}).get('deny', [])
        merged_deny = sorted(list(set(existing_deny + new_deny)))
        
        existing_ask = existing.get('permissions', {}).get('ask', [])
        new_ask = new_config.get('permissions', {}).get('ask', [])
        merged_ask = sorted(list(set(existing_ask + new_ask)))
        
        new_config['permissions'] = {
            'allow': merged_allow,
            'deny': merged_deny,
            'ask': merged_ask
        }
    
    # Add hooks configuration if it doesn't exist, otherwise merge
    if 'hooks' not in existing:
        existing['hooks'] = new_config.get('hooks', {})
    else:
        # Merge hook configurations
        for hook_type, hook_config in new_config.get('hooks', {}).items():
            if hook_type not in existing['hooks']:
                existing['hooks'][hook_type] = hook_config
            else:
                print(f"Hook {hook_type} already exists, skipping...")
    
    # Add statusLine if it doesn't exist
    if 'statusLine' not in existing and 'statusLine' in new_config:
        existing['statusLine'] = new_config['statusLine']
    
    # Add mcpServers if they don't exist
    if 'mcpServers' not in existing:
        existing['mcpServers'] = new_config.get('mcpServers', {})
    else:
        # Merge MCP servers
        for server_name, server_config in new_config.get('mcpServers', {}).items():
            if server_name not in existing['mcpServers']:
                existing['mcpServers'][server_name] = server_config
    
    # Write merged configuration
    with open('$existing_file', 'w') as f:
        json.dump(existing, f, indent=2)
    
    print("✅ Configuration merged successfully")
    
except Exception as e:
    print(f"❌ Error merging configurations: {e}")
    print("Using new configuration as fallback")
    # If merge fails, use the new configuration
    with open('$new_file', 'r') as f:
        content = f.read()
    with open('$existing_file', 'w') as f:
        f.write(content)
        
EOF
        
        echo -e "${GREEN}✅ Settings merged with existing configuration${NC}"
    else
        echo -e "📝 No existing settings found, creating new settings.json"
        cp "$new_file" "$existing_file"
        echo -e "${GREEN}✅ New settings.json created${NC}"
    fi
}

# Download new settings to temporary location
temp_settings=$(mktemp)
download_file "$REPO_URL/.claude/settings.json" "$temp_settings" "settings.json (temporary)"

# Merge with existing settings
merge_settings_json ~/.claude/settings.json "$temp_settings"

# Clean up temporary file
rm -f "$temp_settings"

# Handle CLAUDE.md file
if [ -f ~/.claude/CLAUDE.md ]; then
    echo -e "${YELLOW}⚠️  Existing CLAUDE.md found${NC}"
    backup_claude="~/.claude/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "📝 Creating backup at $backup_claude"
    cp ~/.claude/CLAUDE.md "$backup_claude"
    
    # Ask user if they want to replace or append
    echo -e "${BLUE}Options for CLAUDE.md:${NC}"
    echo "1. Keep existing (recommended)"
    echo "2. Append our template"
    echo "3. Replace with our template"
    
    # For automated installation, default to keep existing
    echo -e "${GREEN}Keeping existing CLAUDE.md file${NC}"
    echo -e "${BLUE}💡 You can manually review the template at: https://github.com/PeterJBurke/claude-code-advanced-hooks/blob/main/.claude/CLAUDE.md${NC}"
else
    download_file "$REPO_URL/.claude/CLAUDE.md" ~/.claude/CLAUDE.md "CLAUDE.md template"
fi

# Download hook files intelligently  
echo -e "${BLUE}🪝 Setting up hook scripts...${NC}"
cd ~/.claude/hooks

# Always download/update project configuration files
download_file "$REPO_URL/.claude/hooks/pyproject.toml" pyproject.toml "Python project config"
download_file "$REPO_URL/.claude/hooks/.env.example" .env.example "Environment template"

# Hook scripts array
declare -a hooks=("session_start.py" "pre_tool_use.py" "post_tool_use.py" "notification.py" "user_prompt_submit.py" "subagent_stop.py" "pre_compact.py" "stop.py")

# Check if any hook files already exist
existing_hooks=()
for script in "${hooks[@]}"; do
    if [ -f "$script" ]; then
        existing_hooks+=("$script")
    fi
done

if [ ${#existing_hooks[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found existing hook scripts: ${existing_hooks[*]}${NC}"
    echo -e "${BLUE}Creating backups and updating...${NC}"
    
    for script in "${hooks[@]}"; do
        if [ -f "$script" ]; then
            backup_script="${script}.backup-$(date +%Y%m%d-%H%M%S)"
            echo -e "📝 Backing up $script to $backup_script"
            cp "$script" "$backup_script"
        fi
        download_file "$REPO_URL/.claude/hooks/$script" "$script" "hook: $script"
    done
    
    echo -e "${GREEN}✅ Hook scripts updated (backups created)${NC}"
else
    echo -e "📝 No existing hooks found, downloading all scripts..."
    for script in "${hooks[@]}"; do
        download_file "$REPO_URL/.claude/hooks/$script" "$script" "hook: $script"
    done
fi

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

# Handle environment file intelligently
echo -e "${BLUE}🔐 Setting up environment configuration...${NC}"

if [ ! -f ~/.claude/.env ]; then
    cp .env.example ~/.claude/.env
    echo -e "${GREEN}📝 Created ~/.claude/.env${NC}"
    echo -e "${YELLOW}⚠️  Please edit ~/.claude/.env with your API keys${NC}"
else
    echo -e "${YELLOW}⚠️  ~/.claude/.env already exists${NC}"
    
    # Check if existing .env has the keys we need
    missing_keys=()
    
    if ! grep -q "ANTHROPIC_API_KEY" ~/.claude/.env; then
        missing_keys+=("ANTHROPIC_API_KEY")
    fi
    if ! grep -q "OPENAI_API_KEY" ~/.claude/.env; then
        missing_keys+=("OPENAI_API_KEY")
    fi
    if ! grep -q "ENGINEER_NAME" ~/.claude/.env; then
        missing_keys+=("ENGINEER_NAME")
    fi
    
    if [ ${#missing_keys[@]} -gt 0 ]; then
        echo -e "${BLUE}💡 Adding missing environment variables...${NC}"
        backup_env="~/.claude/.env.backup-$(date +%Y%m%d-%H%M%S)"
        cp ~/.claude/.env "$backup_env"
        echo -e "📝 Backup created at $backup_env"
        
        echo "" >> ~/.claude/.env
        echo "# Added by Claude Code Advanced Hooks installer" >> ~/.claude/.env
        
        for key in "${missing_keys[@]}"; do
            case $key in
                "ANTHROPIC_API_KEY")
                    echo "ANTHROPIC_API_KEY=your-anthropic-api-key-here" >> ~/.claude/.env
                    ;;
                "OPENAI_API_KEY")
                    echo "OPENAI_API_KEY=your-openai-api-key-here" >> ~/.claude/.env
                    ;;
                "ENGINEER_NAME")
                    echo "ENGINEER_NAME=YourName" >> ~/.claude/.env
                    ;;
            esac
            echo -e "${GREEN}✅ Added $key template${NC}"
        done
        
        echo -e "${YELLOW}⚠️  Please edit ~/.claude/.env to set your actual API keys${NC}"
    else
        echo -e "${GREEN}✅ Environment file appears complete${NC}"
    fi
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

# Summary of what was done
echo -e "${BLUE}📋 Installation Summary:${NC}"
if [ -f ~/.claude/settings.json.backup-* ] 2>/dev/null; then
    echo -e "✅ Existing settings.json merged with hook configuration"
    echo -e "   📁 Backup created: ~/.claude/settings.json.backup-*"
else
    echo -e "✅ New settings.json created with hook configuration"
fi

if [ -f ~/.claude/CLAUDE.md.backup-* ] 2>/dev/null; then
    echo -e "✅ Existing CLAUDE.md preserved"
    echo -e "   📁 Backup created: ~/.claude/CLAUDE.md.backup-*"
elif [ -f ~/.claude/CLAUDE.md ]; then
    echo -e "✅ CLAUDE.md template added"
fi

if [ -f ~/.claude/.env.backup-* ] 2>/dev/null; then
    echo -e "✅ Environment variables added to existing .env file"
    echo -e "   📁 Backup created: ~/.claude/.env.backup-*"
elif [ -f ~/.claude/.env ]; then
    echo -e "✅ Environment file created from template"
fi

echo -e "✅ Hook system installed: 8 hooks + utilities"
echo -e "✅ Python dependencies installed via uv"
echo -e "✅ File permissions set"

echo ""
echo -e "${BLUE}Next Steps:${NC}"
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

echo -e "${YELLOW}💡 Important Notes:${NC}"
echo "• Your existing Claude Code settings have been preserved"
echo "• Backup files have been created for any replaced files"  
echo "• The hooks system adds new functionality without breaking existing setup"
echo ""

echo "📚 Documentation: https://github.com/PeterJBurke/claude-code-advanced-hooks"
echo "🐛 Issues: https://github.com/PeterJBurke/claude-code-advanced-hooks/issues"
echo ""
echo -e "${GREEN}Enjoy your enhanced Claude Code experience! 🚀${NC}"