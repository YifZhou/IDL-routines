pro hist_print, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printhistinfo
  Widget_Control, printhistinfo.info.idp3Window, Get_UValue=info

      ; Get the file name the user typed in.
      Widget_Control, printhistinfo.selectfile, Get_Value = filename
      filename = strtrim(filename[0], 2)
      ua_decompose, filename, disk,path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.ps'
      info.savepath = disk + path
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
      if printfil eq 0 then begin
	str = 'PrintHist: Cannot print'
	idp3_updatetxt, info, str
	return
      endif else begin
	if ptr_valid(info.rhisto) and $
	   ptr_valid(info.rh_xax) then begin
	  Case (*info.rhist).otype of

	  0: Begin  ; write postscript
	     set_plot, 'ps', /copy
	     filename = disk + path + name + '.ps' 
	     Widget_Control, printhistinfo.selectfile, Set_Value = filename
             device, /landscape, file=filename, /color, bits=8, encapsulated=0
	     histf = *info.rhisto
	     x_ax = *info.rh_xax
             hxtitle = 'Pixel Values'
	     hxltitle = 'Log(Pixel Values)'
	     hxstitle = 'Sqrt(Pixel Values)'
	     hytitle = 'Number of Pixels'
	     hyltitle = 'Log(Number of Pixels)'
	     if info.imscl eq 1 then xstr = hxltitle else $
	       if info.imscl eq 2 then xstr = hxstitle else xstr = hxtitle
	     if (*info.rhist).log eq 0 then begin
	       ystr = hytitle
	       plot,x_ax, histf, xtitle=xstr, ytitle=ystr, xstyle=1, $
	         ystyle=2, psym=10, position=[.15,.15,.95,.90], $
	         xrange=[min(x_ax),max(x_ax)],/noclip
             endif else begin
	       ystr = hyltitle
	       plot, x_ax, histf, xtitle=xstr, ytitle=ystr, xstyle=1, $
	         ystyle=2, psym=10, position=[.15,.15,.95,.90], $
	         xrange=[min(x_ax),max(x_ax)],/noclip, /ylog
             endelse
             device,/close
             if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
             set_plot, ptype
           end

          1: Begin  ; write encapsulated postscript
	     set_plot, 'ps', /copy
	     filename = disk + path + name + '.eps'
	     Widget_Control, printhistinfo.selectfile, Set_Value = filename
             device, /landscape, file=filename, /color, bits=8, encapsulated=1
	     histf = *info.rhisto
	     x_ax = *info.rh_xax
             hxtitle = 'Pixel Values'
	     hxltitle = 'Log(Pixel Values)'
	     hxstitle = 'Sqrt(Pixel Values)'
	     hytitle = 'Number of Pixels'
	     hyltitle = 'Log(Number of Pixels)'
	     if info.imscl eq 1 then xstr = hxltitle else $
	       if info.imscl eq 2 then xstr = hxstitle else xstr = hxtitle
	     if (*info.rhist).log eq 0 then begin
	       ystr = hytitle
	       plot,x_ax, histf, xtitle=xstr, ytitle=ystr, xstyle=1, $
	         ystyle=2, psym=10, position=[.15,.15,.95,.90], $
	         xrange=[min(x_ax),max(x_ax)],/noclip
             endif else begin
	       ystr = hyltitle
	       plot, x_ax, histf, xtitle=xstr, ytitle=ystr, xstyle=1, $
	         ystyle=2, psym=10, position=[.15,.15,.95,.90], $
	         xrange=[min(x_ax),max(x_ax)],/noclip, /ylog
             endelse
             device,/close
             if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
             set_plot, ptype
           end

	  2: Begin   ; write PICT
	     wset, info.histdraw
	     ua_decompose, filename, disk,path, name, extn, version
	     filename = disk + path + name + '.pict' 
	     Widget_Control, printhistinfo.selectfile, Set_Value = filename
	     write_pict, filename, tvrd()
	   end

          3: Begin   ; write TIFF
	     wset, info.histdraw
	     ua_decompose, filename, disk,path, name, extn, version
	     filename = disk + path + name + '.tiff'
	     Widget_Control, printhistinfo.selectfile, Set_Value = filename
	     rim = tvrd()
	     irim = reverse(rim,2)
	     write_tiff, filename, irim
           end

          4: Begin   ; write JPEG
	     wset, info.histdraw
	     ua_decompose, filename, disk,path, name, extn, version
	     filename = disk + path + name + '.jpg'
	     Widget_Control, printhistinfo.selectfile, Set_Value = filename
	     im = tvrd()
	     write_jpeg, filename, im
	     im = 0
	   end

          else:
  	  endcase
        endif else begin
	  str = 'PrintHist: Nothing to print'
	  idp3_updatetxt, info, str
	  return
        endelse
      endelse
      if printfil eq 1 then Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      end  

pro printhist_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printhistinfo
  Widget_Control, printhistinfo.info.idp3Window, Get_UValue=info

  case event.id of

  printhistinfo.otypeButtons: begin
    otype = event.value
    (*info.rhist).otype = otype
    end

  printhistinfo.browseButton: begin
    Pathvalue = Dialog_Pickfile(Title='Please select output file path', $
       Path=info.savepath, Get_Path=outpath)
    Widget_Control, printhistinfo.selectfile, set_value=outpath
    end

  printhistinfo.cancelButton: begin
    if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
    set_plot, ptype
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, event.top, /Destroy
    return
    end

  endcase

  Widget_Control, event.top, Set_UValue=printhistinfo
  Widget_Control, printhistinfo.info.idp3Window, Set_UValue=info

end


pro idp3_printhist, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_printhist")) then return

  Widget_Control, event.top, Get_UValue = histinfo
  Widget_Control, histinfo.info.idp3Window, Get_UValue = info

  path = info.savepath

  title      = 'IDP3 Print Histogram'
  pntrbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  pntr1base =  Widget_Base(pntrbase, /Row)
  label      = Widget_Label (pntr1base, Value='Output file name:') 
  selectfile = Widget_Text  (pntr1base, Value = path, XSize = 80, /Edit, $
		    Event_Pro = 'hist_print')
  pntr2base  = Widget_Base  (pntrbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'PICT', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(pntr2base, tnames, row=1, label_left='File type:', $
	      uvalue='obutton', set_value=(*info.rhist).otype, exclusive=1, $
	      /no_release)
  label3     = Widget_Label (pntr2base, Value = '     ')
  browseButton = Widget_Button(pntr2base, Value = ' Browse ')
  printButton = Widget_Button(pntr2base, Value = ' Print ', $
		   Event_Pro = 'hist_print')
  cancelButton = Widget_Button(pntr2base, Value = ' Cancel ')

  printhistinfo = {selectfile    :     selectfile,   $
 		   browseButton  :     browseButton, $
		   cancelButton  :     cancelButton, $
		   otypeButtons  :     otypeButtons, $
		   info          :     info        }

  Widget_Control, pntrbase, set_uvalue = printhistinfo
  Widget_Control, pntrbase, /Realize

  XManager, "idp3_printhist", pntrbase, Event_Handler = "printhist_ev"
          
end
