pro print_xsect, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printxsinfo
  Widget_Control, printxsinfo.info.idp3Window, Get_UValue=info

  ; Get the file name the user typed in.
  Widget_Control, printxsinfo.selectfile, Get_Value = filename
  filename = strtrim(filename[0], 2)
  ua_decompose, filename, disk,path, name, extn, version
  if strlen(extn) eq 0 then filename = filename + '.ps'
  info.savepath = disk + path

  ; Get cross section profile info, extract the image.
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
    if  ptr_valid(info.xsecx) AND ptr_valid(info.xsecy) then begin
      Case (*info.prof).otype of

      0: Begin  ; write postscript
	set_plot,'ps',/copy
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.ps'
	Widget_Control, printxsinfo.selectfile, Set_Value = filename
        device,/landscape,bits=8,file=filename,encapsulated=0
        x = info.xsecx
        y = info.xsecy
        wid = info.plot_linwid
        if n_elements((*x)) gt 1 AND n_elements((*y)) gt 1 then begin
          if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
          if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
          Widget_Control, info.profymintxt, Get_Value = pymin
          Widget_Control, info.profymaxtxt, Get_Value = pymax
	  yr = [pymin,pymax]
          if (*info.prof).log eq 0 then begin
	    plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      thick=wid, xthick=wid, ythick=wid, charthick=wid, $
	      ystyle=ysc, xstyle=xsc, yrange=yr, $
	      xtitle='Pixels', ytitle='Intensity'
          endif else begin
	    plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      thick=wid, xthick=wid, ythick=wid, charthick=wid, $
	      ystyle=ysc, xstyle=xsc, /ylog, $
	      xtitle='Pixels', ytitle='Intensity', yrange=yr
          endelse  
          device,/close
          if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
          set_plot, ptype
        endif else begin
          a = Dialog_Message('No cross section data to plot')
        endelse
     end

     1: Begin   ; print encapsulated postscript
	set_plot,'ps',/copy
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.eps'
	Widget_Control, printxsinfo.selectfile, Set_Value = filename
        device,/landscape,bits=8,file=filename,encapsulated=1
        x = info.xsecx
        y = info.xsecy
        wid = info.plot_linwid
        if n_elements((*x)) gt 1 AND n_elements((*y)) gt 1 then begin
          if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
          if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
          Widget_Control, info.profymintxt, Get_Value = pymin
          Widget_Control, info.profymaxtxt, Get_Value = pymax
	  yr = [pymin,pymax]
          if (*info.prof).log eq 0 then begin
	    plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      thick=wid, xthick=wid, ythick=wid, charthick=wid, $
	      ystyle=ysc, xstyle=xsc, yrange=yr, $
	      xtitle='Pixels', ytitle='Intensity'
          endif else begin
	    plot, (*x), (*y), position=[.20,.15,.95,.90], /ynozero, $
	      thick=wid, xthick=wid, ythick=wid, charthick=wid, $
	      ystyle=ysc, xstyle=xsc, /ylog, $
	      xtitle='Pixels', ytitle='Intensity', yrange=yr
          endelse  
          device,/close
          if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
          set_plot, ptype
        endif else begin
          a = Dialog_Message('No cross section data to plot')
        endelse
       end

     2: Begin    ; print PICT
       wset, info.profdraw
       ua_decompose, filename, disk,path, name, extn, version
       filename = disk + path + name + '.pict'
       Widget_Control, printxsinfo.selectfile, Set_Value = filename
       write_pict, filename, tvrd()
       end

     3: Begin    ; print TIFF
       wset, info.profdraw
       ua_decompose, filename, disk,path, name, extn, version
       filename = disk + path + name + '.tiff'
       Widget_Control, printxsinfo.selectfile, Set_Value = filename
       him = tvrd()
       ihim = reverse(him,2)
       tvlct, v1, v2, v3, /get
       write_tiff, filename, ihim, red=v1, green=v2, blue=v3
       end

     4: Begin     ; print JPEG
       wset, info.profdraw
       ua_decompose, filename, disk,path, name, extn, version
       filename = disk + path + name + '.jpg'
       Widget_Control, printxsinfo.selectfile, Set_Value = filename
       write_jpeg, filename, tvrd()
       end

    endcase
    endif else begin
      a = Dialog_Message('No cross section data to plot')
    endelse
  endif
  if printdone eq 1 then begin
    Widget_Control, info.idp3Window, Set_UValue=info
  endif
  Widget_Control, event.top, /Destroy
end

pro printxsect_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printxsinfo
  Widget_Control, printxsinfo.info.idp3Window, Get_UValue=info

  case event.id of

    printxsinfo.otypeButtons: begin
      otype = event.value
      (*info.prof).otype = otype
      end

    printxsinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, printxsinfo.selectfile, set_value=fpath
      end

    printxsinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      return
      end

  endcase
end

pro idp3_printxsect, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_printxsect")) then return
  Widget_Control, event.top, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Print Cross Section Data'
  pntxsbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  pntxs1base =  Widget_Base(pntxsbase, /Row)
  label      = Widget_Label (pntxs1base, Value='Output file name:') 
  selectfile = Widget_Text  (pntxs1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro = 'print_xsect')
  pntxs2base = Widget_Base(pntxsbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'PICT', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(pntxs2base, tnames, row=1, label_left='File type:', $
       uvalue='obutton', set_value=(*info.prof).otype, exclusive=1, $
       /no_release)
  label3     = Widget_Label (pntxs2base, Value = '     ')
  browseButton = Widget_Button(pntxs2base, Value = ' Browse ')
  label4     = Widget_Label (pntxs2base, Value = '     ')
  printButton = Widget_Button(pntxs2base, Value = ' Print ', $
	       Event_Pro='print_xsect')
  label5     = Widget_Label (pntxs2base, Value = '     ')
  cancelButton = Widget_Button(pntxs2base, Value = ' Cancel ')

  printxsinfo = {selectfile    :     selectfile,   $
		 otypeButtons  :     otypeButtons, $
		 browseButton  :     browseButton, $
		 cancelButton  :     cancelButton, $
		 info          :     info        }

  Widget_Control, pntxsbase, set_uvalue = printxsinfo
  Widget_Control, pntxsbase, /Realize

  XManager, "idp3_printxsect", pntxsbase, Event_Handler = "printxsect_ev"
          
end
