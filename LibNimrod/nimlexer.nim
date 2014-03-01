import lexer
import llstream


type RLLStream = ptr TLLStream
#low level debugging exports

proc ExpFullcollect() {.cdecl,exportc,dynlib.} =
  GC_fullcollect()
proc ExpGCDisable() {.cdecl, exportc, dynlib.} =
  GC_disable()

#llstreams exports
proc ExpLLStreamOpen(data: cstring): PLLStream {.cdecl,exportc,dynlib.} = 
    var gdres = LLStreamOpen($data)
    GC_ref(gdres)
    result = gdres
    
proc ExpLLStreamClose(stream: PLLStream) {.cdecl,exportc,dynlib.} = 
    LLStreamClose(stream)
    GC_unref(stream)
    
type ExpTTokType {.exportc.} = TTokType
proc ExpIsKeyword(kind: ExpTTokType): bool {.cdecl,exportc,dynlib} =
  result = isKeyword(kind)

proc ExpStrMarshal(value: cstring): int {.cdecl,exportc,dynlib.} =
  result = value.len
  
proc ExpGetLLStreamKind(value: PLLStream): TLLStreamKind {.cdecl, exportc, dynlib.} = 
  result = value.kind
proc ExpGetLLStreamReadAll(s: PLLStream): cstring {.cdecl, exportc, dynlib.} =
  result = LLStreamReadAll(s)
proc ExpGetLLStreamString(s: PLLStream): cstring {.cdecl, exportc, dynlib.} =
 result = s.s
proc ExpGetLLStreamRd(s: PLLStream): int {.cdecl, exportc, dynlib.} =
  result = s.rd
proc ExpGetLLStreamWr(s: PLLStream): int {.cdecl, exportc, dynlib.} =
  result = s.wr
  
#token related exports
proc ExpTokGetType(tok: ref TToken): TTokType {.cdecl, exportc, dynlib.} = 
  result = tok.tokType
proc ExpTokGetIndent(tok: ref TToken): int {.cdecl, exportc, dynlib.} = 
  result = tok.indent
proc ExpTokGetiNumber(tok: ref TToken): BiggestInt {.cdecl, exportc, dynlib.} = 
  result = tok.iNumber
proc ExpTokGetfNumber(tok:ref TToken): BiggestFloat {.cdecl, exportc, dynlib.} =
  result = tok.fNumber
proc ExpTokGetBase(tok: ref TToken): TNumericalBase {.cdecl, exportc, dynlib.} =
  result = tok.base
proc ExpTokGetLiteral(tok: ref TToken): cstring {.cdecl, exportc, dynlib.} =
  #this is not dangerous since presumably the ref is already pinned
  #from ExpRawGetTok
  result = tok.literal
proc ExpTokGetLine(tok: ref TToken): int {.cdecl, exportc, dynlib.} =
  result = tok.line
proc ExpTokGetCol(tok: ref TToken): int {.cdecl, exportc, dynlib.} =
  result = tok.col
proc ExpTokToString(tok: ref TToken): cstring {.cdecl, exportc, dynlib.} =
  result = tokToStr(tok[])
  
#lexer related exports
proc ExpOpenLexer(inputstream: PLLStream): ref TLexer {.cdecl, exportc, dynlib.} =
  new(result)
  openLexer(result[], "", inputstream)
  GC_ref(result)
  
proc ExpCloseLexer(lex: ref TLexer) {.cdecl, exportc, dynlib.} =
  #closeLexer(lex[])
  GC_unref(lex)
proc ExpGetLexIndentAhead(lex: ref TLexer): int {.cdecl, exportc, dynlib.} =
  result = lex.indentAhead

proc ExpRawOpenTok(L: ref TLexer) : ref TToken {.cdecl, exportc, dynlib.} =
  new(result)
  initToken(result[])
  rawGetTok(L[], result[])
  GC_ref(result)
proc ExpRawGetTok(L: ref TLexer): TToken {.cdecl, exportc, dynlib.} =
  initToken(result)
  rawGetTok(L[], result)
proc ExpRawFreeTok(tok: ref TToken) {.cdecl, exportc, dynlib.} = 
  GC_unref(tok)
  

  