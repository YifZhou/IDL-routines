
pro roisurf_done, Event
  widget_control, event.top, /destroy
end

pro idp3_roisurf_event, Event
  widget_control,Event.Id,get_uvalue=Ev
end

pro idp3_roisurf,  event

@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  ; Get the ROI data and pop up a widget and display the surface plot.
  roi = info.roi
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend
  zoom = (*roi).roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = info.roiioz

  idp3roisurf = widget_base (group_leader=event.top, $
			     title='IDP3-ROI Surface Plot', $
			     xoffset=info.wpos.swp[0], $
			     yoffset=info.wpos.swp[1],/column)
  ssdraw = widget_draw(idp3roisurf,xsize=350, ysize=350, retain=info.retn)
  donebutton = widget_button (idp3roisurf, value='Done', $
			      Event_Pro='roisurf_done')

  widget_control, idp3roisurf, /realize

  WIDGET_CONTROL, ssdraw, GET_VALUE=drawfield_id
  wset, drawfield_id
;  surface, $
;	idp3_congrid((*info.dispim)[x1+info.sxoff:x2+info.sxoff,$
;	y1+info.syoff:y2+info.syoff], xsize, ysize, zoom, ztype, info.pixorg)
  surface, idp3_congrid((*info.dispim)[x1:x2,y1:y2], $
	 xsize, ysize, zoom, ztype, info.pixorg)
  wset, info.drawid1

  xmanager, 'idp3roisurf', idp3roisurf
end
