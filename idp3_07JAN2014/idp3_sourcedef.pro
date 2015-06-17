function rpdata, image, rad, ix, iy, ox, oy, x1, y1

  imsz = size(image)
  x1 = round(ix - rad) > 0
  x2 = round(ix + rad) < (imsz[1]-1)
  y1 = round(iy - rad) > 0
  y2 = round(iy + rad) < (imsz[2]-1)
  ox = ix - float(x1)
  oy = iy - float(y1)
  data = image[x1:x2, y1:y2]
  print, n_elements(data), ' pixels fit'
  return, data
end

pro make_profile, rpimage, xc, yc, zoom, nbins, domed, xplot, yplot

  imsz = size(rpimage)
  if nbins gt 1 then begin
    theplot = fltarr(nbins)
    totalplot = fltarr(nbins)
    theplotcount = intarr(nbins)
    nrej = intarr(nbins)
    maxpt = fix(nbins*2*!pi) + 50
    tempdat = fltarr(nbins,maxpt)
    minx =  0
    maxx = imsz[1]-1
    miny = 0
    maxy = imsz[2]-1
    tmp = ptr_new(bytarr(imsz[1], imsz[2]))
    (*tmp)[*,*] = 1
    for j = miny,maxy do begin
      for i = minx,maxx do begin
        rr = sqrt((float(i)-xc)^2+(float(j)-yc)^2)
        r = round(rr)
        if r le nbins-1 then begin
    	  if ((*tmp)[i,j] eq 1) then begin
	    totalplot[r] = totalplot[r] + rpimage[i,j]
	    tempdat[r,theplotcount(r)] = rpimage[i,j]
	    theplotcount[r] = theplotcount[r] + 1
	  endif else begin
	    nrej[r] = nrej[r] + 1
          endelse
        endif
      endfor
    endfor
    if domed eq 0 then begin
      indx = where(theplotcount gt 0,cnt1)
      temp = where(theplotcount le 0,cnt)
      if cnt gt 0 then begin
        if cnt1 gt 0 then begin
          theplot[indx] = totalplot[indx]/theplotcount[indx]
        endif
      endif else begin
        theplot = totalplot/theplotcount
      endelse
    endif else begin
      for i = 0, nbins-1 do begin
	num = theplotcount[i]-1
	if num gt 0 then begin
	  med = median(tempdat[i,0:num], /even)
	  theplot[i] = med
        endif else begin
	  theplot[i] = totalplot[i]
        endelse
      endfor
    endelse
    if theplotcount[0] eq 0 then begin
      xplot = float(indgen(nbins-1))
      xplot = xplot + 1.0
      xplot = xplot/float(zoom) + 0.5 * (1.0/zoom)
      theplot = theplot[1:nbins-1]
      totalplot = totalplot[1:nbins-1]
      theplotcount = theplotcount[1:nbins-1]
      nrej = nrej[1:nbins-1]
    endif else begin
      xplot = float(indgen(nbins))
      xplot = xplot/float(zoom) + 0.5 * (1.0/zoom)
    endelse
    yplot = theplot
  endif   
end

function get_fwhm, xplot, yplot

   ymin = min(yplot)
   ymax = max(yplot)
   midpt = (ymax + ymin) * 0.5
   numpts = n_elements(yplot)
   xpt = 0.0
   for i = 0, numpts-2 do begin
     if midpt lt yplot[i] and midpt gt yplot[i+1] then begin
       pct = (yplot[i]-midpt) / abs(yplot[i]-yplot[i+1])
       xpt = xplot[i] + pct * abs(xplot[i] - xplot[i+1])
     endif
   endfor
   if xpt gt 0. then begin
     fwhm = 2.0 * xpt
   endif else fwhm = 0.
return, fwhm
end

function get_gfit, gimage, fwhm, xc, yc, perror, bestnorm

  start = fltarr(8)
  start[2] = fwhm / 2.534
  start[3] = fwhm / 2.534
  start[4] = xc
  start[5] = yc
  yfit = mpfit2dpeak(gimage, aa, estimates=start, perror=perror, $
		bestnorm=bestnorm)
return, aa
end

pro source_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=sourceinfo
  Widget_control, sourceinfo.info.idp3Window, Get_UValue = info

  Case event.id of

  sourceinfo.donebutton: begin
    ptr_free, sourceinfo.pimage
    ptr_free, sourceinfo.pdispim
    Widget_Control, event.top, /Destroy
    return
  end

  sourceinfo.pminField: begin
    Widget_Control, sourceinfo.pminField, Get_Value = z1
    sourceinfo.z1 = z1
    z2 = sourceinfo.z2
    image = *(sourceinfo.pimage)
    wset, sourceinfo.sourceid
    bits = info.color_bits
    tv, bytscl(image,top=info.d_colors-bits-1,min=z1, max=z2)+bits
  end

  sourceinfo.pmaxField: begin
    Widget_Control, sourceinfo.pmaxField, Get_Value = z2
    sourceinfo.z2 = z2
    z1 = sourceinfo.z1
    image = *(sourceinfo.pimage)
    wset, sourceinfo.sourceid
    bits = info.color_bits
    tv, bytscl(image,top=info.d_colors-bits-1,min=z1, max=z2)+bits
  end

  sourceinfo.radiusField: begin
    Widget_Control, sourceinfo.radiusField, Get_Value = radius
    sourceinfo.radius = radius
  end

  sourceinfo.displogButton: begin
    xdisplayfile, 'gfitting.log', title='Fit Iteration Log', width=100
  end

  sourceinfo.viewfitButton: begin
  end

  sourceinfo.zoom1button: begin
    dataimage = *(sourceinfo.pdispim)
    zoom = 1
    imsz = size(image)
    xsz = imsz[1] * zoom
    ysz = imsz[2] * zoom
    xmax = sourceinfo.xmax
    ymax = sourceinfo.ymax
    Widget_Control, sourceinfo.sourceDraw, /Destroy
    if xsz le xmax and ysz le ymax then begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	 XSize = xmax, YSize = ymax, $
	 /Motion_Events, /Button_Events, retain=info.retn)
      scroll = 0
    endif else begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	XSize = xsz, YSize = ysz, $
	x_scroll_size=xmax, y_scroll_size=ymax, /scroll, $
	/Motion_Events, /Button_Events, retain=info.retn)
      scroll = 1
    endelse
    Widget_Control, sourceDraw, Get_Value = sourceid
    wset, sourceid
    bits = info.color_bits
    z1 = sourceinfo.z1
    z2 = sourceinfo.z2
    tv, bytscl(image,top=info.d_colors-bits-1,min=z1, max=z2)+bits
    sourceinfo.zoom = zoom
    sourceinfo.xsz = xsz
    sourceinfo.ysz = ysz
    sourceinfo.scroll = scroll
    ptr_free, sourceinfo.pimage
    pimage = ptr_new(dataimage)
    sourceinfo.pimage = pimage
    sourceinfo.sourceid = sourceid
    sourceinfo.sourceDraw = sourceDraw
  end

  sourceinfo.zoom2button: begin
    image = *(sourceinfo.pdispim)
    zoom = 2
    imsz = size(image)
    xsz = imsz[1] * zoom
    ysz = imsz[2] * zoom
    xmax = sourceinfo.xmax
    ymax = sourceinfo.ymax
    Widget_Control, sourceinfo.sourceDraw, /Destroy
    if xsz le xmax and ysz le ymax then begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	 XSize = xmax, YSize = ymax, $
	 /Motion_Events, /Button_Events, retain=info.retn)
      scroll = 0
    endif else begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	XSize = xsz, YSize = ysz, $
	x_scroll_size=xmax, y_scroll_size=ymax, /scroll, $
	/Motion_Events, /Button_Events, retain=info.retn)
      scroll = 1
    endelse
    Widget_Control, sourceDraw, Get_Value = sourceid
    wset, sourceid
    bits = info.color_bits
    z1 = sourceinfo.z1
    z2 = sourceinfo.z2
    dataimage = idp3_congrid(image, xsz, ysz, zoom, info.mdioz, info.pixorg)
    tv, bytscl(dataimage,top=info.d_colors-bits-1,min=z1, max=z2)+bits
    sourceinfo.zoom = zoom
    sourceinfo.xsz = xsz
    sourceinfo.ysz = ysz
    sourceinfo.scroll = scroll
    ptr_free, sourceinfo.pimage
    pimage = ptr_new(dataimage)
    sourceinfo.pimage = pimage
    sourceinfo.sourceid = sourceid
    sourceinfo.sourceDraw = sourceDraw
  end

  sourceinfo.zoom4button: begin
    image = *(sourceinfo.pdispim)
    zoom = 4
    imsz = size(image)
    xsz = imsz[1] * zoom
    ysz = imsz[2] * zoom
    xmax = sourceinfo.xmax
    ymax = sourceinfo.ymax
    Widget_Control, sourceinfo.sourceDraw, /Destroy
    if xsz le xmax and ysz le ymax then begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	 XSize = xmax, YSize = ymax, $
	 /Motion_Events, /Button_Events, retain=info.retn)
      scroll = 0
    endif else begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	XSize = xsz, YSize = ysz, $
	x_scroll_size=xmax, y_scroll_size=ymax, /scroll, $
	/Motion_Events, /Button_Events, retain=info.retn)
      scroll = 1
    endelse
    Widget_Control, sourceDraw, Get_Value = sourceid
    wset, sourceid
    bits = info.color_bits
    z1 = sourceinfo.z1
    z2 = sourceinfo.z2
    dataimage = idp3_congrid(image, xsz, ysz, zoom, info.mdioz, info.pixorg)
    tv, bytscl(dataimage,top=info.d_colors-bits-1,min=z1, max=z2)+bits
    sourceinfo.zoom = zoom
    sourceinfo.xsz = xsz
    sourceinfo.ysz = ysz
    sourceinfo.scroll = scroll
    ptr_free, sourceinfo.pimage
    pimage = ptr_new(dataimage)
    sourceinfo.pimage = pimage
    sourceinfo.sourceid = sourceid
    sourceinfo.sourceDraw = sourceDraw
  end

  sourceinfo.zoom8button: begin
    image = *(sourceinfo.pdispim)
    zoom = 8
    imsz = size(image)
    xsz = imsz[1] * zoom
    ysz = imsz[2] * zoom
    xmax = sourceinfo.xmax
    ymax = sourceinfo.ymax
    Widget_Control, sourceinfo.sourceDraw, /Destroy
    if xsz le xmax and ysz le ymax then begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	 XSize = xmax, YSize = ymax, $
	 /Motion_Events, /Button_Events, retain=info.retn)
      scroll = 0
    endif else begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	XSize = xsz, YSize = ysz, $
	x_scroll_size=xmax, y_scroll_size=ymax, /scroll, $
	/Motion_Events, /Button_Events, retain=info.retn)
      scroll = 1
    endelse
    Widget_Control, sourceDraw, Get_Value = sourceid
    wset, sourceid
    bits = info.color_bits
    z1 = sourceinfo.z1
    z2 = sourceinfo.z2
    dataimage = idp3_congrid(image, xsz, ysz, zoom, info.mdioz, info.pixorg)
    tv, bytscl(dataimage,top=info.d_colors-bits-1,min=z1, max=z2)+bits
    sourceinfo.zoom = zoom
    sourceinfo.xsz = xsz
    sourceinfo.ysz = ysz
    sourceinfo.scroll = scroll
    ptr_free, sourceinfo.pimage
    pimage = ptr_new(dataimage)
    sourceinfo.pimage = pimage
    sourceinfo.sourceid = sourceid
    sourceinfo.sourceDraw = sourceDraw
  end

  sourceinfo.zoom16button: begin
    image = *(sourceinfo.pdispim)
    zoom = 16
    imsz = size(image)
    xsz = imsz[1] * zoom
    ysz = imsz[2] * zoom
    xmax = sourceinfo.xmax
    ymax = sourceinfo.ymax
    Widget_Control, sourceinfo.sourceDraw, /Destroy
    if xsz le xmax and ysz le ymax then begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	 XSize = xmax, YSize = ymax, $
	 /Motion_Events, /Button_Events, retain=info.retn)
      scroll = 0
    endif else begin
      sourceDraw = Widget_Draw(sourceinfo.sourceWindow, $
	XSize = xsz, YSize = ysz, $
	x_scroll_size=xmax, y_scroll_size=ymax, /scroll, $
	/Motion_Events, /Button_Events, retain=info.retn)
      scroll = 1
    endelse
    Widget_Control, sourceDraw, Get_Value = sourceid
    wset, sourceid
    bits = info.color_bits
    z1 = sourceinfo.z1
    z2 = sourceinfo.z2
    dataimage = idp3_congrid(image, xsz, ysz, zoom, info.mdioz, info.pixorg)
    tv, bytscl(dataimage,top=info.d_colors-bits-1,min=z1, max=z2)+bits
    sourceinfo.zoom = zoom
    sourceinfo.xsz = xsz
    sourceinfo.ysz = ysz
    sourceinfo.scroll = scroll
    ptr_free, sourceinfo.pimage
    pimage = ptr_new(dataimage)
    sourceinfo.pimage = pimage
    sourceinfo.sourceid = sourceid
    sourceinfo.sourceDraw = sourceDraw
  end

  sourceinfo.sourceDraw: begin

    image = *(sourceinfo.pimage)
    imsz = size(image)
    zoom = float(sourceinfo.zoom)
    x = event.x > 0 < (imsz[1] - 1)
    y = event.y > 0 < (imsz[2] - 1)
    xp = float(x) / zoom
    yp = float(y) / zoom
    vstr = strtrim(string(image[x,y]),2)
    str = string(format="('X:',f8.3, ' Y:', f8.3, '  Value: ')", xp, yp) + $
	  vstr
    Widget_Control, sourceinfo.pixlab, Set_Value = str
    if event.press eq 1 then begin
      Widget_Control, sourceinfo.radiusField, Get_Value = radius
      if radius le 0.0 then begin
	stat = Widget_Message('Must define profile radius!')
	return
      endif
      openw, glun, 'gfitting.log', width=100, /get_lun, /append
      sourceinfo.radius = radius
      domed = (*info.roi).rpmm
      rad0 = radius * zoom
      nbins = round(rad0) + 1
      data = rpdata(image, rad0, x, y, xc0, yc0, xb0, yb0)
      make_profile, data, xc0, yc0, zoom, nbins, domed, xplot, yplot
      fwhm0 = get_fwhm(xplot, yplot) * zoom
      rad1 = fwhm0 * 1.22
      nbins = round(rad1) + 1
      data = rpdata(image, rad1, x, y, xc1, yc1, xb1, yb1)
      make_profile, data, xc1, yc1, zoom, nbins, domed, xplot, yplot
      fwhm1 = get_fwhm(xplot, yplot) * zoom
      res = get_gfit(data, fwhm1, xc1, yc1, perror, bestnorm)
      x0 = res[4] + xb1
      y0 = res[5] + yb1
      xfwhm = res[2] * 2.534
      yfwhm = res[3] * 2.534
      dof = n_elements(data) - n_elements(start)
      scf = sqrt(bestnorm / float(dof))
      printf, glun, '   '
      printf, glun, 'File: ', sourceinfo.rname
      str = 'Iteration 1: ' + $
	    string(x0/zoom,'$(f8.3)') + $
	    ' (' + string(perror[4]*scf,'$(f9.5)') + ')  ' + $
	    string(y0/zoom,'$(f8.3)') + $
	    ' (' + string(perror[5]*scf,'$(f9.5)') + ')  ' + $
	    string(xfwhm/zoom,'$(f7.4)') + $
	    ' (' + string(perror[2]*scf,'$(f9.5)') + ')  ' + $
	    string(yfwhm/zoom, '$(f7.4)') + $
	    ' (' + string(perror[3]*scf,'$(f9.5)') + ')  ' + $
	    string(rad1/zoom,'$(f6.3)')
      printf, glun, str
      data = rpdata(image, rad1, x0, y0, xc2, yc2, xb2, yb2)
      make_profile, data, xc2, yc2, zoom, nbins, domed, xplot, yplot
      fwhm2 = get_fwhm(xplot, yplot) * zoom
      rad2 = rad1  ;ceil(fwhm2 * 1.22)
      res = get_gfit(data, fwhm2, xc2, yc2, perror)
      x1 = res[4] + xb2
      y1 = res[5] + yb2 
      xfwhm = res[2] * 2.534 
      yfwhm = res[3] * 2.534
      dof = n_elements(data) - n_elements(start)
      scf = sqrt(bestnorm / float(dof))
      str = 'Iteration 2: ' + $
	    string(x1/zoom,'$(f8.3)') + $
	    ' (' + string(perror[4]*scf,'$(f9.5)') + ')  ' + $
	    string(y1/zoom,'$(f8.3)') + $
	    ' (' + string(perror[5]*scf,'$(f9.5)') + ')  ' + $
	    string(xfwhm/zoom,'$(f7.4)') + $
	    ' (' + string(perror[2]*scf,'$(f9.5)') + ')  ' + $
	    string(yfwhm/zoom, '$(f7.4)') + $
	    ' (' + string(perror[3]*scf,'$(f9.5)') + ')  ' + $
	    string(rad2/zoom,'$(f6.3)')
      printf, glun, str
      data = rpdata(image, rad2, x1, y1, xc3, yc3, xb3, yb3)
      make_profile, data, xc3, yc3, zoom, nbins, domed, xplot, yplot
      fwhm3 = get_fwhm(xplot, yplot) * zoom
      rad3 = rad1  ;ceil(fwhm3 * 1.22)
      res = get_gfit(data, fwhm3, xc3, yc3, perror)
      x2 = res[4] + xb3
      y2 = res[5] + yb3 
      xfwhm = res[2] * 2.534 
      yfwhm = res[3] * 2.534
      dof = n_elements(data) - n_elements(start)
      scf = sqrt(bestnorm / float(dof))
      str = 'Iteration 3: ' + $
	    string(x2/zoom,'$(f8.3)') + $
	    ' (' + string(perror[4]*scf,'$(f9.5)') + ')  ' + $
	    string(y2/zoom,'$(f8.3)') + $
	    ' (' + string(perror[5]*scf,'$(f9.5)') + ')  ' + $
	    string(xfwhm/zoom,'$(f7.4)') + $
	    ' (' + string(perror[2]*scf,'$(f9.5)') + ')  ' + $
	    string(yfwhm/zoom, '$(f7.4)') + $
	    ' (' + string(perror[3]*scf,'$(f9.5)') + ')  ' + $
	    string(rad3/zoom,'$(f6.3)')
      printf, glun, str
      data = rpdata(image, rad3, x2, y2, xc4, yc4, xb4, yb4)
      make_profile, data, xc4, yc4, zoom, nbins, domed, xplot, yplot
      fwhm4 = get_fwhm(xplot, yplot) * zoom
      rad4 = rad1 ;ceil(fwhm4 * 1.22)
      res = get_gfit(data, fwhm4, xc4, yc4, perror)
      x3 = res[4] + xb3
      y3 = res[5] + yb3 
      xfwhm = res[2] * 2.534 
      yfwhm = res[3] * 2.534
      dof = n_elements(data) - n_elements(start)
      scf = sqrt(bestnorm / float(dof))
      str = 'Iteration 4: ' + $
	    string(x3/zoom,'$(f8.3)') + $
	    ' (' + string(perror[4]*scf,'$(f9.5)') + ')  ' + $
	    string(y3/zoom,'$(f8.3)') + $
	    ' (' + string(perror[5]*scf,'$(f9.5)') + ')  ' + $
	    string(xfwhm/zoom,'$(f7.4)') + $
	    ' (' + string(perror[2]*scf,'$(f9.5)') + ')  ' + $
	    string(yfwhm/zoom, '$(f7.4)') + $
	    ' (' + string(perror[3]*scf,'$(f9.5)') + ')  ' + $
	    string(rad4/zoom,'$(f6.3)')
      printf, glun, str
      close, glun
      free_lun, glun
      err = sqrt((perror[2]*scf)^2 + (perror[3]*scf)^2)
      diff = (abs(xfwhm - yfwhm) / zoom) * 0.5
      eratio = diff / err
      print, err, diff, eratio
      str = 'Fit: ' + $
	    string(x3/zoom,'$(f8.3)') + $
	    ' (' + string(perror[4]*scf,'$(f7.4)') + ') ' + $
	    string(y3/zoom,'$(f8.3)') + $
	    ' (' + string(perror[5]*scf,'$(f7.4)') + ') ' + $
	    string(xfwhm/zoom,'$(f7.4)') + $
	    ' (' + string(perror[2]*scf,'$(f7.4)') + ') ' + $
	    string(yfwhm/zoom, '$(f7.4)') + $
	    ' (' + string(perror[3]*scf,'$(f7.4)') + ') 
        str = str + string(eratio, '$(f6.2)')
      Widget_Control, sourceinfo.reslab, Set_Value = str
    endif
  end

  else:
  endcase

  Widget_Control, sourceinfo.info.idp3Window, Set_UValue = info
  Widget_Control, event.top, Set_UValue = sourceinfo
end

pro idp3_sourcedef, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info

  ; If there are no images, return
  c = size(*info.images)
  if (c[0] eq 0 and c[1] le 2) then begin 
    str = 'Source Def: No data loaded'
    idp3_updatetxt, info, str
    return
  endif

  ; get reference image if on
  moveim = info.moveimage
  ims = info.images
  ref = (*ims)[info.moveimage]
  if (*ref).vis ne 1 then begin
    stat = Widget_Message('Reference Image not ON')
    return
  endif
  ; Figure out how big the display image must be.
  ; This depends on the size of the image and its offsets.
  maxx = ((*ref).xsiz + 2 * (*ref).pad) * (*ref).xpscl * (*ref).zoom + $
	 (*ref).xoff
  maxy = ((*ref).ysiz + 2 * (*ref).pad) * (*ref).ypscl * (*ref).zoom + $
	 (*ref).yoff
  maxx = maxx + info.sxoff
  maxy = maxy + info.syoff
  dispim = fltarr(maxx,maxy) 
  dispim[*,*] = 0.
  mdst = idp3_setdata(info, moveim)
  mds = mdst[*,*,0]
  ; Determine where this image should be in the display.
  ; check offsets, check boundaries, etc.
  xoff = (*ref).xoff + info.sxoff
  yoff = (*ref).yoff + info.syoff
  xsiz = ((*ref).xsiz + 2 * (*ref).pad) * (*ref).zoom * (*ref).xpscl
  ysiz = ((*ref).ysiz + 2 * (*ref).pad) * (*ref).zoom * (*ref).ypscl
  idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax,dymin,dymax, $
		   gxmin,gxmax,gymin,gymax,err
  dispim[gxmin:gxmax,gymin:gymax] = $
      dispim[gxmin:gxmax,gymin:gymax] + mds[dxmin:dxmax,dymin:dymax]
  rname = (*ref).name
  ua_decompose, rname, disk, path, name, extn, vers
  refstr = 'Ref:' + name + extn
  radius = 0.
 
  xmax = 512
  ymax = 512
  z1 = info.Z1
  z2 = info.Z2
  zoom = info.sourcezoom
  xsz = maxx * zoom
  ysz = maxy * zoom
  if zoom gt 1 then begin
    dataimage = idp3_congrid(dispim, xsz, ysz, zoom, mdioz, info.pixorg)
  endif else dataimage = dispim
  mdst = 0
  mds = 0
  pdispim = ptr_new(dispim)
  pimage = ptr_new(dataimage)

    sourceWindow = Widget_Base(Title='IDP3 Image Source Location', /Column, $
	       Group_Leader = event.top, Mbar=menuBar, /TLB_Size_Events, $
	       TLB_Frame_Attr=8, XOffset = info.wpos.rpwp[0], $
	       YOffset = info.wpos.rpwp[1]) 

    ; build menu bar
    source_fileMenu = Widget_Button(menuBar, Value = "File  ", /Menu)
    source_zoomMenu = Widget_Button(menuBar, Value="  Zoom  ", /Menu)
    source_editMenu = Widget_Button(menuBar, Value = "  Edit  ", /Menu)
    source_alignMenu = Widget_Button(menuBar, Value="  Align  ", /Menu)
    source_doneMenu = Widget_Button(menuBar, Value="  Done  ", /Menu)

    ; Add to Zoom Menu
    zoom1Button = Widget_Button(source_zoomMenu, Value=' 1 ')
    zoom2Button = Widget_Button(source_zoomMenu, Value=' 2 ')
    zoom4Button = Widget_Button(source_zoomMenu, Value=' 4 ')
    zoom8Button = Widget_Button(source_zoomMenu, Value=' 8 ')
    zoom16Button = Widget_Button(source_zoomMenu, Value=' 16 ')
    
    ; Add to Edit Menu
    undolastButton = Widget_Button(source_editMenu, Value = 'Delete Last')
    undoallButton = Widget_Button(source_editMenu, Value='Delete All')

    ; Add to File Menu
    displogButton = Widget_Button(source_fileMenu, Value = 'Show Fit Log')
    viewfitButton = Widget_Button(source_fileMenu, Value = 'View Fit List')

    ; Add to Align Menu
    fitButton = Widget_Button(source_alignMenu, Value='Fit Images')
    alignButton = Widget_Button(source_alignMenu, Value='Align Images')

    ; Add to Done Menu
    doneButton = Widget_Button(source_doneMenu, Value='Done')

    namlab = Widget_Label(sourceWindow, Value = refstr)
    pixBase = Widget_Base(sourceWindow, /Row)
    pminField = cw_field(pixBase, value=z1, title='Plot: Min', xsize=8, $
		uvalue='pmin', /Return_Events, /Floating)
    pmaxField = cw_field(pixBase, value=z2, title='Max', xsize=8, $
		uvalue='pmax', /Return_Events, /Floating)

    radiusField = cw_field(pixbase, value=0., title='   Radius:', $
		uvalue='crad', xsize=8, /Return_Events, /Floating)
    splab = Widget_Label(pixbase, Value = '    ')
    saveButton = Widget_Button(pixbase, Value = ' Save Fit', /align_center)
    resbase = Widget_Base(sourceWindow, frame=1, map=1, column=1)
    reslab = Widget_Label(resbase, Value = '                              ' + $
       '                                                         ')
    if xsz le xmax and ysz le ymax then begin
       sourceDraw = Widget_Draw(sourceWindow, XSize = xmax, YSize = ymax, $
	       /Motion_Events, /Button_Events, retain=info.retn) 
       scroll = 0
    endif else begin 
       sourceDraw = Widget_Draw(sourceWindow, XSize = xsz, YSize = ysz, $
	       x_scroll_size=xmax, y_scroll_size=ymax, /scroll, $
	       /Motion_Events, /Button_Events, retain=info.retn)
       scroll = 1
    endelse
    pixlab = Widget_Label(sourceWindow, Value = $
     '                                              ')

    Widget_Control, sourceWindow, /Realize

;    info.sourceWindow = sourceWindow
;    Widget_Control,info.idp3Window,Set_UValue=info

    Widget_Control, sourceDraw, Get_Value = sourceid
    wset, sourceid
    bits = info.color_bits
    tv, bytscl(dataimage,top=info.d_colors-bits-1,min=z1, max=z2)+bits

    sourceinfo = { sourceWindow    :  sourceWindow,    $
		   zoom1Button     :  zoom1Button,     $
		   zoom2Button     :  zoom2Button,     $
		   zoom4Button     :  zoom4Button,     $
		   zoom8Button     :  zoom8Button,     $
		   zoom16Button    :  zoom16Button,    $
		   displogButton   :  displogButton,   $
		   viewfitButton   :  viewfitButton,   $
		   undolastButton  :  undolastButton,  $
		   undoallButton   :  undoallButton,   $
		   doneButton      :  doneButton,      $
		   pixlab          :  pixlab,          $
		   pminField       :  pminField,       $
		   pmaxField       :  pmaxField,       $
		   radiusField     :  radiusField,     $
		   reslab          :  reslab,          $
		   sourceid        :  sourceid,        $
		   sourceDraw      :  sourceDraw,      $
		   scroll          :  scroll,          $
		   zoom            :  zoom,            $
		   xsz             :  xsz,             $
		   ysz             :  ysz,             $
		   xmax            :  xmax,            $
		   ymax            :  ymax,            $
		   radius          :  radius,          $
		   z1              :  z1,              $
		   z2              :  z2,              $
		   pdispim         :  pdispim,         $
		   pimage          :  pimage,          $
		   rname           :  rname,           $
	           info            :  info             }

    Widget_Control, info.idp3Window, Set_UValue = info
    Widget_Control, sourceWindow, Set_UValue = sourceinfo
    XManager, 'idp3_source', sourceWindow, /No_Block, Event_Handler='source_ev'

end

