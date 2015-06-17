pro idp3_undolast, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  ims = info.images

  ; If there are no images, return
  if n_elements(*ims) lt 1 then return

  ; get reference image
  imptr = (*ims)[info.moveimage]
;  if n_elements(imptr) lt 2 then return
  if (*imptr).vis ne 1 then begin
    stat = Widget_Message('Cannot undo last edit, Reference Image not ON')
    return
  endif
  if ptr_valid((*imptr).xedit) then begin
    xedit = *(*imptr).xedit
    yedit = *(*imptr).yedit
    zedit = *(*imptr).zedit

    num = n_elements(xedit)
    if num eq 1 then begin
      ptr_free, (*(*info.images)[info.moveimage]).xedit
      ptr_free, (*(*info.images)[info.moveimage])(*imptr).yedit
      ptr_free, (*(*info.images)[info.moveimage])(*imptr).zedit
    endif else begin
      xedit = xedit[0:num-2]
      yedit = yedit[0:num-2]
      zedit = zedit[0:num-2]
      (*(*info.images)[info.moveimage]).xedit = ptr_new(xedit)
      (*(*info.images)[info.moveimage]).yedit = ptr_new(yedit)
      (*(*info.images)[info.moveimage]).zedit = ptr_new(zedit)
    endelse
  endif else begin
    str = 'UndoEdits: Nothing to undo!'
    idp3_updatetxt, info, str
    return
  endelse

  idp3_display, info
  Widget_Control, event.top, Set_UValue=info
  Widget_Control, info.idp3Window, Set_UValue=info
end

