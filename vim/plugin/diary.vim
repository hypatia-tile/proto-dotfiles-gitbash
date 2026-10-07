" Diary helpers. Entries live outside this repository, in $DIARY_DIR
" (default ~/diary), as YYYY/MM/YYYY-MM-DD.md.

if exists('g:loaded_diary')
  finish
endif
let g:loaded_diary = 1

if !exists('g:diary_dir')
  let g:diary_dir = empty($DIARY_DIR) ? '~/diary' : $DIARY_DIR
endif

function! s:Dir() abort
  return substitute(fnamemodify(expand(g:diary_dir), ':p'), '/\+$', '', '')
endfunction

function! s:Path(date) abort
  return printf('%s/%s/%s/%s.md', s:Dir(), a:date[0:3], a:date[5:6], a:date)
endfunction

" '' is today, -1 / +2 are offsets in days, YYYY-MM-DD is taken as is.
function! s:Date(arg) abort
  let arg = trim(a:arg)
  if arg ==# ''
    return strftime('%Y-%m-%d')
  elseif arg =~# '^[+-]\=\d\+$'
    return strftime('%Y-%m-%d', localtime() + str2nr(substitute(arg, '^+', '', '')) * 86400)
  elseif arg =~# '^\d\{4}-\d\d-\d\d$'
    return arg
  endif
  echohl ErrorMsg
  echo 'diary: expected an offset like -1 or a date like 2026-10-07'
  echohl None
  return ''
endfunction

function! s:Heading(date) abort
  let heading = '# ' . a:date
  if exists('*strptime')
    let time = strptime('%Y-%m-%d', a:date)
    if time
      let heading .= strftime(' (%a)', time)
    endif
  endif
  return heading
endfunction

function! s:Entries() abort
  return sort(globpath(escape(s:Dir(), ','), '*/*/????-??-??.md', 0, 1))
endfunction

function! s:Open(arg, to_end) abort
  let date = s:Date(a:arg)
  if empty(date)
    return
  endif
  let path = s:Path(date)
  if !isdirectory(fnamemodify(path, ':h'))
    call mkdir(fnamemodify(path, ':h'), 'p')
  endif
  execute 'edit' fnameescape(path)
  if !filereadable(path) && line('$') == 1 && getline(1) ==# ''
    call setline(1, [s:Heading(date), ''])
    " Quitting without writing anything should not leave an empty entry.
    setlocal nomodified
  endif
  execute 'normal!' (a:to_end ? 'G' : 'gg')
endfunction

function! s:Step(delta) abort
  let current = expand('%:t:r')
  if current !~# '^\d\{4}-\d\d-\d\d$'
    let current = strftime('%Y-%m-%d')
  endif
  let dates = map(s:Entries(), 'fnamemodify(v:val, ":t:r")')
  if a:delta < 0
    let found = filter(dates, 'v:val <# current')
    let target = empty(found) ? '' : found[-1]
  else
    let found = filter(dates, 'v:val ># current')
    let target = empty(found) ? '' : found[0]
  endif
  if empty(target)
    echo 'diary: no ' . (a:delta < 0 ? 'earlier' : 'later') . ' entry'
    return
  endif
  call s:Open(target, 0)
endfunction

function! s:Index() abort
  let lines = []
  for path in reverse(s:Entries())
    let preview = ''
    for line in readfile(path, '', 20)
      if line !~# '^\s*\(#.*\)\=$'
        let preview = trim(line)
        break
      endif
    endfor
    call add(lines, fnamemodify(path, ':t:r') . '  ' . preview)
  endfor
  if empty(lines)
    echo 'diary: no entries in ' . s:Dir()
    return
  endif
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap
  silent file Diary\ Index
  call setline(1, lines)
  setlocal nomodifiable
  syntax match diaryIndexDate /^\d\{4}-\d\d-\d\d/
  highlight default link diaryIndexDate Identifier
  nnoremap <buffer> <silent> <CR> :call <SID>Open(matchstr(getline('.'), '^\S\+'), 0)<CR>
  nnoremap <buffer> <silent> q :bwipeout<CR>
endfunction

function! s:Grep(pattern) abort
  try
    execute 'silent vimgrep /' . escape(a:pattern, '/') . '/gj '
          \ . fnameescape(s:Dir()) . '/**/*.md'
  catch /E480/
    echo 'diary: no match for ' . a:pattern
    return
  endtry
  copen
endfunction

" Append a '## HH:MM' heading at the end and start typing under it.
function! s:Stamp() abort
  let gap = getline('$') =~# '^\s*$' ? [] : ['']
  call append('$', gap + ['## ' . strftime('%H:%M'), ''])
  normal! G
  startinsert
endfunction

function! s:IsDiary(path) abort
  let dir = s:Dir() . '/'
  return strpart(fnamemodify(a:path, ':p'), 0, len(dir)) ==? dir
endfunction

function! s:Setup() abort
  setlocal wrap linebreak breakindent nolist textwidth=0
  if !empty(globpath(&runtimepath, 'spell/en.utf-8.spl'))
    setlocal spell spelllang=en,cjk
  endif
  nnoremap <buffer> <expr> j v:count ? 'j' : 'gj'
  nnoremap <buffer> <expr> k v:count ? 'k' : 'gk'
  augroup diary_autosave
    autocmd! * <buffer>
    autocmd InsertLeave,TextChanged,FocusLost <buffer> silent! update
  augroup END
endfunction

augroup diary
  autocmd!
  autocmd BufNewFile,BufRead *.md if s:IsDiary(expand('<afile>')) | call s:Setup() | endif
augroup END

command! -nargs=? Diary call s:Open(<q-args>, 1)
command! DiaryPrev call s:Step(-1)
command! DiaryNext call s:Step(1)
command! DiaryIndex call s:Index()
command! -nargs=1 DiaryGrep call s:Grep(<q-args>)
command! DiaryStamp call s:Stamp()

nnoremap <silent> <Leader>dd :Diary<CR>
nnoremap <silent> <Leader>dy :Diary -1<CR>
nnoremap <silent> <Leader>dp :DiaryPrev<CR>
nnoremap <silent> <Leader>dn :DiaryNext<CR>
nnoremap <silent> <Leader>di :DiaryIndex<CR>
nnoremap <silent> <Leader>dt :DiaryStamp<CR>
nnoremap <Leader>dg :DiaryGrep<Space>
