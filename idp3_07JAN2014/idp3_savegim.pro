pro savegim_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savegiminfo
  info = savegiminfo.info

  case event.id of

    savegiminfo.selectfile: begin

      ; Get the file name the user typed in.
      Widget_Control, savegiminfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ok = idp3_savedat(event, image, filename)
      if ok eq 0 then begin
	; save path
	ua_decompose, filename, disk, path, name, extn, version
	info.savepath = disk + path
	Widget_Control, info.idp3Window, Set_UValue=info
	Widget_Control, event.top, /Destroy
      endif else begin
	if ok lt 0 then $
	  test = Dialog_Message('Error in path/filename specification')
      endelse
    end

    savegiminfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savegiminfo.selectfile, set_value=fpath
    end

    savegiminfo.saveButton: begin
      Widget_Control, saveroiinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ok = idp3_savedat(event, image, filename)
      if ok eq 0 then begin
        ; save path
        ua_decompose, filename, disk, path, name, extn, version
        info.savepath = disk + path
        Widget_Control, info.idp3Window, Set_UValue=info
        Widget_Control, event.top, /Destroy
      endif else begin
        if ok lt 0 then $
          test = Dialog_Message('Error in path/filename specification')
      endelse
    end

    savegiminfo.cancelButton: begin
      Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_savegim, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_savegim")) then return
  Widget_Control, event.top, Get_UValue = tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Save Gaussian Data'
  savegimbase   = Widget_Base(Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base = Widget_Base (savegimbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (saveroibase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savegiminfo = {selectfile    :     selectfile,   $
		 browseButton  :     browseButton, $
		 saveButton    :     saveButton,   $
		 cancelButton  :     cancelButton, $
		 info          :     info          }

  Widget_Control, savegimbase, set_uvalue = savegiminfo
  Widget_Control, savegimbase, /Realize

  XManager, "idp3_savegim", savegimbase, Event_Handler = "savegim_ev"
          
end
