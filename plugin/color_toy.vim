if exists("loaded_color_toy_plugin_color_toy") || &cp || version < 700
  finish
endif
let loaded_color_toy_plugin_color_toy = 1

" s:Toy -- the core object                          {{{1

let s:Toy = {} " local shortened alias
let g:mdx = s:Toy   " for test

function s:Toy.init() dict "                           {{{2
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
endfunction " }}}2

function s:Toy.saveStat() dict "                       {{{2
  if self.lastContext !=# self.curContext()
    call self.decrementPoint(self.lastContext, self.lastVimColor)
    call self.incrementPoint(self.curContext(), self.lastVimColor)
  endif

  let lines = []
  for [cntx, score_board] in items(self.stat_pool)
    " skip all virtually empty items.
    call filter(score_board, 'v:val != 0')
    if empty(score_board)
      continue
    endif

    let line = cntx . ':'
    let list = []
    for [name, cnt] in items(score_board)
      let list = add(list, name . '#' . cnt)
    endfor
    let line = line . join(list, ',')
    let lines = add(lines, line)
  endfor

  call writefile(lines, self.fileName)
endfunction " }}}2

function s:Toy.loadStat() dict "                       {{{2
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
      let cntx = cntx_and_score_board[0]
      let score_board = split(cntx_and_score_board[1], ',')

      let self.stat_pool[cntx] = {}
      for record in score_board
        let [name, cnt] = split(record, '#')
        if cnt !~ '\m[0-9]\+'
          echoerr 'Invalid count string in ' . expand(self.fileName)
        endif
        let cnt = str2nr(cnt) " return 0 in case a invalid string.
        let self.stat_pool[cntx][name] = cnt
      endfor
    endfor
  endif
endfunction " }}}2

function s:Toy.resetStat() dict "                      {{{2
  " clear statistic file and s:Toy.stat_pool.

  call delete(self.fileName)
  call self.init()
endfunction " }}}2

function s:Toy.curContext() dict "                     {{{2
  let gui_or_term = has('gui_running') ? 'gui' : 'term'
  let light_or_dark = &background
  let filetype = len(&filetype) ? &filetype : 'untyped'

  " TODO: currently only implement vim part, left airline part for next time.
  return join([gui_or_term, light_or_dark, filetype, 'vim'], '_')
endfunction " }}}2

function s:Toy.vimColorAvail() dict "                  {{{2
  let list = split(globpath(&rtp, 'colors/*.vim', 1), '\n')
  call map(list, 'fnamemodify(v:val, ":t:r")')

  return list
endfunction " }}}2

function s:Toy.airlineThemeAvail() dict "              {{{2
  let list = split(globpath(&rtp, 'autoload/airline/themes/*.vim', 1), '\n')
  echo list
  call map(list, 'fnamemodify(v:val, ":t:r")')
  return list
endfunction " }}}2

function s:Toy.vimColorVirtualBoard() dict "           {{{2
  let virtual_board = {}
  " initialize all color with 0 cnt
  for name in self.vimColorAvail()
    let virtual_board[name] = 0
  endfor

  let recorded_board = self.getScoreBoard(self.curContext())

  " panic and quit if not enough colorscheme are available.
  if len(virtual_board) <= 3
    echoerr 'Found colorscheme files: ' . join(virtual_board, ', ')
    echoerr 'Not enough colorscheme files found, need at least 4 colorscheme files.'
    throw "mudox#color_toy: Inadequate colorscheme files"
  endif

  " merge recored scores into virtual board, for all
  " available colors.
  for [name, cnt] in items(recorded_board)
    if has_key(virtual_board, name)
      let virtual_board[name] = cnt
    endif
  endfor

  "echo virtual_board
  " flatten the dict to a list for sorting
  let score_list = []
  for [name, cnt] in items(virtual_board)
    let score_list = add(score_list, [name, cnt])
  endfor

  " sort by cnt in descending order
  call sort(score_list, 's:cntDesc')
  return score_list
endfunction " }}}2

function s:cntDesc(lhs, rhs) "                         {{{2
  " used by s:Toy.roll() below to sort color points records by their point in
  " descending order.

  return -(a:lhs[1] - a:rhs[1])
endfunction " }}}2

function s:Toy.roll() dict "                           {{{2
  " build virtual score board & exclud last color from it.
  let board = self.vimColorVirtualBoard()
  unlet board[self.lastVimColor]

  " 6-3-1 scheme randomization.
  let len        = len(board)
  let delim_1    = float2nr(len * ( 1.0 / 10.0 ))
  let delim_2    = float2nr(len * ( 4.0 / 10.0 ))
  let high_queue = board[              : delim_1]
  let mid_queue  = board[delim_1 + 1 : delim_2]
  let low_queue  = board[delim_2 + 1 :          ]

  " now let's shuffle up.
  let dice = localtime() % 10
  if dice < 6                 " 60% chance
    let pool = high_queue
  elseif dice < 9             " 30% chance
    let pool = mid_queue
  else                          " 10% chance
    let pool = low_queue
  endif

  let win_num = localtime() % len(pool)
  return pool[win_num][0] " only return color name.
endfunction " }}}2

function s:Toy.getScoreBoard(context) dict "           {{{2
  if a:context !~# self.contextPattern
    throw 's:Toy.getScoreBoard(context) gots an invalid a:context string'
  endif

  " if empty, initiali it to {}.
  if !has_key(self.stat_pool, a:context)
    let self.stat_pool[a:context] = {}
  endif

  return self.stat_pool[a:context]
endfunction " }}}2

function s:Toy.getPoint(context, name) dict "          {{{2
  if a:context !~# self.contextPattern
    throw 's:Toy.getPoint(context, name) gots an invalid a:context string'
  endif

  let board = self.getScoreBoard(a:context)
  if !has_key(board, a:name)
    let board[a:name] = 0
  endif
  return board[a:name]
endfunction " }}}2

function s:Toy.onColorScheme() dict "                  {{{2
  let new_color = self.getCurVimColor()
  "echo self.stat_pool | " test

  " decrement old color's point.
  call self.decrementPoint(self.lastContext, self.lastVimColor)

  let old_color = self.lastVimColor
  let self.lastVimColor = new_color
  let self.lastContext = self.curContext()

  " increment new color's point.
  call self.incrementPoint(self.curContext(), new_color)

  redraw
  echo printf("color switched: %s[%d] -> %s[%d]",
        \ old_color, self.getPoint(self.curContext(), old_color),
        \ new_color, self.getPoint(self.curContext(), new_color)
        \ )
endfunction " }}}2

function s:Toy.onVimEnter() dict "                     {{{2
  call self.nextVimColor()
  " by default, vim event dost no allow nesting.
  " simulate ColorScheme that the above .nextVimColor() call would incur.
  call self.onColorScheme()
  redraw
  call self.showCurColors()
endfunction " }}}2

function s:Toy.getCurVimColor() dict "                 {{{2
  if !exists('g:colors_name')
    throw 'g:colors_name not exists, syn off?'
  endif
  return g:colors_name
endfunction " }}}2

function s:Toy.setPoint(context, name, point) dict "   {{{2
  if a:context !~# self.contextPattern
    throw 's:Toy.setPoint(context, name) gots an invalid a:context string'
  endif

  if empty(a:name)
    echoerr 'Empty name arg for setPoint()'
    return
  endif
  let board = self.getScoreBoard(a:context)
  let board[a:name] = a:point
endfunction " }}}2

function s:Toy.incrementPoint(context, name) dict "    {{{2
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
endfunction " }}}2

function s:Toy.decrementPoint(context, name) dict "    {{{2
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
endfunction " }}}2

function s:Toy.nextVimColor() dict "                   {{{2
  let picked = self.roll()
  execute 'colorscheme ' . picked
endfunction " }}}2

" TODO: reimplement it
function s:Toy.coloMarquee() dict "                    {{{2
  " let cur_color = g:colors_name

  " for c in s:Toy.vim_color_avail
  " execute "colorscheme " . c
  " redraw
  " echo c
  " sleep 300m
  " endfor

  " restore previous colorscheme.
  " execute 'colorscheme ' . cur_color
endfunction " }}}2

function s:Toy.showCurColors() dict "                  {{{2
  let msg = '[Vim] : ' . self.getCurVimColor()
  if exists(':AirlineTheme') && len(self.lastAirlineTheme) > 0
    let msg = msg . "\t\t[Airline] : " . self.lastAirlineTheme
  endif

  echo msg
endfunction " }}}2

" TODO: unimplemented
function s:Toy.airlineVirtualBoard() dict "            {{{2
endfunction " }}}2

call s:Toy.init()
"}}}1

" public interfaces                                 {{{1

function <SID>NextVimColor() "                         {{{2
  call s:Toy.nextVimColor()
endfunction " }}}2

function <SID>ShowCurColors() "                        {{{2
  call s:Toy.showCurColors()
endfunction " }}}2

nnoremap <Plug>(Mdx_Color_Toy_NextColor)  :<C-U>call <SID>NextVimColor()<Cr>
nnoremap <Plug>(Mdx_Color_Toy_ShowCurColors)  :<C-U>call <SID>ShowCurColors()<Cr>

augroup Mdx_Color_Toy
  autocmd!
  autocmd ColorScheme * call s:Toy.onColorScheme()
  autocmd VimLeavePre * call s:Toy.saveStat()
  autocmd VimEnter    * call s:Toy.onVimEnter()
augroup END

command -nargs=0 ColorToyReset call s:Toy.resetStat()

"}}}1
