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
  let self.lastVimColor = self.getCurVimColor()
  let self.lastAirlineTheme = ''
  let self.setting_pool = {}
  call self.loadConfig()
endfunction

function s:Toy.saveConfig() dict
  let l:lines = []
  "echo self.setting_pool | " test
  for [l:cntx, l:score_board] in items(self.setting_pool)
    " skip all virtually empty boards.
    call filter(l:score_board, 'v:val != 0')
    if empty(l:score_board)
      continue
    endif

    let l:line = l:cntx . ':'
    let l:list = []
    for [l:name, l:count] in items(l:score_board)
      let l:list = add(l:list, l:name . '#' . l:count)
    endfor
    let l:line = l:line . join(l:list, ',')
    let l:lines = add(l:lines, l:line)
  endfor
  "echo l:lines | " test 
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

      let self.setting_pool[l:cntx] = {}
      for l:record in l:score_board
	let [l:name, l:count] = split(l:record, '#')
	let self.setting_pool[l:cntx][l:name] = l:count
      endfor
    endfor
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

function s:Toy.airlineThemeAvail() dict
  let l:list = split(globpath(&rtp, 'autoload/airline/themes/*.vim', 1), '\n')
  echo l:list
  call map(l:list, 'fnamemodify(v:val, ":t:r")')
  return l:list
endfunction

function s:Toy.vimColorVirtualBoard() dict
  let l:virtual_board = {}
  " initialize all color with 0 count
  for l:name in self.vimColorAvail()
    let l:virtual_board[l:name] = 0
  endfor

  let l:recorded_board = self.curScoreBoard('vim')

  " panic and quit if not enough colorscheme are available.
  if len(l:virtual_board) <= 3
    echoerr 'Found colorscheme files: ' . join(l:virtual_board, ', ')
    echoerr 'Not enough colorscheme files found, need at least 4 colorscheme files.'
    throw "mudox#color_toy: Inadequate colorscheme files"
  endif

  " merge recored scores into virtual board, for all
  " available colors.
  for [l:name, l:count] in items(l:recorded_board)
    if has_key(l:virtual_board, l:name)
      let l:virtual_board[l:name] = l:count
    endif
  endfor

  "echo l:virtual_board
  " flatten the dict to a list for sorting
  let l:score_list = []
  for [l:name, l:count] in items(l:virtual_board)
    let l:score_list = add(l:score_list, [l:name, l:count])
  endfor

  " sort by count in descending order
  call sort(l:score_list, 's:cntDesc')
  return l:score_list
endfunction

function s:cntDesc(lhs, rhs)
  "return a:lhs[1] == a:rhs[1] ? 0 : a:lhs[1] > a:rhs[1] ? -1 : 1
  return -(a:lhs[1] - a:rhs[1])
endfunction

function s:Toy.roll() dict
  let l:board = self.vimColorVirtualBoard()

  "for l:idx in range(len(l:board))
  "echo printf("%25s -> %3d  ", 
  "\ l:board[l:idx][0], l:board[l:idx][1])
  "endfor

  " 6-3-1 scheme randomization.
  let l:len        = len(l:board)
  let l:delim_1    = float2nr(l:len * ( 1.0 / 10.0 ))
  let l:delim_2    = float2nr(l:len * ( 4.0 / 10.0 ))
  let l:high_queue = l:board[              : l:delim_1]
  let l:mid_queue  = l:board[l:delim_1 + 1 : l:delim_2]
  let l:low_queue  = l:board[l:delim_2 + 1 :          ]

  "echo l:low_queue
  "echo
  "echo l:mid_queue
  "echo
  "echo l:high_queue

  " now let's shuffle up.
  let l:dice = localtime() % 10
  if l:dice < 6                 " 60% chance
    let l:pool = l:high_queue
  elseif l:dice < 9             " 30% chance
    let l:pool = l:mid_queue
  else                          " 10% chance
    let l:pool = l:low_queue
  endif

  let l:win_num = localtime() % len(l:pool)
  return l:pool[l:win_num][0] " only return color name.
endfunction

function s:Toy.curScoreBoard(vim_or_airline) dict
  if a:vim_or_airline !~# '\mvim\|airline'
    throw 's:Toy.curScoreBoard() needs a string "vim" or "airline" as its argument'
  endif

  let l:cntx = self.curContext() . '_' . a:vim_or_airline

  " if empty, initiali it to {}.
  if !has_key(self.setting_pool, l:cntx)
    let self.setting_pool[l:cntx] = {}
  endif

  return self.setting_pool[l:cntx]
endfunction

function s:Toy.getPoint(vim_or_arline, name) dict
  let l:board = self.curScoreBoard(a:vim_or_arline)
  if !has_key(l:board, a:name)
    let l:board[a:name] = 0
  endif
  return l:board[a:name]
endfunction

function s:Toy.onColorScheme() dict
  let l:new_color = self.getCurVimColor()
  "echo self.setting_pool | " test

  " decrement old color's point.
  call self.decrementPoint('vim', self.lastVimColor)
  let self.lastVimColor = l:new_color

  " increment new color's point.
  call self.incrementPoint('vim', l:new_color)

  "echo self.setting_pool | " test
endfunction

function s:Toy.getCurVimColor() dict
  if !exists('g:colors_name')
    throw 'g:colors_name not exists, syn off?'
  endif
  return g:colors_name
endfunction

function s:Toy.setPoint(vim_or_arline, name, point) dict
  if empty(a:name)
    echoerr 'Empty name arg for setPoint()'
    return
  endif
  let l:board = self.curScoreBoard(a:vim_or_arline)
  let l:board[a:name] = a:point
endfunction

function s:Toy.incrementPoint(vim_or_airline, name) dict
  if empty(a:name)
    echoerr 'Empty name arg for incrementPoint()'
    return
  endif
  call self.setPoint(a:vim_or_airline, a:name, 
	\ max([0, self.getPoint(a:vim_or_airline, a:name) + 1])
	\ )
endfunction

function s:Toy.decrementPoint(vim_or_airline, name) dict
  if empty(a:name)
    echoerr 'Empty name arg for decrementPoint()'
    return
  endif
  call self.setPoint(a:vim_or_airline, a:name, 
	\ max([0, self.getPoint(a:vim_or_airline, a:name) - 1])
	\ )
endfunction

function s:Toy.nextVimColor() dict
  let l:picked = self.roll()
  execute 'colorscheme ' . l:picked
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
  let l:msg = '[Vim] : ' . self.getCurVimColor()
  if exists(':AirlineTheme') && len(self.lastAirlineTheme) > 0
    let l:msg = l:msg . "\t\t[Airline] : " . self.lastAirlineTheme
  endif

  echo l:msg
endfunction

" TODO: unimplemented
function s:Toy.airlineVirtualBoard() dict
endfunction

" public interface
function mudox#color_toy#NextColor()
  call s:Toy.roll()
endfunction

call s:Toy.init()
