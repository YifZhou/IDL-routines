Pro Idp3_Phot_Done, event

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=pinfo
  Widget_Control, pinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.phwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.phwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, pinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end

pro Idp3_Phot_Help, event
  tmp = idp3_findfile('idp3_phot.hlp')
  xdisplayfile, tmp
end

pro Idp3_Phot_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=pinfo
  Widget_Control, pinfo.info.idp3Window, Get_UValue=cinfo
  pinfo.info = cinfo
  Widget_Control, event.top, Set_UValue=pinfo

  roi = *(cinfo.roi)
  x1 = roi.roixorig
  x2 = roi.roixend
  y1 = roi.roiyorig
  y2 = roi.roiyend
  zoom = roi.roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = cinfo.roiioz
  zm = ['Bi-Cub Sinc','Bi-Lin','Pix-Rep', 'Bi-Cub Spline']
  sztype = zm[ztype]
  zf = ['NOT Conserved', 'Conserved']
  zfl = zf[cinfo.zoomflux]
  zstr = '   Zoom: ' +  strtrim(string(zoom),2) + '/' + sztype + $
    '/' + zfl
  Widget_Control, pinfo.zlabel, Set_Value=zstr
  tmpstr = $
    '                                                                        '
  wset, roi.drawid2

  case event.id of
    pinfo.sButtons: begin
      ; toggle photometry shape.
      shape = event.value
      cinfo.phot.shape = shape
      end

    pinfo.cButtons: begin
      ; toggle center used.
      rcntr = event.value
      cinfo.phot.all_cntrs = rcntr
      end

    pinfo.tradiusField: begin
      ; check and save target radius value
      Widget_Control, pinfo.tradiusField, Get_Value = trad
      if trad gt 0.0 then begin
        Widget_Control, pinfo.xcenField, Get_Value = sxcen
        Widget_Control, pinfo.ycenField, Get_Value = sycen
	xcen = float(sxcen[0])
	ycen = float(sycen[0])
        tledge = xcen - trad
        tredge = xcen + trad
        ttop = ycen + trad
        tbottom = ycen - trad
        if tledge lt x1 or tredge gt x2 or tbottom lt y1 or ttop gt y2 $
	  then begin
	  stat = Widget_Message('Target region falls outside the ROI!')
	  return
        endif else begin
	  cinfo.phot.tradius = trad
	  if cinfo.cent.fwhm gt 0.0 then begin
	    str = 'Phot: FWHM: ' + string(cinfo.cent.fwhm) + $
	      '  Target Radius: ' + string(trad) + $
	       '  radius/fwhm ' + string(trad/cinfo.cent.fwhm)
            idp3_updatetxt, cinfo, str
          endif
        endelse
      endif
      end

    pinfo.mradButton: begin
      Widget_Control, pinfo.xcenField, Get_Value = sxcen
      Widget_Control, pinfo.ycenField, Get_Value = sycen
      xcen = float(sxcen[0])
      ycen = float(sycen[0])
      xsl = CEIL(xcen) - x1 
      xsr = x2 - CEIL(xcen)
      yst = y2 - CEIL(ycen)
      ysb = CEIL(ycen) - y1
      mrad = min([xsl, xsr, ysb, yst])
      Widget_Control, pinfo.boradiusField, Set_Value = mrad
      end

    pinfo.xcenField: begin
      Widget_Control, pinfo.xcenField, Get_Value = sxcen
      xcen = float(sxcen[0])
      if xcen le x1 or xcen ge x2 then begin
	stat = Widget_Message('X Center falls outside the ROI!')
	return
      endif
      end

    pinfo.ycenField: begin
      Widget_Control, pinfo.ycenField, Get_Value = sycen
      ycen = float(sycen[0])
      if ycen le y1 or ycen ge y2 then begin
	stat = Widget_Message('Y Center falls outside the ROI!')
	return
      endif
      end

    pinfo.acorrField: begin
      Widget_Control, pinfo.acorrField, Get_Value = ap_corr
      cinfo.phot.ap_corr = ap_corr
      end

    pinfo.bkgfField: begin
      Widget_Control, pinfo.bkgfField, Get_Value = bkg_fract
      cinfo.phot.bkg_fract = bkg_fract
      end

    pinfo.mthreshField: begin
      Widget_Control, pinfo.mthreshField, Get_Value = med_thresh
      cinfo.phot.med_thresh = med_thresh
      end

    pinfo.getrefbutton: begin
      numimages = n_elements(*cinfo.images)
      xcen = 0.0
      ycen = 0.0
      moveim = cinfo.moveimage
      m = (*cinfo.images)[moveim]
      if (*m).vis eq 1 and xcen le 0.0 then begin
        xcen = (*m).lccx
        ycen = (*m).lccy
      endif
      Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
      Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
      if xcen gt 0. and ycen gt 0. then begin
	idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=m
	idp3_conra, nra/15.0, racen
	idp3_condec, ndec, deccen
        Widget_Control, pinfo.racenField, Set_Value = racen
	Widget_Control, pinfo.deccenField, Set_Value = deccen
      endif else begin
	Widget_Control, pinfo.racenField, Set_Value = ' '
	Widget_Control, pinfo.deccenField, Set_Value = ' '
      endelse
      end

    pinfo.getrabutton: begin
      ; get target ra and dec - convert to photometry x,y center
      moveim = cinfo.moveimage
      ims = (*cinfo.images)[moveim]
      thdr = [*(*ims).phead, *(*ims).ihead]
      telescop = strlowcase(strtrim(sxpar(thdr, 'TELESCOP'),2))
      if telescop eq 'hst' then begin
	ratarg = sxpar(thdr, 'RA_TARG', Count=rmatches)
	dectarg = sxpar(thdr, 'DEC_TARG', Count=dmatches)
      endif else begin
	ratarg = sxpar(thdr, 'RA_REF', Count=rmatches)
	dectarg = sxpar(thdr, 'DEC_REF', Count=dmatches)
      endelse
      if rmatches le 0 or dmatches le 0 then begin
	str = 'Target RA and/or Dec not found in header'
	stat = Widget_Message(str)
	idp3_updatetxt, cinfo, str
	return
      endif else begin
	idp3_getcoords, 1, xcen, ycen, ratarg, dectarg, imstr=ims
	Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
	idp3_conra, ratarg/15.0, racen
	idp3_condec, dectarg, deccen
	Widget_Control, pinfo.racenField, Set_Value = racen
	Widget_Control, pinfo.deccenField, Set_Value = deccen
      endelse
    end

    pinfo.loadButton: begin
      Widget_Control, pinfo.commentField, Get_Value = comment
      Widget_Control, pinfo.outnameField, Get_Value = outname
      Widget_Control, pinfo.tradiusField, Get_Value = tradius
      Widget_Control, pinfo.biradiusField, Get_Value = biradius
      Widget_Control, pinfo.boradiusField, Get_Value = boradius
      Widget_Control, pinfo.acorrField, Get_Value = ap_corr
      Widget_Control, pinfo.bkgfField, Get_Value = bkg_fract
      Widget_Control, pinfo.mthreshField, Get_Value = med_thresh
      Widget_Control, pinfo.xcenField, Get_Value = sxcen
      Widget_Control, pinfo.ycenField, Get_Value = sycen
      xcen = float(sxcen[0])
      ycen = float(sycen[0])
      Widget_Control, pinfo.racenField, Get_Value = racen
      Widget_Control, pinfo.deccenField, Get_Value = deccen
      sharp = cinfo.phot.sharp
      cntr_def = cinfo.phot.all_cntrs
      inpath=cinfo.imagepath
      apfile = Dialog_Pickfile(/Read, Get_Path=outpath, Path=inpath, $
	title='Select Aperture Definition File', /Must_Exist)
      cinfo.imagepath = outpath
      apfile = strtrim(apfile[0],2)
      if strlen(apfile) gt 1 then begin
	str = 'Phot: loading ' + apfile
	idp3_updatetxt, cinfo, str
        openr, lun, apfile, /get_lun
        lineofText = ' '
        while not eof(lun) do begin
	  readf, lun, lineofText
	  if strmid(lineofText, 0, 1) ne ';' and strlen(lineofText) gt 0 $
	    then begin
	    strs = strtrim(strsplit(lineofText, '=', /extract), 2)
	    if n_elements(strs) eq 2 then begin 
	      pstr = 'Phot: ' + lineofText
	      idp3_updatetxt, cinfo, pstr
	      strs[0] = strlowcase(strs[0])
	      semi = strpos(strs[1], ';')
	      if semi gt 0 then strs[1] = strtrim(strmid(strs[1],0,semi-1),2)
	      case strs[0] of
		'xcen'       : xcen = float(strs[1])
		'ycen'       : ycen = float(strs[1])
		'racen'      : racen = idp3_extstr(strs[1])
		'deccen'     : deccen = idp3_extstr(strs[1])
		'tradius'    : tradius = float(strs[1])
		'biradius'   : biradius = float(strs[1])
		'boradius'   : boradius = float(strs[1])
		'sharp'      : sharp = fix(strs[1])
		'ap_corr'    : ap_corr = float(strs[1])
		'bkg_fract'  : bkg_fract = float(strs[1])
		'med_thresh' : med_thresh = float(strs[1])
		'cntr_def'   : cntr_def = fix(strs[1])
	        'comment'    : comment = idp3_extstr(strs[1])
		'outname'    : outname = idp3_extstr(strs[1])
                else: begin
		  vstr = 'Variable: ' + strs[0] + ' not found'
		  idp3_updatetxt, cinfo, vstr
                end
              endcase
            endif
          endif
        endwhile
	close, lun
	free_lun, lun
	if xcen ne 0. and ycen ne 0. then begin
	  moveim = cinfo.moveimage
	  ims = cinfo.images
	  imptr = (*ims)[moveim]
	  idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=imptr
	  idp3_conra, nra/15.0, racen
	  idp3_condec, ndec, deccen
        endif else begin
	  if n_elements(racen) gt 0 and n_elements(deccen) gt 0 then begin
	    if strlen(racen) gt 2 and strlen(deccen gt 2) then begin
	      str = racen[0] + '  ' + deccen[0]
	      get_coords, pos, 2, instring=str
	      ra = pos[0] * 15.0
	      dec = pos[1]
	      moveim = cinfo.moveimage
	      ims = cinfo.images
	      imptr = (*ims)[moveim]
	      idp3_getcoords, 1, xcen, ycen, ra, dec, imstr=imptr
            endif 
          endif
        endelse
        Widget_Control, pinfo.commentField, Set_Value = comment
        Widget_Control, pinfo.outnameField, Set_Value = outname
        Widget_Control, pinfo.tradiusField, Set_Value = tradius
        Widget_Control, pinfo.biradiusField, Set_Value = biradius
        Widget_Control, pinfo.boradiusField, Set_Value = boradius
        Widget_Control, pinfo.acorrField, Set_Value = ap_corr
        Widget_Control, pinfo.bkgfField, Set_Value = bkg_fract
        Widget_Control, pinfo.mthreshField, Set_Value = med_thresh
	Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
	Widget_Control, pinfo.racenField, Set_Value = racen
	Widget_Control, pinfo.deccenField, Set_Value = deccen
        Widget_Control, pinfo.shpButton, Set_Value = sharp
        Widget_Control, pinfo.cButtons, Set_Value = cntr_def
        cinfo.phot.sharp = sharp
	cinfo.phot.all_cntrs = cntr_def
	cinfo.phot.outname = outname
	cinfo.phot.comment = comment
	cinfo.phot.tradius = tradius
	cinfo.phot.biradius = biradius
	cinfo.phot.boradius = boradius
	cinfo.phot.ap_corr = ap_corr
	cinfo.phot.bkg_fract = bkg_fract
	cinfo.phot.med_thresh = med_thresh
	cinfo.phot.xcenter = xcen
	cinfo.phot.ycenter = ycen
	cinfo.phot.photra = racen
	cinfo.phot.photdec = deccen
      endif else begin
	str = 'Phot: No aperture file given'
	idp3_updatetxt, cinfo, str
      endelse
    end

    pinfo.markappButton: begin
      ; get centroid x,y center, target radius and draw in roi
      Widget_Control, pinfo.xcenField, Get_Value = sxcen
      Widget_Control, pinfo.ycenField, Get_Value = sycen
      xcen = float(sxcen[0])
      ycen = float(sycen)
      Widget_Control, pinfo.tradiusField, Get_Value = trad
      Widget_Control, pinfo.biradiusField, Get_Value = birad
      Widget_Control, pinfo.boradiusField, Get_Value = borad
      if xcen gt x1 and xcen lt x2 and ycen gt y1 and ycen lt y2 $
	then begin
        ztr = trad * zoom
	zbir = birad * zoom
	zbor = borad * zoom
	zxcen = (xcen - x1) * zoom
        zycen = (ycen - y1) * zoom
	zxplot = (xcen - roi.roixorig) * zoom
	zyplot = (ycen - roi.roiyorig) * zoom
	nang = 361
	th = fltarr(nang)
	for i=0, nang-1 do th(i)=float(i)*(!pi/180.)
	if cinfo.phot.shape eq 0 then begin
          plots, ztr*cos(th)+zxplot, ztr*sin(th)+zyplot, color=vt, /device
          plots, zbir*cos(th)+zxplot, zbir*sin(th)+zyplot, color=vbi, /device
          plots, zbor*cos(th)+zxplot, zbor*sin(th)+zyplot, color=vbo, /device
        endif else begin
	  ztledge = zxplot - ztr
	  ztredge = zxplot+ ztr
	  ztbottom = zyplot - ztr
	  zttop = zyplot + ztr
	  plots, ztledge, ztbottom, color=vt, /device
	  plots, ztredge, ztbottom, color=vt, /device, /continue
	  plots, ztredge, zttop, color=vt, /device, /continue
	  plots, ztledge, zttop, color=vt, /device, /continue
	  plots, ztledge, ztbottom, color=vt, /device, /continue
	  zboledge = zxplot - zbor
	  zboredge = zxplot + zbor
	  zbotop = zyplot + zbor
	  zbobottom = zyplot - zbor
	  zbiledge = zxplot - zbir
	  zbiredge = zxplot + zbir
	  zbibottom = zyplot - zbir
	  zbitop = zyplot + zbir
	  plots, zbiledge, zbibottom, color=vbi, /device
	  plots, zbiredge, zbibottom, color=vbi, /device, /continue
	  plots, zbiredge, zbitop, color=vbi, /device, /continue
	  plots, zbiledge, zbitop, color=vbi, /device, /continue
	  plots, zbiledge, zbibottom, color=vbi, /device, /continue
	  plots, zboledge, zbobottom, color=vbo, /device
	  plots, zboredge, zbobottom, color=vbo, /device, /continue
	  plots, zboredge, zbotop, color=vbo, /device, /continue
	  plots, zboledge, zbotop, color=vbo, /device, /continue
	  plots, zboledge, zbobottom, color=vbo, /device, /continue
        endelse
      endif else begin
	str = 'Phot: Photometry center outside of ROI'
	stat = Widget_Message(str)
	idp3_updatetxt, cinfo, str
      endelse
   end

    pinfo.pstackButton: begin
      ; standard photometry on the stack
      idp3_photall, event, 0
      Widget_Control, pinfo.info.idp3Window, Get_UValue=cinfo
    end

    pinfo.fstackButton: begin
      ; feps photometry on the stack
      idp3_photall, event, 1
      Widget_Control, pinfo.info.idp3Window, Get_UValue=cinfo
    end

    pinfo.fepsdatButton: begin
      ; get and check feps table
      inpath = cinfo.imagepath
      get_new = 1
      stat = idp3_rdfeps(inpath, outpath, filename, get_new)
      if stat eq 0 then begin
	cinfo.imagepath = outpath
	cinfo.phot.fepsstat = 0
	cinfo.phot.fepsfile = filename
	str = 'Phot: feps file: ' + filename
	idp3_updatetxt, cinfo, str
      endif
      end

    pinfo.biradiusField: begin
      ; check and save background inner radius value
      Widget_Control, pinfo.biradiusField, Get_Value = birad
      if birad gt 0.0 then begin
        Widget_Control, pinfo.xcenField, Get_Value = sxcen
        Widget_Control, pinfo.ycenField, Get_Value = sycen
	xcen = float(sxcen[0])
	ycen = float(sycen[0])
        biledge = xcen - birad
        biredge = xcen + birad
        bitop = ycen + birad
        bibottom = ycen - birad
        if biledge lt x1 or biredge gt x2 or bibottom lt y1 or bitop gt y2 $
	  then begin
	  stat=Widget_Message('Background inner region falls outside the ROI!')
	  return
        endif else begin
	  cinfo.phot.biradius = birad
        endelse
      endif
      end

    pinfo.boradiusField: begin
      ; check and save background outer radius value
      Widget_Control, pinfo.boradiusField, Get_Value = borad
      if borad gt 0.0 then begin
        Widget_Control, pinfo.xcenField, Get_Value = sxcen
        Widget_Control, pinfo.ycenField, Get_Value = sycen
	xcen = float(sxcen[0])
	ycen = float(sycen[0])
        boledge = xcen - borad
        boredge = xcen + borad
        botop = ycen + borad
        bobottom = ycen - borad
        if boledge lt x1 or boredge gt x2 or bobottom lt y1 or botop gt y2 $
	  then begin
	  stat=Widget_Message('Background outer region falls outside the ROI!')
	  return
        endif else begin
	  cinfo.phot.boradius = borad
        endelse
      endif
      end

    pinfo.outnameField: begin
      Widget_Control, pinfo.outnameField, Get_Value = outname
      str = 'Phot: ' +  outname + string(n_elements(outname))
      idp3_updatetxt, cinfo, str
      outname = outname[0]
      if strlen(outname) gt 0 then cinfo.phot.outname = outname
      end

    pinfo.shpButton: begin
      ; toggle sharpness calculation.
      sharp = event.value
      cinfo.phot.sharp = sharp
      end

    pinfo.commentField: begin
      Widget_Control, pinfo.commentField, Get_Value = comment
      comment = strtrim(comment[0],2)
      if strlen(comment) gt 0 then begin
	strput, tmpstr, comment, 0
	cinfo.phot.comment = tmpstr
      endif
      end

    pinfo.pgridButton: begin

      moveim = cinfo.moveimage
      ims = cinfo.images
      ref = (*ims)[moveim]
      words = ['RA', 'DEC', 'XC', 'YC', 'TR', 'BIR', 'BOR']
      nwords = n_elements(words)
      Widget_Control, pinfo.tradiusField, Get_Value = itrad
      Widget_Control, pinfo.biradiusField, Get_Value = ibirad
      Widget_Control, pinfo.boradiusField, Get_Value = iborad
      Widget_Control, pinfo.outnameField, Get_Value = outname
      outname = outname[0]
      if strlen(outname) gt 0 then cinfo.phot.outname = outname
      Widget_Control, pinfo.commentField, Get_Value = comment
      comment = strtrim(comment[0],2)
      if strlen(comment) gt 0 then strput, tmpstr, comment, 0
      ua_decompose, (*ref).name, dsk1, pth1, nam1, ex1, ver1
      ua_decompose, (*ref).orgname, dsk2, pth2, nam2, ex2, ver2
      l1 = strlen(nam1)
      l2 = strlen(nam2)
      if l1 gt l2 then exts = fix(strmid(nam1, l2+1)) else exts=0
      nam = nam2 + ex2
      if strlen(nam) gt 22 then lim=38 else lim=22
      name = idp3_getname(nam, lim)
      cinfo.phot.method = 'aperture'
      ua_decompose, (*ref).name, pdisk, ppath, pnam, pextn, pvers
      str = 'Results for Image ' + strtrim(string(moveim),2) + ' - ' $
	    + pnam + pextn
      Widget_Control, pinfo.rlabel, Set_Value = str
      im = *(cinfo.dispim)
      imsz = size(im)
      dataimage = idp3_congrid(im[x1:x2,y1:y2], xsize, ysize, zoom, ztype, $
	      cinfo.pixorg)
      if cinfo.zoomflux eq 1 then dataimage[*,*] = dataimage[*,*]/zoom^2
      aim = *(cinfo.alphaim)
      alpha = congrid(aim[x1:x2,y1:y2], xsize, ysize)
      aim = 0
      abad = where(alpha eq 0, acnt)
      tmp = bytarr(xsize, ysize)
      tmp[*,*] = 1
      if acnt gt 0 then tmp[abad] = 0
      im = 0
      aim = 0
      alpha = 0

      inpath=cinfo.imagepath
      apgfile = Dialog_Pickfile(/Read, Get_Path=outpath, Path=inpath, $
	 title='Select Aperture Coords File', /Must_Exist)
      cinfo.imagepath = outpath
      apgfile = strtrim(apgfile[0],2)
      if strlen(apgfile) gt 1 then begin
	openr, lun, apgfile, /get_lun
	str = ' '
	indx = 0
	while not eof(lun) do begin
	  readf, lun, str
	  if strmid(str, 0, 1) ne ';' then begin
	    if indx eq 0 then strs = str else strs = [strs, str]
	    indx = 1
          endif
        endwhile
	close, lun
	free_lun, lun
	nstrs = n_elements(strs)
	if nstrs gt 1 then begin
	  ara = strarr(nstrs)
	  ara[*] = ' '
	  adec = strarr(nstrs)
	  adec[*] = ' '
	  axcen = fltarr(nstrs)
	  axcen[*] = 0.0
	  aycen = fltarr(nstrs)
	  aycen[*] = 0.0
	  atrad = fltarr(nstrs)
	  atrad[*] = itrad
	  abirad = fltarr(nstrs)
	  abirad[*] = ibirad
	  aborad = fltarr(nstrs)
	  aborad[*] = iborad
	  for i = 0, nstrs-1 do begin
	    ttmpstr = strsplit(strs[i], /extract)
	    num = n_elements(ttmpstr)
	    for j = 0, num-1 do begin
	      for k = 0, nwords-1 do begin
		vstr = strtrim(strupcase(ttmpstr[j]),2)
	        if strpos(vstr, words[k]) ge 0 then begin
		  eqpos = strpos(vstr, '=')
		  vlen = strlen(vstr)
		  if eqpos gt 0 then begin
		    val = float(strmid(vstr, eqpos+1, vlen-eqpos))
		    case k of
		    0: ara[i] = val
		    1: adec[i] = val
		    2: axcen[i] = val
		    3: aycen[i] = val
		    4: atrad[i] = val
		    5: abirad[i] = val
		    6: aborad[i] = val
		    else: begin
		      str = 'Phot: match not found'
		      idp3_updatetxt, cinfo, str
                    end
                    endcase
                  endif
                endif
              endfor
            endfor
	  endfor  
          for i = 0, nstrs-1 do begin
	    if axcen[i] gt 0.0 and aycen[i] gt 0.0 then begin
	      if (*ref).valid_wcs eq 1 and cinfo.show_wcs gt 0 then begin
	        idp3_getcoords, 0, axcen[i], aycen[i], nra, ndec, imstr=ref
	        idp3_conra, nra/15.0, racen
	        idp3_condec, ndec, deccen
		ara[i] = racen
		adec[i] = deccen
              endif else begin
		racen = ' '
		deccen = ' '
              endelse
            endif else begin
	      if (*ref).valid_wcs eq 1 and cinfo.show_wcs gt 0 then begin
	        if strlen(ara[i]) gt 3 and strlen(adec[i]) gt 3 then begin
	          pstr = ara[i] + '  ' + adec[i]
	          get_coords, pos, 2, instring=str
	          ra = pos[0] * 15.0
	          dec = pos[1]
	          idp3_getcoords, 1, xcen, ycen, ra, dec, imstr=ref
	          axcen[i] = xcen
	          aycen[i] = ycen
                endif else begin
		  str = 'Phot: Invalid RA/Dec, must abort'
		  idp3_updatetxt, cinfo, str
		  return
                endelse
              endif else begin
		if cinfo.show_wcs gt 0 then begin
		  str = 'Phot: No WCS info, must abort'
		  idp3_updatetxt, cinfo, str
		  return
                endif
	      endelse	 
            endelse
          endfor
	  for i = 0, nstrs-1 do begin
	    xcen = axcen[i]
	    ycen = aycen[i]
	    racen = ara[i]
	    deccen = adec[i]
	    trad = atrad[i]
	    birad = abirad[i]
	    borad = aborad[i]
	    cinfo.phot.xcenter = xcen
	    cinfo.phot.ycenter = ycen
	    Widget_Control, pinfo.racenField, Set_Value = racen
	    Widget_Control, pinfo.deccenField, Set_Value = deccen
	    Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	    Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
	    Widget_Control, pinfo.tradiusField, Set_Value = trad
	    Widget_Control, pinfo.biradiusField, Set_Value = birad
	    Widget_Control, pinfo.boradiusField, Set_Value = borad
	    if xcen lt trad or ycen lt trad then begin
	      str = 'Phot: Invalid center position: ' + string(xcen) + $
		    string(ycen)
              idp3_updatetxt, cinfo, str
            endif else begin
	      Widget_Control, pinfo.info.idp3Window, Set_UValue = cinfo
	      coords = [x1, x2, y1, y2]
	      if i eq 0 or borad eq 0. or trad eq 0. then preset = 0 $
		else preset = 1
	      stat = idp3_phcalc(pinfo, dataimage, tmp, coords, preset)
	      Widget_Control, pinfo.info.idp3Window, Get_UValue = cinfo
	      if stat ge 0 then begin
                if strlen(outname) gt 0 then begin
		  title = 1 
		  ; new title with each position
                  idp3_prntphot, cinfo, name, exts, title
                endif
              endif
            endelse
          endfor
        endif
      endif
      dataimage = 0
      tmp = 0
    end

    pinfo.computeButton: begin
      bkg_flg =  0
      numimages = n_elements(*cinfo.images)
      moveim = cinfo.moveimage
      ims = cinfo.images
      Widget_Control, pinfo.tradiusField, Get_Value = trad
      Widget_Control, pinfo.xcenField, Get_Value = sxcen
      Widget_Control, pinfo.ycenField, Get_Value = sycen
      xcen = float(sxcen[0])
      ycen = float(sycen[0])
      Widget_Control, pinfo.racenField, Get_Value = racen
      Widget_Control, pinfo.deccenField, Get_Value = deccen
      imptr = (*ims)[moveim]
      if xcen le 0. and ycen le 0. then begin
	if strlen(racen) gt 2 and strlen(deccen gt 2) then begin
	  str = racen + '  ' + deccen
	  get_coords, pos, 2, instring=str
	  ra = pos[0] * 15.0
	  dec = pos[1]
	  idp3_getcoords, 1, xcen, ycen, ra, dec, imstr=imptr
          Widget_Control, pinfo.xcenField, Set_Value = string(xcen,'$(f9.4)')
	  Widget_Control, pinfo.ycenField, Set_Value = string(ycen,'$(f9.4)')
        endif 
      endif else begin
	if strlen(racen) le 2 and strlen(deccen) le 2 then begin
	  idp3_getcoords, 0, xcen, ycen, nra, ndec, imstr=imptr
	  idp3_conra, nra/15.0, racen
	  idp3_condec, ndec, deccen
	  Widget_Control, pinfo.racenField, Set_Value = racen
	  Widget_Control, pinfo.deccenField, Set_Value = deccen
	endif
      endelse
      ua_decompose, (*imptr).name, pdisk, ppath, pnam, pextn, pvers
      str = 'Results for Image ' + strtrim(string(moveim),2) + ' - ' $
	    + pnam + pextn
      Widget_Control, pinfo.rlabel, Set_Value = str
      hdrlab = '                             Total Flux       Number Pixels ' $
         + '       Median Flux         RMS  '
      Widget_Control, pinfo.ulabel, Set_Value = hdrlab
      ; special addition for limited error computation (MIPS)
      if ptr_valid((*(*ims)[moveim]).errs) then begin
	for kk = 0, numimages - 1 do begin
	  if (*(*ims)[kk]).vis eq 1 and kk ne moveim then begin
	    str = 'Phot:  Only Reference image can be ON'
	    idp3_updatetxt, cinfo, str
	    return
          endif
        endfor
	err = (*(*ims)[moveim]).errs
	errm = *err
	errors = errm[x1:x2,y1:y2]
	enotnan = finite(errors)
	ebad = where(enotnan eq 0, ebcnt)
	if ebcnt gt 0 then errors[ebad] = 0.
	if zoom gt 1. then begin
	  errors = congrid(errors, xsize, ysize)
	  if cinfo.zoomflux eq 1 then errors = errors/(zoom^2)
        endif
      endif else errors = 0
      ; end MIPS addition
      Widget_Control, pinfo.commentField, Get_Value = comment
      comment = strtrim(comment[0],2)
      if strlen(comment) gt 0 then begin
	strput, tmpstr, comment, 0
	cinfo.phot.comment = tmpstr
      endif
      im = *(cinfo.dispim)
      dataimage = idp3_congrid(im[x1:x2,y1:y2], xsize, ysize, zoom, ztype, $
	          cinfo.pixorg)
      if cinfo.zoomflux eq 1 then dataimage[*,*] = dataimage[*,*]/zoom^2
      aim = *(cinfo.alphaim)
      alpha = congrid(aim[x1:x2,y1:y2], xsize, ysize)
      aim = 0
      abad = where(alpha eq 0, acnt)
      tmp = bytarr(xsize, ysize)
      tmp[*,*] = 1
      if acnt gt 0 then tmp[abad] = 0
      Widget_Control, pinfo.info.idp3Window, Set_UValue = cinfo
      coords = [x1, x2, y1, y2]
      preset = 0
      stat = idp3_phcalc(pinfo, dataimage, tmp, coords, preset)
      Widget_Control, pinfo.info.idp3Window, Get_UValue = cinfo
      pinfo.info = cinfo
      dataimage = 0
      tmp = 0
      end

    pinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output filename')
      Widget_Control, pinfo.outnameField, set_value=Pathvalue
      end

    pinfo.saveButton: begin
      Widget_Control, pinfo.commentField, Get_Value = comment
      comment = strtrim(comment[0],2)
      if strlen(comment) gt 0 then begin
	strput, tmpstr, comment, 0
	cinfo.phot.comment = tmpstr
      endif
      Widget_Control, pinfo.outnameField, Get_Value = outname
      outname = strtrim(outname[0],2)
      if strlen(outname) gt 0 then begin
	cinfo.phot.outname = outname
	imptr = (*cinfo.images)[cinfo.moveimage]
	ua_decompose, (*imptr).name, dsk1, pth1, nam1, ex1, ver1
	ua_decompose, (*imptr).orgname, dsk2, pth2, nam2, ex2, ver2
	l1 = strlen(nam1)
	l2 = strlen(nam2)
	if l1 gt l2 then exts = fix(strmid(nam1, l2+1)) else exts=0
	nam = nam2 + ex2
	if strlen(nam) gt 25 then lim=42 else lim=25
	name = idp3_getname(nam, lim)
	idp3_prntphot, cinfo, name, exts, 1
      endif
      end
  else:
  endcase

  pinfo.info = cinfo
  Widget_Control, event.top, Set_UValue=pinfo
  Widget_Control, pinfo.info.idp3Window, Set_UValue=cinfo

end


pro Idp3_Phot, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_photometry')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  numimages = n_elements(*info.images)
  xcen = 0.0
  ycen = 0.0
  m = (*info.images)[info.moveimage]
  if (*m).vis eq 1 then begin
    xcen = (*m).lccx
    ycen = (*m).lccy
  endif

  blnk96 = '                                                ' + $
	   '                                                '
  blnk36 = '                                    '
  blnk32 = '                                '
  blnk30 = '                              '
  blnk10 = '          '
  shape = info.phot.shape
  sharp = info.phot.sharp
  refcntr = info.phot.all_cntrs
  pWindow = Widget_base(Title = 'IDP3-ROI Aperture Photometry', /Column, $
			 Group_Leader = info.idp3Window, $ ; /Grid_Layout, $
			 XOffset = info.wpos.phwp[0], $
			 YOffset = info.wpos.phwp[1])
  info.apphotBase = pWindow
  Widget_Control, tinfo.idp3Window, Set_UValue=info

  sBase = Widget_Base(pWindow,/Row)
  snames = ['Circle', 'Square']
  sButtons = cw_bgroup(sBase, snames, row=1, label_left='Shape:', $
		 uvalue='sbutton', set_value=shape, exclusive=1, /no_release)
  shpnames = ['No', 'Yes']
  shpButton = cw_bgroup(sBase, shpnames, row=1, $
	       label_left='Sharpness:', $
	       uvalue='shpbutton', set_value=sharp, exclusive=1, /no_release)
  zm = ['Bi-Cub Sinc','Bi-Lin','Pix-Rep', 'Bi-Cub Spline']
  ztype = zm[info.roiioz]
  zfact = (*info.roi).roizoom
  zf = ['NOT Conserved', 'Conserved']
  zfl = zf[info.zoomflux]
  zstr = 'Zoom: ' +  strtrim(string(zfact),2) + '/' + ztype + $
	 '/' + zfl + ' '
  zlabel = Widget_Label(sBase, Value=zstr, /Align_Center)
  helpButton=Widget_Button(sBase,Value='Help',Event_Pro='idp3_phot_Help', $
	  /Align_Center)
  doneButton=Widget_Button(sBase,Value='Done',Event_Pro='idp3_phot_Done', $
	  /Align_Center)

  tBase = Widget_Base(pWindow, /Row)
  xcenField = cw_field(tBase,value='0.0',title='Center: X', $
		  uvalue='xcenter',xsize=9, /Return_Events, /string)
  ycenField = cw_field(tBase,value='0.0',title='Y', $
		  uvalue='ycenter',xsize=9, /Return_Events, /string)
  racenField = cw_field(tBase, value=' ', title='RA', $
		  uvalue='racenter',xsize=12, /Return_Events, /String)
  deccenField = cw_field(tBase, value=' ', title='Dec', $
		  uvalue='decenter',xsize=12, /Return_Events, /String)
  getlab = Widget_Label(tBase, Value='Get X,Y:')
  getrefbutton = Widget_Button(tBase, Value='Ref Cntrd', /Align_Center)
  getrabutton = Widget_Button(tBase, Value='RA/Dec', /Align_Center)
  tsBase = Widget_Base(pWindow, /Row)
  cnames = ['Ref Centroid', 'Individual Centroids', 'RA/Dec', $
    'Hdr RA/Dec', 'XYCenter']
  cButtons = cw_bgroup(tsBase, cnames, row=1, label_left='Stack Centers:', $
	     Set_Value=refcntr, exclusive=1, uvalue='rcbutton', /no_release)
  bBase = Widget_Base(pWindow,/Row)
  tradiusField = cw_field(bBase, value=info.phot.tradius, title = $
		 'Target: Radius',$
		 uvalue='radius',xsize=6, /Return_Events, /Floating)
  biradiusField = cw_field(bBase, value = info.phot.biradius, title = $
		  'Background: Inner Radius', $
                  uvalue='irad', xsize=6, /Return_Events, /Floating)
  boradiusField = cw_field(bBase, value = info.phot.boradius, title = $
		  'Outer Radius', $
                  uvalue='orad', xsize=6, /Return_Events, /Floating)
  mradButton = Widget_Button(bBase, Value='Max Radius', /Align_Center)
  t1Base = Widget_base(pWindow, /Row)
  mthreshField = cw_field(t1Base, value=info.phot.med_thresh, title = $
		 'Median Threshold:',$
		 uvalue='mthresh',xsize=4, /Return_Events, /Floating)
  acorrField = cw_field(t1Base, value=info.phot.ap_corr, title = $
		 'Aperture Fraction:',$
		 uvalue='appcorr',xsize=6, /Return_Events, /Floating)
  bkgfField = cw_field(t1Base, value=info.phot.bkg_fract, title = $
		 'PSF Bkg Fract Flux per Pix:',$
		 uvalue='bkgf',xsize=6, /Return_Events, /Floating)
  commentField = cw_field(pWindow, Value=' ', title = 'Comment:', $
		 uvalue='comm', xsize=90, /Return_Events, /String)
  lastbase = Widget_Base(pWindow,/Row)
  outnameField = cw_field(lastBase, Value = info.phot.outname, $
		 title = 'Output File:', $
                 uvalue='outnam', xsize=76, /Return_Events, /String)
  browseButton = Widget_Button(lastBase, Value='Browse', /Align_Center)
  oBase = Widget_Base(pWindow, /Row)
  loadButton = Widget_Button(oBase, Value='Load Aperture File', /Align_Center)
  markappButton = Widget_Button(oBase, Value='Mark Aperture', /Align_Center)
  computeButton = Widget_Button(oBase, Value='Compute', /Align_Center)
  saveButton = Widget_Button(oBase, Value='Save', /Align_Center)
  pstackButton = Widget_Button(oBase, Value='Stack', /Align_Center)
  pgridButton = Widget_Button(oBase, Value='Grid', /Align_Center)
  if info.dofeps eq 1 then begin
    flabel = Widget_Label(oBase, Value = $
	 '          FEPS:', /Align_Center)
    fepsdatButton = Widget_Button(oBase, Value='Load FEPS', /Align_Center)
    fsaveButton = Widget_Button(oBase, Value='SAVE', $
      Event_Pro='idp3_fepssave', /Align_Center)
    fstackButton = Widget_Button(oBase, Value='STACK', /Align_Center)
  endif else begin
    fstackButton = 0L
    fepsdatButton = 0L
  endelse
  linlab = Widget_Label(pWindow, Value=blnk96)
  outbase = Widget_Base(pWindow, /Column, /Frame)
  rlabel = Widget_Label(outbase, Value = blnk96)
  blabel = Widget_Label(outbase, Value = blnk96)
  ulabel = Widget_Label(outbase, Value = blnk96)
  tlabbase = Widget_Base(outbase, /Row)
  tnamelabel = Widget_Label(tlabbase, Value=blnk30)
  sp1label = Widget_Label(tlabbase, Value='  ')
  tfluxlabel = Widget_Label(tlabbase, Value=blnk10)
  sp2label = Widget_Label(tlabbase, Value='      ')
  tpixlabel = Widget_Label(tlabbase, Value=blnk10)
  sp3label = Widget_Label(tlabbase, Value='       ')
  tmfluxlabel = Widget_Label(tlabbase, Value=blnk10)
  sp4label = Widget_Label(tlabbase, Value='    ')
  trmslabel = Widget_Label(tlabbase, Value=blnk10)
  btlabbase = Widget_Base(outbase, /Row)
  btnamelabel = Widget_Label(btlabbase, Value=blnk30)
  btsp1label = Widget_Label(btlabbase, Value='  ')
  btfluxlabel = Widget_Label(btlabbase, Value=blnk10)
  btsp2label = Widget_Label(btlabbase, Value='      ')
  btpixlabel = Widget_Label(btlabbase, Value=blnk10)
  btsp3label = Widget_Label(btlabbase, Value='       ')
  btmfluxlabel = Widget_Label(btlabbase, Value=blnk10)
  btsp4label = Widget_Label(btlabbase, Value='    ')
  btrmslabel = Widget_Label(btlabbase, Value=blnk10)
  blabbase = Widget_Base(outbase, /Row)
  bnamelabel = Widget_Label(blabbase, Value=blnk30)
  bsp1label = Widget_Label(blabbase, Value='  ')
  bfluxlabel = Widget_Label(blabbase, Value=blnk10)
  bsp2label = Widget_Label(blabbase, Value='      ')
  bpixlabel = Widget_Label(blabbase, Value=blnk10)
  bsp3label = Widget_Label(blabbase, Value='       ')
  bmfluxlabel = Widget_Label(blabbase, Value=blnk10)
  bsp4label = Widget_Label(blabbase, Value='    ')
  brmslabel = Widget_Label(blabbase, Value=blnk10)
  b1label = Widget_Label(outbase, Value=blnk96)
  labbase = Widget_Base(outbase, /Row)
  tcflabel = Widget_Label(labbase, Value = blnk36)
  shplabel = Widget_Label(labbase, Value=blnk30)
  shpbkglabel = Widget_Label(labbase, Value=blnk32)

  pinfo =  { sButtons       : sButtons,      $
	     cButtons       : cButtons,      $
	     shpButton      : shpButton,     $
             tradiusField   : tradiusField,  $
	     acorrField     : acorrField,    $
	     bkgfField      : bkgfField,     $
	     mthreshField   : mthreshField,  $
	     mradButton     : mradButton,    $
	     zlabel         : zlabel,        $
	     rlabel         : rlabel,        $
	     ulabel         : ulabel,        $
	     xcenField      : xcenField,     $
             ycenField      : ycenField,     $
	     racenField     : racenField,    $
	     deccenField    : deccenField,   $
	     getrefbutton   : getrefbutton,  $
	     getraButton    : getraButton,   $
	     markappButton  : markappButton, $
	     loadButton     : loadButton,    $
	     pstackButton   : pstackButton,  $
	     pgridButton    : pgridButton,   $
	     fstackButton   : fstackButton,  $
	     fepsdatButton  : fepsdatButton, $
             biradiusField  : biradiusField, $
	     boradiusField  : boradiusField, $
	     outnameField   : outnameField,  $
	     browseButton   : browseButton,  $
	     commentField   : commentField,  $
	     tcflabel       : tcflabel,      $
	     shplabel       : shplabel,      $
	     shpbkglabel    : shpbkglabel,   $
	     tnamelabel     : tnamelabel,    $
	     tfluxlabel     : tfluxlabel,    $
	     tpixlabel      : tpixlabel,     $
	     tmfluxlabel    : tmfluxlabel,   $
	     trmslabel      : trmslabel,     $
	     btnamelabel    : btnamelabel,   $
	     btfluxlabel    : btfluxlabel,   $
	     btmfluxlabel   : btmfluxlabel,  $
	     btpixlabel     : btpixlabel,    $
	     btrmslabel     : btrmslabel,    $
	     bnamelabel     : bnamelabel,    $
	     bfluxlabel     : bfluxlabel,    $
	     bpixlabel      : bpixlabel,     $
	     bmfluxlabel    : bmfluxlabel,   $
	     brmslabel      : brmslabel,     $
             computeButton  : computeButton, $
             saveButton     : saveButton,    $
	     info           : info           }

  Widget_Control, pWindow, Set_UValue=pinfo

  Widget_Control, pWindow, /Realize
  Widget_Control,pinfo.info.idp3Window,Set_UValue=pinfo.info
  Widget_Control,event.top, set_UValue=pinfo.info

  XManager, 'idp3_photometry', pWindow, /No_Block,  $
	    Event_Handler='idp3_phot_Event'

end
