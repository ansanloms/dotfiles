local wezterm = require("wezterm");
local config = wezterm.config_builder()

function merge(config, new_config)
  for k, v in pairs(new_config) do
    config[k] = v
  end
end

-- 設定の自動再読み込み。
config.automatically_reload_config = true

-- IME を有効にする。
config.use_ime = true

-- 起動するシェルの設定。
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = { "pwsh.exe", "-NoLogo" }
end
if wezterm.target_triple == "x86_64-apple-darwin" then
  config.default_prog = { "zsh" }
end

-- @see https://github.com/wezterm/wezterm/issues/4881
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"

-- 外観。
merge(config, require("appearance"))

-- キーバインドまわり。
merge(config, require("keybinding"))

return config
