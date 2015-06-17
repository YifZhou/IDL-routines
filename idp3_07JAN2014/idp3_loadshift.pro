pro Idp3_LoadShift, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo
  ; We keep track of the path the user picks files from.
  inpath = cinfo.imagepath
  filename = Dialog_Pickfile(/Read, /Must_Exist, Get_Path=outpath, Path=inpath)
  cinfo.imagepath = outpath
  filename = strtrim(filename(0), 2)
  setdef = -1
  outer = cinfo.outer_radius
  inner = cinfo.inner_radius
  master_shifts = cinfo.master_shifts
  mask = cinfo.coron_mask
  maskx = cinfo.mask_xcenter
  masky = cinfo.mask_ycenter
  mask_flag = 0

  ; Check if master shift table given, exists and load
  if strlen(master_shifts) eq 0 then begin 
    tstr = 'No master shifts file defined - Select below'
    tmp = Dialog_Pickfile(/Read, /Must_Exist, title=tstr)
    cinfo.master_shifts = tmp
  endif else begin
    tmp = idp3_findfile(master_shifts)
    if tmp eq '' then begin
      tstr = 'Master shifts not found - Select below'
      tmp = Dialog_Pickfile(/Read, /Must_Exist, title=tstr)
      cinfo.master_shifts = tmp
    endif
  endelse
  if tmp eq '' then begin
    str = 'LoadShifts: WARNING: Shifts file not found' 
    idp3_updatetxt, cinfo, str
    return
  endif else begin
    str = 'LoadShifts: Reading master shifts file: ' + tmp
    idp3_updatetxt, cinfo, str
    openr, slun, tmp, /get_lun
    fname = ''
    sxpos = ''
    sypos = ''
    indx = 0
    while not eof(slun) do begin
      lineOfText = ''
      readf, slun, lineOfText
      ttmpstr = strsplit(lineOfText, /extract)
      if indx eq 0 then begin
        fname = ttmpstr[0]
        sxpos = ttmpstr[1]
        sypos = ttmpstr[2]
	indx = indx + 1
      endif else begin
	fname = [fname, ttmpstr[0]]
	sxpos = [sxpos, ttmpstr[1]]
	sypos = [sypos, ttmpstr[2]]
	indx = indx + 1
      endelse
    endwhile
  endelse
  ; Check if mask is given, exists and load
  if strlen(mask) eq 0 then begin
    str = 'LoadShifts: WARNING: Mask file is not defined'
    idp3_updatetxt, cinfo, str
    mask_flag = 0
  endif else begin
    tmp = idp3_findfile(mask)
    if tmp eq '' then begin
      str = 'LoadShifts: WARNING: Mask file not found'
      idp3_updatetxt, cinfo, str
      return
    endif else begin
      str = 'LoadShifts: Reading mask file: ' + tmp
      idp3_updatetxt, cinfo, str
      ua_fits_read, tmp, mask_dat, mskhdr
      msize = size(mask_dat)
      mask_flag = 1
    endelse
  endelse

  ; Check to see if this list exists.
  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin
    ; Open the list.
    openr, ilun, filename, /GET_LUN
    while not eof(ilun) do begin
      ; Read a line from the file.
      lineOfText = ''
      readf, ilun, lineOfText
      tempfname = strtrim(lineOfText, 2)
      ua_decompose, tempfname, disk, path, xname, extn, version
      shortname = strmid(xname, 0, 6)
      i = -1 
      found = 0
      repeat begin
	i = i + 1
	shn = strmid(fname[i],0,6)
      endrep until (shn EQ shortname or i eq indx-1)
      if shn eq shortname then begin 
        if setdef lt 0 then begin
  	  master_xs = float(sxpos[i])
  	  master_ys = float(sypos[i])
          setdef = 0 
	  found = 1
          defx = fix(master_xs + 0.5)
          defy = fix(master_ys + 0.5)
        endif else begin
	  current_xs = float(sxpos[i])
	  current_ys = float(sypos[i])
          defx = fix(current_xs + 0.5)
          defy = fix(current_ys + 0.5)
	  found = 2
        endelse
      endif else begin
	msg = 'Sorry, ' + tempfname + ' not matched in database - Cannot load'
        test = Dialog_Message(msg)
      endelse
      if found ge 1 then begin
	new_mask = intarr(msize[1], msize[2])
	new_mask[*,*] = 0
	if mask_flag eq 1 then begin
	  dif = defx - maskx
	  if dif gt 0 then begin
	    begx = dif
	    endx = msize[1]-1
          endif else begin
	    begx = 0
	    endx = msize[1] - 1 + dif
          endelse
          dif = defy - masky
	  if dif gt 0 then begin
	    begy = dif
	    endy = msize[2] - 1
          endif else begin
	    begy = 0
	    endy = msize[2] - 1 + dif
          endelse
          lenx = endx - begx
	  leny = endy - begy
	  new_mask[begx:endx,begy:endy] = mask_dat[0:lenx,0:leny]
        endif
        ; Check to see of this image exists.
        temp = file_search (tempfname, Count = fcount)
        if (lineOfText ne '' and fcount gt 0) then begin
  	  ; Make a new image structure.
          newim = ptr_new({idp3im})
	  (*newim).name = tempfname

          ilen = strlen(tempfname)
	  ua_decompose, tempfname, disk, path, name, extn, version
	  lextn = strlowcase(extn)
	  if lextn eq '.fits' or lextn eq '.fit' then begin
	    ; FITS format
	    str = 'LoadShifts: Open data file: ' + tempfname
	    idp3_updatetxt, cinfo, str
	    ua_fits_open, tempfname, fcb
	    if fcb.nextend gt 0 then begin
	      ua_fits_read, fcb, temp, phdr,Exten_No=0,/Header_Only,/no_abort
	      ua_fits_read, fcb, tempdata, ihdr, Extver=1, /NO_PDU, /no_abort
            endif else begin
	      ua_fits_read, fcb, tempdata, phdr, /no_abort
	      ihdr = ['','']
            endelse
	    ua_fits_close, fcb
	  endif else begin
	    ; Assume HDF format.
	    ua_hdf_read, tempfname, phdr, tempdata, hdr_flag, image_flag
	    if image_flag eq 1 then begin
	      ihdr = ['','']
	      if hdr_flag eq 0 then begin
		phdr = ['','']
		str = 'LoadShifts: No fits header found in file ' + tempfname
		idp3_updatetxt, cinfo, str
              endif
            endif else begin
	      str = 'File ' + tempfname + $
		  ' not recognized as fits or hdf format'
              idp3_updatetxt, cinfo, str
            endelse
          endelse

	  ; Load up the new image with data, etc.
	  cz = size(tempdata)
	  alpha = fltarr(cz[1],cz[2])
	  alpha[*,*] = 0.
	  notnan = finite(tempdata)
	  good = where(notnan eq 1, gcount)
	  if gcount gt 0 then alpha[good] = 1.
	  bad = where(notnan eq 0, bcount)
	  if bcount gt 0 then tempdata[bad] = 0.
	  (*newim).data = ptr_new(tempdata)
	  (*newim).phead = ptr_new(phdr)
	  (*newim).ihead = ptr_new(ihdr)
	  temphead = [phdr, ihdr]
	  c = size(tempdata)
	  (*newim).xsiz = c[1]
	  (*newim).ysiz = c[2]
	  instr = strtrim(sxpar(temphead, 'INSTRUME'),2)
	  if instr eq 'NICMOS' then begin
	    det = sxpar(temphead, 'CAMERA') 
	    sdet = strtrim(string(det),2)
            od = sxpar(temphead, 'DATE-OBS')
	    ot = sxpar(temphead, 'TIME-OBS')
	    odsz = size(od)
	    otsz = size(ot)
	    if odsz[1] eq 7 and otsz[1] eq 7 $
	      then idp3_getplate,instr,sdet,xpsiz,ypsiz,odate=od,otime=ot $
	      else idp3_getplate,instr,sdet,xpsiz,ypsiz
          endif else begin
	    det = sxpar(temphead, 'DETECTOR')
	    if instr eq 'WFPC2' then sdet=strtrim(string(det),2) else sdet=det
	    aa = size(sdet)
	    if aa[1] ne 7 then sdet = strtrim(string(sdet),2)
	    idp3_getplate, instr, sdet, xpsiz, ypsiz
          endelse
          (*newim).xplate = xpsiz
	  (*newim).yplate = ypsiz
          (*newim).oxplate = xpsiz
	  (*newim).oyplate = ypsiz
	  (*newim).nxplate = 0.0
	  (*newim).nyplate = 0.0
	  (*newim).xpscl = 1.0
	  (*newim).ypscl = 1.0
	  (*newim).instrume = instr
	  (*newim).detector = sdet
	  if cinfo.pixorg eq 0 then begin
	    (*newim).rotcx = (c[1]-1)/2.
	    (*newim).rotcy = (c[2]-1)/2.
          endif else begin
	    (*newim).rotcx = c[1]/2.
	    (*newim).rotcy = c[2]/2.
          endelse
	  (*newim).rotxpad = 0
	  (*newim).rotypad = 0
	  (*newim).clipbottom = 0
	  (*newim).clipmin = min(*(*newim).data)
	  (*newim).cminval = min(*(*newim).data)
	  (*newim).cliptop = 0
	  (*newim).clipmax = max(*(*newim).data)
	  (*newim).cmaxval = max(*(*newim).data)
	  c2 = imscale(tempdata,10.0)
	  (*newim).z1 = c2[0]
	  (*newim).z2 = c2[1]
	  (*newim).dispf = ADD
	  (*newim).vis = 1
	  (*newim).zoom = 1.0
	  (*newim).scl = 1.0
	  (*newim).bias = 0.0
	  (*newim).rot = 0.0
	  (*newim).sclamt = 0.0
	  (*newim).movamt = 0.0
	  (*newim).rotamt = 0.0
	  (*newim).topad = 0
	  (*newim).pad = 0
	  (*newim).lccx = -1.0
	  (*newim).lccy = -1.0
	  (*newim).olccx = -1.0
	  (*newim).olccy = -1.0
          xb = 0
          xe = c[1]-1
          yb = 0
          ye = c[2]-1
          xcen = sxpos[i]
          ycen = sypos[i]
          pospts = (outer^2 - inner^2) * 10
          dat = fltarr(pospts)
          minx = FIX(xcen - outer + 0.5) > xb
          maxx = FIX(xcen + outer + 0.5) < xe
          miny = FIX(ycen - outer + 0.5) > yb
          maxy = FIX(ycen + outer + 0.5) < ye
          npt = 0
          for j = miny, maxy do begin
            for k = minx, maxx do begin
  	      r = sqrt((k-xcen)^2 + (j-ycen)^2) 
	      if r LE outer then begin
                if new_mask[k,j] eq 0 then begin
	          dat[npt] = tempdata[k,j]
	          npt = npt + 1
	        endif else begin
                endelse
              endif
            endfor
          endfor
          results = moment(dat[0:npt-1])
          if setdef le 0 then begin
	    master_flux = results[0]
	    (*newim).scl = 1.0
	    setdef = 1
          endif else begin
	    current_flux = results[0]
	    (*newim).scl = master_flux/current_flux
	    str = 'LoadShift: ' + string(current_flux) + string(master_flux) + $
		  string((*newim).scl)
            idp3_updatetxt, cinfo, str
          endelse
	  if setdef eq 1 and found gt 1 then begin
	    nxshift = master_xs - current_xs 
	    fracsa = nxshift - fix(nxshift)
	    intsa  = float(fix(nxshift - fracsa))
	    (*newim).xpoff = fracsa
	    (*newim).xoff = intsa
	    nyshift = master_ys - current_ys
	    fracsa = nyshift - fix(nyshift)
	    intsa  = float(fix(nyshift - fracsa))
	    (*newim).ypoff = fracsa
	    (*newim).yoff = intsa
          endif

	  ; Save this new image into the image array or structures.
	  c = size(*cinfo.images)
	  if (c[0] eq 0 and c[1] eq 2) then begin
	    ; If this is the first image loaded then set Z1 Z2 from this one.
	    tempimages = newim
	    cinfo.Z1 = (*newim).z1
	    cinfo.Z2 = (*newim).z2
	  endif else begin
	    ; If this isn't the first image loaded, concatinate this image
	    ; onto the existing list of images and replace the old list with
	    ; the new list.
	    tempimages = [*cinfo.images,newim]
	    ptr_free,cinfo.images
	  endelse
	  cinfo.images = ptr_new(tempimages)
	  Widget_Control, cinfo.idp3Window, Set_UValue=cinfo

	  ; Call the ShowIm routine and exit.
	  ; If ShowIm is already running, kill it first.
	  if (XRegistered('idp3_showim')) then begin
            geo = Widget_Info(cinfo.ShowImBase, /geometry)
            cinfo.wpos.siwp[0] = geo.xoffset - cinfo.xoffcorr
            cinfo.wpos.siwp[1] = geo.yoffset - cinfo.yoffcorr
            Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
	    Widget_Control, cinfo.ShowImBase, /Destroy
	  endif
          idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,$
	     SELECT:0}
	  Widget_Control, cinfo.idp3Window, Get_UValue=info
	  Widget_Control, cinfo.idp3Window, Get_UValue=cinfo
        endif else begin
          test = Dialog_Message("Sorry, couldn't find file "+tempfname)
        endelse
      endif
    endwhile
    close, ilun
    free_lun, ilun
  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  ; Update graphics display.
  idp3_display,info

  Widget_Control, event.top, Set_UValue=info

end

