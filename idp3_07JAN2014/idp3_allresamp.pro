pro Resample_Cancel, event
  Widget_Control, event.top, /Destroy
end

pro resampup2, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 0
  resample, indx, event
end

pro resampup4, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 1
  resample, indx, event
end

pro resampup8, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 2
  resample, indx, event
end

pro resampup16, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 3
  resample, indx, event
end

pro resampdown2, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 4
  resample, indx, event
end

pro resampdown4, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 5
  resample, indx, event
end

pro resampdown8, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx = 6
  resample, indx, event
end

pro resampdown16, event

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info
  indx =7 
  resample, indx, event
end

pro Resample, indx, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=rsinfo
  Widget_Control, rsinfo.info.idp3Window, Get_UValue=info

  if indx lt 0 or indx gt 7 then indx = -1
  info.lastresamp = indx  

  case indx of
     0: zoomfact = 2.0
     1: zoomfact = 4.0
     2: zoomfact = 8.0
     3: zoomfact = 16.0
     4: zoomfact = 0.5
     5: zoomfact = 0.25
     6: zoomfact = 0.125
     7: zoomfact = 0.0625
     else: zoomfact = 1.0
   endcase
   c = size(*info.images)                       ; How many images?
   if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to display
      str = 'Nothing to resample!'
      idp3_updatetxt, info, str
   endif else begin
     numimages = n_elements(*info.images)
     str = 'Images resampled by factor of ' + string(zoomfact)
     for i = 0, numimages-1 do begin
       ; Resample this image
       m = (*info.images)[i]    ; m is a pointer to this image structure

       ; Zoom
       (*m).zoom = (*m).zoom * zoomfact

       ; Offsets
       xoff = (*m).xoff + (*m).xpoff
       xoff = xoff * zoomfact
       fracsa = float(xoff) - float(fix(xoff))
       intsa  = float(fix(xoff - fracsa))
       (*m).xpoff = fracsa
       (*m).xoff = intsa
       yoff = (*m).yoff + (*m).ypoff
       yoff = yoff * zoomfact
       fracsa = float(yoff) - float(fix(yoff))
       intsa  = float(fix(yoff - fracsa))
       (*m).ypoff = fracsa
       (*m).yoff = intsa

     endfor
   endelse
   Widget_Control, info.idp3Window, Set_UValue=info
   if XRegistered('idp3_adjustposition') then begin
     geo = Widget_Info(info.apWindow, /geometry)
     info.wpos.apwp[0] = geo.xoffset - info.xoffcorr
     info.wpos.apwp[1] = geo.yoffset - info.yoffcorr
     Widget_Control, info.idp3Window, Set_UValue=info
     Widget_Control, info.apWindow, /Destroy
     idp3_adjustposition, $
       {WIDGET_BUTTON,ID:0L,TOP:info.idp3Window,HANDLER:0L,SELECT:0}
   endif
   Widget_Control, info.idp3Window, Get_UValue=info
   idp3_display,info
   Widget_Control, info.idp3Window, Set_UValue=info
   Widget_Control, event.top, /Destroy
end


pro Idp3_allResamp, event

@idp3_structs
@idp3_errors
        
  resamps = [ $
	     '  2.0    ', $
	     '  4.0    ', $
	     '  8.0    ', $
	     ' 16.0    ', $
	     '  0.5    ', $
	     '  0.25   ', $
	     '  0.125  ', $
	     '  0.0625 ']
  labs = ['   ', '   ', '   ', '   ', '   ', '   ', '   ', '   ']
  marker = '  *'

  if (XRegistered('idp3_resample')) then return

  Widget_Control, event.top, Get_UValue=showinfo
  Widget_Control, showinfo.info.idp3Window, Get_UValue=info

  indx = info.lastresamp
  if indx ge 0 and indx le 7 then labs[indx] = marker

  rsWindow = Widget_base(Title = 'IDP3 Resample All', /Column, $
			 Group_Leader = event.top, /Modal, $
			 XOffset = info.wpos.scwp[0], $
			 YOffset = info.wpos.scwp[1])

  rslabel = Widget_Label(rsWindow, Value = 'Cumulative Multiplication Factor')

  rsupbase = Widget_Base(rsWindow, /Row)
  rsuplab = Widget_Label(rsupbase, Value='Increase:')
  rsup0lab = Widget_Label(rsupbase, Value=labs[0])
  rsup0button = Widget_Button(rsupbase, Value=resamps[0], $
	Event_Pro='resampup2')
  rsup1lab = Widget_Label(rsupbase, Value=labs[1])
  rsup1button = Widget_Button(rsupbase, Value=resamps[1], $
	Event_Pro='resampup4')
  rsup2lab = Widget_Label(rsupbase, Value=labs[2])
  rsup2button = Widget_Button(rsupbase, Value=resamps[2], $
	Event_Pro='resampup8')
  rsup3lab = Widget_Label(rsupbase, Value=labs[3])
  rsup3button = Widget_Button(rsupbase, Value=resamps[3], $
	Event_Pro='resampup16')
  rsdownbase = Widget_Base(rsWindow, /Row)
  rsdownlab = Widget_Label(rsdownbase, Value='Decrease:')
  rsdown0lab = Widget_Label(rsdownbase, Value=labs[4])
  rsdown0button = Widget_Button(rsdownbase, Value=resamps[4], $
	Event_Pro='resampdown2')
  rsdown1lab = Widget_Label(rsdownbase, Value=labs[5])
  rsdown1button = Widget_Button(rsdownbase, Value=resamps[5], $
	Event_Pro='resampdown4')
  rsdown2lab = Widget_Label(rsdownbase, Value=labs[6])
  rsdown2button = Widget_Button(rsdownbase, Value=resamps[6], $
	Event_Pro='resampdown8')
  rsdown3lab = Widget_Label(rsdownbase, Value=labs[7])
  rsdown3button = Widget_Button(rsdownbase, Value=resamps[7], $
	Event_Pro='resampdown16')
  rslab2 = Widget_Label(rsWindow, Value = $
      '* preceding button denotes last selection')
  cancelbutton = Widget_Button(rsWindow, Value = 'Cancel', $
		    Event_Pro = 'Resample_Cancel')

  rsinfo = { $
	     resamps      : resamps,       $
	     info         : info  }

  Widget_Control, rsWindow, /Realize
  Widget_Control, rsWindow, Set_UValue=rsinfo

  XManager, 'idp3_resample', rsWindow, /No_Block

end

