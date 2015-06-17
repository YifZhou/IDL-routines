pro idp3_photcircle, fmask, tmp, nang, thresh, rad, zr, zxcen, zycen, mpol, $
		 nbad, ixsz, iysz
  
   nbad = 0
   zledge = zxcen - zr
   zredge = zxcen + zr
   zbottom = zycen - zr
   ztop = zycen + zr
   zlf = floor(zledge) > 0.
   zrc = ceil(zredge) < (ixsz-1)
   zbf = floor(zbottom) > 0.
   ztc = ceil(ztop) < (iysz-1)
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
       endif else begin
	 if r le zr then nbad = nbad + 1
       endelse
     endfor
   endfor
end
