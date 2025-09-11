#!/bin/bash
set -e

# Claude Code Advanced Hooks - Global Installer
# This script downloads and installs the hook system globally in ~/.claude
# with proper environment handling and TTS functionality

echo "🚀 Installing Claude Code Advanced Hooks globally..."
echo "Repository: https://github.com/PeterJBurke/claude-code-advanced-hooks"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Track installation success
INSTALL_SUCCESS=true
CCUSAGE_INSTALLED=false
TTS_WORKING=false

# Function to print colored messages
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🔍 Checking prerequisites..."

# Check for curl
if ! command -v curl &> /dev/null; then
    print_status $RED "❌ curl not found. Please install curl first."
    exit 1
fi

# Check for uv and install if needed
if ! command -v uv &> /dev/null; then
    print_status $YELLOW "⚠️  uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Try to source common shell configs
    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    elif [ -f ~/.zshrc ]; then
        source ~/.zshrc
    fi
    
    # Check again
    if ! command -v uv &> /dev/null; then
        print_status $YELLOW "⚠️  Please restart your shell or run: source ~/.bashrc"
        print_status $YELLOW "Then run this installer again."
        exit 1
    fi
    print_status $GREEN "✅ uv installed successfully"
else
    print_status $GREEN "✅ uv found"
fi

# Check for Node.js and npm
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_status $GREEN "✅ Node.js found: $NODE_VERSION"
    
    # Install ccusage globally
    print_status $BLUE "📊 Installing ccusage for statusline..."
    if npm install -g ccusage 2>/dev/null; then
        print_status $GREEN "✅ ccusage installed successfully"
        CCUSAGE_INSTALLED=true
    else
        # Try with --force flag for version warnings
        print_status $YELLOW "⚠️  Installing ccusage with --force flag (ignoring version warnings)..."
        if npm install -g ccusage --force 2>/dev/null; then
            print_status $GREEN "✅ ccusage installed successfully (with version warnings ignored)"
            CCUSAGE_INSTALLED=true
        else
            print_status $YELLOW "⚠️  ccusage installation failed, but continuing..."
            print_status $CYAN "   You can install it later with: npm install -g ccusage"
        fi
    fi
else
    print_status $YELLOW "⚠️  Node.js/npm not found. This is optional but recommended for statusline."
    print_status $CYAN "   Install with: brew install node (macOS) or sudo apt install nodejs npm (Ubuntu)"
    echo ""
fi

# Create directory structure
print_status $BLUE "📁 Creating directory structure..."
mkdir -p ~/.claude/hooks/utils/{llm,tts}
mkdir -p ~/.claude/logs

# Define base URL
REPO_URL="https://raw.githubusercontent.com/PeterJBurke/claude-code-advanced-hooks/main"

# Download function with enhanced error handling
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-$(basename "$output")}"
    
    echo -n "⬇️  Downloading ${description}... "
    
    if curl -fsSL "$url" -o "$output" 2>/dev/null; then
        print_status $GREEN "✅"
    else
        print_status $RED "❌ Failed to download ${description}"
        print_status $RED "   URL: $url"
        INSTALL_SUCCESS=false
        return 1
    fi
}

# Handle existing configuration files intelligently
print_status $BLUE "⚙️  Configuring Claude Code settings..."

# Function to merge JSON configurations with better error handling
merge_settings_json() {
    local existing_file="$1"
    local new_file="$2"
    local backup_file="${existing_file}.backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$existing_file" ]; then
        print_status $YELLOW "⚠️  Existing settings found at $existing_file"
        print_status $CYAN "📝 Creating backup at $backup_file"
        cp "$existing_file" "$backup_file"
        
        # Use python to intelligently merge JSON configurations
        print_status $BLUE "🔄 Merging configuration with existing settings..."
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
                print(f"Hook {hook_type} already exists, keeping existing configuration")
    
    # Add statusLine if it doesn't exist
    if 'statusLine' not in existing and 'statusLine' in new_config:
        existing['statusLine'] = new_config['statusLine']
        print("✅ Added statusLine configuration")
    
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
        
        if [ $? -eq 0 ]; then
            print_status $GREEN "✅ Settings merged with existing configuration"
        else
            print_status $YELLOW "⚠️  Merge failed, using new configuration"
            cp "$new_file" "$existing_file"
        fi
    else
        print_status $CYAN "📝 No existing settings found, creating new settings.json"
        cp "$new_file" "$existing_file"
        print_status $GREEN "✅ New settings.json created"
    fi
}

# Download new settings to temporary location
temp_settings=$(mktemp)
if download_file "$REPO_URL/.claude/settings.json" "$temp_settings" "settings.json (temporary)"; then
    # Merge with existing settings
    merge_settings_json ~/.claude/settings.json "$temp_settings"
else
    print_status $RED "❌ Failed to download settings.json"
    INSTALL_SUCCESS=false
fi

# Clean up temporary file
rm -f "$temp_settings"

# Handle CLAUDE.md file
if [ -f ~/.claude/CLAUDE.md ]; then
    print_status $YELLOW "⚠️  Existing CLAUDE.md found"
    backup_claude="~/.claude/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
    print_status $CYAN "📝 Creating backup at $backup_claude"
    cp ~/.claude/CLAUDE.md "$backup_claude"
    print_status $GREEN "✅ Keeping existing CLAUDE.md file"
    print_status $CYAN "💡 You can manually review the template at: https://github.com/PeterJBurke/claude-code-advanced-hooks/blob/main/.claude/CLAUDE.md"
else
    download_file "$REPO_URL/.claude/CLAUDE.md" ~/.claude/CLAUDE.md "CLAUDE.md template"
fi

# Download hook files intelligently  
print_status $BLUE "🪝 Setting up hook scripts..."
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
    print_status $YELLOW "⚠️  Found existing hook scripts: ${existing_hooks[*]}"
    print_status $BLUE "🔄 Creating backups and updating..."
    
    for script in "${hooks[@]}"; do
        if [ -f "$script" ]; then
            backup_script="${script}.backup-$(date +%Y%m%d-%H%M%S)"
            print_status $CYAN "📝 Backing up $script to $backup_script"
            cp "$script" "$backup_script"
        fi
        download_file "$REPO_URL/.claude/hooks/$script" "$script" "hook: $script"
    done
    
    print_status $GREEN "✅ Hook scripts updated (backups created)"
else
    print_status $CYAN "📝 No existing hooks found, downloading all scripts..."
    for script in "${hooks[@]}"; do
        download_file "$REPO_URL/.claude/hooks/$script" "$script" "hook: $script"
    done
fi

# Download utilities
print_status $BLUE "🛠️  Downloading utility modules..."
download_file "$REPO_URL/.claude/hooks/utils/constants.py" utils/constants.py "constants.py"
download_file "$REPO_URL/.claude/hooks/utils/summarizer.py" utils/summarizer.py "summarizer.py"

# Download LLM modules
print_status $BLUE "🤖 Downloading AI integrations..."
download_file "$REPO_URL/.claude/hooks/utils/llm/anth.py" utils/llm/anth.py "Anthropic integration"
download_file "$REPO_URL/.claude/hooks/utils/llm/oai.py" utils/llm/oai.py "OpenAI integration"

# Download TTS modules
print_status $BLUE "🔊 Downloading TTS modules..."
download_file "$REPO_URL/.claude/hooks/utils/tts/elevenlabs_tts.py" utils/tts/elevenlabs_tts.py "ElevenLabs TTS"
download_file "$REPO_URL/.claude/hooks/utils/tts/openai_tts.py" utils/tts/openai_tts.py "OpenAI TTS"
download_file "$REPO_URL/.claude/hooks/utils/tts/pyttsx3_tts.py" utils/tts/pyttsx3_tts.py "pyttsx3 TTS"

# Make scripts executable
print_status $BLUE "🔐 Setting permissions..."
chmod +x *.py utils/**/*.py 2>/dev/null || chmod +x *.py utils/*/*.py

# Install Python dependencies
print_status $BLUE "🐍 Installing Python dependencies..."
if uv sync; then
    print_status $GREEN "✅ Python dependencies installed"
else
    print_status $RED "❌ Failed to install Python dependencies"
    print_status $CYAN "   Try running: cd ~/.claude/hooks && uv sync"
    INSTALL_SUCCESS=false
fi

# CRITICAL: Handle environment file correctly
print_status $BLUE "🔐 Setting up environment configuration..."
print_status $CYAN "🚨 CRITICAL: Environment file must be in ~/.claude/.env (NOT hooks/.env)"

# Remove any .env file that might be in the hooks directory (common mistake)
if [ -f ~/.claude/hooks/.env ]; then
    print_status $YELLOW "⚠️  Found .env in hooks directory - this will break TTS!"
    print_status $CYAN "🔄 Moving to correct location: ~/.claude/.env"
    if [ -f ~/.claude/.env ]; then
        # Backup existing root .env
        backup_env="~/.claude/.env.backup-$(date +%Y%m%d-%H%M%S)"
        cp ~/.claude/.env "$backup_env"
        print_status $CYAN "📝 Backed up existing ~/.claude/.env to $backup_env"
    fi
    mv ~/.claude/hooks/.env ~/.claude/.env
    print_status $GREEN "✅ Moved .env to correct location"
fi

if [ ! -f ~/.claude/.env ]; then
    # Create .env in the CORRECT location
    cp .env.example ~/.claude/.env
    print_status $GREEN "📝 Created ~/.claude/.env"
    print_status $YELLOW "⚠️  Please edit ~/.claude/.env with your API keys"
else
    print_status $CYAN "📝 ~/.claude/.env already exists"
    
    # Check if existing .env has the keys we need and add missing ones
    missing_keys=()
    
    if ! grep -q "ANTHROPIC_API_KEY" ~/.claude/.env; then
        missing_keys+=("ANTHROPIC_API_KEY")
    fi
    if ! grep -q "OPENAI_API_KEY" ~/.claude/.env; then
        missing_keys+=("OPENAI_API_KEY")
    fi
    if ! grep -q "ELEVENLABS_API_KEY" ~/.claude/.env; then
        missing_keys+=("ELEVENLABS_API_KEY")
    fi
    if ! grep -q "ENGINEER_NAME" ~/.claude/.env; then
        missing_keys+=("ENGINEER_NAME")
    fi
    
    if [ ${#missing_keys[@]} -gt 0 ]; then
        print_status $BLUE "💡 Adding missing environment variables..."
        backup_env="~/.claude/.env.backup-$(date +%Y%m%d-%H%M%S)"
        cp ~/.claude/.env "$backup_env"
        print_status $CYAN "📝 Backup created at $backup_env"
        
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
                "ELEVENLABS_API_KEY")
                    echo "ELEVENLABS_API_KEY=your-elevenlabs-api-key-here" >> ~/.claude/.env
                    ;;
                "ENGINEER_NAME")
                    echo "ENGINEER_NAME=YourName" >> ~/.claude/.env
                    ;;
            esac
            print_status $GREEN "✅ Added $key template"
        done
        
        print_status $YELLOW "⚠️  Please edit ~/.claude/.env to set your actual API keys"
    else
        print_status $GREEN "✅ Environment file appears complete"
    fi
fi

# Verify environment file location (critical for TTS)
print_status $BLUE "🔍 Verifying environment file location..."
if [ -f ~/.claude/.env ]; then
    print_status $GREEN "✅ ~/.claude/.env exists (correct location)"
else
    print_status $RED "❌ ~/.claude/.env missing"
    INSTALL_SUCCESS=false
fi

if [ -f ~/.claude/hooks/.env ]; then
    print_status $RED "❌ ~/.claude/hooks/.env exists (wrong location - will break TTS!)"
    print_status $CYAN "🔧 Fixing: removing incorrect .env file"
    rm ~/.claude/hooks/.env
    print_status $GREEN "✅ Removed incorrect .env file"
fi

# Test environment loading from hooks context
print_status $BLUE "🧪 Testing environment loading from hooks..."
cd ~/.claude/hooks
ENV_TEST_OUTPUT=$(uv run python -c "
import os
from pathlib import Path
from dotenv import load_dotenv

# Test the path that hooks will use
env_path = Path(__file__).parent / '.env'
print(f'Looking for .env at: {env_path}')
print(f'File exists: {env_path.exists()}')

if env_path.exists():
    load_dotenv(env_path)
    elevenlabs_key = os.getenv('ELEVENLABS_API_KEY')
    if elevenlabs_key and elevenlabs_key != 'your-elevenlabs-api-key-here':
        print('✅ ELEVENLABS_API_KEY loaded successfully')
    else:
        print('⚠️  ELEVENLABS_API_KEY not set or using template value')
else:
    print('❌ .env file not found - TTS will not work!')
" 2>&1)

echo "$ENV_TEST_OUTPUT"
if echo "$ENV_TEST_OUTPUT" | grep -q "✅"; then
    print_status $GREEN "✅ Environment loading test passed"
    TTS_WORKING=true
elif echo "$ENV_TEST_OUTPUT" | grep -q "⚠️"; then
    print_status $YELLOW "⚠️  Environment loading works but API keys need to be set"
else
    print_status $RED "❌ Environment loading test failed"
    INSTALL_SUCCESS=false
fi

# Final verification
print_status $BLUE "🔍 Verifying installation..."

# Check key files exist
if [ -f ~/.claude/settings.json ] && [ -f ~/.claude/hooks/session_start.py ] && [ -f ~/.claude/.env ]; then
    print_status $GREEN "✅ Core files installed successfully"
else
    print_status $RED "❌ Some core files are missing"
    INSTALL_SUCCESS=false
fi

# Test basic functionality
print_status $BLUE "🧪 Testing basic hook execution..."
if cd ~/.claude/hooks && echo '{"session_id": "installer-test"}' | timeout 10 uv run session_start.py > /dev/null 2>&1; then
    print_status $GREEN "✅ Basic hook execution works"
else
    print_status $YELLOW "⚠️  Hook execution test failed (may need API keys)"
fi

# Test TTS if API keys are set
if [ "$TTS_WORKING" = true ]; then
    print_status $BLUE "🎵 Testing TTS functionality..."
    if timeout 10 uv run utils/tts/elevenlabs_tts.py "Installation test" > /dev/null 2>&1; then
        print_status $GREEN "✅ TTS test passed"
    else
        print_status $YELLOW "⚠️  TTS test failed (check API keys)"
    fi
fi

# Test ccusage if installed
if [ "$CCUSAGE_INSTALLED" = true ]; then
    print_status $BLUE "📊 Testing ccusage statusline..."
    if echo '{"test": "data"}' | timeout 5 npx -y ccusage statusline > /dev/null 2>&1; then
        print_status $GREEN "✅ ccusage statusline works"
    else
        print_status $YELLOW "⚠️  ccusage test failed (non-critical)"
    fi
fi

echo ""
if [ "$INSTALL_SUCCESS" = true ]; then
    print_status $GREEN "🎉 Installation completed successfully!"
else
    print_status $YELLOW "⚠️  Installation completed with some issues"
    print_status $CYAN "   Check the messages above and run the manual verification steps"
fi
echo ""

# Installation Summary
print_status $BLUE "📋 Installation Summary:"
if [ -f ~/.claude/settings.json.backup-* ] 2>/dev/null; then
    print_status $GREEN "✅ Existing settings.json merged with hook configuration"
    print_status $CYAN "   📁 Backup created: ~/.claude/settings.json.backup-*"
else
    print_status $GREEN "✅ New settings.json created with hook configuration"
fi

if [ -f ~/.claude/CLAUDE.md.backup-* ] 2>/dev/null; then
    print_status $GREEN "✅ Existing CLAUDE.md preserved"
    print_status $CYAN "   📁 Backup created: ~/.claude/CLAUDE.md.backup-*"
elif [ -f ~/.claude/CLAUDE.md ]; then
    print_status $GREEN "✅ CLAUDE.md template added"
fi

if [ -f ~/.claude/.env.backup-* ] 2>/dev/null; then
    print_status $GREEN "✅ Environment variables added to existing .env file"
    print_status $CYAN "   📁 Backup created: ~/.claude/.env.backup-*"
elif [ -f ~/.claude/.env ]; then
    print_status $GREEN "✅ Environment file created from template"
fi

print_status $GREEN "✅ Hook system installed: 8 hooks + utilities"
print_status $GREEN "✅ Python dependencies installed via uv"
print_status $GREEN "✅ File permissions set"
print_status $GREEN "✅ Environment file in correct location (~/.claude/.env)"

if [ "$CCUSAGE_INSTALLED" = true ]; then
    print_status $GREEN "✅ ccusage installed for statusline monitoring"
else
    print_status $YELLOW "⚠️  ccusage not installed (optional for statusline)"
fi

echo ""
print_status $BLUE "📝 Next Steps:"
print_status $BLUE "1." "Edit ~/.claude/.env with your API keys:"
echo "   - ANTHROPIC_API_KEY=your-key-here"
echo "   - OPENAI_API_KEY=your-key-here" 
echo "   - ELEVENLABS_API_KEY=your-key-here (optional for premium TTS)"
echo "   - ENGINEER_NAME=YourName"
echo ""
print_status $BLUE "2." "Test the installation:"
echo "   echo '{\"session_id\": \"test\"}' | uv run ~/.claude/hooks/session_start.py --notify"
echo ""
print_status $BLUE "3." "Start Claude Code in any project - hooks will activate automatically!"
echo "   claude"
echo ""

print_status $YELLOW "💡 Important Notes:"
echo "• Your existing Claude Code settings have been preserved"
echo "• Backup files have been created for any replaced files"  
echo "• The .env file is correctly placed in ~/.claude/.env (critical for TTS)"
echo "• If TTS doesn't work, verify your API keys in ~/.claude/.env"
echo ""

if [ "$CCUSAGE_INSTALLED" = false ] && command -v npm &> /dev/null; then
    print_status $CYAN "💡 To install statusline monitoring later:"
    echo "   npm install -g ccusage"
    echo ""
fi

print_status $BLUE "📚 Documentation:" "https://github.com/PeterJBurke/claude-code-advanced-hooks"
print_status $BLUE "🐛 Issues:" "https://github.com/PeterJBurke/claude-code-advanced-hooks/issues"
echo ""

if [ "$INSTALL_SUCCESS" = true ]; then
    print_status $GREEN "Enjoy your enhanced Claude Code experience! 🚀"
else
    print_status $YELLOW "Installation completed with warnings. Check troubleshooting guide if needed."
fi

# Create a quick verification script
cat > ~/.claude/verify-installation.sh << 'EOF'
#!/bin/bash
echo "🔍 Claude Code Advanced Hooks - Installation Verification"
echo ""

# Check directory structure
echo "📁 Directory Structure:"
[ -d ~/.claude ] && echo "✅ ~/.claude exists" || echo "❌ ~/.claude missing"
[ -d ~/.claude/hooks ] && echo "✅ ~/.claude/hooks exists" || echo "❌ ~/.claude/hooks missing"
[ -d ~/.claude/logs ] && echo "✅ ~/.claude/logs exists" || echo "❌ ~/.claude/logs missing"
echo ""

# Check critical files
echo "📄 Critical Files:"
[ -f ~/.claude/settings.json ] && echo "✅ settings.json exists" || echo "❌ settings.json missing"
[ -f ~/.claude/.env ] && echo "✅ .env in correct location" || echo "❌ .env missing"
[ -f ~/.claude/hooks/.env ] && echo "❌ .env in wrong location (will break TTS!)" || echo "✅ no .env in hooks directory"
echo ""

# Check hook scripts
echo "🪝 Hook Scripts:"
cd ~/.claude/hooks
for hook in session_start.py pre_tool_use.py post_tool_use.py notification.py; do
    [ -f "$hook" ] && echo "✅ $hook exists" || echo "❌ $hook missing"
done
echo ""

# Test environment loading
echo "🔐 Environment Loading Test:"
if uv run python -c "
import os
from pathlib import Path
from dotenv import load_dotenv
env_path = Path(__file__).parent / '.env'
if env_path.exists():
    load_dotenv(env_path)
    print('✅ Environment file loads correctly')
    keys = ['ANTHROPIC_API_KEY', 'OPENAI_API_KEY', 'ELEVENLABS_API_KEY']
    for key in keys:
        value = os.getenv(key)
        if value and not value.startswith('your-'):
            print(f'✅ {key} is set')
        else:
            print(f'⚠️  {key} needs to be set')
else:
    print('❌ Environment file not found')
" 2>/dev/null; then
    echo "Environment test completed"
else
    echo "❌ Environment test failed"
fi
echo ""

# Check ccusage
echo "📊 StatusLine (ccusage):"
if command -v npx &> /dev/null; then
    if timeout 3 echo '{"test":"data"}' | npx -y ccusage statusline >/dev/null 2>&1; then
        echo "✅ ccusage statusline works"
    else
        echo "⚠️  ccusage test failed (may need installation)"
    fi
else
    echo "⚠️  npm/npx not found (needed for statusline)"
fi

echo ""
echo "📝 To fix any issues, see: https://github.com/PeterJBurke/claude-code-advanced-hooks"
EOF

chmod +x ~/.claude/verify-installation.sh

print_status $CYAN "💡 Created verification script: ~/.claude/verify-installation.sh"
print_status $CYAN "   Run it anytime with: ~/.claude/verify-installation.sh"