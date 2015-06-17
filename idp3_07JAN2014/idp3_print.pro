pro idp3print, event

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
	str = 'IDP3 Print: Cannot print'
	idp3_updatetxt, info, str
	return
      endif else begin
        if info.otype lt 2 then begin      
        ; Get info
	  imsiz = size(*info.dispim)
          xsize = imsiz[1]
          ysize = imsiz[2]
          bits = info.color_bits
          ncolors = info.d_colors-bits-1
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
	  fz = (xsize / 256) > 1
	  num = (fz * 256) < xsize
	  bbeg = xsize/2 - num/2
          bend = bbeg + num - 1
	  bdelta = num / 5
	  astr = ['Intensity', 'Log(I)', 'Sq Root(I)']
	  annot = astr[info.imscl]
	  bysize = ysize
          if info.scb gt 0 then bysize = bysize + space + ylabp
	  if info.scb eq 2 then begin
            xsizp = xsize 
            bysize = bysize + ysizp
          endif

          ; Write the file.
          set_plot,'ps',/copy
	  labsz = float(bysize - ysize)
          if xsize gt ysize then begin
            sizzx = info.mpsz
            sizzy = (float(ysize)/float(xsize) + labsz/float(xsize)) * info.mpsz
          endif else begin
            sizzy = (1.0 + labsz/float(ysize)) * info.mpsz
            sizzx = (float(xsize)/float(ysize)) * info.mpsz
          endelse
	  ua_decompose, filename, disk,path, name, extn, version
        endif
	sdispim = idp3_scaldisplay(info)

	Case info.otype of

	0: begin
	   filename = disk + path + name + '.ps' 
	   Widget_Control, printinfo.selectfile, Set_Value = filename
           device,/portrait,/inches,yoffset=2.0,xsize=sizzx,ysize=sizzy, $
              file=filename,/color,bits=8,encapsulated=0
           barray = bytarr(xsize, bysize)
	   barray[*,*] = 255
	   Case info.scb of
	   0: barray[0:xsize-1,0:ysize-1] = $
	        bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2)+bits
	   1: barray[0:xsize-1,ylabp+space:bysize-1] = $
	        bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2)+bits
           2: begin
              barray[0:xsize-1,ylabp+ysizp+space:bysize-1] = $
  	        bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2)+bits
              leg = bytarr(num,yleg)
	      leg = byte((float(ncolors+1)*findgen(num)/float(num-1)) $
	        # replicate(1,yleg))
              arr = (fix(bdelta+0.5) * indgen(6)) < (num-1)
	      farr = (bdelta * findgen(6)) < (float(num) - 1.)
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
	     z1str = 'Min=' + strmid(strtrim(string(info.Z1),2),0,6)
	     xyouts, 0.003, 0.01, z1str, /normal
	     z2str = 'Max=' + strmid(strtrim(string(info.Z2),2),0,6)
	     xyouts, 0.85, 0.01, z2str, /normal
           endif else if info.scb eq 2 then begin
	     yvloc = float(bleg) / float(bysize) - 0.03
	     for i = 0, 5 do begin
	       if i eq 0 and bits gt 0 then boff = xnd + 1 else boff = 0
	       xi = float(bbeg + arr[i] + boff) / float(xsize) - 0.025
	       if i lt 5 $
	         then val = info.Z1 + (info.Z2-info.Z1)/float(num-1) * farr[i] $
		 else val = info.Z2
	       sval = strmid(strcompress(string(val),/remove_all),0,4)
	       xyouts, xi, yvloc, sval, /normal, charsize=0.9 
             endfor
	     yaloc = (float(bleg) + float(yleg)) / float(bysize) + $
	        (1.0 / float(bysize)) * factor
	     xyouts, 0.49, yaloc, annot, /normal, charsize=csize
	   endif  
           moveim = *(*info.images)[info.moveimage]
           if moveim.vis eq 1 then begin
             him = [*moveim.phead, *moveim.ihead]
             orient = sxpar(him, 'ORIENTAT', count=omatches)
	     reorient = sxpar(him, 'REORIENT', count=rmatches)
	     if rmatches ne 0 then orient = reorient 
             if omatches + rmatches ne 0 then begin
	       orient = orient + moveim.rot
	       if moveim.flipy eq 1 then orient = 360. - (180. + orient)
	       name = moveim.name
	       if info.sip eq 0 then begin
	         ua_decompose, name, disk, path, nname, extn, version
	         name = nname + extn
               endif
               szn = 20.0 
               sze = 15.0 
	       iscl = 1.
	       if orient gt 360. then an = orient - 360. else an = orient
               if orient lt 0. then an  = orient + 360. else an = orient
               conv = !pi / 180.
               sinan = sin(an * conv)
               cosan = cos(an * conv)
               if moveim.flipy eq 0 then ae = an + 270. else ae = an - 270.
               if (ae LT 0.) then ae = ae + 360.
               if (ae GT 360.) then ae = ae - 360.
               sinae = sin(ae * conv)
               cosae = cos(ae * conv)
	       xdn = (szn * iscl * sinan) / xsize
	       ydn = (szn * iscl * cosan) / ysize
	       xde = (sze * iscl * sinae) / xsize
	       yde = (sze * iscl * cosae) / ysize
	       xincpt = 0.92
	       yincpt = 0.92
               xan = xdn + xincpt
               yan = ydn + yincpt
               xae = xde + xincpt
               yae = yde + yincpt
               plots, xincpt, yincpt, /normal, color=250
               plots, xan, yan, /normal, /continue, color=250
               plots, xincpt, yincpt, /normal, color=250
               plots, xae, yae, /normal, /continue, color=250
	       xap = xan+0.01
	       if yan LT yincpt then yap = yan-0.05 else yap=yan+0.005
	       xyouts, xap, yap, 'N', /normal, color=250
	       str = name + '  orientat= ' + string(orient, '$(f8.3)')
	       xyouts, 0.03, 0.95, str, /normal, charsize=0.9, color=250
             endif
           endif
           device,/close
           if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
           set_plot, ptype
	   sdispim = 0
        end

	1: begin  ; encapsulated postscript
	   filename = disk + path + name + '.eps'
	   Widget_Control, printinfo.selectfile, Set_Value = filename
	   device,/portrait,/inches,yoffset=2.0,xsize=sizzx,ysize=sizzy, $
	      file=filename,/color,bits=8,encapsulated=1
           barray = bytarr(xsize, bysize)
	   barray[*,*] = 255
	   Case info.scb of
	   0: barray[0:xsize-1,0:ysize-1] = $
	        bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2)+bits
	   1: barray[0:xsize-1,ylabp+space:bysize-1] = $
	        bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2)+bits
           2: begin
              barray[0:xsize-1,ylabp+ysizp+space:bysize-1] = $
  	        bytscl(sdispim,top=ncolors,min=info.Z1, max=info.Z2)+bits
              leg = bytarr(num,yleg)
	      leg = byte((float(ncolors+1)*findgen(num)/float(num-1)) $
	        # replicate(1,yleg))
              arr = (fix(bdelta+0.5) * indgen(6)) < (num-1)
	      farr = (bdelta * findgen(6)) < (float(num) - 1.)
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
	     z1str = 'Min=' + strmid(strtrim(string(info.Z1),2),0,6)
	     xyouts, 0.003, 0.01, z1str, /normal
	     z2str = 'Max=' + strmid(strtrim(string(info.Z2),2),0,6)
	     xyouts, 0.85, 0.01, z2str, /normal
           endif else if info.scb eq 2 then begin
	     yvloc = float(bleg) / float(bysize) - 0.03
	     for i = 0, 5 do begin
	       if i eq 0 and bits gt 0 then boff = xnd + 1 else boff = 0
	       xi = float(bbeg + arr[i] + boff) / float(xsize) - 0.025
	       if i lt 5 $
	         then val = info.Z1 + (info.Z2-info.Z1)/float(num-1) * farr[i] $
		 else val = info.Z2
	       sval = strmid(strcompress(string(val),/remove_all),0,4)
	       xyouts, xi, yvloc, sval, /normal, charsize=0.9 
             endfor
	     yaloc = (float(bleg) + float(yleg)) / float(bysize) + $
	        (1.0 / float(bysize)) * factor
	     xyouts, 0.49, yaloc, annot, /normal, charsize=csize
	   endif  
           moveim = *(*info.images)[info.moveimage]
           if moveim.vis eq 1 then begin
             him = [*moveim.phead, *moveim.ihead]
             orient = sxpar(him, 'ORIENTAT', count=omatches)
	     reorient = sxpar(him, 'REORIENT', count=rmatches)
	     if rmatches ne 0 then orient = reorient 
             if omatches + rmatches ne 0 then begin
	       orient = orient + moveim.rot
	       if moveim.flipy eq 1 then orient = 360. - (180. + orient)
	       name = moveim.name
	       if info.sip eq 0 then begin
	         ua_decompose, name, disk, path, nname, extn, version
	         name = nname + extn
               endif
               szn = 20.0 
               sze = 15.0 
	       iscl = 1.
	       if orient gt 360. then an = orient - 360. else an = orient
               if orient lt 0. then an  = orient + 360. else an = orient
               conv = !pi / 180.
               sinan = sin(an * conv)
               cosan = cos(an * conv)
               if moveim.flipy eq 0 then ae = an + 270. else ae = an - 270.
               if (ae LT 0.) then ae = ae + 360.
               if (ae GT 360.) then ae = ae - 360.
               sinae = sin(ae * conv)
               cosae = cos(ae * conv)
	       xdn = (szn * iscl * sinan) / xsize
	       ydn = (szn * iscl * cosan) / ysize
	       xde = (sze * iscl * sinae) / xsize
	       yde = (sze * iscl * cosae) / ysize
	       xincpt = 0.92
	       yincpt = 0.92
               xan = xdn + xincpt
               yan = ydn + yincpt
               xae = xde + xincpt
               yae = yde + yincpt
               plots, xincpt, yincpt, /normal, color=250
               plots, xan, yan, /normal, /continue, color=250
               plots, xincpt, yincpt, /normal, color=250
               plots, xae, yae, /normal, /continue, color=250
	       xap = xan+0.01
	       if yan LT yincpt then yap = yan-0.05 else yap=yan+0.005
	       xyouts, xap, yap, 'N', /normal, color=250
	       str = name + '  orientat= ' + string(orient, '$(f8.3)')
	       xyouts, 0.03, 0.95, str, /normal, charsize=0.9, color=250
             endif
           endif
           device,/close
           if !version.os eq 'MacOS' then ptype = 'MAC' else ptype = 'x'
           set_plot, ptype
	   sdispim = 0
        end
	2: Begin   ; PICT format
	   wset, info.drawid1
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.pict' 
	   Widget_Control, printinfo.selectfile, Set_Value = filename
	   write_pict, filename, tvrd()
        end 

	3: Begin   ; Tiff format
	   wset, info.drawid1
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.tiff'
	   Widget_Control, printinfo.selectfile, Set_Value = filename
	   im = tvrd()
	   iim = reverse(im,2)
	   write_tiff, filename, iim
	   im = 0
	   iim = 0
        end

	4: Begin   ; JPEG format
	   wset, info.drawid1
	   ua_decompose, filename, disk,path, name, extn, version
	   filename = disk + path + name + '.jpg'
	   Widget_Control, printinfo.selectfile, Set_Value = filename
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

pro printmain_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=printinfo
  Widget_Control, printinfo.info.idp3Window, Get_UValue=info

  case event.id of

  printinfo.otypeButtons: begin
    otype = event.value
    info.otype = otype
    end

  printinfo.browseButton: begin
    Pathvalue = Dialog_Pickfile(Title='Please select output file path', $
      Path=info.savepath, Get_Path=outpath)
;    ua_decompose, Pathvalue, disk, path, file, extn, version
;    fpath = disk + path
    Widget_Control, printinfo.selectfile, set_value=outpath
    end

  printinfo.cancelButton: begin
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, event.top, /Destroy
    return
    end

  endcase

  Widget_Control, event.top, Set_UValue=printinfo   
  Widget_Control, printinfo.info.idp3Window, Set_UValue=info

end


pro idp3_print, event

@idp3_errors

  ; Pop up a small widget so the user can type in a file name.
  ; Wait for the user to type a carriage-return.
  if(XRegistered("idp3_print")) then return
  Widget_Control, event.top, Get_UValue = info
  path = info.savepath

  title      = 'IDP3 Print Main'
  pntrbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.printwp[0], $
			     yoffset=info.wpos.printwp[1], /Modal)
  pntr1base =  Widget_Base(pntrbase, /Row)
  label      = Widget_Label (pntr1base, Value='Output file name:') 
  selectfile = Widget_Text  (pntr1base, Value = path, XSize = 80, /Edit, $
		    Event_Pro = 'idp3print')
  pntr2base  = Widget_Base  (pntrbase, /Row)
  tnames = ['PostScript', 'Encapsulated Postscript', 'Pict', 'TIFF', 'JPEG']
  otypeButtons = cw_bgroup(pntr2base, tnames, row=1, label_left='File type:', $
	      uvalue='obutton', set_value=info.otype, exclusive=1)
  label3     = Widget_Label (pntr2base, Value = '     ')
  browseButton = Widget_Button(pntr2base, Value = ' Browse ')
  printButton = Widget_Button(pntr2base, Value = ' Print ', $
		   Event_Pro = 'idp3print')
  cancelButton = Widget_Button(pntr2base, Value = ' Cancel ')

  printinfo = {selectfile    :     selectfile, $
               browseButton  :     browseButton, $
	       cancelButton  :     cancelButton, $
	       otypeButtons  :     otypeButtons,  $
	       info          :     info        }

  Widget_Control, pntrbase, set_uvalue = printinfo
  Widget_Control, pntrbase, /Realize

  XManager, "idp3_print", pntrbase, Event_Handler = "printmain_ev"
          
end
