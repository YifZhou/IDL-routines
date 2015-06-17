;+
; NAME:
;
;
;
; PURPOSE:
;
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
;-
FUNCTION my_shift2d, im, dx, dy, cubic = cubic
  sz = size(im)
  xlen = sz[1]
  ylen = sz[2]
  x0 = findgen(xlen)
  y0 = findgen(ylen)
  xnew = x0 - dx
  xnew = xnew - xlen * floor(xnew / xlen)
  ynew = y0 - dy
  ynew = ynew - ylen * floor(ynew / ylen)
  IF keyword_set(cubic) THEN BEGIN
     cubic = -0.5
     imnew = interpolate(im, xnew, ynew, /grid, cubic=cubic)
  ENDIF ELSE BEGIN
     imnew = interpolate(im, xnew, ynew, /grid)
  ENDELSE  
  return, imnew  
END
  
