" log.vim: logging library
" Last Change: 2008-08-05
" Maintainer: Yukihiro Nakadaira <yukihiro.nakadaira@gmail.com>
" License: This file is placed in the public domain.
"

function logger#import()
    return s:lib
endfunction

function logger#init(...)
    call call(s:lib.init, a:000, s:lib)
endfunction

function logger#getLogger(name)
    return s:lib.Logger.new(a:name)
endfunction



" options. {{{1
if !exists('g:prettyprint_indent')  " {{{2
    let g:prettyprint_indent = 4
    "if exists('*shiftwidth')
    "    let g:prettyprint_indent = 'shiftwidth()'
    "else
    "    let g:prettyprint_indent = '&l:shiftwidth'
    "endif
endif

if !exists('g:prettyprint_width')  " {{{2
    let g:prettyprint_width = '&columns'
endif

if !exists('g:prettyprint_string')  " {{{2
    let g:prettyprint_string = []
endif

if !exists('g:prettyprint_show_expression')  " {{{2
    let g:prettyprint_show_expression = 0
endif

let s:string_t = type('')
let s:list_t = type([])
let s:dict_t = type({})
let s:func_t = type(function('tr'))

" functions. {{{1
function! s:pp(expr, shift, width, stack) abort
    let indent = repeat(s:blank, a:shift)
    let indentn = indent . s:blank

    let appear = index(a:stack, a:expr)
    call add(a:stack, a:expr)

    let width = s:width - a:width - s:indent * a:shift

    let str = ''
    if type(a:expr) == s:list_t
        if appear < 0
            let result = []
            for Expr in a:expr
                call add(result, s:pp(Expr, a:shift + 1, 0, a:stack))
                unlet Expr
            endfor
            let oneline = '[' . join(result, ', ') . ']'
            if strlen(oneline) < width && oneline !~ "\n"
                let str = oneline
            else
                let content = join(map(result, 'indentn . v:val'), ",\n")
                let str = printf("[\n%s\n%s]", content, indent)
            endif
        else
            let str = '[nested element ' . appear .']'
        endif

    elseif type(a:expr) == s:dict_t
        if appear < 0
            let result = []
            for key in sort(keys(a:expr))
                let skey = string(strtrans(key))
                let sep = ': '
                let Val = get(a:expr, key)  " Do not use a:expr[key] to avoid Partial
                let valstr = s:pp(Val, a:shift + 1, strlen(skey . sep), a:stack)
                if s:indent < strlen(skey . sep) &&
                            \ width - s:indent < strlen(skey . sep . valstr) && valstr !~ "\n"
                    let sep = ":\n" . indentn . s:blank
                endif
                call add(result, skey . sep . valstr)
                unlet Val
            endfor
            let oneline = '{' . join(result, ', ') . '}'
            if strlen(oneline) < width && oneline !~ "\n"
                let str = oneline
            else
                let content = join(map(result, 'indentn . v:val'), ",\n")
                let str = printf("{\n%s\n%s}", content, indent)
            endif
        else
            let str = '{nested element ' . appear .'}'
        endif

    elseif type(a:expr) == s:func_t
        silent! let funcstr = string(a:expr)
        let matched = matchlist(funcstr, '\C^function(''\(.\{-}\)''\()\?\)')
        let funcname = matched[1]
        let is_partial = matched[2] !=# ')'
        let symbol = funcname =~# '^\%(<lambda>\)\?\d\+$' ?
                    \                         '{"' . funcname . '"}' : funcname
        if &verbose && exists('*' . symbol)
            redir => func
            " Don't print a definition location if &verbose == 1.
            silent! execute (&verbose - 1) 'verbose function' symbol
            redir END
            let str = func
        elseif is_partial
            let str = printf("function('%s', {partial})", funcname)
        else
            let str = printf("function('%s')", funcname)
        endif
    elseif type(a:expr) == s:string_t
        let str = a:expr
        if a:expr =~# "\n" && s:string_split
            let expr = s:string_raw ? 'string(v:val)' : 'string(strtrans(v:val))'
            let str = "join([\n" . indentn .
                        \ join(map(split(a:expr, '\n', 1), expr), ",\n" . indentn) .
                        \ "\n" . indent . '], "\n")'
        elseif s:string_raw
            "let str = string(a:expr)
            let str = a:expr
        else
            "let str = string(strtrans(a:expr))
            let str = strtrans(a:expr)
        endif
    else
        let str = string(a:expr)
    endif

    unlet a:stack[-1]
    return str
endfunction

function! s:option(name) abort
    let name = 'prettyprint_' . a:name
    let opt = has_key(b:, name) ? b:[name] : g:[name]
    return type(opt) == type('') ? eval(opt) : opt
endfunction

function! logger#echo(str, msg, expr) abort
    let str = a:str
    if g:prettyprint_show_expression
        let str = a:expr . ' = ' . str
    endif
    if a:msg
        for s in split(str, "\n")
            echomsg s
        endfor
    else
        echo str
    endif
endfunction

function! logger#_prettyprint(exprs) abort
    let s:indent = s:option('indent')
    let s:blank = repeat(' ', s:indent)
    let s:width = s:option('width') - 1
    let string = s:option('string')
    let strlist = type(string) is type([]) ? string : [string]
    let s:string_split = 0 <= index(strlist, 'split')
    let s:string_raw = 0 <= index(strlist, 'raw')
    let result = []
    for Expr in a:exprs
        call add(result, s:pp(Expr, 0, 0, []))
        unlet Expr
    endfor
    return join(result, '')
endfunction

function! logger#prettyprint(...) abort
    let s:indent = s:option('indent')
    let s:blank = repeat(' ', s:indent)
    let s:width = s:option('width') - 1
    let string = s:option('string')
    let strlist = type(string) is type([]) ? string : [string]
    let s:string_split = 0 <= index(strlist, 'split')
    let s:string_raw = 0 <= index(strlist, 'raw')
    let result = []
    for Expr in a:000
        call add(result, s:pp(Expr, 0, 0, []))
        unlet Expr
    endfor
    return join(result, "\n")
endfunction


let s:lib = {}

let s:lib.ALL = 0
let s:lib.TRACE = 1
let s:lib.DEBUG = 2
let s:lib.INFO = 3
let s:lib.WARN = 4
let s:lib.ERROR = 5
let s:lib.FATAL = 6
let s:lib.NONE = 999999

let s:lib.config = {}
let s:lib.config.level = s:lib.NONE
let s:lib.config.format = ''
let s:lib.config.filter = ''
let s:lib.config.targets = []

function s:lib.init(level, targets, ...)
    let tmp = {}    " for E704
    let format = get(a:000, 0, '')
    let tmp.filter = get(a:000, 1, '')
    if empty(format)
        "let format = '[{level}][{strftime("%Y-%m-%d %H:%M:%S")}][{name}] {msg}'
        let format = '[{level}][{strftime("%H:%M:%S")}][{name}] {msg}'
    endif
    if empty(tmp.filter)
        let tmp.filter = ''
    endif
    let self.config.level = self[toupper(a:level)]
    let self.config.targets = []
    let self.config.format = format
    for tmp.target in (type(a:targets) == type([])) ? a:targets : [a:targets]
        if type(tmp.target) == type("")
            call add(self.config.targets, self.FileAppender.new(tmp.target))
        elseif type(tmp.target) == type(function("tr"))
            call add(self.config.targets, self.FuncAppender.new(tmp.target))
        elseif type(tmp.target) == type({})
            if !self.is_callable(tmp.target)
                throw "logger#init(): target object must have __call__(str) method"
            endif
            call add(self.config.targets, tmp.target)
        else
            throw "logger#init(): not supported target object"
        endif
        unlet tmp.target   " for E706
    endfor
    if type(tmp.filter) == type("")
        let self.config.filter = self.PatternFilter.new(tmp.filter)
    elseif type(tmp.filter) == type(function("tr"))
        let self.config.filter = self.FuncFilter.new(tmp.filter)
    elseif type(tmp.filter) == type({})
        if !self.is_callable(tmp.filter)
            throw "logger#init(): filter object must have __call__(name) method"
        endif
        let self.config.filter = tmp.filter
    else
        throw "logger#init(): not supported filter object"
    endif
endfunction

function s:lib.is_callable(d)
    return type(a:d) == type({})
                \ && has_key(a:d, '__call__')
                \ && type(a:d.__call__) == type(function('tr'))
endfunction


let s:lib.Logger = {}

let s:lib.Logger.level = s:lib.NONE
let s:lib.Logger.name = ''

function s:lib.Logger.new(name)
    let res = copy(self)
    let res.name = a:name
    if s:lib.config.filter.__call__(a:name)
        let res.level = s:lib.config.level
    endif
    return res
endfunction

function s:lib.Logger.log(level, args)
    let level = a:level
    let name = self.name

    "let msg = (len(a:args) == 1) ? a:args[0] : call('printf', a:args)
    let msg = logger#_prettyprint(a:args)

    " sub-replace-\= does not work recursively.
    "let str = substitute(s:lib.config.format, '{\([^}]\+\)}', '\=eval(submatch(1))', 'g')
    let str = ''
    let m = s:lib.Matcher.new(s:lib.config.format, '{\([^}]\+\)}')
    while m.find()
        let str .= m.head() . eval(m[1])
    endwhile
    let str .= m.tail()
    for t in s:lib.config.targets
        call t.__call__(str)
    endfor
endfunction

function s:lib.Logger.trace(...)
    if self.isTraceEnabled()
        call self.log('TRACE', a:000)
    endif
endfunction

function s:lib.Logger.debug(...)
    if self.isDebugEnabled()
        call self.log('DEBUG', a:000)
    endif
endfunction

function s:lib.Logger.info(...)
    if self.isInfoEnabled()
        call self.log('INFO', a:000)
    endif
endfunction

function s:lib.Logger.warn(...)
    if self.isWarnEnabled()
        call self.log('WARN', a:000)
    endif
endfunction

function s:lib.Logger.error(...)
    if self.isErrorEnabled()
        call self.log('ERROR', a:000)
    endif
endfunction

function s:lib.Logger.fatal(...)
    if self.isFatalEnabled()
        call self.log('FATAL', a:000)
    endif
endfunction

function s:lib.Logger.isTraceEnabled()
    return self.level <= s:lib.TRACE
endfunction

function s:lib.Logger.isDebugEnabled()
    return self.level <= s:lib.DEBUG
endfunction

function s:lib.Logger.isInfoEnabled()
    return self.level <= s:lib.INFO
endfunction

function s:lib.Logger.isWarnEnabled()
    return self.level <= s:lib.WARN
endfunction

function s:lib.Logger.isErrorEnabled()
    return self.level <= s:lib.ERROR
endfunction

function s:lib.Logger.isFatalEnabled()
    return self.level <= s:lib.FATAL
endfunction


let s:lib.FileAppender = {}

function s:lib.FileAppender.new(filename)
    let res = copy(self)
    let res.filename = a:filename
    return res
endfunction

function s:lib.FileAppender.__call__(str)
    execute printf('redir >> %s', self.filename)
    silent echo a:str
    redir END
endfunction


let s:lib.FuncAppender = {}

function s:lib.FuncAppender.new(log)
    let res = copy(self)
    let res.__call__ = a:log
    return res
endfunction


let s:lib.PatternFilter = {}

function s:lib.PatternFilter.new(pattern)
    let res = copy(self)
    let res.pattern = a:pattern
    return res
endfunction

function s:lib.PatternFilter.__call__(name)
    return a:name =~ self.pattern
endfunction


let s:lib.FuncFilter = {}

function s:lib.FuncFilter.new(filter)
    let res = copy(self)
    let res.__call__ = a:filter
    return res
endfunction


let s:lib.Matcher = {}

function s:lib.Matcher.new(expr, pat)
    let res = copy(self)
    let res.expr = a:expr
    let res.pat = a:pat
    let res.submatch = []
    let res.last = 0
    let res.start = 0
    return res
endfunction

function s:lib.Matcher.find()
    if self.start == -1
        return 0
    endif
    if self.submatch != []
        let self.last = matchend(self.expr, self.pat, self.start)
    endif
    let self.start = match(self.expr, self.pat, self.last)
    if self.start == -1
        return 0
    endif
    let self.submatch = matchlist(self.expr, self.pat, self.start)
    for i in range(len(self.submatch))
        let self[i] = self.submatch[i]
    endfor
    return 1
endfunction

function s:lib.Matcher.head()
    return strpart(self.expr, self.last, self.start - self.last)
endfunction

function s:lib.Matcher.tail()
    if self.start != -1
        return strpart(self.expr, matchend(self.expr, self.pat, self.start))
    endif
    return strpart(self.expr, self.last)
endfunction
