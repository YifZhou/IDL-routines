pro Idp3_RestorInfo, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo
  tstr = 'Please select file to restore'
  inpath = cinfo.parpath
  infilt = cinfo.parfilter
  filename = Dialog_Pickfile(title=tstr,/Read, /Must_Exist, Get_Path=outpath, $
	     Path=inpath, Filter=infilt)
  cinfo.parpath = outpath
  filename = strtrim(filename(0), 2)
  one = 1.0
  zero = 0.0
  zero_int = 0
  delim = cinfo.name_delim

  ; Check if parameters table exists and load
  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin  
    openr, ilun, filename, /get_lun
    fname = ''
    while not eof(ilun) do begin
      lineOfText = ''
      readf, ilun, lineOfText
      if (strmid(lineOfText,0,8) ne 'Filename') then begin
	if strlen(delim) eq 1 then begin
	  namend = strpos(lineOfText, delim)
	  fname = strmid(lineOfText, 0, namend)
	  fname = strtrim(fname,2)
	  len = strlen(lineOfText) - namend - 1
	  newtext = strmid(lineOfText, namend+1, len)
	  xtmpstr = strsplit(newtext, /extract)
	  num = n_elements(xtmpstr) + 1
	  ttmpstr = strarr(num)
	  ttmpstr[0] = fname
	  ttmpstr[1:num-1] = xtmpstr
        endif else begin
          ttmpstr = strsplit(lineOfText, /extract)
          fname = ttmpstr[0]
        endelse
        xpos = float(ttmpstr[1])
        ypos = float(ttmpstr[2])
	entries = n_elements(ttmpstr)
	Case entries of

	7: Begin
	   rno = zero
	   extnam = ''
	   rot = float(ttmpstr[3])
	   scl = float(ttmpstr[4])
	   bias = float(ttmpstr[5])
	   zoom = float(ttmpstr[6])
	   movamt = one
	   rotamt = zero
	   sclamt = zero
	   pad = zero_int
	   topad = 0
	   rotxpad = zero_int
	   rotypad = zero_int
	   rotcx = zero
	   rotcy = zero
	   xpscl = 1.0d0
	   ypscl = 1.0d0
	   flipy = 0
	   clipmin = 0
	   cmin = zero
	   cminval = zero
	   clipmax = 0
	   cmax = zero
	   cmaxval = zero
	   xpix = zero
	   ypix = zero
	   nxpix = zero
	   nypix = zero
	   lccx = zero
	   lccy = zero
	   dispf = 1
	   vis = 1
	   end
       10: Begin
	   rno = zero
	   extnam = ''
	   rot = float(ttmpstr[3])
	   scl = float(ttmpstr[4])
	   bias = float(ttmpstr[5])
	   zoom = float(ttmpstr[6])
	   movamt = float(ttmpstr[7])
	   rotamt = float(ttmpstr[8])
	   sclamt = float(ttmpstr[9])
	   pad = zero_int
	   topad = 0
	   rotxpad = zero_int
	   rotypad = zero_int
	   rotcx = zero
	   rotcy = zero
	   xpscl = 1.0d0
	   ypscl = 1.0d0
	   flipy = 0
	   clipmin = 0
	   cmin = zero
	   cminval = zero
	   clipmax = 0
	   cmax = zero
	   cmaxval = zero
	   xpix = zero
	   ypix = zero
	   nxpix = zero
	   nypix = zero
	   lccx = zero
	   lccy = zero
	   dispf = 1
	   vis = 1
	   end
       24: Begin
	   rno = zero
	   extnam = ''
	   rot = float(ttmpstr[3])
	   scl = float(ttmpstr[4])
	   bias = float(ttmpstr[5])
	   zoom = float(ttmpstr[6])
	   topad = fix(ttmpstr[7])
	   rotxpad = fix(ttmpstr[8])
	   rotypad = fix(ttmpstr[9])
	   pad = rotxpad
	   rotcx = float(ttmpstr[10])
	   rotcy = float(ttmpstr[11])
	   xpscl = double(ttmpstr[12])
	   ypscl = double(ttmpstr[13])
	   movamt = float(ttmpstr[14])
	   rotamt = float(ttmpstr[15])
	   sclamt = float(ttmpstr[16])
	   flipy = fix(ttmpstr[17])
	   clipbottom = fix(ttmpstr[18])
	   clipmin = float(ttmpstr[19])
	   cminval = float(ttmpstr[20])
	   cliptop = fix(ttmpstr[21])
	   clipmax = float(ttmpstr[22])
	   cmaxval = float(ttmpstr[23])
	   xpix = zero
	   ypix = zero
	   nxpix = zero
	   nypix = zero
	   lccx = zero
	   lccy = zero
	   dispf = 1
	   vis = 1
	   end
       32: Begin
	   rno = zero
	   extnam = ''
	   rot = float(ttmpstr[3])
	   scl = float(ttmpstr[4])
	   bias = float(ttmpstr[5])
	   zoom = float(ttmpstr[6])
	   topad = fix(ttmpstr[7])
	   rotxpad = fix(ttmpstr[8])
	   rotypad = fix(ttmpstr[9])
	   pad = rotxpad
	   rotcx = float(ttmpstr[10])
	   rotcy = float(ttmpstr[11])
	   xpscl = double(ttmpstr[12])
	   ypscl = double(ttmpstr[13])
	   movamt = float(ttmpstr[14])
	   rotamt = float(ttmpstr[15])
	   sclamt = float(ttmpstr[16])
	   flipy = fix(ttmpstr[17])
	   clipbottom = fix(ttmpstr[18])
	   clipmin = float(ttmpstr[19])
	   cminval = float(ttmpstr[20])
	   cliptop = fix(ttmpstr[21])
	   clipmax = float(ttmpstr[22])
	   cmaxval = float(ttmpstr[23])
	   xpix = float(ttmpstr[24])
	   ypix = float(ttmpstr[25])
	   nxpix = float(ttmpstr[26])
	   nypix = float(ttmpstr[27])
	   lccx = float(ttmpstr[28])
	   lccy = float(ttmpstr[29])
	   dispf = fix(ttmpstr[30])
	   vis = fix(ttmpstr[31])
           end
       34: Begin
	   rno = fix(ttmpstr[3])
	   extnam = ttmpstr[4]
	   if extnam eq '-' then extnam = ''
	   rot = float(ttmpstr[5])
	   scl = float(ttmpstr[6])
	   bias = float(ttmpstr[7])
	   zoom = float(ttmpstr[8])
	   topad = fix(ttmpstr[9])
	   rotxpad = fix(ttmpstr[10])
	   rotypad = fix(ttmpstr[11])
	   pad = rotxpad
	   rotcx = float(ttmpstr[12])
	   rotcy = float(ttmpstr[13])
	   xpscl = double(ttmpstr[14])
	   ypscl = double(ttmpstr[15])
	   movamt = float(ttmpstr[16])
	   rotamt = float(ttmpstr[17])
	   sclamt = float(ttmpstr[18])
	   flipy = fix(ttmpstr[19])
	   clipbottom = fix(ttmpstr[20])
	   clipmin = float(ttmpstr[21])
	   cminval = float(ttmpstr[22])
	   cliptop = fix(ttmpstr[23])
	   clipmax = float(ttmpstr[24])
	   cmaxval = float(ttmpstr[25])
	   xpix = float(ttmpstr[26])
	   ypix = float(ttmpstr[27])
	   nxpix = float(ttmpstr[28])
	   nypix = float(ttmpstr[29])
	   lccx = float(ttmpstr[30])
	   lccy = float(ttmpstr[31])
	   dispf = fix(ttmpstr[32])
	   vis = fix(ttmpstr[33])
           end
     else: Begin
	   rno = 0
	   extnam = ''
           rot = zero
	   scl = one
	   bias = zero
	   zoom = one
	   movamt = one
	   rotamt = zero
	   sclamt = zero
	   pad = zero_int
	   topad = 0
	   rotxpad = zero_int
	   rotypad = zero_int
	   rotcx = zero
	   rotcy = zero
	   xpscl = 1.0d0
	   ypscl = 1.0d0
	   flipy = 0
	   clipbottom = 0
	   clipmin = zero
	   cminval = zero
	   cliptop = 0
	   clipmax = zero
	   cmaxval = zero
	   xpix = zero
	   ypix = zero
	   nxpix = zero
	   nypix = zero
	   lccx = zero
	   lccy = zero
	   dispf = 1
	   vis = 1
	  end
    endcase

        ; Check to see of this image exists.
        temp = file_search (fname, Count = fcount)
        if (fname ne '' and fcount gt 0) then begin
          ; Make a new image structure.
          newim = ptr_new({idp3im})
          (*newim).orgname = fname
	  (*newim).extnam = extnam
	  (*newim).extver = rno
	  (*newim).name = fname

	  ua_decompose, fname, disk, path, name, extn, version
	  lextn = strlowcase(extn)
	  if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
	  if lextn eq '.fit' then begin
            ; FITS format
	    ua_fits_open, fname, fcb
	    nextn = fcb.nextend
	    if nextn gt 0 then if  fcb.xtension[1] eq 'TABLE' then nextn = 0
	    if nextn gt 0 then begin
	      ua_fits_read, fcb, temp,phdr,exten_no=0,/Header_Only,/no_abort
	      if strlowcase(extnam) ne 'none' and extnam ne '' then begin
	        maxver = idp3_extver(nextn, fcb.extname, extnam)
		lg = 1
	        if maxver le 0 then begin
	  	  str = 'Restorinfo: Error in extension name'
		  idp3_updatetxt, cinfo, str
		  return
                endif
              endif else begin
		maxver = nextn
		lg = 0
              endelse
	      inst = strtrim(sxpar(phdr, 'INSTRUME'), 2)
	      if inst eq 'NICMOS' then begin
		if rno lt 0 then begin
		  if maxver gt 1 then rno = (maxver-1)
		  exread = 1
                endif else begin
		  rno = rno < (maxver-1)
		  exread = maxver - rno
                endelse
		if maxver gt 1 then begin
		  str = 'Restorinfo: Loading ' + extnam + ' extension ' + $
		    strtrim(string(exread),2) + ' which is sample ' + $
		    strtrim(string(rno),2) + ' (time order)'
                  idp3_updatetxt, cinfo, str
                endif
              endif else begin
		if rno le 0 then rno = 1
		exread = rno
              endelse
	      if lg eq 1 then $
	      ua_fits_read,fcb,tempdata, ihdr, Extver=exread, Extname=extnam, $
		  /NO_PDU $
              else ua_fits_read,fcb,tempdata, ihdr, Exten_no=exread,/NO_PDU
              if rno gt 0 then begin
	        num = setnum(rno,maxver,1)
	        (*newim).name = disk + path + name + '_' + num + extn
              endif
            endif else begin
	      ua_fits_read, fname, tempdata, phdr, /no_abort
	      ; special fix for 3-D WFPC data (access only to 1st chip)
	      imsz = size(tempdata)
	      if imsz[0] eq 3 then begin
		if rno lt 0 then exver = 0 else exver = rno < (imsz[3]-1)
		tempdata = tempdata[*,*,exver]
		num = setnum(rno, imsz[3], 1)
		(*newim).name = disk + path + name + '_' + num + extn
              endif
	      ihdr = ['', '']
            endelse
	    ua_fits_close, fcb
          endif else if lextn eq '.pic' then begin
	    ; this is a Macintosh pict file
	    read_pict, fname, tempdata
	    ihdr = ['','']
	    phdr = ['','']
          endif else if lextn eq '.tif' then begin
	    ; this is a tiff file
	    tempdata = read_tiff(fname)
	    imsz = size(tempdata)
	    if imsz[0] eq 3 then begin
	      tmp = bytarr(imsz[2],imsz[3],imsz[1])
	      tmp[*,*,0] = tempdata[0,*,*]
	      tmp[*,*,1] = tempdata[1,*,*]
	      tmp[*,*,2] = tempdata[2,*,*]
	      tempdata = tmp
	      tmp = 0
	      if rno lt 0 then exver = 0 else exver = rno < (imsz[1]-1)
	      tempdata = tempdata[*,*,exver]
	      num = setnum(rno, imsz[1], 1)
	      (*newim).name = disk + path + name + '_' + num + extn
            endif
	    ihdr = ['', '']
	    phdr = ['', '']
          endif else begin
            ; Assume HDF format.
	    ua_hdf_read, fname, phdr, tempdata, hdr_flag, image_flag
	    if image_flag eq 1 then begin
	      ihdr = ['','']
	      if hdr_flag eq 0 then begin
	        phdr = ['','']
	        str = 'Restorinfo: No fits header found in file ' + fname
		idp3_updatetxt, cinfo, str
              endif
            endif else begin
	      str = 'Restorinfo: File ' + fname + $
		    ' not recognized as fits or hdf format'
	      idp3_updatetxt, cinfo, str
            endelse
          endelse

	 ; print out filename to dialog window
	 str = 'Restorinfo: Loading: ' + fname + string(rno)
	 idp3_updatetxt, cinfo, str

         ; Load up the new image with data, etc.
	 cz = size(tempdata)
	 if cz[0] eq 3 then begin
	   tempdata = tempdata[*,*,0]
	   cz = size(tempdata)
         endif
	 tempmask = intarr(cz[1],cz[2])
	 tempmask[*,*] = 1
	 notnan = finite(tempdata)
	 gcount = 0l
	 bcount = 0l
	 good = where(notnan eq 1, gcount)
	 bad = where(notnan eq 0, bcount)
	 if bcount gt 0l then begin
	   str = 'Restorinfo: ' + string(bcount) + ' NaN pixels'
	   idp3_updatetxt, cinfo, str
	   tempdata[bad] = 0.
	   tempmask[bad] = 0
	   nan_xp = bad MOD cz[1]
	   nan_yp = bad / cz[1]
	   (*newim).xnan = ptr_new(nan_xp)
	   (*newim).ynan = ptr_new(nan_yp)
         endif else begin
	   (*newim).xnan = ptr_new()
	   (*newim).ynan = ptr_new()
         endelse
         (*newim).data = ptr_new(tempdata)
	 (*newim).mask = ptr_new(tempmask)
         (*newim).phead = ptr_new(phdr)
         (*newim).ihead = ptr_new(ihdr)
	 temphead = [phdr, ihdr]
         (*newim).xsiz = cz[1]
         (*newim).ysiz = cz[2]
	 (*newim).viewtext = 0L
	 (*newim).viewwin = 0L
	 (*newim).cntrdtext = 0L
	 (*newim).cntrdwin = 0L
	 instr = strtrim(sxpar(temphead, 'INSTRUME'),2)
	 if instr eq 'NICMOS' then det = sxpar(temphead, 'CAMERA') $
	   else det = sxpar(temphead, 'DETECTOR')
         (*newim).xplate = xpix
         (*newim).yplate = ypix
	 (*newim).nxplate = nxpix
	 (*newim).nyplate = nypix
	 (*newim).xpscl = xpscl
	 (*newim).ypscl = ypscl
	 (*newim).instrume = instr
         aa = size(det)
	 if aa[1] eq 2 or aa[1] eq 3 $
	   then (*newim).detector = strtrim(string(det),2) $
	   else (*newim).detector = det
	 if rotcx eq zero and rotcy eq zero then begin
           (*newim).rotcx = c[1]/2
           (*newim).rotcy = c[2]/2
         endif else begin
	   (*newim).rotcx = rotcx
	   (*newim).rotcy = rotcy
         endelse
	 (*newim).olccx = lccx
	 (*newim).olccy = lccy
	 (*newim).lccx = lccx
	 (*newim).lccy = lccy
	 (*newim).clipbottom = clipbottom
	 (*newim).clipmin = clipmin
	 (*newim).cminval = cminval
	 (*newim).cliptop = cliptop
	 (*newim).clipmax = clipmax
	 (*newim).cmaxval = cmaxval
         c = imscale(tempdata,10.0)
         (*newim).z1 = c[0]
         (*newim).z2 = c[1]
         (*newim).dispf = dispf
         (*newim).vis = vis
         (*newim).zoom = zoom
         (*newim).scl = scl
         (*newim).bias = bias
	 (*newim).rot = rot
	 (*newim).pad = pad
	 (*newim).topad = topad
	 (*newim).rotxpad = rotxpad
	 (*newim).rotypad = rotypad
	 (*newim).movamt = movamt
	 (*newim).rotamt = rotamt
	 (*newim).sclamt = sclamt
	 (*newim).flipy = flipy
         fracsa = xpos - fix(xpos)
         intsa  = float(fix(xpos - fracsa))
         (*newim).xpoff = fracsa
         (*newim).xoff = intsa
         fracsa = ypos - fix(ypos)
         intsa  = float(fix(ypos - fracsa))
         (*newim).ypoff = fracsa
         (*newim).yoff = intsa
	 wcs = idp3_getwcs(temphead, crval1, crval2, crpix1, crpix2, $
			   cd11, cd12, cd21, cd22)
	 (*newim).crpix1 = crpix1
	 (*newim).crpix2 = crpix2
	 (*newim).crval1 = crval1
	 (*newim).crval2 = crval2
	 (*newim).cd11 = cd11
	 (*newim).cd12 = cd12
	 (*newim).cd21 = cd21
	 (*newim).cd22 = cd22
	 (*newim).acrpix1 = crpix1
	 (*newim).acrpix2 = crpix2
	 (*newim).acrval1 = crval1
	 (*newim).acrval2 = crval2
	 (*newim).acd11 = cd11
	 (*newim).acd12 = cd12
	 (*newim).acd21 = cd21
	 (*newim).acd22 = cd22
	 (*newim).valid_wcs = wcs
	 (*newim).maskvis = 0

         ; Save this new image into the image array or structures.
         c = size(*cinfo.images)
         if (c[0] eq 0 and c[1] eq 2) then begin
           ; If this is the first image loaded then set Z1 Z2 from this one.
 	   tempimages = newim
	   if cinfo.autoscale eq 1 then begin
	     cinfo.Z1 = (*newim).z1
	     cinfo.Z2 = (*newim).z2
           endif
         endif else begin
	   ; If this isn't the first image loaded, concatinate this image
	   ; onto the existing list of images and replace the old list with
	   ; the new list.
	   tempimages = [*cinfo.images,newim]
	   ptr_free,cinfo.images
         endelse
         cinfo.images = ptr_new(tempimages)
         Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
       endif else begin
	 str = "Sorry, couldn't find file "+fname
	 stat = idp3_Message(cinfo, str)
	 if stat eq 0 then return
       endelse
     endif
   endwhile
   close, ilun
   free_lun, ilun
;  Call the ShowIm routine and exit.
;  If ShowIm is already running, kill it first.
   if (XRegistered('idp3_showim')) then begin
     geo = Widget_Info(cinfo.ShowImBase, /geometry)
     cinfo.wpos.siwp[0] = geo.xoffset - cinfo.xoffcorr
     cinfo.wpos.siwp[1] = geo.yoffset - cinfo.yoffcorr
     Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
     Widget_Control, cinfo.ShowImBase, /Destroy
   endif
   idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,SELECT:0}
   Widget_Control, cinfo.idp3Window, Get_UValue=info
   Widget_Control, cinfo.idp3Window, Get_UValue=cinfo
 endif else begin
   test = Dialog_Message("Sorry, couldn't find file "+filename)
 endelse

  ; Update graphics display.
  idp3_display,info

  Widget_Control, event.top, Set_UValue=info

end

