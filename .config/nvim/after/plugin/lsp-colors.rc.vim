if !exists('#LspColors') | finish | endif

lua << EOF
require("lsp-colors").setup({
  Error = "#ff79c6",
  Warning = "#8be9fd",
  Information = "#bd93f9",
  Hint = "#6277a4"
})
EOF
