; IDP3_WCSCentroid -- Centroid all on images by determining the first
; guesses (gaussian fit) by comparing each WCS to the WCS of the reference
; image.  Must have performed radial profile and centroid on reference image.

pro Idp3_WCSCentroid, event

@idp3_structs
@idp3_errors

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
      str = 'WCSCentroid: Nothing to compute'
      idp3_updatetxt, info, str
    endif
    return
  endif
  
  fstr = ' Filename                              '
  hstr = strmid(fstr, 0, maxlen) + $
	 '    Cntrd X     Cntrd Y    Shift X     Shift Y ' 
 
  moveim = info.moveimage
  openw, lun, 'wcs_centroid.txt', /Get_Lun
  m = (*info.images)[moveim]

  refcrval1 = (*m).acrval1
  refcrval2 = (*m).acrval2
  refcd11 = (*m).acd11
  refcd12 = (*m).acd12
  refcd21 = (*m).acd21
  refcd22 = (*m).acd22

  roi = *info.roi
  rx1 = roi.roixorig
  ry1 = roi.roiyorig
  rx2 = roi.roixend
  ry2 = roi.roiyend
  zoom = roi.roizoom
  ztype = info.roiioz
  Widget_Control, info.rpxcentxt, Get_Value=temp
  rxc = float(temp[0])
  Widget_Control, info.rpycentxt, Get_Value=temp
  ryc = float(temp[0])
  Widget_Control, info.rpradiustxt, Get_Value=temp
  rad = float(temp[0]) * zoom
  printf, lun, hstr
  shift = '     0.000'
  str = string(moveim,'$(i4)') + '  ' + names[moveim] + $
	string(rxc,'$(f12.5)') + string(ryc,'$(f12.5)') + $
	string(shift,'$(f12.5)') + string(shift,'$(f12.5)')
  printf, lun, str
  idp3_updatetxt, info, str
  if info.dospitzer eq 1 then begin
    fname = (*m).orgname
    f2name = (*m).name
    ua_decompose, fname, disk, path, name, extn, version
    ua_decompose, f2name, disk2, path2, name2, extn2, version2
    tname = name + '_wcs_tinytim.lis'
    tfname =  name2 + '_psf'
    openw, tlun, tname, /Get_Lun
    printf, tlun, string(rxc,'$(f12.5)'), string(ryc,'$(f12.5)'), tfname
  endif
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

  for i = 0, numimages-1 do begin
    m = (*info.images)[i]
    if (*m).crval1 ne -1.0 and (*m).vis eq 1 and i ne moveim  then begin
      crval1 = (*m).acrval1
      crval2 = (*m).acrval2
      cd11 = (*m).acd11
      cd12 = (*m).acd12
      cd21 = (*m).acd21
      cd22 = (*m).acd22
      if crval1 le 0.0 and crval2 le 0.0 then begin
	xdeltax = 0.
	xdeltay = 0.
      endif else begin
        idp3_pixoffset, refcd11, refcd12, refcd21, refcd22, $
	  refcrval1, refcrval2, crval1, crval2, xdeltax, xdeltay
      endelse
      mdst = idp3_setdata(info, i)
      dispim = mdst[*,*,0]
      alphaim = mdst[*,*,1]
      mdst = 0
      imsz = size(dispim)
      x1 = Round(rx1 - xdeltax) > 0
      x2 = Round(rx2 - xdeltax) < (imsz[1]-1)
      y1 = Round(ry1 - xdeltay) > 0
      y2 = Round(ry2 - xdeltay) < (imsz[2]-1)
      xc = rxc - xdeltax > x1 < x2
      yc = ryc - xdeltay > y1 < y2
      xsize = (abs(x2-x1)+1) * zoom
      ysize = (abs(y2-y1)+1) * zoom
      tiim = idp3_congrid(dispim[x1:x2,y1:y2], xsize, ysize, $
	  zoom,ztype,info.pixorg)
      if info.zoomflux eq 1 then tiim[*,*] = tiim[*,*]/zoom ^ 2
      alph = idp3_congrid(alphaim[x1:x2,y1:y2], xsize, ysize, $
	  zoom,ztype,info.pixorg)
      dispim = 0
      alphaim = 0
      maxwgt = max(sqrt(alph))
      alph = sqrt(alph)/maxwgt
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
        if info.dospitzer eq 1 then begin
          f2name = (*m).name
	  ua_decompose, f2name, disk2, path2, name2, extn2, version2
	  tfname = name2 + '_psf'
	  printf, tlun, string(fxc,'$(f12.5)'), string(fyc,'$(f12.5)'), $
	     tfname
        endif
      endif else if gf eq 1 then begin
	xg1 = Round(xcen - rad) > 0
	xg2 = Round(xcen + rad) < (xsize-1)
	yg1 = Round(ycen - rad) > 0
	yg2 = Round(ycen + rad) < (ysize-1)
	fitdata = tiim[xg1:xg2,yg1:yg2]
	tmpalpha = alph[xg1:xg2,yg1:yg2]
	rm1 = moment(fitdata[where(tmpalpha gt 0.)])
	fmin = min(fitdata)
	fminloc = where(fitdata eq fmin)
	tmpalpha[fminloc] = 0.
	rm2 = moment(fitdata[where(tmpalpha gt 0.)])
	if sqrt(rm1[1])/sqrt(rm2[1]) ge 7.5 then begin
	  fitalpha = tmpalpha
	  str = 'WCSCentroids: minimum ' + string(fmin) + ' excluded from fit'
	  idp3_updatetxt, info, str
        endif else fitalpha = alph[xg1:xg2, yg1:yg2]
;	fitalpha = alph[xg1:xg2, yg1:yg2]
	start = fltarr(8)
	fmax = max(tiim[xcen-1:xcen+1,ycen-1:ycen+1])
	if tiim[xcen,ycen] lt fmax*0.5 then begin
	  start[1]=fmax 
	  str = 'WCSCentroids: Resetting gaussian height from ' + $
	    string(tiim[xcen,ycen]) + ' to ' + string(fmax)
          idp3_updatetxt, info, str
	endif else start[1] = tiim[xcen,ycen]
;	start[1] = tiim[xcen,ycen]
	start[2] = zfwhm / 2.534
	start[3] = zfwhm / 2.534
	start[4] = xcen - float(xg1)
	start[5] = ycen - float(yg1)
	yfit = mpfit2dpeak(fitdata, aa, estimates=start, perror=perror, $
	     weights=fitalpha, /tilt)
        fxc = (aa[4]+float(xg1))/zoom + float(x1)
	fyc = (aa[5]+float(yg1))/zoom + float(y1)
	openw, jlun, 'centroid.jnk', /get_lun, /append, width=140
	nam = strmid(names[i], 11, 12) + strmid(names[i], 34, 3)
	str =  string(i, '$(i4)') + ' ' + nam + string(fxc, '$(f10.3)') + $
	  string(fyc,'$(f10.3)') + string(start[1],'$(f10.3)')
        printf, jlun, str
	close, jlun
	free_lun, jlun
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
        if info.dospitzer eq 1 then begin
          f2name = (*m).name
	  ua_decompose, f2name, disk2, path2, name2, extn2, version2
	  tfname = name2 + '_psf'
	  printf, tlun, string(fxc,'$(f12.5)'), string(fyc,'$(f12.5)'), $
	     tfname
        endif
      endif
    endif
    m = 0
    tiim = 0
    alph = 0
    fitdata = 0
    tmpalpha = 0
    fitalpha = 0
  endfor
  close, lun
  free_lun, lun
  if info.dospitzer eq 1 then begin
    close, tlun
    free_lun, tlun
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo

end

