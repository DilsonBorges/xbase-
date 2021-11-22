/*****************************
* Source : Ajax.prg
* System : WaaRC
* Author : Phil Ide
* Created: 18-Jun-2005
*
* Purpose: 
* ----------------------------
* History:                    
* ----------------------------
* $DATETIME$ idep - Created
*
* Last Revision:
*    $Rev$
*    $Date$
*    $Author: idep $
*    $URL:  $
*    
*
*****************************/

#include "common.ch"
#include "dll.ch"

#define CR Chr(13)
#define LF Chr(10)
#define CRLF CR+LF

Function _register(oPkg)
   return TRUE

Function _version()
   return "1.0"

Function _copyright()
   return "Phil Ide 2005, All Rights Reserved"

// <!-- CUT -->
Function ServerTime( oHtml, oContext )
   local xTime := Seconds()
   local cXml

   xTime := xTime - Int(xTime)
   xTime := '.'+StrZero(xTime*100,2,0)
   cXml := '<?xml version="1.0"?>'+LF+;
           '<Result>'+LF+;
           '  <method>ServerTime</method>'+LF+;
           '  <Result>'+Time()+xTime+'</Result>'+LF+;
           '</Result>'

   oHtml:put(cXml)
   oHtml:cContentType := 'text/xml'
   return TRUE

Function CheckNumericInputRange( oHtml, oContext )
   local cXml := '<?xml version="1.0"?>'+LF+;
           '<Result>'+LF+;
           '  <method>numberCheck</method>'+LF+;
           '  <Response>$1</Response>'+LF+;
           '  <Status>$2</Status>'+LF+;
           '</Result>'
   local cResultText   := 'Error - invalid value (1 - 10)'
   local cResultStatus := '0'
   local n := oHtml:getVar('UNUMBER')

   n := Val(n)
   if n >= 1 .and. n <= 10
      cResultStatus := '1'
      cResultText := 'You entered '+LTrim(Str(n))+' - thank you!'
   endif
   cXml := StrTran( cXml, '$1', cResultText )
   cXml := StrTran( cXml, '$2', cResultStatus )
   oHtml:put(cXml)
   oHtml:cContentType := 'text/xml'
   return TRUE

Function GetSource( oHtml, oContext )
   local cSource := 'not found'
   local cSName := oHtml:getVar('source')
   local cTag := '// <!-- CUT -->'+CRLF
   local i

   do case
      case right(lower(cSName),4) == '.prg'
         if FExists(cSName)
            cSource := MemoRead(cSName)
            i := At(cTag, cSource)
            cSource := SubStr(cSource, i+Len(cTag))
         endif

      case right(lower(cSName),3) == '.js'
         cTag := oContext:getDocRoot()+'non_ssl/conf/'+cSName
         if FExists(cTag)
            cSource := MemoRead(cTag)
         endif

      case right(lower(cSName),5) == '.html'
         cTag := oContext:getDocRoot()+'non_ssl/'+cSName
         if FExists(cTag)
            cSource := MemoRead(cTag)
         endif

   endcase
   cSource := StrTran( cSource, CRLF, LF )
   oHtml:put( cSource )
   oHtml:cContentType := 'text/plain'
   return TRUE

