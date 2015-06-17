pro idp3_updatetxt, info, str

  print, str
  txtarr = (*info.ptxtarr)
  txtarr = [txtarr, str]
  info.ptxtarr = ptr_new(txtarr)
  if XRegistered('idp3_scrolltxt') then begin
    Widget_Control, info.scrolltxt, Set_Value=str, /append
  endif
end
