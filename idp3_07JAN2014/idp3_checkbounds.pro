
; CheckBounds -- Determine where the data image overlaps the graphics field.
;   When the bounds of the data image and the overlap region of the graphics
;   field have been determined, check the calculations again for
;   off-the-edge-of-the-image errors.

pro idp3_checkbounds,dxs,dys,xsiz,ysiz,xoff,yoff,dxmin,dxmax,dymin,dymax, $
		     gxmin,gxmax,gymin,gymax,err

@idp3_errors

err = 0

  if xoff+xsiz-1 gt dxs then begin
    gxmax = dxs-1
    dxmax = xsiz-((xoff+xsiz-1)-dxs)-2
  endif else begin
    gxmax = xoff+xsiz-1
    if gxmax gt dxs-1 then gxmax = dxs-1
    dxmax = xsiz-1
  endelse

  if xoff lt 0 then begin
    gxmin = 0
    dxmin = -xoff
  endif else begin
    gxmin = xoff
    dxmin = 0
  endelse

  if gxmax le gxmin then begin
    err = -1
    return
  endif

  if yoff+ysiz-1 gt dys then begin
    gymax = dys-1
    dymax = ysiz - ((yoff+ysiz-1)-dys) - 2
  endif else begin
    gymax = yoff+ysiz-1
    if gymax gt dys-1 then gymax = dys-1
    dymax = ysiz-1
  endelse

  if yoff lt 0 then begin
    gymin = 0
    dymin = -yoff
  endif else begin
    gymin = yoff
    dymin = 0
  endelse

  if gymax le gymin then begin
    err = -2
    return
  end

  if gxmax-gxmin ne dxmax-dxmin then begin
    dxmax = dxmin + gxmax-gxmin
  endif
  if gymax-gymin ne dymax-dymin then begin
    dymax = dymin + gymax-gymin
  endif


  ; Check for off-the-edge-of-the-image errors.
  if dxmax gt xsiz then dxmax = xsiz
  if dxmin gt xsiz then dxmin = xsiz
  if dxmin lt 0 then dxmin = 0
  if dxmax lt 0 then dxmax = 0
  if gxmax gt dxs-1 then gxmax = dxs-1
  if gxmin gt dxs-1 then gxmin = dxs-1
  if gxmin lt 0 then gxmin = 0
  if gxmax lt 0 then gxmax = 0

  if dymax gt ysiz then dymax = ysiz
  if dymin gt ysiz then dymin = ysiz
  if dymin lt 0 then dymin = 0
  if dymax lt 0 then dymax = 0
  if gymax gt dys-1 then gymax = dys-1
  if gymin gt dys-1 then gymin = dys-1
  if gymin lt 0 then gymin = 0
  if gymax lt 0 then gymax = 0

end
