" Author: Mudox
" Description: A funny toy for play with vim colorschemes.

"if exists('loaded_mudox_color_toy_options') || &cp || version < 700
"finish
"endif
"let loaded_mudox_color_toy_options = 1

let mudox#color_toy#options#Toy = {}
let s:Toy = mudox#color_toy#options#Toy " local shortened alias

function s:Toy.init() dict
    let self.filename = expand(get(g:, "color_toy_config_file",
                \ '~/.vim_color_toy'))
    let self.curVimColor = ''
    let self.curAirlineTheme = ''
    call self.loadConfig()
endfunction

function s:Toy.saveConfig() dict
    let l:lines = []
    for [l:cntx, l:score_board] in items(self.setting_pool)
        " skip empty boards.
        if empty(l:score_board)
            continue
        endif

        let l:line = l:cntx . ':'
        let l:list = []
        for [l:name, l:count] in items(l:score_board)
            let l:list = add(l:list, l:name . '#' . l:count)
        endfor
        let l:line = l:line . join(l:list, ',')
    endfor
    let l:lines = add(l:lines, l:line)
    echo l:lines
    call writefile(l:lines, self.filename)
endfunction

function s:Toy.loadConfig() dict
    if filereadable(self.filename)
        let l:lines = readfile(self.filename)

        " verify the content
        let l:line_pat = '^\m\C'
                    \ . '\%(gui\|term\)_'
                    \ . '\%(light\|dark\)_'
                    \ . '\%(\f\+\)_'
                    \ . '\%(vim\|airline\):'
        for l:line in l:lines
            if l:line !~# l:line_pat
                echoerr 'Invalied content in ' . expand(self.filename)
                return 0
            endif
        endfor

        for l:line in l:lines
            let l:cntx_and_score_board = split(l:line, ':')
            let l:cntx = l:cntx_and_score_board[0]
            let l:score_board = split(l:cntx_and_score_board[1], ',')

            let self.setting_pool = { l:cntx : {} }
            for l:record in l:score_board
                let [l:name, l:count] = split(l:record, '#')
                let self.setting_pool[l:cntx][l:name] = l:count
            endfor
        endfor
    else
        " set default options.
        let self.setting_pool = {}
    endif

endfunction

function s:Toy.curContext() dict
    let l:gui_or_term = has('gui_running') ? 'gui' : 'term'
    let l:light_or_dark = &background
    let l:filetype = len(&filetype) ? &filetype : 'untyped'
    return join([l:gui_or_term, l:light_or_dark, l:filetype], '_')
endfunction

function s:Toy.vimColorAvail() dict
    let l:list = split(globpath(&rtp, 'colors/*.vim', 1), '\n')
    call map(l:list, 'fnamemodify(v:val, ":t:r")')
    return l:list
endfunction

" TODO: panic if 'airline' is absent
function s:Toy.airlineThemeAvail() dict
    let l:list = split(globpath(&rtp, 'autoload/airline/themes/*.vim', 1), '\n')
    echo l:list
    call map(l:list, 'fnamemodify(v:val, ":t:r")')
    return l:list
endfunction

" TODO: reimplement it
function s:Toy.coloMarquee() dict
    " let l:cur_color = g:colors_name

    " for c in s:Toy.vim_color_avail
    " execute "colorscheme " . c
    " redraw
    " echo c
    " sleep 300m
    " endfor

    " restore previous colorscheme.
    " execute 'colorscheme ' . l:cur_color
endfunction

" TODO: adapt it to new host
function s:Toy.showCurColors() dict
    let l:msg = '[Vim] : ' . s:Toy.curVimColor
    if exists(':AirlineTheme') && len(s:Toy.curAirlineTheme) > 0
        let l:msg = l:msg . "\t\t[Airline] : " . s:Toy.curAirlineTheme
    endif

    echo l:msg
endfunction

" TODO: implementing, unfinished
function s:Toy.vimColorVirtualBoard() dict
    let l:virtual_board = {}
    " initialize all color with 0 count
    for l:name in self.vimColorAvail()
        let l:virtual_board[l:name] = 0
    endfor

    " merge recored scores into virtual board, for all
    " available colors.
    let l:recorded_board = self.curScoreBoard('vim')

    " panic and quit if not enough colorscheme are available.
    if len(l:recorded_board) <= 3
        echoerr 'Found colorscheme files: ' . join(l:recorded_board, ', ')
        echoerr 'Not enough colorscheme files found, need at least 4 colorscheme files.'
        throw "mudox#color_toy: Inadequate colorscheme files"
    endif

    for [l:name, l:count] in items(l:recorded_board)
        if has_key(l:virtual_board, l:name)
            let l:virtual_board[l:name] = l:count
        endif
    endfor

    " flatten the dictr to a list for sorting
    let l:score_list = []
    for [l:name, l:count] in items(l:virtual_board)
        let l:score_list = add(l:score_list, [l:name, l:count])
    endfor

    " sort by count in descending order
    function l:cntDesc(lhs, rhs)
        "return a:lhs[1] == a:rhs[1] ? 0 : a:lhs[1] > a:rhs[1] ? -1 : 1
        return -(a:lhs[1] - a:rhs[1])
    endfunction
    call sort(l:score_list, 'l:cntDesc')
    return l:score_list
endfunction

" TODO: unimplemented
function s:Toy.airlineVirtualBoard() dict
endfunction

" TODO: implement the new mechanism.
function s:Toy.old_shuffleColor() dict

    " pick a vim colorscheme first.
    let l:idx = localtime() % len(self.vimColorAvail)
    let self.curVimColor = self.vimColorAvail[l:idx]

    " if the there is a airline theme named as the picked vim colorscheme
    " above, use it, otherwise randomly pick a airline theme.
    if len(self.airlineThemeAvail) > 0
        if index(self.airlineThemeAvail, self.curVimColor) >= 0
            let self.curAirlineTheme = self.curVimColor
        else
            let l:idx = localtime() % len(self.airlineThemeAvail)
            let self.curAirlineTheme = self.airlineThemeAvail[l:idx]
        endif
    endif

    execute "colorscheme " . self.curVimColor

    if exists(':AirlineTheme') && len(self.curAirlineTheme) > 0
        execute "AirlineTheme " . self.curAirlineTheme
    endif

    redraw

    call self.showCurColors()

endfunction

" TODO: unfinished
function s:Toy.shuffleColor() dict
    let l:board_list = self.vimColorVirtualBoard()

    "for l:idx in range(len(l:score_list))
        "echo printf("%25s -> %3d  ", 
                    "\ l:score_list[l:idx][0], l:score_list[l:idx][1])
    "endfor

    " 6-3-1 scheme randomization.
    let l:len      = len(l:board_list)
    let l:delim_1  = float2nr(l:len * ( 1.0 / 10.0 ))
    let l:delim_2  = float2nr(l:len * ( 4.0 / 10.0 ))
    let low_queue  = l:board_list[              : l:delim_1]
    let mid_queue  = l:board_list[l:delim_1 + 1 : l:delim_2]
    let high_queue = l:board_list[l:delim_2 + 1 :          ]

    echo low_queue
    echo
    echo mid_queue
    echo
    echo high_queue

    " now let's shuffle up.

endfunction

function s:Toy.curScoreBoard(vim_or_airline) dict
    let l:cntx = self.curContext() . '_' . a:vim_or_airline

    " if empty, initiali it to {}.
    if !has_key(self.setting_pool, l:cntx)
        self.setting_pool[l:cntx] = {}
    endif

    return self.setting_pool[l:cntx]
endfunction

call s:Toy.init()

" public interface
"function mudox#auto_colo#ShuffleColor()
"call s:Toy.shuffleColor()
"endfunction

"let s:curCntx = s:Toy.curContext() . '_vim'
"let s:Toy.setting_pool[s:curCntx] = {
"\ 'desert'     : 23,
"\ 'desert_mdx' : 39,
"\ 'luna'       : 16,
"\ 'night'      : 11,
"\ 'jellybeans' : 25,
"\ 'molokai'    : 33,
"\ 'grubox'     : 18,
"\ 'blackboard' : 23,
"\ 'inkpot'     : 34,
"\ 'desertink'  : 60,
"\ 'autumn'     : 37,
"\ 'solarized'  : 28,
"\ 'default'    : 7,
"\ }

"echo s:Toy.setting_pool

"call s:Toy.saveConfig()

"echo s:Toy.curContext()

call s:Toy.shuffleColor()
