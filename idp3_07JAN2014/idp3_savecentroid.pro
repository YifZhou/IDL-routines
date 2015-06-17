pro centroid_save, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savecentinfo
  Widget_Control, savecentinfo.info.idp3Window, GET_UValue=cinfo
      
      Widget_Control, savecentinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      str = 'Save Centroids: ' + filename
      idp3_updatetxt, cinfo, str
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.txt'
      cinfo.savepath = disk + path
      savdone = 0
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
        idp3_selectval, event.top, 'Are all desired images turned ON?', $
  	  ['no','yes'], ok
        if ok eq 1 then begin
          openw, lun, filename, /Get_Lun
          ims = (*savecentinfo.info.images)
	  show_path = savecentinfo.info.sip
	  namlen = 0
	  for i = 0,n_elements(ims)-1 do begin
	    if (*ims[i]).vis eq 1 then begin
	      if show_path eq 1 then begin
		fname = (*ims[i]).name
              endif else begin
		ua_decompose, (*ims[i]).name, disk, path, name, extn, version
		fname = name + extn
              endelse
	      len = strlen(fname)
	      if namlen lt len then namlen = len
            endif
          endfor
	  blank = '                                                  '
	  namstr = blank + blank + blank
	  namstr = strmid(namstr, 0, namlen)
          for i = 0,n_elements(ims)-1 do begin
            if (*ims[i]).vis eq 1 then begin
	      if show_path eq 1 then begin
	        fname = (*ims[i]).name
              endif else begin
	        ua_decompose, (*ims[i]).name, disk, path, name, extn, version
	        fname = name + extn
              endelse
	      str = '     '
	      tmpstr = namstr
	      strput, tmpstr, fname
	      if i eq savecentinfo.info.moveimage then str = '  Ref'
  	      printf, lun, tmpstr, (*ims[i]).lccx, (*ims[i]).lccy, str
            endif
          endfor
          close, lun
          free_lun, lun
	  savdone = 1
        endif else begin
	  temp = Widget_Message( $
	    'Turn on desired images and reset output filename')
        endelse
        if savdone eq 1 then begin
	  Widget_Control, event.top, /Destroy
	  Widget_Control, savecentinfo.info.idp3Window, Set_UValue=cinfo
        endif
      endif
end

pro savecentroid_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savecentinfo
  Widget_Control, savecentinfo.info.idp3Window, GET_UValue=cinfo

  case event.id of

    savecentinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savecentinfo.selectfile, set_value=fpath
      end

    savecentinfo.cancelButton: begin
      Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
      Widget_Control, event.top, /Destroy
      end

  endcase
end


pro idp3_savecentroid, event

@idp3_structs
@idp3_errors

  ; Pop up a widget so the user can enter a file name, then go save
  ; the display image in that file (with an appropriate header).
  if(XRegistered("idp3_savecentroid")) then return
  Widget_Control, event.top, Get_UValue = info

  Widget_Control, info.idp3Window, Get_UValue=cinfo
 
  path = cinfo.savepath

  title      = 'IDP3 Save Centroids'
  savebase   = Widget_Base(Title = title, /Column, Group_Leader=event.top, $
			     xoffset=cinfo.wpos.savwp[0], $
			     yoffset=cinfo.wpos.savwp[1])
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro='centroid_save')
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ', $
	       Event_Pro='centroid_save')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savecentinfo = {browseButton  :     browseButton, $
		  cancelButton  :     cancelButton, $ 
		  selectfile    :     selectfile,   $
		  info          :     info          }

  Widget_Control, savebase, set_uvalue = savecentinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_savecentroid", savebase, Event_Handler = "savecentroid_ev",$
     /NO_BLOCK
          
end
