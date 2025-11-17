# Documentation Templates Library
## Reusable Templates for Zellij Documentation

**Purpose**: Standardized templates for consistent documentation across all Zellij integration documents.
**Usage**: Copy-paste and customize for each section.

---

## Table of Contents

1. [Document Header Templates](#document-header-templates)
2. [Section Templates](#section-templates)
3. [Code Example Templates](#code-example-templates)
4. [Troubleshooting Templates](#troubleshooting-templates)
5. [Comparison Table Templates](#comparison-table-templates)
6. [ASCII Diagram Templates](#ascii-diagram-templates)
7. [Navigation Templates](#navigation-templates)

---

## 1. Document Header Templates

### Template 1.1: Main Documentation Header

```markdown
# [Document Title]

[One-sentence description of document purpose]

## Overview

[2-3 paragraphs introducing the topic]

This guide covers:
- **Topic 1**: Brief description
- **Topic 2**: Brief description
- **Topic 3**: Brief description

**Prerequisites**:
- Prerequisite 1 ([link to guide](#))
- Prerequisite 2 ([link to guide](#))

**Estimated Reading Time**: X minutes

---

## Table of Contents

1. [Section 1](#section-1)
2. [Section 2](#section-2)
3. [Section 3](#section-3)

---
```

**Example Usage** (docs/ZELLIJ.md):

```markdown
# Zellij Configuration Guide

Complete guide for Zellij terminal multiplexer configuration in this dotfiles repository.

## Overview

This dotfiles repository includes a fully configured Zellij setup with:

This guide covers:
- **Installation**: Automatic setup via install.sh
- **Configuration**: Shared and machine-specific settings
- **Usage**: Essential keybindings and workflows
- **Layouts**: Pre-configured and custom layouts

**Prerequisites**:
- Wezterm installed ([Wezterm Guide](./WEZTERM.md))
- Basic terminal knowledge

**Estimated Reading Time**: 25-30 minutes

---
```

### Template 1.2: Subsection Header

```markdown
## [Section Title]

[1-2 sentence section introduction]

### Subsection 1

[Content]

### Subsection 2

[Content]
```

---

## 2. Section Templates

### Template 2.1: Feature Overview

```markdown
## [Feature Name]

[Feature description paragraph]

**Key Benefits**:
- Benefit 1
- Benefit 2
- Benefit 3

**When to Use**:
- Use case 1
- Use case 2

**Quick Example**:
```[language]
[minimal working example]
```

**See Also**: [Related Section](#section-name)
```

**Example Usage**:

```markdown
## Zellij Layouts

Layouts are pre-configured arrangements of panes and tabs that you can load instantly.

**Key Benefits**:
- Save time with instant workspace setup
- Maintain consistency across projects
- Share configurations with team members

**When to Use**:
- Starting a development session
- Switching between different project types
- Onboarding new team members

**Quick Example**:
```bash
# Load the development layout
zellij --layout development

# Or from within Zellij
Ctrl+o → l → development
```

**See Also**: [Creating Custom Layouts](#creating-custom-layouts)
```

### Template 2.2: Step-by-Step Tutorial

```markdown
## [Tutorial Title]

[Introduction paragraph explaining what we'll accomplish]

### Step 1: [Action]

[Explanation of what this step does]

```[language]
[command or code]
```

**Expected Result**:
[What the user should see]

### Step 2: [Action]

[Explanation]

```[language]
[command or code]
```

**Expected Result**:
[What the user should see]

### Step 3: [Action]

[Explanation]

```[language]
[command or code]
```

**Result**:
[Final outcome]

**Next Steps**:
- [What to do next]
- [Further reading]
```

**Example Usage** (5-Minute Quick Start):

```markdown
## 5-Minute Quick Start

In this tutorial, you'll learn the basics of Zellij in just 5 minutes.

### Step 1: Launch Zellij

Start Zellij from your terminal:

```bash
zellij
```

**Expected Result**:
You'll see a full-screen terminal with a status bar at the bottom showing available keybindings.

### Step 2: Create Your First Pane

Split the terminal horizontally:

1. Press `Ctrl+p` (enter Pane mode)
2. Press `d` (split down)

**Expected Result**:
Your terminal is now split into two horizontal panes, with focus on the new pane.

### Step 3: Navigate Between Panes

Move between panes using arrow keys:

1. Press `Ctrl+p` (enter Pane mode)
2. Press `↑` or `↓` to switch panes

**Result**:
You can now create and navigate between multiple terminal panes!

**Next Steps**:
- Try creating vertical panes with `Ctrl+p` → `r` (split right)
- Learn about [tabs](#tab-management)
- Explore [layouts](#layouts)
```

### Template 2.3: Configuration Section

```markdown
## [Configuration Topic]

[Introduction to configuration area]

### Location

```
[file path or directory structure]
```

### Default Configuration

```[language]
# Default settings
[configuration code with comments]
```

### Customization Options

**Option 1: [Name]**

[Description]

```[language]
[configuration example]
```

**Option 2: [Name]**

[Description]

```[language]
[configuration example]
```

### Machine-Specific Overrides

[Explanation of override system]

```[language]
# machines/<machine-type>/zellij.local.kdl
[override example]
```

### See Also

- [Related Config Section](#section)
- [Troubleshooting](#troubleshooting)
```

---

## 3. Code Example Templates

### Template 3.1: Basic Command Example

```markdown
### [Command/Feature Name]

[Brief description]

```[language]
# [Comment explaining the command]
command --flag value

# Output:
# [Expected output]
```

**Explanation**:
- `command`: What it does
- `--flag`: What this flag does
- `value`: What value means

**Common Options**:
| Option | Description | Example |
|--------|-------------|---------|
| `--option1` | Description | `command --option1` |
| `--option2` | Description | `command --option2` |

**See Also**: [Related Command](#related)
```

**Example Usage**:

```markdown
### Create a New Pane

Split your current pane to create a new one.

```bash
# Split horizontally (create pane below)
Ctrl+p → d

# Split vertically (create pane to the right)
Ctrl+p → r

# Or use CLI to start with splits
zellij --layout compact
```

**Explanation**:
- `Ctrl+p`: Enters Pane mode
- `d`: Splits down (horizontal split)
- `r`: Splits right (vertical split)

**Common Pane Commands**:
| Keybinding | Description | Visual Result |
|------------|-------------|---------------|
| `Ctrl+p → n` | New pane (auto-direction) | Splits based on space |
| `Ctrl+p → d` | Split down | Creates pane below |
| `Ctrl+p → r` | Split right | Creates pane to right |
| `Ctrl+p → x` | Close pane | Closes current pane |

**See Also**: [Pane Navigation](#pane-navigation)
```

### Template 3.2: Configuration File Example

```markdown
### [Configuration Name]

**Location**: `[file path]`

**Purpose**: [What this config controls]

```[language]
// [Comment: Section description]
[config-key] [config-value]

// [Comment: Another section]
[config-key] {
    [nested-key] [nested-value]
    [nested-key] [nested-value]
}
```

**Key Settings**:

**Setting 1: `[config-key]`**
- **Purpose**: [What it does]
- **Type**: [data type]
- **Default**: `[default value]`
- **Example**: `[example value]`

**Setting 2: `[config-key]`**
- **Purpose**: [What it does]
- **Type**: [data type]
- **Default**: `[default value]`
- **Example**: `[example value]`

**Complete Example**:

```[language]
// Full configuration example
[complete working config with comments]
```

**Testing Your Configuration**:
```bash
[command to test config]
```
```

**Example Usage** (Zellij Theme Config):

```markdown
### Theme Configuration

**Location**: `~/.config/zellij/themes/dracula.kdl`

**Purpose**: Defines color scheme for Zellij UI elements

```kdl
// Dracula theme for Zellij
themes {
    dracula {
        fg "#f8f8f2"
        bg "#282a36"
        black "#21222c"
        red "#ff5555"
        green "#50fa7b"
        yellow "#f1fa8c"
        blue "#bd93f9"
        magenta "#ff79c6"
        cyan "#8be9fd"
        white "#f8f8f2"
        orange "#ffb86c"
    }
}
```

**Key Settings**:

**Setting 1: `fg` (foreground)**
- **Purpose**: Default text color
- **Type**: Hex color code
- **Default**: `#f8f8f2` (off-white)
- **Example**: `#ffffff` (pure white)

**Setting 2: `bg` (background)**
- **Purpose**: Default background color
- **Type**: Hex color code
- **Default**: `#282a36` (dark purple)
- **Example**: `#1e1e1e` (darker gray)

**Complete Example**:

```kdl
// Full Dracula theme with all colors
themes {
    dracula {
        fg "#f8f8f2"
        bg "#282a36"
        black "#21222c"
        red "#ff5555"
        green "#50fa7b"
        yellow "#f1fa8c"
        blue "#bd93f9"
        magenta "#ff79c6"
        cyan "#8be9fd"
        white "#f8f8f2"
        orange "#ffb86c"
    }
}
```

**Testing Your Configuration**:
```bash
# Reload Zellij configuration
Ctrl+o → r  # (within Zellij)

# Or restart Zellij
zellij kill-all-sessions
zellij
```
```

### Template 3.3: Comparison Example (Side-by-Side)

```markdown
### [Comparison Title]

[Introduction explaining what's being compared]

#### Option 1: [Name]

```[language]
[code example]
```

**Pros**:
- Pro 1
- Pro 2

**Cons**:
- Con 1
- Con 2

**Use When**: [scenario]

#### Option 2: [Name]

```[language]
[code example]
```

**Pros**:
- Pro 1
- Pro 2

**Cons**:
- Con 1
- Con 2

**Use When**: [scenario]

#### Recommendation

[Which option to choose and why]
```

---

## 4. Troubleshooting Templates

### Template 4.1: Problem-Solution Format

```markdown
### Problem: [Brief Problem Statement]

**Symptoms**:
- Symptom 1
- Symptom 2

**Possible Causes**:
1. Cause 1
2. Cause 2
3. Cause 3

---

#### Solution 1: [Primary Solution]

[Explanation of what this fixes]

```bash
# Step 1
command1

# Step 2
command2

# Verify
verification_command
# Expected output: [what you should see]
```

**Success Indicator**: [How to know it worked]

---

#### Solution 2: [Alternative Solution]

[When to use this alternative]

```bash
alternative_command
```

---

#### Solution 3: [Last Resort]

[Explanation of drastic measures]

```bash
# Backup first!
backup_command

# Then fix
fix_command
```

⚠️ **Warning**: [Potential risks]

---

#### Still Not Working?

If none of the above solutions work:

1. **Check logs**:
   ```bash
   tail -f ~/.zellij/zellij.log
   ```

2. **Run debug mode**:
   ```bash
   zellij --debug
   ```

3. **Verify installation**:
   ```bash
   zellij --version
   which zellij
   ```

4. **Report issue**: [GitHub Issues link]

**See Also**: [Related Troubleshooting](#section)
```

**Example Usage**:

```markdown
### Problem: Keybindings Not Working

**Symptoms**:
- Pressing `Ctrl+p` does nothing
- Zellij doesn't respond to keyboard input
- Terminal seems "frozen"

**Possible Causes**:
1. Conflicting keybindings in terminal emulator
2. Zellij is in a different mode
3. Configuration syntax error
4. Terminal input not being captured

---

#### Solution 1: Check Current Mode

Zellij might be in a different mode.

```bash
# Look at the bottom status bar
# It shows the current mode (Normal, Pane, Tab, etc.)

# Return to Normal mode
Press Esc

# Or press the mode key again
Ctrl+p  # If already in Pane mode, exits to Normal
```

**Success Indicator**: Status bar should show "Normal" mode

---

#### Solution 2: Check for Conflicts

Wezterm or other tools might be intercepting keybindings.

```bash
# Edit Wezterm config
nvim ~/.config/wezterm/wezterm.lua

# Look for conflicting keybindings
# Comment out or remove:
-- { key = "p", mods = "CTRL", action = ... },
```

**Restart both Wezterm and Zellij** after changes.

---

#### Solution 3: Reset Configuration

Config file might have syntax errors.

```bash
# Backup current config
cp ~/.config/zellij/config.kdl ~/.config/zellij/config.kdl.backup

# Use default config
rm ~/.config/zellij/config.kdl

# Restart Zellij
zellij kill-all-sessions
zellij
```

⚠️ **Warning**: This removes your custom configuration

---

#### Still Not Working?

If none of the above solutions work:

1. **Check logs**:
   ```bash
   tail -f ~/.zellij/zellij.log
   ```

2. **Run debug mode**:
   ```bash
   zellij --debug
   ```

3. **Verify installation**:
   ```bash
   zellij --version
   which zellij
   ```

4. **Report issue**: [GitHub Issues](https://github.com/.../issues)

**See Also**: [Keybinding Customization](#keybinding-customization)
```

### Template 4.2: Quick Diagnostic

```markdown
### Quick Diagnostic: [Issue Name]

**Run these commands to diagnose**:

```bash
# Check 1: [What this checks]
command1
# Expected: [good output]
# If you see: [bad output] → [problem identified]

# Check 2: [What this checks]
command2
# Expected: [good output]
# If you see: [bad output] → [problem identified]

# Check 3: [What this checks]
command3
# Expected: [good output]
# If you see: [bad output] → [problem identified]
```

**Based on Results**:
- Problem 1 → [Solution link](#solution-1)
- Problem 2 → [Solution link](#solution-2)
- Problem 3 → [Solution link](#solution-3)
```

---

## 5. Comparison Table Templates

### Template 5.1: Feature Comparison

```markdown
### [Comparison Title]

| Feature | Tool 1 | Tool 2 | Tool 3 | Winner |
|---------|--------|--------|--------|--------|
| Feature 1 | ✅ Yes | ❌ No | ⚠️ Partial | Tool 1 |
| Feature 2 | Value 1 | Value 2 | Value 3 | Tool 2 |
| Feature 3 | ✅ | ✅ | ✅ | Tie |

**Legend**:
- ✅ = Supported
- ❌ = Not supported
- ⚠️ = Partial support / limitations
```

**Example Usage** (tmux vs Zellij):

```markdown
### tmux vs. Zellij: Feature Comparison

| Feature | tmux | Zellij | Winner |
|---------|------|--------|--------|
| Written in | C | Rust | Zellij (memory safety) |
| Default UI | Minimal | Rich status bar | Zellij (beginner-friendly) |
| Layout system | Manual scripting | Built-in KDL | Zellij (easier) |
| Learning curve | Steep | Gentle | Zellij (onboarding) |
| Plugin ecosystem | Mature | Early stage | tmux (more options) |
| Performance | Excellent | Excellent | Tie |
| Session persistence | ✅ | ✅ | Tie |

**Legend**:
- ✅ = Supported
- ❌ = Not supported
- ⚠️ = Partial support / Work in progress
```

### Template 5.2: Keybinding Comparison

```markdown
### [Keybinding Category]

| Action | Tool 1 | Tool 2 | Tool 3 | Notes |
|--------|--------|--------|--------|-------|
| Action 1 | Key 1 | Key 2 | Key 3 | Note |
| Action 2 | Key 1 | Key 2 | Key 3 | Note |

**Conflicts**:
- Conflict 1: [Description and resolution]
- Conflict 2: [Description and resolution]

**Recommendations**:
- [Recommendation 1]
- [Recommendation 2]
```

**Example Usage**:

```markdown
### Pane Management Keybindings

| Action | tmux | Zellij | Neovim | Notes |
|--------|------|--------|--------|-------|
| New pane | `Ctrl+b %` | `Ctrl+p n` | N/A | Zellij auto-detects direction |
| Split horizontal | `Ctrl+b "` | `Ctrl+p d` | `:split` | Zellij mnemonic: "d" = down |
| Split vertical | `Ctrl+b %` | `Ctrl+p r` | `:vsplit` | Zellij mnemonic: "r" = right |
| Navigate left | `Ctrl+b ←` | `Ctrl+p h` | `Ctrl+w h` | Vim-style in Zellij/Neovim |
| Navigate down | `Ctrl+b ↓` | `Ctrl+p j` | `Ctrl+w j` | Vim-style in Zellij/Neovim |
| Close pane | `Ctrl+b x` | `Ctrl+p x` | `:q` | Consistent "x" across tools |

**Conflicts**:
- `Ctrl+p`: Zellij Pane mode vs. Neovim command history (↑)
  - **Resolution**: Neovim conflict only in terminal mode, minimal impact
- `Ctrl+w`: Neovim window commands vs. browser close
  - **Resolution**: Use Neovim inside Zellij/Wezterm, browser separate

**Recommendations**:
- Learn Zellij's vim-style navigation (`hjkl`) for muscle memory consistency
- Remap Wezterm keybindings to avoid Zellij conflicts
- Use Neovim's terminal mode sparingly; prefer Zellij panes
```

---

## 6. ASCII Diagram Templates

### Template 6.1: Layout Diagram

```markdown
### [Layout Name]

**Visual Structure**:

```
┌─────────────────────────────────────┐
│                                     │
│       [Pane Name] ([Size]%)         │
│                                     │
├─────────────────────────────────────┤
│ [Pane] ([Size]%) │ [Pane] ([Size]%) │
├──────────────────┴──────────────────┤
│ [Status Bar or Footer]              │
└─────────────────────────────────────┘
```

**Pane Details**:
- **Pane 1**: [Purpose, typical command]
- **Pane 2**: [Purpose, typical command]
- **Pane 3**: [Purpose, typical command]

**Use Case**: [When to use this layout]

**Load Command**:
```bash
zellij --layout [layout-name]
```
```

**Example Usage**:

```markdown
### Development Layout

**Visual Structure**:

```
┌─────────────────────────────────────┐
│                                     │
│       Editor (Neovim) (60%)         │
│                                     │
├─────────────────────────────────────┤
│ Terminal (40%)  │ Logs (60%)        │
├─────────────────┴───────────────────┤
│ Status: zellij | 3 panes | Tab 1    │
└─────────────────────────────────────┘
```

**Pane Details**:
- **Editor Pane (top)**: Neovim for code editing (60% height)
- **Terminal Pane (bottom-left)**: Command execution, git operations (40% width)
- **Logs Pane (bottom-right)**: Server logs, test output (60% width)

**Use Case**: Full-stack development with live logs monitoring

**Load Command**:
```bash
zellij --layout development
```
```

### Template 6.2: Workflow Diagram

```markdown
### [Workflow Name]

```
[State 1] → [Action] → [State 2]
                      ├─ [Option A] → [Result A]
                      └─ [Option B] → [Result B]
```

**Steps**:
1. [State 1]: [Description]
2. [Action]: [Description]
3. [State 2]: [Description]
4. [Decision]: [Description]
```

**Example Usage** (Zellij Mode System):

```markdown
### Zellij Mode System Workflow

```
Normal Mode → Ctrl+p → Pane Mode
                      ├─ n → New pane (auto-direction)
                      ├─ d → Split down (horizontal)
                      ├─ r → Split right (vertical)
                      ├─ x → Close pane
                      ├─ hjkl → Navigate panes
                      ├─ Shift+hjkl → Resize panes
                      └─ Esc → Back to Normal Mode

Normal Mode → Ctrl+t → Tab Mode
                      ├─ n → New tab
                      ├─ 1-9 → Switch to tab N
                      ├─ h/l → Previous/Next tab
                      ├─ r → Rename tab
                      └─ Esc → Back to Normal Mode
```

**Steps**:
1. **Normal Mode**: Default state, no special actions
2. **Enter Mode**: Press mode prefix (`Ctrl+p`, `Ctrl+t`, etc.)
3. **Execute Action**: Press action key (single key, no prefix)
4. **Auto-Return**: Automatically returns to Normal Mode after action
```

### Template 6.3: Tree Structure

```markdown
### [Structure Name]

```
Root
├── Branch 1
│   ├── Item 1.1
│   └── Item 1.2
├── Branch 2
│   ├── Item 2.1
│   ├── Item 2.2
│   └── Item 2.3
└── Branch 3
    └── Item 3.1
```

**Description**:
- **Branch 1**: [Description]
- **Branch 2**: [Description]
- **Branch 3**: [Description]
```

---

## 7. Navigation Templates

### Template 7.1: "See Also" Section

```markdown
## See Also

- [Related Topic 1](./file.md#section) - Brief description
- [Related Topic 2](./file.md#section) - Brief description
- [Related Topic 3](./file.md#section) - Brief description

**External Resources**:
- [Official Documentation](https://example.com)
- [Community Forum](https://example.com)
```

### Template 7.2: Cross-Reference Link

```markdown
For more details, see [Section Name](#section-anchor) in this guide.

Related: [Other Document Title](./other-file.md)
```

### Template 7.3: Prerequisites Callout

```markdown
> **Prerequisites**: Before proceeding, ensure you have:
> - ✅ [Prerequisite 1](./link.md)
> - ✅ [Prerequisite 2](./link.md)
> - ✅ [Prerequisite 3](./link.md)
```

### Template 7.4: Next Steps

```markdown
## Next Steps

Now that you've completed [current topic], you can:

1. **Beginner**: [Next Beginner Topic](./link.md)
2. **Intermediate**: [Next Intermediate Topic](./link.md)
3. **Advanced**: [Next Advanced Topic](./link.md)

Or explore:
- [Alternative Path 1](./link.md)
- [Alternative Path 2](./link.md)
```

---

## 8. Callout/Warning Templates

### Template 8.1: Warning

```markdown
⚠️ **Warning**: [Brief warning]

[Detailed explanation of the risk]

**Before proceeding**:
- [ ] Backup: [What to backup]
- [ ] Verify: [What to verify]
- [ ] Understand: [Consequences]
```

### Template 8.2: Tip

```markdown
💡 **Tip**: [Helpful hint]

[Explanation of the tip]
```

### Template 8.3: Note

```markdown
📝 **Note**: [Important information]

[Details]
```

### Template 8.4: Important

```markdown
❗ **Important**: [Critical information]

[Explanation of why this is critical]
```

---

## Usage Guidelines

### When to Use Each Template

| Template | Use Case |
|----------|----------|
| Document Header | Start of every major documentation file |
| Feature Overview | Introducing new concepts |
| Step-by-Step Tutorial | Teaching procedures |
| Configuration Section | Explaining config files |
| Command Example | Documenting commands |
| Troubleshooting | Solving problems |
| Comparison Table | Choosing between options |
| ASCII Diagram | Visualizing structures |

### Customization Guidelines

1. **Copy** the template to your document
2. **Replace** all `[placeholders]` with actual content
3. **Adjust** section lengths based on complexity
4. **Test** all code examples before publishing
5. **Cross-reference** related sections

---

*This templates library is maintained as part of the Zellij documentation strategy.*
