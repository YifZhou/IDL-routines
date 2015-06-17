pro savegfit_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savegfitinfo
  info = savegfitinfo.info
  roi = *info.roi
  zm = float(roi.roizoom)
  rd = (*info.roi).radradius
  x1 = (info.cent.sx - rd) / zm + roi.roixorig
  x2 = (info.cent.sx + rd) / zm + roi.roixorig
  y1 = (info.cent.sy - rd) / zm + roi.roiyorig
  y2 = (info.cent.sy + rd) / zm + roi.roiyorig
  typ = 1 

  case event.id of

    savegfitinfo.selectfile: begin

      ; Get the file name the user typed in.
      Widget_Control, savegfitinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ok = idp3_savegdata(event, info, filename, typ, x1, x2, y1, y2)
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

    savegfitinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savegfitinfo.selectfile, set_value=fpath
    end

    savegfitinfo.saveButton: begin
      Widget_Control, savegfitinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ok = idp3_savegdata(event, info, filename, typ, x1, x2, y1, y2)
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

    savegfitinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_savegfit, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_savegfit")) then return
  Widget_Control, event.top, Get_UValue = tinfo
  Widget_Control, tinfo.info.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Save Gaussian Fit Data'
  savegfitbase   = Widget_Base(Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base = Widget_Base (savegfitbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (savegfitbase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savegfitinfo = {selectfile    :     selectfile,   $
		 browseButton  :     browseButton, $
		 saveButton    :     saveButton,   $
		 cancelButton  :     cancelButton, $
		 info          :     info          }

  Widget_Control, savegfitbase, set_uvalue = savegfitinfo
  Widget_Control, savegfitbase, /Realize

  XManager, "idp3_savegfit", savegfitbase, Event_Handler = "savegfit_ev"
          
end
