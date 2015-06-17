pro savegraw_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savegrawinfo
  info = savegrawinfo.info
  roi = *info.roi
  zm = float(roi.roizoom)
  rd = (*info.roi).radradius
  x1 = (info.cent.sx - rd) / zm + roi.roixorig
  x2 = (info.cent.sx + rd) / zm + roi.roixorig
  y1 = (info.cent.sy - rd) / zm + roi.roiyorig
  y2 = (info.cent.sy + rd) / zm + roi.roiyorig
  typ = 0

  case event.id of

    savegrawinfo.selectfile: begin

      ; Get the file name the user typed in.
      Widget_Control, savegrawinfo.selectfile, Get_Value = filename
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

    savegrawinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savegrawinfo.selectfile, set_value=fpath
    end

    savegrawinfo.saveButton: begin
      Widget_Control, savegrawinfo.selectfile, Get_Value = filename
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

    savegrawinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

  endcase
end


pro idp3_savegraw, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_savegraw")) then return
  Widget_Control, event.top, Get_UValue = tinfo
  Widget_Control, tinfo.info.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Save Gaussian Raw Data'
  savegrawbase   = Widget_Base(Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base = Widget_Base (savegrawbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (savegrawbase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savegrawinfo = {selectfile    :     selectfile,   $
		 browseButton  :     browseButton, $
		 saveButton    :     saveButton,   $
		 cancelButton  :     cancelButton, $
		 info          :     info          }

  Widget_Control, savegrawbase, set_uvalue = savegrawinfo
  Widget_Control, savegrawbase, /Realize

  XManager, "idp3_savegraw", savegrawbase, Event_Handler = "savegraw_ev"
          
end
