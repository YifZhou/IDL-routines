pro saveim_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=saveiminfo
  Widget_Control, saveiminfo.info.idp3Window, GET_UValue=cinfo

  case event.id of

    saveiminfo.selectfile: begin
      ; The user hit return after typing in a file name, get it.
      Widget_Control, saveiminfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      x1 = 0
      y1 = 0
      x2 = saveiminfo.info.maxxpoint-1
      y2 = saveiminfo.info.maxypoint-1
      ok = idp3_saveimage(event, cinfo, filename, x1, x2, y1, y2)
      if ok eq 0 then begin
        ; save path
	ua_decompose, filename, disk, path, name, extn, version
        cinfo.savepath = disk + path
        Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
        Widget_Control, event.top, /Destroy
      endif else begin
	if ok lt 0 then $
	  test = Dialog_Message('Error in path/filename specification')
      endelse
    end

  saveiminfo.browseButton: begin
    Pathvalue = Dialog_Pickfile(Title='Please select output file path')
    ua_decompose, Pathvalue, disk, path, file, extn, version
    fpath = disk + path
    Widget_Control, saveiminfo.selectfile, set_value=fpath
    end

    saveiminfo.saveButton: begin
      Widget_Control, saveiminfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      x1 = 0
      y1 = 0
      x2 = saveiminfo.info.maxxpoint-1
      y2 = saveiminfo.info.maxypoint-1
      ok = idp3_saveimage(event, cinfo, filename, x1, x2, y1, y2)
      if ok eq 0 then begin
        ; save path
	ua_decompose, filename, disk, path, name, extn, version
        cinfo.savepath = disk + path
        Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
        Widget_Control, event.top, /Destroy
      endif else begin
	if ok lt 0 then $
	  test = Dialog_Message('Error in path/filename specification')
      endelse
    end

  saveiminfo.cancelButton: begin
    Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
    Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_saveim, event

@idp3_errors

  ; Pop up a widget so the user can enter a file name, then go save
  ; the display image in that file (with an appropriate header).
  if(XRegistered("idp3_saveim")) then return
  Widget_Control, event.top, Get_UValue = info
  
  path = info.savepath
  refim = *(*info.images)[info.moveimage]
  name = refim.name

  title      = 'IDP3 Save image'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  str = 'Output hdr from ref image - ' + strtrim(string(info.moveimage),2) $
	 + ': ' + name
  label1     = Widget_Label (savebase, Value=str) 
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  saveiminfo = {selectfile    :     selectfile,   $
		browseButton  :     browseButton, $
		saveButton    :     saveButton,   $
		cancelButton  :     cancelButton, $
		info          :     info          }

  Widget_Control, savebase, set_uvalue = saveiminfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_saveim", savebase, Event_Handler = "saveim_ev"
          
end
