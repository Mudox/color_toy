if exists("loaded_color_toy_plugin_color_toy") || &cp || version < 700
  finish
endif
let loaded_color_toy_plugin_color_toy = 1

let s:Toy = {} " local shortened alias
let g:mdx = s:Toy   " for test 

function s:Toy.init() dict
  let self.fileName = expand(get(g:, "color_toy_stat_file",
        \ '~/.vim_color_toy'))

  let self.contextPattern = '^\m\C'
        \ . '\%(gui\|term\)_'
        \ . '\%(light\|dark\)_'
        \ . '\%(\f\+\)_'
        \ . '\%(vim\|airline\)'

  let self.lastContext = self.curContext()
  let self.lastVimColor = self.getCurVimColor()

  let self.lastAirlineTheme = ''
  let self.stat_pool = {}

  call self.loadStat()

  call self.incrementPoint(self.lastContext, self.lastVimColor)
endfunction

function s:Toy.saveStat() dict
  let l:lines = []
  "echo self.stat_pool | " test
  for [l:cntx, l:score_board] in items(self.stat_pool)
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
  call writefile(l:lines, self.fileName)
endfunction

function s:Toy.loadStat() dict
  if filereadable(self.fileName)
    let l:lines = readfile(self.fileName)

    " verify the content
    for l:line in l:lines
      if l:line !~# self.contextPattern
        echoerr 'Invalied content in ' . expand(self.fileName)
        return 0
      endif
    endfor

    for l:line in l:lines
      let l:cntx_and_score_board = split(l:line, ':')
      let l:cntx = l:cntx_and_score_board[0]
      let l:score_board = split(l:cntx_and_score_board[1], ',')

      let self.stat_pool[l:cntx] = {}
      for l:record in l:score_board
        let [l:name, l:count] = split(l:record, '#')
        let self.stat_pool[l:cntx][l:name] = l:count
      endfor
    endfor
  endif
endfunction

function s:Toy.curContext() dict
  let l:gui_or_term = has('gui_running') ? 'gui' : 'term'
  let l:light_or_dark = &background
  let l:filetype = len(&filetype) ? &filetype : 'untyped'

  " TODO: currently only implement vim part, left airline part for next time.
  return join([l:gui_or_term, l:light_or_dark, l:filetype, 'vim'], '_')
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

  let l:recorded_board = self.getScoreBoard(self.curContext())

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
  " build virtual score board & exclud last color from it.
  let l:board = self.vimColorVirtualBoard()
  unlet l:board[self.lastVimColor]

  " 6-3-1 scheme randomization.
  let l:len        = len(l:board)
  let l:delim_1    = float2nr(l:len * ( 1.0 / 10.0 ))
  let l:delim_2    = float2nr(l:len * ( 4.0 / 10.0 ))
  let l:high_queue = l:board[              : l:delim_1]
  let l:mid_queue  = l:board[l:delim_1 + 1 : l:delim_2]
  let l:low_queue  = l:board[l:delim_2 + 1 :          ]

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

function s:Toy.getScoreBoard(context) dict
  if a:context !~# self.contextPattern
    throw 's:Toy.getScoreBoard(context) gots an invalid a:context string'
  endif

  " if empty, initiali it to {}.
  if !has_key(self.stat_pool, a:context)
    let self.stat_pool[a:context] = {}
  endif

  return self.stat_pool[a:context]
endfunction

function s:Toy.getPoint(context, name) dict
  if a:context !~# self.contextPattern
    throw 's:Toy.getPoint(context, name) gots an invalid a:context string'
  endif

  let l:board = self.getScoreBoard(a:context)
  if !has_key(l:board, a:name)
    let l:board[a:name] = 0
  endif
  return l:board[a:name]
endfunction

function s:Toy.onColorScheme() dict
  let l:new_color = self.getCurVimColor()
  "echo self.stat_pool | " test

  " decrement old color's point.
  call self.decrementPoint(self.lastContext, self.lastVimColor)

  let l:old_color = self.lastVimColor
  let self.lastVimColor = l:new_color
  let self.lastContext = self.curContext()

  " increment new color's point.
  call self.incrementPoint(self.curContext(), l:new_color)

  echo printf("Toy.onColorScheme() called: %s -> %s", l:old_color, l:new_color)
endfunction

function s:Toy.onVimEnter() dict
  call self.nextVimColor()
  call self.onColorScheme()
endfunction

function s:Toy.getCurVimColor() dict
  if !exists('g:colors_name')
    throw 'g:colors_name not exists, syn off?'
  endif
  return g:colors_name
endfunction

function s:Toy.setPoint(context, name, point) dict
  if a:context !~# self.contextPattern
    throw 's:Toy.setPoint(context, name) gots an invalid a:context string'
  endif

  if empty(a:name)
    echoerr 'Empty name arg for setPoint()'
    return
  endif
  let l:board = self.getScoreBoard(a:context)
  let l:board[a:name] = a:point
endfunction

function s:Toy.incrementPoint(context, name) dict
  if a:context !~# self.contextPattern
    throw 's:Toy.incrementPoint(context, name) gots an invalid a:context string'
  endif


  if empty(a:name)
    echoerr 'Empty name arg for incrementPoint()'
    return
  endif

  call self.setPoint(a:context, a:name, 
        \ max([0, self.getPoint(a:context, a:name) + 1])
        \ )
endfunction

function s:Toy.decrementPoint(context, name) dict
  if a:context !~# self.contextPattern
    throw 's:Toy.decrementPoint(context, name) gots an invalid a:context string'
  endif

  if empty(a:name)
    echoerr 'Empty name arg for decrementPoint()'
    return
  endif

  call self.setPoint(a:context, a:name, 
        \ max([0, self.getPoint(a:context, a:name) - 1])
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

call s:Toy.init()

function <SID>NextVimColor() 
  call s:Toy.nextVimColor() 
endfunction

function <SID>ShowCurColors() 
  call s:Toy.showCurColors() 
endfunction

nnoremap <Plug>(Mdx_Color_Toy_NextColor)  :<C-U>call <SID>NextVimColor()<Cr>
nnoremap <Plug>(Mdx_Color_Toy_ShowCurColors)  :<C-U>call <SID>ShowCurColors()<Cr>

augroup Mdx_Color_Toy
  autocmd!
  autocmd ColorScheme * call s:Toy.onColorScheme()
  autocmd VimLeavePre * call s:Toy.saveStat()
  autocmd VimEnter    * call s:Toy.onVimEnter()
augroup END
