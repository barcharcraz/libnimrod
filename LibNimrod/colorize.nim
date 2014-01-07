import docutils.highlite

proc ExpColorOpenGeneralTokenizer(g: ptr TGeneralTokenizer, buf: cstring) {.cdecl,exportc,dynlib.} =
  g.buf = buf
  g.kind = low(TTokenClass)
  g.start = 0
  g.length = 0
  g.state = low(TTokenClass)
  var pos = 0
  while g.buf[pos] in {' ', '\x09'..'\x0D'}: inc(pos)
  g.pos = pos
proc ExpColorNimNextToken(tokenizer: var TGeneralTokenizer) {.cdecl,exportc,dynlib.} =
  getNextToken(tokenizer, langNimrod)