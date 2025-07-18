local augroupIm = vim.api.nvim_create_augroup("im-settings", { clear = true })
local uname = vim.uv.os_uname()

if uname.sysname == "Linux" and os.getenv("WSL_DISTRO_NAME") ~= "" then
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = augroupIm,
    command = "silent! !zenhan.exe 1",
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroupIm,
    command = "silent! !zenhan.exe 0",
  })
end
