if exists('g:loaded_pythonic')
  finish
endif
let g:loaded_pythonic = 1
let s:save_cpo = &cpo
set cpo&vim
command! -nargs=? CtrlPPythonic call ctrlp#pythonic#pythonic(<q-args>)
let &cpo = s:save_cpo
unlet s:save_cpo
