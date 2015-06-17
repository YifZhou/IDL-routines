function idp3_saveimage,event,saveinfo,filename,x1,x2,y1,y2,rsave=rsave, $
	  rpsave=rpsave, rmsave=rmsave
@idp3_structs
     
      if n_elements(rsave) eq 0 then rsave = 0
      if n_elements(rpsave) eq 0 then rpsave = 0
      if n_elements(rmsave) eq 0 then rmsave = 0
      ; decompose string and check if file extension is given
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.fits'

      imageon = 0
      ims = (*saveinfo.images)
      im = saveinfo.moveimage
      for i = 0, n_elements(ims)-1 do begin
	if (*ims[i]).vis eq 1 then imageon = imageon + 1
      endfor
      if imageon gt 0 then begin
        ; check if file already exists, if so query if wish to overwrite
        temp = file_search (filename, Count = fcount)
        if fcount gt 0 then begin
	  idp3_selectval,event.top,'Do you wish to overwrite existing file?',$
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
	  roi = saveinfo.roi
	  sfits = saveinfo.sfits
	  if rpsave eq 0 and rmsave eq 0 then begin
            ; Get the image data and deref the move image and get its header.
            dat  = (*saveinfo.dispim)[x1:x2, y1:y2]
	    if rsave eq 1 then begin
	      if (*roi).msk eq 1 then begin
	        sz = size(*(*roi).mask)
	        x2m = x2 < (sz[1]-1)
	        y2m = y2 < (sz[2]-1)
	        xm = abs(x2m-x1)+1
	        ym = abs(y2m-y1)+1
	        tmpmsk = (*(*roi).mask)[x1:x2m,y1:y2m]
	        bad = where(tmpmsk ne (*roi).maskgood, cnt)
	        if cnt gt 0 then dat[bad] = 0.
              endif
	      zoom = (*roi).roizoom
	      if zoom ne 1 then begin
	        xsize = (abs(x2-x1)+1) * zoom
	        ysize = (abs(y2-y1)+1) * zoom
	        ztype = saveinfo.roiioz
	        pixorg = saveinfo.pixorg
	        ndat = idp3_congrid(dat,xsize,ysize,zoom,ztype,pixorg)
	        dat = ndat
              endif
            endif
          endif else if rpsave eq 1 then begin
	    dat = (*saveinfo.radpfim)
          endif else begin
	    dat = (*saveinfo.rcollapsim)
          endelse
	  lim1 = 0
	  lim2 = n_elements(ims)-1
	  sz = size(dat)
	  dsz = [sz[1],sz[2]]
	  if saveinfo.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	    else str = 'Flux Conserved'
	  idp3_sethdr, ims, im, sfits, phead, ihead, dsz, lim1, lim2, str

	  ; if x1 ne 0 then save origin in header
          if rsave eq 1 or rpsave eq 1 or rmsave eq 1 then begin
	    sxaddpar, phead, 'ROIXORIG', x1
	    sxaddpar, phead, 'ROIYORIG', y1
	    sxaddpar, phead, 'ROIXEND', x2
	    sxaddpar, phead, 'ROIYEND', y2
	    if saveinfo.zoomflux eq 0 then str = 'Flux not conserved' else $
	      str = 'Flux conserved'
	    sxaddpar, phead, 'ROIZOOM', (*roi).roizoom, str
          endif

	  if rpsave eq 1 then begin
	    zoom = (*roi).roizoom
	    xc = (*roi).radxcent / zoom + x1
	    yc = (*roi).radycent / zoom + y1
	    rad = (*roi).radradius / zoom
	    sxaddpar, phead, 'HISTORY', '2-D image of a radial profile' 
	    str = 'With Center = ' + strtrim(string(xc),2) + $
		   '  ' + strtrim(string(yc),2)
	    sxaddpar, phead, 'HISTORY', str 
	    str = 'and Radius = ' + strtrim(string(rad),2)
          endif

	  if rmsave eq 1 then begin
	    if (*roi).msk eq 1 then begin
	      str = (*roi).maskname + ' mask applied to data'
	      sxaddpar, phead, 'HISTORY', str
            endif
            if (*roi).collapse_dir eq 0 then str = 'Row ' else str = 'Column '
	    if (*roi).collapse_type eq 0 then str = str + 'Median 1D Image' $
	      else str = str + 'Mean 1D Image'
            sxaddpar, phead, 'HISTORY', str
          endif

          ; Write out the result.
	  ua_fits_open, filename, fcb, /write
	  if n_elements(ihead) le 2 then begin
            ua_fits_write, fcb, dat, phead, /NOEXTEND
          endif else begin
	    ua_fits_write, fcb, 0, phead
	    ua_fits_write, fcb, dat, ihead, extname='SCI', extver=1
          endelse
	  ua_fits_close, fcb
          return, 0
        endif else begin
	  disk = ''
	  path = ''
	  return, -1
        endelse
     endif else begin
       stat = Widget_Message('No image to save!')
     endelse
 end
