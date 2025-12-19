# ============================================================================
# Machine-Specific Fish Configuration Template
# ============================================================================
# Copy this file to machines/{YOUR_MACHINE_TYPE}/fish.local.fish
# and customize for your specific machine.
#
# Setup:
#   1. Copy this template: cp -r machines/_template machines/{machine-name}
#   2. Set MACHINE_TYPE: set -gx MACHINE_TYPE "{machine-name}"
#      Or let it auto-detect from hostname
#   3. Customize the settings below
# ============================================================================

# ============================================================================
# Machine Information (Optional - for documentation)
# ============================================================================
# Hostname: {your-hostname}
# OS: {macOS / Linux / etc.}
# Architecture: {arm64 / x86_64 / etc.}
# Purpose: {development / server / personal / etc.}

# ============================================================================
# OS-Specific Environment Variables
# ============================================================================
# Uncomment and modify as needed for your OS/architecture

# --- macOS with Homebrew (Apple Silicon) ---
# set -gx HOMEBREW_PREFIX "/opt/homebrew"
# set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar"
# set -gx HOMEBREW_REPOSITORY "/opt/homebrew"

# --- macOS with Homebrew (Intel) ---
# set -gx HOMEBREW_PREFIX "/usr/local"
# set -gx HOMEBREW_CELLAR "/usr/local/Cellar"
# set -gx HOMEBREW_REPOSITORY "/usr/local/Homebrew"

# --- Linux (common paths) ---
# fish_add_path -p /usr/local/bin
# fish_add_path -a ~/.local/bin

# ============================================================================
# Build Dependencies (if needed)
# ============================================================================
# set -gx LDFLAGS "-L/path/to/lib"
# set -gx CPPFLAGS "-I/path/to/include"

# ============================================================================
# Conda/Mamba/Miniforge Configuration
# ============================================================================
# Uncomment and modify based on your conda installation

# --- Miniforge (recommended for Apple Silicon) ---
# set -l CONDA_BASE "$HOME/miniforge3"

# --- Anaconda ---
# set -l CONDA_BASE "$HOME/anaconda3"

# --- Miniconda ---
# set -l CONDA_BASE "$HOME/miniconda3"

# if test -d $CONDA_BASE
#     set -gx CONDA_EXE "$CONDA_BASE/bin/conda"
#     set -gx _CONDA_ROOT $CONDA_BASE
#
#     # Lazy-load conda for faster shell startup
#     function conda --description "Lazy-loaded conda"
#         functions -e conda
#         if test -f $CONDA_EXE
#             eval $CONDA_EXE "shell.fish" hook $argv | source
#         else if test -f "$_CONDA_ROOT/etc/fish/conf.d/conda.fish"
#             source "$_CONDA_ROOT/etc/fish/conf.d/conda.fish"
#         else
#             fish_add_path -p "$_CONDA_ROOT/bin"
#         end
#         conda $argv
#     end
# end

# ============================================================================
# Prompt Theme Configuration (Optional)
# ============================================================================
# Override the default oh-my-posh theme path if needed
# set -gx OMP_THEME_PATH "/path/to/your/theme.omp.json"

# Or use Starship instead
# set -gx USE_STARSHIP 1

# ============================================================================
# Machine-Specific Aliases
# ============================================================================
# Add any aliases specific to this machine

# Example: Application shortcuts
# alias tailscale "/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Example: SSH shortcuts
# alias server1 "ssh user@server1.example.com"

# ============================================================================
# Machine-Specific Functions
# ============================================================================
# Add any functions specific to this machine

# Example: Quick project navigation
# function proj
#     cd ~/Projects/$argv[1]
# end

# ============================================================================
# Machine-Specific PATH additions
# ============================================================================
# Add machine-specific tools to PATH

# Example: Custom tool installations
# fish_add_path -a /opt/custom-tools/bin

# ============================================================================
# End of Template
# ============================================================================
