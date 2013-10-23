if exists('loaded_mudox_color_toy_options') || &cp || version < 700
    finish
endif
let loaded_mudox_color_toy_options = 1

if !exists('g:color_toy_config_file')
    let g:color_toy_config_file = '~/.vim_color_toy'
endif

let mudox#color_toy#options#dict = {}
let s:opt = mudox#color_toy#options#dict " local shortened alias

function s:opt.Save() dict
    let l:lines = []
    for [k, v] in items(self.setting_pool)
        l:lines =  add(l:lines, k . ':' . join(v, ','))
    endfor
    echo l:lines
    call writefile(l:lines, self.filename)
endfunction

function s:opt.Load() dict
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

function s:opt.Hate_it(dict) dict

endfunction

function s:opt.Like_it(dict) dict

endfunction

function s:opt.Reset_it(dict) dict

endfunction

function s:opt.Init(dict) dict
    let self.filename = expand(get(g:, "color_toy_config_file",
                \ '~/.vim_color_toy'))
    let self.Load()
endfunction

s:opt.Init()
