-- XMLの設定
local augroup_xml = vim.api.nvim_create_augroup("xml-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_xml,
  pattern = "xml",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- フォーマット指定
    if vim.fn.executable("xmllint") == 1 then
      vim.opt_local.formatprg = "xmllint --format -"
    elseif vim.fn.executable("python") == 1 then
      vim.opt_local.formatprg =
        "python -c 'import sys;import xml.dom.minidom;s=sys.stdin.read();print(xml.dom.minidom.parseString(s).toprettyxml())'"
    end
  end,
})
