pro savemask_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savemaskinfo
  Widget_Control, savemaskinfo.info.idp3Window, Get_UValue=info
  errstr = 'Do you wish to overwrite the existing file?'

  case event.id of

    savemaskinfo.selectfile: begin
      Widget_Control, savemaskinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.fit'
      info.savepath = disk + path

      if n_elements(savemaskinfo.mask) gt 0 then begin
	temp = file_search(filename, Count=fcount)
	if fcount gt 0 then begin
	  idp3_selectval, event.top, errstr, ['no', 'yes'], val
	  if val eq 0 then dowrite = 0 else dowrite = 1
        endif else dowrite = 1
	if dowrite eq 1 then begin
          themask = savemaskinfo.mask
          thehdr = savemaskinfo.maskhdr
          ua_fits_write, filename, themask, thehdr
          themask = 0
        endif else stat = Dialog_Message('Mask file not overwritten')
      endif else begin
	stat = Dialog_Message('No mask to save')
      endelse
      Widget_Control, event.top, /Destroy
      end  

    savemaskinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savemaskinfo.selectfile, set_value=fpath
    end

    savemaskinfo.saveButton: begin
     Widget_Control, savemaskinfo.selectfile, Get_Value = filename
     filename = strtrim(filename(0), 2)
     ua_decompose, filename, disk, path, name, extn, version
     if strlen(extn) eq 0 then filename = filename + '.fit'
     info.savepath = disk + path
     if n_elements(savemaskinfo.mask) gt 0 then begin
       temp = file_search(filename, Count=fcount)
       if fcount gt 0 then begin
	 idp3_selectval, event.top, errstr, ['no', 'yes'], val
	 if val eq 0 then dowrite = 0 else dowrite = 1
       endif else dowrite = 1
       if dowrite eq 1 then begin
	 Widget_Control, savemaskinfo.goodField, Get_Value=goodval
	 Widget_Control, savemaskinfo.badField, Get_Value=badval
         themask = savemaskinfo.mask
         thehdr = savemaskinfo.maskhdr
	 newmask = themask
	 newmask[*,*] = goodval
	 bad = where(themask eq 0, cnt)
	 if cnt gt 0 then newmask[bad] = badval
	 sxaddpar, thehdr, 'MASKGOOD', goodval
	 sxaddpar, thehdr, 'MASKBAD', badval
         ua_fits_write, filename, newmask, thehdr
         themask = 0
	 newmask = 0
       endif else stat = Dialog_Message('Mask file not overwritten')
     endif else begin
       test = Dialog_Message('No mask to save')
     endelse
     Widget_Control, event.top, /Destroy
    end

    savemaskinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end

    savemaskinfo.goodField: begin
      Widget_Control, savemaskinfo.goodField, Get_Value=temp
    end

    savemaskinfo.badField: begin
      Widget_Control, savemaskinfo.badField, Get_Value=temp
    end
  endcase
end


pro idp3_savemask, event

@idp3_errors

  if(XRegistered("idp3_savemask")) then return
  Widget_Control, event.top, Get_UValue = maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  path = info.savepath
  mask = maskinfo.cur_mask
  maskhdr = maskinfo.cur_hdr

  title      = 'IDP3 Save Mask'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save0base = Widget_Base(savebase, /Row)
  goodField = cw_field(save0base, value=1., title='Output Mask Good Value:', $
	   uvalue='gval', xsize=5, /Return_Events, /Floating)
  badField = cw_field(save0base, value=0., title='Bad Value:', $
	   uvalue='bval', xsize=5, /Return_Events, /Floating)
  save1base = Widget_Base(savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit)
  save2base = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savemaskinfo = {selectfile    :     selectfile,   $
		  browseButton  :     browseButton, $
		  saveButton    :     saveButton,   $
		  cancelButton  :     cancelButton, $
		  goodField     :     goodField,    $
		  badField      :     badField,     $
		  mask          :     mask,         $
		  maskhdr       :     maskhdr,      $
		  info          :     info          }

  Widget_Control, savebase, set_uvalue = savemaskinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_savemask", savebase, Event_Handler = "savemask_ev"
          
end
