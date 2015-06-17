
pro Selectim_Event, event

@idp3_errors

  Widget_Control, event.top, Get_UValue=selectinfo

  ; Figure out which image name the user clicked on.
  pos = event.offset
  columnRow = WIDGET_INFO(selectinfo.dispnames, Text_Offset_To_XY=pos)
  row = columnRow(1)
  ni = n_elements(*selectinfo.info.images)
  if row gt ni-1 then row = ni-1

  ; Make that image the 'moving' image.
  selectinfo.info.moveimage = row
  Widget_Control, selectinfo.info.idp3Window, Set_UValue=selectinfo.info

  ; Call the ShowIm routine and exit.
  ; If ShowIm is already running, kill it first.
  if (XRegistered('idp3_showim')) then begin
    geo = Widget_Info(selectinfo.info.ShowImBase, /geometry)
    selectinfo.info.wpos.siwp[0] = geo.xoffset - selectinfo.info.xoffcorr
    selectinfo.info.wpos.siwp[1] = geo.yoffset - selectinfo.info.yoffcorr
    Widget_Control, selectinfo.info.idp3Window, Set_UValue=selectinfo.info
    Widget_Control, selectinfo.info.ShowImBase, /Destroy
    idp3_showim, $
      {WIDGET_BUTTON,ID:0L,TOP:selectinfo.info.idp3Window,HANDLER:0L,SELECT:0}
  endif

  ; Also Adjust Position.
  if (XRegistered('idp3_adjustposition')) then begin
    geo = Widget_Info(selectinfo.info.apWindow, /geometry)
    selectinfo.info.wpos.apwp[0] = geo.xoffset - selectinfo.info.xoffcorr
    selectinfo.info.wpos.apwp[1] = geo.yoffset - selectinfo.info.yoffcorr
    Widget_Control, selectinfo.info.idp3Window, Set_UValue=selectinfo.info
    Widget_Control, selectinfo.info.apWindow, /Destroy
    idp3_adjustposition, $
      {WIDGET_BUTTON,ID:0L,TOP:selectinfo.info.idp3Window,HANDLER:0L,SELECT:0}
  endif

  ; Make sure the structure is saved after ShowIm is restarted so we
  ; will have access to the new value of info.ShowImBase for the next load.
  Widget_Control, selectinfo.info.idp3Window, Get_UValue=tempinfo
  selectinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=selectinfo

  Widget_Control, event.top, /Destroy

end


pro Idp3_SelectIm, event

; This code is really obsolete because the user can select an
; image to be the 'move' image by just clicking on the image name
; in the "show images" widget.  I leave it in just in case somebody
; still uses it.

@idp3_errors

  if (XRegistered('idp3_selectim')) then return

  Widget_Control, event.top, Get_UValue=info

  ; Pop up a window with the list of images, wait for the user to
  ; click on one of them.

  c = size(*info.images)
  if (c[0] eq 0) then return

  ; Find the maximum length of the image names and set the name field widths.
  ; Also assemble an array containing the image names.
  ilen = 0
  for i = 0, n_elements(*info.images)-1 do begin
    thisname = (*(*info.images)[i]).name
    if strlen(thisname) gt ilen then ilen=strlen(thisname)
    if i eq 0 then begin
      nlist = thisname
    endif else begin
      nlist = [nlist,thisname]
    endelse
  endfor

  selectimWindow = Widget_Base(Title = 'IDP3 Select Image Window', /Column, $
			     Group_Leader = event.top, $
			     XOffset = info.wpos.seliwp[0], $
			     YOffset = info.wpos.seliwp[1])

  dispnames = Widget_Text(selectimWindow, XSize=ilen, $
			  YSize=20, $
			  Event_Pro = 'SelectIm_Event', $
			  value = nlist, /SCROLL, /ALL_EVENTS)

  selectinfo = { info        : info,        $
                 dispnames   : dispnames,   $
		 nlist       : nlist        }

  Widget_Control, selectimWindow, /Realize
  Widget_Control, selectimWindow, Set_UValue=selectinfo
  XManager, 'idp3_selectim', selectimWindow, /No_Block

end


