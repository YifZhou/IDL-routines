; IDP3_Alignwcs -- Align the images based on their world coordinates.

pro Idp3_Alignwcs,event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to align
    return
  endif

  numimages = n_elements(*info.images)
  numon = 0
  moveim = info.moveimage
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then numon = numon + 1
  endfor
  if numon le 1 or (*(*info.images)[moveim]).vis eq 0 then begin
    str = 'AlignWCS: Cannot align, REF image and at least one other must be ON'
    idp3_updatetxt, info, str
    return
  endif
  xoffar = dblarr(numimages)
  yoffar = dblarr(numimages)
  xoffar[*] = -99999.0d0
  yoffar[*] = -99999.0d0
  openw, lun, 'alignwcs.txt', /get_lun

  ; Get the wcs of the 'move' image.
  if (*(*info.images)[moveim]).vis eq 1 then begin
    refcrval1 = (*(*info.images)[moveim]).acrval1
     refcrval2 = (*(*info.images)[moveim]).acrval2
    cd11 = (*(*info.images)[moveim]).acd11
    cd12 = (*(*info.images)[moveim]).acd12
    cd21 = (*(*info.images)[moveim]).acd21
    cd22 = (*(*info.images)[moveim]).acd22
    offx = (*(*info.images)[moveim]).xoff
    poffx = (*(*info.images)[moveim]).xpoff
    offy = (*(*info.images)[moveim]).yoff
    poffy = (*(*info.images)[moveim]).ypoff
    fname = (*(*info.images)[moveim]).name
    ua_decompose, fname, disk, path, name, extn, version
    printf, lun, info.header_char, 'Computed offsets'
    printf, lun, name, string(offx+poffx,'$(f12.4)'), $
       string(offy+poffy,'$(f12.4)')
    xoffar[moveim] = offx + poffx
    yoffar[moveim] = offy + poffy
  endif else begin
    test = Widget_Message('Cannot Align, Reference image not on')
    return
  end
  ; compute offsets based on world coordinates
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).crval1 ne -1.0 and (*(*info.images)[i]).vis eq 1 $
      and i ne moveim  then begin
      crval1 = (*(*info.images)[i]).acrval1
      crval2 = (*(*info.images)[i]).acrval2
      idp3_pixoffset, cd11, cd12, cd21, cd22, refcrval1, refcrval2, $
		 crval1, crval2, xdeltax, xdeltay
      offx = (*(*info.images)[i]).xoff
      poffx = (*(*info.images)[i]).xpoff
      offy = (*(*info.images)[i]).yoff
      poffy = (*(*info.images)[i]).ypoff
      tempxoff= offx + poffx + xdeltax
      tempyoff= offy + poffy + xdeltay
      fname = (*(*info.images)[i]).name
      ua_decompose, fname, disk, path, name, extn, version
      printf, lun, name, string(tempxoff,'$(f12.4)'), $
	 string(tempyoff, '$(f12.4)')
      xoffar[i] = tempxoff
      yoffar[i] = tempyoff
    endif
  endfor
  good = where(xoffar gt -99999.0d0, count)
  if info.adjnegoff eq 1 then begin
    xadj = min(xoffar[good])
    yadj = min(yoffar[good])
    if xadj lt 0.0d0 then ixadj = fix(abs(xadj)+1) else ixadj = 0
    if yadj lt 0.0d0 then iyadj = fix(abs(yadj)+1) else iyadj = 0
    ; adjust offsets according to most negative shift
    printf, lun, info.header_char, 'adjusted offsets', ixadj, iyadj
  endif else begin
    ixadj = 0
    iyadj = 0
  endelse
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then begin
      tempxoff = xoffar[i] + double(ixadj)
      tempyoff = yoffar[i] + double(iyadj)
      fracsa = Double(tempxoff) - Double(fix(tempxoff))
      intsa  = Double(fix(tempxoff - fracsa))
      (*(*info.images)[i]).xpoff = float(fracsa)
      (*(*info.images)[i]).xoff = float(intsa)
      fracsa = Double(tempyoff) - Double(fix(tempyoff))
      intsa  = Double(fix(tempyoff - fracsa))
      (*(*info.images)[i]).ypoff = float(fracsa)
      (*(*info.images)[i]).yoff = float(intsa)
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

