
; Fractional pixel shift using VERY simple bilinear interpolation.

function fracshift,image,xshift,yshift
  thesize = size (image)
  xs = thesize(1)
  ys = thesize(2)
  w1 = (1.0-abs(xshift)) * (1.0-abs(yshift))
  w2 =      abs(xshift)  * (1.0-abs(yshift))
  w3 =      abs(xshift)  *      abs(yshift)
  w4 = (1.0-abs(xshift)) *      abs(yshift)
  im1 = w1 * image
  if (xshift lt 0.0) then begin
    im2 = w2 * shift(image,-1,0)
    im2(xs-1,*) = im2(xs-2,*)
  endif else begin
    im2 = w2 * shift(image,1,0)
    im2(0,*) = im2(1,*)
  endelse
  if (xshift lt 0.0 and yshift lt 0.0) then begin
    im3 = w3 * shift(image,-1,-1)
    im3(xs-1,*) = im3(xs-2,*)
    im3(*,ys-1) = im3(*,ys-2)
  endif else if (xshift lt 0.0 and yshift gt 0.0) then begin
    im3 = w3 * shift(image,-1,1)
    im3(xs-1,*) = im3(xs-2,*)
    im3(*,0) = im3(*,1)
  endif else if (xshift gt 0.0 and yshift gt 0.0) then begin
    im3 = w3 * shift(image,1,1)
    im3(0,*) = im3(1,*)
    im3(*,0) = im3(*,1)
  endif else begin
    im3 = w3 * shift(image,1,-1)
    im3(0,*) = im3(1,*)
    im3(*,ys-1) = im3(*,ys-2)
  endelse
  if (yshift lt 0.0) then begin
    im4 = w4 * shift(image,0,-1)
    im4(*,ys-1) = im4(*,ys-2)
  endif else begin
    im4 = w4 * shift(image,0,1)
    im4(*,0) = im4(*,1)
  endelse
  return, im1+im2+im3+im4
end

