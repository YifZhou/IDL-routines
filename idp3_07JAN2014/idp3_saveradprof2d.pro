pro saverp2d_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=saverpinfo
  info = saverpinfo.info

  case event.id of

    saverpinfo.selectfile: begin

      ; Get the file name the user typed in.
      Widget_Control, saverpinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      roi = info.roi
      x1 = (*roi).roixorig
      y1 = (*roi).roiyorig
      x2 = (*roi).roixend
      y2 = (*roi).roiyend
      ok = idp3_saveimage(event, info, filename, x1, x2, y1, y2, rpsave=1)
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

    saverpinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, saverpinfo.selectfile, set_value=fpath
    end

    saverpinfo.saveButton: begin
      Widget_Control, saverpinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      roi = info.roi
      x1 = (*roi).roixorig
      y1 = (*roi).roiyorig
      x2 = (*roi).roixend
      y2 = (*roi).roiyend
      ok = idp3_saveimage(event,info,filename,x1,x2,y1,y2,rpsave=1)
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

    saverpinfo.cancelButton: begin
      Widget_Control, saverpinfo.info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_saveradprof2d, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_saverp2d")) then return
  Widget_Control, event.top, Get_UValue = tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Save 2D Radial Profile'
  saverpbase   = Widget_Base(Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base = Widget_Base (saverpbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (saverpbase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  saverpinfo = {selectfile    :     selectfile,   $
		 browseButton  :     browseButton, $
		 saveButton    :     saveButton,   $
		 cancelButton  :     cancelButton, $
		 info          :     info          }

  Widget_Control, saverpbase, set_uvalue = saverpinfo
  Widget_Control, saverpbase, /Realize

  XManager, "idp3_saverp2d", saverpbase, Event_Handler = "saverp2d_ev"
          
end
