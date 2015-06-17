; IDP3_INDWCSCentroid -- Centroid all on images by determining the first
; guesses (gaussian fit) by comparing each WCS to the WCS of the reference
; image.  Must have performed radial profile and centroid on reference image.
; The world coordinates of each frame are used to find the location of the
; RA and DEC in that image.

pro Idp3_INDWCSCentroid, event

@idp3_structs
@idp3_errors

;  forward_function idp3_getcoords
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  if not XRegistered('idp3_radprof') then begin
    stat = Dialog_Message( $
      'Cannot centroid without Radial Profile Widget active')
    return
  endif

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to align
    return
  endif

  non = 0
  maxlen = 0
  bl = ' '

  indx = 0
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    ua_decompose, (*(*info.images)[i]).name, disk, path, name, extn, version
    if (*(*info.images)[i]).vis eq 1 then begin
      thislen = strlen(name)
      if thislen gt maxlen then maxlen = thislen
      non = non + 1
    endif
    if indx eq 0 then names = name else names = [names, name]
    indx = indx + 1
  endfor

  if non le 1 then begin
    if non eq 1 then begin
      str = 'IndCentroids: Nothing to compute'
      idp3_updatetxt, info, str
    endif
    return
  endif
  
  fstr = ' Filename                              '
  hstr = strmid(fstr, 0, maxlen) + $
	 '    Cntrd X     Cntrd Y    Shift X     Shift Y ' 
 
  moveim = info.moveimage
  openw, lun, 'ind_wcs_centroid.txt', /Get_Lun
  m = (*info.images)[moveim]

  roi = *info.roi
  rx1 = roi.roixorig
  ry1 = roi.roiyorig
  rx2 = roi.roixend
  ry2 = roi.roiyend
  xhalf = (float(rx2) - float(rx1)) * 0.5
  yhalf = (float(ry2) - float(ry1)) * 0.5
  zoom = roi.roizoom
  ztype = info.roiioz
  Widget_Control, info.rpxcentxt, Get_Value=temp
  rxc = Double(temp[0])
  Widget_Control, info.rpycentxt, Get_Value=temp
  ryc = Double(temp[0])
  Widget_Control, info.rpradiustxt, Get_Value=temp
  rad = float(temp[0]) * zoom
  printf, lun, hstr
  shift = '     0.000'
  str = string(moveim,'$(i4)') + '  ' + names[moveim] + $
	string(rxc,'$(f12.5)') + string(ryc,'$(f12.5)') + $
	string(shift,'$(f12.5)') + string(shift,'$(f12.5)')
  printf, lun, str
  idp3_updatetxt, info, str 
  setcflags, (*info.roi).cmethod, info.doirs, wm, gf, cwm, ifp
  if cwm eq 1 then begin
    stat = Widget_Message('Constrained Weighted Moment not supported!')
    return
  endif 
  if wm eq 0 and gf eq 0 then begin
    stat = widget_message('Must select method before centroiding')
    return
  endif
  Widget_Control, info.rpfwhmtxt, Get_Value=temp
  if temp[0] eq ' ' then fwhm = 0. else fwhm = float(temp[0])
  zfwhm = fwhm * zoom
  if fwhm lt 0.5 then begin
    test = Widget_Message('Must define FWHM before centroiding!')
    return
  endif

  if (*m).crval1 gt 0.0 then begin
    idp3_getcoords, 0, rxc, ryc, nra, ndec, imstr=m
    rxc = rxc[0]
    ryc = ryc[0]
    nra = nra[0]
    ndec = ndec[0]
    if nra lt 0 then begin
      str = 'IndCentroids: No valid WCS info'
      idp3_updatetxt, info, str
      return
    endif 
  endif

  for i = 0, numimages-1 do begin
    m = (*info.images)[i]
    if (*m).vis eq 1 and i ne moveim  then begin
      if (*m).crval1 le 0.0 then begin
	xc = rxc
	yc = ryc
      endif else begin
	idp3_getcoords, 1, xc, yc, nra, ndec, imstr=m
	xc = xc[0]
	yc = yc[0]
	nra = nra[0]
	ndec = ndec[0]
        if xc lt 0 then begin
          str = 'IndCentroids: No valid WCS info'
	  idp3_updatetxt, info, str
          return
        endif 
      endelse
      mdst = idp3_setdata(info, i)
      dispim = mdst[*,*,0]
      alphaim = mdst[*,*,1]
      imsz = size(dispim)
      x1 = Round(xc - xhalf) > 0
      x2 = Round(xc + xhalf) < (imsz[1]-1)
      y1 = Round(yc - yhalf) > 0
      y2 = Round(yc + yhalf) < (imsz[1]-1)
      xsize = (abs(x2-x1)+1) * zoom
      ysize = (abs(y2-y1)+1) * zoom
      tmpim = dispim[x1:x2,y1:y2]
      tiim = idp3_congrid(tmpim, xsize, ysize, zoom,ztype,info.pixorg)
      alph = congrid(alphaim[x1:x2,y1:y2], xsize, ysize)
      maxwgt = max(alph)
      alph = alph/maxwgt
      ; Calculate the centroid position
      xcen = (xc - float(x1)) * zoom
      ycen = (yc - float(y1)) * zoom
      if wm eq 1 then begin
	coords = fltarr(4)
	idp3_cntrd,tiim,xcen,ycen,fxcen,fycen,zfwhm,coords
	fxc = fxcen/zoom + float(x1)
	fyc = fycen/zoom + float(y1)
	cdeltax = rxc - fxc
	cdeltay = ryc - fyc
	str = string(i,'$(i4)') + '  ' + names[i] + $
	      string(fxc,'$(f12.5)') + string(fyc,'$(f12.5)') + $
	      string(cdeltax,'$(f12.5)') + string(cdeltay,'$(f12.5)')
        idp3_updatetxt, info, str
	printf, lun, str
      endif else if gf eq 1 then begin
	xg1 = Round(xcen - rad) > 0
	xg2 = Round(xcen + rad) < (xsize-1)
	yg1 = Round(ycen - rad) > 0
	yg2 = Round(ycen + rad) < (ysize-1)
	start = fltarr(8)
	start[1] = tiim[xcen,ycen]
	start[2] = zfwhm / 2.534
	start[3] = zfwhm / 2.534
	start[4] = xcen - float(xg1)
	start[5] = ycen - float(yg1)
	yfit = mpfit2dpeak(tiim[xg1:xg2,yg1:yg2], aa, estimates=start, perror=perror, $
	     weights=alph[xg1:xg2,yg1:yg2], /tilt)
        fxc = (aa[4]+float(xg1))/zoom + float(x1)
	fyc = (aa[5]+float(yg1))/zoom + float(y1)
	cdeltax = rxc - fxc
	cdeltay = ryc - fyc
	str = string(i,'$(i4)') + '  ' + names[i] + $
	      string(fxc,'$(f12.5)') + string(fyc,'$(f12.5)') + $
	      string(cdeltax,'$(f12.5)') + string(cdeltay,'$(f12.5)')
        idp3_updatetxt, info, str
	printf, lun, str
	(*(*info.images)[i]).lccx = fxc
	(*(*info.images)[i]).lccy = fyc
	img = (*info.images)[i]
	olcc = idp3_getolcc(img, fxc, fyc, info.sxoff, info.syoff)
	(*(*info.images)[i]).olccx = olcc[0]
	(*(*info.images)[i]).olccy = olcc[1]
      endif
    endif
    m = 0
    mdst = 0
    dispim = 0
    alphaim = 0
    tmpim = 0
    tiim = 0
    alph = 0
  endfor
  close, lun
  free_lun, lun
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo

end

