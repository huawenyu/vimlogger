# vimlogger
Trace logging in viml

# Usage:
```vim
  " in .vimrc
  call logger#init('ALL', ['/dev/stdout', '/tmp/vim.log'])

  " in script
  silent! let s:log = logger#getLogger(expand('<sfile>:t'))

  " start logger
  silent! call s:log.info('aaa')


  $ tail -f /tmp/vim.log

  [TRACE][20:42:46][gdb.vim] gdb: {
      'ServerInit': function('confos#InitSvr'),
      'Symbol': function('confos#Symbol'),
      '_autorun': 0,
      '_current_buf': -1,
      '_current_line': -1,
      '_gdb_break_qf': /tmp/gdb.break,
      '_gdb_bt_qf': /tmp/gdb.bt,
      '_has_breakpoints': 0,
      '_initialized': 0,
      '_jump_window': 1,
      '_reconnect': 0,
      '_server_addr': [10.1.1.125, 444],
      '_server_exited': 0
  }
  [INFO][20:42:46][state.vim] Open gdb#SchemeCreate
  [INFO][20:42:49][state.vim] matched: [, call, on_init]
  [INFO][20:42:49][gdb.vim] Load breaks ...
  [INFO][20:42:49][gdb.vim] Load set breaks ...
  [INFO][20:42:49][gdb.vim] Gdbserver call Init()=function('confos#InitSvr')
  [INFO][20:42:49][state.vim] matched: [, call, on_init]

```


# Function Reference:

##  function logger#init(level, targets [, format [, filter]])
```vim
  @param level [String]
    Log level.  One of 'ALL|TRACE|DEBUG|INFO|WARN|ERROR|FATAL|NONE'.
  @param targets [mixed]
    Output target.  Filename or Function or Dictionary or List of these
    values.
    Filename:
      Log is appended to the file.
    Function:
      function Log(str)
        echo a:str
      endfunction
    Dictionary:
      let Log = {}
      function Log.__call__(str)
        echohl Error
        echo a:str
        echohl None
      endfunction
  @param format [String]
    Log format.  {expr} is replaced by eval(expr).  For example, {getpid()}
    is useful to detect session.  Following special variables are available.
    {level}   log level like DEBUG, INFO, etc...
    {name}    log name specified by logger#getLogger(name)
    {msg}     log message
    If this is 0, '', [] or {} (empty(format) is true), default is used.
    default:  [{level}][{strftime("%Y-%m-%d %H:%M:%S")}][{name}] {msg}
  @param filter [mixed]
    Pattern (String) or Function or Dictionary to filter log session.
    Filter is applied to name that specified by logger#getLogger(name).  If
    result is false, logging session do not output any text.
    Pattern (String):
      name =~ Pattern
    Function:
      function Filter(name)
        return a:name == 'mylib'
      endfunction
    Dictionary:
      let Filter = {}
      let Filter.filter = ['alib', 'blib', 'clib']
      function Filter.__call__(name)
        return index(self.filter, a:name) != -1
      endfunction
  @return void
```
##  function logger#getLogger(name)
```vim
  @param name [String] Log name
  @return Logger object
```
