import docutils.highlite

proc ExpColorOpenGeneralTokenizer(g: ptr TGeneralTokenizer, buf: cstring) {.cdecl,exportc,dynlib.} =
  initGeneralTokenizer(g[], buf)
proc ExpColorNimNextToken(tokenizer: var TGeneralTokenizer) {.cdecl,exportc,dynlib.} =
  getNextToken(tokenizer, langNimrod)