" Vim/NeoVim global plugin to change colors via [thcon](https://github.com/sjbarag/thcon)
" Last Change: 2021 Jan 04
" Maintainer: Sean Barag <sean@barag.org>
" License: MIT

if exists("g:loaded_thcon")
    finish
endif
let g:loaded_thcon = v:true

" ensure job_start is available, or we can't start a background process and read from it
if !has("nvim") && !has("job")
    echom "thcon.vim requires a vim instance compiled with +job"
    finish
endif

" don't break with 'compatible' mode; copied verbatim from `:h write-plugin`
let s:save_cpo = &cpo
set cpo&vim

let g:thcon_debug = v:false

" figure out where this script is installed, so we can reference other files included with a
" this plugin
let s:plugindir = resolve(expand('<sfile>:p:h'))

if has("nvim")
    echom "neovim isn't yet supported"

    " restore 'compatible' settings; copied verbatim from `:h write-plugin`
    let &cpo = s:save_cpo
    unlet s:save_cpo

    finish
endif

" Handles lines printed by thcon-vim.sh
" Lines that aren't valid JSON are ignored.  Lines that are valid JSON objects are used to
" change colorschemes and set other arbitrary variables.  See ../thcon.schema.json for that
" object's schema.
func s:on_stdout(chan, msg)
    echom "[s:on_stdout] msg " . a:msg
    let v:errmsg = ""
    silent! let req = json_decode(a:msg)

    if v:errmsg != "" || type(req) != type({})
        echom "[s:on_stdout] err = " v:errmsg
        echom "[s:on_stdout] bailing"
        return
    endif

    if has_key(req, "colorscheme")
        let newcolor = req.colorscheme
        if type(newcolor) == type("") && newcolor != ""
            execute "colorscheme " . newcolor
        endif
    endif

    if has_key(req, "variables")
        let variables = req.variables
        if type(variables) == type({})
            for [key, value] in items(variables)
                let { key } = value
            endfor
        endif
    endif
endfunc

func s:on_stderr(chan, msg)
    if g:thcon_debug
        echom "[OnThconStderr] " . a:msg
    endif
endfunc

func! thcon#listen()
    let script = s:plugindir . "/thcon-vim.sh"
    let s:job = job_start(script, {
    \   "out_cb": function("s:on_stdout"),
    \   "err_cb": function("s:on_stderr"),
    \   "env": { "DEBUG": "1" }
    \ })
endfunc

augroup thcon
    autocmd!
    autocmd VimLeave * job_stop(s:job)
augroup end

" restore 'compatible' settings; copied verbatim from `:h write-plugin`
let &cpo = s:save_cpo
unlet s:save_cpo
