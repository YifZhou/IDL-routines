pro xsadj_done, Event
  ; call idp3_display and destroy widget
  Widget_Control, event.top, Get_UValue=adjxsinfo
  Widget_Control, adjxsinfo.info.idp3Window, Get_UValue=tempinfo
  ;adjxsinfo.info = tempinfo
  ;idp3_display, adjxsinfo.info
  Widget_Control, Event.top, /Destroy
end

pro idp3_adjxs_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=adjxsinfo
  Widget_Control, adjxsinfo.info.idp3Window, Get_UValue=tempinfo
  adjxsinfo.info = tempinfo

  case event.id of

    adjxsinfo.xcancelButton: begin
      Widget_Control, adjxsinfo.xxstartField, Set_Value = $
	  (*tempinfo.roi).xsxstart
      Widget_Control, adjxsinfo.xxstopField, Set_Value = $
	  (*tempinfo.roi).xsxstop
      Widget_Control, adjxsinfo.xystartField, Set_Value = $
	  (*tempinfo.roi).xsystart
      Widget_Control, adjxsinfo.xystopField, Set_Value = $
	  (*tempinfo.roi).xsystop
      end

    adjxsinfo.scancelButton: begin
      Widget_Control, adjxsinfo.sxstartField, Set_Value = $
	  (*tempinfo.roi).xsxstart
      Widget_Control, adjxsinfo.systartField, Set_Value = $
	  (*tempinfo.roi).xsystart
      Widget_Control, adjxsinfo.sangleField, Set_Value = $
	  (*tempinfo.roi).xsangle
      Widget_Control, adjxsinfo.slengthField, Set_Value = $
	  (*tempinfo.roi).xslength
      end

    adjxsinfo.ccancelButton: begin
      Widget_Control, adjxsinfo.cxcenterField, Set_Value = $
	  (*tempinfo.roi).xsxcenter
      Widget_Control, adjxsinfo.cycenterField, Set_Value = $
	  (*tempinfo.roi).xsycenter
      Widget_Control, adjxsinfo.cangleField, Set_Value = $
	  (*tempinfo.roi).xsangle
      Widget_Control, adjxsinfo.clengthField, Set_Value = $
	  (*tempinfo.roi).xslength
      end

    adjxsinfo.xapplyButton: begin
      ; get all parameters
      Widget_Control, adjxsinfo.xxstartField, Get_Value = xs
      (*tempinfo.roi).xsxstart = xs
      Widget_Control, adjxsinfo.xystartField, Get_Value = ys
      (*tempinfo.roi).xsystart = ys
      Widget_Control, adjxsinfo.xxstopField, Get_Value = xe
      (*tempinfo.roi).xsxstop = xe
      Widget_Control, adjxsinfo.xystopField, Get_Value = ye
      (*tempinfo.roi).xsystop = ye
      xc = (xe + xs) * 0.5
      yc = (ye + ys) * 0.5
      xdist = xe - xs
      ydist = ye - ys
      xl = sqrt(xdist^2 + ydist^2)
      xa = atan(ydist/xdist) * 180.0d0/!dpi
      (*tempinfo.roi).xsxcenter = xc
      (*tempinfo.roi).xsycenter = yc
      (*tempinfo.roi).xslength = xl
      (*tempinfo.roi).xsangle = xa
      Widget_Control, adjxsinfo.sxstartField, Set_Value = xs
      Widget_Control, adjxsinfo.systartField, Set_Value = ys
      Widget_Control, adjxsinfo.sangleField, Set_Value = xa
      Widget_Control, adjxsinfo.slengthField, Set_Value = xl
      Widget_Control, adjxsinfo.cxcenterField, Set_Value = xc
      Widget_Control, adjxsinfo.cycenterField, Set_Value = yc
      Widget_Control, adjxsinfo.cangleField, Set_Value = xa
      Widget_Control, adjxsinfo.clengthField, Set_Value = xl
      end

    adjxsinfo.sapplyButton: begin
      ; get all parameters
      Widget_Control, adjxsinfo.sxstartField, Get_Value = xs
      (*tempinfo.roi).xsxstart = xs
      Widget_Control, adjxsinfo.systartField, Get_Value = ys
      (*tempinfo.roi).xsystart = ys
      Widget_Control, adjxsinfo.sangleField, Get_Value = xa
      (*tempinfo.roi).xsangle = xa
      Widget_Control, adjxsinfo.slengthField, Get_Value = xl
      (*tempinfo.roi).xslength = xl
      ang = xa * (!dpi/180.0d0)
      xdist = xl * cos(ang)
      ydist = xl * sin(ang)
      xe = xs + xdist
      ye = ys + ydist
      xc = (xe + xs) * 0.5
      yc = (ye + ys) * 0.5
      print, xdist, xs, xe, xc
      print, ydist, ys, ye, yc
      (*tempinfo.roi).xsxcenter = xc
      (*tempinfo.roi).xsycenter = yc
      (*tempinfo.roi).xsxstop = xe
      (*tempinfo.roi).xsystop = ye
      Widget_Control, adjxsinfo.xxstartField, Set_Value = xs
      Widget_Control, adjxsinfo.xxstopField, Set_Value = xe
      Widget_Control, adjxsinfo.xystartField, Set_Value = ys
      Widget_Control, adjxsinfo.xystopField, Set_Value = ye
      Widget_Control, adjxsinfo.cxcenterField, Set_Value = xc
      Widget_Control, adjxsinfo.cycenterField, Set_Value = yc
      Widget_Control, adjxsinfo.cangleField, Set_Value = xa
      Widget_Control, adjxsinfo.clengthField, Set_Value = xl
      end

    adjxsinfo.capplyButton: begin
      ; get all parameters
      Widget_Control, adjxsinfo.cxcenterField, Get_Value = xc
      (*tempinfo.roi).xsxcenter = xc
      Widget_Control, adjxsinfo.cycenterField, Get_Value = yc
      (*tempinfo.roi).xsycenter = yc
      Widget_Control, adjxsinfo.cangleField, Get_Value = xa
      (*tempinfo.roi).xsangle = xa
      Widget_Control, adjxsinfo.clengthField, Get_Value = xl
      (*tempinfo.roi).xslength = xl
      ang = xa * (!dpi/180.0d0)
      xdist = xl * cos(ang)
      ydist = xl * sin(ang)
      xs = xc - xdist * 0.5
      ys = yc - ydist * 0.5
      xe = xc + xdist * 0.5
      ye = yc + ydist * 0.5
      (*tempinfo.roi).xsxstart = xs
      (*tempinfo.roi).xsystart = ys
      (*tempinfo.roi).xsxstop = xe
      (*tempinfo.roi).xsystop = ye
      Widget_Control, adjxsinfo.xxstartField, Set_Value = xs
      Widget_Control, adjxsinfo.xxstopField, Set_Value = xe
      Widget_Control, adjxsinfo.xystartField, Set_Value = ys
      Widget_Control, adjxsinfo.xystopField, Set_Value = ye
      Widget_Control, adjxsinfo.sxstartField, Set_Value = xs
      Widget_Control, adjxsinfo.systartField, Set_Value = ys
      Widget_Control, adjxsinfo.sangleField, Set_Value = xa
      Widget_Control, adjxsinfo.slengthField, Set_Value = xl
      end

    adjxsinfo.xxstartField: begin
      Widget_Control, adjxsinfo.xxstartField, Get_Value = xs
      end

    adjxsinfo.xxstopField: begin
      Widget_Control, adjxsinfo.xxstopField, Get_Value = xe
      end

    adjxsinfo.xystartField: begin
      Widget_Control, adjxsinfo.xystartField, Get_Value = ys
      end

    adjxsinfo.xystopField: begin
      Widget_Control, adjxsinfo.xystopField, Get_Value = ye
      end
    
    adjxsinfo.sxstartField: begin
      Widget_Control, adjxsinfo.sxstartField, Get_Value = xs
      end

    adjxsinfo.systartField: begin
      Widget_Control, adjxsinfo.systartField, Get_Value = ys
      end

    adjxsinfo.sangleField: begin
      Widget_Control, adjxsinfo.sangleField, Get_Value = xa
      end

    adjxsinfo.slengthField: begin
      Widget_Control, adjxsinfo.slengthField, Get_Value = xl
      end

    adjxsinfo.cxcenterField: begin
      Widget_Control, adjxsinfo.cxcenterField, Get_Value = xc
      end

    adjxsinfo.cycenterField: begin
      Widget_Control, adjxsinfo.cycenterField, Get_Value = yc
      end

    adjxsinfo.cgetcentroid: begin
      ; get centroid solution for x,y center
      xc = (*tempinfo.roi).radxcent/(*tempinfo.roi).roizoom + $
	   (*tempinfo.roi).roixorig + tempinfo.sxoff
      Widget_Control, adjxsinfo.cxcenterField, Set_Value = xc
      yc = (*tempinfo.roi).radycent/(*tempinfo.roi).roizoom + $
	   (*tempinfo.roi).roiyorig + tempinfo.syoff
      Widget_Control, adjxsinfo.cycenterField, Set_Value = yc
      end

    adjxsinfo.cangleField: begin
      Widget_Control, adjxsinfo.cangleField, Get_Value = xa
      end

    adjxsinfo.clengthField: begin
      Widget_Control, adjxsinfo.clengthField, Get_Value = xl
      end

  else:
  endcase
  Widget_Control, tempinfo.idp3Window, Set_UValue=tempinfo
  adjxsinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue = adjxsinfo
  idp3_display, tempinfo
end

pro idp3_adjustxsect, event

@idp3_structs
@idp3_errors

  ; Don't pop up if there is already an adjust x section widget up.
  if (XRegistered('idp3_adjustxsect')) then return

  Widget_Control, event.top, Get_UValue = info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  title = 'IDP3-ROI Adjust Cross Section'
  adjxsWindow = Widget_base(Title = title, Column=4, $
			 Group_Leader = event.top, $
			 XOffset = cinfo.wpos.axwp[0], $
			 YOffset = cinfo.wpos.axwp[1])

  cinfo.axsbase = adjxsWindow
  Widget_Control, info.idp3Window, Set_UValue = cinfo

  xs = float((*cinfo.roi).xsxstart)
  xc = float((*cinfo.roi).xsxcenter)
  xe = float((*cinfo.roi).xsxstop)
  ys = float((*cinfo.roi).xsystart)
  yc = float((*cinfo.roi).xsycenter)
  ye = float((*cinfo.roi).xsystop)
  xa = float((*cinfo.roi).xsangle)
  xl = float((*cinfo.roi).xslength)

  adjssbase = Widget_Base(adjxsWindow, /Row, /Frame)
  adjsabase = Widget_Base(adjxsWindow, /Row, /Frame)
  adjcabase = Widget_Base(adjxsWindow, /Row, /Frame)
  adjdonebase = Widget_Base(adjxsWindow, /Row)

  adjss1base = Widget_Base(adjssbase, /Column)
  labx = Widget_Label(adjss1base, Value='Start/Stop')

  xxstartField = cw_field(adjss1base,value=xs, title='x start:', $
                          uvalue='xstart', xsize=12, /Return_Events, /Floating)
  xxstopField = cw_field(adjss1base,value=xe, title='x stop: ', $
                          uvalue='xstop', xsize=12, /Return_Events, /Floating)
  xystartField = cw_field(adjss1base,value=ys, title='y start:', $
                          uvalue='ystart', xsize=12, /Return_Events, /Floating)
  xystopField = cw_field(adjss1base,value=ye, title='y stop: ', $
                          uvalue='ystop', xsize=12, /Return_Events, /Floating)
  xbuttonbase = Widget_Base(adjss1base, /Row)
  xlabel = Widget_Label(xbuttonbase, Value='    ')
  xapplyButton = Widget_Button(xbuttonbase,Value = 'Apply')
  xcancelButton = Widget_Button(xbuttonbase, Value='Cancel')

  adjsa1base = Widget_Base(adjsabase, /Column)
  labs = Widget_Label(adjsa1base, Value='Start/Angle')

  sxstartField = cw_field(adjsa1base,value=xs, title='x start:    ', $
		  uvalue='sxstart', xsize=12, /Return_Events, /Floating)
  systartField = cw_field(adjsa1base,value=ys, title='y start:    ', $
		  uvalue='systart', xsize=12, /Return_Events, /Floating)
  sangleField = cw_field(adjsa1base,value=xa, title='line angle: ', $
		  uvalue='sangle', xsize=12, /Return_Events, /Floating)
  slengthField = cw_field(adjsa1base,value=xl, title='line length:', $
		  uvalue='slen', xsize=12, /Return_Events, /Floating)
  sbuttonbase = Widget_Base(adjsa1base, /Row)
  slabel = Widget_Label(sbuttonbase, Value='    ')
  sapplyButton = Widget_Button(sbuttonbase,Value = 'Apply')
  scancelButton = Widget_Button(sbuttonbase, Value='Cancel')

  adjca1base = Widget_Base(adjcabase, /Column)
  labc = Widget_Label(adjca1base, Value='Center/Angle')

  cxcenterField = cw_field(adjca1base,value=xc, title='x center:   ', $
		  uvalue='cxcenter', xsize=12, /Return_Events, /Floating)
  cycenterField = cw_field(adjca1base,value=yc, title='y center:   ', $
		  uvalue='cycenter', xsize=12, /Return_Events, /Floating)
  cangleField = cw_field(adjca1base,value=xa, title='line angle: ', $
		  uvalue='cangle', xsize=12, /Return_Events, /Floating)
  clengthField = cw_field(adjca1base,value=xl, title='line length:', $
		  uvalue='clen', xsize=12, /Return_Events, /Floating)
  cbuttonbase = Widget_Base(adjca1base, /Row)
  cgetcentroid = Widget_Button(cbuttonbase, Value='Centroid X,Y')
  capplyButton = Widget_Button(cbuttonbase,Value = 'Apply')
  ccancelButton = Widget_Button(cbuttonbase, Value='Cancel')

  doneButton = Widget_Button(adjdonebase, Value='Done', $
       Event_Pro = 'xsadj_done')
  
  adjxsinfo = { xxstartField   : xxstartField,  $
                xystartField   : xystartField,  $
                xxstopField    : xxstopField,   $
                xystopField    : xystopField,   $
	        xapplyButton   : xapplyButton,  $
	        xcancelButton  : xcancelButton, $
		sxstartField   : sxstartField,  $
		systartField   : systartField,  $
		sangleField    : sangleField,   $
		slengthField   : slengthField,  $
		sapplyButton   : sapplyButton,  $
		scancelButton  : scancelButton, $
		cxcenterField  : cxcenterField, $
		cycenterField  : cycenterField, $
		cangleField    : cangleField,   $
		clengthField   : clengthField,  $
		cgetcentroid   : cgetcentroid,  $
		capplyButton   : capplyButton,  $
		ccancelButton  : ccancelButton, $
	        info           : info           }

  Widget_Control, adjxsWindow, Set_UValue=adjxsinfo

  Widget_Control, adjxsWindow, /Realize
  XManager, 'idp3_adjustxsect', adjxsWindow, /No_Block,  $
	    Event_Handler='idp3_adjxs_Event'

end
