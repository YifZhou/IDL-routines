pro idp3_undoall, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  ims = info.images

  ; If there are no images, return
  if n_elements(*ims) lt 1 then return

  ; get reference image if on
  imptr = (*ims)[info.moveimage]
;  if n_elements(imptr) lt 2 then return
  if (*imptr).vis ne 1 then begin
    stat = Widget_Message('Cannot undo edits, Reference Image not ON')
    return
  endif
  if ptr_valid((*(*info.images)[info.moveimage]).xedit) then begin
    ptr_free, (*(*info.images)[info.moveimage]).xedit
    ptr_free, (*(*info.images)[info.moveimage]).yedit
    ptr_free, (*(*info.images)[info.moveimage]).zedit
  endif else begin
    str = 'UndoEdits: Nothing to undo!'
    idp3_updatetxt, info, str
    return
  endelse

  idp3_display, info
  Widget_Control, event.top, Set_UValue=info
  Widget_Control, info.idp3Window, Set_UValue=info
end

