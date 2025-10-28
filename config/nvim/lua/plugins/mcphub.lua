return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
  },
  opts = function()
    extensions = {
      avante = {
          make_slash_commands = true, -- make /slash commands from MCP server prompts
      }
    }
  end,
  build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
  config = function()
    require("mcphub").setup()
  end,
}
