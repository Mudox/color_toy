" Author: Mudox
" Description: A funny toy for play with vim colorschemes.

" if exists('g:loaded_colors_funny_toy')
    " finish
" endif
" let g:loaded_colors_funny_toy = 1

let mudox#auto_colo#Toy = {} " for global reference.
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

function! s:Toy.showCurColors() dict
    echo '[Vim] : ' . s:Toy.curVimColor . "\t[Airline] : " . s:Toy.curAirlineColor
endfunction

" used after gvim's initialization is finished.
function! s:Toy.shuffleAfterRC() dict
    call s:Toy.shuffle()

    execute "colorscheme " . s:Toy.curVimColor
    execute "AirlineTheme " . s:Toy.curAirlineColor
    redraw

    call s:Toy.showCurColors()
endfunction

" used when vim is initializing.
function! s:Toy.shuffleRC() dict
    call s:Toy.shuffle()

    execute "colorscheme " . s:Toy.curVimColor
    let g:airline_theme = s:Toy.curAirlineColor

    autocmd VimEnter * :call s:Toy.showCurColors()
endfunction

function! s:Toy.shuffle() dict
    " pick a vim colorscheme first.
    let l:idx = localtime() % len(s:Toy.vimColorAvail)
    let s:Toy.curVimColor = s:Toy.vimColorAvail[l:idx]

    " if the there is a airline theme named as the picked vim colorscheme
    " above, use it, otherwise randomly draw a airline theme.
    if len(s:Toy.vimColorAvail) > 0
        if index(s:Toy.airlineColorAvail, s:Toy.curVimColor) >= 0
            let s:Toy.curAirlineColor = s:Toy.curVimColor
        else
            let l:idx = localtime() % len(s:Toy.airlineColorAvail)
            let s:Toy.curAirlineColor = s:Toy.airlineColorAvail[l:idx]
        endif
    else
        let s:Toy.curAirlineColor = ''
    endif
endfunction

function! mudox#auto_colo#ShuffleColorRC()
    call s:Toy.shuffleRC()
endfunction

function! mudox#auto_colo#ShuffleColorAfterRC()
    call s:Toy.shuffleAfterRC()
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
