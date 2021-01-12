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

if !exists("g:thcon_debug")
    let g:thcon_debug = v:false
endif

function! s:debug(...)
    if g:thcon_debug
        echom join(a:000)
    endif
endfunc

" figure out where this script is installed, so we can reference other files included with a
" this plugin
let s:plugindir = resolve(expand('<sfile>:p:h'))

" Handles lines printed by thcon-vim.sh
" Lines that aren't valid JSON are ignored.  Lines that are valid JSON objects are used to
" change colorschemes and set other arbitrary variables.  See ../thcon.schema.json for that
" object's schema.
func s:on_stdout(msg)
    call s:debug("[s:on_stdout] msg ", a:msg)
    let v:errmsg = ""
    silent! let req = json_decode(a:msg)
    call s:debug("[s:on_stdout] parsed = ", req)

    if v:errmsg != "" || type(req) != type({})
        call s:debug("[s:on_stdout] err = ", v:errmsg)
        call s:debug("[s:on_stdout] bailing")
        return
    endif

    if has_key(req, "colorscheme")
        let newcolor = s:execescape(req.colorscheme)
        call s:debug("[s:on_stdout] colorscheme = " . newcolor)
        if type(newcolor) == type("") && newcolor != ""
            call s:debug("[s:on_stdout] setting colorscheme...")
            execute "colorscheme " . newcolor
        endif
    endif

    if has_key(req, "let")
        let lets = req.let
        if type(lets) == type({})
            for [key, value] in items(lets)
                let { key } = value
            endfor
        endif
    endif

    for set_cmd in ["set", "setglobal"]
        if has_key(req, set_cmd)
            let options = req[set_cmd]
            if type(options) == type({})
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
    if type(a:str) != type("")
        return a:str
    endif

    return trim(get(split(a:str, "[|\n]"), 0, ""))
endfunc

func s:on_stderr(msg)
    echom "[on_stderr] " string(a:msg)
endfunc

func! thcon#listen()
    let script = s:plugindir . "/thcon-vim.sh"
    if has("nvim")
        let job_options = { "on_stdout": { job, data, event, -> s:on_stdout(data) } }
        if g:thcon_debug
            call extend(job_options, {
            \   "on_stderr": { job, data, event, -> s:on_stderr(data) },
            \   "env": { "DEBUG": "1" }
            \ })
        endif
        let s:job = jobstart(script, job_options)
    else
        let job_options = { "out_cb": { chan, msg -> s:on_stdout(msg) } }
        if g:thcon_debug
            call extend(job_options, {
            \   "err_cb": { chan, msg -> s:on_stderr(msg) },
            \   "env": { "DEBUG": "1" }
            \ })
        endif
        let s:job = job_start(script, job_options)
    endif
endfunc

func! s:on_vimleave()
    if has("nvim")
        call jobstop(s:job)
    else
        call s:debug("[s:on_vimleave] Stopping job: ", s:job)
        call job_stop(s:job)
    endif
endfunc

augroup thcon
    autocmd!
    autocmd VimLeavePre * call s:on_vimleave()
augroup end

" restore 'compatible' settings; copied verbatim from `:h write-plugin`
let &cpo = s:save_cpo
unlet s:save_cpo
