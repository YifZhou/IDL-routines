pro idp3_exppm, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue = info
     
  imageon = 0
  ims = (*info.images)
  im = info.moveimage
  for i = 0, n_elements(ims)-1 do begin
    if (*ims[i]).vis eq 1 then imageon = imageon + 1
  endfor
  if imageon gt 0 then begin
    datptr  = info.dispim
    lim1 = 0
    lim2 = n_elements(ims)-1
    sz = size(*datptr)
    dsz = [sz[1],sz[2]]
    sfits = info.sfits
    sip = info.sip
    if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
       else str = 'Flux Conserved'
    idp3_sethdr, ims, im, sfits, phead, ihead, dsz, lim1, lim2, str
      phdrptr = ptr_new(phead)
      psz = n_elements(*phdrptr)
      if n_elements(ihead) gt 2 then begin
	ihdrptr = ptr_new(ihead) 
	ihsz = n_elements(ihead)
	idp3_updatetxt, info, ihead
      endif else begin
	ihdrptr = ptr_new()
	ihsz = 0
      endelse
      idp3_irs, addtopm=[datptr,phdrptr,ihdrptr]
      str = 'Exporting to Project Manager, Size Image:' + $
	    string(sz[1]) +  string(sz[2]) +  $
	    ' Primary Header:' + string(psz) + ' Image Header:' + $
	    string(ihsz)
      idp3_updatetxt, info, str
    endif else begin
      stat = Widget_Message('No image to save!')
    endelse
end
