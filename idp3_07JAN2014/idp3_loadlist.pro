pro Idp3_LoadList, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  loaddata = 0

  ; We keep track of the path the user picks files from.
  inpath = cinfo.listpath
  infilt = cinfo.listfilter
  lfilename = Dialog_Pickfile(/Read, Get_Path=outpath, $
	     Path=inpath, Filter=infilt, Title='Please Select List File')
  cinfo.listpath = outpath
  ename = cinfo.extnam
  lfilename = strtrim(lfilename[0], 2)
  pln = cinfo.load_planes
  psz = size(pln)
  if psz[1] ne 7 then pln = strtrim(string(pln),2)

  ; Check to see if this list exists.
  temp = file_search (lfilename, Count = fcount)
  if (strlen(lfilename) gt 0 and fcount ne 0) then begin
    ; Open the list.
    openr, ilun, lfilename, /GET_LUN
    while not eof(ilun) do begin
      ; Read a line from the file.
      lineOfText = ''
      readf, ilun, lineOfText
      filename = strtrim(lineOfText, 2)
      flen = strlen(filename)
      if flen gt 500 then begin
	msg = 'Filename: ' + strcompress(strmid(filename,0,500), /remove_all) $
            + ' TOO LONG!'
	stat = Widget_Message(msg)
	return
      endif
      archivename = filename
      ; Check if an extension was given
      exnum = -1
      extb = strpos(filename, '[')
      exte = strpos(filename, ']')
      if extb gt 0 and exte gt extb then begin
	exnum = fix(strmid(filename, extb+1, exte-extb+1))
	filename = strmid(filename, 0, extb)
      endif

      ; Check to see if this image exists.
      temp = file_search (filename, Count = fcount)
      if fcount gt 0 then begin
	str = 'LoadList: Loading: ' + filename
	idp3_updatetxt, cinfo, str
        ilen = strlen(filename)
        fdecomp, filename, disk, path, name, extn, version
        lextn = '.' + strlowcase(extn)
        if lextn eq '.gz' then begin
          fdecomp, name, tdisk, tpath, tname, nextn, nvers
          lextn = '.' + strlowcase(nextn)
        endif
        if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
        findx = 0
        lindx = 0
        Case lextn of

          '.fit': Begin
           ; FITS format
           fits_open, filename, fcb
           nextn = fcb.nextend
           if nextn gt 0 then if  fcb.xtension[1] eq 'TABLE' $
	     then nextn = 0
           if nextn gt 0 then begin
             fits_read, fcb, temp, phdr, Exten_No=0, /Header_Only, /no_abort
             maxver = idp3_extver(nextn, fcb.extname, ename, val_extnam)
             if maxver le 0 and exnum ne -1 then begin
	       str = 'LoadList: Error in extension name'
	       idp3_updatetxt, cinfo, str
	       loaddata = 0
             endif else begin
               inst = strtrim(sxpar(phdr, 'INSTRUME'),2)
               if inst eq 'NICMOS' then begin
	         if exnum lt 0 then begin
	           if maxver gt 1 then exnum = maxver - 1
	           exread = 1
                 endif else begin
	           exnum = exnum < (maxver-1)
	           exread = maxver - exnum
                 endelse
	         if maxver gt 1 then begin
		   str ='LoadList: Loading ' + ename + ' extension ' + $
	             strtrim(string(exread),2) + ' which is sample ' + $
	             strtrim(string(exnum),2) + ' (time order)'
                   idp3_updatetxt, cinfo, str
                 endif
               endif else begin
	         if exnum lt 0 then exnum = 1
	         exread = exnum < maxver
               endelse
	       if val_extnam gt 0 then begin 
	         fits_read, fcb, tempdata, ihdr, Extver=exread, $
		   Extname=ename, /NO_PDU, /no_abort
               endif else begin
                 fits_read, fcb, tempdata, ihdr, Exten_No=exread, $
		   /NO_PDU, /no_abort
               endelse
               if n_elements(ihdr) eq 0 then begin
	         fits_close, fcb
	         fits_open, filename, fcb
	         fits_read, fcb, tempdata, phdr, /no_abort
	         ihdr = ['','']
	         exnum = -1
               endif
	       imsz = size(tempdata)
	       loaddata = 1
             endelse
           endif else begin
             fits_read, fcb, tempdata, phdr, /no_abort
 	     imsz = size(tempdata)
	     if imsz[0] eq 3 then begin
	       if exnum lt 0 then begin
		 if pln eq '*' then begin
		   findx = 0
		   lindx = imsz[3]-1
                 endif else begin
		   findx = fix(pln) > 0 < (imsz[3]-1)
		   lindx = findx
                 endelse
               endif else begin
	         findx = exnum > 0 < (imsz[3]-1)
	         lindx = findx
               endelse
             endif
	     ihdr = ['','']
	     loaddata = 1
           endelse
           fits_close, fcb
           end

         '.pic': Begin
          ; this is a Macintosh pict file
          read_pict, filename, tempdata
          nextn = 0
          ihdr = ['','']
          phdr = ['','']
          imsz = size(tempdata)
          loaddata = 1
         end

        '.tif': Begin
         ; this is a tiff file
         tempdata = read_tiff(filename)
         nextn = 0
         ihdr = ['','']
         phdr = ['','']
         imsz = size(tempdata)
         if imsz[0] eq 3 then begin
           tmp = bytarr(imsz[2],imsz[3],imsz[1])
           tmp[*,*,0] = tempdata[0,*,*]
           tmp[*,*,1] = tempdata[1,*,*]
           tmp[*,*,2] = tempdata[2,*,*]
           tempdata = tmp
           tmp = 0
           if pln eq '*' then begin
	     findx = 0
	     lindx = imsz[1]-1
           endif else begin
	     findx = fix(pln) > 0 < (imsz[1]-1)
	     lindx = findx
           endelse
         endif
         loaddata = 1
         end

         else: Begin
          ; Assume HDF format.
          ua_hdf_read, filename, phdr, tempdata, hdr_flag, image_flag
          nextn = 0
          if image_flag eq 1 then begin
    	    ihdr = ['','']
	    if hdr_flag eq 0 then begin
	      phdr = ['','']
	      str = 'LoadImage: No fits header found in file ' + filename
	      idp3_updatetxt, cinfo, str
            endif
	    imsz = size(tempdata)
	    loaddata = 1
          endif else begin
    	    str = 'File ' + filename + ' not recognized as fits or hdf format'
	    a = Widget_Message(str)
	    loaddata = 0
          endelse
          end
        endcase
  
        if loaddata eq 1 then begin
          for j = findx, lindx do begin
            newim = ptr_new({idp3im})
            if imsz[0] eq 2 then begin
	      tdata = tempdata 
              if nextn gt 0 then begin
                (*newim).extnam = ename
                if exnum ge 0 then begin
                  (*newim).extver = exnum
                  num = setnum(exnum,maxver, 1)
                  (*newim).name = disk + path + name + '_' + num + extn 
	          (*newim).orgname = filename
                endif else begin
	          (*newim).name = filename
	          (*newim).orgname = filename
	          ;(*newim).extnam = ''
	          (*newim).extver = 0
                endelse
              endif else begin
                (*newim).extnam = ''
                (*newim).extver = 0
                (*newim).name = filename
	        (*newim).orgname = filename
              endelse
            endif else begin
	      tdata = tempdata[*,*,j]
	      imsz = size(tempdata)
	      num = setnum(j, imsz[3], 1)
	      (*newim).name = disk + path + name + '_' + num + extn
	      (*newim).extver = j
	      (*newim).extnam = ''
	      (*newim).orgname = filename
            endelse

            ; Set up stuff in the new image structure.
            idp3_imstruct, cinfo, newim, tdata, phdr, ihdr

            ; Save this new image into the image array or structures.
            c = size(*cinfo.images)
            if (c[0] eq 0 and c[1] eq 2) then begin
              tempimages = newim
              if cinfo.autoscale eq 1 then begin
                cinfo.Z1 = (*newim).z1
                cinfo.Z2 = (*newim).z2
              endif
            endif else begin
              tempimages = [*cinfo.images,newim]
              ptr_free,cinfo.images
            endelse
            cinfo.images = ptr_new(tempimages)
          endfor
        endif else begin
          test = Dialog_Message("Sorry, couldn't find file "+filename)
        endelse
      endif else begin
	test = Dialog_Message("Sorry, couldn't find file "+filename)
      endelse
    endwhile
    close, ilun
    free_lun, ilun
    Widget_Control, info.idp3Window, Set_UValue=cinfo
    ; Call the ShowIm routine and exit.
    ; If ShowIm is already running, kill it first.
    if (XRegistered('idp3_showim')) then begin
      geo = Widget_Info(cinfo.ShowImBase, /geometry)
      cinfo.wpos.siwp[0] = geo.xoffset - cinfo.xoffcorr
      cinfo.wpos.siwp[1] = geo.yoffset - cinfo.yoffcorr
      Widget_Control, info.idp3Window, Set_UValue=cinfo
      Widget_Control, cinfo.ShowImBase, /Destroy
    endif
    idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,SELECT:0}
    Widget_Control, cinfo.idp3Window, Get_UValue=info
    ; Update graphics display.
    idp3_display,info
  endif else begin
    test = Dialog_Message("Sorry, couldn't file list file " + lfilename)
  endelse
  if loaddata eq 0 then begin
    Widget_Control, info.idp3Window, Set_UValue=cinfo
    Widget_Control, info.idp3Window, Get_UValue=info
  endif
 Widget_Control, event.top, Set_UValue=info
end

