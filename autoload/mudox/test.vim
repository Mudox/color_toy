nnoremap <Enter>t  :call <SID>Main()<Cr>
function <SID>Main()
  call s:Toy.nextVimColor()
  call s:Toy.saveConfig()
endfunction
