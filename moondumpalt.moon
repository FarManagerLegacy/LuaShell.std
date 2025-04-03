--https://github.com/leafo/moonscript/wiki/Alternative-Table-Dumper-%28with-indentation%29
line = ""
buff = {}
idx = 1

io_write = (str)->
    line = line..str

io_write_nl = ()->
    buff[idx] = line
    idx += 1
    line = ""

ilevel = 0
indent = (a, b)->
    steps, fn = if b
        a, b
    else
        1, a
    ilevel += steps
    fn!
    ilevel -= steps
writeindent = -> io_write "   "\rep ilevel

dump = =>
    visited = {}
    _write = =>
        if type(self) == 'table' and not visited[self]
            if not (@@ and @@__name and not @__tostring)
                visited[self] = true
                io_write "{"
                io_write_nl!
                for k, v in pairs self
                    indent ->
                        writeindent!
                        _write k
                        io_write ': '
                        _write v
                        io_write_nl!
                writeindent!
                _write "}"
            elseif @__tostring
                io_write @__tostring!
            else
                io_write @@__name
        else
            io_write tostring self
    _write self
    table.concat buff, "\n"

if _cmdline==""
    print "A simple table pretty-printer, using indentation."
    print "Doesn't output valid moonscript code, because string values are not put in quotes."
    print "This could easily be changed, but serialization isn't the purpose of this module."
    print ""
    print "To prevent cycles a simple rule is used that every table is only output once in a given invocation."
    print "Even if there are no cycles, and the table structure just contains non-tree-like references, it will still output each table only once."
    print ""
    print "Every key-value pair is output on a separate line, so, although always remaining fairly readable, the output can get rather large fairly quickly."
elseif _cmdline
    print dump _cmdline\eval!
    return
else
    return dump 
