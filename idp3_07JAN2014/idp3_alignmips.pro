
; IDP3_AlignMips -- Align MIPS images based on the stored last centroid centers.

pro Idp3_AlignMIPS,event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to align
    return
  endif

  numimages = n_elements(*info.images)

  ; Get the position of the 'move' image centroid.
  moveim = info.moveimage
  micx = (*(*info.images)[moveim]).lccx
  micy = (*(*info.images)[moveim]).lccy
  openw, lun, 'alignmips.txt', width=120, /get_lun
  offx = (*(*info.images)[moveim]).xoff + (*(*info.images)[moveim]).xpoff
  offy = (*(*info.images)[moveim]).yoff + (*(*info.images)[moveim]).ypoff
  fname = (*(*info.images)[moveim]).name
  ua_decompose, fname, disk, path, name, extn, version
  printf, lun, name, micx, micy, offx, offy 

  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).lccx ne -1.0 and (*(*info.images)[i]).vis eq 1 $
      and i ne info.moveimage then begin
      deltax = micx - (*(*info.images)[i]).lccx
      deltay = micy - (*(*info.images)[i]).lccy

      tempxoff=deltax ;+(*(*info.images)[i]).xoff + (*(*info.images)[i]).xpoff
      tempyoff=deltay ;+(*(*info.images)[i]).yoff + (*(*info.images)[i]).ypoff

;      offx = (*(*info.images)[i]).xoff + (*(*info.images)[i]).xpoff
;      offy = (*(*info.images)[i]).yoff + (*(*info.images)[i]).ypoff

      fracsa = float(tempxoff) - float(fix(tempxoff))
      intsa  = float(fix(tempxoff - fracsa))
      (*(*info.images)[i]).xpoff = fracsa
      (*(*info.images)[i]).xoff = intsa

      fracsa = float(tempyoff) - float(fix(tempyoff))
      intsa  = float(fix(tempyoff - fracsa))
      (*(*info.images)[i]).ypoff = fracsa
      (*(*info.images)[i]).yoff = intsa
      fname = (*(*info.images)[i]).name
      ua_decompose, fname, disk, path, name, extn, version
      printf, lun, name, (*(*info.images)[i]).lccx, $
	 (*(*info.images)[i]).lccy, tempxoff, tempyoff
    endif
  endfor
  close, lun
  free_lun, lun

  idp3_display,info

  Widget_control,info.idp3Window,Set_UValue=info
;  Widget_control,event.top,Set_UValue=tinfo

end

