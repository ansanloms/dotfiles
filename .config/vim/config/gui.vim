if has("gui_running")
  if has("vim_starting")
    " フォント設定
    set guifont=Moralerspace_Krypton_HWNF:h10:cSHIFTJIS:qDRAFT

    " 縦幅 デフォルトは 24
    set lines=40

    " 横幅 デフォルトは 80
    set columns=160
  endif

  " GUI オプション
  set guioptions=AcfiM!

  " 行間設定
  set linespace=0

  " カーソルを点滅させない
  set guicursor=a:blinkon0
endif
