pro AdjustPoly_Done, event

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=apolyinfo
  Widget_Control, apolyinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.apolywp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.apolywp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, apolyinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end

pro AdjustPoly_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=apolyinfo
  Widget_Control, apolyinfo.info.idp3Window, Get_UValue=tempinfo
  apolyinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=apolyinfo

  roi = *apolyinfo.info.roi
  polypts = roi.polypts
  polyxy = intarr(2,polypts)

  case event.id of
    apolyinfo.polyTable: begin
      Widget_Control, apolyinfo.polyTable, Get_Value = polyxy
      xpts = polyxy[0,*]
      ypts = polyxy[1,*]
      if ptr_valid((*apolyinfo.info.roi).polyx) then $
	ptr_free, (*apolyinfo.info.roi).polyx
      if ptr_valid((*apolyinfo.info.roi).polyy) then $
	ptr_free, (*apolyinfo.info.roi).polyy
      (*apolyinfo.info.roi).polyx = ptr_new(xpts)
      (*apolyinfo.info.roi).polyy = ptr_new(ypts)
      end
  else:
  endcase

  Widget_Control, apolyinfo.info.idp3Window, Set_UValue=apolyinfo.info
  Widget_Control, event.top, Set_UValue=apolyinfo

  geo = Widget_Info(apolyinfo.info.roiBase, /geometry)
  apolyinfo.info.wpos.rwp[0] = geo.xoffset - apolyinfo.info.xoffcorr
  apolyinfo.info.wpos.rwp[1] = geo.yoffset - apolyinfo.info.yoffcorr
  Widget_Control, apolyinfo.info.idp3Window, Set_UValue=apolyinfo.info
  Widget_Control, apolyinfo.info.roiBase, /Destroy
  idp3_roi, apolyinfo.info.idp3Window

end


pro Idp3_AdjustPoly, event

@idp3_structs
@idp3_errors

  ; Don't pop up if there is already an adjust poly widget up.
  ; Also, don't pop up if there is no polygon to adjust.
  if (XRegistered('idp3_adjustpoly')) then return
  if (not(XRegistered('idp3_polystatistics'))) then return

  Widget_Control, event.top, Get_UValue=info

  apolyWindow = Widget_base(Title = 'IDP3 Adjust Polygon Window', /Column, $
			 Group_Leader = info.idp3Window, /Grid_Layout, $
			 XOffset = info.wpos.apolywp[0], $
			 YOffset = info.wpos.apolywp[1])

  roi = *info.roi
  polypts = roi.polypts + 1
  polyxy = intarr(2,polypts)
  for i = 0, polypts-1 do begin
    polyxy[0,i] = (*roi.polyx)[i]
    polyxy[1,i] = (*roi.polyy)[i]
  endfor

  polyTable = Widget_Table(apolyWindow,value=polyxy, $
                          uvalue='polyt', xsize=2, ysize=polypts, /Editable, $
			  format="(i8)",alignment=1,Column_Labels=['X', 'Y'])
  doneButton = Widget_Button(apolyWindow,Value='Done', $
			     Event_Pro='AdjustPoly_Done')

  apolyinfo = { polyTable   : polyTable, $
	       info         : info          }

  Widget_Control, apolyWindow, Set_UValue=apolyinfo

  info.apolyBase = apolyWindow
  Widget_Control, info.idp3Window, Set_UValue=info

  Widget_Control, apolyWindow, /Realize
  XManager, 'idp3_adjustpoly', apolyWindow, /No_Block,  $
	    Event_Handler='AdjustPoly_Event'

  Widget_Control, info.idp3Window, Set_UValue=info
end
