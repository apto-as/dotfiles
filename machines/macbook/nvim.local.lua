-- ===========================================================================
-- Machine-Specific Neovim Configuration for: Mac (MacBook)
-- ===========================================================================
-- This file is loaded after the main init.lua
-- Use it for machine-specific settings

return {
  -- UI adjustments for this machine
  ui = {
    -- Smaller window size for MacBook screen
    width = 120,
    height = 35,
  },

  -- Machine-specific LSP servers (optional)
  lsp = {
    -- servers = {
    --   -- Example: enable specific LSP only on this machine
    --   -- sourcekit = {},  -- Swift development
    -- },
  },

  -- Performance tuning for this machine
  performance = {
    -- max_workers = 4,
  },

  -- Any other machine-specific settings
}
