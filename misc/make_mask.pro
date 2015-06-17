
FUNCTION make_mask, mask0, maskList
  ;; to Make a mask from a series of annuli
  ;; mask0 is the original mask, it can be set according to cosmic ray
  ;; header
  ;; maskList is a 4 * n array, contains n masks
  ;; if mask[3, i] = 0, mask[i] is a circle, centered at (mask[0, i],
  ;; mask[1, i]), with inner radius of mask[2, i], and outer radius of
  ;; mask[3, i]
  
  sizeMaskList = size(maskList)
  sizeMask = (size(mask0))[1:2] ;; size of the original mask
  mask = mask0
  meshgrid, sizeMask[0], sizeMask[1], xx, yy
  
  IF sizeMaskList[1] NE 4 THEN BEGIN
     print, 'wrong format for sizeMask'
     return, mask0
  ENDIF
  
  IF sizeMaskList[0] EQ 1 THEN BEGIN
     dist = sqrt((xx - maskList[0])^2 + (yy - maskList[1])^2)
     mask[where((dist gE maskList[2]) AND (dist LE maskList[3]))] = 0
  ENDIF ELSE BEGIN
     FOR i=0, sizeMaskList[2] - 1 DO BEGIN
        dist = sqrt((xx - maskList[0, i])^2 + (yy - maskList[1, i])^2)
        mask[where((dist gE maskList[2, i]) AND (dist LE maskList[3, i]))] = 0
     ENDFOR 
  ENDELSE
  return, mask  
END
