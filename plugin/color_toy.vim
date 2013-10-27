nnoremap <Plug>NextColor  :<C-U>call mudox#auto_colo#Toy.shuffleColor()<CR>
nnoremap <Plug>ShowColors  :<C-U>call mudox#auto_colo#Toy.showCurColors()<CR>

autocmd ColorScheme * call mudox#color_toy#options#Toy.onColorScheme()
autocmd VimLeavePre * call mudox#color_toy#options#Toy.saveConfig()
autocmd VimEnter    * call mudox#color_toy#options#Toy.nextVimColor()
