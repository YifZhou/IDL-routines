; IDP3_Alignxy -- Align the images based on the stored x,y centers.

pro Idp3_Alignxy,event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to align
    return
  endif

  numimages = n_elements(*info.images)

  ; Get the position of the 'move' image center.
  moveim = info.moveimage
  micx = (*(*info.images)[moveim]).xpos
  micy = (*(*info.images)[moveim]).ypos
  openw, lun, 'alignxy.txt', width=150, /get_lun
  offx = (*(*info.images)[moveim]).xoff + (*(*info.images)[moveim]).xpoff
  offy = (*(*info.images)[moveim]).yoff + (*(*info.images)[moveim]).ypoff
  fname = (*(*info.images)[moveim]).name
  ua_decompose, fname, disk, path, name, extn, version
  printf, lun, name, micx, micy, offx, offy 
  xoffar = fltarr(numimages)
  yoffar = fltarr(numimages)
  xoffar[*] = -99999.0
  yoffar[*] = -99999.0
  xoffar[moveim] = offx
  yoffar[moveim] = offy

  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).xpos ne -1.0 and (*(*info.images)[i]).vis eq 1 $
      and i ne info.moveimage then begin
      deltax = micx - (*(*info.images)[i]).xpos
      deltay = micy - (*(*info.images)[i]).ypos

      tempxoff= (*(*info.images)[i]).xoff + (*(*info.images)[i]).xpoff + deltax
      tempyoff= (*(*info.images)[i]).yoff + (*(*info.images)[i]).ypoff + deltay
      xoffar[i] = tempxoff
      yoffar[i] = tempyoff
    endif
  endfor
  good = where(xoffar gt -9999.0, count)
  xadj = min(xoffar[good])
  yadj = min(yoffar[good])
  if xadj lt 0.0d0 then ixadj = fix(abs(xadj)+1) else ixadj = 0
  if yadj lt 0.0d0 then iyadj = fix(abs(yadj)+1) else iyadj = 0
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then begin
      tempxoff = xoffar[i] + double(ixadj)
      tempyoff = yoffar[i] + double(iyadj)
      fracsa = tempxoff - float(fix(tempxoff))
      intsa  = float(fix(tempxoff - fracsa))
      (*(*info.images)[i]).xpoff = fracsa
      (*(*info.images)[i]).xoff = intsa
      fracsa = tempyoff - float(fix(tempyoff))
      intsa  = float(fix(tempyoff - fracsa))
      (*(*info.images)[i]).ypoff = fracsa
      (*(*info.images)[i]).yoff = intsa
      fname = (*(*info.images)[i]).name
      ua_decompose, fname, disk, path, name, extn, version
      printf, lun, name, string(tempxoff,'$(f12.4)'), $
	  string(tempyoff, '$(f12.4)')
    endif
  endfor
  close, lun
  free_lun, lun
  idp3_display,info

  Widget_control,info.idp3Window,Set_UValue=info
;  Widget_control,event.top,Set_UValue=tinfo

end

