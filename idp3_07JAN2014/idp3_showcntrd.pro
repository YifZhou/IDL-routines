pro showcntrd_done, event
  Widget_Control, event.top, /Destroy
  end

pro showcntrd_upd, event
  Widget_Control, event.top, Get_UValue = scinfo
  Widget_Control, scinfo.info.idp3Window, Get_UValue=info

  if XRegistered('idp3_radprof') then begin
    imptr = (*info.images)[scinfo.ii]
    xcentroid = (*imptr).lccx
    ycentroid = (*imptr).lccy
    if xcentroid gt 0. then begin
      rpxcen = (xcentroid - (*info.roi).roixorig) * (*info.roi).roizoom
      rpycen = (ycentroid - (*info.roi).roiyorig) * (*info.roi).roizoom
      (*info.roi).radxcent = rpxcen
      (*info.roi).radycent = rpycen
      (*info.rprf).sx = xcentroid
      (*info.rprf).sy = ycentroid
      Widget_Control, scinfo.info.idp3Window, Set_UValue=info
      idp3_radprof, info
    endif else begin
      str = 'ShowCentroid: Invalid centroid solution'
      idp3_updatetxt, info, str
    endelse
  endif else begin
    str = 'ShowCentroid: No Radial Profile widget to update'
    idp3_updatetxt, info, str
  endelse
end

pro showcntrd_rcu, event
  Widget_Control, event.top, Get_UValue = scinfo
  Widget_Control, scinfo.info.idp3Window, Get_UValue=info
    
    imptr = (*info.images)[scinfo.ii]
    xcentroid = (*imptr).lccx
    ycentroid = (*imptr).lccy
    tempx = xcentroid
    tempy = ycentroid
    if xcentroid gt 0.0 and ycentroid gt 0.0 then begin
      xoff = (*imptr).xpoff + (*imptr).xoff + info.sxoff
      if xoff gt 0.0 then tempx = tempx - xoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then tempx = tempx / (*imptr).zoom
      if (*imptr).xpscl ne 1.0 and (*imptr).xpscl ne 0.0 $
        then tempx = tempx / (*imptr).xpscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
        then tempx = tempx - (*imptr).pad
      (*imptr).rotcx = tempx
      yoff = (*imptr).ypoff + (*imptr).yoff + info.syoff
      if yoff gt 0.0 then tempy = tempy - yoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then tempy = tempy / (*imptr).zoom
      if (*imptr).ypscl ne 1.0 and (*imptr).ypscl ne 0.0 $
        then tempy = tempy / (*imptr).ypscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
        then tempy = tempy - (*imptr).pad
      (*imptr).rotcy = tempy
      ref = info.moveimage
      if XRegistered('idp3_adjustposition') and scinfo.ii eq ref then begin
        Widget_Control, info.rtxcenField, Set_Value=xcentroid
        Widget_Control, info.rtycenField, Set_Value=ycentroid
      endif
      Widget_Control, scinfo.info.idp3Window, Set_UValue=info
    endif
end
 
pro idp3_showcntrd, info, ii

@idp3_structs
@idp3_errors

  imptr = (*info.images)[ii]
  ua_decompose, (*imptr).name, disk, path, fname, extn, version

  xcentroid = (*imptr).lccx
  ycentroid = (*imptr).lccy

  ctext = strarr(2)
  ctext[0] = ' (X,Y) =' + string(xcentroid,'$(f10.4)') + $
             string(ycentroid,'$(f10.4)')

  if info.show_wcs gt 0 and xcentroid ge 0. then begin
    tmphdr = idp3_setcoords(*imptr, pwcs)
    if pwcs gt 0 then begin
      ra = sxpar(tmphdr, 'CRVAL1')
      dec = sxpar(tmphdr, 'CRVAL2')
      xyad, tmphdr, xcentroid, ycentroid, xra, xdec
      if info.show_wcs eq 1 then begin
        idp3_conra, xra/15.0, rastr
        idp3_condec, xdec, decstr
      endif else begin
        rastr = string(xra,'$(f12.7)')
        decstr = string(xdec,'$(f12.7)')
      endelse
      ctext[1] = 'RA: ' + rastr + '  Dec: ' + decstr
    endif else ctext[1] = '        '
  endif else ctext[1] = '        '
    
  cname = 'idp3_showcntrd' + strtrim(string(ii),2)
  if XRegistered(cname) then begin
    Widget_Control, (*imptr).cntrdtext, Set_Value = ctext
  endif else begin
    ; Pop up a new widget to show the centroid values
    thename = fname + extn
    width = 50
    title = 'IDP3 Show Centroid' 

    scWindow = Widget_Base(group_leader=info.idp3Window, $
			 Title = title, /Base_Align_Left, /Column)
    scbase = Widget_Base(scWindow, /Row)
    sclabel = Widget_Label(scbase, Value = 'Centroid Values: ' + thename)

    wtext = Widget_Text(scWindow, xsize=width, ysize=2, value=ctext)
    cntrdbase = Widget_Base(scWindow, /Row)
    if xcentroid gt 0. then begin
      updButton = Widget_Button(cntrdbase, uvalue='upd', Value = $
	    'Update RP Center', Event_Pro='showcntrd_upd')
      rcButton = Widget_Button(cntrdbase, uvalue='rcu', Value = $
	    'Update Rotation Center', Event_Pro='showcntrd_rcu')
    endif
    donebutton = Widget_Button(cntrdbase, uvalue='exit', Value='Done', $
	       Event_Pro = 'showcntrd_done')

    (*imptr).cntrdtext = wtext
    (*imptr).cntrdwin = scWindow
    (*info.images)[ii] = imptr

    scinfo = { $
  	         wtext      :  wtext,      $
	         ctext      :  ctext,      $
		    ii      :  ii,         $
	          info      :  info        }
  
    Widget_Control, scWindow, Set_UValue=scinfo
    Widget_Control, scWindow, /Realize
 
    XManager, cname, scWindow, /No_Block
  endelse
end

