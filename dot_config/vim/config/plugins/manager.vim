" minpac の取得
if !isdirectory(expand("~/.config/vim/pack/minpac/opt/minpac"))
  call system("git clone https://github.com/k-takata/minpac.git " . expand("~/.config/vim/pack/minpac/opt/minpac"))
endif
packadd minpac

call minpac#init()

call minpac#add("https://github.com/k-takata/minpac.git", {"type": "opt"})
