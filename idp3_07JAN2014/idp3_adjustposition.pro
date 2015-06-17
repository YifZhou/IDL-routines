pro AdjustPosition_Done, event
  Widget_Control, event.top, Get_UValue=apinfo
  Widget_Control, apinfo.info.idp3Window, Get_UValue=tempinfo
  geo = Widget_Info(event.top, /geometry)
  tempinfo.wpos.apwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.apwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, apinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy
end

pro AdjustPosition_Help, event
  Widget_Control, event.top, Get_UValue=apinfo
  Widget_Control, apinfo.info.idp3Window, Get_UValue = info
  if info.pdf_viewer eq '' then begin
    tmp = idp3_findfile('idp3_adjustposition.hlp')
    xdisplayfile, tmp
  endif else begin
    tmp = idp3_findfile('idp3_adjustposition.pdf')
    str = info.pdf_viewer + ' ' + tmp
    if !version.os eq 'darwin' then str = 'open -a ' + str
    spawn, str
  endelse
end

pro AdjustPosition_Event, event

@idp3_structs
@idp3_errors

  ; Get a fresh copy of the 'info' structure.
  Widget_Control, event.top, Get_UValue=apinfo
  Widget_Control, apinfo.info.idp3Window, Get_UValue=tempinfo
  apinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=apinfo

  ; Get the pointer to the current 'move' image.
  ; "images" is a pointer to an array of structures.
  moveim = apinfo.info.moveimage
  imptr = (*apinfo.info.images)[moveim]

  case event.id of
    apinfo.scaleField: begin
      Widget_Control, apinfo.scaleField, Get_Value = temp
      ; Update the "scl" field in the image structure pointed to by imptr.
      (*imptr).scl = temp
      end
    apinfo.mvAmountField: begin
      ; Do nothing.
      Widget_Control, apinfo.mvAmountField, Get_Value = temp
      (*imptr).movamt = temp
      end
    apinfo.sclAmountField: begin
      ; Do nothing.
      Widget_Control, apinfo.sclAmountField, Get_Value = temp
      (*imptr).sclamt = temp
      end
    apinfo.biasAmountField: begin
      ; Do nothing.
      Widget_Control, apinfo.biasAmountField, Get_Value = temp
      (*imptr).biasamt = temp
      end
    apinfo.rtField: begin
      ; Do nothing.
      Widget_Control, apinfo.rtField, Get_Value = temp
      (*imptr).rotamt = temp
      end
    apinfo.rtAmountField: begin
      Widget_Control, apinfo.rtAmountField, Get_Value = temp
      (*imptr).rot = temp
      end
    apinfo.zoomField: begin
      Widget_Control, apinfo.zoomField, Get_Value = temp
      thiszoom = float(temp)/(*imptr).zoom
      (*imptr).zoom = temp
      end
    apinfo.biasField: begin
      Widget_Control, apinfo.biasField, Get_Value = temp
      (*imptr).bias = temp
      end
    apinfo.sclupButton: begin
      Widget_Control, apinfo.sclAmountField, Get_Value = temp
      (*imptr).sclamt = temp
      ; The user in incrementing the image scale by pushing the '+' button.
      ; Increment the scale and go update the scale field.
      (*imptr).scl = (*imptr).scl + temp
      Widget_Control, apinfo.scaleField, Set_Value = (*imptr).scl
      end
    apinfo.scldnButton: begin
      Widget_Control, apinfo.sclAmountField, Get_Value = temp
      (*imptr).sclamt = temp
      (*imptr).scl = (*imptr).scl - temp
      Widget_Control, apinfo.scaleField, Set_Value = (*imptr).scl
      end
    apinfo.invsclButton: begin
      Widget_Control, apinfo.scaleField, Get_Value = temp
      if temp ne 0.0 then (*imptr).scl = 1.0/(*imptr).scl
      Widget_Control, apinfo.scalefield, Set_Value = (*imptr).scl
      end
    apinfo.biasupButton: begin
      Widget_Control, apinfo.biasAmountField, Get_Value = temp
      (*imptr).biasamt = temp
      ; The user in incrementing the image bias by pushing the '+' button.
      ; Increment the bias and go update the scale field.
      (*imptr).bias = (*imptr).bias + temp
      Widget_Control, apinfo.biasField, Set_Value = (*imptr).bias
      end
    apinfo.biasdnButton: begin
      Widget_Control, apinfo.biasAmountField, Get_Value = temp
      (*imptr).biasamt = temp
      (*imptr).bias = (*imptr).bias - temp
      Widget_Control, apinfo.biasField, Set_Value = (*imptr).bias
      end
    apinfo.rtupButton: begin
      Widget_Control, apinfo.rtField, Get_Value = temp
      (*imptr).rotamt = temp
      (*imptr).rot = (*imptr).rot + temp
      Widget_Control, apinfo.rtAmountField, Set_Value = (*imptr).rot
      end
    apinfo.rtdnButton: begin
      Widget_Control, apinfo.rtField, Get_Value = temp
      (*imptr).rotamt = temp
      (*imptr).rot = (*imptr).rot - temp
      Widget_Control, apinfo.rtAmountField, Set_Value = (*imptr).rot
      end
    apinfo.nupButton: begin
      refim = *(imptr)
      orient = idp3_getorient(refim)
;      hdr = [*(*imptr).phead, *(*imptr).ihead]
;      orient = sxpar(hdr, 'ORIENTAT', count=omatch)
;      reorient = sxpar(hdr, 'REORIENT', count = rmatch)
;      pa = sxpar(hdr, 'PA', count = pmatch)
;      if omatch le 0 and rmatch le 0 and pmatch le 0 then begin
;	if (*imptr).valid_wcs gt 0 then begin
;	  getrot, hdr, rot, cdelt
;	  oangle = rot
;        endif else begin
;	  print, 'Error: orientation angle not found'
;	  return
;        endelse
;      endif
;      getrot, hdr, rot, cdelt
;      print, 'Rotation from CD Matrix: ', rot
;      if rmatch ge 1 then oangle = reorient $
;	else if omatch ge 1 then oangle = orient $
;	else if pmatch ge 1 then oangle = pa $
;	else oangle = rot 
      oangle = orient * (-1.0)
      (*imptr).rot = oangle
      Widget_Control, apinfo.rtAmountField, Set_Value = (*imptr).rot
    end

    apinfo.padButtons: begin
      ; should images be padded before rotation to prevent cropping
      Widget_Control, apinfo.padButtons, Get_Value=barray
      rot_crop = barray[0]
      (*imptr).topad = rot_crop
      if rot_crop eq 1 $
        then padd = fix((*imptr).xsiz * 0.4) > fix((*imptr).ysiz * 0.4) $
	else padd = 0
      Widget_Control, apinfo.padField, Set_Value = padd
      (*imptr).pad = padd
      (*imptr).rotxpad = padd
      (*imptr).rotypad = padd
      end
    apinfo.padField: begin
      ; get pad value for this image
      Widget_Control, apinfo.padField, Get_Value = temp
      if temp gt 0 then begin
	(*imptr).topad = 1
        (*imptr).pad = temp
        (*imptr).rotxpad = temp
        (*imptr).rotypad = temp
	Widget_Control, apinfo.padButtons, Set_Value=1 
      endif else begin
	Widget_Control, apinfo.padButtons, Set_Value=0
	(*imptr).topad = 0
	(*imptr).pad = 0
	(*imptr).rotxpad = 0
	(*imptr).rotypad = 0
	if temp lt 0 then stat = $
	   Widget_Message('Pad value must be greater than 0')
      endelse
      end
    apinfo.rtxcenField: begin
      ; update x rotation center position
      Widget_Control, apinfo.rtxcenField, Get_Value = temp
      str = 'AdjustPosition: Setting rotation X Center to: ' + string(temp)
      idp3_updatetxt, apinfo.info, str
      xoff = (*imptr).xpoff + (*imptr).xoff + apinfo.info.sxoff
      if abs(xoff) gt 0.0 then temp = temp - xoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then temp = temp / (*imptr).zoom
      if (*imptr).xpscl ne 1.0 and (*imptr).xpscl ne 0.0 $
	 then temp = temp / (*imptr).xpscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
	 then temp = temp - (*imptr).pad
      (*imptr).rotcx = temp
      end
    apinfo.rtycenField: begin
      ; update y rotation center position
      Widget_Control, apinfo.rtycenField, Get_Value = temp
      str = 'AdjustPosition: Setting rotation Y Center to: ' + string(temp)
      idp3_updatetxt, apinfo.info, str
      yoff = (*imptr).ypoff + (*imptr).yoff + apinfo.info.syoff
      if abs(yoff) gt 0.0 then temp = temp - yoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then temp = temp / (*imptr).zoom
      if (*imptr).ypscl ne 1.0 and (*imptr).ypscl ne 0.0 $
	then temp = temp / (*imptr).ypscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
	then temp = temp - (*imptr).pad
      if (*imptr).flipy eq 1 then temp = (*imptr).ysiz - temp -1
      (*imptr).rotcy = temp
      end
    apinfo.pxsclButton: begin
      ; adjust x and y pixel scales
      idp3_setpixscl, event
      end
    apinfo.psundoButton: begin
      ; reset pixel scale parameters to 1.0 
      (*imptr).xpscl = 1.0d0
      (*imptr).ypscl = 1.0d0
      (*imptr).xplate = (*imptr).oxplate
      (*imptr).yplate = (*imptr).oyplate
      (*imptr).nxplate = 0.0
      (*imptr).nyplate = 0.0
      end
    apinfo.clipbotButton: begin
      ; set values and flag to clip data bottom
      idp3_clipbottom, event
      end
    apinfo.cliptopButton: begin
      ; set values and flag to clip data top
      idp3_cliptop, event
      end
    apinfo.mv_Widget: begin
      ; They pushed one of the arrow buttons, update the XY offsets
      ; accordingly.  First read the 'move amount' field to know how far to
      ; move.
      Widget_Control, apinfo.mvAmountField, Get_Value = temp
      (*imptr).movamt = temp
      nxshift = (*imptr).xoff + (*imptr).xpoff
      nyshift = (*imptr).yoff + (*imptr).ypoff
      if(event.North eq 1) then begin
	nyshift = (*imptr).yoff + (*imptr).ypoff + temp
      endif
      if(event.West eq 1) then begin
	nxshift = (*imptr).xoff + (*imptr).xpoff - temp
      endif
      if(event.East eq 1) then begin
	nxshift = (*imptr).xoff + (*imptr).xpoff + temp
      endif
      if(event.South eq 1) then begin
	nyshift = (*imptr).yoff + (*imptr).ypoff - temp
      endif
      ; When moving diagonally, we still want to move the correct distance
      ; so we move root two times the move amount in both X and Y.
      if(event.NEast eq 1) then begin
	nyshift = (*imptr).yoff + (*imptr).ypoff + temp * .70710678
	nxshift = (*imptr).xoff + (*imptr).xpoff + temp * .70710678
      endif
      if(event.NWest eq 1) then begin
	nyshift = (*imptr).yoff + (*imptr).ypoff + temp * .70710678
	nxshift = (*imptr).xoff + (*imptr).xpoff - temp * .70710678
      endif
      if(event.SWest eq 1) then begin
	nyshift = (*imptr).yoff + (*imptr).ypoff - temp * .70710678
	nxshift = (*imptr).xoff + (*imptr).xpoff - temp * .70710678
      endif
      if(event.SEast eq 1) then begin
	nyshift = (*imptr).yoff + (*imptr).ypoff - temp * .70710678
	nxshift = (*imptr).xoff + (*imptr).xpoff + temp * .70710678
      endif

      ; Recalculate the integer and fractional portions of the shifts.
      ; Update the offset fields.
      fracsa = float(nxshift) - float(fix(nxshift))
      intsa  = float(fix(nxshift - fracsa))
      (*imptr).xpoff = fracsa
      (*imptr).xoff = intsa
      offx = intsa + fracsa
      WIDGET_CONTROL, apinfo.xoffField, SET_VALUE = offx

      fracsa = float(nyshift) - float(fix(nyshift))
      intsa  = float(fix(nyshift - fracsa))
      (*imptr).ypoff = fracsa
      (*imptr).yoff = intsa
      offy = intsa + fracsa
      WIDGET_CONTROL, apinfo.yoffField, SET_VALUE = offy

      end
    apinfo.xoffField: begin
      ; Read the offset field directly, recalculate the integer and fractional
      ; offsets, update the image.
      Widget_Control, apinfo.xoffField, Get_Value = txoff
      fracsa = float(txoff[0]) - float(fix(txoff[0]))
      intsa  = float(fix(txoff[0] - fracsa))
      (*imptr).xpoff = fracsa
      (*imptr).xoff = intsa
      end
    apinfo.yoffField: begin
      Widget_Control, apinfo.yoffField, Get_Value = tyoff
      fracsa = float(tyoff[0]) - float(fix(tyoff[0]))
      intsa  = float(fix(tyoff[0] - fracsa))
      (*imptr).ypoff = fracsa
      (*imptr).yoff = intsa
      end
  else:
  endcase

  (*apinfo.info.images)[moveim] = imptr
  Widget_Control, apinfo.info.idp3Window, Set_UValue=apinfo.info
  Widget_Control, event.top, Set_UValue=apinfo

  idp3_display, apinfo.info

end


pro Idp3_AdjustPosition, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_adjustposition')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  ; If no images, don't even pop-up the widget.
  c = size(*info.images)
  if (c[0] eq 0 and c[1] eq 2) then return


  apWindow = Widget_base(Title = 'IDP3 Adjust Position', /Column, $
			 Group_Leader = event.top, /Base_Align_Center, $
			 XOffset = info.wpos.apwp[0], $
			 YOffset = info.wpos.apwp[1])

  mim = info.moveimage
  ptrim = (*info.images)[mim]
  ua_decompose,(*ptrim).name,disk,path,fname,extn,version
  temp = (*ptrim).rotcx
  if (*ptrim).topad eq 1 and (*ptrim).pad gt 0 $
    then temp = temp + (*ptrim).pad
  if (*ptrim).xpscl ne 1.0 then temp = temp * (*ptrim).xpscl
  if abs((*ptrim).zoom - 1.0) gt 0.00001 then temp = temp * (*ptrim).zoom
  xoff = (*ptrim).xpoff + (*ptrim).xoff + info.sxoff
  if xoff gt 0.0 then temp = temp + xoff
  rotx = temp
  temp = (*ptrim).rotcy
  if (*ptrim).flipy eq 1 then temp = (*ptrim).ysiz - temp -1
  if (*ptrim).topad eq 1 and (*ptrim).pad gt 0 $
     then temp = temp + (*ptrim).pad
  if (*ptrim).ypscl ne 1.0 then temp = temp * (*ptrim).ypscl
  if abs((*ptrim).zoom - 1.0) gt 0.00001 then temp = temp * (*ptrim).zoom
  yoff = (*ptrim).ypoff + (*ptrim).yoff + info.syoff
  if yoff gt 0.0 then temp = temp + yoff
  roty = temp
  xypos = (*ptrim).xypos
  oangle = idp3_getorient (*ptrim)

  moveImageLabel = Widget_Label(apWindow, Value=fname+extn)
  
  clipbase      = Widget_Base(apWindow, /Row)
  clipbotButton = Widget_Button(clipbase, Value = 'Clip Image Min')
  cliptopButton = Widget_Button(clipbase, Value = 'Clip Image Max')

  padbase = Widget_Base(apWindow, /Row, /frame)
  padButtons = CW_BGroup(padbase, ['Pad Image  No. Pixels:'], row=1, $
	       uvalue='padbutton', $
	       set_value=(*ptrim).topad, /nonexclusive)
  padField   = CW_Field(padBase, Title='',value=(*ptrim).pad, $
		       /Return_Events, xsize=4, /Integer, UValue='padamt')
  
  psclbase      = Widget_Base(apWindow, /Row)
  pxsclButton   = Widget_Button(psclbase,Value=' Pixel Scale ')
  psundoButton  = Widget_Button(psclbase, Value=' Undo ')
  
  zoomBase      = Widget_Base(apWindow,/column)
  zoomField     = CW_Field(zoomBase, Title='Resample Factor:',$
		       value=(*ptrim).zoom, $
		       /Return_Events, xsize=8, /Floating,UValue='zoomamt')
  
  rtBase = Widget_Base(apWindow, /Column, /frame)
  rtAmountLabel = Widget_Label(rtBase,Value='Image Rotation', /align_center)
  rtcenbase     = Widget_Base(rtBase,/row)
  rtxcenField   = CW_Field(rtcenbase, Value=rotx, xsize=8, /Floating, $
		    Title='Center: X', /Return_Events, UValue='rtxcen')
  rtycenField   = CW_Field(rtcenbase, Value=roty, xsize=8, /Floating, $
		    Title='Y', /Return_Events, UValue='rtycen')
  rtAmtbase     = Widget_Base(rtbase, /row)
  rtAmountField = CW_Field(rtAmtBase,Value=(*ptrim).rot,XSize=8,/Floating,$
		   /Return_Events,UValue='rotateamount',$
		   Title='Angle-CW:')
  if oangle gt -999. $
    then nupButton = Widget_Button(rtAmtBase, Value='Rot North UP',/Align_Center) $
    else nupButton = 0L
  rtBase2       = Widget_Base(rtBase,/row)
  rtField       = CW_Field(rtBase2,Value=(*ptrim).rotamt,XSize=6,/Floating, $
		    Title='Angle Increment:',/Return_Events,UValue='rtamount')
  rtupButton    = Widget_Button(rtBase2,UValue='rtup',Value='+', /Align_Center)
  rtdnButton    = Widget_Button(rtBase2,UValue='rtdown',Value='-', /Align_Center)
  
  movebase = Widget_Base(apWindow, /Column, /frame)
  lab1 = Widget_Label(movebase, Value='Image Offsets', /align_center)
  m2base = Widget_Base(movebase, /Row)
  txoff         = (*ptrim).xpoff + (*ptrim).xoff
  tyoff         = (*ptrim).ypoff + (*ptrim).yoff
  xoffField     = CW_Field(m2Base, Title='X:',value=txoff, $
		       /Return_Events, xsize=10, /Floating,UValue='xoffamt')
  yoffField     = CW_Field(m2Base, Title='Y:',value=tyoff, $
		       /Return_Events, xsize=10, /Floating,UValue='yoffamt')
  moveincbase = Widget_Base(movebase, /Row)
  m3base = Widget_Base(moveincbase, /Column)
  m4base = Widget_Base(moveincbase, /Column)
  mvtitle0 = Widget_Label(m3Base, Value='  Offset  ')
  mv_Widget     = CW_CTRLPAD(m4Base)
  mvtitle = Widget_Label(m3Base,  Value='Increment:')
  mvAmountField  = CW_Field(m3Base, Title='',/Floating,$
      value=(*ptrim).movamt, /Return_Events, xsize=8, UValue='moveamt') 
  
  scalbase = Widget_Base(apWindow, /Column, /frame)
  scaleBase1 = Widget_Base(scalbase, /row)
  scaleField     = CW_Field(scalebase1,Value=(*ptrim).scl,XSize=8,/Floating, $
			Title='Flux Scale:',/Return_Events,UValue='scale')
  invsclbutton = Widget_Button(scalebase1, Value='1/flux', UValue='invb', $
                 /align_center)
  scaleBase2     = Widget_Base(scalbase,/row)
  sclAmountField = CW_Field(scaleBase2,Value=(*ptrim).sclamt,XSize=8,$
		     Title='Flux Increment:',/Floating,/Return_Events,$
		     UValue='scaleamount')
  sclupButton    = Widget_Button(scaleBase2,UValue='sclup',Value='+',/align_center)
  scldnButton    = Widget_Button(scaleBase2,UValue='scldown',Value='-', $
		    /align_center)


  biasbase      = Widget_Base(apWindow, /Column, /frame)
  biasField     = CW_Field(biasbase, Title='Image Bias:',value=(*ptrim).bias, $
		       /Return_Events, xsize=8, /Floating,UValue='biasamt')
  biasBase2     = Widget_Base(biasbase,/row)
  biasAmountField = CW_Field(biasBase2,Value=(*ptrim).biasamt,XSize=8,$
		     Title='Bias Increment:',/Floating,/Return_Events,$
		     UValue='biasamount')
  biasupButton   = Widget_Button(biasBase2,UValue='biasup',Value='+',/align_center)
  biasdnButton   = Widget_Button(biasBase2,UValue='biasdown',Value='-', $
		   /align_center)
   
  donebase = Widget_Base(apWindow, /Row)
  if xypos eq 1 then begin
    xyposButton   = Widget_Button(doneBase, Value = 'X/Y Position', $
		    Event_Pro='idp3_setxypos')
  endif else xyposButton = 0L
  helpButotn = Widget_Button(donebase, Value='Help', $
		    Event_Pro='AdjustPosition_help')
  doneButton    = Widget_Button(donebase,Value='Done', $
			        Event_Pro='AdjustPosition_Done')

  info.rtxcenField = rtxcenField
  info.rtycenField = rtycenField
  info.imbiasField = biasField
  info.imscaleField = scaleField

  apinfo = { scaleField     : scaleField,        $
             mvAmountField  : mvAmountField,     $
             rtAmountField  : rtAmountField,     $
             sclAmountField : sclAmountField,    $
	     biasAmountField: biasAmountField,   $
             rtField        : rtField,           $
             zoomField      : zoomField,         $
             biasField      : biasField,         $
	     mv_Widget      : mv_Widget,         $
             sclupButton    : sclupButton,       $
             scldnButton    : scldnButton,       $
             invsclButton   : invsclButton,      $
	     biasupButton   : biasupButton,      $
	     biasdnButton   : biasdnButton,      $
	     nupButton      : nupButton,         $
             rtupButton     : rtupButton,        $
             rtdnButton     : rtdnButton,        $
	     rtxcenField    : rtxcenField,       $
	     rtycenField    : rtycenField,       $
	     padButtons     : padButtons,        $
	     xyposButton    : xyposButton,       $
	     padField       : padField,          $
             xoffField      : xoffField,         $
             yoffField      : yoffField,         $
	     pxsclButton    : pxsclButton,       $
	     psundoButton   : psundoButton,      $
	     clipbotButton  : clipbotButton,     $
	     cliptopButton  : cliptopButton,     $
;	     vhButton       : vhButton,          $
	     info           : info               }

  Widget_Control, apWindow, Set_UValue=apinfo

  Widget_Control, apWindow, /Realize
  info.apWindow = apWindow
  Widget_Control, info.idp3Window, Set_UValue=info

  XManager, 'idp3_adjustposition', apWindow, /No_Block,  $
	    Event_Handler='AdjustPosition_Event'

end

