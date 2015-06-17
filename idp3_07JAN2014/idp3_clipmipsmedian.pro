pro idp3_clipmipsmedian, info, output, soutput

   pp = 'M'
   idp3_mipsmset, pp, info, data, mask, phdr, ihdr
   ez = info.exclude_invalid
   ev = info.invalid
   sig1 = info.negsig
   if sig1 gt 0. then sig1 = sig1 * (-1.0)
   sig2 = info.possig
   if sig1 eq 0. and sig2 eq 0. then sig = 0 else sig = 1
   dsz = size(data)
   if dsz[0] eq 3 then begin
     maxx = dsz[1]
     maxy = dsz[2]
     numimages = dsz[3]
     str = 'Clipmipsmedian: num images ' + string(numimages)
     idp3_updatetxt, info, str
     final = fltarr(maxx, maxy)
     stddev = fltarr(maxx, maxy)
     final[*,*] = 0.
     stddev[*,*] = 0.
     for j = 0, maxy-1 do begin
       for i = 0, maxx-1 do begin
         arr = data[i,j,*]
	 msk = mask[i,j,*]
	 if ez eq 1 then begin
	   good = where(msk eq 1 and arr ne ev, count)
         endif else begin
	   good = where(msk eq 1, count)
         endelse
         if count gt 0 then begin
	   newarr = arr[good]
	   amed = median(newarr,/even)
	   if sig eq 0 then begin
	     final[i,j] = amed
	     if count gt 1 then stddev[i,j] = $
	       sqrt(total((newarr-amed)^2) / float(count-1))
           endif else begin
	     if count lt 5 then begin
	       final[i,j] = median(newarr, /even)
	       if count gt 1 then stddev[i,j] = $
		 sqrt(total((newarr-amed)^2) / float(count-1))
             endif else begin
	       asig = sqrt(total((newarr-amed)^2) / float(count-1))
	       dmask = intarr(count)
	       dmask[*] = 1
	       bad1 = where(newarr-amed lt sig1*asig, nbad1)
               if nbad1 gt 0 then dmask[bad1] = 0 
	       bad2 = where(newarr-amed gt sig2*asig, nbad2)
               if nbad2 gt 0 then dmask[bad2] = 0
	       goodpix = where(dmask eq 1, ngood)
	       if ngood gt 0 then begin
		 final[i,j] = median(newarr[goodpix], /even)
		 if ngood gt 1 then stddev[i,j] = $
                   sqrt(total((newarr[goodpix]-final[i,j])^2) / float(ngood-1))
               endif
             endelse
           endelse
         endif else begin
	   final[i,j] = 0.
         endelse
       endfor
     endfor
     str = string(numimages) + ' median combined'
     sxaddpar, phdr, 'HISTORY', str
     str = ' negative limit = ' + strtrim(string(sig1),2) + $
       '  positive limit = ' + strtrim(string(sig2),2)
     sxaddpar, phdr, 'HISTORY', str
     ua_fits_open, output, dfcb, /write
     ua_fits_open, soutput, sfcb, /write
     if info.sfits eq 0 and n_elements(ihdr) gt 2 then begin
       ua_fits_write, dfcb, 0, phdr
       ua_fits_write, dfcb, final, ihdr, extname='SCI', extver=1
       ua_fits_write, sfcb, 0, phdr
       ua_fits_write, sfcb, stddev, ihdr, extname='SCI', extver=1
     endif else begin
       ua_fits_write, dfcb, final, phdr
       ua_fits_write, sfcb, stddev, phdr
     endelse
     ua_fits_close, dfcb
     ua_fits_close, sfcb
     str = 'Clipmipsmedian:  files: ' + output + ', ' + soutput + $
	  ' written to disk'
     idp3_updatetxt, info, str
     final = 0
     data = 0
     stddev = 0
 endif
end
