return {
  {
    "nvim-lualine/lualine.nvim",
    -- event = "VeryLazy", -- LazyVimのデフォルトに含まれていれば不要な場合も
    opts = function(_, opts)
      -- 第2引数 'opts' でデフォルト設定を受け取る
      local mcphub_module = require('mcphub.extensions.lualine')

      -- 1. カスタムコンポーネントをrequire
      local mcphub_component_definition = {
        mcphub_module,
        -- 後々、ここにcolor設定を足すこと
      }

      if opts.sections and opts.sections.lualine_x then
         table.insert(opts.sections.lualine_x, mcphub_component_definition)
      else
         -- もし LazyVim のデフォルトに lualine_x がなければ作成して追加
         opts.sections = opts.sections or {}
         opts.sections.lualine_x = { mcphub_component_definition }
      end

      -- 3. 他にも変更したいデフォルト設定があれば、ここで opts テーブルを書き換える
      opts.options.theme = 'dracula'

    end,
  },
}