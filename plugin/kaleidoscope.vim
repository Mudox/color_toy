" vim: foldmethod=marker

" GUARD                                                                                {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" S:CORE -- THE CORE OBJECT                                                            {{{1

let s:core = {} " local shortened alias
let g:mdx_kaleidoscope = s:core   " for test

function s:core.init() dict                                                             " {{{2
  let self.fileName = expand(get(g:, "kaleidoscope_stat_file",
        \ '~/.vim_kaleidoscope'))
  let self.background = expand(get(g:, "kaleidoscope_backgroud",
        \ 'dark'))

  let self.contextPattern = '\m\C^'
        \ . '\%(gui\|term\)_'
        \ . '\%(\f\+\)'
  let self.statLinePattern = '\m\C^'
        \ . '\s*'
        \ . '\(\d+\)'      " count
        \ . ' -- '
        \ . '\(\w\+\)$'    " color name

  let self.lastContext = self.getCurContext()
  let self.lastColor = self.getCurColor()

  let self.stat_pool = {}

  call self.loadStat()

  call self.incrementPoint(self.lastContext, self.lastColor)
endfunction " }}}2

function s:core.saveStat() dict                                                         " {{{2
  let lines = []
  for [cntx, score_board] in items(self.stat_pool)
    let line = cntx . ':'
    let list = []

    if len(score_board) == 0
      continue
    endif

    for [name, cnt] in items(score_board)
      let list = add(list, name . '#' . cnt)
    endfor

    let line = line . join(list, ',')
    let lines = add(lines, line)
  endfor

  call writefile(lines, self.fileName)
endfunction " }}}2

function s:core.loadStat() dict                                                         " {{{2
  if filereadable(self.fileName)
    let lines = readfile(self.fileName)

    " verify the content
    for line in lines
      if line !~# self.contextPattern
        echoerr 'Invalied content in ' . expand(self.fileName)
        return 0
      endif
    endfor

    for line in lines
      let cntx_and_score_board = split(line, ':')

      if len(cntx_and_score_board) != 2
        continue
      endif

      let cntx = cntx_and_score_board[0]
      let score_board = split(cntx_and_score_board[1], ',')

      let self.stat_pool[cntx] = {}
      for record in score_board
        let [name, cnt] = split(record, '#')
        if cnt !~ '\m[0-9]\+'
          echoerr 'Invalid count string in ' . expand(self.fileName)
        endif
        let cnt = str2nr(cnt) " will return 0 in case a invalid string.
        let self.stat_pool[cntx][name] = cnt
      endfor
    endfor
  endif
endfunction " }}}2

function s:core.resetStat() dict                                                        " {{{2
  " clear statistic file and s:core.stat_pool.

  call delete(self.fileName)
  call self.init()
endfunction " }}}2

" return a string in the form: '[gui|term]_<filetype>', indicating current
" context.
function s:core.getCurContext() dict                                                    " {{{2
  let gui_or_term = has('gui_running') ? 'gui' : 'term'
  let file_type = len(&filetype) ? &filetype : 'untyped'

  return gui_or_term . '_' . file_type
endfunction " }}}2

function s:core.colorsAvail() dict                                                      " {{{2
  let list = split(globpath(&rtp, 'colors/*.vim', 1), '\n')
  call map(list, 'fnamemodify(v:val, ":t:r")')

  return list
endfunction " }}}2

" return a list of (name, count) binary tuples, sorted by count in descending
" order.
function s:core.getInnerBoardSorted(context) dict                                       " {{{2
  return s:dict2SortedList(self.getInnerBoard(a:context))
endfunction " }}}2

" raturn a list of (name, count) binary turples of all available colors.
function s:core.getVirtualBoardSorted() dict                                            " {{{2
  let virtual_board = {}
  " initialize all color with 0 cnt
  for name in self.colorsAvail()
    let virtual_board[name] = 0
  endfor

  let recorded_board = self.getInnerBoard(self.getCurContext())

  " panic and quit if not enough colorschemes are available.
  if len(virtual_board) <= 3
    echoerr 'Found colorscheme files: ' . join(virtual_board, ', ')
    echoerr 'Not enough colorscheme files found, need at least 4 colorscheme files.'
    throw "mudox#kaleidoscope: Inadequate colorscheme files"
  endif

  " merge recored scores into virtual board, for all
  " available colors.
  for [name, cnt] in items(recorded_board)
    if has_key(virtual_board, name)
      let virtual_board[name] = cnt
    endif
  endfor

  " flatten the dict to a list for sorting
  return s:dict2SortedList(virtual_board)
endfunction " }}}2

function s:cntDesc(lhs, rhs)                                                            " {{{2
  " used by s:core.roll() below to sort color points records by their point in
  " descending order.

  return -(a:lhs[1] - a:rhs[1])
endfunction " }}}2

function s:dict2SortedList(the_dict)                                                    " {{{2
  " flatten the dict to a list for sorting
  let sorted_list = []
  for [name, cnt] in items(a:the_dict)
    let sorted_list = add(sorted_list, [name, cnt])
  endfor

  " sort by cnt in descending order
  call sort(sorted_list, 's:cntDesc')
  return sorted_list
endfunction " }}}2

function s:core.roll() dict                                                             " {{{2
  " build virtual score board & exclud last color from it.
  let board = self.getVirtualBoardSorted()

  " exclude current (old) color.
  call filter(board, 'v:val[0] != "' . self.lastColor . '"')

  " exclude banned colors.
  call filter(board, 'v:val[1] >= 0')

  " 6-3-1 scheme randomization.
  let len        = len(board)
  let delim_1    = float2nr(len * ( 1.0 / 10.0 ))
  let delim_2    = float2nr(len * ( 4.0 / 10.0 ))
  let high_queue = board[              : delim_1]
  let mid_queue  = board[delim_1 + 1   : delim_2]
  let low_queue  = board[delim_2 + 1   :        ]

  " now let's shuffle up.
  let dice = localtime() % 10
  if dice < 6                 " 60% chance
    let pool = high_queue
  elseif dice < 9             " 30% chance
    let pool = mid_queue
  else                        " 10% chance
    let pool = low_queue
  endif

  let win_num = localtime() % len(pool)
  return pool[win_num][0] " only return color name.
endfunction " }}}2

function s:core.getInnerBoard(context) dict                                             " {{{2
  " arguemnts check
  if a:context !~# self.contextPattern
    throw 's:core.getInnerBoard(context) gots an invalid a:context string'
  endif

  " sync from disk.
  call self.loadStat()

  " if not exist, initiali it to {}.
  if !has_key(self.stat_pool, a:context)
    let self.stat_pool[a:context] = {}
  endif

  return self.stat_pool[a:context]
endfunction " }}}2

function s:core.getCurColor() dict                                                      " {{{2
  return exists('g:colors_name') ? g:colors_name : 'default'
endfunction " }}}2

function s:core.getPoint(context, name) dict                                            " {{{2
  if a:context !~# self.contextPattern
    throw 's:core.getPoint(context, name) gots an invalid a:context string'
  endif

  let board = self.getInnerBoard(a:context)
  if !has_key(board, a:name)
    let board[a:name] = 0
  endif
  return board[a:name]
endfunction " }}}2

function s:core.setPoint(context, name, point) dict                                     " {{{2
  " arguments check
  if a:context !~# self.contextPattern
    throw 's:core.setPoint(context, name) gots an invalid a:context string'
  endif

  if empty(a:name)
    echoerr 'Got empty name arg for s:core.setPoint()'
    return
  endif

  if a:0 != 1 && a:0 != 0
    echo a:0
    echoerr 'Invalid number of unnamed arguments given to s:core.setPoint()'
    return
  elseif a:0 == 1 && a:1 !=# 'nosave'
    echoerr 'Invalid unnamed argumetn for s:core.setPoint(), needs "nosave"'
    return
  endif


  let board = self.getInnerBoard(a:context)
  let board[a:name] = a:point

  call self.saveStat()
endfunction " }}}2

function s:core.banColor(context, name) dict                                            " {{{2
  call self.setPoint(a:context, a:name, -1)
endfunction " }}}2

" reset the point of current vim color and roll to next color.
function s:core.banCurColor() dict                                                      " {{{2
  call self.banColor(self.getCurContext(), self.getCurColor())
  call self.colorRandom()
endfunction " }}}2

function s:core.incrementPoint(context, name) dict                                      " {{{2
  " arguments check
  if a:context !~# self.contextPattern
    throw 's:core.incrementPoint(context, name) gots an invalid a:context string'
  endif

  if empty(a:name)
    echoerr 'Empty name arg for incrementPoint()'
    return
  endif

  let oldPnt = self.getPoint(a:context, a:name)
  if oldPnt != -1
    call self.setPoint(a:context, a:name, oldPnt + 1)
  else
    echo printf("color [%s] is already banned in context [%s].",
          \ a:name, a:context)
  endif
endfunction " }}}2

function s:core.decrementPoint(context, name) dict                                      " {{{2
  if a:context !~# self.contextPattern
    throw 's:core.decrementPoint(context, name) gots an invalid a:context string'
  endif

  if empty(a:name)
    echoerr 'Empty name arg for decrementPoint()'
    return
  endif

  let oldPnt = self.getPoint(a:context, a:name)
  if oldPnt > 0
    call self.setPoint(a:context, a:name, oldPnt - 1)
  else
    echo printf("the count of color [%s] is already 0 in context [%s]",
          \ a:name, a:context)
  endif
endfunction " }}}2

function s:core.colorRandom() dict                                                      " {{{2
  let picked = self.roll()
  execute 'colorscheme ' . picked
endfunction " }}}2

function s:core.showCurColors() dict                                                    " {{{2
  " make sure current color in current context gain at least 1 point.
  let name           = self.getCurColor()
  let context        = self.getCurContext()
  let points         = self.getPoint(context, name)
  let context_string = substitute(context, '_', ' | ', 'g')
  let msg            = printf("[Vim] : %s #%d in [%s]",
        \ name, points, context_string)

  echo msg
endfunction " }}}2

function s:core.editColorFile(name)                                                     " {{{2
  let paths = split(globpath(&rtp, printf('colors/%s.vim', a:name), 1), "\n")
  if len(paths) == 0
    throw printf('color file [%s] not found in &rtp.', a:name)
  elseif len(paths) != 1
    echo printf("found multiple files: %s.\nedit the first one.", paths)
  endif

  call mudox#query_open_file#New(paths[0])
endfunction " }}}2

" TODO: reimplement it
function s:core.coloMarquee() dict                                                      " {{{2
  " let cur_color = g:colors_name

  " for c in s:core.vim_color_avail
  " execute "colorscheme " . c
  " redraw
  " echo c
  " sleep 300m
  " endfor

  " restore previous colorscheme.
  " execute 'colorscheme ' . cur_color
endfunction " }}}2

" autocmd callback functions.

function s:core.onColorScheme() dict                                                    " {{{2
  let new_color = self.getCurColor()
  let old_color = self.lastColor

  call self.decrementPoint(self.lastContext, self.lastColor)

  let self.lastColor = new_color
  let self.lastContext = self.getCurContext()

  call self.incrementPoint(self.lastContext, self.lastColor)

  let &background = self.background

  redraw
  echo printf("color switched: %s[%d] -> %s[%d]",
        \ old_color, self.getPoint(self.getCurContext(), old_color),
        \ new_color, self.getPoint(self.getCurContext(), new_color)
        \ )
endfunction " }}}2

function s:core.onVimEnter() dict                                                       " {{{2
  call self.colorRandom()
  " by default, vim event dost no allow nesting.
  " simulate ColorScheme that the above .colorRandom() call would incur.
  call self.onColorScheme()
  
  if exists(':AirlineTheme')
    AirlineTheme ubaryd
  endif

  redraw
  call self.showCurColors()
endfunction " }}}2

function s:core.onVimLeavePre() dict                                                    " {{{2
  if self.lastContext !=# self.getCurContext()
    call self.decrementPoint(self.lastContext, self.lastColor)
    call self.incrementPoint(self.getCurContext(), self.lastColor)
  endif
endfunction " }}}2

call s:core.init()

"}}}1

" PUBLIC INTERFACES                                                                    {{{1

function <SID>NextColor()                                                               " {{{2
  call s:core.colorRandom()
endfunction " }}}2

function <SID>ShowCurColors()                                                           " {{{2
  call s:core.showCurColors()
endfunction " }}}2

function <SID>Ban()                                                                     " {{{2
  call s:core.banCurColor()
endfunction " }}}2

function <SID>EditCurrentColor()                                                        " {{{2
  try
    let name = s:core.getCurColor()
    call s:core.editColorFile(name)
  catch /^mudox#query_open_file: Canceled$/
    echohl WarningMsg | echo '* EditCurrentColor: Canceled *' | echohl None
  endtry
endfunction " }}}2

nnoremap <Plug>(Mdx_Kaleidoscope_NextColor)
      \ <Esc>:call <SID>NextColor()<Cr>
nnoremap <Plug>(Mdx_Kaleidoscope_ShowCurColors)
      \ <Esc>:call <SID>ShowCurColors()<Cr>
nnoremap <Plug>(Mdx_Kaleidoscope_Hate)
      \ <Esc>:call <SID>Ban()<Cr>
nnoremap <Plug>(Mdx_Kaleidoscope_View)
      \ <Esc>:call mudox#kaleidoscope#view#open(g:mdx_kaleidoscope.getCurContext())<Cr>
nnoremap <Plug>(Mdx_Kaleidoscope_View_All)
      \ <Esc>:call mudox#kaleidoscope#view#open('all')<Cr>
nnoremap <Plug>(Mdx_Kaleidoscope_Edit_Current_Color)
      \ <Esc>:call <SID>EditCurrentColor()<Cr>

augroup Mdx_Kaleidoscope
  autocmd!
  autocmd ColorScheme * call s:core.onColorScheme()
  autocmd VimLeavePre * call s:core.onVimLeavePre()
  autocmd VimEnter    * call s:core.onVimEnter()
augroup END

command -nargs=0 KaleidoscopeReset call s:core.resetStat()
"}}}
