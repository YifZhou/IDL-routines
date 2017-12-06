function jhrangmask, image



;Get the dimensions of a single frame
x = (size(image))(1)
y = (size(image))(2)

x = double(x)
y = double(y)

;Make sure array is square
 x = min([x,y])
 y =x
 
  anglemask = image  ; use the first image in cube to create mask

;Define Mask by Pixel
for xx=0, x-1 do begin
  for yy=0, y-1 do begin

     ;Define angle on just the axes
     if yy eq y/2. and xx ge x/2. then anglemask[xx,yy] = 0.
     if xx eq x/2. and yy ge y/2. then anglemask[xx,yy] = !pi/2.
     if yy eq y/2. and xx le x/2. then anglemask[xx,yy] = !pi
     if xx eq x/2. and yy le y/2. then anglemask[xx,yy] = 3.*!pi/2.

     ;Define angles where atan is defined (4 cases because atan is not unique)
     if xx gt x/2. and yy gt y/2. then anglemask[xx,yy] = atan((yy-y/2.)/(xx-x/2.))
     if xx lt x/2. and yy gt y/2. then anglemask[xx,yy] = atan((x/2.-xx)/(yy-y/2.))+!pi/2.
     if xx lt x/2. and yy lt y/2. then anglemask[xx,yy] = atan((y/2.-yy)/(x/2.-xx))+!pi
     if xx gt x/2. and yy lt y/2. then anglemask[xx,yy] = atan((xx-x/2.)/(y/2.-yy))+3.*!pi/2.

  endfor
endfor

;writefits, 'anglemask.fits',anglemask

print, '--[ SEARCH_ZONES    ]-- ANGLE MASK COMPLETE'


return, anglemask
end
