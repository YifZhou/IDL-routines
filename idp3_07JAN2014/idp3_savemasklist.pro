pro savemasklist_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savemlistinfo
  Widget_Control, savemlistinfo.info.idp3Window, Get_UValue=info
  errstr = 'Do you wish to overwrite the existing file?'

  case event.id of

    savemlistinfo.selectfile: begin
      Widget_Control, savemlistinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
;      ua_decompose, filename, disk, path, name, extn, version
;      if strlen(extn) eq 0 then filename = filename + '.fit'
;      info.savepath = disk + path

      if n_elements(savemlistinfo.mask) gt 0 then begin
	temp = file_search(filename, Count=fcount)
	if fcount gt 0 then begin
	  idp3_selectval, event.top, errstr, ['no', 'yes'], val
	  if val eq 0 then dowrite = 0 else dowrite = 1
        endif else dowrite = 1
	if dowrite eq 1 then begin
          themask = savemlistinfo.mask
	  badp = where(themask eq 0, cnt)
	  if cnt gt 0 then begin
	    res = array_indices(themask, badp)
	    xbadpix = res[0,*]
	    ypadpix = res[1,*]
	    openw, blun, filename, /Get_Lun
	    printf, blun, 'Bad pixel list created from mask'
	    for i = 0, n_elements(xbadpix)-1 do begin
	      printf, blun, xbadpix[i], ypadpix[i]
            endfor
	    close, blun
	    free_lun, blun
          endif else begin
	    str = 'No bad pixels in mask'
	    idp3_updatetxt, info, str
	    return
          endelse
          themask = 0
        endif else stat = Dialog_Message('Mask List file not overwritten')
      endif else begin
	stat = Dialog_Message('No mask to save')
      endelse
      Widget_Control, event.top, /Destroy
      end  

    savemlistinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savemlistinfo.selectfile, set_value=fpath
    end

    savemlistinfo.saveButton: begin
     Widget_Control, savemlistinfo.selectfile, Get_Value = filename
     filename = strtrim(filename[0], 2)
     if n_elements(savemlistinfo.mask) gt 0 then begin
       temp = file_search(filename, Count=fcount)
       if fcount gt 0 then begin
	 idp3_selectval, event.top, errstr, ['no', 'yes'], val
	 if val eq 0 then dowrite = 0 else dowrite = 1
       endif else dowrite = 1
       if dowrite eq 1 then begin
	 Widget_Control, savemlistinfo.goodField, Get_Value=goodval
	 Widget_Control, savemlistinfo.badField, Get_Value=badval
         themask = savemlistinfo.mask
	 bad = where(themask eq 0, cnt)
	 if cnt gt 0 then begin
	   res = array_indices(themask, badp)
	   xbadpix = res[9,*]
	   ypadpix = res[1,*]
	   openw, blun, filename, /Get_Lun
	   printf, blun, 'Bad pixel list created from mask'
	   for i = 0, n_elements(xbadpix)-1 do begin
	     printf, blun, xbadpix[i], ypadpix[i]
           endfor
	   close, blun
	   free_lun, blun
	 endif else begin
	   str = 'No bad pixels in mask'
	   idp3_updatetxt, info, str
	   return
	 endelse
         themask = 0
       endif else stat = Dialog_Message('Mask file not overwritten')
     endif else begin
       test = Dialog_Message('No mask to save')
     endelse
     Widget_Control, event.top, /Destroy
    end

    savemlistinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

    savemlistinfo.goodField: begin
      Widget_Control, savemlistinfo.goodField, Get_Value=temp
    end

    savemlistinfo.badField: begin
      Widget_Control, savemlistinfo.badField, Get_Value=temp
    end
  endcase
end


pro idp3_savemasklist, event

@idp3_errors

  if(XRegistered("idp3_savemasklist")) then return
  Widget_Control, event.top, Get_UValue = maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  path = info.savepath
  mask = maskinfo.cur_mask

  title      = 'IDP3 Save Mask List'
  savelbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base = Widget_Base(savelbase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (savelbase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savemlistinfo = {selectfile    :     selectfile,   $
		   browseButton  :     browseButton, $
		   saveButton    :     saveButton,   $
		   cancelButton  :     cancelButton, $
		   mask          :     mask,         $
		   info          :     info          }

  Widget_Control, savelbase, set_uvalue = savemlistinfo
  Widget_Control, savelbase, /Realize

  XManager, "idp3_savemasklist", savelbase, Event_Handler = "savemasklist_ev"
          
end
