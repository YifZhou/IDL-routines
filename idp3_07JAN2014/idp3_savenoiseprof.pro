pro noiseprof_save, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savenpinfo
  Widget_Control, savenpinfo.info.idp3Window, Get_UValue=info

  Widget_Control, savenpinfo.selectfile, Get_Value = filename
  filename = strtrim(filename(0), 2)
  ua_decompose, filename, disk, path, name, extn, version
  if strlen(extn) eq 0 then filename = filename + '.txt'
  info.savepath = disk + path
  savdone = 0
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
	savfil = 1
      endif else begin
	temp = Widget_Message('Cannot open file for writing - Invalid Path?')
        savfil = 0
      endelse
    endelse
  endif else savfil = 1
  if savfil eq 1 then begin
    ; If we've got a valid cross section array, write it to a text file.
    if ptr_valid(info.noispx) then begin
      x = info.noispx
      y = info.noispy
      a = info.noispa
      m = info.noispm
      r = info.noispr
      np = info.noispp
      if n_elements((*x)) gt 1 then begin
        openw, olun, filename, /GET_LUN
        ; Write the header info first.
        xi = (*info.roi).aincr
        xs = (*info.roi).awidth
        xc = (*info.roi).npxcenter
        yc = (*info.roi).npycenter
        px = (*info.roi).pxscale
        py = (*info.roi).pyscale
        printf, olun,	info.header_char,'center for noise profile  ', xc, yc
        printf, olun, info.header_char,'pixel scale used ', px, py
        printf, olun, info.header_char,'annulus width for noise profile  ', xs
        printf,olun, info.header_char, '  '
        printf, olun, info.header_char, $
          'cntr_radius    mean        stddev   no.points    area      rej_pix'
        for i = 0, n_elements((*x))-1 do begin
          cntr = string((*x)[i],'$(f8.3)')
          printf,olun,cntr,(*m)[i],(*y)[i], (*np)[i], (*a)[i], (*r)[i]
        endfor
        close, olun
        free_lun,olun
	savdone = 1
      endif else begin
        a = Dialog_Message('No noise profile data to save!')
	Widget_Control, event.top, /Destroy
      endelse
    endif else begin
      a = Dialog_Message('No noise profile data to save!')
      Widget_Control, event.top, /Destroy
    endelse
    if savdone eq 1 then begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    endif
  endif
 end  

pro savenoiseprof_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savenpinfo
  Widget_Control, savenpinfo.info.idp3Window, Get_UValue=info

  case event.id of

    savenpinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savenpinfo.selectfile, set_value=fpath
      end

    savenpinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      end

  endcase
 end

pro idp3_savenoiseprof, event

@idp3_errors

  ; Pop up a widget to allow the use to name the output text file.
  if XRegistered("idp3_savenoiseprof") then return
  Widget_Control, event.top, Get_UValue = npinfo
  Widget_Control, npinfo.info.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Save Noise Profile'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1], /Modal)
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro='noiseprof_save')
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ', $
	       Event_Pro='noiseprof_save')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savenpinfo = {selectfile    :     selectfile,   $
		browseButton  :     browseButton, $
		cancelButton  :     cancelButton, $
		info          :     info          }

  Widget_Control, savebase, set_uvalue = savenpinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_savenoiseprof", savebase, Event_Handler = "savenoiseprof_ev"
          
end
