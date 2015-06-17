
pro roishadesurf_done, Event
  widget_control, event.top, /destroy
end

pro idp3_roishadesurf_event, Event
  widget_control,Event.Id,get_uvalue=Ev
end

pro idp3_roishadesurf,  event
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  ; Just extract the ROI data and pop-up a window showing the shade-surf.
  roi = info.roi
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend

  idp3roishadesurf = widget_base (group_leader=event.top, $
				  title='IDP3-ROI Shade Surface Plot', $
				  xoffset=info.wpos.shdswp[0], $
			          yoffset=info.wpos.shdswp[1],/column)
  ssdraw = widget_draw(idp3roishadesurf,xsize=350, ysize=350, retain=info.retn)
  donebutton = widget_button (idp3roishadesurf, value='Done', $
			      Event_Pro='roishadesurf_done')

  widget_control, idp3roishadesurf, /realize

  WIDGET_CONTROL, ssdraw, GET_VALUE=drawfield_id
  wset, drawfield_id
;  shade_surf, $
;	(*info.dispim)[x1+info.sxoff:x2+info.sxoff,y1+info.syoff:y2+info.syoff]
  shade_surf, (*info.dispim)[x1:x2,y1:y2]
  wset, info.drawid1

  xmanager, 'idp3roishadesurf', idp3roishadesurf
end
