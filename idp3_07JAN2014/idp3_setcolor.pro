pro idp3_SetColor_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=scinfo
  Widget_Control, scinfo.info.idp3Window, Get_UValue=tempinfo
  scinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=scinfo

  Case event.id of

  scinfo.rpcButton: Begin
    ; set color for radial profile
    temp = event.value
    if scinfo.info.color_radpf le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_radpf = temp - 1
  end

  scinfo.pcButton: Begin
    ; set color for polygon
    temp = event.value
    if scinfo.info.color_poly le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_poly = temp - 1
  end

  scinfo.npicButton: Begin
    ; set color for noise profile inner circle
    temp = event.value
    if scinfo.info.color_innernpf le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_innernpf = temp - 1
  end

  scinfo.npocButton: Begin
    ; set color for noiseprofile outer circle
    temp = event.value
    if scinfo.info.color_outernpf le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_outernpf = temp - 1
  end

  scinfo.xscButton: Begin
    ; set color for cross section
    temp = event.value
    if scinfo.info.color_xsect le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_xsect = temp - 1
  end

  scinfo.rcButton: Begin
    ; set color for roi box in main display
    temp = event.value
    if scinfo.info.color_roi le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_roi = temp - 1
  end

  scinfo.sscButton: Begin
    ; set color for spreadsheet
    temp = event.value
    if scinfo.info.color_spsh le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_spsh = temp - 1
  end

  scinfo.ocButton: Begin
    ; set color for orientation vector in main display
    temp = event.value
    if scinfo.info.color_orient le 1 and temp gt 1 then begin
      color6
      scinfo.info.color_bits=6
    endif
    scinfo.info.color_orient = temp - 1
  end

  scinfo.resetButton: Begin
    ; reset all colors to default -1 allowing 256 colors for the image display
    scinfo.info.color_radpf = -1
    Widget_Control, scinfo.rpcButton, Set_Value = 0
    scinfo.info.color_poly = -1
    Widget_Control, scinfo.pcButton, Set_Value = 0
    scinfo.info.color_innernpf = -1
    Widget_Control, scinfo.npicButton, Set_Value = 0
    scinfo.info.color_outernpf = -1
    Widget_Control, scinfo.npocButton, Set_Value = 0
    scinfo.info.color_xsect = -1
    Widget_Control, scinfo.xscButton, Set_Value = 0
    scinfo.info.color_roi = -1
    Widget_Control, scinfo.rcButton, Set_Value = 0
    scinfo.info.color_spsh = -1
    Widget_Control, scinfo.sscButton, Set_Value = 0
    scinfo.info.color_orient = -1
    Widget_Control, scinfo.ocButton, Set_Value = 0
    scinfo.info.color_bits = 0
    loadct, 0
  end

  scinfo.updateButton: Begin
    ; kill widget
    colors = intarr(8)
    colors[*] = 0
    Widget_Control, scinfo.rpcButton, Get_Value = tmp
    colors[0] = tmp + 1
    Widget_Control, scinfo.pcButton, Get_Value = tmp 
    colors[1] = tmp + 1
    Widget_Control, scinfo.npicButton, Get_Value = tmp
    colors[2] = tmp + 1
    Widget_Control, scinfo.npocButton, Get_Value = tmp
    colors[3] = tmp + 1
    Widget_Control, scinfo.xscButton, Get_Value = tmp
    colors[4] = tmp + 1
    Widget_Control, scinfo.rcButton, Get_Value = tmp
    colors[5] = tmp + 1
    Widget_Control, scinfo.sscButton, Get_Value = tmp
    colors[6] = tmp + 1
    Widget_Control, scinfo.ocButton, Get_Value = tmp
    colors[7] = tmp + 1
    if max(colors) gt 0 then color6
    end

  scinfo.doneButton: Begin
    Widget_Control, event.top, /Destroy
    return
    end

  else:
  endcase

  Widget_Control, event.top, Set_UValue=scinfo
  Widget_Control, scinfo.info.idp3Window, Set_UValue=scinfo.info
  idp3_display,scinfo.info

  Widget_Control, scinfo.info.idp3Window, Get_UValue=tempinfo
  scinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=scinfo

end

pro idp3_SetColor, event

@idp3_structs
@idp3_errors

  ; Don't pop up if there is already an edit user preferences widget up.
  if (XRegistered('Set_Color')) then return

  Widget_Control, event.top, Get_UValue=info
;  Widget_Control, epinfo.info.idp3Window, Get_UValue=info

  scWindow = Widget_base(Title = 'IDP3 Set Colors', /Column, $
			 Group_Leader = event.top, /Grid_Layout, $
			 XOffset = info.wpos.tcwp[0], $
			 YOffset = info.wpos.tcwp[1])
 
  rpc = info.color_radpf + 1
  xsc = info.color_xsect + 1
  npic = info.color_innernpf + 1
  npoc = info.color_outernpf + 1
  pc = info.color_poly + 1
  ssc = info.color_spsh + 1
  rc = info.color_roi + 1
  oc = info.color_orient + 1

  colornames = ['None', 'Black', 'White', 'Red', 'Green', 'Blue', 'Yellow']
  rpcbase = Widget_Base(scWindow, /Row, /Frame)
  rpclabel = Widget_Label(rpcbase,   Value='            Radial Profile:')
  rpcButton = CW_BGroup(rpcbase, colornames, exclusive=1, row=1, $
	       Set_Value=rpc, /No_Release)
  xscbase = Widget_Base(scWindow, /Row, /Frame)
  xsclabel = Widget_Label(xscbase,   Value='             Cross Section:')
  xscButton = CW_BGroup(xscbase, colornames, exclusive=1, row=1, $
	       Set_Value=xsc, /No_Release)
  npicbase = Widget_Base(scWindow, /Row, /Frame)
  npiclabel = Widget_Label(npicbase, Value='Noise Profile Inner Circle:')
  npicButton = CW_BGroup(npicbase, colornames, exclusive=1, row=1, $
		Set_Value=npic, /No_Release)
  npocbase = Widget_Base(scWindow, /Row, /Frame)
  npoclabel = Widget_Label(npocbase, Value='              Outer Circle:')
  npocButton = CW_BGroup(npocbase, colornames, exclusive=1, row=1, $
		Set_Value=npoc, /No_Release)
  pcbase = Widget_Base(scWindow, /Row, /Frame)
  pclabel = Widget_Label(pcbase,     Value='                   Polygon:')
  pcButton = CW_BGroup(pcbase, colornames, exclusive=1, row=1, $
		Set_Value=pc, /No_Release)
  sscbase = Widget_Base(scWindow, /Row, /Frame)
  ssclabel = Widget_Label(sscbase,   Value='               Spreadsheet:')
  sscButton = CW_BGroup(sscbase, colornames, exclusive=1, row=1, $
		 Set_Value=ssc, /No_Release)
  rcbase = Widget_Base(scWindow, /Row, /Frame)
  rclabel = Widget_Label(rcbase,     Value='                   ROI Box:')
  rcButton = CW_BGroup(rcbase, colornames, exclusive=1, row=1, $
		 Set_Value=rc, /No_Release)
  ocbase = Widget_Base(scWindow, /Row, /Frame)
  oclabel = Widget_Label(ocbase,     Value='        Orientation Vector:')
  ocButton = CW_BGroup(ocbase, colornames, exclusive=1, row=1, $
	      Set_Value=oc, /No_Release)
  butbase = Widget_Base(scWindow, /Row)
  resetButton = Widget_Button(butbase, Value='Reset')
  updateButton = Widget_Button(butbase, Value='Update Colors')
  doneButton = Widget_Button(butbase, Value='Close Window')

  scinfo = { rpcButton   :   rpcButton,  $
	     xscButton   :   xscButton,  $
	     npicButton  :   npicButton, $
	     npocButton  :   npocButton, $
	     pcButton    :   pcButton,   $
	     sscButton   :   sscButton,  $
	     rcButton    :   rcButton,   $
	     ocButton    :   ocButton,   $
	     resetButton :   resetButton,$
	     updateButton:   updateButton,$
	     doneButton  :   doneButton, $
	     info        :   info        }

  Widget_Control, scWindow, Set_UValue = scinfo

  Widget_Control, info.idp3Window, Set_UValue=info
  Widget_Control, scWindow, /Realize
  XManager, 'set_colors', scWindow, /No_Block, $
      Event_Handler='idp3_SetColor_Ev'

  Widget_Control, info.idp3Window, Set_UValue=info
end
