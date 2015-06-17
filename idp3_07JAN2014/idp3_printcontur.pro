pro contur_print, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printconturinfo
  Widget_Control, printconturinfo.info.idp3Window, Get_UValue=info

    ; Get the file name the user typed in.
    Widget_Control, printconturinfo.selectfile, Get_Value = filename
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
      str = 'PrintContour: Cannot print'
      idp3_updatetxt, info, str
      return
    endif else begin
      if (*info.roi).cotype lt 2 then begin ; postscript or encapsulated ps  
        ; Get ROI info, extract the image.
	overlay = info.roicntr_ovly
        roi = info.roi
        x1 = (*roi).roixorig
        y1 = (*roi).roiyorig
        x2 = (*roi).roixend
        y2 = (*roi).roiyend
        zoom = (*roi).roizoom
	if info.zoomflux eq 0 then begin
	  rz1 = info.Z1
	  rz2 = info.Z2
        endif else begin
	  CASE info.imscl of
	  0: Begin  ; linear scaling
	    rz1 = info.Z1 / (*roi).roizoom^2
	    rz2 = info.Z2 / (*roi).roizoom^2
            end
          1: Begin  ; log scaling
	    rz1 = info.Z1 - alog10((*info.roi).roizoom^2)
	    rz2 = info.Z2 - alog10((*info.roi).roizoom^2)
	    end
          2: Begin  ; square root scaling
	    rz1 = info.Z1 / (*info.roi).roizoom
	    rz2 = info.Z2 / (*info.roi).roizoom
            end
          endcase
        endelse
        xsize = (abs(x2-x1)+1) * zoom
        ysize = (abs(y2-y1)+1) * zoom
        ztype = info.roiioz
        bits = info.color_bits
        ncolors = info.d_colors-bits-1
	if xsize ge ysize then begin
	  sizzx = info.rpsz
	  sizzy = (float(ysize)/float(xsize)) * info.rpsz
        endif else begin
	  sizzy = info.rpsz
	  sizzx = (float(xsize)/float(ysize)) * info.rpsz
        endelse
	sdispim = idp3_scaldisplay(info)
        ; Zoom the image in the appropriate way.
        tiim = idp3_congrid(sdispim[x1:x2,y1:y2], $
	   xsize,ysize,zoom,info.roiioz,info.pixorg)
	sdispim = 0
        if info.zoomflux eq 1 then tiim = tiim/(zoom * zoom)
	alphaim = congrid((*info.alphaim)[x1:x2,y1:y2], xsize, ysize)
	bad = where(alphaim eq 0., count)
	if count gt 0 then tiim[bad] = 0.
	alphaim = 0
	if (*roi).msk eq 1 then begin
	  tmpmask = *(*roi).mask
	  xoff = (*roi).msk_xoff
	  yoff = (*roi).msk_yoff
	  goodval = (*roi).maskgood
	  mask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
	  mzxsize = (x2 - x1 + 1) * zoom
	  mzysize = (y2 - y1 + 1) * zoom
	  roimask = congrid(mask, mzxsize, mzysize)
	  bad = where(roimask NE (*roi).maskgood, count)
	  if count gt 0 then begin
	    tiim[bad] = 0.
	    str = 'PrintContour: ' + string(count) + $
		  ' bad pixels masked in roi region'
            idp3_updatetxt, info, str
          endif
        endif
        if (*roi).rod eq 1 and n_elements(*(*roi).roddmask) gt 0 then begin
         tiim[*(*roi).roddmask] = 0.
        endif
	pos_color = 3
	neg_color = 2
	no_color = 250
	logspace = info.roicntr_logs
	levs = *info.roicntr_levs
	nlevs = n_elements(levs)
	linstyl = intarr(nlevs)
	linstyl[*] = 0
	neg = where(levs lt 0, count)
	if count gt 0 then linstyl[neg] = 2
	if info.color_bits eq 6 then begin
	  col = intarr(nlevs)
	  col[*] = pos_color
	  if count gt 0 then col[neg] = neg_color
        endif else col = no_color
	cpos = [0.0, 0.0, sizzx, sizzy]
        barray = bytarr(xsize, ysize)
        if overlay eq 0 then barray[*,*] = 255 else $
	   barray = bytscl(*tiim,top=ncolors,min=rz1, max=rz2) + bits
      endif

      ; Write the file.
      Case (*info.roi).cotype of

      0: Begin  ; write postscript
         set_plot,'ps',/copy
	 ua_decompose, filename, disk,path, name, extn, version
	 filename = disk + path + name + '.ps' 
	 Widget_Control, printconturinfo.selectfile, Set_Value = filename
         device,/portrait,/inches,yoffset=2.0,xsize=sizzx,ysize=sizzy, $
             file=filename,/color,bits=8,encapsulated=0
         tv, barray, xsize=sizzx, ysize=sizzy, /inches
	 contour, *tiim, levels=levs, xstyle=5, ystyle=5, /device, $
	    min_value=rz1, max_value=rz2, $  ;position=cpos, $
	    c_linestyle=linstyl, c_colors=col, c_charsize=0.8, /overplot
         device,/close
         if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
         set_plot, ptype
         ptr_free, tiim
         end

        1: Begin  ; write encapsulated postscript
         set_plot,'ps',/copy
	 ua_decompose, filename, disk,path, name, extn, version
	 filename = disk + path + name + '.eps'
	 Widget_Control, printconturinfo.selectfile, Set_Value = filename
	 device,/portrait,/inches,yoffset=2.0,xsize=sizzx,ysize=sizzy, $
	     file=filename,/color,bits=8,encapsulated=1
         tv, barray, xsize=sizzx, ysize=sizzy, /inches
	 contour, *tiim, levels=levs, xstyle=5, ystyle=5, /device, $
	    min_value=rz1, max_value=rz2, position=cpos, $
	    c_linestyle=linstyl, c_colors=col, c_charsize=0.8, /overplot
         device,/close
         if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
         set_plot, ptype
         ptr_free, tiim
         end

	2: Begin   ; write PICT
	   wset, info.roicntrim
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.pict' 
	   Widget_Control, printconturinfo.selectfile, Set_Value = filename
	   rim = tvrd()
	   tvlct, r, g, b, /get
	   write_pict, filename, rim, r, g, b
	   end

        3: Begin   ; write TIFF
	   wset, info.roicntrim
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.tiff'
	   Widget_Control, printconturinfo.selectfile, Set_Value = filename
	   rim = tvrd()
	   tvlct, r, g, b, /get
	   irim = reverse(rim,2)
	   write_tiff, filename, irim, red=r, green=g, blue=b
           end

        4: Begin   ; write JPEG
	   wset, info.roicntrim
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.jpg'
	   Widget_Control, printconturinfo.selectfile, Set_Value = filename
	   im = tvrd()
	   write_jpeg, filename, im
	   im = 0
	   end

        else:
	endcase
    endelse
    Widget_Control, event.top, /Destroy
end  

pro printcontur_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printconturinfo
  Widget_Control, printconturinfo.info.idp3Window, Get_UValue=info

  case event.id of

  printconturinfo.otypeButtons: begin
    otype = event.value
    (*info.roi).cotype = otype
    end

  printconturinfo.browseButton: begin
    Pathvalue = Dialog_Pickfile(Title='Please select output file path', $
       Path=info.savepath, Get_Path=outpath)
    Widget_Control, printconturinfo.selectfile, set_value=outpath
    end

  printconturinfo.cancelButton: begin
    if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
    set_plot, ptype
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, event.top, /Destroy
    return
    end

  endcase

end


pro idp3_printcontur, event

@idp3_errors

  if XRegistered("idp3_printcontur") then return
  
  Widget_Control, event.top, Get_UValue = crinfo
  Widget_Control, crinfo.info.idp3Window, Get_UValue = info
  
  path = info.savepath

  if not XRegistered('idp3_roicntr')  then begin
    str = 'PrintContour: No Contour Map to Print'
    idp3_updatetxt, info, str
    return
  endif


  title      = 'IDP3 Print ROI Contour Map'
  pntrbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  pntr1base =  Widget_Base(pntrbase, /Row)
  label      = Widget_Label (pntr1base, Value='Output file name:') 
  selectfile = Widget_Text  (pntr1base, Value = path, XSize = 80, /Edit, $
		    Event_Pro = 'contur_print')
  pntr2base  = Widget_Base  (pntrbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'PICT', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(pntr2base, tnames, row=1, label_left='File type:', $
	      uvalue='obutton', set_value=(*info.roi).cotype, exclusive=1)
  label3     = Widget_Label (pntr2base, Value = '     ')
  browseButton = Widget_Button(pntr2base, Value = ' Browse ')
  printButton = Widget_Button(pntr2base, Value = ' Print ', $
		   Event_Pro = 'contur_print')
  cancelButton = Widget_Button(pntr2base, Value = ' Cancel ')

  printconturinfo = {selectfile    :     selectfile,   $
	  	     browseButton  :     browseButton, $
		     cancelButton  :     cancelButton, $
		     otypeButtons  :     otypeButtons, $
		     info          :     info          }

  Widget_Control, pntrbase, set_uvalue = printconturinfo
  Widget_Control, pntrbase, /Realize

  XManager, "idp3_printcontur", pntrbase, Event_Handler = "printcontur_ev"
          
end
