pro saveinfo_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=saveparinfo
  Widget_Control, saveparinfo.info.idp3Window, GET_UValue=cinfo

  case event.id of

    saveparinfo.selectfile: begin
      ; The user hit return after typing in a file name, get it.
      Widget_Control, saveparinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.par'
      cinfo.parpath = disk + path
      temp = file_search (filename, Count = fcount)
      if fcount gt 0 then begin
	idp3_selectval, event.top, 'Do you wish to overwrite existing file?',$
	  ['no','yes'], savfil
        if savfil eq 0 then begin
	  temp = Widget_Message('Reselect name for output file or Cancel')
        endif else begin
	  ; check if path is valid
          openw, lun, filename, error=err, /get_lun
	  if err eq 0 then begin
	    close, lun
	    free_lun, lun
	    savfil = 1
          endif else begin
	    savfil = 0
	    temp=Widget_Message('Cannot open file for writing - Invalid Path?')
          endelse
        endelse
      endif else savfil = 1
      if savfil eq 1 then begin
        ims = (*saveparinfo.info.images)
	delim = saveparinfo.info.name_delim
	if strlen(delim) gt 0 $
          then idp3_savepar, ims, filename, delim=delim $
          else idp3_savepar, ims, filename
        Widget_Control, event.top, /Destroy
      endif
      end  

    saveparinfo.saveButton: begin
      Widget_Control, saveparinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.par'
      cinfo.parpath = disk + path
      temp = file_search (filename, Count = fcount)
      if fcount gt 0 then begin
	idp3_selectval, event.top, 'Do you wish to overwrite existing file?',$
	  ['no','yes'], savfil
        if savfil eq 0 then begin
	  temp = Widget_Message('Reselect name for output file or Cancel')
        endif else begin
	  ; check if path is valid
          openw, lun, filename, error=err, /get_lun
	  if err eq 0 then begin
	    close, lun
	    free_lun, lun
	    savfil = 1
          endif else begin
	    savfil = 0
	    temp=Widget_Message('Cannot open file for writing - Invalid Path?')
          endelse
        endelse
      endif else savfil = 1
      if savfil eq 1 then begin
        ims = (*saveparinfo.info.images)
	delim = saveparinfo.info.name_delim
	if strlen(delim) gt 0 $
          then idp3_savepar, ims, filename, delim=delim $
          else idp3_savepar, ims, filename
        Widget_Control, event.top, /Destroy
      endif
      end 
 
    saveparinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, saveparinfo.selectfile, set_value=fpath
      end

    saveparinfo.cancelButton: begin
      Widget_Control, saveparinfo.info.idp3Window, Set_UValue=cinfo
      Widget_Control, event.top, /Destroy
      end

  endcase
end


pro idp3_saveinfo, event

@idp3_errors

  ; Pop up a widget so the user can enter a file name, then go save
  ; the display image in that file (with an appropriate header).
  if(XRegistered("idp3_saveinfo")) then return
  Widget_Control, event.top, Get_UValue = info

  Widget_Control, info.idp3Window, Get_UValue=cinfo
  path = cinfo.parpath

  title      = 'IDP3 Save image parameter info'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     /Modal)
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  saveinfo = {selectfile    :     selectfile,   $
	      browseButton  :     browseButton, $
	      saveButton    :     saveButton,   $
	      cancelButton  :     cancelButton, $
	      info          :     info          }

  Widget_Control, savebase, set_uvalue = saveinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_saveinfo", savebase, Event_Handler = "saveinfo_ev"
          
end
