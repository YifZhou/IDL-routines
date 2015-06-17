; IDP3_ReAlign -- Align all ON images based on the computed centroid 
; centers.  Must have performed an Align by WCS previous to this call.

pro Idp3_ReAlign, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  if not XRegistered('idp3_radprof') then begin
    stat = Dialog_Message('Cannot realign - need Radial Profile Widget')
    return
  endif

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to align
    return
  endif

  non = 0
  maxlen = 0
  bl = ' '
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then begin
      non = non + 1
      ua_decompose, (*(*info.images)[i]).name, disk, path, name, extn, version
      thislen = strlen(name)
      if thislen gt maxlen then maxlen = thislen
    endif
  endfor

  if non le 1 then begin
    if non eq 1 then str = 'Realign: Cannot align one image' $
       else str = 'Realign: No images ON'
    idp3_updatetxt, info, str
    return
  endif
  
  fstr = ' Filename                              '
  hstr = strmid(fstr, 0, maxlen) + $
	 '    Cntrd X     Cntrd Y    Beg X Shft  Beg Y Shft ' + $
	 ' End X Shft  End Y Shft'
  
  roi = *info.roi
  method = (*info.roi).cmethod MOD 2
  Widget_Control, info.rpxcentxt, Get_Value=temp
  xc = float(temp[0])
  if xc le roi.roixorig or xc ge roi.roixend then begin
    test = Widget_Message('Centroid x center outside of ROI, Must Abort!')
    return
  endif
  Widget_Control, info.rpycentxt, Get_Value=temp
  yc = float(temp[0])
  if yc le roi.roiyorig or yc ge roi.roiyend then begin
    test = Widget_Message('Centroid y center outside of ROI, Must abort!')
    return
  endif
  Widget_Control, info.rpfwhmtxt, Get_Value=temp
  if temp[0] eq ' ' then fwhm = 0. else fwhm = float(temp[0])
  if fwhm lt 0.5 then begin
    test = Widget_Message('Invalid value of FWHM, must abort!')
    return
  endif

  if method eq 0 then begin
    zoom = roi.roizoom
    x1 = roi.roixorig
    y1 = roi.roiyorig
    x2 = roi.roixend
    y2 = roi.roiyend
  endif else begin
    zoom = roi.roizoom
    Widget_Control, info.rpradiustxt, Get_Value = temp
    rad = float(temp[0])
    x1 = fix(xc - rad + 0.5) > roi.roixorig
    x2 = fix(xc + rad + 0.5) < roi.roixend
    y1 = fix(yc - rad + 0.5) > roi.roiyorig
    y2 = fix(yc + rad + 0.5) < roi.roiyend
  endelse
  xcen = (xc - x1) * zoom
  ycen = (yc - y1) * zoom
  zfwhm = fwhm * zoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = info.roiioz
  moveim = info.moveimage
  ; Get current size of the draw field.
  dxs = info.drawxsize
  dys = info.drawysize
 
  for i = 0, numimages-1 do begin 
    m = (*info.images)[i]
    if i ne moveim and (*m).vis eq 1 then begin
      ; Figure out how big the display image must be.
      ; This depends on the size of the image and its offsets.
      maxx = ((*m).xsiz + 2 * (*m).pad) * (*m).xpscl * (*m).zoom + (*m).xoff 
      maxy = ((*m).ysiz + 2 * (*m).pad) * (*m).ypscl * (*m).zoom + (*m).yoff
      maxx = maxx + info.sxoff
      maxy = maxy + info.syoff
      if maxx lt dxs then maxx = dxs
      if maxy lt dys then maxy = dys
      ; Start from scratch.
      dispim = fltarr(maxx,maxy)   ; An empty display array
      alphaim = fltarr(maxx,maxy)  ; An empty alpha channel
      mdst = idp3_setdata(info, i)
      mds = mdst[*,*,0]
      alpha = mdst[*,*,1]
      ; Determine where this image should be in the display.
      ; check offsets, check boundaries, etc.
      xoff = (*m).xoff + info.sxoff
      yoff = (*m).yoff + info.syoff
      xsiz = ((*m).xsiz + 2 * (*m).pad) * (*m).zoom * (*m).xpscl 
      ysiz = ((*m).ysiz + 2 * (*m).pad) * (*m).zoom * (*m).ypscl
      idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax,dymin, $
      		       dymax,gxmin,gxmax,gymin,gymax,err
      dispim[gxmin:gxmax,gymin:gymax] = $
           dispim[gxmin:gxmax,gymin:gymax] + mds[dxmin:dxmax,dymin:dymax]
      alphaim[gxmin:gxmax,gymin:gymax] = $
	   alphaim[gxmin:gxmax,gymin:gymax] + alpha[dxmin:dxmax,dymin:dymax]
      ; Get the ROI array, zoom it appropriately.
      tiim = idp3_congrid(dispim[x1:x2,y1:y2], xsize, ysize, $
	 zoom,ztype,info.pixorg)
      if info.zoomflux eq 1 then tiim[*,*] = tiim[*,*]/(*info.roi).roizoom ^ 2
      alph = congrid(alphaim[x1:x2,y1:y2], xsize, ysize)
      ; Calculate the centroid position
      setcflags, (*info.roi).cmethod, info.doirs, wm, gf, cwm, ifp
      if wm eq 1 then begin
	coords = fltarr(4)
	idp3_cntrd,tiim,xcen,ycen,fxcen,fycen,zfwhm,coords
        fxc = fxcen/zoom + x1 
        fyc = fycen/zoom + y1
      endif else if gf eq 1 then begin
	start = fltarr(8)
	start[1] = tiim[xcen,ycen]
	start[2] = zfwhm / 2.534
	start[3] = zfwhm / 2.534
	start[4] = xcen
	start[5] = ycen
	yfit = mpfit2dpeak(tiim, aa, estimates=start, perror=perror, $
		weights=alph, /tilt)
        fxc = aa[4]/zoom + x1
	fyc = aa[5]/zoom + y1
	alpha = 0
	yfit = 0
	aa = 0
	start = 0
      endif
      dispim = 0
      alphaim = 0
      mdst = 0
      mds = 0
      tiim = 0
      alph = 0
      if info.show_wcs gt 0 then begin
	tmphdr = [*(*m).phead, *(*m).ihead]
	sxdelpar, tmphdr, 'CRPIX1'
	sxdelpar, tmphdr, 'CRPIX2'
	sxdelpar, tmphdr, 'CD1_1'
	sxdelpar, tmphdr, 'CD1_2'
	sxdelpar, tmphdr, 'CD2_1'
	sxdelpar, tmphdr, 'CD2_2'
	sxdelpar, tmphdr, 'CRVAL1'
	sxdelpar, tmphdr, 'CRVAL2'
	sxdelpar, tmphdr, 'CDELT1'
	sxdelpar, tmphdr, 'CDELT2'
	sxdelpar, tmphdr, 'CROTA'
	sxdelpar, tmphdr, 'CROTA2'
	sxaddpar, tmphdr, 'CRPIX1', (*m).acrpix1
	sxaddpar, tmphdr, 'CRPIX2', (*m).acrpix2
        sxaddpar, tmphdr, 'CD1_1', (*m).acd11
	sxaddpar, tmphdr, 'CD1_2', (*m).acd12
	sxaddpar, tmphdr, 'CD2_1', (*m).acd21
	sxaddpar, tmphdr, 'CD2_2', (*m).acd22
	sxaddpar, tmphdr, 'CRVAL1', (*m).crval1
	sxaddpar, tmphdr, 'CRVAL2', (*m).crval2
	xyad, tmphdr, float(fxc), float(fyc), xra, xdec
	if info.show_wcs eq 1 then begin
	  idp3_conra, xra/15.0, rastr
	  idp3_condec, xdec, decstr
	  strp = 'ra:' + rastr + '   dec:' + decstr
        endif else begin
	  strp = 'ra:' + string(xra,'$(f12.7)') + '   dec:' + $
	    string(xdec,'$(f12.7)')
        endelse
      str = 'Realign: Centroid: ' + string(fxc) + string(fyc) + '  ' + strp
      idp3_updatetxt, info, str
      endif else begin
	str = 'Realign: Centroid: ' + string(fxc) + string(fyc)
	idp3_updatetxt, info, str
      endelse
      (*(*info.images)[i]).lccx = fxc
      (*(*info.images)[i]).lccy = fyc
      img = (*info.images)[i]
      olcc = idp3_getolcc(img, fxc, fyc, info.sxoff, info.syoff)
      (*(*info.images)[i]).olccx = olcc[0]
      (*(*info.images)[i]).olccy = olcc[1]
      tiim = 0
    endif
  endfor

  ; Get the position of the 'move' image centroid.
  micx = (*(*info.images)[moveim]).lccx
  micy = (*(*info.images)[moveim]).lccy
  openw, lun, 'aligncentroid.txt', width=120, /get_lun
  offx = (*(*info.images)[moveim]).xoff + (*(*info.images)[moveim]).xpoff
  offy = (*(*info.images)[moveim]).yoff + (*(*info.images)[moveim]).ypoff
  fname = (*(*info.images)[moveim]).orgname
  f2name = (*(*info.images)[moveim]).name
  ua_decompose, fname, disk, path, name, extn, version
  ua_decompose, f2name, disk2, path2, name2, extn2, version2
  if info.dospitzer eq 1 then begin
    tname = name + '_tinytim.lis'
    tfname =  name2 + '_psf'
    openw, tlun, tname, /Get_Lun
  endif
  zero = '      0.0000'
  printf, lun, info.header_char, hstr
  clen = strlen(name2)
  xname = name2
  if clen lt maxlen then begin
    for nn = clen, maxlen-1 do begin
      strput, bl, xname, nn
    endfor
  endif
  printf, lun, xname, string(micx,'$(f12.4)'), string(micy,'$(f12.4)'), $
     string(offx,'$(f12.4)'), string(offy,'$(f12.4)'), zero, zero 

  if info.dospitzer eq 1 then $
    printf, tlun, micx - offx, micy - offy, '   ', tfname

  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).lccx ne -1.0 and (*(*info.images)[i]).vis eq 1 $
      and i ne info.moveimage then begin
      deltax = micx - (*(*info.images)[i]).lccx
      deltay = micy - (*(*info.images)[i]).lccy

      tempxoff=(*(*info.images)[i]).xoff + (*(*info.images)[i]).xpoff + deltax
      tempyoff=(*(*info.images)[i]).yoff + (*(*info.images)[i]).ypoff + deltay

      offx = (*(*info.images)[i]).xoff + (*(*info.images)[i]).xpoff
      offy = (*(*info.images)[i]).yoff + (*(*info.images)[i]).ypoff

      fracsa = float(tempxoff) - float(fix(tempxoff))
      intsa  = float(fix(tempxoff - fracsa))
      (*(*info.images)[i]).xpoff = fracsa
      (*(*info.images)[i]).xoff = intsa

      fracsa = float(tempyoff) - float(fix(tempyoff))
      intsa  = float(fix(tempyoff - fracsa))
      (*(*info.images)[i]).ypoff = fracsa
      (*(*info.images)[i]).yoff = intsa
      f2name = (*(*info.images)[i]).name
      ua_decompose, f2name, disk2, path2, name2, extn2, version2
      clen = strlen(name2)
      xname = name2
      if clen lt maxlen then begin
        bl = ' '
        for nn = clen, maxlen-1 do begin
          strput, bl, xname, nn
        endfor
      endif
      printf, lun, xname, string((*(*info.images)[i]).lccx,'$(f12.4)'), $
	string((*(*info.images)[i]).lccy,'$(f12.4)'), string(offx,'$(f12.4)'), $
	string(offy,'$(f12.4)'), string(tempxoff,'$(f12.4)'), $
	string(tempyoff,'$(f12.4)')
      if info.dospitzer eq 1 then begin
        tfname = name2 + '_psf' 
        printf, tlun, (*(*info.images)[i]).lccx - offx, $
		    (*(*info.images)[i]).lccy - offy, '   ', tfname
      endif
    endif
  endfor
  close, lun
  free_lun, lun
  if info.dospitzer eq 1 then begin
    close, tlun
    free_lun, tlun
  endif
  idp3_display,info

  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo

end

