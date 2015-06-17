pro roi_print, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printroiinfo
  Widget_Control, printroiinfo.info.idp3Window, Get_UValue=info

      ; Get the file name the user typed in.
      Widget_Control, printroiinfo.selectfile, Get_Value = filename
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
	str = 'PrintROI: Cannot print'
	idp3_updatetxt, info, str
	return
      endif else begin
        if (*info.roi).otype lt 2 then begin      
          ; Get ROI info, extract the image.
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
	  bleg = 15
	  if ysize le 256 then begin
	    ysizp = 13
	    ylabp = 13
	    yleg = 5
	    factor = 3.0
	    csize = 1.1
	    space = 2
          endif else if ysize le 512 then begin
	    ysizp = 26
	    ylabp = 26
	    yleg = 10
	    factor = 6.0
	    csize = 0.9
	    space = 4
          endif else begin
	    ysizp = 39
	    ylabp = 39
	    yleg = 15
	    factor = 9.0
	    csize = 0.8
	    space = 6
          endelse
          ztype = info.roiioz
          bits = info.color_bits
          ncolors = info.d_colors-bits-1
	  fz = (xsize / 256) > 1
	  num = (fz * 256) < xsize
	  bbeg = xsize/2 - num/2
          bend = bbeg + num - 1
	  bdelta = float(num) / 5.
	  astr = ['Intensity', 'Log(I)', 'Sq Root(I)']
	  annot = astr[info.imscl]
	  bysize = ysize
	  if info.scb gt 0 then bysize = bysize + space + ylabp
          if info.scb eq 2 then begin
            xsizp = xsize 
            bysize = bysize + ysizp 
          endif 
	  sdispim = idp3_scaldisplay(info)
          ; Zoom the image in the appropriate way.
          tiim = idp3_congrid(sdispim[x1:x2,y1:y2], $
	         xsize,ysize,zoom,ztype,info.pixorg)
          sdispim = 0
          if info.zoomflux eq 1 then tiim = tiim/(zoom * zoom)
          if (*roi).rod eq 1 and n_elements(*(*roi).roddmask) gt 0 then begin
           tiim[*(*roi).roddmask] = 0
          endif

          ; Write the file.
          set_plot,'ps',/copy
	  labsz = float(bysize - ysize)
          if xsize gt ysize then begin
            sizzx = info.rpsz
            sizzy=(float(ysize)/float(xsize)+labsz/float(xsize)) * info.rpsz
          endif else begin
            sizzy = (1.0 + labsz/float(ysize)) * info.rpsz
            sizzx = (float(xsize)/float(ysize)) * info.rpsz
          endelse
	  ua_decompose, filename, disk,path, name, extn, version
        endif
	Case (*info.roi).otype of

	0: Begin  ; write postscript
	   filename = disk + path + name + '.ps' 
	   Widget_Control, printroiinfo.selectfile, Set_Value = filename
           device,/portrait,/inches,yoffset=2.0,xsize=sizzx,ysize=sizzy, $
             file=filename,/color,bits=8,encapsulated=0
           barray = bytarr(xsize, bysize)
	   barray[*,*] = 255
	   Case info.scb of
	   0: barray[0:xsize-1, 0:ysize-1] = $
	        bytscl(tiim,top=ncolors,min=rz1, max=rz2)+bits
	   1: barray[0:xsize-1,ylabp+space:bysize-1] = $
	        bytscl(tiim,top=ncolors,min=rz1, max=rz2)+bits
           2: begin
              barray[0:xsize-1,ylabp+ysizp+space:bysize-1] = $
  	        bytscl(tiim,top=ncolors,min=rz1, max=rz2)+bits
              leg = bytarr(num,yleg)
	      leg = byte((float(ncolors+1)*findgen(num)/float(num-1)) $
	          # replicate(1,yleg))
              arr = (fix(bdelta+0.5) * indgen(6)) < (num-1)
	      farr = (bdelta * findgen(6)) < (float(num) - 1.0) 
	      for i = 0, 5 do begin
	        leg(arr[i],*) = 128
              endfor
	      if bits gt 0 then begin
	        xnd = bits * fz
	        leg[0:xnd,0:yleg-1] = 255
              endif
	      barray[bbeg:bend,bleg:bleg+yleg-1] = leg
           end
           endcase
           tv, barray, xsize=sizzx, ysize=sizzy, /inches
	   if info.scb eq 1 then begin
	     xyouts, 0.49, 0.048, annot, /normal, charsize=1.1
	     z1str = 'Min=' + strmid(strtrim(string(rz1),2),0,6)
	     xyouts, 0.003, 0.01, z1str, /normal
	     z2str = 'Max=' + strmid(strtrim(string(rz2),2),0,6)
	     xyouts, 0.85, 0.01, z2str, /normal
           endif else if info.scb eq 2 then begin
	     yvloc = float(bleg) / float(bysize) - 0.03
	     for i = 0, 5 do begin
	       if i eq 0 and bits gt 0 then boff = xnd + 1 else boff = 0
	       xi = float(bbeg + arr[i] + boff) / float(xsize) - 0.025
	       if i lt 5 $
	         then val = rz1 + (rz2-rz1)/float(num-1) * farr[i] $
	         else val = rz2
	       sval = strmid(strcompress(string(val),/remove_all),0,4)
	       xyouts, xi, yvloc, sval, /normal, charsize=0.9 
             endfor
	     yaloc = (float(bleg) + float(yleg)) / float(bysize) + $
	             (1.0 / float(bysize)) * factor
	     xyouts, 0.49, yaloc, annot, /normal, charsize=csize
	   endif  
           device,/close
           if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
           set_plot, ptype
	   tiim = 0
           end

        1: Begin  ; write encapsulated postscript
	   filename = disk + path + name + '.eps'
	   Widget_Control, printroiinfo.selectfile, Set_Value = filename
	   device,/portrait,/inches,yoffset=2.0,xsize=sizzx,ysize=sizzy, $
	     file=filename,/color,bits=8,encapsulated=1
           barray = bytarr(xsize, bysize)
	   barray[*,*] = 255
	   Case info.scb of
	   0: barray[0:xsize-1, 0:ysize-1] = $
	        bytscl(tiim,top=ncolors,min=rz1, max=rz2)+bits
	   1: barray[0:xsize-1,ylabp+space:bysize-1] = $
	        bytscl(tiim,top=ncolors,min=rz1, max=rz2)+bits
           2: begin
              barray[0:xsize-1,ylabp+ysizp+space:bysize-1] = $
  	        bytscl(tiim,top=ncolors,min=rz1, max=rz2)+bits
              leg = bytarr(num,yleg)
	      leg = byte((float(ncolors+1)*findgen(num)/float(num-1)) $
	          # replicate(1,yleg))
              arr = (fix(bdelta+0.5) * indgen(6)) < (num-1)
	      farr = (bdelta * findgen(6)) < (float(num) - 1.0) 
	      for i = 0, 5 do begin
	        leg(arr[i],*) = 128
              endfor
	      if bits gt 0 then begin
	        xnd = bits * fz
	        leg[0:xnd,0:yleg-1] = 255
              endif
	      barray[bbeg:bend,bleg:bleg+yleg-1] = leg
              end
           endcase
           tv, barray, xsize=sizzx, ysize=sizzy, /inches
	   if info.scb eq 1 then begin
	     xyouts, 0.49, 0.048, annot, /normal, charsize=1.1
	     z1str = 'Min=' + strmid(strtrim(string(rz1),2),0,6)
	     xyouts, 0.003, 0.01, z1str, /normal
	     z2str = 'Max=' + strmid(strtrim(string(rz2),2),0,6)
	     xyouts, 0.85, 0.01, z2str, /normal
           endif else if info.scb eq 2 then begin
	     yvloc = float(bleg) / float(bysize) - 0.03
	     for i = 0, 5 do begin
	       if i eq 0 and bits gt 0 then boff = xnd + 1 else boff = 0
	       xi = float(bbeg + arr[i] + boff) / float(xsize) - 0.025
	       if i lt 5 $
	         then val = rz1 + (rz2-rz1)/float(num-1) * farr[i] $
	         else val = rz2
	       sval = strmid(strcompress(string(val),/remove_all),0,4)
	       xyouts, xi, yvloc, sval, /normal, charsize=0.9 
             endfor
	     yaloc = (float(bleg) + float(yleg)) / float(bysize) + $
	             (1.0 / float(bysize)) * factor
	     xyouts, 0.49, yaloc, annot, /normal, charsize=csize
	   endif  
           device,/close
           if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
           set_plot, ptype
	   tiim = 0
           end

	2: Begin   ; write PICT
	   wset, (*info.roi).drawid2
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.pict' 
	   Widget_Control, printroiinfo.selectfile, Set_Value = filename
	   rim = tvrd()
	   tvlct, r, g, b, /get
	   write_pict, filename, rim, r, g, b
	   end

        3: Begin   ; write TIFF
	   wset, (*info.roi).drawid2
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.tiff'
	   Widget_Control, printroiinfo.selectfile, Set_Value = filename
	   rim = tvrd()
	   tvlct, r, g, b, /get
	   irim = reverse(rim,2)
	   write_tiff, filename, irim, red=r, green=g, blue=b
           end

        4: Begin   ; write JPEG
	   wset, (*info.roi).drawid2
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.jpg'
	   Widget_Control, printroiinfo.selectfile, Set_Value = filename
	   im = tvrd()
	   write_jpeg, filename, im
	   im = 0
	   end

        else:
	endcase
      endelse
      if printfil eq 1 then Widget_Control, info.idp3Window, Set_UValue=info
      Widget_Control, event.top, /Destroy
      end  

pro printroi_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printroiinfo
  Widget_Control, printroiinfo.info.idp3Window, Get_UValue=info

  case event.id of

  printroiinfo.otypeButtons: begin
    otype = event.value
    (*info.roi).otype = otype
    end

  printroiinfo.browseButton: begin
    Pathvalue = Dialog_Pickfile(Title='Please select output file path', $
       Path=info.savepath, Get_Path=outpath)
;    ua_decompose, Pathvalue, disk, path, file, extn, version
;    fpath = disk + path
    Widget_Control, printroiinfo.selectfile, set_value=outpath
    end

  printroiinfo.cancelButton: begin
    if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
    set_plot, ptype
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, event.top, /Destroy
    return
    end

  endcase

  Widget_Control, event.top, Set_UValue=printroiinfo
  Widget_Control, printroiinfo.info.idp3Window, Set_UValue=info

end


pro idp3_printroi, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_printroi")) then return
  Widget_Control, event.top, Get_UValue = info
  path = info.savepath

  title      = 'IDP3 Print ROI'
  pntrbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  pntr1base =  Widget_Base(pntrbase, /Row)
  label      = Widget_Label (pntr1base, Value='Output file name:') 
  selectfile = Widget_Text  (pntr1base, Value = path, XSize = 80, /Edit, $
		    Event_Pro = 'roi_print')
  pntr2base  = Widget_Base  (pntrbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'PICT', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(pntr2base, tnames, row=1, label_left='File type:', $
	      uvalue='obutton', set_value=(*info.roi).otype, exclusive=1)
  label3     = Widget_Label (pntr2base, Value = '     ')
  browseButton = Widget_Button(pntr2base, Value = ' Browse ')
  printButton = Widget_Button(pntr2base, Value = ' Print ', $
		   Event_Pro = 'roi_print')
  cancelButton = Widget_Button(pntr2base, Value = ' Cancel ')

  printroiinfo = {selectfile    :     selectfile, $
		  browseButton  :     browseButton, $
		  cancelButton  :     cancelButton, $
		  otypeButtons  :     otypeButtons,  $
		  info          :     info        }

  Widget_Control, pntrbase, set_uvalue = printroiinfo
  Widget_Control, pntrbase, /Realize

  XManager, "idp3_printroi", pntrbase, Event_Handler = "printroi_ev"
          
end
