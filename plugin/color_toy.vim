if exists("loaded_color_toy_plugin_color_toy")
    finish
endif
let loaded_color_toy_plugin_color_toy = 1

nnoremap <Plug>NextColor  :<C-U>call mudox#color_toy#NextColor()<Cr>
nnoremap <Plug>ShowCurColors  :<C-U>call mudox#color_toy#ShowCurColors()<Cr>

autocmd ColorScheme * call mudox#color_toy#On_ColorScheme()
autocmd VimLeavePre * call mudox#color_toy#On_VimLeavePre()
autocmd VimEnter    * call mudox#color_toy#On_VimEnter()
