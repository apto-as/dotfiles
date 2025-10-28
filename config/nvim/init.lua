-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- ============================================================================
-- Machine-Specific Configuration Loading
-- ============================================================================
-- Load local.lua for machine-specific settings (UI, LSP, performance, etc.)
local local_config_path = vim.fn.stdpath("config") .. "/lua/local.lua"

if vim.loop.fs_stat(local_config_path) then
  local ok, local_config = pcall(require, "local")
  if ok and local_config then
    -- Apply machine-specific configuration
    if local_config.ui then
      -- UI settings can be applied here if needed
      vim.notify("Loaded machine-specific UI config", vim.log.levels.INFO)
    end
    if local_config.lsp and local_config.lsp.servers then
      -- LSP servers will be loaded by LazyVim
      vim.notify("Loaded machine-specific LSP config", vim.log.levels.INFO)
    end
  else
    vim.notify("Failed to load local config: " .. tostring(local_config), vim.log.levels.WARN)
  end
else
  -- No local.lua found - this is normal for shared config
  -- Uncomment to see warning:
  -- vim.notify("No local.lua found. Using default settings.", vim.log.levels.INFO)
end
