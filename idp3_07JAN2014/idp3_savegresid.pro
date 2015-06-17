pro savegresid_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savegresidinfo
  info = savegresidinfo.info
  roi = *info.roi
  zm = float(roi.roizoom)
  rd = (*info.roi).radradius
  x1 = (info.cent.sx - rd) / zm + roi.roixorig
  x2 = (info.cent.sx + rd) / zm + roi.roixorig
  y1 = (info.cent.sy - rd) / zm + roi.roiyorig
  y2 = (info.cent.sy + rd) / zm + roi.roiyorig
  typ = 2

  case event.id of

    savegresidinfo.selectfile: begin

      ; Get the file name the user typed in.
      Widget_Control, savegresidinfo.selectfile, Get_Value = filename
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

    savegresidinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savegresidinfo.selectfile, set_value=fpath
    end

    savegresidinfo.saveButton: begin
      Widget_Control, savegresidinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ok = idp3_savegdat(event, info, filename, typ, x1, x2, y1, y2)
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

    savegresidinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_savegresid, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_savegresid")) then return
  Widget_Control, event.top, Get_UValue = tinfo
  Widget_Control, tinfo.info.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Save Gaussian Raw Data'
  savegresidbase = Widget_Base(Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base = Widget_Base (savegresidbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (savegresidbase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savegresidinfo = {selectfile    :     selectfile,   $
		 browseButton  :     browseButton, $
		 saveButton    :     saveButton,   $
		 cancelButton  :     cancelButton, $
		 info          :     info          }

  Widget_Control, savegresidbase, set_uvalue = savegresidinfo
  Widget_Control, savegresidbase, /Realize

  XManager, "idp3_savegresid", savegresidbase, Event_Handler = "savegresid_ev"
          
end
