return {
  "rbtnn/vim-ambiwidth",
  init = function()
    vim.g.ambiwidth_cica_enabled = false

    vim.g.ambiwidth_add_list = {
      -- Seti-UI + Custom
      { 0xe5fa,  0xe62d,  2 }, { 0xe62f, 0xe6b7, 2 },
      -- Devicons
      { 0xe700,  0xe8ef,  2 },
      -- Material Design Icons
      { 0xf0001, 0xf1af0, 2 },
      -- Codicons
      { 0xea60,  0xec1e,  2 },
      -- Octicons
      { 0xf400,  0xf533,  2 },
      -- Font Awesome
      { 0xed00,  0xedff,  2 }, { 0xee0c, 0xefce, 2 }, { 0xf000, 0xf2ff, 2 },
      -- Font Logos @see https://github.com/lukas-w/font-logos
      -- 0xf315-0xf316 / 0xf31b-0xf31c は vim-ambiwidth 本体が常時定義済みの為、重複を避けて分割する。
      { 0xf300, 0xf314, 2 }, { 0xf317, 0xf31a, 2 }, { 0xf31d, 0xf381, 2 },
      -- Geometric Shapes @see https://www.unicode.org/charts/PDF/U25A0.pdf
      { 0x25a2, 0x25a9, 2 }, { 0x25ac, 0x25b3, 2 }, { 0x25b6, 0x25b7, 2 }, { 0x25bc, 0x25bd, 2 }, { 0x25c0, 0x25c1, 2 },
      { 0x25c8, 0x25c9, 2 }, { 0x25d0, 0x25d7, 2 }, { 0x25e2, 0x25e5, 2 }, { 0x25e7, 0x25ef, 2 }, { 0x25f0, 0x25ff, 2 },
      -- Mathematical Operators @see https://www.unicode.org/charts/PDF/U2200.pdf
      { 0x2200, 0x2265, 2 }, { 0x2268, 0x22ff, 2 },
      -- Miscellaneous Technical @see https://www.unicode.org/charts/PDF/U2300.pdf
      { 0x2300, 0x23FF, 2 },
      -- General Punctuation @see https://www.unicode.org/charts/PDF/U2000.pdf
      { 0x2025, 0x2027, 2 },
    }
  end,
}
