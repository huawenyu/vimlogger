" ============================================================================
" File:        log.vim
" Description: the wrapper of autoload
" ============================================================================

"Init {
if exists('g:loaded_vimlogger')
    finish
endif

if &cp || v:version < 700
    echom 'Please use the new vim version > 700'
    finish
endif

let g:loaded_vimlogger = 1
"}


"autocmd
command! -nargs=0 Logger call utils#Tracecrash()
