function idp3_roimask, x1roi, x2roi, y1roi, y2roi, mask, xoff, yoff, goodval 

  ; build appropriate mask for this roi
  sz = size(mask)
  szx = sz[1] - 1
  szy = sz[2] - 1
  x1msk = xoff
  y1msk = yoff
  x2msk = x1msk + szx
  y2msk = y1msk + szy
  if x2msk lt 0 or y2msk lt 0 then begin
    stat = Widget_Message('Illegal mask shift')
    tmpmask = intarr((x2roi-x1roi+1),(y2roi-y1roi+1))
    tmpmask[*,*] = goodval
  endif else begin
    bszx = x2msk+1 > (x2roi+1)
    bszy = y2msk+1 > (y2roi+1)
    btmpmsk = intarr(bszx, bszy)
    btmpmsk[*,*] = goodval
    if x1msk gt 0 then begin
      xs1 = 0
      xs2 = szx
      xd1 = x1msk
      xd2 = x2msk
    endif else begin
      xs1 = abs(x1msk)
      xs2 = szx
      xd1 = 0
      xd2 = x2msk
    endelse
    if y1msk gt 0 then begin
      ys1 = 0
      ys2 = szy
      yd1 = y1msk
      yd2 = y2msk
    endif else begin
      ys1 = abs(y1msk)
      ys2 = szy
      yd1 = 0
      yd2 = y2msk
    endelse
    btmpmsk[xd1:xd2,yd1:yd2] = mask[xs1:xs2,ys1:ys2]
    if x1roi ge x2msk or y1roi ge y2msk then begin
      str = 'Mask does not overlap with region of interest'
      stat = Widget_Message(str)
      tmpmask = intarr((x2roi-x1roi+1),(y2roi-y1roi+1))
      tmpmask[*,*] = goodval
    endif else begin
      tmpmask = btmpmsk[x1roi:x2roi,y1roi:y2roi]
    endelse
  endelse
  return, tmpmask
end
