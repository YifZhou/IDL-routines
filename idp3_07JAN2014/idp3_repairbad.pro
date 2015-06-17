pro idp3_repairbaddone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_repairbad_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=repairinfo
  Widget_Control, repairinfo.info.idp3Window, GET_UValue=info

  case event.id of

  repairinfo.selectfilename: begin
    Widget_Control, repairinfo.selectfilename, Get_Value = temp
    repairinfo.filename = strtrim(temp[0],2)
  end

  repairinfo.selectlistname: begin
    Widget_Control, repairinfo.selectlistname, Get_Value = temp
    repairinfo.listname = strtrim(temp[0],2)
  end

  repairinfo.selectmaskname: begin
    Widget_Control, repairinfo.selectmaskname, Get_Value = temp
    repairinfo.maskname = strtrim(temp[0],2)
  end

  repairinfo.browsefileButton: begin
    inpath = info.imagepath
    infilt = info.imfilter
    filevalue = Dialog_Pickfile(/Read, title='Please select bad pixel file', $
		Path=inpath, Filter=infilt)
    filename = strtrim(filevalue[0],2)
    Widget_Control, repairinfo.selectfilename, Set_Value = filename
    repairinfo.filename = filename
  end

  repairinfo.browselistButton: begin
    filevalue = Dialog_Pickfile(/Read, title='Please select list file')
    listname = strtrim(filevalue[0],2)
    Widget_Control, repairinfo.selectlistname, Set_Value = listname
    repairinfo.listname = listname
  end

  repairinfo.browsemaskButton: begin
    filevalue = Dialog_Pickfile(/Read, title='Please select Mask File')
    maskname = strtrim(filevalue[0],2)
    Widget_Control, repairinfo.selectmaskname, Set_Value = maskname
    repairinfo.maskname = maskname
  end

  repairinfo.fileButton: begin
    Widget_Control, repairinfo.fileButton, Get_Value=barray
    if barray[0] eq 1 then print, $
      'Bad Pixel File Selected'
  end

  repairinfo.listButton: begin
    Widget_Control, repairinfo.listButton, Get_Value=barray
    if barray[0] eq 1 then print, $
      'Bad Pixel List Selected'
  end

  repairinfo.badmField: begin
    Widget_Control, repairinfo.badmField, Get_Value = temp
  end

  repairinfo.badimField: begin
    Widget_Control, repairinfo.badimField, Get_Value = temp
  end

  repairinfo.badlField: begin
    Widget_Control, repairinfo.badlField, Get_Value = temp
  end

  repairinfo.badgField: begin
    Widget_Control, repairinfo.badgField, Get_Value = temp
  end

  repairinfo.badButtons: begin
  end

  repairinfo.baddField: begin
    Widget_Control, repairinfo.baddField, Get_Value = temp
  end

  repairinfo.ksizeField: begin
    Widget_Control, repairinfo.ksizeField, Get_Value = temp
  end

  repairinfo.bsizeField: begin
    Widget_Control, repairinfo.bsizeField, Get_Value = temp
  end

  repairinfo.fwhmField: begin
    Widget_Control, repairinfo.fwhmField, Get_Value = temp
  end

  repairinfo.mButtons: begin
  end

  repairinfo.sButtons: begin
  end

  repairinfo.nameField: begin
  end

  repairinfo.appField: begin
  end

  repairinfo.pathField: begin
  end

  repairinfo.maskButtons: begin
    Widget_Control, repairinfo.maskButtons, Get_Value=barray
    if barray eq 1 then print, $
      'Excluding pixels from repair with internal mask' 
    if barray eq 2 then print, $
      'Excluding pixels from repair with mask file' 
    
  end

  repairinfo.computeButton: begin
    Widget_Control, repairinfo.listButton, Get_Value=dolist
    if dolist eq 1 then begin
      Widget_Control, repairinfo.selectlistname, Get_Value=templist
      repairinfo.listname = strtrim(templist[0],2)
      if strlen(repairinfo.listname) eq 0 then begin
        stat = Widget_Message('No List Filename Given!')
        return
      endif
      tmp = file_search(repairinfo.listname, Count=fcount)
      if fcount gt 0 then begin
        openr, llun, repairinfo.listname, /Get_Lun
        str = ' '
        while not eof (llun) do begin
  	  readf, llun, str
	  if strmid(str, 0, 1) NE ";" then begin
	    tmpstrs = strsplit(str, /extract)
	    if n_elements(xpos) eq 0 then begin
	      xpos = fix(tmpstrs[0])
	      ypos = fix(tmpstrs[1])
            endif else begin
	      xpos = [xpos, fix(tmpstrs[0])]
	      ypos = [ypos, fix(tmpstrs[1])]
            endelse
          endif
        endwhile
        close, llun
        free_lun, llun
      endif else begin
        stat = Widget_Message('List File not found!')
        return
      endelse
    endif

    Widget_Control, repairinfo.fileButton, Get_Value=dofile
    if dofile eq 1 then begin
      Widget_Control, repairinfo.selectfilename, Get_Value=tempfile
      repairinfo.filename = strtrim(tempfile[0], 2)
      if strlen(repairinfo.filename) eq 0 then begin
        stat = Widget_Message('No Filename given!')
        return
      endif
      tmp = file_search(repairinfo.filename, Count=fcount)
      if fcount gt 0 then begin
        ua_fits_read, repairinfo.filename, badpixmap, phdr
      endif else begin
        stat = Widget_Message('File not found!')
        return
      endelse
    endif

    Widget_Control, repairinfo.maskButtons, Get_Value=maskid
    if maskid eq 1 then dointmask = 1 else dointmask = 0
    if maskid eq 2 then doextmask = 1 else doextmask = 0
    if doextmask eq 1 then begin
      Widget_Control, repairinfo.selectmaskname, Get_Value=tempfile
      repairinfo.maskname = strtrim(tempfile[0], 2)
      if strlen(repairinfo.maskname) eq 0 then begin
        stat = Widget_Message('No Filename given!')
        return
      endif
      tmp = file_search(repairinfo.maskname, Count=fcount)
      if fcount gt 0 then begin
        ua_fits_read, repairinfo.maskname, imask, phdr
      endif else begin
        stat = Widget_Message('File not found!')
        return
      endelse
    endif

    Widget_Control, repairinfo.badButtons, Get_Value=badid
    dovalue = badid[0]
    dogtvalue = badid[1]
    doltvalue = badid[2]
    donan = badid[3]

    sum = dolist + dofile + dovalue + doltvalue + dogtvalue + donan + $
	  dointmask + doextmask
    if sum le 0 then begin
      stat = Widget_Message('No ID Type Selected!')
      return
    endif

    c = size(info.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'Bad Pixel Repair: No images loaded!'
      idp3_updatetxt, info, str
      return
    endif
    ims = (*info.images)
    moveim = info.moveimage
    numimages = n_elements(*info.images)
    non=0
    for i = 0, numimages-1 do begin
      if (*(*info.images)[i]).vis eq 1 then non = non+1
    endfor
    if non lt 1 then begin
      str = 'Bad Pixel Repair: No images ON!'
      idp3_updatetxt, info, str
      return
    endif
    Widget_Control, repairinfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message('Must select IDP3, File, or both for results')
      return
    endif
    sav2idp3 = barray[0]
    sav2file = barray[1]
    Widget_Control, repairinfo.appField, Get_Value = temp
    appname = strtrim(temp[0],2)
    if strlen(appname) eq 0 then append = 0 else append = 1
    Widget_Control, repairinfo.nameField, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      if append eq 0 then begin
        stat = Widget_Message('Must give name or append for results')
        return
      endif else use_orgname = 1
    endif else begin
      saveiname = idp3name
      use_orgname = 0
      if non gt 1 then begin
	stat = Widget_Message('Name conflict for multiple images')
	return
      endif
    endelse
    sfits = info.sfits
    if sav2file eq 1 then begin
      Widget_Control, repairinfo.pathField, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if plen eq 0 then begin
	CD, current=current
	filepath = current
	Widget_Control, repairinfo.pathField, Set_Value = filepath
      endif
      if strmid(filepath, plen-1) ne info.delim $
	then filepath = filepath + info.delim
      saveinpath = filepath
    endif
    for i = 0, numimages-1 do begin
      im = (*info.images)[i]
      if (*im).vis eq 1 then begin
	if append eq 1 then begin
	  if use_orgname eq 1 then $
	    ua_decompose, (*im).orgname, disk, path, oname, extn, ver $
	    else ua_decompose, idp3name, disk, path, oname, extn, ver
	  if strlen(extn) eq 0 then extn = '.fits'
	  saveiname = oname + '_' + appname + extn
        endif
        image = *(*im).data
        imsz = size(image)
        bdmask = intarr(imsz[1],imsz[2])
        bdmask[*,*] = 1

        if dolist eq 1 then begin
	  ; add bad pixels from list
	  for jj = 0, n_elements(xpos)-1 do begin
	    bdmask[xpos[jj],ypos[jj]] = 0
          endfor
	  str = string(n_elements(xpos)) + ' bad pixels from list; ' $
	       + repairinfo.listname
	  idp3_updatetxt, info, str
        endif

        if dofile eq 1 then begin
	  ; add bad pixels from file
          Widget_Control, repairinfo.badmField, Get_Value=badmval
	  badm = where(badpixmap eq badmval, badmcnt)
	  if badmcnt gt 0 then begin
	    bdmask[badm] = 0
	    str = string(badmcnt) + ' bad pixels from file: ' + $
		 repairinfo.filename
	    idp3_updatetxt, info, str
          endif
        endif 
      
	if dovalue eq 1 then begin
          ; add bad pixels of specified data value in image
	  Widget_Control, repairinfo.baddField, Get_Value=baddval
	  badd = where(image eq baddval, baddcnt)
	  if baddcnt gt 0 then begin
	    bdmask[badd] = 0
	    str = string(baddcnt) + ' bad pixels = ' + string(baddval)
          endif else begin
	    str = 'No pixels of value: ' + string(baddval) + 'found to repair'
	    idp3_updatetxt, info, str
          endelse
        endif

        if dogtvalue eq 1 then begin
	  ; add bad pixels greater than specified data value in image
	  Widget_Control, repairinfo.badgField, Get_Value=badgval
	  badg = where(image gt badgval, badgcnt)
	  if badgcnt gt 0 then begin
	    bdmask[badg] = 0
	    str = string(badgcnt) + ' bad pixels > ' + string(badgval)
	    idp3_updatetxt, info, str
          endif else begin
	    str = 'No pixels greater than ' + string(badgval) + ' found to repair'
	    idp3_updatetxt, info, str
          endelse
        endif

        if doltvalue eq 1 then begin
	  ; add bad pixels less than specified data value in image
          Widget_Control, repairinfo.badlField, Get_Value=badlval
	  badl = where(image le badlval, badlcnt)
	  if badlcnt gt 0 then begin
	    bdmask[badl] = 0
	    str = string(badlcnt) + ' bad pixels < ' + string(badlval)
	    idp3_updatetxt, info, str
          endif else begin
	    str = 'No pixels less than ' + string(badlval) + ' found to repair'
	    idp3_updatetxt, info, str
          endelse
        endif

        if donan eq 1 then begin
	  ; add NaN pixels to mask
          xnan = *(*im).xnan
	  ynan = *(*im).ynan
	  if n_elements(xnan) gt 0 then begin
	    for jj = 0, n_elements(xnan)-1 do begin
	      bdmask[xnan[jj], ynan[jj]] = 0
            endfor
	    str = string(n_elements(xnan)) + ' NaN pixels found to repair'
	    idp3_updatetxt, info, str
          endif else begin
	    str = 'No NaN pixels in image to repair'
	    idp3_updatetxt, info, str
          endelse
        endif
    
        if dointmask eq 1 or doextmask eq 1 then begin
          Widget_Control, repairinfo.badimField, Get_Value=badimvalue
	  if dointmask eq 1 then begin
	    if ptr_valid((*im).mask) then begin
	      imask = *(*im).mask 
            endif else begin
	      str = 'Invalid Mask'
	      idp3_updatetxt, info, str
              return
            endelse
          endif
	  badim = where(imask ne badimvalue, badicnt)
	  if badicnt gt 0 then begin
	    expix = where(imask eq badimvalue, excnt)
	    print, excnt, ' pixels excluded by mask'
            ttmask = intarr(imsz[1],imsz[2])
            ttmask[*,*] = 1
	    bb = where(imask ne badimvalue AND bdmask eq 0, bbcnt)
	    if bbcnt gt 0 then begin
	      ttmask [bb] = 0
	      str = 'Total of ' + string(bbcnt) + ' pixels repaired'
	      idp3_updatetxt, info, str
	      bdmask = ttmask
            endif else begin
	      str = 'All bad pixels excluded by mask'
	      idp3_updatetxt, info, str
            endelse
          endif else begin
	    str = 'No pixels in mask to exclude'
	    idp3_updatetxt, info, str
          endelse
        endif

	tmpmask = bdmask
        ; check that there are some bad pixels to repair
        bad = where(bdmask eq 0, cnt)
        if cnt gt 0 then begin
	  str = string(cnt) + ' pixels to be repaired'
	  idp3_updatetxt, info, str
	  ; repair pixels
	  res = array_indices(bdmask, bad)
	  xbadpix = res[0,*]
	  ybadpix = res[1,*]
	  Widget_Control, repairinfo.mButtons, Get_Value=method
	  if method eq 0 then begin
	    Widget_Control, repairinfo.ksizeField, Get_Value=ksize
	    Widget_Control, repairinfo.FWHMField, Get_Value=fwhm
	    fixim = badpixels(image, bdmask, radius=ksize, fwhm=fwhm)
	    tmpmask[bad] = 1
          endif else begin
	    Widget_Control, repairinfo.bsizeField, Get_Value=boxsize
	    halfbox = boxsize/2
	    fixim = image
	    for kk = 0L, n_elements(xbadpix)-1 do begin
	      x1 = xbadpix[kk] - halfbox > 0
	      x2 = xbadpix[kk] + halfbox < (imsz[1]-1)
	      y1 = ybadpix[kk] - halfbox > 0
	      y2 = ybadpix[kk] + halfbox < (imsz[2]-1)
	      subim = image[x1:x2,y1:y2]
	      submask = bdmask[x1:x2,y1:y2]
	      gg = where(submask eq 1, gcnt)
	      bb = where(submask eq 0, bbcnt)
	      if bbcnt gt (boxsize ^ 2 - 1)/2 then begin
		print, 'Not enough good pixels'
              endif else begin
		med = median(subim[gg], /even)
		fixim[xbadpix[kk], ybadpix[kk]] = med
		tmpmask[xbadpix[kk], ybadpix[kk]] = 1
              endelse
            endfor
          endelse
          ; save results
          if sav2file eq 1 then begin
            filename = filepath + saveiname
            ua_decompose, filename, disk, path, name, extn, vers
            openw, lun, 'idp3_tmp.txt', error=err, /get_lun
            if err ne 0 then begin
	      stat = Widget_Message('Error in Path')
	      return
            endif else begin
	      close, lun
	      free_lun, lun
            endelse
          endif
          final = fixim
          imsz = size(final)
          fsz = [imsz[1],imsz[2]]
          l1 = i
          l2 = i
	  if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	    else str = 'Flux Conserved'
          idp3_sethdr, ims, i, sfits, phdr, ihdr, fsz, l1, l2, str
          if sav2idp3 eq 1 then begin
            ; update images structure
	    if ptr_valid((*im).mask) then begin
              b = where(tmpmask eq 1, bcnt)
	      final_msk = *(*im).mask
	      if bcnt gt 0 then final_msk(b) = 1
            endif else begin
              final_msk = intarr(imsz[1], imsz[2])
              final_msk[*,*] = 1
	      b = where(tmpmask eq 0, bcnt)
              if bcnt gt 0 then final_msk[b] = 0
            endelse
	    newim = ptr_new({idp3im})
            idp3_setimstruct, newim, phdr, ihdr, im, sav2file
            (*newim).name = saveiname
            (*newim).orgname = saveiname
            (*newim).data = ptr_new(final)
            (*newim).mask = ptr_new(final_msk)
            (*newim).xsiz = imsz[1]
            (*newim).ysiz = imsz[2]
            (*newim).vis = 0
            c = imscale(final,10.0)
            (*newim).z1 = c[0]
            (*newim).z2 = c[1]
	    (*newim).scl = (*im).scl
	    (*newim).sclamt = (*im).sclamt
	    (*newim).bias = (*im).bias
	    (*newim).xpscl = (*im).xpscl
	    (*newim).ypscl = (*im).ypscl
	    (*newim).flipy = (*im).flipy
	    (*newim).zoom = (*im).zoom
	    (*newim).rot = (*im).rot
	    (*newim).rotamt = (*im).rotamt
	    (*newim).rotcx = (*im).rotcx
	    (*newim).rotcy = (*im).rotcy
	    (*newim).rotxpad = (*im).rotxpad
	    (*newim).rotypad = (*im).rotypad
	    (*newim).xpoff = (*im).xpoff
	    (*newim).ypoff = (*im).ypoff
	    (*newim).xoff = (*im).xoff
	    (*newim).yoff = (*im).yoff
	    (*newim).topad = (*im).topad
	    (*newim).pad = (*im).pad
	    (*newim).movamt = (*im).movamt
            tempimages = [*info.images, newim]
            ptr_free, info.images
            info.images = ptr_new(tempimages)
	    Widget_Control, info.idp3Window, Set_UValue=info
          endif
          if sav2file eq 1 then begin
            if strlen(extn) eq 0 then filename = filename + '.fits'
            temp = file_search (filename, Count = fcount)
            if fcount gt 0 then begin
	      idp3_selectval, event.top, $
		'Do you wish to overwrite existing file?', $
	        ['no','yes'], val
              if val eq 0 then return
            endif 
	    ua_fits_open, filename, fcb, /Write
	    if n_elements(ihdr) le 2 then begin
	      ua_fits_write, fcb, final, phdr, /noextend
            endif else begin
	      ua_fits_write, fcb, 0, phdr
	      ua_fits_write, fcb, final, ihdr, extname='SCI', extver=1
            endelse
	    ua_fits_close, fcb
          endif
        endif else begin
	  str = 'No pixels to repair'
	  idp3_updatetxt, info, str
	  return
        endelse
      endif
    endfor
    if sav2idp3 eq 1 then begin
      if XRegistered('idp3_showim') then begin
	geo = Widget_Info(info.ShowImBase, /geometry)
	info.wpos.siwp[0] = geo.xoffset - info.xoffcorr
	info.wpos.siwp[1] = geo.yoffset - info.yoffcorr
	Widget_Control, info.idp3Window, Set_UValue=info
	Widget_Control, info.ShowImBase, /Destroy
      endif
      idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:info.idp3Window,HANDLER:0L,$
	         SELECT:0}
      Widget_Control, info.idp3Window, Get_UValue=info
      idp3_display,info
    endif
  end

  repairinfo.helpButton: begin
    if info.pdf_viewer eq '' then begin
      tmp = idp3_findfile('idp3_pixrepair.hlp')
      xdisplayfile, tmp
    endif else begin
      tmp = idp3_findfile('idp3_repairbad.pdf')
      str = info.pdf_viewer + ' ' + tmp
      if !version.os eq 'darwin' then str = 'open -a ' + str
      spawn, str
    endelse
  end

  endcase

  Widget_Control, repairinfo.info.idp3Window,Get_UValue=tinfo
  repairinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=repairinfo
end

pro idp3_repairbad, event

@idp3_structs
@idp3_errors

  if(XRegistered("idp3_pixrepair")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  title = 'IDP3 Bad Pixel Repair'

  fwhm = 0.
  boxsize = 0
  ksize = 0
  method = 0
  mbadval = 0
  dbadval = 0.0
  dbadvalg = 0.0
  dbadvall = 0.0
  listname = '   '
  filename = '   '
  maskname = '   '
  dolist = 0
  dofile = 0
  domasks = 0
  imbadval = 0
  badbval = [0,0,0,0]

  srbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])

  badfbase = Widget_Base(srbase, /Column, /Frame)
  plabel = Widget_Label(badfbase, Value='Bad Pixel Identification Files')
  badfbase1 = Widget_Base(badfbase, row=1, map=1)
  listButton = cw_bgroup(badfbase1, ['List'], $
     row=1, set_value = [dolist], /nonexclusive)
  selectlistname = Widget_Text(badfbase1, Value = listname, XSize = 32, /Edit)
  browselistButton = Widget_Button(badfbase1, Value='Browse',/align_center)
  badfbase2 = Widget_Base(badfbase, row=1, map=1)
  fileButton = cw_bgroup(badfbase2, ['File'], $
     row=1, set_value = [dofile], /nonexclusive)
  selectfilename = Widget_Text(badfbase2, Value = maskname, XSize = 32, /Edit)
  browsefileButton = Widget_Button(badfbase2, Value='Browse',/align_center)
  badmField = cw_Field(badfbase2, value=mbadval, title = 'Bad Value:', $
     uvalue='mbadv', xsize=2, /Return_Events, /Integer)

  badpbase = Widget_Base(srbase, /Column, /Frame)
  vallabel = Widget_Label(badpbase, Value= $
     'Bad Pixel Identification Values (in Image)')
  badpbase1 = Widget_Base(badpbase, row=1, map=1) 
  badtypes = ['Value', '> Value', '< Value', 'NaN']
  badButtons = cw_BGroup(badpbase1, badtypes, row=1, /nonexclusive, $
	   label_left='  Select (1 or more):', $
	   Set_Value=badbval, /no_release)
  badpbase2 = Widget_Base(badpbase, /Row)
  baddField = cw_Field(badpbase2, value = dbadval, title= $
     'Value:', uvalue='dbadv', xsize=8, /Return_Events, /Floating)
  badgField = cw_Field(badpbase2, value = dbadvalg, title= $
     'Greater Than:', uvalue='dbadvg', xsize=8, /Return_Events, /Floating)
  badlField = cw_Field(badpbase2, value = dbadvall, title= $
     'Less Than:', uvalue='dbadvl', xsize=8, /Return_Events, /Floating)

  badimbase = Widget_Base(srbase, /column, /frame)
  masktypes = ['None', 'Internal Mask', 'External File']
  maskButtons = cw_BGroup(badimbase, masktypes, row=1, uvalue='tybut', $
	   label_left='Mask Identified Bad Pixels with: ', $
	   Set_Value = [domasks], /exclusive, /no_release)
  badimbase1 = Widget_Base(badimbase, /row)
  masklabel = Widget_Label(badimbase1, Value='File:')
  selectmaskname = Widget_Text(badimbase1, Value = maskname, XSize = 32, /Edit)
  browsemaskButton = Widget_Button(badimbase1, Value='Browse',/align_center)
  badimField = cw_Field(badimbase1, value=imbadval, title = $
     'Exclude Value:', uvalue='imbadv', xsize=2, /Return_Events, /Integer)

  rmethbase = Widget_Base(srbase, /column, /frame)
  mlabel = Widget_Label(rmethbase, Value = 'Bad Pixel Repair Method')

  rmethbase1 = Widget_Base(rmethbase, /Row)
  mnames = ['Gaussian Interpolation           ', 'Neighbor (Box) Median']
  mButtons = cw_bgroup(rmethbase1, mnames, row=1, uvalue='mbutton', $
       set_value=method, /exclusive, /no_release)

  rmethbase2 = Widget_Base(rmethbase, /Row)
  ksizeField = cw_Field(rmethbase2, title='Kernel Diameter (pixels):', $
       value=ksize, uvalue='ksiz', xsize=3, /Return_Events, /Integer)
  bsizeField = cw_Field(rmethbase2, title='     Box Size: ', $
       value=boxsize, uvalue='bsiz', xsize=4, /Return_Events, /Integer)

  FWHMField = cw_Field(rmethbase, value=fwhm, title=' FWHM', uvalue='fwh', $
       xsize=6, /Return_Events, /Floating)

  srbase5d = Widget_Base(srbase, /Column)
  snames=['IDP3: Name and/or Append (single), Append (multiple)', $
	  'File: Name and/or Append (see above) and Path']
  sButtons = cw_bgroup(srbase5d, snames, column=1, uvalue='sbutton', $
    set_value=[0,0], /nonexclusive, $
    label_top='Save Results to: ')
  srbase5e = Widget_Base(srbase, /Row)
  label = Widget_Label(srbase5e, Value='Name:')
  nameField =  Widget_Text(srbase5e, Value = '  ', XSize = 32, /Edit)
  labela = Widget_Label(srbase5e, Value='   Append:')
  appField = Widget_Text(srbase5e, Value='  ', XSize=5, /Edit)
  srbase5f = Widget_Base(srbase, /Row)
  label2 = Widget_Label(srbase5f, Value='Path:')
  pathField = Widget_Text(srbase5f, Value = ' ', XSize = 32, /Edit)

  srbase6r = Widget_Base(srbase, /Row)
  splabel = Widget_Label(srbase6r, Value='                 ')
  computeButton = Widget_Button(srbase6r, Value = 'Compute')
  helpButton = Widget_Button(srbase6r, Value='Help')
  doneButton = Widget_Button(srbase6r, Value = ' Done ', $
	      Event_Pro='idp3_repairbaddone')

  repairinfo = {   listButton        :  listButton,       $
		   selectlistname    :  selectlistname,   $
		   browselistButton  :  browselistButton, $
		   fileButton        :  fileButton,       $
 	           selectfilename    :  selectfilename,   $
		   browsefileButton  :  browsefileButton, $
		   maskButtons       :  maskButtons,      $
		   selectmaskname    :  selectmaskname,   $
		   browsemaskButton  :  browsemaskButton, $
		   badmField         :  badmField,        $
		   badButtons        :  badButtons,       $
		   baddField         :  baddField,        $
		   badlField         :  badlField,        $
		   badgField         :  badgField,        $
		   badimField        :  badimField,       $
		   sButtons          :  sButtons,         $
		   pathField         :  pathField,        $
		   nameField         :  nameField,        $
		   appField          :  appField,         $
		   mButtons          :  mButtons,         $
		   ksizeField        :  ksizeField,       $
		   bsizeField        :  bsizeField,       $
		   FWHMField         :  FWHMField,        $
	           computeButton     :  computeButton,    $
		   helpButton        :  helpButton,       $
		   maskname          :  maskname,         $
		   listname          :  listname,         $
		   filename          :  filename,         $
	           info              :   info             }

  Widget_Control, srbase, set_uvalue = repairinfo
  Widget_Control, srbase, /Realize

  XManager, "idp3_pixrepair", srbase, Event_Handler = "idp3_repairbad_ev", $
       /No_Block
          
end
