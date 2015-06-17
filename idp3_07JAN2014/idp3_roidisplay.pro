pro ROIDisplay_Done, event

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=rdinfo
  Widget_Control, rdinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.rdwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.rdwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, rdinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end


pro ROIDisplay_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=rdinfo
  Widget_Control, rdinfo.info.idp3Window, Get_UValue=tempinfo
  rdinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=rdinfo

  case event.id of
    rdinfo.plotminField: begin
      ; Just read the value and save it.
      Widget_Control, rdinfo.plotminField, Get_Value = temp
      rdinfo.info.Z1 = temp
      if rdinfo.info.zoomflux eq 0 then begin
	rz1 = temp
      endif else begin
	case rdinfo.info.imscl of
	  0: rz1 = temp/((*rdinfo.info.roi).roizoom) ^ 2
	  1: rz1 = temp - alog10((*rdinfo.info.roi).roizoom ^ 2)
	  2: rz1 = temp / (*rdinfo.info.roi).roizoom
	  else:
        endcase
      endelse
      Widget_Control, rdinfo.rplotminField, Set_Value = rz1
      rdinfo.info.autoscale = 0
      if (XRegistered('idp3_adjustdisplay')) then begin
	Widget_Control, rdinfo.info.adBase, Get_UValue = tempadinfo
	Widget_Control, tempadinfo.plotminField, Set_Value = temp
	Widget_Control, tempadinfo.autoButton, Set_Value = rdinfo.info.autoscale
      endif
      end
    rdinfo.plotmaxField: begin
      Widget_Control, rdinfo.plotmaxField, Get_Value = temp
      rdinfo.info.Z2 = temp
      if rdinfo.info.zoomflux eq 0 then begin
	rz2 = temp
      endif else begin
	case rdinfo.info.imscl of
	  0: rz2 = temp/((*rdinfo.info.roi).roizoom) ^ 2
	  1: rz2 = temp - alog10((*rdinfo.info.roi).roizoom ^ 2)
	  2: rz2 = temp / (*rdinfo.info.roi).roizoom
	  else:
        endcase
      endelse
      Widget_Control, rdinfo.rplotmaxField, Set_Value = rz2
      rdinfo.info.autoscale = 0
      if (XRegistered('idp3_adjustdisplay')) then begin
	Widget_Control, rdinfo.info.adBase, Get_UValue = tempadinfo
	Widget_Control, tempadinfo.plotmaxField, Set_Value = temp
	Widget_Control, tempadinfo.autoButton, Set_Value = rdinfo.info.autoscale
      endif
      end
    rdinfo.rplotminField: begin
      Widget_Control, rdinfo.rplotminField, Get_Value = temp
      if rdinfo.info.zoomflux eq 0 then begin
	rz1 = temp 
      endif else begin
	case rdinfo.info.imscl of
	  0: rz1 = temp * ((*rdinfo.info.roi).roizoom) ^ 2
	  1: rz1 = temp + alog10((*rdinfo.info.roi).roizoom ^ 2)
	  2: rz1 = temp * (*rdinfo.info.roi).roizoom
	  else:
        endcase
      endelse
      rdinfo.info.Z1 = rz1
      Widget_Control, rdinfo.plotminField, Set_Value = rz1
      rdinfo.info.autoscale = 0
      if (XRegistered('idp3_adjustdisplay')) then begin
	Widget_Control, rdinfo.info.adBase, Get_UValue = tempadinfo
	Widget_Control, tempadinfo.plotminField, Set_Value = rz1
	Widget_Control, tempadinfo.autoButton, Set_Value = rdinfo.info.autoscale
      endif
      end
    rdinfo.rplotmaxField: begin
      Widget_Control, rdinfo.rplotmaxField, Get_Value = temp
      if rdinfo.info.zoomflux eq 0 then begin
	rz2 = temp 
      endif else begin
	case rdinfo.info.imscl of
	  0: rz2 = temp * ((*rdinfo.info.roi).roizoom) ^ 2
	  1: rz2 = temp + alog10((*rdinfo.info.roi).roizoom ^ 2)
	  2: rz2 = temp * (*rdinfo.info.roi).roizoom
	  else:
        endcase
      endelse
      rdinfo.info.Z2 = rz2
      Widget_Control, rdinfo.plotmaxField, Set_Value = rz2
      rdinfo.info.autoscale = 0
      if (XRegistered('idp3_adjustdisplay')) then begin
	Widget_Control, rdinfo.info.adBase, Get_UValue = tempadinfo
	Widget_Control, tempadinfo.plotmaxField, Set_Value = rz2
	Widget_Control, tempadinfo.autoButton, Set_Value = rdinfo.info.autoscale
      endif
      end
  else:
      
  endcase

  ; Make sure we've got a fresh copy of the 'info' structure to pass to display.
  Widget_Control, event.top, Set_UValue=rdinfo
  Widget_Control, rdinfo.info.idp3Window, Set_UValue=rdinfo.info

  ; Update the display.
  idp3_display,rdinfo.info

  ; Make sure we save the updated 'info' structure back into this widget's
  ; 'rdinfo' structure.
  Widget_Control, rdinfo.info.idp3Window, Get_UValue=tempinfo
  rdinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=rdinfo

end


pro Idp3_ROIDisplay, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_roidisplay')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  z1 = info.Z1
  z2 = info.Z2
  if info.zoomflux eq 0 then begin
    rz1 = z1
    rz2 = z2
  endif else begin
    case info.imscl of
      0: begin
	rz1 = z1/((*info.roi).roizoom) ^ 2
	rz2 = z2/((*info.roi).roizoom) ^ 2
        end
      1: begin
	rz1 = z1 - alog10((*info.roi).roizoom ^ 2)
	rz2 = z2 - alog10((*info.roi).roizoom ^ 2)
        end
      2: begin
	rz1 = z1 / (*info.roi).roizoom
	rz2 = z2 / (*info.roi).roizoom
        end
      else:
    endcase
  endelse
  rdWindow = Widget_base(Title = 'IDP3-ROI Adjust Display', /Column, $
			 Group_Leader = event.top, /Grid_Layout, $
			 XOffset = info.wpos.rdwp[0], $
			 YOffset = info.wpos.rdwp[1])
  zBase = Widget_Base(rdWindow,/Row)
  plotminField = cw_field(zBase,value=z1,title='main plotmin:', $
                          uvalue='plotmin', xsize=15, /Return_Events, /Floating)
  plotmaxField = cw_field(zBase,value=z2,title='main plotmax:', $
                          uvalue='plotmax', xsize=15, /Return_Events, /Floating)
  dBase = Widget_Base(rdWindow,/Row)
  rplotminField = cw_field(dBase,value=rz1,title='ROI plotmin:', $
                          uvalue='plotmin', xsize=15, /Return_Events, /Floating)
  rplotmaxField = cw_field(dBase,value=rz2,title='ROI plotmax:', $
                          uvalue='plotmax', xsize=15, /Return_Events, /Floating)
  doneButton = Widget_Button(dBase,Value='Done',Event_Pro='ROIDisplay_Done')

  rdinfo = { plotminField   : plotminField,  $
             plotmaxField   : plotmaxField,  $
	     rplotminField  : rplotminField, $
	     rplotmaxField  : rplotmaxField, $
	     info           : info           }

  Widget_Control, rdWindow, Set_UValue=rdinfo

  ; Remember the main base widget ID so we can update this widget from
  ; elsewhere.
  info.rdBase = rdWindow
  Widget_Control, info.idp3Window, Set_UValue=info

  Widget_Control, rdWindow, /Realize
  XManager, 'idp3_roidisplay', rdWindow, /No_Block,  $
	    Event_Handler='ROIDisplay_Event'

  Widget_Control, info.idp3Window, Set_UValue=info
end


