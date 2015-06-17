pro AdjustRoi_Done, event

  Widget_Control, event.top, /Destroy

end

pro AdjustRoi_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=aroiinfo
  Widget_Control, aroiinfo.info.idp3Window, Get_UValue=tempinfo
  aroiinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=aroiinfo
  numimages = n_elements(*aroiinfo.info.images)
  xlim = 0
  ylim = 0
  for i = 0, numimages-1 do begin
    if (*(*aroiinfo.info.images)[i]).vis eq 1 then begin
      xz = (*(*aroiinfo.info.images)[i]).xsiz + $
	   (*(*aroiinfo.info.images)[i]).xoff
      yz = (*(*aroiinfo.info.images)[i]).ysiz + $
	   (*(*aroiinfo.info.images)[i]).yoff
      if xz gt xlim then xlim = xz
      if yz gt ylim then ylim = yz
    endif
  endfor
  xlim = (xlim-1) > (aroiinfo.info.drawxsize - 1)
  ylim = (ylim-1) > (aroiinfo.info.drawysize - 1)
  xorig = (*aroiinfo.info.roi).roixorig
  yorig = (*aroiinfo.info.roi).roiyorig 
  xend = (*aroiinfo.info.roi).roixend
  yend = (*aroiinfo.info.roi).roiyend
  ; get coordinate parameters
  Widget_Control, aroiinfo.xorigField, Get_Value = xo
  Widget_Control, aroiinfo.xendField, Get_Value = xe
  Widget_Control, aroiinfo.yorigField, Get_Value = yo
  Widget_Control, aroiinfo.yendField, Get_Value = ye
  Widget_Control, aroiinfo.xcentField, Get_Value = xc
  Widget_Control, aroiinfo.xlenField, Get_Value = xl
  Widget_Control, aroiinfo.ycentField, Get_Value = yc
  Widget_Control, aroiinfo.ylenField, Get_Value = yl

  case event.id of
    aroiinfo.xorigField: begin
      if XRegistered("idp3_roi") then begin
        ; Update the xorigin of the roi 
	if xo lt 0 then begin
	  xo = 0
	  str = 'AdjustROI: XOrigin less than 0, resetting to 0.'
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.xorigField, Set_Value = xo
        endif
	if xe gt xlim then begin
	  xe = xlim
	  str = 'AdjustROI: XEnd greater than roi, resetting to ' + string(xlim)
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.xendField, Set_Value = xe
        endif
        if xo lt xe then begin
          xl = ABS(xe - xo) + 1
          xc=(xo + xe) * 0.5
          Widget_Control, aroiinfo.xcentField, Set_Value = xc
          Widget_Control, aroiinfo.xlenField, Set_Value = xl
        endif else begin
	  test = Widget_Message('Xend < Xorigin, Resetting Xorigin')
          Widget_Control, aroiinfo.xorigField, Set_Value = xorig 
        endelse
      endif else begin
	Widget_Control, aroiinfo.xorigField, Set_Value = xorig
      endelse
      end

    aroiinfo.yorigField: begin
      if XRegistered("idp3_roi") then begin
        ; Update the yorigin of the roi 
        if yo lt 0 then begin
	  yo = 0
	  str = 'AdjustROI: YOrigin less than 0, resetting to 0.'
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.yorigField, Set_Value = yo
        endif
	if ye gt ylim then begin
	  ye = ylim
	  str = 'AdjustROI: YEnd greater than roi, resetting to ' + string(ylim)
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.yendField, Set_Value = ye
        endif
	if yo lt ye then begin
          yl = ABS(ye - yo) + 1
          yc=(ye + yo)*0.5
          Widget_Control, aroiinfo.ycentField, Set_Value = yc
          Widget_Control, aroiinfo.ylenField, Set_Value = yl
        endif else begin
	  test = Widget_Message('Yend < Yorigin, Resetting Yorigin')
	  Widget_Control, aroiinfo.yorigField, Set_Value = yorig
        endelse
      endif else begin
	Widget_Control, aroiinfo.yorigField, Set_Value = yorig
      endelse
      end

    aroiinfo.xendField: begin
      if XRegistered("idp3_roi") then begin
        ; Update the xend of the roi 
	if xe gt xlim then begin
	  xe = xlim
	  str = 'AdjustROI: XEnd greater than roi, resetting to ' + string(xlim)
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.xendField, Set_Value = xe
        endif
	if xo lt 0 then begin
	  xo = 0
	  str = 'AdjustROI: XOrigin less than 0, resetting to 0.'
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.xorigField, Set_Value = xo
        endif
        if xe gt xo then begin
	  xl = ABS(xe - xo) + 1
	  xc=(xe + xo)*0.5
	  Widget_Control, aroiinfo.xcentField, Set_Value = xc
	  Widget_Control, aroiinfo.xlenField, Set_Value = xl
        endif else begin
	  test = Widget_Message('Xorigin > Xend, Resetting Xend')
	   Widget_Control, aroiinfo.xendField, Set_Value = xend
        endelse
      endif else begin
	Widget_Control, aroiinfo.xendField, Set_Value = xend
      endelse
      end

    aroiinfo.yendField: begin
      if XRegistered("idp3_roi") then begin
        ; Update the yend of the roi 
	if ye gt ylim then begin
	  ye = ylim
	  str = 'AdjustROI: YEnd greater than roi, resetting to ' + string(ylim)
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.yendField, Set_Value = ye
        endif
	if yo lt 0 then begin
	  yo = 0
	  str = 'AdjustROI: YOrigin less than 0, resetting to 0.'
	  idp3_updatetxt, aroiinfo.info, str
	  Widget_Control, aroiinfo.yorigField, Set_Value = yo
        endif
        if ye gt yo then begin
	  yl = ye - yo + 1
	  yc=(ye + yo)*0.5
	  Widget_Control, aroiinfo.ycentField, Set_Value = yc
	  Widget_Control, aroiinfo.ylenField, Set_Value = yl
        endif else begin
	  test = Widget_Message('Yorigin > Yend, Resetting Yend')
	   Widget_Control, aroiinfo.yendField, Set_Value = yend
        endelse
      endif else begin
	Widget_Control, aroiinfo.yendField, Set_Value = yend
      endelse
      end

    aroiinfo.xcentField: begin
      if XRegistered("idp3_roi") then begin
	; Update the xorig and xend from length
        if xc lt xlim then begin
          xo = FIX(xc - xl*0.5 + 0.5) > 0
          xe = FIX(xo + xl -0.5) < xlim
          Widget_Control, aroiinfo.xorigField, Set_Value = xo
          Widget_Control, aroiinfo.xendField, Set_Value = xe
	  xl = xe - xo + 1
	  xc = (xe + xo)*0.5
        endif else begin
	  test = Widget_Message('Error, ROI Xcenter out of bounds')
	  xc = (xend - xorig)*0.5
	  xl = xend - xorig + 1
        endelse
      endif else begin
	xc = (xend - xorig)*0.5
	xl = xend - xorig + 1
      endelse
      Widget_Control, aroiinfo.xcentField, Set_Value = xc
      Widget_Control, aroiinfo.xlenField, Set_Value = xl
      end

    aroiinfo.ycentField: begin
      if XRegistered("idp3_roi") then begin
        if yc lt ylim then begin
          yo = FIX(yc - yl*0.5 + 0.5) > 0
          ye = FIX(yo + yl -0.5) < ylim
          Widget_Control, aroiinfo.yorigField, Set_Value = yo
          Widget_Control, aroiinfo.yendField, Set_Value = ye
	  yl = ye - yo + 1
	  yc = (ye + yo)*0.5
        endif else begin
	  test = Widget_Message('Error, ROI Ycenter out of bounds')
	  yc = (yend - yorig)*0.5
	  yl = yend - yorig + 1
        endelse
      endif else begin
	yc = (yend - yorig)*0.5
	yl = yend - yorig + 1
      endelse
      Widget_Control, aroiinfo.ycentField, Set_Value = yc
      Widget_Control, aroiinfo.ylenField, Set_Value = yl
      end

    aroiinfo.xlenField: begin
      if XRegistered("idp3_roi") then begin
        Widget_Control, aroiinfo.xlenField, Get_Value = xl
        Widget_Control, aroiinfo.xcentField, Get_Value = xc
        if xl lt xlim then begin
          xo = FIX(xc - xl*0.5 + 0.5) > 0
          xe = FIX(xo + xl - 0.5) < xlim
          Widget_Control, aroiinfo.xorigField, Set_Value = xo
          Widget_Control, aroiinfo.xendField, Set_Value = xe
	  xl = xe - xo + 1
	  xc = (xe + xo)*0.5
        endif else begin
	  test = Widget_Message('Error, ROI xlength out of bounds')
	  xc = (xend - xorig)*0.5
	  xl = xend - xorig + 1
        endelse
      endif else begin
	xc = (xend - xorig)*0.5
	xl = xend - xorig + 1
      endelse
      Widget_Control, aroiinfo.xcentField, Set_Value = xc
      Widget_Control, aroiinfo.xlenField, Set_Value = xl
      end

    aroiinfo.ylenField: begin
      if XRegistered("idp3_roi") then begin
        Widget_Control, aroiinfo.ylenField, Get_Value = yl
        Widget_Control, aroiinfo.ycentField, Get_Value = yc
        if yl lt ylim then begin
          yo = FIX(yc - yl*0.5 + 0.5) > 0
          ye = FIX(yo + yl - 0.5) < ylim
          Widget_Control, aroiinfo.yorigField, Set_Value = yo
          Widget_Control, aroiinfo.yendField, Set_Value = ye
	  yl = ye - yo + 1
	  yc = (ye + yo)*0.5
        endif else begin
	  test = Widget_Message('Error, ROI ylength out of bounds')
	  yc = (yend - yorig)*0.5
	  yl = yend - yorig + 1
        endelse
      endif else begin
	yc = (yend - yorig)*0.5
	yl = yend - yorig + 1
      endelse
      Widget_Control, aroiinfo.ycentField, Set_Value = yc
      Widget_Control, aroiinfo.ylenField, Set_Value = yl
      end

    aroiinfo.centButton: begin
      if XRegistered("idp3_roi") then begin
        ref = aroiinfo.info.moveimage
        refim = (*(*aroiinfo.info.images)[ref])
        xc = refim.lccx
        yc = refim.lccy
	if xc le 0 or yc le 0 then begin
	  stat = Widget_Message('No centroid for reference image')
	  return
        endif
        xo = FIX(xc - xl*0.5 + 0.5) > 0
        yo = FIX(yc - yl*0.5 + 0.5) > 0
        xe = FIX(xo + xl - 0.5) < xlim
        ye = FIX(yo + yl - 0.5) < ylim
	xl = xe - xo + 1
	yl = ye - yo + 1
        Widget_Control, aroiinfo.xcentField, Set_Value = xc
        Widget_Control, aroiinfo.ycentField, Set_Value = yc
        Widget_Control, aroiinfo.xlenField, Set_Value = xl
        Widget_Control, aroiinfo.ylenField, Set_Value = yl
        Widget_Control, aroiinfo.xorigField, Set_Value = xo
        Widget_Control, aroiinfo.xendField, Set_Value = xe
        Widget_Control, aroiinfo.yorigField, Set_Value = yo
        Widget_Control, aroiinfo.yendField, Set_Value = ye
      endif
      end
  else:
  endcase

  (*aroiinfo.info.roi).roixorig = xo
  (*aroiinfo.info.roi).boxx0 = xo
  (*aroiinfo.info.roi).roixend = xe
  (*aroiinfo.info.roi).tempxbox = xe
  (*aroiinfo.info.roi).roiyorig = yo
  (*aroiinfo.info.roi).boxy0 = yo
  (*aroiinfo.info.roi).roiyend = ye
  (*aroiinfo.info.roi).tempybox = ye
  
  Widget_Control, event.top, Set_UValue=aroiinfo
  Widget_Control, aroiinfo.info.idp3Window, Set_UValue=aroiinfo.info
  if XRegistered("idp3_roi") then begin
    idp3_display, aroiinfo.info
 
    Widget_Control, aroiinfo.info.roiBase, /Destroy
    idp3_roi, aroiinfo.info.idp3Window
  endif

end


pro Idp3_AdjustRoi, event

@idp3_structs
@idp3_errors

  ; Don't pop up if there is already an adjust roi widget up.
  ; Also, don't pop up if there is no roi to adjust.
  if (XRegistered('idp3_adjustroi')) then return
  if (not(XRegistered('idp3_roi'))) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  aroiWindow = Widget_base(Title = 'Adjust ROI', /Column, $
			 Group_Leader = info.idp3Window, /Grid_Layout, $
			 XOffset = info.wpos.aroiwp[0], $
			 YOffset = info.wpos.aroiwp[1])

  xo = (*info.roi).roixorig
  yo = (*info.roi).roiyorig
  xe = (*info.roi).roixend
  ye = (*info.roi).roiyend
  xl = ABS(xe - xo) + 1
  xc = (xo + xe) * 0.5
  yl = ABS(ye - yo) + 1
  yc = (yo + ye) * 0.5

  xorigField = cw_field(aroiWindow,value=xo, title='x origin:', $
                          uvalue='xorigin', xsize=10, /Return_Events, /Integer)
  xendField = cw_field(aroiWindow,value=xe, title='x end   :', $
                          uvalue='xend', xsize=10, /Return_Events, /Integer)
  xcentField = cw_field(aroiWindow,value=xc, title='x center:', $
                          uvalue='xcenter', xsize=10, /Return_Events, /Floating)
  xlenField = cw_field(aroiWindow,value=xl, title='x length:', $
                          uvalue='xlength', xsize=10, /Return_Events, /Integer)
  yorigField = cw_field(aroiWindow,value=yo, title='y origin:', $
                          uvalue='yorigin', xsize=10, /Return_Events, /Integer)
  yendField = cw_field(aroiWindow,value=ye, title='y end   :', $
                          uvalue='yend', xsize=10, /Return_Events, /Integer)
  ycentField = cw_field(aroiWindow,value=yc, title='y center:', $
                          uvalue='ycenter', xsize=10, /Return_Events, /Floating)
  ylenField = cw_field(aroiWindow,value=yl, title='y length:', $
                          uvalue='ylength', xsize=10, /Return_Events, /Integer)
  centButton = Widget_Button(aroiWindow, Value='  Get Centroid x,y Center  ')
  doneButton = Widget_Button(aroiWindow,Value='Done', $
			     Event_Pro='AdjustRoi_Done')

  aroiinfo = { xorigField   : xorigField, $
               xendField    : xendField,  $
	       xcentField   : xcentField, $
	       xlenField    : xlenField,  $
               yorigField   : yorigField, $
	       yendField    : yendField,  $
               ycentField   : ycentField, $
	       ylenField    : ylenField,  $ 
	       centButton  : centButton, $
	       info         : info          }

  Widget_Control, aroiWindow, Set_UValue=aroiinfo

  info.aroiBase = aroiWindow
  Widget_Control, tinfo.idp3Window, Set_UValue=info

  Widget_Control, aroiWindow, /Realize
  XManager, 'idp3_adjustroi', aroiWindow, /No_Block,  $
	    Event_Handler='AdjustRoi_Event'

end
