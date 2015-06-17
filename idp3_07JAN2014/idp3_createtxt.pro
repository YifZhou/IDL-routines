pro createtxt_done, event
  Widget_Control, event.top, /Destroy
end

pro createtxt_clear, event
  Widget_Control, event.top, Get_UValue = ctinfo
  Widget_Control, ctinfo.cinfo.idp3Window, Get_UValue=info
  if ptr_valid(info.ptxtarr) then ptr_free, info.ptxtarr
  txtarr = "Image Display Paradigm #3, Version " + info.UAVersion
  info.ptxtarr = ptr_new(txtarr)
  Widget_Control, ctinfo.cinfo.idp3Window, Set_UValue=info
  Widget_Control, event.top, /Destroy

end

pro createtxt_save, event
  Widget_Control, event.top, Get_UValue = ctinfo
  Widget_Control, ctinfo.cinfo.idp3Window, Get_UValue=info
  txtarr = (*info.ptxtarr)
  openw, lun, 'idp3.log', /get_lun
  printf, lun, txtarr
  close, lun
  free_lun, lun
  print, 'text saved to idp3.log'
;  ptr_free, info.ptxtarr
;  txtarr = "Image Display Paradigm #3, Version " + info.UAVersion
;  info.ptxtarr = ptr_new(txtarr)
;  Widget_Control, ctinfo.info.idp3Window, Set_UValue=info
;  Widget_Control, event.top, Set_UValue=ctinfo
end

pro idp3_createtxt, event
@idp3_structs
@idp3_errors

  if XRegistered('idp3_scrolltxt') then return
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo
  txtarr = *cinfo.ptxtarr
  xsz = info.textwinsz

  stWindow = Widget_Base(Title = 'IDP3 Scroll Text', /Column, $
	     Group_Leader = event.top, $
	     XOffset = cinfo.wpos.adwp[0], $
	     YOffset = cinfo.wpos.adwp[1])

  textwindow = Widget_Text(stWindow, xsize=xsz, ysize=30, /Scroll, $
	       value=txtarr)
  cinfo.scrolltxt = textwindow
  Widget_Control, info.idp3Window, Set_UValue=cinfo
  buttonbase = Widget_Base(stWindow, /Row)
  saveButton = Widget_Button(buttonbase, Value='Save', $
	       Event_Pro='createtxt_save')
  clearButton = Widget_Button(buttonbase, Value='Clear', $
	       Event_Pro='createtxt_clear')
  doneButton = Widget_Button(buttonbase, Value='Done', $
	       Event_pro='createtxt_done')

  ctinfo = { textWindow  :  textWindow,   $
	     cinfo       :  cinfo          }

  Widget_Control, stWindow, Set_UValue=ctinfo
  Widget_Control, stWindow, /Realize
  XManager, 'idp3_scrolltxt', stWindow, /no_block
end

