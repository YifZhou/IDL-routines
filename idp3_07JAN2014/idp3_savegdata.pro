function idp3_savegdata, event, sinfo, filename, type, x1, x2, y1, y2  
@idp3_structs
      
      ; decompose string and check if file extension is given
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.fits'

      ; check if file already exists, if so query if wish to overwrite
      temp = file_search (filename, Count = fcount)
      if fcount gt 0 then begin
	idp3_selectval, event.top, 'Do you wish to overwrite existing file?',$
	  ['no','yes'], val
	if val eq 0 then begin 
	  disk = ''
	  path = ''
	  return, 1
	endif else err = 0
      endif else begin
        ; check if path is valid
        openw, lun, filename, error=err, /get_lun
	if err eq 0 then begin
	  close, lun
	  free_lun, lun
        endif
      endelse
      if err eq 0 then begin
        ; Get the image data and deref the move image and get its header.
	case type of
	0: begin
	   dat = *(sinfo.rpgaussim1)
	   strdat = 'Raw Data'
	   end
	1: begin
	   dat = *(sinfo.rpgaussim2)
	   strdat = '2D Gaussian Fit'
	   end
	2: begin
	   dat = *(sinfo.rpgaussim1) - *(sinfo.rpgaussim2)
	   strdat = 'Residual Image (Raw - Gaussian Fit)'
	   end
	else: begin
	   dat = 0.
	   strdat = ' '
           end
	endcase
        moveim = sinfo.moveimage
	ims = (*sinfo.images)
	sfits = sinfo.sfits
	ref = (*sinfo.images)[moveim]
	phdr = *(*ref).phead
	ihdr = *(*ref).ihead
	imsz = size(dat)
	fsz = [imsz[1], imsz[2]]
	i1 = 0
	i2 = n_elements(ims)-1
	if sinfo.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	  else str = 'Flux Conserved'
	idp3_sethdr, ims, moveim, sfits, phdr, ihdr, fsz, i1, i2, str

	; save history records about fitting
	sxaddpar, phdr, 'HISTORY', strdat
	str2 = 'Original image coordinates  X: ' + strtrim(string(x1),2) + $
	  ' - ' + strtrim(string(x2),2) + '  Y: ' + strtrim(string(y1),2) + $
	  ' - ' + strtrim(string(y2),2)
	sxaddpar, phdr, 'HISTORY', str2
	xcen = sinfo.cent.gfx
	ycen = sinfo.cent.gfy
	errx = sinfo.cent.errgfx
	erry = sinfo.cent.errgfy
	str3 = 'Gaussian Center  X: ' + strtrim(string(xcen),2) + $
	    '(' + strtrim(string(errx),2) + ')' + $
	    '  Y: ' + strtrim(string(ycen),2) + $
            '(' + strtrim(string(erry),2) + ')'
        sxaddpar, phdr, 'HISTORY', str3
	majfwhm = sinfo.cent.fwhmx > sinfo.cent.fwhmy
	minfwhm = sinfo.cent.fwhmy < sinfo.cent.fwhmx
	str4 =  'Gaussian FWHM  Major axis: ' + $
	   strtrim(string(majfwhm),2) + '  Minor axis: ' + $
	   strtrim(string(minfwhm),2)
        sxaddpar, phdr, 'HISTORY', str4
        str5 = 'Rotation angle of the ellipse: ' + $
	  strtrim(string(sinfo.cent.theta),2)
        sxaddpar, phdr, 'HISTORY', str5

        ; Write out the result.
	ua_fits_open, filename, fcb, /write
	if n_elements(ihdr) le 2 then begin
          ua_fits_write, fcb, dat, phdr, /NOEXTEND
        endif else begin
	  ua_fits_write, fcb, 0, phdr
	  ua_fits_write, fcb, dat, ihdr, extname='SCI', extver=1
        endelse
	ua_fits_close, fcb
        return, 0
      endif else begin
	disk = ''
	path = ''
	return, -1
      endelse
 end
