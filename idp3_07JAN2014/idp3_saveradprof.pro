pro radprof_save, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=saverpinfo
  Widget_Control, saverpinfo.info.idp3Window, Get_UValue=info

  sk1 = info.header_char + 'xcenter ='
  sk2 = info.header_char + 'ycenter ='
  sk3 = info.header_char + 'radius  ='
  sk4 = info.header_char + 'zoom    ='
  sk5 = info.header_char + 'roixorg ='
  sk6 = info.header_char + 'roixend ='
  sk7 = info.header_char + 'roiyorg ='
  sk8 = info.header_char + 'roiyend ='
  sk9 = info.header_char + 'smooth  ='
  sc1 = '  /profile xcenter in original image'
  sc2 = '  /profile ycenter in original image'
  sc3 = '  /profile radius (original pixels)'
  sc4 = '  /roi zoom factor'
  sc5 = '  /roi x origin'
  sc6 = '  /roi x end'
  sc7 = '  /roi y origin'
  sc8 = '  /roi y end'
  sc9 = '  /num pixels over which profile smoothed'

  domedian = (*info.roi).rpmm
  if domedian eq 0 then str = $
     '      Radius         Mean     STD(Mean)   Enc_Energy  No_Pts  No_Rej' $
     + '   SERR(Mean)   S/N(Mean)    S/N(Pixel)' $
     else str = $
     '      Radius        Median   STD(Median)  Enc_Energy  No_Pts  No_Rej' $
     + '  SERR(Median) S/N(Median)   S/N(Pixel)'

  Widget_Control, saverpinfo.selectfile, Get_Value = filename
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
    ; If we've got a valid radial profile array, write it to a text file.
    if ptr_valid(info.radpx) and ptr_valid(info.radpy) then begin
      x = info.radpx
      y = info.radpy
      e = info.radee
      n = info.radnpt
      r = info.radrej
      s = info.radstd
      bins = intarr(6)
      bins[0] = n_elements(*x)
      bins[1] = n_elements(*y)
      bins[2] = n_elements(*e)
      bins[3] = n_elements(*n)
      bins[4] = n_elements(*r)
      bins[5] = n_elements(*s)
      nbins = min(bins)
      serr = fltarr(nbins)
      snm = fltarr(nbins)
      snp = fltarr(nbins)
      if nbins lt bins[0] then begin
	str = 'Error in array sizes, ' + string(nbins) + string(bins[0])
	idp3_updatetxt, info, str
      endif
      if nbins gt 1 then begin
        openw, olun, filename, /GET_LUN
        ; Write the center coords first.
        xc = float((*info.roi).radxcent)/(*info.roi).roizoom + $
	       (*info.roi).roixorig 
        yc = float((*info.roi).radycent)/(*info.roi).roizoom + $
	       (*info.roi).roiyorig 
        x1 = (*info.roi).roixorig
	x2 = (*info.roi).roixend
	y1 = (*info.roi).roiyorig
	y2 = (*info.roi).roiyend
	smwid = info.rpsmoothwid
	zoom = (*info.roi).roizoom
	if info.zoomflux eq 0 then zstr = ' - flux not conserved' $ 
	   else zstr = ' - flux conserved'
	rad = (*info.roi).radradius / (*info.roi).roizoom
	printf, olun, sk1, string(xc,'$(f10.4)'), sc1
	printf, olun, sk2, string(yc,'$(f10.4)'), sc2
	printf, olun, sk3, string(rad,'$(f10.4)'), sc3
	printf, olun, sk4, string(zoom,'$(i10)'), sc4, zstr
	printf, olun, sk5, string(x1,'$(i10)'), sc5
	printf, olun, sk6, string(x2,'$(i10)'), sc6
	printf, olun, sk7, string(y1,'$(i10)'), sc7
	printf, olun, sk8, string(y2,'$(i10)'), sc8
	printf, olun, sk9, string(smwid,'$(i10)'), sc9

        printf,olun,info.header_char, '  '
        printf, olun, info.header_char, str
        for i = 0, nbins-1 do begin
	  if (*n)[i] gt 1 then begin
	    serr[i] = (*s)[i]/sqrt(float((*n)[i])-1.)
	    snm[i] = (*y)[i]/serr[i]
	    snp[i] = (*y)[i]/(*s)[i]
          endif else begin
	    serr[i] = 0.
	    snm[i] = 0.
	    snp[i] = 0.
          endelse
	  dstr = string((*x)[i], (*y)[i],(*s)[i],(*e)[i],(*n)[i],$
	    (*r)[i],serr[i],snm[i],snp[i], '$(4g13.6,2i7,3g13.6)')
          printf,olun, dstr
        endfor
        close, olun
        free_lun,olun
	savdone = 1
      endif else begin
        a = Dialog_Message('No radial profile data to save!')
	Widget_Control, event.top, /Destroy
      endelse
    endif else begin
      a = Dialog_Message('No radial profile data to save!')
      Widget_Control, event.top, /Destroy
    endelse
    if savdone eq 1 then begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
    endif
  endif
 end

pro saveradprof_ev, event

@idp3_errors

  Widget_Control, event.top, Get_UValue=saverpinfo
  Widget_Control, saverpinfo.info.idp3Window, Get_UValue=info

  case event.id of
    saverpinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, saverpinfo.selectfile, set_value=fpath
      end

    saverpinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      end

  endcase
end

pro idp3_saveradprof, event

@idp3_structs
@idp3_errors

  ; Pop up a widget to allow the use to name the output text file.
  if(XRegistered("idp3_saveradprof")) then return
  Widget_Control, event.top, Get_UValue = info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  path = cinfo.savepath

  title      = 'IDP3 Save Radial Profile'
  savebase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=cinfo.wpos.savwp[0], $
			     yoffset=cinfo.wpos.savwp[1], /Modal)
  save1base  = Widget_Base (savebase, /Row)
  label      = Widget_Label (save1base, Value='Output file name:') 
  selectfile = Widget_Text  (save1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro='radprof_save')
  save2base  = Widget_Base  (savebase, /Row)
  label2     = Widget_Label (save2base, Value='                             ')
  browseButton = Widget_Button(save2base, Value = ' Browse ')
  label3     = Widget_Label (save2base, Value = '     ')
  saveButton = Widget_Button(save2base, Value = ' Save ', $
	       Event_Pro='radprof_save')
  label4     = Widget_Label (save2base, Value = '     ')
  cancelButton = Widget_Button(save2base, Value = ' Cancel ')

  saverpinfo = {selectfile    :     selectfile,   $
		browseButton  :     browseButton, $
		cancelButton  :     cancelButton, $
		info          :     info          }

  Widget_Control, savebase, set_uvalue = saverpinfo
  Widget_Control, savebase, /Realize

  XManager, "idp3_saveradprof", savebase, Event_Handler = "saveradprof_ev"
          
end
