function idp3_congrid, array, xsize, ysize, zoom, ztype, po

  if zoom ne 1.0 then begin
    zcubic = -0.5
    sz = size(array)
    if sz[0] lt 2 or sz[1] lt 2 or sz[2] lt 2 then begin
      res = Dialog_Message('image too small to zoom')
      return, array
    endif
    CASE ztype of
    0: Begin
      zarray =congrid(array, xsize, ysize, cubic=zcubic)
      if po eq 1 then begin
        zoff = FIX(zoom/2. + 0.5)
        tempz = fltarr(xsize, ysize)
        tempz(zoff:xsize-1,zoff:ysize-1) = zarray[0:xsize-zoff-1,0:ysize-zoff-1]
        zarray = tempz
        tempz = 0
      endif
      end
    1: Begin
      zarray = congrid(array, xsize, ysize, /interp)
      if po eq 1 then begin
        zoff = FIX(zoom/2. + 0.5)
        tempz = fltarr(xsize, ysize)
        tempz(zoff:xsize-1,zoff:ysize-1) = zarray[0:xsize-zoff-1,0:ysize-zoff-1]
        zarray = tempz
        tempz = 0
      endif
      end
   2: Begin
      zarray = congrid(array, xsize, ysize)
      end
   3: Begin
      zarray = idp3_spline(array, xsize, ysize)
      if po eq 1 then begin
	zoff = FIX(zoom/2. + 0.5)
	tempz = fltarr(xsize, ysize)
	tempz(zoff:xsize-1,zoff:ysize-1) = zarray[0:xsize-zoff-1,0:ysize-zoff-1]
	zarray = tempz
	tempz = 0
      endif
      end
   else: Begin
      zarray =congrid(array, xsize, ysize, cubic=zcubic)
      if po eq 1 then begin
        zoff = FIX(zoom/2. + 0.5)
        tempz = fltarr(xsize, ysize)
        tempz(zoff:xsize-1,zoff:ysize-1) = zarray[0:xsize-zoff-1,0:ysize-zoff-1]
        zarray = tempz
        tempz = 0
      endif
      end
    endcase
  endif else begin
    zarray = array
  endelse
  return, zarray

END
