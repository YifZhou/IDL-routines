FUNCTION findPeak, im, x0, y0, range=range
  ;+n
; NAME: findPeak
;
; PURPOSE: use a moffat profile to fit the image to find the centroid
; of a star image
;
; CATEGORY: fit, image processing
;
; CALLING SEQUENCE: cen = findPeak(image, x0, y0, range = range)
;
; INPUTS:
;    x0: initial value OF the centriod in x direction
;    y0: initial value OF the centroid in y direction
; OPTIONAL INPUTS:
;    range: the range of the gaussing profile to fit, default is 10 pixels
;
;
; KEYWORD PARAMETERS:
;    range
;
; OUTPUTS:
;    cen, 2 2d array contains the center of x and y
;
; OPTIONAL OUTPUTS: none
; COMMON BLOCKS: none
; SIDE EFFECTS: make used of mpfit2dpeak routine from cm library
; RESTRICTIONS: not known yet;
; MODIFICATION HISTORY:
;    created by Yifan Zhou on Dec 4, 2014
;-

  IF N_ELEMENTS(range) EQ 0 THEN range = 10
  xlow = floor(x0 - range)
  ylow = floor(y0 - range)
  yfit = mpfit2dpeak(im[xlow:xlow + 2*range, ylow:ylow+2*range], params, /moffat)
  return, [params[4] + xlow, params[5] + ylow]
END
