pro idp3_spreaddone, Event
  geo = Widget_Info(event.top, /geometry)
  Widget_Control,Event.Top,Get_UValue=info
  Widget_Control,info.idp3Window,Get_UValue=info
  wset, (*info.roi).drawid2

  ; Erase the box from the ROI graphics window if needed.
  if (info.sprd.sx ne -2) then begin
    tv, *(*info.roi).roiimage
    info.sprd.sx = -2
  endif

  info.wpos.sswp[0] = geo.xoffset - info.xoffcorr
  info.wpos.sswp[1] = geo.yoffset - info.yoffcorr
  Widget_Control,Event.Top,Set_UValue=info
  Widget_Control,info.idp3Window,Set_UValue=info
  wset, info.drawid1
  Widget_Control, Event.Top, /destroy
end

pro idp3spread_event, Event
  Widget_Control,Event.Top,Get_UValue=info
  Widget_Control,info.idp3Window,Get_UValue=info

  ; Decode the event.
  left   = event.sel_left
  right  = event.sel_right
  top    = event.sel_top
  bottom = event.sel_bottom

  ; preserve the view area and cells
  view = widget_info(info.sstable, /table_view)
  cells = widget_info(info.sstable, /table_select)
  info.sprd.view = view
  info.sprd.cells = cells

  ; Get ROI information.
  roi = *info.roi
  wset, roi.drawid2
  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend
  zoom = roi.roizoom

  ; As the user selects spreadsheet cells with the cursor, draw a
  ; box around those pixels on the ROI graphics display.
  if (left ne -1) then begin
    ; cell selection
    ; a -2 in sprd.sx signals that no box is currently drawn on the ROI.
    if info.sprd.sx eq -2 then begin
      ; Draw box.
      info.sprd.sx = left  * zoom
      info.sprd.ex = (right+1) * zoom
      info.sprd.sy = ((y2-y1+1)-bottom-1) * zoom
      info.sprd.ey = ((y2-y1+1)-top)    * zoom
      ss_color = info.color_spsh
      if ss_color lt 0 then ss_color=200
      plots, info.sprd.sx, info.sprd.sy, color=ss_color, /device
      plots, info.sprd.sx, info.sprd.ey, color=ss_color, /device, /continue
      plots, info.sprd.ex, info.sprd.ey, color=ss_color, /device, /continue
      plots, info.sprd.ex, info.sprd.sy, color=ss_color, /device, /continue
      plots, info.sprd.sx, info.sprd.sy, color=ss_color, /device, /continue
    endif else begin
      ; Erase old box.
      tv, *(*info.roi).roiimage
      ; Draw new box.
      info.sprd.sx = left  * zoom
      info.sprd.ex = (right+1) * zoom
      info.sprd.sy = ((y2-y1+1)-bottom-1) * zoom
      info.sprd.ey = ((y2-y1+1)-top)    * zoom
      ss_color = info.color_spsh
      if ss_color lt 0 then ss_color=200
      plots, info.sprd.sx, info.sprd.sy, color=ss_color, /device
      plots, info.sprd.sx, info.sprd.ey, color=ss_color, /device, /continue
      plots, info.sprd.ex, info.sprd.ey, color=ss_color, /device, /continue
      plots, info.sprd.ex, info.sprd.sy, color=ss_color, /device, /continue
      plots, info.sprd.sx, info.sprd.sy, color=ss_color, /device, /continue
    endelse
    xbeg = left + x1
    xend = right + x1
    ybeg = y2 - bottom
    yend = y2 - top
    if xbeg eq xend then xstr = strtrim(string(xbeg),2) else xstr = $
       strtrim(string(xbeg),2) + ':' + strtrim(string(xend),2)
    if ybeg eq yend then ystr = strtrim(string(ybeg),2) else ystr = $
       strtrim(string(ybeg),2) + ':' + strtrim(string(yend),2)
    pstr = 'Spreadsheet pixel(s) selected: [' + xstr + ',' + ystr + ']'
    if xbeg eq xend and ybeg eq yend $
      then str = pstr + string((*info.dispim)[xbeg,ybeg]) $
      else str = pstr + string((*info.dispim)[xbeg:xend,ybeg:yend])
      idp3_updatetxt, info, str
  endif
  wset, info.drawid1
  Widget_Control,Event.Top,Set_UValue=info
  Widget_Control,info.idp3Window,Set_UValue=info
end

pro idp3_Spreadsheet, event

@idp3_errors

  ; Pop up a spreadsheet widget.

  if (XRegistered('idp3_spreadsheet')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  ; Get ROI information.
  roi = *info.roi
  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend

  ; Set up the arrays of strings for labeling the X and Y cell numbers.
;  for i = x1+info.sxoff,x2+info.sxoff do begin
;    if i eq x1+info.sxoff then xstrings = string(format='(i4)',i) $
;    else xstrings = [xstrings,string(format='(i4)',i)]
;  endfor
;  for i = y2+info.syoff,y1+info.syoff,-1 do begin
;    if i eq y2+info.syoff then ystrings = string(format='(i4)',i) $
;    else ystrings = [ystrings,string(format='(i4)',i)]
;  endfor
  for i = x1, x2 do begin
    if i eq x1 then xstrings = string(format='(i4)',i) $
    else xstrings = [xstrings,string(format='(i4)',i)]
  endfor
  for i = y2, y1, -1 do begin
    if i eq y2 then ystrings = string(format='(i4)',i) $
    else ystrings = [ystrings,string(format='(i4)',i)]
  endfor

  ; Get the data pixel values, reverse them in Y because the spreadsheet
  ; has the origin in the upper left.
;  data = (*info.dispim)[x1+info.sxoff:x2+info.sxoff,y1+info.syoff:y2+info.syoff]
  data = (*info.dispim)[x1:x2,y1:y2]
  data = reverse(data,2)

  ; Make the widget.
  idp3spread = widget_base (group_leader=info.idp3Window, $
			    title='IDP3-ROI Spreadsheet', $
                            xoffset=info.wpos.sswp[0], $
			    yoffset=info.wpos.sswp[1],/column)

  info.spread = idp3spread

  idp3sstable = widget_table(idp3spread,value=data, /scroll,x_scroll_size=10, $
			     y_scroll_size=20,column_labels=xstrings, $
			     row_labels=ystrings,column_widths=80,units=0, $
			     /all_events)
  buttonbase = widget_base(idp3spread,/row)
  savebutton = widget_button (buttonbase, value='Save', $
			      Event_Pro='idp3_savespread')
  donebutton = widget_button (buttonbase, value='Done', $
			      Event_Pro='idp3_spreaddone')

  info.sstable = idp3sstable
  Widget_Control,tinfo.idp3Window,Set_UValue=info
  Widget_Control, idp3spread, Set_UValue=info

  view = info.sprd.view
  cells = info.sprd.cells

  Widget_Control, idp3spread, /Realize
  XManager, 'idp3_spreadsheet', idp3spread, /No_Block, $
            Event_Handler='idp3spread_event'
  
  if cells[0] gt 0 then begin
    Widget_Control, info.sstable, Set_Table_Select = cells
  endif
  if view[0] gt 0 then begin
    Widget_Control, info.sstable, Set_Table_View = view
  endif
end
