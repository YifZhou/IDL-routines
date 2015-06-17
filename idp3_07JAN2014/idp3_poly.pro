function idp3_poly, x,y,xs,ys

 mask = intarr(xs,ys)
 mask1 = intarr(xs,ys)
 mask2 = intarr(xs,ys)
 mask[*,*]=0
 mask1[*,*]=0
 mask2[*,*]=0
 datsize = n_elements(x) 
 
 xmin = min(x)
 xmax = max(x)
 ymin = min(y)
 ymax = max(y)

 for i = 1, datsize-1 do begin
   xb = x[i-1]
   xe = x[i]
   yb = y[i-1]
   ye = y[i]
   if ABS(ye-yb) gt 0 and ABS(xe-xb) gt 0 then begin
     a = float(ye-yb) / float(xe-xb)
     b = float(ye) - a*float(xe)
     if (xb gt xe and yb gt ye) OR (xb lt xe and yb lt ye) $
       then adj = 0.0 else adj = 0.5
     if abs(xe - xb) GT abs(yb - ye) then begin
       if xb gt xe then xincr = -1 else xincr = 1
       for j = xb, xe, xincr do begin
          yp = a * float(j) + b
          yi = fix(yp+adj)
          mask1(j,yi) = 1
        endfor
     endif else begin
       if yb gt ye then yincr = -1 else yincr = 1
       for j = yb, ye, yincr do begin
         xp = (float(j) - b) / a
         xi = fix(xp+adj)
         mask1(xi,j) = 1
       endfor
     endelse 
   endif else begin
     if xb eq xe then begin
       y1 = yb < ye
       y2 = ye > yb
       mask1[xb,y1:y2] = 1 
     endif else begin
       x1 = xb < xe
       x2 = xe > xb
       mask1[x1:x2,yb] = 1
     endelse
   endelse
 endfor
 
  mask2(polyfillv(x,y,xs,ys)) = 2
  
  mask = mask1 + mask2
  for i = 0, ys-1 do begin
    line = mask[*,i]
    nozero = where(line gt 0, nzcnt)
    if nzcnt gt 0 then begin
      if line(nozero[0]) eq 2 then line(nozero[0]) = 0
      zero = where(line eq 0, zcnt)
      if zcnt gt 0 then begin
        for j = 0, zcnt-1 do begin
  	  indx = zero(j)
	  if indx le xs-3 then begin
	    if line[indx+1] eq 2 and line[indx+2] eq 3 then line[indx+1] = 0
          endif
	  if indx gt 0 and indx lt xs-1 then begin
	    if line[indx-1] eq 2 and line[indx+1] eq 1 then line[indx] = 1
          endif
        endfor
      endif
      mask[*,i] = line
    endif
  endfor
  
  mask(where(mask gt 1)) = 1

  return, mask
END
