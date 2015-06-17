pro xsect_save, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savexsinfo
  Widget_Control, savexsinfo.info.idp3Window, Get_UValue=info

  Widget_Control, savexsinfo.selectfile, Get_Value = filename
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
	free_lun, lun
	savfil = 1
      endif else begin
	temp = Widget_Message('Cannot open file for writing - Invalid Path?')
	savfil = 0
      endelse
    endelse
  endif else savfil = 1
  if savfil eq 1 then begin
    ; If we've got a valid cross section array, write it to a text file.
    if ptr_valid(info.xsecx) then begin
      x = info.xsecx
      y = info.xsecy
      if ptr_valid(info.xsgfit) and ptr_valid(info.xsbasefit) then begin
	 f = info.xsgfit
	 b = info.xsbasefit
      endif
      if n_elements((*x)) gt 1 then begin
        openw, olun, filename, /GET_LUN
        ; Write the cross section coords first.
        xb = float((*info.roi).xsxstart)
        yb = float((*info.roi).xsystart)
        xe = float((*info.roi).xsxstop)
        ye = float((*info.roi).xsystop)
        xs = (*info.roi).xswidth
        printf, olun, info.header_char, 'cross section coords:  ' 
	printf, olun, info.header_char, 'xstart = ', xb, '  xstop = ', xe
	printf, olun, info.header_char, 'ystart = ', yb, '  ystop = ', ye
	str0 = info.header_char + 'cross section width = ' + $
	  strtrim(string(xs),2)
	sngl = 1.0 / (*info.roi).roizoom
	if xs-sngl gt 0.01 then begin
	  case (*info.roi).xsmm of
	    0: str = ' (Mean)'
	    1: str = ' (Integration)'
	    2: str = ' (Median)'
	    else:
          endcase
          str0 = str0 + str
	endif
        printf, olun, str0
	if info.zoomflux eq 0 then zstr = ' - flux not conserved' $
	    else zstr = ' - flux conserved'
	str00 = info.header_char + 'roi zoom factor =' + $
		string((*info.roi).roizoom,'$(i10)') + zstr
        printf, olun, str00
	if ptr_valid(info.xsgfit) and ptr_valid(info.xsbasefit) then begin
	  str1 = info.header_char + 'Gaussian fit parameters: 1/e=' + $
	     string((*info.roi).xs1overe, '$(f10.5)')
	  str2 = info.header_char + 'fwhm=' + $
	    string((*info.roi).xsfwhm,'$(f10.5)') + '  peak location=' + $
	    string((*info.roi).xspeak,'$(f10.4)') + '  height=' + $
	    string((*info.roi).xsheight,'$(f10.4)')
          Case (*info.roi).xsbkg of
	    0: str3 = info.header_char + 'No baseline fit'
	    1: str3 = info.header_char + 'Constant baseline value=' + $
	      string((*info.roi).xsbase0,'$(f10.5)')
            2: str3 = info.header_char + 'Linear baseline: intercept=' + $
	      string((*info.roi).xsbase0, '$(f10.5)') + '  slope=' + $
	      string((*info.roi).xsbase1, '$(f10.5)')
          endcase
	  printf, olun, str1
	  printf, olun, str2
	  printf, olun, str3
        endif
        printf,olun,info.header_char, '  '
        for i = 0, n_elements((*x))-1 do begin
          if ptr_valid(info.xsgfit) and ptr_valid(info.xsbasefit) $
	   then printf,olun,(*x)[i],(*y)[i],(*f)[i],(*b)[i] $
	   else printf,olun,(*x)[i],(*y)[i]
        endfor
        close, olun
        free_lun,olun
	savdone = 1
      endif else begin
        a = Dialog_Message('No cross section data to save - too few points!')
      endelse
    endif else begin
      a = Dialog_Message('No cross section data to save - pointer invalid!')
    endelse
    if savdone eq 1 then begin
      Widget_Control, info.idp3Window, Set_UValue=info
      ;Widget_Control, event.top, /Destroy
    endif
  endif
 end

pro savexsect_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savexsinfo
  Widget_Control, savexsinfo.info.idp3Window, Get_UValue=info

  case event.id of

    savexsinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, savexsinfo.selectfile, set_value=fpath
      end

    savexsinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      end

  endcase
end


pro idp3_savexsect, event

@idp3_errors

  ; Pop up a widget to allow the use to name the output text file.
  if(XRegistered("idp3_savexsect")) then return
  Widget_Control, event.top, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Save Cross Section'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1])
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro='xsect_save')
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ', $
	       Event_Pro='xsect_save')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  savexsinfo = {selectfile    :     selectfile,   $
		browseButton  :     browseButton, $
		cancelButton  :     cancelButton, $
		info          :     info          }

  Widget_Control, savebase, set_uvalue = savexsinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_savexsect", savebase, Event_Handler = "savexsect_ev", $
	    /no_block
          
end
