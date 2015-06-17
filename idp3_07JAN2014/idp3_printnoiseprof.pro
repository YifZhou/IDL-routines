pro noiseprof_print, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printnpinfo
  Widget_Control, printnpinfo.info.idp3Window, Get_UValue=info

  ; Get the file name the user typed in.
  Widget_Control, printnpinfo.selectfile, Get_Value = filename
  filename = strtrim(filename[0], 2)
  ua_decompose, filename, disk,path, name, extn, version
  if strlen(extn) eq 0 then filename = filename + '.ps'
  info.savepath = disk + path

  ; Get noise profile info, extract the image.
  ; Write the file.
  printdone = 0
  temp = file_search (filename, Count = fcount)
  if fcount gt 0 then begin
    idp3_selectval, event.top, 'Do you wish to overwrite existing file?',$
      ['no','yes'], printfil
    if printfil eq 0 then begin
      temp = Widget_Message('Enter new name for output file or Cancel')
    endif else begin
      ; check if path is valid
      openw, lun, filename, error=err, /get_lun
      if err eq 0 then begin
	close, lun
	free_lun, lun
	printfil = 1
      endif else begin
	temp=Widget_Message('Cannot open file for writing - Invalid Path?')
	printfil = 0
      endelse
    endelse
  endif else printfil = 1
  if printfil eq 1 then begin
    if  ptr_valid(info.noispx) AND ptr_valid(info.noispy) then begin
      Case (*info.nprf).otype of

      0: Begin  ; write postscript
        set_plot,'ps',/copy
        ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.ps'
	Widget_Control, printnpinfo.selectfile, Set_Value = filename
        device,/landscape,bits=8,file=filename,encapsulated=0
        x = info.noispx
        y = info.noispy
        if n_elements((*x)) gt 1 AND n_elements((*y)) gt 1 then begin
	  wid = info.plot_linwid
	  if info.plot_xscale eq 1 $
            then plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      xtitle='Radius of Annulus Center', ytitle = 'One sigma', $
	      ystyle=2,background=1, color=0, thick=wid, ythick=wid, $
	      xthick=wid, charthick=wid $
            else plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      xstyle=1,xtitle='Radius of Annulus Center', ytitle='One sigma', $
	      ystyle=2,background=1, color=0, thick=wid, ythick=wid, $
	      xthick=wid, charthick=wid
          device,/close
	  if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
          set_plot, ptype
  	  printdone = 1
        endif else begin
	  a = Dialog_Message('No noise profile data to plot')
        endelse
      end
      1: Begin  ; write encapsulated postscript
        set_plot,'ps',/copy
        ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.eps'
	Widget_Control, printnpinfo.selectfile, Set_Value = filename
        device,/landscape,bits=8,file=filename,encapsulated=1
        x = info.noispx
        y = info.noispy
        if n_elements((*x)) gt 1 AND n_elements((*y)) gt 1 then begin
	  wid = info.plot_linwid
	  if info.plot_xscale eq 1 $
            then plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      xtitle='Radius of Annulus Center', ytitle = 'One sigma', $
	      ystyle=2,background=1, color=0, thick=wid, ythick=wid, $
	      xthick=wid, charthick=wid $
            else plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      xstyle=1,xtitle='Radius of Annulus Center', ytitle='One sigma', $
	      ystyle=2,background=1, color=0, thick=wid, ythick=wid, $
	      xthick=wid, charthick=wid
          device,/close
	  if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
          set_plot, ptype
  	  printdone = 1
        endif else begin
	  a = Dialog_Message('No noise profile data to plot')
        endelse
      end
      2: Begin   ; print PICT
	wset, info.npfdraw
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.pict'
	Widget_Control, printnpinfo.selectfile, Set_Value = filename
	write_pict, filename, tvrd()
      end
      3: Begin    ; print TIFF
	wset, info.npfdraw
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.tiff'
	Widget_Control, printnpinfo.selectfile, Set_Value = filename
	him = tvrd()
	ihim = reverse(him,2)
	write_tiff, filename, ihim
      end
      4: Begin    ; print JPEG
	wset, info.npfdraw
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.jpg'
	Widget_Control, printnpinfo.selectfile, Set_Value = filename
	write_jpeg, filename, tvrd()
      end
    endcase
    endif else begin
      a = Dialog_Message('No noise profile data to plot')
    endelse
  endif
  if printdone eq 1 then begin
    Widget_Control, info.idp3Window, Set_UValue=info
  endif
  Widget_Control, event.top, /Destroy
end  

pro printnoiseprof_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printnpinfo
  Widget_Control, printnpinfo.info.idp3Window, Get_UValue=info

  case event.id of

   printnpinfo.otypeButtons: begin
     otype = event.value
     (*info.nprf).otype = otype
     end

   printnpinfo.browseButton: begin
     Pathvalue = Dialog_Pickfile(Title='Please select output file path')
     ua_decompose, Pathvalue, disk, path, file, extn, version
     fpath = disk + path
     Widget_Control, printnpinfo.selectfile, set_value=fpath
     end

   printnpinfo.cancelButton: begin
     Widget_Control, info.idp3Window, Set_UValue=info
     Widget_Control, event.top, /Destroy
     return
     end

  endcase
end

pro idp3_printnoiseprof, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if XRegistered("idp3_printnoiseprof") then return
  Widget_Control, event.top, Get_UValue = tempinfo
  Widget_Control, tempinfo.info.idp3Window, Get_UValue=info

  path = info.savepath

  title      = 'IDP3 Print Noise Profile'
  pntnpbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  pntnp1base = Widget_Base(pntnpbase, /Row)
  label      = Widget_Label (pntnp1base, Value='Output file name:') 
  selectfile = Widget_Text  (pntnp1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro = 'noiseprof_print')
  pntnp2base = Widget_Base(pntnpbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'PICT', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(pntnp2base, tnames, row=1, label_left='File type:', $
       uvalue='obutton', set_value=(*info.nprf).otype, exclusive=1, $
       /no_release)
  browseButton = Widget_Button(pntnp2base, Value = ' Browse ')
  label3     = Widget_Label (pntnp2base, Value = '     ')
  printButton = Widget_Button(pntnp2base, Value = ' Print ', $
		Event_Pro='noiseprof_print')
  label4     = Widget_Label (pntnp2base, Value = '     ')
  cancelButton = Widget_Button(pntnp2base, Value = ' Cancel ')

  printnpinfo = {selectfile    :     selectfile,   $
		 otypeButtons  :     otypeButtons, $
		 browseButton  :     browseButton, $
		 cancelButton  :     cancelButton, $
	         info          :     info        }

  Widget_Control, pntnpbase, set_uvalue = printnpinfo
  Widget_Control, pntnpbase, /Realize

  XManager, "idp3_printnoiseprof", pntnpbase, Event_Handler = "printnoiseprof_ev"
          
end
