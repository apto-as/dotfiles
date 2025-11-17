# Secure Credentials Management for Fish Shell
# Hestia Security Audit - 2025-11-13
#
# ⚠️ NEVER commit API keys directly to config files
# Use 1Password CLI or similar secure storage

# Check if op (1Password CLI) is available
if command -q op
    # Gemini API Key from 1Password
    # Format: op read "op://Private/Gemini API Key/credential"
    function load_gemini_api_key
        set -gx GEMINI_API_KEY (op read "op://Private/Gemini API Key/credential" 2>/dev/null)
        if test -z "$GEMINI_API_KEY"
            echo "⚠️  Failed to load Gemini API Key from 1Password" >&2
        end
    end

    # OpenAI API Key from 1Password
    function load_openai_api_key
        set -gx OPENAI_API_KEY (op read "op://Private/OpenAI API Key/credential" 2>/dev/null)
        if test -z "$OPENAI_API_KEY"
            echo "⚠️  Failed to load OpenAI API Key from 1Password" >&2
        end
    end

    # Google Service Account from 1Password
    function load_google_credentials
        # Store the path, not the actual credentials
        set -gx GOOGLE_APPLICATION_CREDENTIALS "$HOME/.gemini/gen-lang-client-0226258514-6fd63a2c94e1.json"

        # Verify the file exists and has correct permissions
        if test -f "$GOOGLE_APPLICATION_CREDENTIALS"
            set -l perms (stat -f "%Lp" "$GOOGLE_APPLICATION_CREDENTIALS")
            if test "$perms" != "600"
                echo "⚠️  WARNING: Google Service Account key has insecure permissions: $perms" >&2
                echo "   Run: chmod 600 $GOOGLE_APPLICATION_CREDENTIALS" >&2
            end
        else
            echo "⚠️  Google Service Account key not found: $GOOGLE_APPLICATION_CREDENTIALS" >&2
        end
    end

    # Load credentials only when explicitly requested
    # Do NOT load automatically on shell startup for security

else if test -f "$HOME/.secure_credentials/api_keys.env"
    # Fallback: Load from secure local file (gitignored)
    function load_credentials_from_file
        # Parse KEY=value format and export variables
        while read -l line
            # Skip empty lines and comments
            if test -z "$line" -o (string sub -l 1 -- "$line") = "#"
                continue
            end

            # Parse KEY=value format
            set -l parts (string split -m 1 "=" -- "$line")
            if test (count $parts) -eq 2
                set -gx $parts[1] $parts[2]
            end
        end < "$HOME/.secure_credentials/api_keys.env"
    end

    # Auto-load credentials from file on shell startup
    load_credentials_from_file

    # Note: Using secure file-based credentials (1Password CLI is optional)
    # To enable 1Password CLI integration: brew install 1password-cli
else
    echo "⚠️  No secure credential storage found." >&2
    echo "   Option 1: Install 1Password CLI: brew install 1password-cli" >&2
    echo "   Option 2: Create ~/.secure_credentials/api_keys.env (gitignored)" >&2
end

# Helper function to load all credentials at once
function load_all_credentials
    if functions -q load_gemini_api_key
        load_gemini_api_key
    end

    if functions -q load_openai_api_key
        load_openai_api_key
    end

    if functions -q load_google_credentials
        load_google_credentials
    end

    echo "✅ Credentials loaded securely"
end

# Security: Clear credentials on shell exit
function clear_credentials --on-event fish_exit
    set -e GEMINI_API_KEY
    set -e OPENAI_API_KEY
end
