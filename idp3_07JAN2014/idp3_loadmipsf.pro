pro phot_circle, fmask, tmp, nang, thresh, rad, zr, zxcen, zycen, mpol
      
   zledge = zxcen - zr
   zredge = zxcen + zr
   zbottom = zycen - zr
   ztop = zycen + zr
   zlf = floor(zledge)
   zrc = ceil(zredge)
   zbf = floor(zbottom)
   ztc = ceil(ztop)
   endadj = ceil(52.0/rad)
   th = fltarr(nang)
   xe = fltarr(nang)
   ye = fltarr(nang)
   for i=0, nang-1 do th(i)=float(i)*(!pi/180.)
   xe = zr * cos(th) + zxcen
   ye = zr * sin(th) + zycen
   for j = zbf, ztc do begin
     for i = zlf, zrc do begin
       r = SQRT(ABS(zxcen-i)^2 + ABS(zycen-j)^2)
       if tmp[i,j] eq 1 then begin
         lim = zr - 2.0 > 0.0
	 if r lt lim then begin
	   if mpol eq 1 then fmask[i,j] = 1.0 else fmask[i,j] = 0.0
         endif else begin
	   if r le zr + 2.0 then begin
	     ii = float(i)
	     jj = float(j)
	     fnd = 0
	     sfnd = 0
             xst = 0
             xsp = 0
             yst = 0
             ysp = 0
	     if ii le xe[0] and ii+1. ge xe[0] and jj le ye[0] and $
	       jj+1. ge ye[0] then flim1 = 300 else flim1 = 0
	     for kk = flim1, nang-1 do begin
	       if fnd eq 0 then begin
	         if xe[kk] ge ii and xe[kk] le ii+1. and ye[kk] ge jj $
		   and ye[kk] le jj+1. then begin
		   xst = xe[kk]
		   yst = ye[kk]
		   if kk ge nang-endadj then kkk = 0 else kkk = kk
		   fnd = 1
		   sfnd = 0
		   slim1 = kkk+40 < (nang-2)
		   slim2 = kkk+1 < (nang-2)
		   for ll = slim1, slim2, -1 do begin
		     if sfnd eq 0 then begin
		       if xe[ll] ge ii and xe[ll] le ii+1. and $
		         ye[ll] ge jj and ye[ll] le jj+1. then begin
			 xsp = xe[ll]
			 ysp = ye[ll]
			 sfnd = 1
                       endif
                     endif
                    endfor
		    if sfnd eq 0 and flim1 eq 300 then begin
		      for ll = 40, 1, -1 do begin
		        if sfnd eq 0 then begin
			  if xe[ll] ge ii and xe[ll] le ii+1. and $
			    ye[ll] ge jj and ye[ll] le jj+1. then begin
			    xsp = xe[ll]
			    ysp = ye[ll]
                          endif
                        endif
                      endfor
                    endif
		    if sfnd eq 1 then begin
		      xmx = max([xst, xsp])
		      xmn = min([xst, xsp])
		      ymx = max([yst, ysp])
		      ymn = min([yst, ysp])
		      if abs(xsp - xst) ge thresh then begin
		        ; assume trapezoid traversing entire pixel in x
		        xc = fltarr(4)
		        yc = fltarr(4)
		        xc[0] = floor(xmn)
		        xc[1] = floor(xmn)
		        xc[2] = ceil(xmx)
		        xc[3] = ceil(xmx)
		        yc[0] = ymn
		        yc[3] = ymx
                        if yst - fix(yst) gt 0 then yind=yst else yind=ysp
		        if yst lt zycen then yc[1]=ceil(yind) else yc[1]=$
			  floor(yind)
                        yc[2] = yc[1]
			if mpol eq 1 then fmask[i,j] = poly_area(xc,yc) $
			  else fmask[i,j] = 1.0 - poly_area(xc,yc)
                      endif else if abs(ysp - yst) ge thresh then begin
			; assume trapezoid traversing entire pixel in y
			xc = fltarr(4)
			yc = fltarr(4)
			yc[0] = floor(ymn)
			yc[1] = floor(ymn)
			yc[2] = ceil(ymx)
			yc[3] = ceil(ymx)
			xc[0] = xmn
			xc[3] = xmx
                        if xmn - fix(xmn) gt 0 then xind=xmn else xind=xmx
                        if xmn lt zxcen then xc[1]=ceil(xind) else $
			  xc[1] = floor(xind)
                        xc[2] = xc[1]
			if mpol eq 1 then fmask[i,j] = poly_area(xc,yc) $
			  else fmask[i,j] = 1.0 - poly_area(xc,yc)
                      endif else begin
		        ; assume a triangle
			xc = fltarr(3)
			yc = fltarr(3)
			xc[0] = xst
			xc[1] = xsp
			yc[0] = yst
			yc[1] = ysp
			if ii+1. - xmx gt xmn - ii then xc[2] = ii else $
			  xc[2] = ii+1.
                        if jj+1. - ymx gt ymn - jj then yc[2] = jj else $
			  yc[2] = jj + 1.
                        if mpol eq 1 then fmask[i,j] = poly_area(xc,yc) $
			  else fmask[i,j] = 1.0 - poly_area(xc,yc)
			; locate triangles to adjust
			if xst lt xsp then begin
			  if yst lt ysp and r le zr then fmask[i,j] = $
				  1.0 - fmask[i,j]
                          if yst gt ysp and xc[2] eq ii and yc[2] eq jj $
			    then fmask[i,j] = 1.0 - fmask[i,j]
                        endif else begin
			  if yst gt ysp and r le zr then fmask[i,j] = $
			    1.0 - fmask[i,j]
                          if yst lt ysp and xc[2] eq ii+1. and yc[2] eq $
			    jj+1. then fmask[i,j] = 1.0 - fmask[i,j]
                        endelse
                      endelse
                    endif
                  endif
                endif 
              endfor
	      if sfnd eq 0 then begin
	        if i gt (zxcen-0.61) then ep = -0.015 * rad else if $
		  i lt zxcen then ep = rad * 0.015 else ep = 0.
		if r le (zr+ep) then begin
		  if mpol eq 1 then fmask[i,j] = 1.0 else fmask[i,j]=0.0
                endif else begin
		  if mpol eq 1 then fmask[i,j] = 0.0  ; else fmask[i,j]  = 1.0
	        endelse	 
              endif
            endif
         endelse
       endif
     endfor
   endfor
end

pro Idp3_Loadmipsf, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo
  ; We keep track of the path the user picks files from.
  inpath = cinfo.imagepath
  filename = Dialog_Pickfile(/Read, /Must_Exist, Get_Path=outpath, Path=inpath)
  cinfo.imagepath = outpath
  filename = strtrim(filename(0), 2)
  if strlen(filename) eq 0 then return
  zoom = cinfo.m_zoom
  tthresh = cinfo.m_thresh
  borad = cinfo.m_tborad 
  birad = cinfo.m_tbirad 
  trad = cinfo.m_trad
  trefit = cinfo.m_refit
  porad = cinfo.m_pborad
  pirad = cinfo.m_pbirad
  prad = cinfo.m_prad
  zbor = borad * zoom
  zbir = birad * zoom
  ztrad = trad * zoom
  pxcen = cinfo.m_pxcen
  pycen = cinfo.m_pycen
  nang = 361
  th = fltarr(nang)
  xe = fltarr(nang)
  ye = fltarr(nang)
  for i=0, nang-1 do th(i)=float(i)*(!pi/180.)
  thresh = 0.85
  plane = 0
  if birad lt trad or borad - birad lt 1. then bkg_flg = 0 else bkg_flg = 1
  if trad lt 1. then begin
    str = 'LoadMIPSf: Invalid target radius'
    idp3_updatetxt, cinfo, str
    return
  endif

  ; read input file (xpos, ypos, psf name)
  openr, slun, filename, /get_lun
  pname = ''
  fname = ''
  extn = '.fits'
  sxpos = ''
  sypos = ''
  sext = ''
  indx = 0
  while not eof(slun) do begin
    lineOfText = ''
    readf, slun, lineOfText
    ttmpstr = strsplit(lineOfText, /extract)
    if indx eq 0 then begin
      sxpos = ttmpstr[0]
      sypos = ttmpstr[1]
      pname = ttmpstr[2] + extn
      len = strlen(ttmpstr[2])
      fname = strmid(ttmpstr[2], 0, len-7) + extn
      sext = strmid(ttmpstr[2],len-6,2)
      indx = indx + 1
    endif else begin
      sxpos = [sxpos, ttmpstr[0]]
      sypos = [sypos, ttmpstr[1]]
      pname = [pname, ttmpstr[2] + extn]
      fname = [fname, strmid(ttmpstr[2], 0, len-7) + extn]
      sext = [sext, strmid(ttmpstr[2],len-6,2)]
      indx = indx + 1
    endelse
  endwhile
  close, slun
  free_lun, slun
  xpos = float(sxpos) * zoom
  ypos = float(sypos) * zoom
  ext = fix(sext)
  num = n_elements(xpos)
  openw, tlun, 'mips_psf.txt', /get_lun
  for i = 0, num-1 do begin
    str = 'LoadMIPSf: ' +  fname[i] + ext[i] + '  ' + pname[i] + $
	  string(xpos[i]) + string(ypos[i])
    idp3_updatetxt, cinfo, str
    printf, tlun, fname[i], ext[i], '  ', pname[i], xpos[i], ypos[i]
    tempfname = fname[i]
    flen = strlen(tempfname)
    temppname = pname[i]
    plen = strlen(temppname)
    if flen gt 0 and plen gt 0 then begin
      ftemp = file_search (tempfname, Count = fcount)
      ptemp = file_search (temppname, Count = pcount)
      if fcount gt 0 and pcount gt 0 then okay = 1 else okay = 0
    endif
    if okay eq 1 then begin 
      ; Make a new image structure.
      newim = ptr_new({idp3im})
      ua_decompose, tempfname, disk, path, name, extn, version
      (*newim).name = disk + path + name + '_' + sext[i] + extn
      (*newim).orgname = tempfname
      ua_fits_open, tempfname, fcb
      if fcb.nextend gt 0 then begin
        ua_fits_read, fcb, temp, phdr,Exten_No=0,/Header_Only,/no_abort
	ua_fits_read, fcb, tempdata, ihdr, Exten_no=ext[i], /NO_PDU, /no_abort
      endif else begin
	ua_fits_read, fcb, tempdata, phdr, /no_abort
	ihdr = ['','']
      endelse
      ua_fits_close, fcb
      ; Load up the new image with data, etc.
      (*newim).extnam = 'None'
      (*newim).extver = ext[i]
      (*newim).phead = ptr_new(phdr)
      (*newim).ihead = ptr_new(ihdr)
      temphead = [phdr, ihdr]
      sz = size(tempdata)
      if sz[0] eq 3 then tdata = tempdata[*,*,plane] else tdata = tempdata
      xsiz = sz[1]*zoom
      ysiz = sz[2]*zoom
      if zoom gt 1.0 then begin
	tmdata = idp3_congrid(tdata, xsiz, ysiz, zoom, cinfo.mdioz, $
	      cinfo.pixorg)
        if cinfo.zoomflux eq 1 then tmdata = tmdata/zoom^2 
      endif else tmdata = tdata
      idp3_imstruct, cinfo, newim, tdata, phdr, ihdr
      ; refit center and background
      if trefit eq 1 then begin
        xf = xpos[i] - ztrad
        xl = xpos[i] + ztrad
        yf = ypos[i] - ztrad
        yl = ypos[i] + ztrad
        dat = tmdata[xf:xl, yf:yl]
        start = fltarr(8)
        start[1] = tmdata[xpos[i],ypos[i]]
        start[2] = ztrad / 2.534
        start[3] = ztrad / 2.534
        start[4] = xpos[i] - xf
        start[5] = ypos[i] - yf
        yfit = mpfit2dpeak(dat, aa, estimates=start, perror=perror)
        txcen = aa[4] + xf
        tycen = aa[5] + yf
        tbkg = aa[0]
        str = 'LoadMIPSf: target:' + string(xpos[i]) + string(txcen) + $
	       string(ypos[i]) +  string(tycen) + string(tbkg)
        idp3_updatetxt, cinfo, str
        printf, tlun, 'target:', xpos[i], txcen, ypos[i], tycen, tbkg
      endif else begin
	txcen = xpos[i]
	tycen = ypos[i]
      endelse
      (*newim).lccx = txcen
      (*newim).lccy = tycen
      (*newim).zoom = zoom
      if i gt 0 then (*newim).vis = 0
      ; Save this new image into the image array or structures.
      c = size(*cinfo.images)
      if (c[0] eq 0 and c[1] eq 2) then begin
        ; If this is the first image loaded then set Z1 Z2 from this one.
        tempimages = newim
        cinfo.Z1 = (*newim).z1
        cinfo.Z2 = (*newim).z2
      endif else begin
        ; If this isn't the first image loaded, concatinate this image
        ; onto the existing list of images and replace the old list with
        ; the new list.
        tempimages = [*cinfo.images,newim]
        ptr_free,cinfo.images
      endelse
      cinfo.images = ptr_new(tempimages)
      Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
      ; calculate target and background fluxes
      zxcen = txcen
      zycen = tycen
      tmp = bytarr(xsiz, ysiz)
      tmp[*,*] = 1
      ftmask = fltarr(xsiz, ysiz)
      ftmask[*,*] = 0.
      fbmask = fltarr(xsiz, ysiz)
      fbmask[*,*] = 0.
      if bkg_flg eq 1 then begin
        ; circular aperture for background - update for fractional pixels
	if zxcen - zbor gt 0. and zxcen + zbor lt xsiz-1 and $
	  zycen - zbor gt 0. and zycen + zbor lt ysiz-1 then begin
	  xe = zbor * cos(th) + zxcen
	  ye = zbor * sin(th) + zycen
	  ; outer circle
	  mpol = 1
	  phot_circle, fbmask,tmp,nang,thresh,borad,zbor,zxcen,zycen,mpol
	  ; inner circle
	  mpol = 0
	  phot_circle, fbmask,tmp,nang,thresh,birad,zbir,zxcen,zycen,mpol
	  bgood = where(fbmask gt 0.0, bcnt)
	  if bcnt gt 1 then begin
;	    btotal = total(tmdata[bgood]*fbmask[bgood])
;	    bmedian = median(tmdata[bgood]*fbmask[bgood], /even)
;	    bc = moment(tmdata[bgood])
;	    brms = SQRT(bc[1])
	    bsz = size(tmdata)
            btotal = 0.
	    for ij = 0, n_elements(bgood)-1 do begin
	      tgy = bgood[ij]/sz[1]
	      tgx = bgood[ij] MOD sz[1]
              btotal = btotal + tmdata[tgx,tgy] * fbmask[tgx,tgy]
            endfor
	    bnpix = total(fbmask[bgood])
            bmean = btotal/bnpix
	    bgoodmed = where(fbmask gt tthresh, tbcnt)
	    if tbcnt gt 0 then bmedian = median(tmdata[bgoodmed],/even) $
	      else bmedian = 0.
	    str = 'LoadMIPSf: Bkg(flux,median,medpix,mean,npix):'
	    idp3_updatetxt, cinfo, str
	    str = 'LoadMIPSf: ' + string(btotal) + string(bmedian) + $
		   string(tbcnt) + string(bmean) + string(bnpix)
            idp3_updatetxt, cinfo, str
	    printf, tlun, 'Bkg(flux,median,medpix,mean,npix):'
	    printf, tlun, btotal,bmedian,tbcnt,bmean,bnpix
	    tmdata = tmdata - bmedian
	    numimages = n_elements(*cinfo.images)
	    (*(*cinfo.images)[numimages-1]).bias = bmedian * (-1.0)
	    Widget_Control, cinfo.idp3Window, Set_UValue = cinfo
          endif else bkg_flg = 0
        endif else bkg_flg = 0
      endif
      if trad gt 0. then begin
	; circular aperture for target
	xe = ztrad * cos(th) + zxcen
	ye = ztrad * sin(th) + zycen
	mpol = 1
	phot_circle,ftmask,tmp, nang, thresh, trad, ztrad, zxcen, zycen, mpol
        tgood = where(ftmask gt 0.0, tcnt)
        if tcnt gt 1 then begin
;          ttotal = total(tmdata[tgood]*ftmask[tgood])
;	  tmedian = median(tmdata[tgood]*ftmask[tgood], /even)
;	  tc = moment(tmdata[tgood])
;	  trms = SQRT(tc[1])
;	  tmean = tc[0]
	  tsz = size(tmdata)
          ttotal = 0.
	  for ij = 0, n_elements(tgood)-1 do begin
	    tgy = tgood[ij]/sz[1]
	    tgx = tgood[ij] MOD sz[1]
            ttotal = ttotal + tmdata[tgx,tgy] * ftmask[tgx,tgy]
          endfor
	  tnpix = total(ftmask[tgood])
          tmean = ttotal/tnpix
	  str = 'LoadMIPSf: Target(flux,mean,npix):' + $
		string(ttotal) + string(tmean) + string(tnpix)
          idp3_updatetxt, cinfo, str
	  printf, tlun, 'Target(flux,mean,npix):', ttotal, tmean, tnpix
        endif
      endif
      ; load psf
      newim = ptr_new({idp3im})
      (*newim).name = temppname
      (*newim).orgname = temppname
      ua_fits_read, temppname, psfdata, psfhdr
      psfihdr = ' '
      (*newim).extnam = 'None'
      (*newim).extver = 0
      (*newim).phead = ptr_new(psfhdr)
      (*newim).ihead = ptr_new(psfihdr)
      ; refit psf center
      xf = pxcen - prad
      xl = pxcen + prad
      yf = pycen - prad
      yl = pycen + prad
      dat = psfdata[xf:xl, yf:yl]
      start = fltarr(8)
      start[1] = psfdata[pxcen, pycen]
      start[2] = prad/2.534
      start[3] = prad/ 2.534
      start[4] = pxcen - xf
      start[5] = pycen - yf
      yfit = mpfit2dpeak(dat, aa, estimates=start, perror=perror, /tilt)
      npxcen = aa[4] + xf
      npycen = aa[5] + yf
      pbkg = aa[0]
      str = 'LoadMIPSf: ' + string(pxcen) + string(npxcen) + string(pycen) + $
	    string(npycen) + string(pbkg)
      idp3_updatetxt, cinfo, str
      printf, tlun, pxcen, npxcen, pycen, npycen, pbkg
      ; calculate psf background if non-zero values are given for annulus
      psz = size(psfdata)
      opmask = fltarr(psz[1], psz[2])
      opmask[*,*] = 0.
      pbmask = fltarr(psz[1], psz[2])
      pbmask[*,*] = 0.
      ptmp = bytarr(psz[1],psz[2])
      ptmp[*,*] = 1
      if pirad gt 0. and porad gt 0. then begin
	if npxcen - porad gt 0. and npxcen + porad lt psz[1]-1 and $
	  npycen - porad gt 0. and npycen + porad lt psz[2]-1 then begin
	  pxe = porad * cos(th) + npxcen
	  pye = porad * sin(th) + npycen
	  ; outer circle
	  mpol = 1
	  phot_circle, pbmask, ptmp, nang, thresh, porad, porad, npxcen, $
	    npycen, mpol
          ; inner circle
	  mpol = 0
	  phot_circle, pbmask, ptmp, nang, thresh, pirad, pirad, npxcen, $
	    npycen, mpol
          pbgood = where(pbmask gt 0.0, pcnt)
	  if pcnt gt 1 then begin
	    pbtotal = 0.
	    for ij = 0, n_elements(pbgood)-1 do begin
	      pgy = pbgood[ij]/psz[1]
	      pgx = pbgood[ij] MOD psz[1]
	      pbtotal = pbtotal + psfdata[pgx,pgy] * pbmask[pgx,pgy]
            endfor
	    pbnpix = total(pbmask[pbgood])
	    pbmean = pbtotal/pbnpix
	    pbgoodmed = where(pbmask gt tthresh, pbcnt)
	    if pbcnt gt 0 then pbmedian = median(psfdata[pbgoodmed],/even) $
	      else bmedian = 0.
            str = 'LoadMIPSf: PSF Bkg(flux,median,medpix,mean,npix):'
	    idp3_updatetxt, cinfo, str
	    str = 'LoadMIPSf: ' + string(pbtotal) + string(pbmedian) + $
		  string(pbcnt) + string(pbmean) + string(pbnpix)
            idp3_updatetxt, cinfo, str
	    printf, tlun, 'PSF Bkg(flux,median,medpix,mean,npix):'
	    printf, tlun, pbtotal,pbmedian,pbcnt,pbmean,pbnpix
          endif
        endif
      endif
      ; calculate flux and scale psfdata
      if prad gt 0. then begin
	tpsfdata = psfdata - pbmedian
	; circular aperture for psf
	xe = prad * cos(th) + npxcen
	ye = prad * sin(th) + npycen
	mpol = 1
	phot_circle, opmask,ptmp,nang,thresh,prad,prad,npxcen,npycen,mpol
        pgood = where(opmask gt 0.0, pcnt)
        if pcnt gt 1 then begin
;         ptotal = total(psfdata[pgood]*opmask[pgood])
;	  pmedian = median(psfdata[pgood]*opmask[pgood], /even)
;	  pc = moment(psfdata[pgood])
;	  pmean = pc[0]
;	  prms = SQRT(pc[1])
          ptotal = 0.
	  for ij = 0, n_elements(pgood)-1 do begin
	    pgy = pgood[ij]/psz[1]
	    pgx = pgood[ij] MOD psz[1]
            ptotal = ptotal + tpsfdata[pgx,pgy] * opmask[pgx,pgy]
          endfor
	  pnpix = total(opmask[pgood])
          pmean = ptotal/pnpix
	  ratio = tmean/pmean
	  str = 'LoadMIPSf: PSF(flux,mean,npix,scale):' + string(ptotal) + $
		 string(pmean) + string(pnpix) + string(ratio)
          idp3_updatetxt, cinfo, str
	  printf, tlun, 'PSF(flux,mean,npix,scale):', ptotal, pmean, $
		 pnpix, ratio
        endif
      endif
      idp3_imstruct, cinfo, newim, psfdata, psfhdr, psfihdr
      (*newim).lccx = npxcen
      (*newim).lccy = npycen
      if i gt 0 then (*newim).vis = 0
      (*newim).dispf = 2
      (*newim).bias = pbmedian * (-1.0) * ratio
      (*newim).scl = ratio
      xo = zxcen - npxcen
      yo = zycen - npycen
      (*newim).xoff = float(floor(xo))
      (*newim).xpoff = xo - (*newim).xoff
      (*newim).yoff = float(floor(yo))
      (*newim).ypoff = yo - (*newim).yoff
      tempimages = [*cinfo.images,newim]
      ptr_free,cinfo.images
      cinfo.images = ptr_new(tempimages)
      Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
    endif
  endfor
  close, tlun
  free_lun, tlun
  fbmask = 0
  ftmask = 0
  tmp = 0
  ptmp = 0
  pbmask = 0
  tmdata = 0
  tpsfdata = 0
  ; save this for last
  ; Call the ShowIm routine and exit.
  ; If ShowIm is already running, kill it first.
  if (XRegistered('idp3_showim')) then begin
    geo = Widget_Info(cinfo.ShowImBase, /geometry)
    cinfo.wpos.siwp[0] = geo.xoffset - cinfo.xoffcorr
    cinfo.wpos.siwp[1] = geo.yoffset - cinfo.yoffcorr
    Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
    Widget_Control, cinfo.ShowImBase, /Destroy
  endif
  idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,SELECT:0}
  Widget_Control, cinfo.idp3Window, Get_UValue=info
  Widget_Control, cinfo.idp3Window, Get_UValue=cinfo
  ; Update graphics display.
  idp3_display,cinfo

  Widget_Control, event.top, Set_UValue=cinfo
end

