pro idp3_getcoords, dir, xx, yy, nra, ndec, imstr=imstr, thdr=thdr

  if n_elements(imstr) gt 0 then begin
    hdr = [*(*imstr).phead, *(*imstr).ihead]
    updat = 1
  endif else if n_elements(thdr) gt 0 then begin
    hdr = thdr
    updat = 0
  endif else begin
    print, 'Error, header not defined'
    xx = -1.
    yy = -1.
    nra = -1.
    ndec = -1.
    return
  endelse
  ctype1 = sxpar(hdr, 'CTYPE1', count=wcs1)
  ctype2 = sxpar(hdr, 'CTYPE2', count=wcs2)
  if wcs1 ge 1 and wcs2 ge 1 then begin
    ctype1 = strtrim(ctype1,2)
    ctype2 = strtrim(ctype2,2)
    if strlowcase(ctype1) ne 'lambda' and strlowcase(ctype1) ne 'angle' and $
      strlowcase(ctype1) ne 'pixel' then begin
      if updat EQ 1 then begin
        sxdelpar, hdr, 'CRPIX1'
        sxdelpar, hdr, 'CRPIX2'
        sxdelpar, hdr, 'CD1_1'
        sxdelpar, hdr, 'CD1_2'
        sxdelpar, hdr, 'CD2_1'
        sxdelpar, hdr, 'CD2_2'
        sxdelpar, hdr, 'CRVAL1'
        sxdelpar, hdr, 'CRVAL2'
        sxdelpar, hdr, 'CDELT1'
        sxdelpar, hdr, 'CDELT2'
        sxdelpar, hdr, 'CROTA'
        sxdelpar, hdr, 'CROTA2'
        sxaddpar, hdr, 'CRVAL1', (*imstr).acrval1
        sxaddpar, hdr, 'CRVAL2', (*imstr).acrval2
        sxaddpar, hdr, 'CRPIX1', (*imstr).acrpix1
        sxaddpar, hdr, 'CRPIX2', (*imstr).acrpix2
        sxaddpar, hdr, 'CD1_1', (*imstr).acd11
        sxaddpar, hdr, 'CD1_2', (*imstr).acd12
        sxaddpar, hdr, 'CD2_1', (*imstr).acd21
        sxaddpar, hdr, 'CD2_2', (*imstr).acd22
      endif
      if dir eq 0 then begin
	xyad, hdr, xx, yy, nra, ndec
      endif else begin
	adxy, hdr, nra, ndec, xx, yy
      endelse
    endif else begin
      if dir eq 0 then nra = -1 else xx = -1
    endelse
  endif else begin
    if dir eq 0 then begin
      nra = -1 
      ndec = -1
    endif else begin
      xx = -1
      yy = -1
    endelse
  endelse
  xsz = size(xx)
  ysz = size(yy)
  if xsz[0] eq 1 then xx = xx[0]
  if ysz[0] eq 1 then yy = yy[0]
  end
