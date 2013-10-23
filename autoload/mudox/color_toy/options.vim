if exists('loaded_mudox_color_toy_options') || &cp || version < 700
    finish
endif
let loaded_mudox_color_toy_options = 1

if !exists('g:color_toy_config_file')
    let g:color_toy_config_file = '~/.vim_color_toy'
endif

let mudox#color_toy#options#dict = {}
let s:opt = mudox#color_toy#options#dict " local shortened alias

function s:opt.saveConfig() dict " TODO: test it 
    let l:lines = []
    for [k, v] in items(self.setting_pool)
        l:lines =  add(l:lines, k . ':' . join(v, ','))
    endfor
    echo l:lines
    call writefile(l:lines, self.filename)
endfunction

function s:opt.loadConfig() dict " TODO: test it 
    if filereadable(self.filename)
        let l:lines = readfile(self.filename)

        " verify the content
        let g:line_pat = '^\m\(gui\|term\)_'
                    \ . '\(light\|dark\)_' .
                    \ . '\(\f\+\|untyped buffer\)_'
                    \ . '\(vim\|airline\)_'
                    \ . '\(black\|white\):'
        for l:x in l:lines
            if l:x !~# l:line_pat
                echoerr 'Invalied content in ' . expand(g:color_toy_config_file)
                return 0
            endif
        endfor

        for l:x in l:lines
            let l:head_and_list = split(l:x, ':')
            let l:head = l:head_and_list[0]
            let l:list = split(l:head_and_list[1], ',')
            self.setting_pool[l:head] = l:list
        endfor
    else
        " set default options.

    endif

endfunction

function s:opt.Context() dict
    let l:gui_or_term = has('gui_running') ? 'gui' : 'term'
    let l:light_or_dark = &background
    let l:filetype = len(&filetype) ? &filetype : 'untyped buffer'
    return [l:gui_or_term, l:light_or_dark, l:filetype]
endfunction

function s:opt.vimColorAvail(dict) dict " TODO: test it 
    let l:list = split(globpath(&rtp, 'colors/*.vim', 1), '\n')
    call map(l:list, 'fnamemodify(v:val, ":t:r")')
endfunction

function s:opt.airlineThemeAvail(dict) dict
    let l:list = split(globpath(&rtp, 'autoload/airline/themes/*.vim', 1), '\n')
    call map(l:list, 'fnamemodify(v:val, ":t:r")')
endfunction

function s:opt.Init(dict) dict " TODO: test it 
    let self.filename = expand(get(g:, "color_toy_config_file",
                \ '~/.vim_color_toy'))
    let self.curVimColor = ''
    let self.curAirlineTheme = ''
    let self.loadConfig()
endfunction

function mudox#auto_colo#ColoMarquee() " TODO: reimplement it 
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

function s:Toy.showCurColors() dict " TODO: adapt it to new host   

    let l:msg = '[Vim] : ' . s:Toy.curVimColor
    if exists(':AirlineTheme') && len(s:Toy.curAirlineTheme) > 0
        let l:msg = l:msg . "\t\t[Airline] : " . s:Toy.curAirlineTheme
    endif

    echo l:msg
endfunction

function s:Toy.shuffleColor() dict " TODO: implement the new mechanism. 

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

s:opt.Init()

" public interface 
function mudox#auto_colo#ShuffleColor()
    call s:Toy.shuffleColor()
endfunction
