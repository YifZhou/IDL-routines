function idp3_getolcc, im, lccx, lccy, xo, yo

  olccx = lccx
  olccy = lccy

  ; pixel shifts
  xoff = (*im).xpoff + (*im).xoff + xo
  if abs(xoff) gt 0.0 then olccx = olccx - xoff
  yoff = (*im).ypoff + (*im).yoff + yo
  if abs(yoff) gt 0.0 then olccy = olccy - yoff
 
  ; rotation
  rota = (*im).rot * (-1.0)
  if abs(rota) ne 0.0 then begin
    ; update the rotation center
    cdr = !DPI/180.0d0
    theta = rota * cdr
    rotx = (*im).rotcx
    roty = (*im).rotcy
    if (*im).flipy eq 1 then begin
      tempsz = size(*(*im).data)
      roty = tempsz[2] - roty - 1
    endif
    if (*im).topad eq 1 and (*im).pad gt 0 then begin
      rotx = rotx + (*im).pad
      roty = roty + (*im).pad
    endif
    if (*im).xpscl ne 1.0 then begin
      rotx = rotx * (*im).xpscl
    endif
    if (*im).ypscl ne 1.0 then begin
      roty = roty * (*im).ypscl
    endif
    if (*im).zoom ne 1.0 then begin
      rotx = rotx * (*im).zoom
      roty = roty * (*im).zoom
    endif
    rotc = [rotx, roty]
    rot_mat = [[ cos(theta), sin(theta)], $
  	       [-sin(theta), cos(theta)]]
    nlcc = rotc + transpose(rot_mat)#([olccx,olccy]-rotc) 
    olccx = nlcc[0]
    olccy = nlcc[1]
  endif

  ; zoom
  fact = 1.0 / (*im).zoom
  olccx = olccx * fact
  olccy = olccy * fact

  ; pixel scale
  xfact = 1.0 / (*im).xpscl
  yfact = 1.0 / (*im).ypscl
  olccx = olccx * xfact
  olccy = olccy * yfact

  ; image pad
  olccx = olccx - (*im).pad
  olccy = olccy - (*im).pad

  ;flip y axis
  if (*im).flipy eq 1 then begin
    tempsz = size((*im).data)
    olccy = tempsz[2] - olccy - 1
  endif

  olcc = [olccx, olccy]
  return, olcc

end
