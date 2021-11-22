#include "appevent.ch"
#include "common.ch"
#include "fileio.ch"
#include "xbp.ch"
#include "gra.ch"
#include "dac.ch"

#define CRLF Chr(13)+Chr(10)

#pragma Library( "XppUi2.lib" )
#pragma Library( "Adac20b.lib" )

procedure dbesys(); return
//procedure appsys();return

procedure main()
   cls
   ? 'Demo of FileReader() class'
   ? '--------------------------'
   ? 'Three demos will be shown sequentially:'
   ? '   1.  FReader() in basic mode'
   ? '   2.  Freader() enhanced mode using XbpBrowse'
   ? '   3.  Freader() enhanced mode using XbpQuickBrowse'
   ?
   wait
   cls
   mainConsole()
   mainGUI()
   mainXbpQ()
   return

procedure mainConsole()
   local cFile := 'C:\idep\Xbase\fileReader\fileReader.prg'
   local o := FileReader():new(cFile)
   local cLine := ''
   local i

   o:stripEOL := FALSE

   while !( cLine := o:readLine() ) == NIL
      ?? cLine
   enddo
   wait
   ?
   ? 'Rewinding...9 lines (press any key to continue)'
   ? '-----------------------------------------------'
   ?
   ?
   inkey(0)
   for i := 1 to 9
      o:rewind()
   next
   while !( cLine := o:readLine() ) == NIL
      ?? cLine
   enddo
   wait
   return

procedure mainGUI()
   local cFile := 'C:\idep\Xbase\fileReader\fileReader.prg'
   local o := FileReader():new(cFile)
   local oDlg
   local oP
   local oBrowse
   local nEvent
   local mp1
   local mp2
   local oXbp
   local aPP := {{XBP_PP_COL_DA_BGCLR, GRA_CLR_WHITE},;
                 {XBP_PP_COL_DA_ROWSEPARATOR,XBPCOL_SEP_LINE},;
                 {XBP_PP_COL_DA_COLSEPARATOR,XBPCOL_SEP_NONE},;
                 {XBP_PP_COL_DA_ROWHEIGHT,14};
                }

   o:stripEOL := TRUE

   oDlg := XbpDialog():new(AppDeskTop(),,{100,100},{600,400})
   oDlg:sysmenu := TRUE
   oDlg:tasklist := TRUE
   oDlg:title := "FileReader Test - XbpBrowse (Alt-F4 to end XbpBrowse)"
   oDlg:create()
   oP := oDlg:drawingArea
   oBrowse := XbpBrowse():new(oP,,{0,0},oP:currentSize(),aPP,TRUE)
   oBrowse:setFontCompoundName("8.Courier")

   oBrowse:create()
   o:configureXbpBrowse(oBrowse)

   // add columns with datalinks back to the FileReader() object
   //
   oBrowse:addColumn( {|| Str(o:lineNo(),5) },5,"Line" )
   oBrowse:addColumn( {|| o:currentLine() },100,cFile )

   oDlg:drawingArea:resize := ;
         {|mp1,mp2,obj| obj:childList()[1]:setSize(mp2) }

   oDlg:show()
   SetAppWindow(oDlg)
   oBrowse:show()
   SetAppFocus( oBrowse )

   DO WHILE nEvent <> xbeP_Close
      nEvent := AppEvent( @mp1, @mp2, @oXbp )
      oXbp:handleEvent( nEvent, mp1, mp2 )
   ENDDO
   oDlg:destroy()
   RETURN 

procedure mainXbpQ()
   local cFile := 'C:\idep\Xbase\fileReader\fileReader.prg'
   local o := FileReader():new(cFile)
   local oDlg
   local oP
   local oBrowse
   local nEvent
   local mp1
   local mp2
   local oXbp
   local aPP := {{XBP_PP_COL_DA_BGCLR, GRA_CLR_WHITE},;
                 {XBP_PP_COL_DA_ROWSEPARATOR,XBPCOL_SEP_LINE},;
                 {XBP_PP_COL_DA_COLSEPARATOR,XBPCOL_SEP_NONE},;
                 {XBP_PP_COL_DA_ROWHEIGHT,14};
                }

   o:stripEOL := TRUE

   oDlg := XbpDialog():new(AppDeskTop(),,{100,100},{610,400})
   oDlg:sysmenu := TRUE
   oDlg:tasklist := TRUE
   oDlg:title := "FileReader Test - XbpQuickBrowse (Alt-F4 to end XbpQuickBrowse)"
   oDlg:create()
   oP := oDlg:drawingArea
   oBrowse := XbpQuickBrowse():new(oP,,{0,0},oP:currentSize(),aPP,TRUE)
   oBrowse:setFontCompoundName("8.Courier")

   // associate FileRead() object with XbpQuickBrowse
   // and examine() the file to get number of lines and fetch
   // line offset info
   //
   oBrowse:dataLink := o
   o:examine()
   oBrowse:create()

   oDlg:drawingArea:resize := ;
         {|mp1,mp2,obj| obj:childList()[1]:setSize(mp2) }

   oDlg:setInputFocus := {|| SetAppFocus( oBrowse ) }
   oDlg:show()
   SetAppWindow(oDlg)
   oBrowse:show()
   SetAppFocus( oBrowse )

   DO WHILE nEvent <> xbeP_Close
      nEvent := AppEvent( @mp1, @mp2, @oXbp )
      oXbp:handleEvent( nEvent, mp1, mp2 )
   ENDDO
   RETURN 

