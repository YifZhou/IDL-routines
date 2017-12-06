;+
; NAME:
;	FFTSHIFT - shift a 2D image by any value via a FFT.
;
; CATEGORY:
;	Array and Image Processing Routines
;
; CALLING SEQUENCE:
;	new_image = fftshift(IMG, XSHIFT, YSHIFT)
;
; PURPOSE:
;   The functions shifts an image by any subpixel value using FFT.
;
;   The image must be square and of even width.
;
; PARAMETERS:
;	IMAGE - image to be shifted
;
;	XSHIFT - amount of shift in x
;	
;	YSHIFT - amount of shift in y
;
; -

FUNCTION fftshift, image, xshift, yshift
  on_error,2
  
  sz = size(image)
  NX = sz[1]           ;; image assumed square NXxNX and NX additionally assumed even
  NY = sz[2]           ;; Number of Lines in the image

  IF ((NX NE NY) OR ((NX MOD 2) NE 0)) THEN $ 
     message, 'SUBPIXEL_SHIFT only works on square images of even width.'

  x_ramp = (dblarr(NX)+1D)##(dindgen(NX)-NX/2)  ;; ramp along x
  y_ramp = (dindgen(NX)-NX/2)##(dblarr(NX)+1D)  ;; ramp along y

  tilt = (-2D*!dpi/double(NX)) *(double(xshift)*x_ramp+double(yshift)*y_ramp)

  nimage = real_part(fft(fft(image, -1) * $
                         shift(dcomplex(cos(tilt),sin(tilt)), -NX/2, -NX/2),1))

  return, nimage

END
