return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Draculaテーマを適用
      opts.options = opts.options or {}
      opts.options.theme = 'dracula'
    end,
  },
}
