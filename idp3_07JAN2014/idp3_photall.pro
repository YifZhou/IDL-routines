Pro idp3_PhotAll, event, feps

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=pinfo
  Widget_Control, pinfo.info.idp3Window, Get_UValue=cinfo

  c = size(*cinfo.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Not enough images loaded
    str = 'PhotStack: No images loaded'
    idp3_updatetxt, cinfo, str
    return
  endif

  non = 0
  numimages = n_elements(*cinfo.images)
  for i = 0, numimages-1 do begin
    if (*(*cinfo.images)[i]).vis eq 1 then non = non + 1
  endfor
  if non le 1 then begin
    str = 'PhotStack: Not enough images ON'
    idp3_updatetxt, cinfo, str
    return
  endif

  moveim = cinfo.moveimage
  ref = (*cinfo.images)[cinfo.moveimage]
  if (*ref).vis eq 0 then begin
    str = 'PhotStack: Reference Image not ON'
    idp3_updatetxt, cinfo, str
    return
  endif
  blnk10 = '          '
  ref_lccx = (*ref).lccx
  ref_lccy = (*ref).lccy
  refhdr = [*(*ref).phead, *(*ref).ihead]
  cntrs = cinfo.phot.all_cntrs
  case cntrs of
  0: begin  ; reference centroid is center
    xcen = ref_lccx
    ycen = ref_lccy
    idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=ref
    idp3_conra, nra/15.0, racen
    idp3_condec, ndec, deccen
    Widget_Control, pinfo.racenField, Set_Value = racen
    Widget_Control, pinfo.deccenField, Set_Value = deccen
    Widget_Control, pinfo.xcenField, Set_Value=string(xcen,'$(f9.4)')
    Widget_Control, pinfo.ycenField, Set_Value=string(ycen,'$(f9.4)')
    cinfo.phot.xcenter = xcen
    cinfo.phot.ycenter = ycen
    cinfo.phot.photra = nra
    cinfo.phot.photdec = ndec
    end
  1: begin  ; individual centroid is center
    xcen = ref_lccx
    ycen = ref_lccy
    idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=ref
    idp3_conra, nra/15.0, racen
    idp3_condec, ndec, deccen
    Widget_Control, pinfo.racenField, Set_Value = racen
    Widget_Control, pinfo.deccenField, Set_Value = deccen
    Widget_Control, pinfo.xcenField, Set_Value=string(xcen,'$(f9.4)')
    Widget_Control, pinfo.ycenField, Set_Value=string(ycen,'$(f9.4)')
    cinfo.phot.xcenter = xcen
    cinfo.phot.ycenter = ycen
    cinfo.phot.photra = nra
    cinfo.phot.photdec = ndec
    end
  2: begin  ; center derived from ra/dec in widget
    Widget_Control, pinfo.racenField, Get_Value = racen
    Widget_Control, pinfo.deccenField, Get_Value = deccen
    racen = racen[0]
    deccen = deccen[0]
    if strlen(racen) gt 2 and strlen(deccen) gt 2 then begin
      str = racen + '  ' + deccen
      get_coords, pos, 2, instring=str
      ra = pos[0] * 15.0
      dec = pos[1]
      idp3_getcoords, 1, xcen, ycen, ra, dec, imstr=ref
      Widget_Control, pinfo.xcenField, Set_Value=string(xcen,'$(f9.4)')
      Widget_Control, pinfo.ycenField, Set_Value=string(ycen,'$(f9.4)')
      cinfo.phot.xcenter = xcen
      cinfo.phot.ycenter = ycen
      cinfo.phot.photra = nra
      cinfo.phot.photdec = ndec
    endif else begin
      str = 'PhotStack: Error in RA or Dec'
      stat = Widget_Message(str)
      idp3_updatetxt, cinfo, str
    endelse
    end
  3: begin  ; center derived from ra/dec in header
    telescop = strlowcase(strtrim(sxpar(refhdr, 'TELESCOP'),2))
    if telescop eq 'hst' then begin
      ratarg = sxpar(refhdr, 'RA_TARG', Count=rmatches)
      dectarg = sxpar(refhdr, 'DEC_TARG', Count=dmatches)
    endif else begin
      ratarg = sxpar(refhdr, 'RA_REF', Count=rmatches)
      dectarg = sxpar(refhdr, 'DEC_REF', Count=dmatches)
    endelse
    if rmatches le 0 or dmatches le 0 then begin
      str = 'PhotStack: Target RA and/or Dec not found in header'
      stat = Widget_Message(str)
      idp3_updatetxt, cinfo, str
    endif else begin
      idp3_getcoords, 1, xcen, ycen, ratarg, dectarg, imstr=ref
      idp3_conra, ratarg/15.0, racen
      idp3_condec, dectarg, deccen
      Widget_Control, pinfo.racenField, Set_Value = racen
      Widget_Control, pinfo.deccenField, Set_Value = deccen
      Widget_Control, pinfo.xcenField, Set_Value=string(xcen,'$(f9.4)')
      Widget_Control, pinfo.ycenField, Set_Value=string(ycen,'$(f9.4)')
      cinfo.phot.xcenter = xcen
      cinfo.phot.ycenter = ycen
      cinfo.phot.photra = nra
      cinfo.phot.photdec = ndec
    endelse
    end
  4: begin   ; center is x, y position defined in widget
    Widget_Control, pinfo.xcenField, Get_Value = sxcen
    Widget_Control, pinfo.ycenField, Get_Value = sycen
    xcen = float(sxcen[0])
    ycen = float(sycen[0])
    cinfo.phot.xcenter = xcen
    cinfo.phot.ycenter = ycen
    end
  endcase

  Widget_Control, pinfo.tradiusField, Get_Value = trad
  str = 'PhotStack: target radius ' + string(trad)
  idp3_updatetxt, cinfo, str
  if trad le 0. then begin
    str = 'PhotStack: Invalid target radius: ' + string(trad)
    idp3_updatetxt, cinfo, str
    return
  endif
  if xcen lt trad or ycen lt trad then begin
    str = 'PhotStack: Invalid center position: ' + $
	  string(xcen) + string(ycen)
    idp3_updatetxt, cinfo, str
    return
  endif
  
  ua_decompose, (*ref).name, pdisk, ppath, pnam, pextn, pvers
  str = 'Results for Image ' + strtrim(string(moveim),2) + ' - ' + pnam + pextn
  Widget_Control, pinfo.rlabel, Set_Value=str
  hdrlab = '                             Total Flux       Number Pixels ' $
     + '       Median Flux         RMS  '
  Widget_Control, pinfo.ulabel, Set_Value = hdrlab


  roi = *cinfo.roi
  zoom = roi.roizoom
  nang = 361
  thresh = 0.85
  th = fltarr(nang)
  for i=0, nang-1 do th(i)=float(i)*(!pi/180.)
  tmpstr = $
    '                                                                        '
  sharp = cinfo.phot.sharp

  Widget_Control, pinfo.biradiusField, Get_Value = birad
  Widget_Control, pinfo.boradiusField, Get_Value = borad
  Widget_Control, pinfo.acorrField, Get_Value = ap_corr
  Widget_Control, pinfo.bkgfField, Get_Value = bkg_fract
  Widget_Control, pinfo.mthreshField, Get_Value = med_thresh
  Widget_Control, pinfo.commentField, Get_Value = comment
  comment = strtrim(comment[0],2)
  if strlen(comment) gt 0 then strput, tmpstr, comment, 0
  cinfo.phot.comment = tmpstr

  Widget_Control, pinfo.outnameField, Get_Value = outname
  outname = strtrim(outname[0],2)
  cinfo.phot.outname = outname

  ; initialize results

  wset, roi.drawid2

  moveim = cinfo.moveimage
  ; Get current size of the draw field.
  dxs = cinfo.drawxsize
  dys = cinfo.drawysize
 
  if (*ref).vis eq 0 then begin
    str = 'PhotStack: Reference image not ON'
    idp3_updatetxt, cinfo, str
    return
  endif else begin
    str = 'PhotStack: image ' + strtrim(string(moveim),2) + ': ' + $
	  (*ref).name + ' processed'
    idp3_updatetxt, cinfo, str
    ; Figure out how big the display image must be.
    ; This depends on the size of the image and its offsets.
    maxx = ((*ref).xsiz + 2 * (*ref).pad) * (*ref).xpscl * (*ref).zoom + $
	   (*ref).xoff 
    maxy = ((*ref).ysiz + 2 * (*ref).pad) * (*ref).ypscl * (*ref).zoom + $
	   (*ref).yoff
    maxx = maxx + cinfo.sxoff
    maxy = maxy + cinfo.syoff
    if maxx lt dxs then maxx = dxs
    if maxy lt dys then maxy = dys
    ; Start from scratch.
    dispim = fltarr(maxx,maxy)   ; An empty display array
    alphaim = fltarr(maxx,maxy)

    mdst = idp3_setdata(cinfo, moveim)
    mds = mdst[*,*,0]
    alpha = mdst[*,*,1]
    mdst = 0

    ; Determine where this image should be in the display.
    ; check offsets, check boundaries, etc.
    xoff = (*ref).xoff + cinfo.sxoff
    yoff = (*ref).yoff + cinfo.syoff
    xsiz = ((*ref).xsiz + 2 * (*ref).pad) * (*ref).zoom * (*ref).xpscl 
    ysiz = ((*ref).ysiz + 2 * (*ref).pad) * (*ref).zoom * (*ref).ypscl
    idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax,dymin,dymax, $
     		       gxmin,gxmax,gymin,gymax,err
    dispim[gxmin:gxmax,gymin:gymax] = $
          dispim[gxmin:gxmax,gymin:gymax] + mds[dxmin:dxmax,dymin:dymax]
    alphaim[gxmin:gxmax,gymin:gymax] = $
          alphaim[gxmin:gxmax,gymin:gymax] + alpha[dxmin:dxmax,dymin:dymax]

    mds = 0
    alpha = 0
    x1 = roi.roixorig > gxmin
    x2 = roi.roixend < gxmax
    y1 = roi.roiyorig > gymin
    y2 = roi.roiyend < gymax
    xsize = (x2 - x1 + 1) * zoom
    ysize = (y2 - y1 + 1) * zoom
    ztype = cinfo.roiioz
    if zoom gt 1 then begin
      dataimage = idp3_congrid(dispim[x1:x2,y1:y2], xsize, ysize, zoom, $
		 ztype, cinfo.pixorg)
      if cinfo.zoomflux eq 1 then dataimage[*,*] = dataimage[*,*]/zoom^2
      alpha = congrid(alphaim[x1:x2,y1:y2], xsize, ysize)
    endif else begin
      dataimage = dispim[x1:x2,y1:y2]
      alpha = alphaim[x1:x2,y1:y2]
    endelse
    dispim = 0
    alphaim = 0
    tmp = bytarr(xsize, ysize)
    tmp[*,*] = 1
    abad = where(alpha eq 0, acnt)
    if acnt gt 0 then tmp[abad] = 0
    abad = 0
    alpha = 0

    Widget_Control, pinfo.info.idp3Window, Set_UValue = cinfo
    coords = [x1, x2, y1, y2]
    preset = 0
    stat = idp3_phcalc(pinfo, dataimage, tmp, coords, preset)
    Widget_Control, pinfo.info.idp3Window, Get_UValue = cinfo
    if stat ge 0 then begin
      if strlen(outname) gt 0 then begin
        ua_decompose, (*ref).orgname, dsk2, pth2, nam2, ex2, ver2
        nam = nam2 + ex2
        exts = (*ref).extver
        if strlen(nam) gt 22 then lim=38 else lim=22
        name = idp3_getname(nam, lim)
        str = 'PhotStack: ' + (*ref).name + string(exts)
        idp3_updatetxt, cinfo, str
        idp3_prntphot, cinfo, name, exts, 1
        if feps eq 1 then begin
	  allon = 0
	  dohdr = 1
	  moveim = cinfo.moveimage
	  comstr = '                    '
	  Widget_Control, pinfo.commentField, Get_Value = comment
	  comment = strtrim(comment[0],2)
	  if strlen(comment) gt 0 then begin
	    strput, comstr, comment, 0
	    cinfo.phot.comment = tmpstr
          endif
	  title = 'Enter Quality Flags'
	  valstr = idp3_getvals(title,cinfo.phot.qualflag,groupleader=event.top,$
	    cancel=cancel, ws=25, xp=400, yp=400)
          if cancel eq 1 then begin
	    str = 'PhotStack: Save aborted'
	    idp3_updatetxt, cinfo, str
            return
          endif
	  cinfo.phot.qualflag = strtrim(valstr,2)
	  Widget_Control, pinfo.info.idp3Window, Set_UValue=cinfo
	  idp3_prntfeps, cinfo, nam, moveim, exts, dohdr, allon
        endif
      endif 
    endif
    dataimage = 0
    tmp = 0
  endelse

  ;  Process rest of images that are on

  for mm = 0, numimages-1 do begin
    m = (*cinfo.images)[mm]
    if mm ne moveim and (*m).vis eq 1 then begin
      str = 'PhotStack: image ' + strtrim(string(mm),2) + ': ' + $
	    (*m).name + ' processed'
      idp3_updatetxt, cinfo, str
      ; Figure out how big the display image must be.
      ; This depends on the size of the image and its offsets.
      ua_decompose, (*m).name, pdisk, ppath, pnam, pextn, pvers
      str = 'Results for Image ' + strtrim(string(mm),2) + ' - ' + pnam + pextn
      Widget_Control, pinfo.rlabel, Set_Value=str
      maxx = ((*m).xsiz + 2 * (*m).pad) * (*m).xpscl * (*m).zoom + (*m).xoff
      maxy = ((*m).ysiz + 2 * (*m).pad) * (*m).ypscl * (*m).zoom + (*m).yoff
      maxx = maxx + cinfo.sxoff
      maxy = maxy + cinfo.syoff
      if maxx lt dxs then maxx = dxs
      if maxy lt dys then maxy = dys
      ; Start from scratch
      dispim = fltarr(maxx,maxy)   ; An empty display array
      alphaim = fltarr(maxx,maxy)  ; An empty alpha array
      mdst = idp3_setdata(cinfo, mm)
      mds = mdst[*,*,0]
      alpha = mdst[*,*,1]
      mdst = 0
      ; Determine where this image should be in the display.
      ; check offsets, check boundaries, etc.
      xoff = (*m).xoff + cinfo.sxoff
      yoff = (*m).yoff + cinfo.syoff
      xsiz = ((*m).xsiz + 2 * (*m).pad) * (*m).zoom * (*m).xpscl
      ysiz = ((*m).ysiz + 2 * (*m).pad) * (*m).zoom * (*m).ypscl
      idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax, $
	   dymin,dymax,gxmin,gxmax,gymin,gymax,err
      dispim[gxmin:gxmax,gymin:gymax] = $
	   dispim[gxmin:gxmax,gymin:gymax] + mds[dxmin:dxmax,dymin:dymax]
      alphaim[gxmin:gxmax,gymin:gymax] = $
	   alphaim[gxmin:gxmax,gymin:gymax] + alpha[dxmin:dxmax,dymin:dymax]
      mds = 0 
      alpha = 0
      ; Get the ROI array, zoom it appropriately.
      x1 = roi.roixorig > gxmin
      y1 = roi.roiyorig > gymin
      x2 = roi.roixend < gxmax
      y2 = roi.roiyend < gymax
      xsize = (x2 - x1 + 1) * zoom
      ysize = (y2 - y1 + 1) * zoom
      if zoom gt 1 then begin
        dataimage = idp3_congrid(dispim[x1:x2,y1:y2], xsize, ysize, zoom, $
		 ztype, cinfo.pixorg)
        if cinfo.zoomflux eq 1 then dataimage[*,*] = dataimage[*,*]/zoom^2
        alpha = congrid(alphaim[x1:x2,y1:y2], xsize, ysize)
      endif else begin
        dataimage = dispim[x1:x2,y1:y2]
        alpha = alphaim[x1:x2,y1:y2]
      endelse
      dispim = 0
      alphaim = 0
      tmp = bytarr(xsize, ysize)
      tmp[*,*] = 1
      abad = where(alpha eq 0, acnt)
      if acnt gt 0 then tmp[abad] = 0

      case cntrs of
      0: begin   ; reference centroid is center
	xcen = ref_lccx
	ycen = ref_lccy
	idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=m
	idp3_conra, nra/15.0, racen
	idp3_condec, ndec, deccen
	Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
	Widget_Control, pinfo.racenField, Set_Value = racen
	Widget_Control, pinfo.deccenField, Set_Value = deccen
        cinfo.phot.xcenter = xcen
        cinfo.phot.ycenter = ycen
        cinfo.phot.photra = nra
        cinfo.phot.photdec = ndec
	cenflg = 1
	end
      1: begin   ; individual centroid is center
	xcen = (*m).lccx
	ycen = (*m).lccy
	idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=m
	idp3_conra, nra/15.0, racen
	idp3_condec, ndec, deccen
	Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
	Widget_Control, pinfo.ycenField, Set_Value = ycen
	Widget_Control, pinfo.racenField, Set_Value = racen
	Widget_Control, pinfo.deccenField, Set_Value = deccen
        cinfo.phot.xcenter = xcen
        cinfo.phot.ycenter = ycen
        cinfo.phot.photra = nra
        cinfo.phot.photdec = ndec
	cenflg = 1
	end
      2: begin   ; center derived from ra/dec in widget
	Widget_Control, pinfo.racenField, Get_Value = racen
	Widget_Control, pinfo.deccenField, Get_Value = deccen
	racen = racen[0]
	deccen = deccen[0]
	if strlen(racen) gt 2 and strlen(deccen) gt 2 then begin
	  str = racen + '  ' + deccen
	  get_coords, pos, 2, instring=str
	  ra = pos[0] * 15.0
	  dec = pos[1]
	  idp3_getcoords, 1, xcen, ycen, ra, dec, imstr=m
	  Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	  Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
          cinfo.phot.xcenter = xcen
          cinfo.phot.ycenter = ycen
          cinfo.phot.photra = nra
          cinfo.phot.photdec = ndec
	  cenflg = 1
        endif else begin
	  str = 'PhotStack: Error in RA or Dec'
	  idp3_updatetxt, cinfo, str
	  cenflg = 0
        endelse
	end
      3: begin   ; center derived from ra/dec in header
	thdr = [*(*m).phead, *(*m).ihead]
	telescop = strlowcase(strtrim(sxpar(thdr, 'TELESCOP'),2))
	if telescop eq 'hst' then begin
	  ratarg = sxpar(thdr, 'RA_TARG', Count=rmatches)
	  dectarg = sxpar(thdr, 'DEC_TARG', Count=dmatches)
        endif else begin
	  ratarg = sxpar(thdr, 'RA_REF', Count=rmatches)
	  dectarg = sxpar(thdr, 'DEC_REF', Count=dmatches)
        endelse
	if rmatches le 0 or dmatches le 0 then begin
	  str = 'PhotStack: Target RA and/or Dec not found in header'
	  idp3_updatetxt, cinfo, str
	  cenflg = 0
        endif else begin
	  idp3_getcoords, 1, xcen, ycen, ratarg, dectarg, imstr=m
	  idp3_conra, ratarg/15.0, racen
	  idp3_condec, dectarg, deccen
	  Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	  Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
	  Widget_Control, pinfo.racenField, Set_Value = racen
	  Widget_Control, pinfo.deccenField, Set_Value = deccen
          cinfo.phot.xcenter = xcen
          cinfo.phot.ycenter = ycen
          cinfo.phot.photra = nra
          cinfo.phot.photdec = ndec
	  cenflg = 1
        endelse
	end
      4: begin   ; center is x, y position defined in widget
        Widget_Control, pinfo.xcenField, Get_Value = sxcen
        Widget_Control, pinfo.ycenField, Get_Value = sycen
	xcen = float(sxcen[0])
	ycen = float(sycen[0])
        cinfo.phot.xcenter = xcen
        cinfo.phot.ycenter = ycen
	cenflg = 1
        end
      endcase
      if cenflg eq 1 then begin
	Widget_Control, pinfo.info.idp3Window, Set_UValue = cinfo
	coords = [x1, x2, y1, y2]
        preset = 1
	stat = idp3_phcalc(pinfo, dataimage, tmp, coords, preset)
	Widget_Control, pinfo.info.idp3Window, Get_UValue = cinfo
	if stat ge 0 then begin
          if strlen(outname) gt 0 then begin
            ua_decompose, (*m).orgname, dsk2, pth2, nam2, ex2, ver2
            nam = nam2 + ex2
	    exts = (*m).extver
            if strlen(nam) gt 22 then lim=38 else lim=22
            name = idp3_getname(nam, lim)
            idp3_prntphot, cinfo, name, exts, 0
            if feps eq 1 then begin
	      allon = 0
	      dohdr = 0 
	      idp3_prntfeps, cinfo, nam, mm, exts, dohdr, allon
            endif
          endif
        endif else begin
	  str = 'PhotStack: No target or background set'
	  idp3_updatetxt, cinfo, str
        endelse
      endif else begin
        str = 'PhotStack: File: ' + (*m).name + ': Error in position'
        idp3_updatetxt, cinfo, str
      endelse
    endif else begin
      if mm ne moveim then begin
	str = 'Image: ' + strtrim(string(mm),2) + ' OFF'
	idp3_updatetxt, cinfo, str
      endif
    endelse
    dataimage = 0
    tmp = 0
  endfor

  Widget_Control, pinfo.info.idp3Window, Set_UValue=cinfo
  Widget_Control, event.top, Set_UValue=pinfo

 end
