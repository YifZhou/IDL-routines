pro radprof_print, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printinfo
  Widget_Control, printinfo.info.idp3Window, Get_UValue=info

  ; Get the file name the user typed in.
  Widget_Control, printinfo.selectfile, Get_Value = filename
  filename = strtrim(filename[0], 2)
  ua_decompose, filename, disk,path, name, extn, version
  if strlen(extn) eq 0 then filename = filename + '.ps'
  info.savepath = disk + path

  ; Get radial profile info, extract the image.
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
    if  ptr_valid(info.radpx) AND ptr_valid(info.radpy) then begin
      Case (*info.rprf).otype of

      0: Begin  ; write postscript
        set_plot,'ps',/copy
        ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.ps'
	Widget_Control, printinfo.selectfile, Set_Value = filename
        device,/landscape,bits=8,file=filename,encapsulated=0 
        x = info.radpx
        y = info.radpy
        e = info.radee
        nbins = n_elements((*x))
        if nbins gt 1 then begin
          if (*info.rprf).ee eq 0 then begin
            yarray = (*y)
            yt = 'Intensity'
          endif else begin
            yarray = (*e)
            yt = 'Encircled Energy'
          endelse
          wid = info.plot_linwid
	  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
	  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
	  Widget_Control, info.rpymintxt, Get_Value = rpymin
	  Widget_Control, info.rpymaxtxt, Get_Value = rpymax
	  yr = [rpymin, rpymax]
          if (*info.rprf).log eq 0 then begin
            plot, (*x), yarray, position=[.20,.15,.95,.90], /ynozero, $
               xtitle = 'Radius', ytitle = yt, thick=wid, ythick=wid, $
               xthick=wid, charthick=wid, yrange=yr, ystyle=ysc, xstyle=xsc 
	    if (*info.rprf).ee eq 0 and (*info.roi).rpeplot gt 0 then begin
	      stdplot = *info.radstd
	      if (*info.roi).rpeplot eq 1 then begin
	        idp3_errbars, (*x), yarray, yerr=stdplot
              endif else begin
	        npts = *info.radnpt
	        fix = where(npts lt 2, cnt)
	        if cnt gt 0 then npts(fix) = 2
	        seplot = stdplot / sqrt(npts)
	        idp3_errbars, (*x), yarray, yerr=seplot
              endelse
            endif
          endif else begin  
            plot, (*x), yarray, position=[.20,.15,.95,.90], /ynozero, $
              xtitle = 'Radius', ytitle = yt, /ylog, thick=wid, ythick=wid, $
	      xthick=wid, charthick=wid, ystyle=ysc, xstyle=xsc, yrange=yr 
          endelse
          device,/close
          if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
          set_plot, ptype
          printdone = 1
        endif else begin
          a = Dialog_Message('No radial profile data to print!')
        endelse
      end

      1: Begin  ; print encapsulated postscript
        set_plot,'ps',/copy
        ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.eps'
	Widget_Control, printinfo.selectfile, Set_Value = filename
        device,/landscape,bits=8,file=filename,encapsulated=1 
        x = info.radpx
        y = info.radpy
        e = info.radee
        nbins = n_elements((*x))
        if nbins gt 1 then begin
          if (*info.rprf).ee eq 0 then begin
            yarray = (*y)
            yt = 'Intensity'
          endif else begin
            yarray = (*e)
            yt = 'Encircled Energy'
          endelse
          wid = info.plot_linwid
	  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
	  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
	  Widget_Control, info.rpymintxt, Get_Value = rpymin
	  Widget_Control, info.rpymaxtxt, Get_Value = rpymax
	  yr = [rpymin, rpymax]
          if (*info.rprf).log eq 0 then begin
            plot, (*x), yarray, position=[.20,.15,.95,.90], /ynozero, $
               xtitle = 'Radius', ytitle = yt, thick=wid, ythick=wid, $
               xthick=wid, charthick=wid, yrange=yr, ystyle=ysc, xstyle=xsc 
	    if (*info.rprf).ee eq 0 and (*info.roi).rpeplot gt 0 then begin
	      stdplot = *info.radstd
	      if (*info.roi).rpeplot eq 1 then begin
	        idp3_errbars, (*x), yarray, yerr=stdplot
              endif else begin
	        npts = *info.radnpt
	        fix = where(npts lt 2, cnt)
	        if cnt gt 0 then npts(fix) = 2
	        seplot = stdplot / sqrt(npts)
	        idp3_errbars, (*x), yarray, yerr=seplot
              endelse
            endif
          endif else begin  
            plot, (*x), yarray, position=[.20,.15,.95,.90], /ynozero, $
              xtitle = 'Radius', ytitle = yt, /ylog, thick=wid, ythick=wid, $
	      xthick=wid, charthick=wid, ystyle=ysc, xstyle=xsc, yrange=yr 
          endelse
          device,/close
          if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
          set_plot, ptype
          printdone = 1
        endif else begin
          a = Dialog_Message('No radial profile data to print!')
        endelse
      end

      2: Begin   ; print PICT
	wset, info.rprfdraw
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.pict'
	Widget_Control, printinfo.selectfile, Set_Value = filename
	write_pict, filename, tvrd()
      end

      3: Begin   ; print TIFF
	wset, info.rprfdraw
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.tiff'
	Widget_Control, printinfo.selectfile, Set_Value = filename
	him = tvrd()
	ihim = reverse(him,2)
	write_tiff, filename, ihim
      end

       4: Begin   ; print JPEG
	wset, info.rprfdraw
	ua_decompose, filename, disk,path, name, extn, version
	filename = disk + path + name + '.jpg'
	Widget_Control, printinfo.selectfile, Set_Value = filename
	write_jpeg, filename, tvrd()
      end
    endcase
    endif else begin
      a = Dialog_Message('No radial profile data to print!')
    endelse
  endif
  if printdone eq 1 then begin
    Widget_Control, info.idp3Window, Set_UValue=info
  endif
  Widget_Control, event.top, /Destroy
end

pro printradprof_ev, event

@idp3_errors

  Widget_Control, event.top, Get_UValue=printinfo
  Widget_Control, printinfo.info.idp3Window, Get_UValue=info

  case event.id of

    printinfo.otypeButtons: begin
      otype = event.value
      (*info.rprf).otype = otype
      end

    printinfo.browseButton: begin
      Pathvalue = Dialog_Pickfile(Title='Please select output file path')
      ua_decompose, Pathvalue, disk, path, file, extn, version
      fpath = disk + path
      Widget_Control, printinfo.selectfile, set_value=fpath
      end

    printinfo.cancelButton: begin
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      return
      end

  endcase
end

pro idp3_printradprof, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_printradprof")) then return
  Widget_Control, event.top, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Print Radial Profile'
  prntbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  prnt1base = Widget_Base (prntbase, /Row)
  label      = Widget_Label (prnt1base, Value='Output file name:') 
  selectfile = Widget_Text  (prnt1base, Value = path, XSize = 80, /Edit, $
	       Event_Pro = 'radprof_print')
  prnt2base = Widget_Base (prntbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'PICT', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(prnt2base, tnames, row=1, label_left='File type:', $
       uvalue='obutton', set_value=(*info.rprf).otype, exclusive=1, $
       /no_release)
  label3     = Widget_Label (prnt2base, Value = '     ')
  browseButton = Widget_Button(prnt2base, Value = ' Browse ')
  label4     = Widget_Label (prnt2base, Value = '     ')
  printButton = Widget_Button(prnt2base, Value = ' Print ', $
	       Event_Pro='radprof_print')
  label5     = Widget_Label (prnt2base, Value = '     ')
  cancelButton = Widget_Button(prnt2base, Value = ' Cancel ')

  printinfo =   {selectfile    :     selectfile,   $
		 otypeButtons  :     otypeButtons,  $
		 browseButton  :     browseButton, $
		 cancelButton  :     cancelButton, $
		 info          :     info        }

  Widget_Control, prntbase, set_uvalue = printinfo
  Widget_Control, prntbase, /Realize

  XManager, "idp3_printradprof", prntbase, Event_Handler = "printradprof_ev"
          
end
