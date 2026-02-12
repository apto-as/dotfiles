-- ============================================================================
-- smart-splits.nvim - Seamless Neovim/tmux Pane Navigation
-- Purpose: Navigate between Neovim splits and tmux panes with the same keys
-- Keybindings: Ctrl+h/j/k/l for navigation, Alt+h/j/k/l for resizing
-- ============================================================================

return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,  -- Load immediately for keybindings
    opts = {
      -- tmux multiplexer integration
      multiplexer_integration = "tmux",

      -- Ignore buffers matching these filetypes when navigating
      ignored_buftypes = {
        "nofile",
        "quickfix",
        "prompt",
      },

      -- Ignore buffers matching these filetypes
      ignored_filetypes = {
        "NvimTree",
        "neo-tree",
      },

      -- Default amount to resize by
      default_amount = 3,

      -- Whether to wrap to opposite side when cursor is at edge
      at_edge = "wrap",

      -- Move cursor to the other window while resizing
      move_cursor_same_row = false,

      -- Whether to resize in insert mode
      cursor_follows_swapped_bufs = false,

      -- Resize mode settings
      resize_mode = {
        quit_key = "<ESC>",
        resize_keys = { "h", "j", "k", "l" },
        silent = false,
        hooks = {
          on_enter = nil,
          on_leave = nil,
        },
      },

      -- Ignored events (for performance)
      ignored_events = {
        "BufEnter",
        "WinEnter",
      },

      -- Log level for debugging
      log_level = "info",
    },
    keys = {
      -- Navigation: Ctrl+h/j/k/l
      -- These work seamlessly across Neovim splits AND Zellij panes
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Move to left split/pane",
        mode = { "n", "t" },
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Move to bottom split/pane",
        mode = { "n", "t" },
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Move to top split/pane",
        mode = { "n", "t" },
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Move to right split/pane",
        mode = { "n", "t" },
      },

      -- Resizing: Alt+h/j/k/l
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize split left",
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "Resize split down",
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "Resize split up",
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize split right",
      },

      -- Swap buffers: Leader+h/j/k/l
      {
        "<leader>bh",
        function()
          require("smart-splits").swap_buf_left()
        end,
        desc = "Swap buffer left",
      },
      {
        "<leader>bj",
        function()
          require("smart-splits").swap_buf_down()
        end,
        desc = "Swap buffer down",
      },
      {
        "<leader>bk",
        function()
          require("smart-splits").swap_buf_up()
        end,
        desc = "Swap buffer up",
      },
      {
        "<leader>bl",
        function()
          require("smart-splits").swap_buf_right()
        end,
        desc = "Swap buffer right",
      },
    },
  },
}
