" Author: Mudox
" Description: A funny toy for play with vim colorschemes.

" if exists('g:loaded_colors_funny_toy')
" finish
" endif
" let g:loaded_colors_funny_toy = 1

" initialize global variable.
let mudox#auto_colo#Toy = {
            \ 'curVimColor' : '',
            \ 'curAirlineColor': ''
            \ }
let s:Toy = mudox#auto_colo#Toy " for local conveniently reference.

" collect vim colorscheme files.
let s:Toy.vimColorAvail = split(globpath(&rtp, 'colors/*.vim', 1), '\n')
call map(s:Toy.vimColorAvail, 'fnamemodify(v:val, ":t:r")')

" collect airline colorscheme files, if any.
let s:Toy.airlineColorAvail = split(globpath(&rtp, 'autoload/airline/themes/*.vim', 1), '\n')
call map(s:Toy.airlineColorAvail, 'fnamemodify(v:val, ":t:r")')

" apply filter options.
" if has("gui_running")
" White list takes precedence over black list.
" if exists('g:mdx_colos_white_list') &&
" \ !empty('g:mdx_colos_white_list')
" let g:my_colos = filter(
" \   copy(s:Toy.vim_color_avail),
" \   'index(g:mdx_colos_white_list, v:val) != -1'
" \ )
" elseif exists('g:mdx_colos_black_list') &&
" \ !empty('g:mdx_colos_black_list')
" let g:my_colos = filter(
" \   copy(s:Toy.vim_color_avail),
" \   'index(g:mdx_colos_black_list, v:val) == -1'
" \ )
" endif
" else
" White list takes precedence over black list.
" if exists('g:mdx_colos_256_white_list') &&
" \ !empty('g:mdx_colos_256_white_list')
" let g:my_colos = filter(
" \   copy(s:Toy.vim_color_avail),
" \   'index(g:mdx_colos_256_white_list, v:val) != -1'
" \ )
" elseif exists('g:mdx_colos_256_black_list') &&
" \ !empty('g:mdx_colos_256_black_list')
" let g:my_colos = filter(
" \   copy(s:Toy.vim_color_avail),
" \   'index(g:mdx_colos_256_black_list, v:val) == -1'
" \ )
" endif
" endif

" show current vim colorscheme & airline theme if any.
function! s:Toy.showCurColors() dict

    let l:msg = '[Vim] : ' . s:Toy.curVimColor
    if exists(':AirlineTheme') && len(s:Toy.curAirlineColor) > 0
        let l:msg = l:msg . "\t\t[Airline] : " . s:Toy.curAirlineColor
    endif

    echo l:msg
endfunction

" randomly change vim colorscheme & ailne theme if any.
function! s:Toy.shuffleColor() dict

    " pick a vim colorscheme first.
    let l:idx = localtime() % len(self.vimColorAvail)
    let self.curVimColor = self.vimColorAvail[l:idx]

    " if the there is a airline theme named as the picked vim colorscheme
    " above, use it, otherwise randomly pick a airline theme.
    if len(self.airlineColorAvail) > 0
        if index(self.airlineColorAvail, self.curVimColor) >= 0
            let self.curAirlineColor = self.curVimColor
        else
            let l:idx = localtime() % len(self.airlineColorAvail)
            let self.curAirlineColor = self.airlineColorAvail[l:idx]
        endif
    endif

    execute "colorscheme " . self.curVimColor

    if exists(':AirlineTheme') && len(self.curAirlineColor) > 0
        execute "AirlineTheme " . self.curAirlineColor
    endif

    redraw

    call self.showCurColors()

endfunction

function mudox#auto_colo#ShuffleColor()
    call s:Toy.shuffleColor()
endfunction

" function! mudox#auto_colo#ColoMarquee()
" let l:cur_color = g:colors_name

" for c in s:Toy.vim_color_avail
" execute "colorscheme " . c
" redraw
" echo c
" sleep 300m
" endfor

" restore previous colorscheme.
" execute 'colorscheme ' . l:cur_color
" endfunction

" vim: fileformat=unix
