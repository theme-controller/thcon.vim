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

    if has_key(req, "let")
        let variables = req.variables
        if type(variables) == type({})
            for [key, value] in items(variables)
                let { key } = value
            endfor
        endif
    endif

    for set_cmd in ["set", "setglobal"]
        if has_key(req, set_cmd)
            let options = req[set_cmd]
            if type(options) == type({})
                echom "Found " . set_cmd
                for [key, value] in items(options)
                    call s:set(set_cmd, key, value)
                endfor
            endif
        endif
    endfor
endfunc

" Calls :set key=value, :set key, :set nokey -- or their :setglobal variants --
" safely, avoiding arbitrary command injection.
" @param {string} set_cmd - one of "set" | "setglobal"
" @param {string} key - the name of the option to be set
" @param {*} value - the value to assign to the option
func s:set(set_cmd, key, value)
    if a:set_cmd != "set" && a:set_cmd != "setglobal"
        echom "[s:set] invalid set_cmd '" . a:set_cmd . "'"
        return
    endif

    let safe_key = s:execescape(a:key)

    if a:value == v:true
        exec a:set_cmd safe_key
    elseif a:value == v:false
        exec a:set_cmd "no".safe_key
    else
        if type(a:value) == type("")
            let safe_value = s:execescape(a:value)
            exec a:set_cmd safe_key."=".safe_value
        else
            exec a:set_cmd safe_key."=".a:value
        endif
    endif
endfunc

" Makes a string safe for use with :exec, preventing arbitrary command injection
" @param {string} str - the string to make safe for use with a dynamic :exec
" @returns {string} - the substring starting at the beginning of str, running until either a command
"                     separator or the end of the string is found.
func s:execescape(str)
    if type(str) != type("")
        return str
    endif

    return trim(get(split(a:str, "[|\n]"), 0, ""))
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

func! s:on_vimleave()
    job_stop(s:job)
endfunc

augroup thcon
    autocmd!
    autocmd VimLeave * call s:on_vimleave()
augroup end

" restore 'compatible' settings; copied verbatim from `:h write-plugin`
let &cpo = s:save_cpo
unlet s:save_cpo
