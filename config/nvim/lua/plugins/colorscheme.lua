return {
  {
    "Mofiqul/dracula.nvim",
    priority = 1000, -- 他のUIより先に読み込む
    config = function()
      -- Dracula テーマのセットアップ (オプションがあればここに追加)
      require('dracula').setup({
        -- transparent_bg = true -- Dracula自体に透過オプションがあれば使う (なければ下記の手動設定)
      })

      -- カラースキームを適用
      vim.cmd.colorscheme("dracula")

      -- 背景透過設定
      local highlights = {
        "Normal", "NormalNC", "NormalFloat", "FloatBorder", "WinSeparator",
        "SignColumn", "ColorColumn", "CursorLine", "CursorLineNr",
        "FoldColumn", "Folded", "EndOfBuffer", "TabLine", "TabLineFill", "TabLineSel",
        "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeWinSeparator",
        -- 必要に応じて :hi で確認し、他のハイライトグループを追加
      }
      for _, group in ipairs(highlights) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
      end

      -- (任意) 上記で透過されないUI要素があれば個別に設定
      -- 例: vim.api.nvim_set_hl(0, "LspInfoBorder", { bg = "none" })
    end,
  },
}
