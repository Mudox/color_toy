" vim: foldmethod=marker
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1

" implementation                                {{{1

let s:core = g:mdx_kaleidoscope

let s:core.head_mark = '>'
let s:core.head_mark_closed = '-'
let s:core.tail_mark = '+--'
let s:buf_nr = -1

function s:cntDesc(lhs, rhs)                     " {{{2
  return -(a:lhs[1] - a:rhs[1])
endfunction " }}}2

function s:core.view(context) dict               " {{{2
  " creat view.              {{{3

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
    let content = self.textBlockAll()
  else
    let content = self.textBlockOf(a:context)
  endif

  let win_width = max(map(copy(content), 'len(v:val)'))

  " replace separator holder with properly lengthened '-'s line.
  let sep = ''
  for x in range(win_width) | let sep .= '-' | endfor
  for x in range(len(content))
    if content[x] ==# '%sep%'
      let content[x] = sep
    endif
  endfor

  call append(0, content)


  " finally adjust view.     {{{3

  " trim leading and tailing empty lines.
  %substitute/\m\%^\(\n\s*\)\+//e
  %substitute/\m\(\n\s*\)\+\%$//e

  execute 'normal! ' . (win_width + 1) . "\<C-W>|"
  setlocal winfixwidth
  setlocal nomodifiable
  setlocal foldmethod=marker
  execute 'setlocal foldmarker=' . self.head_mark . ',' . self.tail_mark
  setlocal foldtext=mudox#kaleidoscope#view#foldtext()

  if a:context ==# 'all'
    setlocal foldenable
  else
    setlocal nofoldenable
  endif

  " install buffer local mappings.
  call self.mappings()

  call cursor(1, 1)

  " }}}3

endfunction " }}}2

function s:core.contextHead(context) dict        " {{{2
  let idx = stridx(a:context, '_')
  let gui_or_term = a:context[:idx - 1]
  let filetype_or_untyped = a:context[idx + 1:]

  let line = printf("%s %-4s | ft: %s",
        \ s:core.head_mark, gui_or_term, filetype_or_untyped)

  return line
endfunction " }}}2

function s:core.statLines(context) dict          " {{{2
  let board_list = self.getInnerBoardSorted(a:context)

  " return nothing for contexts that has a emtpy record list.
  if empty(board_list)
    return []
  endif

  " column width for printing.
  let len_count = len(string(board_list[0][1]))
  let len_count = max([2, len_count])

  let record_strings = []
  for [name, cnt] in board_list
    let item = printf('%' . len_count . 'd -- %s', cnt, name)
    call add(record_strings, item)
  endfor

  return record_strings
endfunction " }}}2

function s:core.textBlockOf(context) dict        " {{{2
  let context_head = self.contextHead(a:context)
  let statLines = self.statLines(a:context)
  let tail = printf('%s Totally %d colors.', self.tail_mark, len(statLines))
  call map(statLines, '"  " . v:val') " indent each line by 2 spaces.

  let content = []
  call add(content, context_head)
  call add(content, '%sep%')
  call extend(content, statLines)
  call add(content, tail)

  return content
endfunction " }}}2

function s:core.textBlockAll() dict              " {{{2
  let content = []
  for context in keys(self.stat_pool)
    call extend(content, self.textBlockOf(context))
    call add(content, "")
  endfor

  return content
endfunction " }}}2

function s:core.mappings() dict                  " {{{2
  nnoremap <buffer> <silent> q :close<Cr>
endfunction " }}}2

function s:core.highlights() dict                " {{{2
  syntax clear
endfunction " }}}2

function! mudox#kaleidoscope#view#foldtext()
  let firstline = getline(v:foldstart)
  let body       = substitute(firstline, s:core.head_mark, '', '')
  let prefix    = s:core.head_mark_closed . ' '
  let foldline  = prefix . body
  return foldline
endfunction
"  }}}1

" public interface                              {{{1

function mudox#kaleidoscope#view#open(context)   " {{{2
  call s:core.view(a:context)
endfunction " }}}2

" }}}1
