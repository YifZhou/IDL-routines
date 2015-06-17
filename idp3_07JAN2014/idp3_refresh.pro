pro idp3_refresh, data=data

  Widget_Control, data.idp3Window, Get_UValue=info
  WSET, info.drawid1
  bits = info.color_bits
  ncolors = info.d_colors - bits - 1
  if n_elements(*(info.dispim)) gt 0 then begin
    sdispim = idp3_scaldisplay(info)
    tv, bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2) + bits 
    if XRegistered('idp3_roi') then begin
      roi = *info.roi
      WSET, roi.drawid2
      tv, *roi.roiimage
    endif
  endif else begin 
    str = 'Refresh: invalid pointer'
    idp3_updatetxt, info, str
  endelse

end
