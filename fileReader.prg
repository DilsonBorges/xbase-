/*****************************
* Source : fileReader.prg
* System : 
* Author : Phil Ide
* Created: 04-Jun-2005
*
* Purpose: 
* ----------------------------
* History:                    
* ----------------------------
* 04-Jun-2005 11:24:09 idep - Created
*
* ----------------------------
* (Subversion Macros)
* Last Revision:
*    $Rev$
*    $Date$
*    $Author$
*    $URL$
*    
*****************************/

#include "appevent.ch"
#include "common.ch"
#include "fileio.ch"
#include "xbp.ch"
#include "gra.ch"
#include "dac.ch"

#define CRLF Chr(13)+Chr(10)

CLASS FileReader
   EXPORTED:
      VAR handle
      VAR buffer
      VAR stripEOL
      VAR dataWidth

   PROTECTED:
      VAR eol_token
      VAR aOffset
      VAR curLine
      VAR cFileName
      VAR qbOffset
      VAR qbRow
      VAR qbCacheSize

   EXPORTED:
      METHOD init
      METHOD configure
      METHOD readLine
      METHOD close
      METHOD eofPos
      METHOD rewind
      METHOD examine
      METHOD reexamine
      METHOD goTo

      // XbpBrowse methods
      METHOD skip
      METHOD goTop
      METHOD goBottom
      METHOD lineNo
      METHOD position
      METHOD goPosition
      METHOD currentLine

      METHOD configureXbpBrowse

      // XbpQuickBrowse
      METHOD getRowData
      METHOD getRowInfo
      METHOD fileName
      METHOD baseFileName
      METHOD bindView
      METHOD setAbsolutePageSize
      METHOD getPos
      METHOD getRelativePageSize
      METHOD scrollDown
      METHOD scrollUp
      METHOD isFirst
      METHOD isLast
      METHOD rowCount
      METHOD getRowCount
      METHOD goFirst
      METHOD goLast
      METHOD goPrev
      METHOD goNext

ENDCLASS

METHOD FileReader:init( cFile, cEol )
   default cEol TO CRLF
   default ::eol_token to cEol
   ::handle := 0
   ::buffer := ''
   ::aOffset := {1}
   ::curLine := 1
   ::stripEOL := TRUE
   ::qbOffset := 0
   ::qbRow    := 1
   ::dataWidth := 72
   ::qbCacheSize:= 10
   if FExists( cFile )
      ::handle := FOpen( cFile, FO_READ+FO_SHARED )
      ::cFileName :=  cFile
   endif
   return self

METHOD FileReader:configure( cFile )
   ::close()
   ::init( cFile )
   return self

METHOD FileReader:close()
   if ::handle <> 0
      FClose(::handle)
      ::init()
   endif
   return self

METHOD FileReader:eofPos()
   local nCurPos
   local nEofPos := 0

   if ::handle <> 0
      nCurPos := FSeek(::handle, 0, FS_RELATIVE )
      nEofPos := FSeek( ::handle, 0, FS_END )
      FSeek( ::handle, nCurPos, FS_SET )

   endif
   return nEofPos


METHOD FileReader:readLine()
   local cBuff
   local nRead
   local i
   local cLine

   if ::handle <> 0
      if ::curLine == Len(::aOffset)
         if ATail(::aOffset) < ::eofPos()
            FSeek( ::handle, (ATail(::aOffset)+Len(::buffer))-1, FS_SET )
            While At( ::eol_token, ::buffer ) == 0
               cBuff := Space(4096)
               nRead := FRead( ::handle, @cBuff, 4096 )
               cBuff := Left( cBuff, nRead )
               ::buffer += cBuff
               if nRead < 4096 //.and. FError() == 0
                  exit
               endif
            Enddo
            if !Empty(::buffer)
               i := At( ::eol_token, ::buffer )
               if i > 0
                  cLine := Left(::buffer,i+1)
               else
                  cLine := ::buffer
               endif
               ::buffer := SubStr( ::buffer, Len(cLine)+1 )
               aadd( ::aOffset, ATail(::aOffset)+Len(cLine) )
               ::curLine++
            endif
         endif
      else
         FSeek( ::handle, ::aOffset[::curLine]-1, FS_SET )
         cLine := Space( ::aOffset[::curLine+1] - ::aOffset[::curLine] )
         nRead := FRead( ::handle, @cLine, Len(cLine) )
         ::curLine++
      endif
   endif
   if !(cLine == NIL) .and. ::stripEOL
      cLine := Left(cLine,Len(cLine)-Len(::eol_token))
   endif
   return cLine

METHOD FileReader:rewind()
   local lOk := FALSE
   if ::handle <> 0 .and. ::curLine > 1
      ::curLine--
      lOk := TRUE
   endif
   return lOk

METHOD FileReader:examine()
   local nLine := ::curLine
   while !(::readLine() == NIL)
   Enddo
   ::curLine := nLine
   return self

METHOD FileReader:reexamine()
   local nCurLine := ::curLine
   local lOk := FALSE

   if ATail(::aOffset) < ::eofPos()
      ::goBottom()
      ::examine()
      ::curLine := nCurLine
      lOk := TRUE
   endif
   return lOk

METHOD FileReader:goTo(n)
   local lOk := FALSE
   if ValType(n) == 'N' .and. n < Len(::aOffset) .and. n > 0
      ::curLine := n
      lOk := TRUE
   endif
   return lOk

METHOD FileReader:skip(n)
   local nRet := 0

   default n TO 1

   if n > 0
      if ::curLine + n > Len(::aOffset)
         nRet := (Len(::aOffset) - ::curLine)+1
      else
         nRet := n
      endif
      ::curLine += nRet
   elseif n < 0
      if ::curLine + n < 1
         nRet := -(::curLine - 1)
      else
         nRet := n
      endif
      ::curLine += nRet
   endif
   return nRet

METHOD FileReader:goTop()
   ::curLine := 1
   return self

METHOD FileReader:goBottom()
   ::curLine := Len(::aOffSet)
   return self

METHOD FileReader:lineNo(a,b,c)
   local n := ::curLine
   return n

METHOD FileReader:position()
   local nRet := (Len(::aOffSet)-1)/100
   nRet := ::curLine/nRet
   return nRet

METHOD FileReader:goPosition(n)
   local i

   i := Int((Len(::aOffSet)-1)*(n/100))
   ::curLine := i
   return i

METHOD FileReader:currentLine()
   local cBuff := ''
   local n0
   local n1
   if ::handle <> 0 .and. ::curLine < Len(::aOffset)
      n0 := ::curLine+1
      n1 := ::curLine

      cBuff := Space( ::aOffset[n0] - ::aOffset[n1] )
      FSeek(::handle, ::aOffset[::curLine]-1, FS_SET )
      FRead( ::handle, @cBuff, Len(cBuff) )
      FSeek(::handle, ::aOffset[::curLine], FS_SET )

      if ::stripEOL
         cBuff := Left(cBuff,Len(cBuff)-Len(::eol_token))
      endif
   endif
   return cBuff

METHOD fileReader:configureXbpBrowse(oBrowse)
   oBrowse:skipBlock       := {|n|  self:skip(n) }
   oBrowse:goTopBlock      := {||   self:goTop() }
   oBrowse:goBottomBlock   := {||   self:goBottom() }
   oBrowse:phyPosBlock     := {||   self:lineNo() }

   oBrowse:posBlock        := {||   self:position() }
   oBrowse:goPosBlock      := {|n|  self:goPosition(n) }
   oBrowse:lastPosBlock    := {||   100 }
   oBrowse:firstPosBlock   := {||     1 }
   ::examine()
   return self

METHOD fileReader:getRowdata( n )
   local nCurLine := ::curLine
   local cRet := ''

   n := ::qbOffset + n //::qbRow
   if n <= Len(::aOffset)
      ::curLine := n
      cRet := ::readLine()
      ::curLine := nCurLine
   else
      n := 0
   endif
   return {n,{Padr(cRet,::dataWidth)}}

METHOD fileReader:getRowInfo( nInfo )
   local aRet := {}
   local cFile
   local i

   do case
      case nInfo == DAC_FIELD_NAME
         aRet := {'FIELD1'}
      case nInfo == DAC_FIELD_CAPTION
         aRet := {::baseFileName()}
      case nInfo == DAC_FIELD_VALTYPE
         aRet := {'C'}
      case nInfo == DAC_FIELD_PICTURE
         aRet := {'@X'}

   endcase
   return aRet

METHOD fileReader:fileName()
   return ::cFileName

METHOD fileReader:baseFileName()
   local i := Rat('\',::cFileName)
   local cRet := SubStr( ::cFileName, i+1 )

   return cRet

METHOD fileReader:bindView()
   return self

METHOD fileReader:setAbsolutePageSize(n)
   local nOld := ::qbCacheSize
   if ValType(n) == 'N' .and. n > 0
      ::qbCacheSize := n
   endif
   return nOld

METHOD fileReader:getPos()
   return ::position()

METHOD fileReader:getRelativePageSize()
   local nRet := (Len(::aOffSet)-1)/::qbCacheSize
   return nRet

METHOD fileReader:scrollDown(n)
   local nSkipped

   nSkipped := ::skip(n)
   ::qbOffset += n
   return nSkipped

METHOD fileReader:scrollUp(n)
   local nSkipped

   nSkipped := ::skip(-n)
   ::qbOffset += nSkipped
   return nSkipped

METHOD fileReader:isFirst()
   return ::qbOffset == 0

METHOD fileReader:isLast()
   local nPages := Len(::aOffSet)/::qbCacheSize
   if nPages <> Int(Len(::aOffSet)/::qbCacheSize)
      nPages++
   endif
   return ::qbOffset == (nPages-1)

METHOD fileReader:rowCount()
   return ::getRowCount()

METHOD fileReader:getRowCount()
   local nRows := ::qbCacheSize
   local nCRow

   Min( ::qbCacheSize, (Len(::aOffset) - ::curLine)+1)
   return nRows

METHOD fileReader:goNext()
   ::skip(::qbCacheSize)
   ::qbOffset := ::curLine-1
   return self

METHOD fileReader:goPrev()
   ::skip(-::qbCacheSize)
   ::qbOffset := ::curLine-1
   return self

METHOD fileReader:goFirst()
   ::curLine := 1
   ::qbOffset := 0
   return self

METHOD fileReader:goLast()
   ::curLine := (Len(::aOffset)-::qbCacheSize)+1
   ::qbOffset := ::curLine-1
   return self



