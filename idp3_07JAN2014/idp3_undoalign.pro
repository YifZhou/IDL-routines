
; IDP3_UndoAlign -- undo alignment done based on last stored centroid
; centers

pro Idp3_UndoAlign,event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to fix
    return
  endif

  refim = info.moveimage
  numimages = n_elements(*info.images)

  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then begin
       (*(*info.images)[i]).xpoff = 0.
       (*(*info.images)[i]).xoff = 0
       (*(*info.images)[i]).ypoff = 0.
       (*(*info.images)[i]).yoff = 0
    endif
  endfor

  idp3_display,info

  Widget_Control,info.idp3Window,Set_UValue=info

end

