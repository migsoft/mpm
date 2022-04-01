/*
 * INDENT.EXE (v.1.7) is a customizable program to reindent your .PRG files
 * Placed in the public domain for the Clipper/Harbour/MiniGUI community
 * by Joe Fanucchi MD (drjoe@meditrax.com, fantasyspinner2002@yahoo.com)
 * Comments and enhancements are welcome.
 */

/*
 * INDENT.EXE (v.11.0531) Modified by MigSoft <migsoft/at/oohg.org>
 *
 */

#include "oohg.ch"
#include "indent.ch"

MEMVAR aGlobal, nLastLine

*------------------------------------------------------------*
FUNCTION MAIN2()
*------------------------------------------------------------*
    PUBLIC aGlobal[ 20 ]                            // used to store public variables used throughout the program
    SET DELETED ON

    z_lhorizln  := .T.                              // must add a checkbox for this
    z_cfolder   := GetStartupFolder()
    z_laction   := .T.
    z_lcomment  := .T.
    z_ldowhile  := .T.
    z_lfornext  := .T.
    z_lfunction := .T.
    z_lifcase   := .T.
    z_lmenuitem := .T.
    z_lmultline := .T.
    z_lpopup    := .T.
    z_lwindow   := .T.
    z_naction   := 40
    z_ncomment  := 52
    z_nindent   := 4

    FindPrg()

RETURN NIL

*------------------------------------------------------------*
FUNCTION FindPrg( cFile )
*------------------------------------------------------------*
    LOCAL cPrgFile := "", i
    lEscaped := .F.

    cPrgFile := cFile

    If Empty( cPrgFile )
        cPrgFile := Getfile ( { {'.PRG Files','*.prg'}, {'All Files','*.*'} } , 'Open File' , z_cfolder , .f. , .t. )
    Endif

    If !Empty( cPrgFile )

       IF MsgYesNo( "Are you sure?", "Reindent code?")

          IF FILE( "MCITEXT.DBF" )
             USE MCITEXT ALIAS "MCITEXT" NEW EXCLUSIVE
             ZAP
             CLOSE MCITEXT
          ELSE
             DBCREATE( "MCITEXT", { { "cTXTLINE",  "C", 254, 0 } } )
          ENDIF

          USE MCITEXT ALIAS "MCITEXT" NEW EXCLUSIVE
          APPEND FROM ( cPrgFile ) SDF
          nLastLine := LASTREC()

          FOR i := 1 TO nLastLine
              GO i
              IF LEN( TRIM( MCITEXT->ctxtline )) == 254   // line is too long
                 MsgStop( "Line " + LTRIM( STR( i, 4 )) + " is too long to edit!   " ;
                 + CRLF + "(Maximum line length is 254 characters)   ", "Line length exceeded" )
                 lEscaped := .T.
                 EXIT
              ENDIF
          NEXT i

          CLOSE MCITEXT

          IF !lEscaped
             IndentIt( cPrgFile )
          Endif

       ENDIF

    Else
         lEscaped := .T.
    Endif

RETURN NIL

*------------------------------------------------------------*
FUNCTION IndentIt( cPrgFile )
*------------------------------------------------------------*
    LOCAL bFuncHead := { | cText | LEFT( UPPER( cText ), 9 ) == "FUNCTION " ;
        .OR. LEFT( UPPER( cText) , 16 ) == "STATIC FUNCTION " ;  // Is this the first line of a PROCEDURE or FUNCTION?
        .OR. LEFT( UPPER( cText) ,  5 ) == "PROC "     ;
        .OR. LEFT( UPPER( cText ), 10 ) == "PROCEDURE ";
        .OR. LEFT( UPPER( cText ),  9 ) == "HB_FUNC( ";
        .OR. LEFT( UPPER( cText ), 18 ) == "#pragma BEGINDUMP ";
        .OR. LEFT( UPPER( cText ),  7 ) == "METHOD " }
    LOCAL cAction                                   // ACTION clause of code line
    LOCAL cComment                                  // comment portion of code line
    LOCAL cLineText                                 // trimmed line of code
    LOCAL cOrigText                                 // original line of code
    LOCAL cTrialLine                                // trial text, used to ensure max length isn't exceeded
    LOCAL lAddAction    := .F.                      // is there an ACTION statement?
    LOCAL lAddSemi      := .F.                      // does comment end with a semicolon?
    LOCAL lMLLine1      := .F.                      // is this the first line of a multiline command?
    LOCAL lMultLine     := .F.                      // is this part of a multiline command?
    LOCAL lReturning    := .F.                      // has there been a RETURN line in this PROCEDURE/FUNCTION?
    LOCAL nBreakPoint   := 0                        // where can we cut out extra spaces if the line is too long?
    LOCAL nHeaderLen    := 0                        // length of header lines
    LOCAL nIndentSpaces := 0                        // leading spaces for this indent level
    LOCAL nLastLine                                 // how many lines in the .PRG file?
    LOCAL nLastReturn                               // record pointer to the most recent RETURN statement
    LOCAL nMLFudge      := 0                        // extra spaces for multi-line commands
    LOCAL nPercent      := 0                        // what percentage of lines is complete?
    LOCAL nThisLine     := 0                        // which line are we indenting?
    LOCAL nThisRecNo                                // record pointer
    LOCAL nCommentCol
    LOCAL cParalel      := chr(32)+chr(47)+chr(47)
    LOCAL cAsteris      := chr(32)+chr(42)+chr(42)
    LOCAL cAction1      := chr(32)+chr(65)+chr(67)+chr(84)+chr(73)+chr(79)+chr(78)+chr(32)

    USE MCITEXT ALIAS "MCITEXT" NEW EXCLUSIVE
    nLastLine := LASTREC()

    FOR nThisLine := 1 TO nLastLine

        GO nThisLine

        cAction    := ""
        cComment   := ""
        cOrigText  := MCITEXT->cTxtLine             // store the original text in a memvar
        cLineText  := TRIM( LTRIM( cOrigText ))     // shorten the line as much as possible
        cTrialLine := ""
        lAddSemi   := .F.                           // comment doesn't end with a semicolon

        DO CASE
          CASE LEFT( cLineText, 1 ) == "*"
                                                    * It's a comment line. Don't adjust spacing
          CASE z_lcomment                           // we want to align comments in a specific column
                                                    * Remove the comment portion first, just in case the comment ends with a semicolon
               DO CASE                              // remove the comments from the right side of the line
               CASE cParalel $ cLineText                                                  // avoids "commenting" URLs
                    cComment := SUBSTR( cLineText, AT( cParalel, cLineText ) + 1 )
                    cLineText := TRIM( LEFT( cLineText, AT( cParalel, cLineText )))
               CASE cAsteris $ cLineText
                    cComment := SUBSTR( cLineText, AT( cAsteris, cLineText ) + 1 )
                    cLineText := TRIM( LEFT( cLineText, AT( cAsteris, cLineText )))
               ENDCASE
          CASE RIGHT( cLineText, 1 ) == ";"
               cLineText := TRIM( LEFT( cLineText, LEN( cLineText ) - 1 ))
               lAddSemi := .T.
          ENDCASE

          lAddAction := .F.                         // there's no ACTION statement

          IF z_laction                              // we want to align ACTION statements in a specific column
               DO CASE
               CASE LEFT( cLineText, 1 ) == "*"
                                                    * It's a comment line. Don't adjust spacing
               CASE cAction1 $ UPPER( cLineText )  // remove the ACTION statement from the right side of the line
                    cAction   := SUBSTR( cLineText, AT( cAction1, UPPER( cLineText )) + 1 )  // "ACTION MsgInfo()"
                    cLineText := TRIM( LEFT( cLineText, AT( cAction1, UPPER( cLineText )) - 1 ))
                    lAddAction := .T.               // there's an ACTION statement
               ENDCASE
          ENDIF

                                                    * Adjust the spaces if we're backing out one indentation level
          DO CASE
          CASE LEFT( cLineText, 1 ) == "*"
                                                    * It's a comment line. Don't adjust spacing
          CASE z_ldowhile .AND. LEFT( LTRIM( UPPER( cLineText )), 4 ) == "ENDD"  // indent DO WHILE / WHILE statements?
               nIndentSpaces -= z_nindent
          CASE z_ldowhile .AND. LEFT( LTRIM( UPPER( cLineText )), 7 ) == "END INI"  // indent BEGIN INI statements?
               nIndentSpaces -= z_nindent
          CASE z_ldowhile .AND. LEFT( LTRIM( UPPER( cLineText )), 12 ) == "END SECUENCE"  // indent BEGIN SECUENCE statements?
               nIndentSpaces -= z_nindent
          CASE z_ldowhile .AND. LEFT( LTRIM( UPPER( cLineText )), 1 ) == "}"  // indent HB_FUNC statements?
               nIndentSpaces -= z_nindent
          CASE z_lfornext .AND. LEFT( LTRIM( UPPER( cLineText )), 4 ) == "NEXT"  // indent FOR/NEXT statements?
               nIndentSpaces -= z_nindent
          CASE z_lifcase .AND. LEFT( LTRIM( UPPER( cLineText )), 4 ) $ "ELSE/ENDI/ENDC/CASE/OTHE"  // indent IF/ELSE/CASE statements?
               nIndentSpaces -= z_nindent
               lReturning := .F.                    // a RETURN statement inside a condition will NOT be backdented
          CASE z_lwindow .AND. LEFT( LTRIM( UPPER( cLineText )), 8 ) $ "END WIND"  // indent WINDOW statements?
               nIndentSpaces -= z_nindent
          CASE z_lwindow .AND. LEFT( LTRIM( UPPER( cLineText )), 8 ) $ "END SPLI"  // indent SPLITBOX statements?
               nIndentSpaces -= z_nindent
          CASE z_lmenuitem .AND. LEFT( LTRIM( UPPER( cLineText )), 8 ) == "END MENU"  // indent MENU statements?
               nIndentSpaces -= z_nindent
          CASE z_lpopup .AND. LEFT( LTRIM( UPPER( cLineText )), 8 ) == "END POPU"  // indent POPUP statements?
               nIndentSpaces -= z_nindent
          CASE z_lfunction .AND. lReturning .AND. EVAL( bFuncHead, UPPER( cLineText ))  // Is this the first line of a PROCEDURE or FUNCTION?
               nIndentSpaces := 0
          ENDCASE

          nIndentSpaces := MAX( 0, nIndentSpaces )  // negative values shouldn't happen
          IF LEFT( cLineText, 1 ) == "*"
               IF z_lhorizln .AND. "---" $ cLineText .AND. cLineText == CHARONLY( "*-", cLineText )  // it's a horizontal spacer line
                    cOrigText := "*" + REPLICATE( "-", 60 ) + "*"  // move it to the left margin
               ENDIF
                                                              * It's a comment line. Dont adjust anything.
               cTrialLine := cOrigText
          ELSE
               cTrialLine := TRIM( SPACE( nIndentSpaces + nMLFudge ) + cLineText )
          ENDIF

          IF lAddAction                             // there's an ACTION statement to be replaced
                                                               * paste the ACTION clause back, as close as possible to the desired aligned column
               cTrialLine := PADR( cTrialLine, MAX( LEN( TRIM( cTrialLine )) + 1, z_naction - 1 )) + cAction
          ENDIF

          IF z_lcomment                             // if we want to put the comment in a specific column
               nCommentCol := MAX( z_ncomment, LEN( cTrialLine ) + 2 )
               cTrialLine := TRIM( PADR( cTrialLine, nCommentCol - 1 ) + " " + cComment )
          ENDIF
          cTrialLine += IIF( lAddSemi, ";", "" )

                                                               * Is the line too long?
          WHILE LEN( cTrialLine ) > 254
               FOR nBreakPoint := LEN( cTrialLine ) - 2 TO 1 STEP -1  // start at the right end of the line
                    IF SUBSTR( cTrialLine, nBreakPoint, 3 ) == SPACE( 3 )  // Replace all 3-space voids with 2-space voids
                         cTrialLine := LEFT( cTrialLine, nBreakPoint ) + SUBSTR( cTrialLine, nBreakPoint + 2 )
                    ENDIF
               NEXT
               EXIT
          ENDDO

                                                               * Is it still too long?
          WHILE LEN( cTrialLine ) > 254
               FOR nBreakPoint := LEN( cTrialLine ) - 1 TO 1 STEP -1  // start at the right end of the line
                    IF SUBSTR( cTrialLine, nBreakPoint, 2 ) == SPACE( 2 )  // Replace all 2-space voids with 1-space voids
                         cTrialLine := LEFT( cTrialLine, nBreakPoint ) + SUBSTR( cTrialLine, nBreakPoint + 2 )
                    ENDIF
               NEXT
               EXIT
          ENDDO

          IF LEN( cTrialLine ) > 254                // seems impossible it would still be too long!
               CLOSE MCITEXT
               MsgStop( "Line " + LTRIM( STR( nThisLine, 4 )) + " is longer than 254 characters   ", "Aborting..." )
               RETU NIL
          ENDIF

          SELECT MCITEXT
          REPLACE MCITEXT->cTxtLine WITH cTrialLine
          DBGOTO( RECNO())

                                                    * Now to adjust the indentation for the next line
          cTrialLine := UPPER( LTRIM( cTrialLine ))
          IF z_lmultline                            // do we indent multi-line commands?
               DO CASE
               CASE LEFT( cLineText, 2 ) == "* "
                                                    * It's a comment line. Don't adjust spacing
               CASE RIGHT( cTrialLine, 1 ) == ";" .AND. ! lMultLine  // is this command continued on the next line?
                    lMultLine  := .T.               // this is part of a multiline command
                    lMLLine1   := .T.               // this is the first line of a multiline command
                    nMLFudge   := z_nindent         // add extra indentation for the next line
               CASE RIGHT( cTrialLine, 1 ) == ";"   // is this command continued on the next line?
                    lMLLine1   := .F.               // this isn't the first line of the multiline command
               CASE lMultLine                       // the previous line ended in a semicolon, but this one doesn't
                    lMLLine1   := .F.               // this isn't the first line of the multiline command
                    lMultLine  := .F.
                    nMLFudge   := 0                 // stop the "extra" indentation after this line
               ENDCASE
          ENDIF

          DO CASE
          CASE LEFT( cLineText, 2 ) == "* "
                                                    * It's a comment line. Don't adjust spacing
          CASE z_lfunction .AND. EVAL( bFuncHead, UPPER( cLineText ))
               nIndentSpaces := z_nindent           // this line is at the left margin; indent lines in the FUNCTION
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation

               IF lReturning                        // we need to backdent the most recent RETURN line
                    nThisRecNo := MCITEXT->( RECNO())  // insert a record pointer
                    GO nLastReturn                  // we're starting a new FUNCTION; need to backdent the most recent RETURN statement
                    REPLACE MCITEXT->cTxtLine WITH LTRIM( MCITEXT->cTxtLine )  // move the RETURN statement to the left margin
                    DBGOTO( RECNO())
                    GO nThisRecNo                   // return to where we were
               ENDIF
               lReturning := .F.

          CASE z_lfunction .AND. LEFT( UPPER( cLineText ), 4 ) == "RETU"   // This MIGHT be the last RETURN line in a PROCEDURE or FUNCTION
               lReturning := .T.
               nLastReturn := MCITEXT->( RECNO() )

          CASE z_lifcase .AND. ( LEFT( cTrialLine, 5 ) $ "CASE " .OR. LEFT( cTrialLine, 4 ) $ "ELSE/OTHE" ;  // indent IF/ELSE/ENDIF/CASE statements?
               .OR. LEFT( cTrialLine, 7 ) == "DO CASE" .OR. LEFT( cTrialLine, 3 ) == "IF " )  // indent IF/ELSE/ENDIF/CASE statements?
               * v 1.7 change: don't indent "IF EMPTY( cText );cText := 'pierpaolo';ENDIF"
               IF ! OneLineIfEndif( cTrialLine )
                    nIndentSpaces += z_nindent
                    nMLFudge := 0                   // next line will already be indented; no need to add multiline indentation
               ENDIF
          CASE z_lwindow .AND. (  LEFT( cTrialLine, 11 ) == "DEFINE WIND" .OR. LEFT( cTrialLine, 9 ) == "DEFI WIND" )  // indent DEFINE WINDOW statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_lwindow .AND. (  LEFT( cTrialLine, 11 ) == "DEFINE SPLI" .OR. LEFT( cTrialLine, 9 ) == "DEFI SPLI" )  // indent DEFINE SPLITBOX statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_lmenuitem .AND. ( LEFT( cTrialLine, 11 ) == "DEFINE MENU" .OR. LEFT( cTrialLine, 9 ) == "DEFI MENU" ;  // indent DEFINE MENU statements?
               .OR. LEFT( cTrialLine, 16 ) == "DEFINE MAIN MENU" .OR. LEFT( cTrialLine, 14 ) == "DEFI MAIN MENU" )  // indent DEFINE MAIN MENU statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_lmenuitem .AND. ( LEFT( cTrialLine, 11 ) == "DEFINE DROP" .OR. LEFT( cTrialLine, 9 ) == "DEFI DROP" ;  // indent DEFINE DROPDOWN MENU statements?
               .OR. LEFT( cTrialLine, 20 ) == "DEFINE DROPDOWN MENU" .OR. LEFT( cTrialLine, 14 ) == "DEFI DROP MENU" )  // indent DEFINE DROPDOWN MENU statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_lpopup .AND. ( LEFT( cTrialLine, 11 ) == "DEFINE POPU" .OR. LEFT( cTrialLine, 9 ) == "DEFI POPU" ;  // indent POPUP statements?
               .OR. LEFT( cTrialLine, 6 ) == "POPUP "  )  // indent POPUP statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_ldowhile .AND. LEFT( cTrialLine, 9 ) == "DO WHILE "  // indent DO WHILE / WHILE statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_ldowhile .AND. LEFT( cTrialLine, 10 ) == "BEGIN INI "  // indent BEGIN INI statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_ldowhile .AND. LEFT( cTrialLine, 15 ) == "BEGIN SECUENCE "  // indent BEGIN SECUENCE statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_ldowhile .AND. LEFT( cTrialLine, 9 ) == "HB_FUNC( "  // indent HB_FUNC statements?
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_lmultline .AND. lMultLine .AND. ! lMLLine1
                                                                                            * this is the second (or subsequent) line of a multiline command; don't adjust the spacing
          CASE z_ldowhile .AND. LEFT( cTrialLine, 6 ) == "WHILE "  // this is not a DO WHILE statement, it's a WHILE condition for e.g. APPEND ... WHILE
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
          CASE z_lfornext .AND. LEFT( cTrialLine, 4 ) == "FOR "  // this is not a FOR/NEXT statement, it's a FOR condition for e.g. APPEND ... FOR
               nIndentSpaces += z_nindent
               nMLFudge := 0                        // next line will already be indented; no need to add multiline indentation
        ENDCASE

     NEXT nThisLine

    PutItBack( cPrgFile, nLastLine )  // copy lines into source file

RETURN NIL

*------------------------------------------------------------*
FUNCTION BublSort( nElements, aArray1, aArray2, aArray3, aArray4 )
*------------------------------------------------------------*
    LOCAL cThisElement                              // contents of this array element
    LOCAL i
    LOCAL nNeed2Sort := 2                           // how many arrays are involved in the sort?

    IF VALTYPE( aArray3 ) == "A"
       ++nNeed2Sort
       IF VALTYPE( aArray4 ) == "A"
          ++nNeed2Sort
       ENDIF
    ENDIF

    FOR i := 1 TO ( nElements - 1 )
        IF aArray1[ i ] > aArray1[ i + 1 ]
           cThisElement     := aArray1[ i ]
           aArray1[ i ]     := aArray1[ i + 1 ]
           aArray1[ i + 1 ] := cThisElement
           cThisElement     := aArray2[ i ]
           aArray2[ i ]     := aArray2[ i + 1 ]
           aArray2[ i + 1 ] := cThisElement
           IF nNeed2Sort > 2
              cThisElement     := aArray3[ i ]
              aArray3[ i ]     := aArray3[ i + 1 ]
              aArray3[ i + 1 ] := cThisElement
              IF nNeed2Sort == 4
                 cThisElement     := aArray4[ i ]
                 aArray4[ i ]     := aArray4[ i + 1 ]
                 aArray4[ i + 1 ] := cThisElement
              ENDIF
           ENDIF
           i := MAX( 0, i - 2 )
        ENDIF
    NEXT i

RETURN NIL

*------------------------------------------------------------*
FUNCTION CharOnly( cOKChars, cString2Check )
*------------------------------------------------------------*
    LOCAL cSingleChar
    LOCAL cStringOutput := ""
    LOCAL i

    FOR i := 1 TO LEN( cString2Check )
        IF ( cSingleChar := SUBSTR( cString2Check, i, 1 )) $ cOKChars
            cStringOutput += cSingleChar
        ENDIF
    NEXT i

RETURN cStringOutput

*------------------------------------------------------------*
FUNCTION OneLineIfEndif( cThisLine )
*------------------------------------------------------------*
    LOCAL nSemiColons := 0                          // how many semicolons in the line?

    cThisLine := UPPER( cThisLine )

    IF "ENDI" $ UPPER( cThisLine ) .AND. ";" $ cThisLine
        DO WHILE ";" $ cThisLine
            ++nSemiColons
            cThisLine := TRIM( LTRIM( SUBSTR( cThisLine, AT( ";", cThisLine ) + 1 )))
        ENDDO
        IF nSemiColons > 1 .AND. LEFT( cThisLine, 4 ) == "ENDI"  // must be at least two semicolons to complete IF;command;ENDIF
           RETURN .T.
        ENDIF
    ENDIF

RETURN .F.

*------------------------------------------------------------------------------------*
FUNCTION PutItBack( cPrgFile, nLastLine )
*------------------------------------------------------------------------------------*
    LOCAL cSrcFile                                                    // name of the actual source code file
    LOCAL cTempFile  := LEFT( cPrgFile, LEN( cPrgFile ) - 1 ) + "x"
    LOCAL nHalfMax                                                    // half the length of the FUNCTION list lines
    LOCAL nHandle                                                     // file handle
    LOCAL nMaxLength := 78                                            // length of longest FUNCTION declaration
    LOCAL nThisFunc
    LOCAL nThisLine  := 0
    LOCAL cLineText, cText
    LOCAL nHeaderLen

    IF FILE( cTempFile )
       FERASE( cTempFile )
    ENDIF

    cSrcFile := UPPER( TRIM( cPrgFile ))                              // C:\MINIGUI\MYCODE\SOURCE.PRG

    DO WHILE "\" $ cSrcFile
       cSrcFile := LTRIM( SUBSTR( cSrcFile, AT( "\", cSrcFile ) + 1 ))  // SOURCE.PRG
    ENDDO

    nHandle := FCREATE( cTempFile )

    SELECT MCITEXT

    FOR nThisLine := 1 TO nLastLine
        GO nThisLine
        cLineText := TRIM( LTRIM( MCITEXT->cTxtLine ))
        cText     := TRIM( MCITEXT->cTxtLine )
        FWRITE( nHandle, cText + IIF( nThisLine == nLastLine, "", CRLF ))
        SELECT MCITEXT
    NEXT nThisLine

    CLOSE MCITEXT
    FCLOSE( nHandle )
    FERASE( cPrgFile )
    RENAME ( cTempFile ) TO ( cPrgFile )
    MsgInfo( cPrgFile + CRLF + "Reindenting completed!   ", "Success..." )

RETURN NIL

*------------------------------------------------------------*
FUNCTION What2Store( cFieldName, lBlanking )
*------------------------------------------------------------*
    LOCAL nFieldPos := FIELDPOS( cFieldName )

    IF ! VALTYPE( lBlanking ) == "L"
        lBlanking := .F.
    ENDIF

    IF lBlanking
        RETURN BLANK( FIELDGET( nFieldPos ))
    ENDIF
RETURN FIELDGET( nFieldPos )

*------------------------------------------------------------*
FUNCTION Blank( xItem )
*------------------------------------------------------------*
    DO CASE
       CASE VALTYPE( xItem ) == "C"
            RETURN SPACE(LEN( xItem ))
       CASE VALTYPE( xItem ) == "D"
            RETURN CTOD( "" )
       CASE VALTYPE( xItem ) == "L"
            RETURN .F.
       CASE VALTYPE( xItem ) == "N"
            RETURN 0
       CASE VALTYPE( xItem ) == "M"
            RETURN ""
    ENDCASE
RETURN NIL

Procedure Nuevo()
   N := 1
Return
