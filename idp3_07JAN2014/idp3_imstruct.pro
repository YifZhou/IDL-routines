pro idp3_imstruct, cinfo, newim, tempdata, phdr, ihdr
@idp3_structs

    ; Define keywords for getting target ra and dec positions
    ra_names = ['RA_TARG', 'RA_REF']
    dec_names = ['DEC_TARG', 'DEC_REF']

    ; Set up stuff in the new image structure.
    cz = size(tempdata)
    tempmask = intarr(cz[1], cz[2])
    tempmask[*,*] = 1
    notnan = finite(tempdata)
    gcount = 0l
    bcount = 0l
    good = where(notnan eq 1, gcount)
    bad = where(notnan eq 0, bcount)
    if bcount gt 0l then begin
      str = string(bcount) +  ' nan pixels'
      idp3_updatetxt, cinfo, str
      tempdata[bad] = 0.
      tempmask[bad] = 0
      nan_xp = bad MOD cz[1]
      nan_yp = bad / cz[1]
      (*newim).xnan = ptr_new(nan_xp)
      (*newim).ynan = ptr_new(nan_yp)
    endif else begin
      (*newim).xnan = ptr_new()
      (*newim).ynan = ptr_new()
    endelse
    (*newim).data = ptr_new(tempdata)
    (*newim).mask = ptr_new(tempmask)
    (*newim).phead = ptr_new(phdr)
    (*newim).ihead = ptr_new(ihdr)
    temphead = [phdr, ihdr]
    (*newim).xsiz = cz[1]
    (*newim).ysiz = cz[2]
    (*newim).viewtext = 0L
    (*newim).viewwin = 0L
    (*newim).cntrdtext = 0L
    (*newim).cntrdwin = 0L
    (*newim).memory_only = 0
    c = imscale(tempdata[good],10.0)
    coron = 0 
    (*newim).z1 = c[0]
    (*newim).z2 = c[1]
    ep = 0.000001d0
    xplate = sxpar(temphead, 'XPLATE', count=xpm)
    yplate = sxpar(temphead, 'YPLATE', count=ypm)
    oxplate = sxpar(temphead, 'OXPLATE', count=oxpm)
    oyplate = sxpar(temphead, 'OYPLATE', count=oypm)
    if xpm ge 1 and ypm ge 1 and oxpm ge 1 and oypm ge 1 then begin
      xpsiz = xplate
      ypsiz = yplate
    endif else begin
      testin = sxpar(temphead, 'INSTRUME', count=inm)
      if inm eq 0 then begin
	instr = 'UNKNOWN'
	det = ' '
	sdet = ' '
	xpsiz = -1.
	ypsiz = -1.
      endif else begin
        instr = strtrim(testin,2)
	CASE instr of
        'NICMOS': begin
          det = sxpar(temphead, 'CAMERA') 
          od = sxpar(temphead, 'DATE-OBS')
          ot = sxpar(temphead, 'TIME-OBS')
          odsz = size(od)
          otsz = size(ot)
          sdet = strtrim(string(det),2)
          if odsz[1] eq 7 and otsz[1] eq 7 $
            then idp3_getplate, instr, sdet, xpsiz, ypsiz, odate=od, otime=ot $
            else idp3_getplate, instr, sdet, xpsiz, ypsiz
          if det eq 2 then begin
	    aperture = sxpar(temphead, 'APERTURE')
	    if strupcase(aperture) eq 'NIC2-CORON' then coron = 1
          endif
        end 
	'WFPC2': begin
          det = sxpar(temphead, 'DETECTOR')
          sdet = strtrim(string(det),2) 
          idp3_getplate, instr, sdet, xpsiz, ypsiz
	  end
        'STIS': begin
	  det = sxpar(temphead, 'DETECTOR')
	  sdet = det
	  aa = size(sdet)
	  if aa[1] ne 7 then sdet = strtrim(string(sdet),2)
	  idp3_getplate, instr, sdet, xpsiz, ypsiz
	  end
        'MIPS': begin
	  det = sxpar(temphead, 'CHNLNUM', count=dcount)
	  if dcount gt 0 then begin
	    sdet = det
	    aa = size(sdet)
	    if aa[1] ne 7 then sdet = strtrim(string(sdet),2)
	    idp3_getplate, instr, sdet, xpsiz, ypsiz
          endif else begin
	    xpsiz = -1
	    ypsiz = -1
	    sdet = '0'
          endelse
	  end
        'IRAC': begin
	  det = sxpar(temphead, 'CHNLNUM', count=dcount)
	  if dcount gt 0 then begin
	    sdet = det
	    aa = size(sdet)
	    if aa[1] ne 7 then sdet = strtrim(string(sdet),2)
	    idp3_getplate, instr, sdet, xpsiz, ypsiz
          endif else begin
	    xpsiz = -1.
	    ypsiz = -1.
	    sdet = '0'
          endelse
	  end
        else: begin
	  xpsiz = -1.
	  ypsiz = -1.
	  sdet = '0'
          end
        endcase
      endelse
    endelse
    (*newim).xplate = xpsiz
    (*newim).yplate = ypsiz
    (*newim).oxplate = xpsiz
    (*newim).oyplate = ypsiz
    (*newim).nxplate = 0.0
    (*newim).nyplate = 0.0
    (*newim).xpscl = 1.0d0
    (*newim).ypscl = 1.0d0
    (*newim).instrume = instr
    if cinfo.show_wcs ne 0 then begin
      ctype1 = sxpar(temphead, 'CTYPE1', count=ctype1_match)
      ctype2 = sxpar(temphead, 'CTYPE2', count=ctype2_match)
      (*newim).crval1 = sxpar(temphead, 'CRVAL1', count=cr1_match)
      (*newim).crval2 = sxpar(temphead, 'CRVAL2', count=cr2_match)
      (*newim).cd11 = sxpar(temphead, 'CD1_1', count=cd11_match)
      (*newim).cd12 = sxpar(temphead, 'CD1_2', count=cd12_match)
      (*newim).cd21 = sxpar(temphead, 'CD2_1', count=cd21_match)
      (*newim).cd22 = sxpar(temphead, 'CD2_2', count=cd22_match)
      (*newim).crpix1 = sxpar(temphead, 'CRPIX1', count=crp1_match)
      (*newim).crpix2 = sxpar(temphead, 'CRPIX2', count=crp2_match)
      if cd12_match eq 0 then (*newim).cd12 = 0.0d0
      if cd21_match eq 0 then (*newim).cd21 = 0.0d0
      cd_tot = min([cd11_match, cd22_match])
      if cd_tot lt 1 then begin
        cdelt1 = sxpar(temphead, 'CDELT1', count=cdelt1_match)
        cdelt2 = sxpar(temphead, 'CDELT2', count=cdelt2_match)
        crota = sxpar(temphead, 'CROTA2', count=crota_match)
        if cdelt1_match ge 1 and cdelt2_match ge 1 then begin
          if crota_match eq 0 then begin
  	    crota = 0.
  	    crota_match = 1
	    str = (*newim).name + '  No crota found, setting to 0.'
	    idp3_updatetxt, cinfo, str
          endif
        endif
        if min([cdelt1_match, cdelt2_match, crota_match]) ge 1 then begin
	  sinrota = double(sin(!dpi/180.0d0*crota))
	  cosrota = double(cos(!dpi/180.0d0*crota))
	  (*newim).cd11 = cdelt1 * cosrota
	  (*newim).cd12 = abs(cdelt2) * sinrota
	  if (cdelt1 lt 0.0) then (*newim).cd12 = -(*newim).cd12
	  (*newim).cd21 = -abs(cdelt1) * sinrota
	  if (cdelt2 lt 0.0) then (*newim).cd21 = -(*newim).cd21
	  (*newim).cd22 = cdelt2 * cosrota
	  cd_tot = 1
        endif
      endif
      if cr1_match ge 1 and cr2_match ge 1 and cd_tot ge 1 and $
         ctype1_match ge 1 and ctype2_match ge 1 then begin
        if strtrim(ctype1,2) ne 'PIXEL' and strtrim(ctype2,2) ne 'PIXEL' $
           then (*newim).valid_wcs = 1 else (*newim).valid_wcs = 0
        (*newim).acrval1 = (*newim).crval1
        (*newim).acrval2 = (*newim).crval2
        (*newim).acd11 = (*newim).cd11
        (*newim).acd12 = (*newim).cd12
        (*newim).acd21 = (*newim).cd21
        (*newim).acd22 = (*newim).cd22
        (*newim).acrpix1 = (*newim).crpix1
        (*newim).acrpix2 = (*newim).crpix2
      endif else begin
        (*newim).valid_wcs = 0
        (*newim).acrval1 = 0.
        (*newim).acrval2 = 0.
        (*newim).acd11 = 0.
        (*newim).acd12 = 0.
        (*newim).acd21 = 0.
        (*newim).acd22 = 0.
        (*newim).acrpix1 = 0.
        (*newim).acrpix2 = 0.
      endelse
    endif else begin
      (*newim).valid_wcs = 0
      (*newim).crval1 = 0.
      (*newim).crval2 = 0.
      (*newim).cd11 = 0.
      (*newim).cd12 = 0.
      (*newim).cd21 = 0.
      (*newim).cd22 = 0.
      (*newim).crpix1 = 0.
      (*newim).crpix2 = 0.
      (*newim).acrval1 = 0.
      (*newim).acrval2 = 0.
      (*newim).acd11 = 0.
      (*newim).acd12 = 0.
      (*newim).acd21 = 0.
      (*newim).acd22 = 0.
      (*newim).acrpix1 = 0.
      (*newim).acrpix2 = 0.
    endelse
    (*newim).detector = sdet
    cntrd = 0
    rotc = 0
    lccx = sxpar(temphead, 'CNTRDX', count=nlccx)
    lccy = sxpar(temphead, 'CNTRDY', count=nlccy)
    if nlccx eq 1 and nlccy eq 1 then cntrd = 1
    rotcx = sxpar(temphead, 'ROTCX', count=nrxc)
    rotcy = sxpar(temphead, 'ROTCY', count=nryc)
    if nrxc eq 1 and nryc eq 1 then rotc = 1
    if coron eq 1 then begin
      nxcentp = sxpar(temphead, 'NXCENTP', count=nxc)
      nycentp = sxpar(temphead, 'NYCENTP', count=nyc)
      noffstyp = sxpar(temphead, 'NOFFSTYP', count=nyo)
      noffstxp = sxpar(temphead, 'NOFFSTXP', count=nxo)
      if nxc gt 0 and nyc gt 0 and nxo gt 0 and nyo gt 0 then begin
	if rotc eq 0 then begin
	  rotcx = 256. - (nycentp - noffstyp)
	  rotcy = 256. - (nxcentp - noffstxp)
          rotc = 1
        endif
	if cntrd eq 0 then begin
	  lccx = rotcx
	  olccx = rotcx
	  lccy = rotcy
	  olccy = rotcy
	  cntrd = 1
        endif
      endif
    endif
    if rotc eq 0 then begin
      if cinfo.pixorg eq 0 then begin
        rotcx = (cz[1]-1)/2.
        rotcy = (cz[2]-1)/2.
      endif else begin
        rotcx = cz[1]/2.
        rotcy = cz[2]/2.
      endelse
    endif
    if cntrd eq 0 then begin
      lccx = -1.0
      lccy = -1.0
      olccx = -1.0
      olccy = -1.0
    endif
    (*newim).rotcx = rotcx
    (*newim).rotcy = rotcy
    (*newim).lccx = lccx
    (*newim).lccy = lccy
    (*newim).olccx = lccx
    (*newim).olccy = lccy
    (*newim).rotxpad = 0
    (*newim).rotypad = 0
    xpos = 0.
    ypos = 0.
    xypos = 0
    if cinfo.show_wcs gt 0 then begin
      for j = 0, n_elements(ra_names)-1 do begin
        if xypos eq 0 then begin
          ra = sxpar(temphead, ra_names[j], count=rcount)
	  dec = sxpar(temphead, dec_names[j], count=dcount)
	  if rcount gt 0 and dcount gt 0 then begin
	    idp3_getcoords, 1, xpos, ypos, ra, dec, thdr=temphead
	    xypos = 1
	    idp3_conra, ra/15.0d0, ras
	    idp3_condec, dec, decs
	    str = 'LoadFile:  RA= ' + ras + ' Dec= ' + decs + $
		' X= ' + strtrim(string(xpos),2) + ' Y= ' + $
		strtrim(string(ypos),2)
            idp3_updatetxt, cinfo, str
	  endif 
        endif 
      endfor 
      (*newim).xpos = xpos
      (*newim).ypos = ypos
      (*newim).xypos = xypos
    endif else begin
      (*newim).xpos = 0
      (*newim).ypos = 0
      (*newim).xypos = 0
    endelse
    (*newim).clipbottom = 0
    (*newim).clipmin = min(*(*newim).data)
    (*newim).cminval = min(*(*newim).data)
    (*newim).cliptop = 0
    (*newim).clipmax = max(*(*newim).data)
    (*newim).cmaxval = max(*(*newim).data)
    (*newim).dispf = ADD
    (*newim).vis = 1
    (*newim).maskvis = 0
    (*newim).zoom = 1.0
    (*newim).scl = 1.0
    (*newim).bias = 0.0
    (*newim).rot = 0.0
    (*newim).sclamt = 0.0
    (*newim).movamt = 1.0
    (*newim).rotamt = 0.0
    (*newim).topad = 0
    (*newim).pad = 0
end

