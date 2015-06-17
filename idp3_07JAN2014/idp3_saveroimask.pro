pro saveroimask_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savermaskinfo
  Widget_Control, savermaskinfo.info.idp3Window, Get_UValue=info

  roi =*info.roi
  if ptr_valid(roi.mask) then begin
    tmpmask = *(roi.mask)
    xoff = roi.msk_xoff
    yoff = roi.msk_yoff
    goodval = roi.maskgood
    x1 = roi.roixorig
    x2 = roi.roixend
    y1 = roi.roiyorig
    y2 = roi.roiyend
    msz = size(tmpmask)
    if msz[0] eq 2 then $
      themask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval) $
      else themask = 0
  endif else themask = 0

  case event.id of

    savermaskinfo.selectfile: begin
      Widget_Control, savermaskinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.fit'
      info.savepath = disk + path
      if n_elements(themask) gt 1 then begin
	ua_fits_write, filename, themask
	themask = 0
      endif else test = Dialog_Message('No mask to save')
      Widget_Control, event.top, /Destroy
    end  

    savermaskinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savermaskinfo.selectfile, set_value=fpath
    end

    savermaskinfo.saveButton: begin
     Widget_Control, savermaskinfo.selectfile, Get_Value = filename
     filename = strtrim(filename(0), 2)
     ua_decompose, filename, disk, path, name, extn, version
     if strlen(extn) eq 0 then filename = filename + '.fit'
     info.savepath = disk + path
     if n_elements(themask) gt 1 then begin
       ua_fits_write, filename, themask
       themask = 0
     endif else test = Dialog_Message('No mask to save')
     Widget_Control, event.top, /Destroy
    end

    savermaskinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    end
  endcase
end


pro idp3_saveroimask, event

@idp3_errors

  if(XRegistered("idp3_saveroimask")) then return
  Widget_Control, event.top, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Save ROI Mask'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
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

  savermaskinfo = {selectfile    :     selectfile,   $
		  browseButton  :     browseButton, $
		  saveButton    :     saveButton,   $
		  cancelButton  :     cancelButton, $
		  info          :     info          }

  Widget_Control, savebase, set_uvalue = savermaskinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_saveroimask", savebase, Event_Handler = "saveroimask_ev"
          
end
