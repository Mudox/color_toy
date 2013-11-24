" vim: foldmethod=marker
if exists("loaded_mdx_autoload_mudox_kaleidoscope_view_vim") || &cp || version < 700
  finish
endif
let loaded_mdx_autoload_mudox_kaleidoscope_view_vim = 1

" implementation                              {{{1

let s:core = g:mdx_kaleidoscope
let s:buf_nr = -1

function s:cntDesc(lhs, rhs) "                   {{{2
  return -(a:lhs[1] - a:rhs[1])
endfunction " }}}2

function s:core.view(context) dict "                    {{{2
  " creat view.            {{{3

  " no buffer named [Kaleidoscope] exists.
  if !bufexists(s:buf_nr)
    topleft vnew
    silent file `="[Kaleidoscope]"`
    let s:buf_nr = bufnr('%')
    " already has a [Kaleidoscope] buffer, but hiddened.
  elseif bufwinnr(s:buf_nr) == -1
    topleft vnew
    execute s:buf_nr . 'buffer'
    " jump to that window.
  elseif bufwinnr(s:buf_nr) != bufwinnr('%')
    execute bufwinnr(s:buf_nr) . 'wincmd w'
  endif

  setlocal filetype=kaleidoscope
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal nobuflisted
  setlocal modifiable
  setlocal nocursorline
  setlocal nocursorcolumn

  %delete _
  " }}}3

  " fill content
  if a:context =~ 'all'
    let content = self.allStatStrings()
  else
    let content = self.contextView(a:context)
  endif

  call append(0, content)
  delete _

  " adjust view.           {{{3
  let win_width = max(map(copy(content), 'len(v:val)'))
  execute 'normal! ' . (win_width + 1) . "\<C-W>|"
  setlocal winfixwidth
  setlocal nomodifiable
  " }}}3

endfunction " }}}2

function s:core.contextLine(context) dict "      {{{2
  let [gui_or_term, light_or_dark, filetype_or_untyped; ignore],
        \ = split(a:context, '_')

  let line = printf("%-4s | bg: %5s | ft: %s",
        \ gui_or_term, light_or_dark, filetype_or_untyped)

  return line
endfunction " }}}2

function s:core.rankingStrings(context) dict "   {{{2
  let board_list = self.vimColorSortedBoard(a:context)

  " column width for printing.
  let len_count = len(string(board_list[0][1]))

  let record_strings = []
  for [name, cnt] in board_list
    let item = printf('%' . len_count . 'd -- %s', cnt, name)
    call add(record_strings, item)
  endfor

  return record_strings
endfunction " }}}2

function s:core.contextView(context) dict "      {{{2
  let context_head = self.contextLine(a:context)
  let rankingStrings = self.rankingStrings(a:context)
  call map(rankingStrings, '"  " . v:val') " indent each line by 2 spaces.

  let content = []
  call add(content, context_head)
  call extend(content, rankingStrings)

  let win_width = max(map(copy(content), 'len(v:val)')) + 2
  let separator = ''
  for x in range(win_width - 1)
    let separator = separator . '-'
  endfor
  call insert(content, separator, 1)

  return content
endfunction " }}}2

function s:core.allStatStrings() dict " {{{2
  let content = []
  for context in keys(self.stat_pool)
    call extend(content, self.contextView(context))
    call add(content, "")
  endfor

  return content
endfunction " }}}2
"  }}}1

" public interface                            {{{1

function mudox#kaleidoscope#view#open(context) "        {{{2
  call s:core.view(a:context)
endfunction " }}}2

" }}}1
