; IDP3_undo_auto_flux_scl - reset image flux scale 

pro Idp3_undo_auto_flux_scl,event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to scale
    return
  endif

  numimages = n_elements(*info.images)

  for i = 0, numimages-1 do begin
    im = (*info.images)[i]
    if (*im).vis eq 1 then begin
      (*im).scl = (*im).oldscl 
    endif
  endfor
  idp3_display,info

  Widget_control,info.idp3Window,Set_UValue=info
;  Widget_control,event.top,Set_UValue=tinfo

end
