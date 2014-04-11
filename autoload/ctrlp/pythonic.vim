" =============================================================================
" File:          autoload/ctrlp/pythonic.vim
" Description:   ctrlp menu extension for ctrlp.vim
" =============================================================================

" Change the name of the g:loaded_ variable to make it unique
if ( exists('g:loaded_ctrlp_pythonic') && g:loaded_ctrlp_pythonic )
      \ || v:version < 700 || &cp
  finish
endif
let g:loaded_ctrlp_pythonic = 1

let s:term_map = {}
let s:term_list = []

function! s:_scan_python(buf_num)
    let s:term_map = {}
    let s:term_list = []
    let l:buf_num = a:buf_num
    let l:lnum = 1
    let l:class_pattern = '^\s*class\s\+[A-Za-z_]\i\+(.*'
    let l:func_pattern = '^\s*def\s\+[A-Za-z_]\i\+(.*'
    let l:current_parent = {}
    while 1
        let l:buf_lines = getbufline(l:buf_num, l:lnum)
        if empty(l:buf_lines)
            break
        endif
        let l:term_found = 0
        let l:pos = match(l:buf_lines[0], l:class_pattern)
        if l:pos >= 0
            let l:term_found = 1
            let indent = substitute(l:buf_lines[0], '\(^\s*\).*', '\1', 'g')
            let indent_level = len(indent)/&shiftwidth
            let item = substitute(l:buf_lines[0], '^\s*class\s\+\([A-Za-z0-9_]\+\)(.*', '\1', 'g')
            let l:current_parent[indent_level+1] = item
        else
            let l:pos = match(l:buf_lines[0], l:func_pattern)
            if l:pos >= 0
                let l:term_found = 1
                let indent = substitute(l:buf_lines[0], '\(^\s*\).*', '\1', 'g')
                let indent_level = len(indent)/&shiftwidth
                let item = substitute(l:buf_lines[0], '^\s*def\s\+\([A-Za-z0-9_]\+\)(.*', '\1', 'g')
                let l:current_parent[indent_level+1] = item
            endif
        endif
        if l:term_found
            let entry = []
            let pidx = 1
            while pidx <= indent_level
                call add(entry, l:current_parent[pidx])
                let pidx += 1
            endwhile
            call add(entry, item)
            let entry_term = join(entry, "/")
            let s:term_map[entry_term] = l:lnum
            call add(s:term_list, entry_term)
        endif
        let l:lnum += 1
    endwhile
    return s:term_map
endfunction

" The main variable for this extension.
"
" The values are:
" + the name of the input function (including the brackets and any argument)
" + the name of the action function (only the name)
" + the long and short names to use for the statusline
" + the matching type: line, path, tabs, tabe
"                      |     |     |     |
"                      |     |     |     `- match last tab delimited str
"                      |     |     `- match first tab delimited str
"                      |     `- match full line like file/dir path
"                      `- match full line
let s:ctrlp_var = {
      \ 'init'  : 'ctrlp#pythonic#init(s:crbufnr)',
      \ 'accept': 'ctrlp#pythonic#accept',
      \ 'lname' : 'pythonic',
      \ 'sname' : 'py',
      \ 'type'  : 'path',
      \ 'sort'  : 0,
      \ 'nolim' : 1,
      \ }


" Append s:ctrlp_var to g:ctrlp_ext_vars
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:ctrlp_var)
else
  let g:ctrlp_ext_vars = [s:ctrlp_var]
endif


" Provide a list of strings to search in
"
" Return: command
function! ctrlp#pythonic#init(buf_num)
  call s:_scan_python(a:buf_num)
  " return keys(s:term_map)
  return s:term_list
endfunction


" The action to perform on the selected string.
"
" Arguments:
"  a:mode   the mode that has been chosen by pressing <cr> <c-v> <c-t> or <c-x>
"           the values are 'e', 'v', 't' and 'h', respectively
"  a:str    the selected string
func! ctrlp#pythonic#accept(mode, str)
  call ctrlp#exit()
  try
      let l:jump_to_lnum = s:term_map[a:str]
      call setpos('.', [0, l:jump_to_lnum, 1, 1])
  catch /E716:/
      redraw
      echohl WarningMsg
      echomsg "Not found: " . l:term
      echohl None
  endtry
endfunc


" Give the extension an ID
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Allow it to be called later
function! ctrlp#pythonic#id()
  return s:id
endfunction

function! ctrlp#pythonic#pythonic(word)
  let s:winnr = winnr()
  try
    if !empty(a:word)
      let default_input_save = get(g:, 'ctrlp_default_input', '')
      let g:ctrlp_default_input = a:word
    endif

    call ctrlp#init(ctrlp#pythonic#id())
  finally
    if exists('default_input_save')
      let g:ctrlp_default_input = default_input_save
    endif
  endtry
endfunction


" vim:fen:fdl=0:ts=2:sw=2:sts=2
