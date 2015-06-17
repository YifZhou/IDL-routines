pro idp3_cd2cdelt,cd11,cd12,cd21,cd22,cdelt1,cdelt2,crota
;
; procedure to convert CD-Matrix to cdelts (x-pixel size and y-pixel size)
; and rotation angle.  Pixel sizes and rotation angle are in degrees.
;
  cdelt1 = sqrt(cd11^2 + cd21^2)
  cdelt2 = sqrt(cd12^2 + cd22^2)
  if ((cd11*cd22-cd12*cd21) lt 0.0) then begin
    cdelt1 = -cdelt1
  endif

  if (cdelt1 lt 0.0) then begin
    crota = double(180.0/!pi*atan (-cd12,cd22))
  endif else begin
    crota = double(180.0/!pi*atan (cd12,cd22))
  endelse

end
