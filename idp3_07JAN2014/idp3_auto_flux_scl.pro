; IDP3_auto_flux_scl - flux scale images to reference image

pro Idp3_auto_flux_scl,event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to scale
    return
  endif

  numimages = n_elements(*info.images)

  ; Get the flux scale of the 'move' image..
  moveim = info.moveimage
  refim = (*info.images)[moveim]
  phdr = *(*refim).phead
  ref_filter = strtrim(sxpar(phdr, 'FILTER'),2)
  jykey = ref_filter + '_JY'
  ref_jy = sxpar(phdr, jykey)
  if ref_jy gt 0. then begin
    for i = 0, numimages-1 do begin
      ; build table for all images to preserve indices
      ; check if image is on in second loop, get filter and jy value
      ; build table to use for scaling
      imptr = (*info.images)[i]
      hdr = *(*imptr).phead
      filter = strtrim(sxpar(hdr, 'FILTER'),2)
      jykey = filter + '_JY'
      jy = sxpar(hdr, jykey)
      if n_elements(filters) eq 0 then begin
        filters = filter
        jys = jy
      endif else begin
        filters = [filters, filter]
        jys = [jys, jy]
      endelse
    endfor

    for i = 0, numimages-1 do begin
      im = (*info.images)[i]
      fdecomp, (*im).name, disk, path, tmpname, tmpext
      tmpname = tmpname + '.' + tmpext
      if (*im).vis eq 1 then begin
        if filters[i] eq filters[moveim] then begin
          if jys[i] gt 0. then begin
            (*im).oldscl = (*im).scl
            (*im).scl = jys[moveim] / jys[i]
            str = tmpname + '  ' + string(jys[moveim]) + $
                  string(jys[i]) + string((*im).scl)
            idp3_updatetxt, info, str
            print, str
          endif else begin 
            str = 'Auto Flux Scale: ' + tmpname + ' scaling value not valid'
            idp3_updatetxt, info, str
            print, str
          endelse
        endif else begin
            str = 'Auto Flux Scale: ' + tmpname + '  ' + filters[i] + $
                  ' filter does not match ' + filters[moveim]
            idp3_updatetxt, info, str
            print, str
        endelse
      endif
    endfor
  endif else begin
    test = widget_message('Error: Scale value for reference image not valid')
  endelse
  idp3_display,info

  Widget_control,info.idp3Window,Set_UValue=info
;  Widget_control,event.top,Set_UValue=tinfo

end
