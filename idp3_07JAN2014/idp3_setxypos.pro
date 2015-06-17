pro Setxypos_Done, event
  Widget_Control, event.top, /Destroy
end


pro Setxypos_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=sxyinfo
  Widget_Control, sxyinfo.info.idp3Window, Get_UValue=tempinfo
  sxyinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=sxyinfo

  moveim = sxyinfo.info.moveimage
  imptr = (*sxyinfo.info.images)[moveim]

  case event.id of

    sxyinfo.xField: begin
      ; Read x position.
      Widget_Control, sxyinfo.xField, Get_Value = temp
      end

    sxyinfo.yField: begin
      ; Read y position.
      Widget_Control, sxyinfo.yField, Get_Value = temp
      end

    scinfo.applyButton: begin
      ; update x and y positions
      Widget_Control, sxyinfo.xField, Get_Value = temp
      str = 'SetXYPos: Setting X Position to: '+ string(temp)
      idp3_updatetxt, sxyinfo.info, str
      xoff = (*imptr).xpoff + (*imptr).xoff + scinfo.info.sxoff
      if xoff gt 0.0 then temp = temp - xoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then temp = temp / (*imptr).zoom
      if (*imptr).xpscl ne 1.0 and (*imptr).xpscl ne 0.0 $
	 then temp = temp / (*imptr).xpscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
	 then temp = temp - (*imptr).pad
      (*imptr).xpos = temp
      Widget_Control, scinfo.yField, Get_Value = temp
      str = 'SetXYPos: Setting Y Position to: ' + string(temp)
      idp3_updatetxt, sxyinfo.info, str
      yoff = (*imptr).ypoff + (*imptr).yoff + scinfo.info.syoff
      if yoff gt 0.0 then temp = temp - yoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then temp = temp / (*imptr).zoom
      if (*imptr).ypscl ne 1.0 and (*imptr).ypscl ne 0.0 $
	then temp = temp / (*imptr).ypscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
	then temp = temp - (*imptr).pad
      if (*imptr).flipy eq 1 then temp = (*imptr).ysiz - temp -1
      (*imptr).ypos = temp
      (*sxyinfo.info.images)[moveim] = imptr
      end
  else:
  endcase

  Widget_Control, event.top, Set_UValue=scinfo
  Widget_Control, scinfo.info.idp3Window, Set_UValue=scinfo.info

end

pro Idp3_SetXYpos, event

@idp3_structs
@idp3_errors

  ; Pop up a window when the user hits the 'set center' button
  ; on the adjust position widget.  Allow the user to change the
  ; X and Y coordinates of the center and press 'apply' to update.
  ; Done only closes widget, it does not update the center values.

  if (XRegistered('idp3_setxypos')) then return

  Widget_Control, event.top, Get_UValue = spinfo
  Widget_Control, spinfo.info.idp3Window, Get_UValue=tinfo
  spinfo.info = tinfo
  imptr = (*spinfo.info.images)[spinfo.info.moveimage]

  temp = (*imptr).xpos
  if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
    then temp = temp + (*imptr).pad
  if (*imptr).xpscl ne 1.0 then temp = temp * (*imptr).xpscl
  if abs((*imptr).zoom - 1.0) gt 0.00001 then temp = temp * (*imptr).zoom
  xoff = (*imptr).xpoff + (*imptr).xoff + spinfo.info.sxoff
  if xoff gt 0.0 then temp = temp + xoff
  xpos = temp
  temp = (*imptr).ypos
  if (*imptr).flipy eq 1 then temp = (*imptr).ysiz - temp -1
  if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
     then temp = temp + (*imptr).pad
  if (*imptr).ypscl ne 1.0 then temp = temp * (*imptr).ypscl
  if abs((*imptr).zoom - 1.0) gt 0.00001 then temp = temp * (*imptr).zoom
  yoff = (*imptr).ypoff + (*imptr).yoff + spinfo.info.syoff
  if yoff gt 0.0 then temp = temp + yoff
  ypos = temp
  ua_decompose, (*imptr).name, disk, path, name, extn, versn
  Title = 'IDP3 X/Y Position (from RA & Dec)'

  scWindow = Widget_base(Title = Title, /Column, $
			 /Grid_Layout, $
			 XOffset = tinfo.wpos.scwp[0], $
			 YOffset = tinfo.wpos.scwp[1])
  lab = Widget_Label(scWindow, Value = name + extn)
  xField = cw_field(scWindow,value=xpos,title='X Position:', $
                    uvalue='xpos', xsize=10, /Return_Events, /Floating)
  yField = cw_field(scWindow,value=ypos,title='Y Position:', $
                    uvalue='ypos', xsize=10, /Return_Events, /Floating)
  dbbase = Widget_Base(scWindow, /Row)
  applyButton = Widget_Button(dbbase, Value='Apply')
  doneButton = Widget_Button(dbbase,Value='Done',Event_Pro='Setxypos_Done')

  scinfo = { xField        : xField,      $
             yField        : yField,      $
	     applyButton   : applyButton, $
	     info          : spinfo.info  }

  Widget_Control, scWindow, Set_UValue=scinfo

  Widget_Control, scWindow, /Realize
  spinfo.info.scWindow = scWindow
  Widget_Control, spinfo.info.idp3Window, Set_UValue = spinfo.info

  XManager, 'idp3_setxypos', scWindow, /No_Block,  $
	    Event_Handler='Setxypos_Event'
end

