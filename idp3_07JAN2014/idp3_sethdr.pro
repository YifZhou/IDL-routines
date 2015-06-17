pro idp3_sethdr, ims, im, ext, phead, ihead, dsz, lim1, lim2, fluxstr
@idp3_structs
        phead  = *(*ims[im]).phead 
	ihead  = *(*ims[im]).ihead
	nax = n_elements(dsz)
	if phead[0] eq '' then begin
          ; Header empty (probably read HDF file), build header.
          phead = $
['SIMPLE  =                    T /image conforms to FITS standard           ', $
 'NAXIS   =                    2 /number of axes                            ', $
 'END                                                                       ']
          sxaddpar,phead,'NAXIS1',dsz[0]
          sxaddpar,phead,'NAXIS2',dsz[1]
	  if nax eq 3 then sxaddpar, phead, 'NAXIS3', dsz[2]
	  ihead = ' '
        endif else begin
	  if n_elements(ihead) gt 2 then begin
	    if ext eq 1 then begin
	      sxdelpar, phead, 'NEXTEND'
	      sxdelpar, phead, 'END'
	      sxdelpar, ihead, 'XTENSION'
	      sxdelpar, ihead, 'INHERIT'
	      sxdelpar, ihead, 'EXTNAME'
	      sxdelpar, ihead, 'EXTVER'
	      sxdelpar, ihead, 'EXTLEVEL'
	      sxdelpar, ihead, 'BITPIX'
	      sxdelpar, ihead, 'NAXIS'
	      sxdelpar, ihead, 'NAXIS1'
	      sxdelpar, ihead, 'NAXIS2'
	      sxdelpar, ihead, 'GCOUNT'
	      phead = [phead, ihead]
	      ihead = ' '
	      sxaddpar, phead, 'NAXIS', 2
	      sxaddpar, phead, 'NAXIS1', dsz[0], AFTER='NAXIS'
	      sxaddpar, phead, 'NAXIS2', dsz[1], AFTER='NAXIS1'
	      if nax eq 3 then sxaddpar, phead, 'NAXIS3', dsz[2], AFTER='NAXIS2'
            endif  
          endif 
        endelse
        xoff = (*ims[im]).xoff
        yoff = (*ims[im]).yoff

        ; Get updated WCS based on what's been done to image.
	crpix1 = (*ims[im]).crpix1
	crpix2 = (*ims[im]).crpix2
	crval1 = (*ims[im]).crval1
	crval2 = (*ims[im]).crval2
	cd11 = (*ims[im]).cd11
	cd12 = (*ims[im]).cd12
	cd21 = (*ims[im]).cd21
	cd22 = (*ims[im]).cd22
	tcpix1 = (*ims[im]).acrpix1
	tcpix2 = (*ims[im]).acrpix2
	tcrval1 = (*ims[im]).acrval1
	tcrval2 = (*ims[im]).acrval2
	tcd11 = (*ims[im]).acd11
	tcd12 = (*ims[im]).acd12
	tcd21 = (*ims[im]).acd21
	tcd22 = (*ims[im]).acd22
	rotcx = (*ims[im]).rotcx
	rotcy = (*ims[im]).rotcy
	rot = (*ims[im]).rot
	cntrdx = (*ims[im]).olccx
	cntrdy = (*ims[im]).olccy
	if (*ims[im]).topad eq 1 and (*ims[im]).pad gt 0 then begin
	  rotcx = rotcx + (*ims[im]).pad
	  rotcy = rotcy + (*ims[im]).pad
	  cntrdx = cntrdx + (*ims[im]).pad
	  cntrdy = cntrdy + (*ims[im]).pad
        endif
	if (*ims[im]).xpscl ne 1.0 then begin
	  rotcx = rotcx * (*ims[im]).xpscl
	  cntrdx = cntrdx * (*ims[im]).xpscl
        endif
	if (*ims[im]).ypscl ne 1.0 then begin
	  rotcy = rotcy * (*ims[im]).ypscl
	  cntrdy = cntrdy * (*ims[im]).ypscl
        endif
	if abs((*ims[im]).zoom - 1.0 gt 0.00001) then begin
	  rotcx = rotcx * (*ims[im]).zoom
	  rotcy = rotcy * (*ims[im]).zoom
	  cntrdx = cntrdx * (*ims[im]).zoom
	  cntrdy = cntrdy * (*ims[im]).zoom
        endif
	if abs(rot) gt 0.0001 and cntrdx gt 0. and cntrdy gt 0. then begin
	  cdr = !DPI/180.0D
	  theta = rot * cdr
	  rot_mat = [ [ cos(theta), sin(theta)], $   ;Rotation matrix
		      [-sin(theta), cos(theta)] ]
          rotc = [rotcx,rotcy]
	  lcc = [cntrdx,cntrdy]
	  nlcc = rotc + transpose(rot_mat)#(lcc-rotc)
	  cntrdx = nlcc[0]
	  cntrdy = nlcc[1]
        endif
	xoff = (*ims[im]).xpoff + (*ims[im]).xoff
	yoff = (*ims[im]).ypoff + (*ims[im]).yoff
	if abs(xoff) gt 0.0 then begin
	  rotcx = rotcx + xoff
	  cntrdx = cntrdx + xoff
        endif
	if abs(yoff) gt 0.0 then begin
	  rotcy = rotcy + yoff
	  cntrdy = cntrdy + yoff
        endif

	if n_elements(ihead) le 2 then begin
          sxaddpar,phead,'CRPIX1',tcpix1
          sxaddpar,phead,'CRPIX2',tcpix2
	  sxaddpar,phead,'CRVAL1',tcrval1
	  sxaddpar,phead,'CRVAL2',tcrval2
	  sxaddpar,phead,'CD1_1',tcd11
	  sxaddpar,phead,'CD1_2',tcd12
	  sxaddpar,phead,'CD2_1',tcd21
	  sxaddpar,phead,'CD2_2',tcd22
	  sxaddpar,phead,'ROTCX',rotcx
	  sxaddpar,phead,'ROTCY',rotcy
	  sxaddpar,phead,'CNTRDX',cntrdx
	  sxaddpar,phead,'CNTRDY',cntrdy
        endif else begin
          sxaddpar,ihead,'CRPIX1',tcpix1
          sxaddpar,ihead,'CRPIX2',tcpix2
	  sxaddpar,ihead,'CRVAL1',tcrval1
	  sxaddpar,ihead,'CRVAL2',tcrval2
	  sxaddpar,ihead,'CD1_1',tcd11
	  sxaddpar,ihead,'CD1_2',tcd12
	  sxaddpar,ihead,'CD2_1',tcd21
	  sxaddpar,ihead,'CD2_2',tcd22
	  sxaddpar,phead,'ROTCX',rotcx
	  sxaddpar,phead,'ROTCY',rotcy
	  sxaddpar,phead,'CNTRDX',cntrdx
	  sxaddpar,phead,'CNTRDY',cntrdy
        endelse

	tstr = 'IDP3 History on ' + systime()
	sxaddpar, phead, 'HISTORY', tstr
	sxaddpar, phead, 'HISTORY', 'Old value of crpix1 ' + string(crpix1)
	sxaddpar, phead, 'HISTORY', 'Old value of crpix2 ' + string(crpix2)
	sxaddpar, phead, 'HISTORY', 'Old value of crval1 ' + string(crval1)
	sxaddpar, phead, 'HISTORY', 'Old value of crval2 ' + string(crval2)
	sxaddpar, phead, 'HISTORY', 'Old value of cd1_1 ' + string(cd11)
	sxaddpar, phead, 'HISTORY', 'Old value of cd1_2 ' + string(cd12)
	sxaddpar, phead, 'HISTORY', 'Old value of cd2_1 ' + string(cd21)
	sxaddpar, phead, 'HISTORY', 'Old value of cd2_2 ' + string(cd22)
	; set plate scale keywords
        sxaddpar,phead,'OXPLATE',(*ims[im]).oxplate, $
		 'X Pixel Scale of Original Data' 
        sxaddpar,phead,'OYPLATE',(*ims[im]).oyplate, $
		 'Y Pixel Scale of Original Data'
        if (*ims[im]).oxplate ne (*ims[im]).xplate OR $
	   (*ims[im]).oyplate ne (*ims[im]).yplate then begin
           sxaddpar,phead,'NXPLATE', (*ims[im]).nxplate, $
		 'X Pixel Scale of Final Data' 
           sxaddpar,phead,'NYPLATE', (*ims[im]).nyplate, $
		 'Y Pixel Scale of Final Data'
        endif

	; add or modify reorient keyword if image has been rotated
	if abs((*ims[im]).rot) gt 0.0001 then begin
	  orient = sxpar(phead, 'ORIENTAT', count=omatch)
	  reorient = sxpar(phead, 'REORIENT', count=rmatch)
	  if rmatch gt 0 then begin
	    neworient = reorient + (*ims[im]).rot
	    sxaddpar, phead, 'REORIENT', neworient
          endif else begin
	    if omatch gt 0 then begin
	      neworient = orient + (*ims[im]).rot
	      sxaddpar, phead, 'REORIENT', neworient
            endif
          endelse
        endif
	idp3_savhistory, ims, phead, lim1, lim2, im
	sxaddpar, phead, 'HISTORY', fluxstr
	sxaddpar, phead, 'HISTORY', tstr
 end
