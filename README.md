# vimlogger
Trace logging in viml

# Usage:
  " in .vimrc
  call logger#init('ALL', ['/dev/stdout', '~/.vim/log.txt'])

  " in script
  silent! let s:log = logger#getLogger(expand('<sfile>:t'))

  " start logger
  silent! call s:log.info('aaa')

# Function Reference:

##  function logger#init(level, targets [, format [, filter]])
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

##  function logger#getLogger(name)
  @param name [String] Log name
  @return Logger object
