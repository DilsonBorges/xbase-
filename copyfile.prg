*** CopyFile.PRG ***

#define PBS_MARQUEE       0x08
#define PBS_SMOOTH        0x01
#define PBS_NORMAL        0x00

PROCEDURE MAIN(cFile)
LOCAL oProgress
LOCAL aPOS     := {0,0}
LOCAL aSIZE    := {0,0}
LOCAL aPP      := {}
LOCAL xMax     := 0
LOCAL xScale   := 0
LOCAL nValue   := 0
LOCAL nEvery   := 100
LOCAL i        := 0
LOCAL cNewDbf  := "TEMP$$$.DBF"

   IF PCOUNT() > 0
      IF !FILE(cFile)
         ALERT("File "+cFile+" not found")
         QUIT
      ENDIF
   ELSE
      ALERT("need DBF Name")
      QUIT
   ENDIF

   USE &(cFile) EXCLUSIVE

   xMax     := Lastrec()
   nEvery   := INT(xMax/100)
   xScale   := xMax*nEvery                   // Scale to 100%

   aSIZE    := SetAppWindow():currentSize()
   aSIZE[2] := 20

   oProgress := DXE_ProgressBar():New( SetAppWindow(),, aPOS, aSIZE,aPP )
   //
   // NEED visual Style and XP Manifest !!!
   //
   oProgress:UseVisualStyle   := .T.
   oProgress:UsePercent       := .T.
   oProgress:Create()
   //
   // assign after create
   //
   oProgress:Style            := PBS_SMOOTH
   oProgress:Minimum          := 0
   oProgress:Maximum          := xMax
   oProgress:nScaleMax        := xScale
   oProgress:Increment        := nEvery

   oProgress:SetData( 1 )                        // start here
   CLS
   ? ""
   ? "copy from "+cFile+" to "+cNewDbf+" NEXT "+LTRIM(STR(xMax))

   COPY TO &(cNewDbf) FOR FORproggress(oProgress,nEvery,i++) NEXT xMax VIA 
"DBFNTX"

   CLOSE
   oProgress:destroy()

   ? ""
   ? "FERASE("+cNewDbf+") "
   FERASE(cNewDbf)
   ? ""
   WAIT

RETURN

FUNCTION FORproggress(oProgress,nEvery,i)
LOCAL nValue := i
   IF ((nValue) % (nEvery)) == 0
      nValue := oProgress:GetData()
      nValue += nEvery
      oProgress:SetData( nValue )
   ENDIF
RETURN .T.

*
* eof
* 