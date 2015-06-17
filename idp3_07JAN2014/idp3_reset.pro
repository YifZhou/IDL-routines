pro idp3reset_ev, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=resetinfo
  Widget_Control, resetinfo.info.idp3Window, Get_UValue=info

  case event.id of

  resetinfo.dxsizfield: begin
    Widget_Control, resetinfo.dxsizfield, Get_Value = dxsize
  end

  resetinfo.dysizfield: begin
    Widget_Control, resetinfo.dysizfield, Get_Value = dysize
  end

  resetinfo.sxsizfield: begin
    Widget_Control, resetinfo.sxsizfield, Get_Value = sxsize
  end

  resetinfo.sysizfield: begin
    Widget_Control, resetinfo.sysizfield, Get_Value = sysize
  end

  resetinfo.scrollbutton: begin
    scroll = event.value
    info.scrollmain = scroll
  end

  resetinfo.helpbutton: begin
    if info.pdf_viewer eq '' then begin
      tmp = idp3_findfile('idp3_resize.hlp')
      xdisplayfile, tmp
    endif else begin
      tmp = idp3_findfile('idp3_resizedisplay.pdf')
      str = info.pdf_viewer + ' ' + tmp
      if !version.os eq 'darwin' then str = 'open -a ' + str
      spawn, str
    endelse
  end

  resetinfo.donebutton: begin
    Widget_Control, resetinfo.dxsizfield, Get_Value=drawxsize
    Widget_Control, resetinfo.dysizfield, Get_Value=drawysize
    Widget_Control, resetinfo.sxsizfield, Get_Value=scrollxsize
    Widget_Control, resetinfo.sysizfield, Get_Value=scrollysize
    scroll = info.scrollmain
    if scroll eq 1 then begin
      if scrollxsize le 0 or scrollysize le 0 then begin
        scroll = 0
	str = 'Cannot scroll image display, scroll size is 0!'
        stat = Widget_Message(str)
      endif
      if scrollxsize ge drawxsize or scrollysize ge drawysize then begin
	scroll = 0
	str = 'Cannot scroll display, scroll size is larger than display size!'
	stat = Widget_Message(str)
      endif
    endif
    Widget_Control, info.idp3Draw, /Destroy
    if scroll eq 0 then begin
      idp3Draw = Widget_Draw(info.gbase, XSize = drawxsize, YSize = drawysize, $
		 /Motion_Events, /Button_Events, Event_Pro = 'Idp3_Draw', $
		 retain=info.retn)
    endif else begin
      idp3Draw = Widget_Draw(info.gbase, XSize = drawxsize, YSize = drawysize, $
		 x_scroll_size = scrollxsize, y_scroll_size = scrollysize, $
		 /scroll, /Motion_Events, /Button_Events, $
		 Event_Pro='Idp3_Draw', retain=info.retn)
    endelse
    info.scrollmain = scroll
    Widget_Control, idp3Draw, Get_Value = drawid1
    info.idp3Draw = idp3Draw
    info.drawid1 = drawid1
    info.drawxsize = drawxsize
    info.drawysize = drawysize
    info.scrollxsize = scrollxsize
    info.scrollysize = scrollysize
    Widget_Control, info.idp3Window, Set_UValue=info
    idp3_display, info
    Widget_Control, event.top, /Destroy
    return
  end
  endcase
  Widget_Control, event.top, Set_UValue=resetinfo
  Widget_Control, resetinfo.info.idp3Window, Set_UValue=info

end

pro Idp3_Reset, event
@idp3_errors
  ; destroy main display widget and recreate
  if XRegistered('idp3_reset') then return
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  dxsize = info.drawxsize
  dysize = info.drawysize
  sxsize = info.scrollxsize
  sysize = info.scrollysize
  scroll = info.scrollmain

  title = 'IDP3 Resize Main Display'
  resetbase = Widget_Base (Title=title, /Column, xoffset=info.wpos.printwp[0], $
			   yoffset=info.wpos.printwp[1])
  imbase = Widget_Base(resetbase, /Row)
  dxsizfield = cw_field(imbase, Value=dxsize, Title='Total Image Size X:', $
		uvalue='dxs', xsize=6, /Return_Events, /Floating)
  dysizfield = cw_field(imbase, Value=dysize, Title='Y:', $
		uvalue='dys', xsize=6, /Return_Events, /Floating)
  snames = ['No', 'Yes']
  scrollbutton = cw_bgroup(resetbase, snames, row=1, Label_Left = $
		 'Scroll Display:', uvalue='sbutton', set_value=scroll, $
		 exclusive=1, /no_release)
  scbase = Widget_Base(resetbase, /Row) 
  sxsizfield = cw_field(scbase, Value=sxsize, Title='Scrolled Image Size X:', $
		uvalue='sxs', xsize=6, /Return_Events, /Floating)
  sysizfield = cw_field(scbase, Value=sysize, Title='Y:', $
		uvalue='sys', xsize=6, /Return_Events, /Floating)
  donebase = Widget_Base(resetbase, /Row)
  helpbutton = Widget_Button(donebase, Value='Help')
  donebutton = Widget_Button(donebase, Value='Done')

  resetinfo = { dxsizfield   : dxsizfield,   $
		dysizfield   : dysizfield,   $
		scrollbutton : scrollbutton, $
		sxsizfield   : sxsizfield,   $
		sysizfield   : sysizfield,   $
		helpbutton   : helpbutton,   $
		donebutton   : donebutton,   $
	        info         : info          }

  Widget_Control, resetbase, Set_UValue = resetinfo

  Widget_Control, resetbase, /Realize
  XManager, 'idp3_reset', resetbase, /No_Block, $
	    Event_Handler = 'idp3reset_ev'
end
