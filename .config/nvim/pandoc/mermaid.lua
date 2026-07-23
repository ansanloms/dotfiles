-- Pandoc Lua filter: ```mermaid コードブロックを client-side レンダリング用の
-- <pre class="mermaid"> に変換する。mermaid.js は textContent を読むため、
-- HTML として壊れないよう最小限のエスケープを行う。
function CodeBlock(el)
  if el.classes:includes("mermaid") then
    local escaped = el.text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    return pandoc.RawBlock("html", '<pre class="mermaid">\n' .. escaped .. "\n</pre>")
  end
end
