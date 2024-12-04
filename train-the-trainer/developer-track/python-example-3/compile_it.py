import sys
import py_compile
# cfile` is named argument for destination filename
py_compile.compile(sys.argv[1],  cfile=sys.argv[2])
