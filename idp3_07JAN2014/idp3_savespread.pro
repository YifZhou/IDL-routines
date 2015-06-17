pro spread_save, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savessinfo
  Widget_Control, savessinfo.info.idp3Window, Get_UValue=info

  Widget_Control, savessinfo.selectfile, Get_Value = filename
  filename = strtrim(filename(0), 2)
  ua_decompose, filename, disk, path, name, extn, version
  if strlen(extn) eq 0 then filename = filename + '.txt'
  info.savepath = disk + path
  temp = file_search (filename, Count = fcount)
  if fcount gt 0 then begin
    idp3_selectval, event.top, 'Do you wish to overwrite existing file?',$
      ['no','yes'], savfil
    if savfil eq 0 then begin
      temp = Widget_Message('Enter new name for output file or Cancel')
    endif else begin
      ; check if path is valid
      openw, lun, filename, error=err, /get_lun
      if err eq 0 then begin
	close, lun
	free_lun, lun
	savfil = 1
      endif else begin
	temp = Widget_Message('Cannot open file for writing - Invalid Path?')
	savfil = 0
      endelse
    endelse
  endif else savfil = 1
  if savfil eq 1 then begin
    ; Write spreadsheet to a text file.
    openw, olun, filename, /GET_LUN, width=200
    ; Write the spreadsheet coordinates first.
    x1 = (*info.roi).roixorig
    y1 = (*info.roi).roiyorig
    x2 = (*info.roi).roixend
    y2 = (*info.roi).roiyend
    refnum = info.moveimage
    refname = (*(*info.images)[refnum]).name
    str = info.header_char + 'File: ' + refname + '  ROI Coordinates [' + $
          string(x1, '$(i5)') + ':' + string(x2, '$(i5)') + ',' + $
	  string(y1, '$(i5)') + ':' +  string(y2, '$(i5)') + ']'
    printf, olun, str
    data = (*info.dispim)[x1:x2, y1:y2]
    dsz = size(data)
    for j = 0, dsz[2]-1 do begin
      array = data[*,j]
      astr = ''
      for i = 0, dsz[1]-1 do begin
	astr = astr + string(array[i],'$(g12.6)') + ' '
      endfor
      printf, olun, astr
    endfor
    close, olun
    free_lun,olun
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, event.top, /Destroy
  endif
 end

pro savespread_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savessinfo
  Widget_Control, savessinfo.info.idp3Window, Get_UValue=info

  case event.id of

    savessinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savessinfo.selectfile, set_value=fpath
      end

    savessinfo.cancelButton: begin
      Widget_Control, savessinfo.info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      end

  endcase
end


pro idp3_savespread, event

@idp3_errors

  ; Pop up a widget to allow the use to name the output text file.
  if(XRegistered("idp3_savespread")) then return
  Widget_Control, event.top, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Save ROI Spreadsheet'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro='spread_save')
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ', $
	       Event_Pro='spread_save')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savessinfo = {selectfile    :     selectfile,   $
		browseButton  :     browseButton, $
		cancelButton  :     cancelButton, $
		info          :     info          }

  Widget_Control, savebase, set_uvalue = savessinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_savespread", savebase, Event_Handler = "savespread_ev"
          
end
