function idp3_setcoords, ims, pwcs

    hdr = [*ims.phead, *ims.ihead]
    if n_elements(hdr) gt 0 then begin
      ctype1 = strtrim(sxpar(hdr, 'CTYPE1', count=wcs1),2)
      ctype2 = strtrim(sxpar(hdr, 'CTYPE2', count=wcs2),2)
      if wcs1 ge 1 and wcs2 ge 1 then begin
;	if strlen(ctype1) gt 8 then begin
;	  ctype1 = strmid(ctype1,0,8)
;	  t1 = 0
;        endif else t1 = 1
;	if strlen(ctype2) gt 8 then begin
;	  ctype2 = strmid(ctype2,0,8)
;	  t2 = 0
;        endif else t2 = 1
        if strlowcase(ctype1) ne 'lambda' and strlowcase(ctype1) ne 'angle' $
	  and strlowcase(ctype1) ne 'pixel' $
	  then begin
  	  crval1 = sxpar(hdr, 'CRVAL1')
	  b = size(crval1)
	  if b[0] eq 0 and b[1] eq 4 or b[1] eq 5 then begin
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
;	    if t1 eq 0 then sxdelpar, hdr, 'CTYPE1'
;	    if t2 eq 0 then sxdelpar, hdr, 'CTYPE2'
	    sxaddpar, hdr, 'CRPIX1', ims.acrpix1
	    sxaddpar, hdr, 'CRPIX2', ims.acrpix2
	    sxaddpar, hdr, 'CD1_1', ims.acd11
	    sxaddpar, hdr, 'CD1_2', ims.acd12
	    sxaddpar, hdr, 'CD2_1', ims.acd21
	    sxaddpar, hdr, 'CD2_2', ims.acd22
	    sxaddpar, hdr, 'CRVAL1', ims.crval1
	    sxaddpar, hdr, 'CRVAL2', ims.crval2
;	    if t1 eq 0 then sxaddpar, hdr, 'CTYPE1', ctype1
;	    if t2 eq 0 then sxaddpar, hdr, 'CTYPE2', ctype2
	    pwcs = 1
          endif
        endif
      endif
    endif
    return, hdr
end

