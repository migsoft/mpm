/*
 * ooHG – Object Oriented Harbour GUI library
 * http://www.oohg.org – http://sourceforge.net/projects/oohg
 * "Sizedemo.prg" – Basado en el ejemplo de Vic
 * (c) 2010-2019 MigSoft <migsoft/at/oohg.org>
 */

#include "oohg.ch"
#define CRLF  HB_OsNewLine()

PROCEDURE MAIN3
   LOCAL oWnd

   DEFINE WINDOW MAIN3 OBJ oWnd WIDTH 520 HEIGHT 300 TITLE "WinSize" MODAL

      DEFINE MAIN MENU
         DEFINE POPUP "File"
            MENUITEM "New…" ACTION Nil
            MENUITEM "Save…" ACTION Nil
            MENUITEM "Print…" ACTION Nil
            SEPARATOR
            MENUITEM "Exit…" ACTION IF(MsgYesNo("Exit?";
                   ,"Release Program"),oWnd:release, Nil)
         END POPUP
      END MENU

      @ 10 , 10 BUTTON Boton1   CAPTION "GetWindowRect"   ;
        WIDTH 120 ACTION Window( oWnd )
      @ 10 ,130 BUTTON Boton2   CAPTION "GetClientRect"   ;
        WIDTH 120 ACTION Client( oWnd )
      @ 10 ,250 BUTTON Boton3   CAPTION "GetBorderHeight" ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetBorderHeight(oWnd:hwnd)))
      @ 10 ,370 BUTTON Boton4   CAPTION "GetBorderWidth"  ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetBorderWidth(oWnd:hwnd)))

      @ 50 , 10 BUTTON Boton5   CAPTION "GetWindowRow"    ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetWindowRow(oWnd:hWnd)))
      @ 50 ,130 BUTTON Boton6   CAPTION "GetWindowCol"    ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetWindowCol(oWnd:hWnd)))

      @ 50 ,250 BUTTON Boton7   CAPTION "GetWindowHeight" ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetWindowHeight(oWnd:hWnd)))
      @ 50 ,370 BUTTON Boton8   CAPTION "GetWindowWidth"  ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetWindowWidth(oWnd:hWnd)))

      @ 90 , 10 BUTTON Boton9   CAPTION "GetDeskTopHeight" ;
        WIDTH 120 ACTION MsgInfo(str(GetDesktopHeight()))
      @ 90 ,130 BUTTON Boton10  CAPTION "GetDeskTopWidth"  ;
        WIDTH 120 ACTION MsgInfo(str(GetDesktopWidth()))

      @ 130, 10 BUTTON Boton11  CAPTION "GetTitleHeight"   ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetTitleHeight(oWnd:hwnd)))
      @ 130,130 BUTTON Boton12  CAPTION "GetMenuBarHeight" ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetMenuBarHeight(oWnd:hwnd)))

      @ 170, 10 BUTTON Boton13  CAPTION "Get3DEdgeHeight"  ;
        WIDTH 120 ACTION ;
        MsgInfo(str(Get3DEdgeHeight(oWnd:hwnd)))
      @ 170,130 BUTTON Boton14  CAPTION "Get3DEdgeWidth"   ;
        WIDTH 120 ACTION ;
        MsgInfo(str(Get3DEdgeWidth(oWnd:hwnd)))

      @ 90 ,250 BUTTON Boton15   CAPTION "GetBottomBarHeight" ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetDesktopHeight()-GetWindowHeight(oWnd:hWnd)))

      @ 90 ,370 BUTTON Boton16   CAPTION "GetTaskBarHeight" ;
        WIDTH 120 ACTION ;
        MsgInfo(str(GetTaskBarHeight()))

   END WINDOW

   CENTER WINDOW Main3
   ACTIVATE WINDOW Main3

RETURN

FUNCTION Window( oWnd )
   LOCAL aInfo
   aInfo := ARRAY( 4 )
   GetWindowRect( oWnd:hWnd, aInfo )
   MSGINFO( "Izquierda " + STR( aInfo[ 1 ],5 ) + CRLF + ;
            "Arriba    " + STR( aInfo[ 2 ],5 ) + CRLF + ;
            "Derecha   " + STR( aInfo[ 3 ],5 ) + CRLF + ;
            "Abajo     " + STR( aInfo[ 4 ],5 ) + CRLF )
RETURN Nil

FUNCTION Client( oWnd )
   LOCAL aInfo 

   aInfo := ARRAY( 4 ) 
   GetClientRect( oWnd:hWnd, aInfo ) 
   MSGINFO( "Izquierda " + STR( aInfo[ 1 ],5 ) + CRLF + ;
            "Arriba    " + STR( aInfo[ 2 ],5 ) + CRLF + ; 
            "Derecha   " + STR( aInfo[ 3 ],5 ) + CRLF + ; 
            "Abajo     " + STR( aInfo[ 4 ],5 ) + CRLF ) 
RETURN Nil 


#pragma BEGINDUMP

#include <windows.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "commctrl.h"

// JD 07/22/2007
HB_FUNC( GET3DEDGEHEIGHT )
{
   hb_retni( GetSystemMetrics(SM_CYEDGE) );
}

// JD 07/22/2007
HB_FUNC( GET3DEDGEWIDTH )
{
   hb_retni( GetSystemMetrics(SM_CXEDGE) );
}

HB_FUNC( GETTASKBARHEIGHT )
{
   RECT rect;

   GetWindowRect( FindWindow( "Shell_TrayWnd", NULL ), &rect );
   hb_retni( ( INT ) rect.bottom - rect.top );
}

#pragma ENDDUMP
