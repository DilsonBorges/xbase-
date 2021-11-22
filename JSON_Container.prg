#include "ot4xb.ch"
//----------------------------------------------------------------------------------------------------------------------
#define JSON_Token_number   ("(?:-?\b(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\b)")
#define JSON_Token_one_char ('(?:[^\0-\x08\x0a-\x1f"\\]|\\(?:["/\\bfnrt]|u[0-9A-Fa-f]{4}))')
#define JSON_Token_string   ('(?:"' + JSON_Token_one_char + '*")')
#define JSON_Token          ('(?:false|true|null|[\{\}\[\]]' + '|' + JSON_Token_number  + '|' + JSON_Token_string  + ')')
//----------------------------------------------------------------------------------------------------------------------
#define JSON_OBJECT     0x01
#define JSON_ARRAY      0x02
#define JSON_SIMPLE     0x03
#define JSON_STRING     0x04
#define JSON_NUMBER     0x05
#define JSON_TRUE       0x06
#define JSON_FALSE      0x07
#define JSON_NULL       0x08
#define JSON_END        0x10
#define JSON_ENDOBJECT  0x11
#define JSON_ENDARRAY   0x12
#define JSON_ERROR      -1
//----------------------------------------------------------------------------------------------------------------------
function json_pretty_out( cIn )
local bmt := ChrR(0,256)
local re := _rgx():New( JSON_Token ,"gim")
local ttr
local cc,n,nn,result
local last,delim,level
local p1,p2,token

@ot4xb:ByteMapTable_FillSeq(@bmt,__i8(32,255),1)
cc := cIn
@ot4xb:ByteMapTable_RemoveUnsafe(bmt,@cc,-1)
cc := TrimZ(cc)

ttr := re:exec(cc)
re:destroy()
if Empty(ttr)
   return cc
end
nn := Len( ttr )
result := ""
last  := 0
level := 0
for n := 1 to nn
   p1 := ttr[n][1]
   p2 := ttr[n][2]
   delim := AllTrim(PeekStr( cc , last , p1 - last ))
   token := AllTrim(PeekStr( cc , p1 , p2 ))
   last  := p1 + p2

   if delim == ":"
      result += " : "
   elseif delim == ","
      result += " ," + CRLF + Space(3*level)
   end
   if token $ "}]"
      level--
      result += CRLF + Space(3*level) + token
   elseif token $ "{["
      result += CRLF + Space(3*level) + token
      level++
      result += CRLF + Space(3*level)
   else
      result += token
   end
next
return result
//----------------------------------------------------------------------------------------------------------------------
function json_condense_out( cIn )
local bmt := ChrR(0,256)
local re := _rgx():New( JSON_Token ,"gim")
local n,nn
local ttr
local result
local last,delim
local p1,p2,token
local cc

@ot4xb:ByteMapTable_FillSeq(@bmt,__i8(32,255),1)
cc := cIn
@ot4xb:ByteMapTable_RemoveUnsafe(bmt,@cc,-1)
cc := TrimZ(cc)

ttr := re:exec(cc)
re:destroy()
if Empty(ttr)
   return cc
end
nn := Len( ttr )
result := ""
last  := 0
for n := 1 to nn
   p1 := ttr[n][1]
   p2 := ttr[n][2]
   delim := AllTrim(PeekStr( cc , last , p1 - last ))
   token := AllTrim(PeekStr( cc , p1 , p2 ))
   last  := p1 + p2
   result += delim + token
next
return result
//----------------------------------------------------------------------------------------------------------------------
function json_serialize( v , lRecursionDetected  , lIgnoreRecursion)
local result := NIL
local lStart := (tls():JSON_Container_Stack == NIL )
lIgnoreRecursion := .F.
if lStart
   if Empty( lIgnoreRecursion )
      tls():JSON_Container_lIgnoreRecursion := .F.
      tls():JSON_Container_Stack := TGXbStack():New()
      tls():JSON_Container_lRecursionDetected := .F.
      tls():JSON_Container_lRecursionDetected := NIL
   else
      tls():JSON_Container_lIgnoreRecursion := .T.
   end
end
result  := json_serialize_internal(v)
if lStart
   if Empty( lIgnoreRecursion )
      tls():JSON_Container_Stack:destroy()
      tls():JSON_Container_Stack := NIL
      lRecursionDetected := tls():JSON_Container_lRecursionDetected
      tls():JSON_Container_lRecursionDetected := NIL
   else
      tls():JSON_Container_lIgnoreRecursion := NIL
   end
end
return result
//----------------------------------------------------------------------------------------------------------------------
function json_unserialize( cc , lError)
local aToken := json_tokenize_string( cc )
local stk
local n,nn
local result
local t,v
local eb
lError := .F.
nn := Len( aToken )
if nn == 0
   lError := .T.
   return NIL
end
t := JSON_ERROR
result := json_token_value( aToken[1] ,@t)
if t > JSON_SIMPLE
   return result
end
stk := TGXbStack():New()
stk:push(result )
eb := ErrorBlock( {|| Break() } )
BEGIN SEQUENCE
   for n := 2 to nn
      v := json_token_value( aToken[n] ,@t)
      if t == -1
         BREAK
      elseif t == JSON_ENDOBJECT
         v := stk:pop()
         v:m_on_unserialize_pop()
         json_tos_put_prop( stk, v )
      elseif t == JSON_ENDARRAY
         v := stk:pop()
         json_tos_put_prop( stk, v )
      elseif t < JSON_SIMPLE
         stk:push(v)
      else
         json_tos_put_prop( stk, v )
      end
   next
RECOVER
   lError := .T.
END SEQUENCE
ErrorBlock(eb)
stk:destroy()
return result
//----------------------------------------------------------------------------------------------------------------------
static function json_tos_put_prop( stk, v )
local tos := stk:tos()
local t
t := Valtype(tos)
if t == "A"
   aadd( tos , v )
elseif t == "O"
   tos:m_unserialize_step(v)
end
return NIL
//----------------------------------------------------------------------------------------------------------------------
static function json_token_value( token , type )
local ch := PeekStr(token,0,1)
if ch == '{'
   type := JSON_OBJECT
   return JSON_Container():New()
elseif ch == '['
   type := JSON_ARRAY
   return Array(0)
elseif ch == '}'
   type := JSON_ENDOBJECT
   return NIL
elseif ch == ']'
   type := JSON_ENDARRAY
   return NIL
elseif ch == '"'
   type := JSON_STRING
   return json_unescape_string( token)
elseif token == 'true'
   type := JSON_TRUE
   return .T.
elseif token == 'false'
   type := JSON_TRUE
   return .F.
elseif token == 'null'
   type := JSON_NULL
   return NIL
else
   type := JSON_NUMBER
   return ot4xb_parse_number( token)
end
return NIL

//----------------------------------------------------------------------------------------------------------------------
function json_escape_string( cc )
local cb   := 0
local p    := 0
local cOut := ""
DEFAULT cc := ""
cb := Len(cc)
p := @ot4xb:escape_to_json(cc,cb,@cb)
if Empty(p) ; return '""' ; end
cOut := cPrintf(,"\q%s\q",p)
_xfree(p)
return cOut
//----------------------------------------------------------------------------------------------------------------------
function json_unescape_string( cc )
local cb   := 0
local p    := 0
local cOut := ""
DEFAULT cc := ""
cb := 0
p := @ot4xb:unescape_from_json(cc,@cb)
if Empty(p) ; return "" ; end
cOut := PeekStr(p,0,cb)
_xfree(p)
return cOut
//----------------------------------------------------------------------------------------------------------------------
static function json_tokenize_string( cc )
local re := _rgx():New( JSON_Token ,"gim")
local ttr := re:exec(cc)
local n,nn
local result
re:destroy()
if Empty(ttr)
   return Array(0)
end
nn := Len( ttr )
result := Array(nn)
for n := 1 to nn
   result[n] := PeekStr( cc , ttr[n][1] , ttr[n][2] )
next
return result
//----------------------------------------------------------------------------------------------------------------------
static function json_serialize_internal( v )
local t,r
local lRecursion
if v == NIL
   return "null"
end
t := ValType( v )
if t == "C"
   return json_escape_string(v)
elseif t == "M"
   return json_escape_string(v)
elseif t == "N"
   if lIsNumF64( v )
      return cPrintf("%f",NIL,v)
   end
   return cPrintf("%i",v)
elseif t == "L"
   return iif( v , "true" , "false" )
elseif t == "D"
   return iif( Empty(v) , "null" , cPrintf(,"\q%s\q",DtoS(v)) )
elseif t == "O"
   if Empty( tls():JSON_Container_lIgnoreRecursion )
      lRecursion := .F.
      tls():JSON_Container_Stack:SEval( {|e| iif( Valtype(e) == "O",iif( e == v , lRecursion := .T. , NIL),NIL) } )
      if lRecursion
         tls():JSON_Container_lRecursionDetected := .T.
         return "null"
      end
      r := NIL
      tls():JSON_Container_Stack:push( v )
      if !lCallMethodPA(v,"json_escape_self",{},@r)
         r := "null"
      end
      tls():JSON_Container_Stack:pop()
   else
      r := NIL
      if !lCallMethodPA(v,"json_escape_self",{},@r)
         r := "null"
      end
   end
   return r
elseif t == "A"
   if Empty( tls():JSON_Container_lIgnoreRecursion )
      lRecursion := .F.
      tls():JSON_Container_Stack:SEval( {|e| iif( Valtype(e) == "A",iif( e == v , lRecursion := .T. , NIL),NIL) } )
      if lRecursion
         tls():JSON_Container_lRecursionDetected := .T.
         return "null"
      end
      r := NIL
      tls():JSON_Container_Stack:push( v )

      r := ""
      AEval( v , {|e,n| r += iif(n > 1,",","") + json_serialize(e) } )
      r := cPrintf("[%s]",r)

      tls():JSON_Container_Stack:pop()
   else
      r := ""
      AEval( v , {|e,n| r += iif(n > 1,",","") + json_serialize(e) } )
      r := cPrintf("[%s]",r)
   end
   return r
end
return "null"

       // ---------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
CLASS JSON_Container
PROTECTED:
       // ---------------------------------------------------------------------------------
       VAR m_json_props
       VAR m_json_hash
       VAR m_unserialize_info
EXPORTED:
       // ---------------------------------------------------------------------------------
INLINE METHOD _toarray(hash) ; hash := ::m_json_hash ; return aclone( ::m_json_props )
       // ---------------------------------------------------------------------------------
INLINE METHOD m_unserialize_step(v)
       DEFAULT ::m_unserialize_info := Array(0)
       aadd( ::m_unserialize_info , v )
       return Self
       // ---------------------------------------------------------------------------------
INLINE METHOD m_on_unserialize_pop()
       local n,nn
       if Empty( ::m_unserialize_info ) ; return NIL ; end
       nn := nAnd(Len( ::m_unserialize_info ), 0x7FFFFFFE )
       n := 1
       while n < nn
          ::set_prop( __vstr(::m_unserialize_info[n],"") , ::m_unserialize_info[n+1] )
          n += 2
       end
       ::m_unserialize_info := NIL
       return Self
       // ---------------------------------------------------------------------------------
INLINE SYNC METHOD json_escape_self()
       local r := ""
       AEval( ::m_json_props , {|e,n| r += iif(n > 1,",","") + cPrintf(,"\q%s\q:%s", e[1] , json_serialize(e[2])) } )
       return  cPrintf("{%s}",r)
       // ---------------------------------------------------------------------------------
INLINE METHOD init()
       ::m_json_props  := Array(0)
       ::m_json_hash   := ""
       return Self
       // ---------------------------------------------------------------------------------
INLINE SYNC METHOD set_prop( k , v )
       local cnt := nRShift(Len(::m_json_hash),2)
       local dwh := 0
       local pos := @ot4xb:_dwscan_lwstrcrc32(::m_json_hash,cnt,__vstr(k,""),-1,@dwh)
       if pos == -1
          pos := cnt
          ::m_json_hash += __i32(dwh)
          aadd( ::m_json_props , __anew( __vstr(k,"") , v ) )
       else
          ::m_json_props[ pos+1][2] := v
       end
       return NIL
       // ---------------------------------------------------------------------------------
INLINE SYNC METHOD get_prop( k )
       local cnt := nRShift(Len(::m_json_hash),2)
       local dwh := 0
       local pos := @ot4xb:_dwscan_lwstrcrc32(::m_json_hash,cnt,__vstr(k,""),-1,@dwh)
       if pos == -1
          return NIL
       end
       return ::m_json_props[ pos+1][2]
       // ---------------------------------------------------------------------------------
INLINE METHOD SetNoIVar(k,v)
       return ::set_prop( k , v )
       // ---------------------------------------------------------------------------------
INLINE METHOD GetNoIVar(k)
       return ::get_prop( k )
       // ---------------------------------------------------------------------------------
ENDCLASS
//----------------------------------------------------------------------------------------------------------------------
