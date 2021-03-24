" Vim/NeoVim global plugin to change colors (and other settings) via [thcon](https://github.com/sjbarag/thcon)
" Last Change: 2021 Mar 24
" Version: 0.4.0
" Maintainer: Sean Barag <sean@barag.org>
" License: MIT

if exists("g:loaded_thcon")
    finish
endif
let g:loaded_thcon = v:true

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

" Handles lines printed by thcon-vim.sh
" Lines that aren't valid JSON are ignored.  Lines that are valid JSON objects are used to
" determine which file to `:source`.  See ../thcon.schema.json for that object's schema.
func s:on_stdout(job_id, msg, event_type)
    call s:debug("[s:on_stdout] msg: ", string(a:msg))
    let msg = join(a:msg, "\n")
    let v:errmsg = ""
    silent! let req = json_decode(msg)
    call s:debug("[s:on_stdout] parsed = ", req)

    if v:errmsg != "" || type(req) != type({})
        call s:debug("[s:on_stdout] err = ", v:errmsg)
        call s:debug("[s:on_stdout] bailing")
        return
    endif

    if has_key(req, "rc_file")
        let rc_file = s:exec_escape(expand(req.rc_file))
        if filereadable(rc_file)
            exec "source " . rc_file
        endif
    endif
endfunc

" Makes a string safe for use with :exec, preventing arbitrary command injection
" @param {string} str - the string to make safe for use with a dynamic :exec
" @returns {string} - the substring starting at the beginning of str, running until either a command
"                     separator or the end of the string is found.
func s:exec_escape(str)
    if type(a:str) != type("")
        return a:str
    endif

    return trim(get(split(a:str, "[|\n]"), 0, ""))
endfunc

func s:on_stderr(job_id, msg, event_type)
    echom "[on_stderr] " string(a:msg)
endfunc

" Listens for JSON-formatted commands provided by `thcon`, applying new settings and colorschemes
" in the calling `vim`/`nvim` instance.
func! thcon#listen()
    if has("nvim")
        let app_name = "nvim"
    else
        let app_name = "vim"
    endif
    let argv = ["thcon-listen", app_name, "--per-process"]

    let job_options = { "on_stdout": function("s:on_stdout") }
    if g:thcon_debug
        call add(argv, "--verbose")
        call extend(job_options, {
        \   "on_stderr": function("s:on_stderr"),
        \ })
    endif
    call s:debug("[thcon#listen] argv = ", join(argv, " "))

    let s:job = thcon#job#start(join(argv, " "), job_options)
endfunc

func! s:on_vimleave()
    call s:debug("[s:on_vimleave] Stopping job: ", s:job)
    call thcon#job#stop(s:job)
    call s:debug("[s:on_vimleave] waiting for: ", s:job)
    call thcon#job#wait([s:job], 2000) " wait at-most 2 seconds for thcon-listen to die
    call s:debug("[s:on_vimleave] job is dead!")
endfunc

augroup thcon
    autocmd!
    autocmd VimLeavePre * call s:on_vimleave()
augroup end

" Loads settings previously applied via `thcon <mode> vim`, ensuring consistency in new instances.
func! thcon#load()
    if has("nvim")
        let rc_name = "nvimrc"
    else
        let rc_name = "vimrc"
    endif

    let rc_path = expand("~/.local/share/thcon/" . rc_name)
    call s:debug("[thcon#load] rc_path = ", rc_path)
    if filereadable(rc_path)
        exec "source " . rc_path
    else
        call s:debug("[thcon#load] file not found")
    endif
endfunc

" restore 'compatible' settings; copied verbatim from `:h write-plugin`
let &cpo = s:save_cpo
unlet s:save_cpo
