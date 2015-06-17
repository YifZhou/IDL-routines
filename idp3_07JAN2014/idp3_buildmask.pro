;+
;
;HISTORY:
;   2008-04-16: Modified display code to keep mask in color on Macs. - M. Perrin
;  		Also added an 'Invert Mask' option. (Inverting then adding then
;   		inverting again lets you subtract regions from a mask...)
;
;-


function bmask_cursor, event
  Widget_Control,event.top,Get_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info
  maskinfo.mouse_mode = Event.Value
  info.maskmode = Event.Value
  if Event.Value eq 4 then begin
    tmp = idp3_findfile('idp3_freehand.hlp')
    xdisplayfile, tmp, title='Freehand Draw (Closed Shape)', width=50, $
       height=4
  endif
  Widget_Control, event.top, Set_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Set_UValue = info
end

function bmask_ccolor, event
  Widget_Control,event.top,Get_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info
  maskinfo.cursor_color = Event.Value
  Widget_Control, event.top, Set_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Set_UValue = info
end

pro bmask_hdr, imptr, mask, phdr

@idp3_structs
  phead  = *(*imptr).phead 
  ihead  = *(*imptr).ihead
  msz = size(mask)
  if phead[0] eq '' then begin
    ; Header empty (probably read HDF file), build header.
    phdr = $
['SIMPLE  =                    T /image conforms to FITS standard           ', $
 'NAXIS   =                    2 /number of axes                            ', $
 'END                                                                       ']
    sxaddpar,phead,'NAXIS1',msz[1]
    sxaddpar,phead,'NAXIS2',msz[2]
  endif else begin
    if n_elements(ihead) gt 2 then begin
      sxdelpar, phead, 'NEXTEND'
      sxdelpar, phead, 'END'
      sxdelpar, ihead, 'XTENSION'
      sxdelpar, ihead, 'INHERIT'
      sxdelpar, ihead, 'EXTNAME'
      sxdelpar, ihead, 'EXTVER'
      sxdelpar, ihead, 'EXTLEVEL'
      sxdelpar, ihead, 'BITPIX'
      sxdelpar, ihead, 'NAXIS'
      sxdelpar, ihead, 'NAXIS1'
      sxdelpar, ihead, 'NAXIS2'
      sxdelpar, ihead, 'GCOUNT'
      phdr = [phead, ihead]
      sxaddpar, phdr, 'NAXIS', 2
      sxaddpar, phdr, 'NAXIS1', msz[0], AFTER='NAXIS'
      sxaddpar, phdr, 'NAXIS2', msz[1], AFTER='NAXIS1'
    endif else phdr = phead
  endelse
 end

function bmask_display, maskinfo, im, mask
  ; display current data selection
  wset, maskinfo.maskid
  xsz = maskinfo.xsz
  ysz = maskinfo.ysz
  bits = maskinfo.bits
  colors = maskinfo.colors
  dmcolor = maskinfo.dmcolor
  z1 = maskinfo.z1
  z2 = maskinfo.z2
  zoom = maskinfo.zoomfact
  auto = maskinfo.AutoScale

  if zoom eq 1 then begin
    zmask = mask 
    zim = im
  endif else begin
    zmask = congrid(mask, xsz, ysz)
    zim = congrid(im, xsz, ysz)
  endelse
  case maskinfo.disp of
    0: begin
      bad = where(zmask eq 0, cnt)
      if maskinfo.autoscale eq 1 then begin
        good = where(zmask ne 0, gcnt)
        if gcnt gt 1 then begin
	  cc = imscale(zim[good], 10.0)
	  z1 = cc[0]
	  z2 = cc[1]
	  maskinfo.z1 = z1
	  maskinfo.z2 = z2
	  Widget_Control, maskinfo.pminField, Set_Value=z1
	  Widget_Control, maskinfo.pmaxField, Set_Value=z2
        endif
      endif
      bim = bytscl(zim,top=colors-bits-1,min=z1, max=z2)+bits
      if cnt gt 0 then bim[bad] = dmcolor
    end
    1: begin
       if maskinfo.autoscale eq 1 then begin
	 cc = imscale(zim, 10.0)
	 z1 = cc[0]
	 z2 = cc[1]
	 maskinfo.z1 = z1
	 maskinfo.z2 = z2
	 Widget_Control, maskinfo.pminField, Set_Value=z1
         Widget_Control, maskinfo.pmaxField, Set_Value=z2
       endif
       bim=bytscl(zim,top=colors-bits-1,min=z1, max=z2)+bits
    end
    2: bim=bytscl(zmask,top=colors-bits-1,min=0, max=1)+bits  
    else:
    endcase
      tv, bim
    zdisplay = bim ;tvrd()
    return, zdisplay
end

pro bmask_remove, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  ims = info.images
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data
  imsz = size(im)
  if ptr_valid((*imptr).mask) then begin
    ptr_free, (*imptr).mask
  endif
  (*info.images)[info.moveimage] = imptr
  if (*imptr).maskvis eq 1 then begin
    (*imptr).maskvis = 0 
    call_display = 1
  endif else call_display = 0
  Widget_Control, maskinfo.info.idp3Window, Set_UValue = info
  if call_display eq 1 then begin
    if (XRegistered('idp3_showim')) then begin
      Widget_Control, info.ShowImBase, /Destroy
      idp3_showim, $
	{WIDGET_BUTTON,ID:0L,TOP:maskinfo.info.idp3Window,HANDLER:0L,SELECT:0}
      Widget_Control, maskinfo.info.idp3Window, Get_UValue=info
    endif 
    maskinfo.info=info
    Widget_Control, event.top, Set_UValue=maskinfo
    idp3_display, info
  endif
      
  maskim = intarr(imsz[1], imsz[2])
  maskim[*,*] = 1
  maskinfo.cur_mask = maskim
  maskinfo.color_mask = maskim
  zdisplay = bmask_display(maskinfo, im, maskim)
  maskinfo.zdisplay = ptr_new(zdisplay)
  Widget_Control, event.top, Set_UValue=maskinfo
end

pro bmask_load, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  ims = info.images
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data

  inpath = info.imagepath
  infilt = info.imfilter
  filename = Dialog_Pickfile(/Read, Get_Path=outpath, title='Select Mask File',$
	       Path=inpath, Filter=infilt)
  filename = strtrim(filename[0], 2)
  info.imagepath = outpath

  ; Check to see if this image exists.
  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin

    ; Read the image.

    getmask = 0
    ua_decompose, filename, disk, path, name, extn, version
    lextn = strlowcase(extn)
    if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
    Case lextn of

    '.fit':  Begin
      ; FITS format
      ua_fits_open, filename, fcb
      if fcb.nextend eq 0 then begin
        ua_fits_read, filename, tempmask, temphead, /no_abort
	str = 'Buildmask: reading mask from file ' + filename
	idp3_updatetxt, info, str
	msz = size(tempmask)
	if msz[0] eq 3 then begin
	  title = 'Which plane in the 3-D image'
	  label = 'Plane 0-' + strtrim(string(imsz[3]-1),2)
	  valstr = idp3_getvals(title, '0', groupleader=info.idp3Window, $
	       lab1=label, cancel=cancel, ws=10)
          if cancel eq 1 then begin
	    str = 'Buildmask: Nothing loaded'
	    idp3_updatetxt, info, str
	    return
          endif
	  pln = fix(valstr)
	  if pln ge 0 and pln lt msz[3]-1 then begin
	    tempmask = tempmask[*,*,pln]
	    getmask = 1
          endif else begin
	    str = 'Buildmask: Incorrect plane for mask'
	    idp3_updatetxt, info, str
          endelse
	endif else getmask = 1
      endif else begin
	for i = 1, fcb.nextend do begin
	  if fcb.extname[i] eq 'DQ' and getmask eq 0 then begin
	    ua_fits_read, fcb, tempmask, temphead, extname='DQ', /no_abort
	    str = 'Buildmask: reading data quality extension from file ' + $
		   filename
            idp3_updatetxt, info, str
	    getmask = 1
          endif
        endfor
	if getmask eq 0 then begin
	  test = Widget_Message('Data Quality extension not found!')
	  return
        endif
      endelse
      end

    '.pic': Begin
      ; this is a Macintosh pict file
      read_pict, filename, tempmask
      temphead = ['','']
      getmask = 1
      end

    '.tif':  Begin
      ; this is a tiff file
      tempmask = read_tiff(filename)
      temphead = ['','']
      getmask = 1
      end

    else: Begin
      ; Assume HDF format.
      ua_hdf_read, filename, temphead, tempmask, hdr_flag, image_flag
      if image_flag eq 1 then begin
	getmask = 1
	str = 'Buildmask: reading mask from hdf file ' + filename
	idp3_updatetxt, info, str
        if hdr_flag eq 0 then begin
	  temphead = ['','']
	  str = 'Buildmask: No fits header found in file ' + filename
	  idp3_updatetxt, info, str
        endif
      endif else begin
	str = 'File ' + filename + ' not recognized as fits or hdf format'
	a = Widget_Message(str)
      endelse
    end
    endcase

    if getmask eq 1 then begin
      zdisplay = bmask_display(maskinfo, im, tempmask)
      maskinfo.zdisplay = ptr_new(zdisplay)
      maskinfo.cur_mask = tempmask
      if ptr_valid((*imptr).mask) then ptr_free, (*imptr).mask
      (*imptr).mask = ptr_new(tempmask)
      (*info.images)[info.moveimage] = imptr
      Widget_Control, maskinfo.info.idp3Window, Set_UValue=info
      if (*imptr).maskvis eq 1 then idp3_display, info
    endif
  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  Widget_Control, event.top, Set_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Set_UValue=info

end

pro bmask_overlay, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info
  
  ims = info.images
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data

  filename = Dialog_Pickfile(/Read, /Must_Exist, title='Select Mask File')
  filename = strtrim(filename(0), 2)

  ; Check to see if this image exists.
  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin

    ; Read the image.

    getmask = 0
    ua_decompose, filename, disk, path, name, extn, version
    lextn = strlowcase(extn)
    if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
    Case lextn of

    '.fit':  Begin
      ; FITS format
      ua_fits_open, filename, fcb
      if fcb.nextend eq 0 then begin
        ua_fits_read, filename, tempmask, temphead, /no_abort
	str = 'Buildmask: reading mask from file ' + filename
	idp3_updatetxt, info, str
	msz = size(tempmask)
	if msz[0] eq 3 then begin
	  title = 'Which plane in the 3-D image'
	  label = 'Plane 0-' + strtrim(string(imsz[3]-1),2)
	  valstr = idp3_getvals(title, '0', groupleader=info.idp3Window, $
	       lab1=label, cancel=cancel, ws=10)
          if cancel eq 1 then begin
	    str = 'Buildmask: Nothing loaded'
	    idp3_updatetxt, info, str
	    return
          endif
	  pln = fix(valstr)
	  if pln ge 0 and pln lt msz[3]-1 then begin
	    tempmask = tempmask[*,*,pln]
	    getmask = 1
          endif else begin
	    str =  'Buildmask: Incorrect plane for mask'
	    idp3_updatetxt, info, str
          endelse
	endif else getmask = 1
      endif else begin
	for i = 1, fcb.nextend do begin
	  if fcb.extname[i] eq 'DQ' and getmask eq 0 then begin
	    ua_fits_read, fcb, tempmask, temphead, extname='DQ', /no_abort
	    str = 'Buildmask: Reading data quality extension from file ' + $
		   filename
            idp3_updatetxt, info, str
	    getmask = 1
          endif
        endfor
	if getmask eq 0 then begin
	  test = Widget_Message('Data Quality extension not found!')
	  return
        endif
      endelse
      end

    '.pic': Begin
      ; this is a Macintosh pict file
      read_pict, filename, tempmask
      temphead = ['','']
      getmask = 1
      end

    '.tif':  Begin
      ; this is a tiff file
      tempmask = read_tiff(filename)
      temphead = ['','']
      getmask = 1
      end

    else: Begin
      ; Assume HDF format.
      ua_hdf_read, filename, temphead, tempmask, hdr_flag, image_flag
      if image_flag eq 1 then begin
	getmask = 1
	str = 'Buildmask: Reading mask from hdf file ' + filename
	idp3_updatetxt, info, str
        if hdr_flag eq 0 then begin
	  temphead = ['','']
	  str = 'Buildmask: No fits header found in file ' + filename
	  idp3_updatetxt, info, str
        endif
      endif else begin
	str = 'File ' + filename + ' not recognized as fits or hdf format'
	a = Widget_Message(str)
      endelse
    end
    endcase

    if getmask eq 1 then begin
      mask = maskinfo.cur_mask
      bad = where(tempmask eq 0, cnt)
      if cnt gt 0 then mask[bad] = 0
      zdisplay = bmask_display(maskinfo, im, mask)
      maskinfo.zdisplay = ptr_new(zdisplay)
      maskinfo.cur_mask = mask
      if ptr_valid((*imptr).mask) then ptr_free, (*imptr).mask
      (*imptr).mask = ptr_new(mask)
      (*info.images)[info.moveimage] = imptr
      Widget_Control, maskinfo.info.idp3Window, Set_UValue=info
      if (*imptr).maskvis eq 1 then idp3_display, info
      tempmask = 0
    endif
  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  Widget_Control, event.top, Set_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Set_UValue=info

end

pro idp3_maskcursor, pim, ix, iy, xb, xe, yb, ye, cc

  device, get_graphics_function=g_fnc
  tv, pim
  image = intarr(16)  ; set image cursor to blank
  device, cursor_image=image
  plots, [xb, ix-3], [iy, iy], /dev, color=cc
  plots, [ix-1, ix+1], [iy, iy], /dev, color=cc
  plots, [ix+3, xe], [iy, iy], /dev, color=cc
  plots, [ix, ix], [yb, iy-3], /dev, color=cc
  plots, [ix, ix], [iy-1, iy+1], /dev, color=cc
  plots, [ix,ix], [iy+3, ye],/dev, color=cc
  device, set_graphics_function=g_fnc
end

pro buildmask_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  ims = info.images
  nn = size(*ims)
  if nn[0] eq 0 and nn[1] eq 2 then return
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data
  maskim = maskinfo.cur_mask
  maskcol = maskinfo.color_mask
  maskWindow = info.maskWindow
  imsz = size(im)
  if maskinfo.zoomfact eq 1 then begin
    maskinfo.xsz = imsz[1]
    maskinfo.ysz = imsz[2]
  endif else begin
    maskinfo.xsz = imsz[1]*maskinfo.zoomfact
    maskinfo.ysz = imsz[2]*maskinfo.zoomfact
  endelse
  xsz = maskinfo.xsz
  ysz = maskinfo.ysz
  maxx = maskinfo.maxx
  maxy = maskinfo.maxy
  bits = maskinfo.bits
  colors = maskinfo.colors
  bwcolor = maskinfo.bwcolor
  dmcolor = maskinfo.mask_color
  pixcolor = maskinfo.mask_color
  crlcolor = maskinfo.crlcolor
  polycolor = maskinfo.polycolor
  regcolor = maskinfo.regcolor
  bits = info.color_bits
  z1 = maskinfo.z1
  z2 = maskinfo.z2
  mask_update = 0
  wset, maskinfo.maskid

  case event.id of

  maskinfo.maskdoneButton: begin
    if ptr_valid((*imptr).mask) then ptr_free, (*imptr).mask
    mask = maskinfo.cur_mask
    (*imptr).mask = ptr_new(mask)
    (*info.images)[info.moveimage] = imptr
    Widget_Control, maskinfo.info.idp3Window, Set_UValue = info
    Widget_Control, event.top, Set_UValue = maskinfo
    Widget_Control, event.top, /Destroy
    return
  end

  maskinfo.blackcursorButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.cursor_color = bwcolor $
       else maskinfo.cursor_color = 0
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.whitecursorButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.cursor_color = bwcolor $
       else maskinfo.cursor_color = 1
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.redcursorButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.cursor_color = bwcolor $
       else maskinfo.cursor_color = 2
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.greencursorButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.cursor_color = bwcolor $
       else maskinfo.cursor_color = 3
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.bluecursorButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.cursor_color = bwcolor $
      else maskinfo.cursor_color = 4
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.yellowcursorButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.cursor_color = bwcolor $
      else maskinfo.cursor_color = 5
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.blackmaskButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.mask_color = 200 $
      else maskinfo.mask_color = 0
    maskinfo.dmcolor = maskinfo.mask_color
    maskinfo.pixcolor = maskinfo.mask_color
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.whitemaskButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.mask_color = 200 $
      else maskinfo.mask_color = 1
    maskinfo.dmcolor = maskinfo.mask_color
    maskinfo.pixcolor = maskinfo.mask_color
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.redmaskButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.mask_color = 200 $
      else maskinfo.mask_color = 2
    maskinfo.dmcolor = maskinfo.mask_color
    maskinfo.pixcolor = maskinfo.mask_color
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.greenmaskButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.mask_color = 200 $
      else maskinfo.mask_color = 3
    maskinfo.dmcolor = maskinfo.mask_color
    maskinfo.pixcolor = maskinfo.mask_color
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.bluemaskButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.mask_color = 200 $
      else maskinfo.mask_color = 4
    maskinfo.dmcolor = maskinfo.mask_color
    maskinfo.pixcolor = maskinfo.mask_color
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.yellowmaskButton: begin
    Widget_Control, event.top, Get_UValue=maskinfo
    if bits eq 0 then maskinfo.mask_color = 200 $
      else maskinfo.mask_color = 5
    maskinfo.dmcolor = maskinfo.mask_color
    maskinfo.pixcolor = maskinfo.mask_color
    Widget_Control, event.top, Set_UValue=maskinfo
  end

  maskinfo.helpButton: begin
    tmp = idp3_findfile('idp3_buildmask.hlp')
    xdisplayfile, tmp
  end

  maskinfo.blinkddButton: begin
    if maskinfo.zoomfact gt 1 then begin
      zim = congrid(im, maskinfo.xsz, maskinfo.ysz)
      zmask = congrid(maskim, maskinfo.xsz, maskinfo.ysz)
    endif else begin
      zim = im
      zmask = maskim
    endelse
    zimm = zim
    a = where(zmask eq 0, cnt)
    for i = 0L, 9 do begin
      dispim = bytscl(zimm,top=colors-bits-1,min=z1, max=z2)+bits
      if cnt gt 0 then dispim[a] = pixcolor
      tv, dispim
      wait, 0.5
      tv,bytscl(zim,top=colors-bits-1,min=z1, max=z2)+bits
      wait, 0.5
    endfor
  end

  maskinfo.blinkdmButton: begin
    if maskinfo.zoomfact gt 1 then begin
      zim = congrid(im, maskinfo.xsz, maskinfo.ysz)
      zmask = congrid(maskim, maskinfo.xsz, maskinfo.ysz)
    endif else begin
      zim = im
      zmask = maskim
    endelse
    for i = 0L, 9 do begin
      tv,bytscl(zim,top=colors-bits-1,min=z1, max=z2)+bits
      wait, 0.5
      tv,bytscl(zmask,top=colors-bits-1,min=0, max=1)+bits
      wait, 0.5
    endfor
  end

  maskinfo.zoom1Button: begin
    maskinfo.zoomfact = 1
    xsz = imsz[1]
    ysz = imsz[2]
    maskinfo.xsz = xsz
    maskinfo.ysz = ysz
    if xsz le maxx and ysz le maxy and maskinfo.scroll eq 1 then begin
      Widget_Control, maskinfo.maskDraw, /Destroy
      maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	    /Motion_Events, /Button_Events, retain=info.retn)
      Widget_Control, maskDraw, Get_Value = maskid
      maskinfo.maskDraw = maskDraw
      maskinfo.maskid = maskid
      maskinfo.scroll = 0
      wset, maskid
    endif else erase
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.zoom2Button: begin
    maskinfo.zoomfact = 2
    xsz = imsz[1] * 2
    ysz = imsz[2] * 2
    maskinfo.xsz = xsz
    maskinfo.ysz = ysz
    zim = congrid(im, xsz, ysz)
    zmask = congrid(maskim, xsz, ysz)
    if xsz gt maxx or ysz gt maxy then begin
      Widget_Control, maskinfo.maskDraw, /Destroy
      maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	       x_scroll_size=maxx, y_scroll_size=maxy, /scroll, $
	       /Motion_Events, /Button_Events, retain=info.retn)
      Widget_Control, maskDraw, Get_Value = maskid
      maskinfo.maskDraw = maskDraw
      maskinfo.maskid = maskid
      maskinfo.scroll = 1
      wset, maskid
    endif else begin
      if maskinfo.scroll eq 1 then begin
        Widget_Control, maskinfo.maskDraw, /Destroy
	maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	    /Motion_Events, /Button_Events, retain=info.retn)
        Widget_Control, maskDraw, Get_Value = maskid
	maskinfo.maskDraw = maskDraw
	maskinfo.maskid = maskid
	maskinfo.scroll = 0
        wset, maskid
      endif else erase
    endelse
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.zoom4Button: begin
    maskinfo.zoomfact = 4
    xsz = imsz[1] * 4
    ysz = imsz[2] * 4
    maskinfo.xsz = xsz
    maskinfo.ysz = ysz
    erase
    zim = congrid(im, xsz, ysz)
    zmask = congrid(maskim, xsz, ysz)
    if xsz gt maxx or ysz gt maxy then begin
      Widget_Control, maskinfo.maskDraw, /Destroy
      maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	  x_scroll_size=maxx, y_scroll_size=maxy, /scroll, $
	  /Motion_Events, /Button_Events, retain=info.retn)
      Widget_Control, maskDraw, Get_Value = maskid
      maskinfo.maskDraw = maskDraw
      maskinfo.maskid = maskid
      maskinfo.scroll = 1
      wset, maskid
    endif else begin
      if maskinfo.scroll eq 1 then begin
        Widget_Control, maskinfo.maskDraw, /Destroy
	maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	    /Motion_Events, /Button_Events, retain=info.retn)
        Widget_Control, maskDraw, Get_Value = maskid
	maskinfo.maskDraw = maskDraw
	maskinfo.maskid = maskid
	maskinfo.scroll = 0
	wset, maskid
      endif else erase
    endelse
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.zoom8Button: begin
    maskinfo.zoomfact = 8 
    xsz = imsz[1] * 8
    ysz = imsz[2] * 8
    maskinfo.xsz = xsz
    maskinfo.ysz = ysz
    zim = congrid(im, xsz, ysz)
    zmask = congrid(maskim, xsz, ysz)
    if xsz gt maxx or ysz gt maxy then begin
      Widget_Control, maskinfo.maskDraw, /Destroy
      maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	       x_scroll_size=maxx, y_scroll_size=maxy, /scroll, $
	       /Motion_Events, /Button_Events, retain=info.retn)
      Widget_Control, maskDraw, Get_Value = maskid
      maskinfo.maskDraw = maskDraw
      maskinfo.maskid = maskid
      maskinfo.scroll = 1
      wset, maskid
    endif else begin
      if maskinfo.scroll eq 1 then begin
        Widget_Control, maskinfo.maskDraw, /Destroy
	maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	    /Motion_Events, /Button_Events, retain=info.retn)
        Widget_Control, maskDraw, Get_Value = maskid
        maskinfo.maskDraw = maskDraw
	maskinfo.maskid = maskid
	maskinfo.scroll = 0
        wset, maskid
      endif else erase
    endelse
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.showdmButton: begin
    maskinfo.disp=0
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.showdataButton: begin
    maskinfo.disp=1
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.showmaskButton: begin
    maskinfo.disp=2
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.showmavButton: begin
    maskinfo.disp=2
    tempmask = maskim
    ebad = where(im eq info.invalid, ecnt)
    if ecnt gt 0 then tempmask[ebad] = 0
    zdisplay = bmask_display(maskinfo, im, tempmask)
    maskinfo.zdisplay = ptr_new(zdisplay)
    if info.exclude_invalid eq 0 then stat = Widget_Message($
	  'Warning!!  Exclude Invalid option not set!!')
  end

  maskinfo.showdmavButton: begin
    maskinfo.disp=0
    tempmask = maskim
    ebad = where(im eq info.invalid, ecnt)
    if ecnt gt 0 then tempmask[ebad] = 0
    zdisplay = bmask_display(maskinfo, im, tempmask)
    maskinfo.zdisplay = ptr_new(zdisplay)
    if info.exclude_invalid eq 0 then stat = Widget_Message($
	  'Warning!!  Exclude Invalid option not set!!')
  end

  maskinfo.undolastpButton: begin
    xpix = maskinfo.last_pixel[0]
    ypix = maskinfo.last_pixel[1]
    if xpix ge 0 and ypix ge 0 then begin
      maskim[xpix,ypix] = 1
      zdisplay = bmask_display(maskinfo, im, maskim)
      maskinfo.zdisplay = ptr_new(zdisplay)
      mask_update = 1
    endif else begin
      str = 'Buildmask: No pixel to undo!'
      idp3_updatetxt, info, str
    endelse
  end

  maskinfo.undolastrButton: begin
    if ptr_valid(maskinfo.last_region) then begin
      region = *maskinfo.last_region
      rsiz = size(region)
      for i = 0L, rsiz[1]-1 do begin
	maskim[region[i,0],region[i,1]] = 1
      endfor
      zdisplay = bmask_display(maskinfo, im, maskim)
      maskinfo.zdisplay = ptr_new(zdisplay)
      mask_update = 1
    endif else begin
      str = 'No valid region to undo!'
      idp3_updatetxt, info, str
    endelse
  end

  maskinfo.undoallButton: begin
    isz = size(im)
    maskim = intarr(isz[1], isz[2])
    maskim[*,*] = 1
    if ptr_valid((*imptr).xnan) and ptr_valid((*imptr).ynan) then begin
      nx = *(*imptr).xnan
      ny = *(*imptr).ynan
      for i = 0L, n_elements(nx)-1 do begin
	maskim[nx[i], ny[i]] = 0
      endfor
    endif
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
    mask_update = 1
  end
  maskinfo.invertButton: begin
    maskim =  1-maskim 
    if ptr_valid((*imptr).xnan) and ptr_valid((*imptr).ynan) then begin
      nx = *(*imptr).xnan
      ny = *(*imptr).ynan
      for i = 0L, n_elements(nx)-1 do begin
			maskim[nx[i], ny[i]] = 0
      endfor
    endif
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
    mask_update = 1
  end

  maskinfo.pminField: begin
    Widget_Control, maskinfo.pminField, Get_Value=z1
    maskinfo.z1 = z1
    maskinfo.AutoScale = 0
    Widget_Control, maskinfo.autoButton, Set_Value=0
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.pmaxField: begin
    Widget_Control, maskinfo.pmaxField, Get_Value=z2
    maskinfo.z2 = z2
    maskinfo.AutoScale = 0
    Widget_Control, maskinfo.autoButton, Set_Value=0
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
  end

  maskinfo.autoButton: begin
     Widget_Control, maskinfo.autoButton, Get_Value = barray
     if barray[0] eq 0 then begin
	maskinfo.AutoScale = 0
     endif else begin
       maskinfo.AutoScale = 1
     endelse
     zdisplay = bmask_display(maskinfo, im, maskim)
     maskinfo.zdisplay = ptr_new(zdisplay)
  end
  maskinfo.radiusField: begin
    Widget_Control, maskinfo.radiusField, Get_Value=radius
  end
  
  maskinfo.xcenField: begin
    Widget_Control, maskinfo.xcenField, Get_Value=xcen
  end

  maskinfo.ycenField: begin
    Widget_Control, maskinfo.ycenField, Get_Value=ycen
  end

  maskinfo.getrefButton: begin
    xcentroid = (*imptr).lccx
    ycentroid = (*imptr).lccy
    tempx = xcentroid
    tempy = ycentroid
    if xcentroid gt 0.0 and ycentroid gt 0.0 then begin
      xoff = (*imptr).xpoff + (*imptr).xoff + info.sxoff
      if xoff gt 0.0 then tempx = tempx - xoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then tempx = tempx / (*imptr).zoom
      if (*imptr).xpscl ne 1.0 and (*imptr).xpscl ne 0.0 $
        then tempx = tempx / (*imptr).xpscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
        then tempx = tempx - (*imptr).pad
      yoff = (*imptr).ypoff + (*imptr).yoff + info.syoff
      if yoff gt 0.0 then tempy = tempy - yoff
      if abs((*imptr).zoom - 1.0) gt 0.00001 then tempy = tempy / (*imptr).zoom
      if (*imptr).ypscl ne 1.0 and (*imptr).ypscl ne 0.0 $
        then tempy = tempy / (*imptr).ypscl
      if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
        then tempy = tempy - (*imptr).pad
      maskinfo.xcentroid = tempx
      maskinfo.ycentroid = tempy
    endif 
    xcen = Round(maskinfo.xcentroid)
    ycen = Round(maskinfo.ycentroid)
    Widget_Control, maskinfo.xcenField, Set_Value=xcen
    Widget_Control, maskinfo.ycenField, Set_Value=ycen
  end

  maskinfo.updatButton: begin
    newxc = Round(maskinfo.xcentroid * maskinfo.zoomfact)
    newyc = Round(maskinfo.ycentroid * maskinfo.zoomfact)
    Widget_Control, maskinfo.radiusField, Get_Value=nrad
    newrad = nrad * maskinfo.zoomfact
    xcen = maskinfo.xcircle
    ycen = maskinfo.ycircle
    rad = maskinfo.radius
    nang = 361
    thresh = 0.85
    th = fltarr(nang)
    for i = 0L, nang-1 do th[i] = float(i) * (!pi/180.)
    coverage = 0.5
    
    ; undo previous circle
    xc = rad * cos(th) + xcen
    yc = rad * sin(th) + ycen
    plots, xc, yc, color=pixcolor
    fmask = fltarr(maskinfo.xsz, maskinfo.ysz)
    tmp = intarr(maskinfo.xsz, maskinfo.ysz)
    fmask[*,*] = 0.
    tmp[*,*] = 1
    mpol = 1
    idp3_photcircle, fmask, tmp, nang, thresh, rad, rad, xcen, ycen, $
	mpol, nbad, maskinfo.xsz, maskinfo.ysz
    res = where(fmask ge coverage, count)
    if count gt 0 then begin
      yy = fix(res/maskinfo.xsz)
      xx = res MOD maskinfo.xsz
      xp = xx / maskinfo.zoomfact
      yp = yy / maskinfo.zoomfact
      for i = 0l, n_elements(xp) - 1 do begin
	maskim[xp[i],yp[i]] = 1
	maskcol[xp[i],yp[i]] = 1
      endfor
      if ptr_valid(maskinfo.last_region) $  
	then ptr_free,maskinfo.last_region
      if ptr_valid(info.maskpix.last_region) $
	then ptr_free, info.maskpix.last_region
    endif
    
    ; apply updated circle
    xc = newrad * cos(th) + newxc
    yc = newrad * sin(th) + newyc
    plots, xc, yc, color=pixcolor
    fmask = fltarr(maskinfo.xsz, maskinfo.ysz)
    tmp = intarr(maskinfo.xsz, maskinfo.ysz)
    fmask[*,*] = 0.
    tmp[*,*] = 1
    mpol = 1
    idp3_photcircle, fmask, tmp, nang, thresh, newrad, newrad, newxc, $
	newyc, mpol, nbad, maskinfo.xsz, maskinfo.ysz
    res = where(fmask ge coverage, count)
    if count gt 0 then begin
      yy = fix(res/maskinfo.xsz)
      xx = res MOD maskinfo.xsz
      xp = xx / maskinfo.zoomfact
      yp = yy / maskinfo.zoomfact
      for i = 0l, n_elements(xp) - 1 do begin
	maskim[xp[i],yp[i]] = 0
	maskcol[xp[i],yp[i]] = pixcolor
      endfor
    endif
    rsiz = size(xp)
    region = intarr(rsiz[1],2)
    region[*,0] = xp
    region[*,1] = yp
    zdisplay = bmask_display(maskinfo, im, maskim)
    maskinfo.zdisplay = ptr_new(zdisplay)
    maskinfo.last_region = ptr_new(region)
    info.maskpix.last_region = ptr_new(region)
    mask_update = 1
    maskinfo.xcircle = newxc
    maskinfo.ycircle = newyc
    maskinfo.radius = newrad
  end

  maskinfo.maskveqField: begin
    Widget_Control, maskinfo.maskveqField, Get_Value = mask_veq
    info.maskpix.mask_veq = mask_veq
    zz = where(im eq mask_veq, cnt)
    if cnt gt 0 then begin
      maskim[zz] = 0
    endif
    str = string(cnt) + ' pixels masked whose values are equal to ' + $
       string(mask_veq)
    idp3_updatetxt, info, str
  end

  maskinfo.maskvltField: begin
    Widget_Control, maskinfo.maskvltField, Get_Value = mask_vlt
    info.maskpix.mask_vlt = mask_vlt
    zz = where(im lt mask_vlt, cnt)
    if cnt gt 0 then begin
      maskim[zz] = 0
    endif
    str = string(cnt) + ' pixels masked whose values are less than ' + $
       string(mask_vlt)
    idp3_updatetxt, info, str
  end

  maskinfo.maskvgtField: begin
    Widget_Control, maskinfo.maskvgtField, Get_Value = mask_vgt
    info.maskpix.mask_vgt = mask_vgt
    zz = where(im gt mask_vgt, cnt)
    if cnt gt 0 then begin
      maskim[zz] = 0
    endif
    str = string(cnt) + ' pixels masked whose values are greater than ' + $
       string(mask_vgt)
    idp3_updatetxt, info, str
  end

  maskinfo.maskDraw: begin
    xb = 0
    yb = 0
    xe = maskinfo.xsz-1
    ye = maskinfo.ysz-1
    x = event.x > xb < xe
    y = event.y > yb < ye
    xp = x / maskinfo.zoomfact
    yp = y / maskinfo.zoomfact
    print, 'polygon: ', xp, yp
    cc = maskinfo.cursor_color
    ;if maskinfo.circle_pressed eq 0 and maskinfo.region_pressed eq 0 and $
    ;  maskinfo.polygon_pressed eq 0 then begin
      idp3_maskcursor, *maskinfo.zdisplay, x, y, xb, xe, yb, ye, cc
    ;endif
    xf = xp 
    yf = yp 
    if maskinfo.disp eq 2 then begin
      zp = maskim[xp,yp]
      vstr = strtrim(string(zp, format="(i)"), 2)
    endif else begin
      zp = im[xf,yf]
      vstr = strtrim(string(zp, format="(f)"), 2)
    endelse
    str = string(format="('X: ',i4,' Y: ',i4,' Value: ')", xf, yf) + vstr
    Widget_Control, maskinfo.pixlab, Set_Value = str
    Case maskinfo.mouse_mode of
    0: begin
      maskinfo.circle_pressed = 0
      maskinfo.region_pressed = 0
      maskinfo.polygon_pressed = 0
    end
    1: begin
      if event.press eq 1 then begin
	if maskim[xp,yp] eq 1 then begin
	  maskim[xp,yp] = 0
	  maskcol[xp,yp] = pixcolor
	  str = 'Buildmask: Masking pixel [' + strtrim(string(xf),2) + ',' + $
	     strtrim(string(yf),2) + ']'
          idp3_updatetxt, info, str
        endif else begin
	  maskim[xp,yp] = 1
	  maskcol[xp,yp] = white
	  str = 'Buildmask: Un-Masking pixel [' + strtrim(string(xf),2) + $
	      ',' + strtrim(string(yf),2) + ']'
          idp3_updatetxt, info, str
        endelse
	zdisplay = bmask_display(maskinfo, im, maskim)
	maskinfo.zdisplay = ptr_new(zdisplay)
	maskinfo.last_pixel = [xp, yp]
	info.maskpix.last_pixel = [xp,yp]
	mask_update = 1
      endif
    end
    2: begin
      nang = 361
      thresh = 0.85 
      th = fltarr(nang)
      for i = 0L, nang-1 do th[i] = float(i) * (!pi/180.)
      if event.press ge 1 then begin
	if maskinfo.radius gt 0. then begin
          tv, *maskinfo.zdisplay
        endif 
	maskinfo.xcircle = x
 	maskinfo.ycircle = y
	maskinfo.circle_pressed = 1
	maskinfo.radius = -1.
	;device, cursor_standard=30
      endif
      if maskinfo.circle_pressed eq 1 then begin
	deltax = maskinfo.xcircle - float(event.x)
	deltay = maskinfo.ycircle - float(event.y)
	maskinfo.radius = sqrt(float(deltax)^2 + float(deltay)^2)
	tv, *maskinfo.zdisplay
	plots, maskinfo.radius * cos(th) + maskinfo.xcircle, $
	  maskinfo.radius * sin(th) + maskinfo.ycircle,/Device,color=pixcolor
        rad = Round(maskinfo.radius/maskinfo.zoomfact)
        Widget_Control, maskinfo.radiusField, Set_Value=rad
	xcen = maskinfo.xcircle/maskinfo.zoomfact
	Widget_Control, maskinfo.xcenField, Set_Value=xcen
	ycen = maskinfo.ycircle/maskinfo.zoomfact
	Widget_Control, maskinfo.ycenField, Set_Value=ycen
      endif
      if event.release ge 1 then begin
	maskinfo.circle_pressed = 0
	tv, *maskinfo.zdisplay
 	xcen = maskinfo.xcircle
	ycen = maskinfo.ycircle
        rad = maskinfo.radius
        xc = rad * cos(th) + xcen
        yc = rad * sin(th) + ycen
        plots, xc, yc, color=pixcolor
        coverage = 0.5
        fmask = fltarr(maskinfo.xsz, maskinfo.ysz)
        tmp = intarr(maskinfo.xsz, maskinfo.ysz)
        fmask[*,*] = 0.
        tmp[*,*] = 1
        mpol = 1
        idp3_photcircle, fmask, tmp, nang, thresh, rad, rad, xcen, ycen, $
	      mpol, nbad, maskinfo.xsz, maskinfo.ysz
        res = where(fmask ge coverage, count)
        if count gt 0 then begin
          yy = fix(res/maskinfo.xsz)
          xx = res MOD maskinfo.xsz
          xp = xx / maskinfo.zoomfact
          yp = yy / maskinfo.zoomfact
          for i = 0l, n_elements(xp) - 1 do begin
            maskim[xp[i],yp[i]] = 0
            maskcol[xp[i],yp[i]] = pixcolor
          endfor
          rsiz = size(xp)
          region = intarr(rsiz[1],2)
          region[*,0] = xp
          region[*,1] = yp
	  zdisplay = bmask_display(maskinfo, im, maskim)
	  maskinfo.zdisplay = ptr_new(zdisplay)
          if ptr_valid(maskinfo.last_region) $
	     then ptr_free,maskinfo.last_region
          maskinfo.last_region = ptr_new(region)
	  if ptr_valid(info.maskpix.last_region) $
	    then ptr_free, info.maskpix.last_region
          info.maskpix.last_region = ptr_new(region)
	  mask_update = 1
        endif
      endif
    end
    3: begin
      ; draw polygon with discrete points to mask area
      if event.press ge 1 then begin
        if maskinfo.polygon_pressed eq 0 and not ptr_valid(maskinfo.polyx) $
	  then begin
		  ; start new polygon 
		  tv, *maskinfo.zdisplay
			  xpts = x
			  ypts = y
			  maskinfo.polyx = ptr_new(xpts)
			  maskinfo.polyy = ptr_new(ypts)
		  maskinfo.polygon_pressed = 1
		  ;device, cursor_standard=30
		  plots, x-3, y, color=polycolor, /device
		  plots, x+3, y, color=polycolor, /device, /continue
		  plots, x, y-3, color=polycolor, /device
		  plots, x, y+3, color=polycolor, /device, /continue
        endif else begin
          xpts = *maskinfo.polyx
          ypts = *maskinfo.polyy
          lastpt = n_elements(xpts) 
          lastx = xpts[lastpt-1]
          lasty = ypts[lastpt-1]
          xpts = [xpts, x]
          ypts = [ypts, y]
          plots, xpts[0], ypts[0], color=polycolor, /device
          for i = 1, lastpt do begin
            plots, xpts[i], ypts[i], color=polycolor, /device, /continue
          endfor
          if ABS(x-lastx) LE 2 AND ABS(y-lasty) LE 2 then begin 
            ; end of polygon
	    if lastpt ge 2 then begin
	      npts = n_elements(xpts)
	      xpts = xpts[0:npts-2]
	      ypts = ypts[0:npts-2]
              ;xpts = [xpts, xpts[0]]
              ;ypts = [ypts, ypts[0]]
              plots, x, y, color=polycolor, /device
	      plots, xpts[0], ypts[0], /device, color=polycolor, /continue
	      mxsz = maskinfo.xsz
	      mysz = maskinfo.ysz
	      res = polyfillv(xpts, ypts, mxsz, mysz)
	      yy = fix(res/maskinfo.xsz)
	      xx = res MOD maskinfo.xsz
	      xp = ceil(float(xx) / float(maskinfo.zoomfact))
	      yp = ceil(float(yy) / float(maskinfo.zoomfact))
	      print, min(xp), max(xp), min(yp), max(yp)
	      for i = 0l, n_elements(xp) - 1 do begin
	        maskim[xp[i],yp[i]] = 0
	        maskcol[xp[i],yp[i]] = dmcolor
          endfor
	      rsiz = size(xp)
	      region = intarr(rsiz[1],2)
	      region[*,0] = xp
	      region[*,1] = yp
	      zdisplay = bmask_display(maskinfo, im, maskim)
      	      maskinfo.zdisplay = ptr_new(zdisplay)
	      if ptr_valid(maskinfo.last_region) $
	        then ptr_free, maskinfo.last_region
	      maskinfo.last_region = ptr_new(region)
	      if ptr_valid(info.maskpix.last_region) $
	        then ptr_free, info.maskpix.last_region
              info.maskpix.last_region = ptr_new(region)
	      mask_update = 1
	      ptr_free, maskinfo.polyx
	      ptr_free, maskinfo.polyy
	      maskinfo.polygon_pressed = 0
              maskinfo.mouse_mode = 0
	      Widget_Control, maskinfo.cursor_buttons, $
		 Set_Value=maskinfo.mouse_mode
            endif else begin
	      str = 'Insufficent number of points in polygon!'
	      idp3_updatetxt, info, str
	      tv, *maskinfo.zdisplay
   	      maskinfo.polygon_pressed = 0
	      ptr_free, maskinfo.polyx
	      ptr_free, maskinfo.polyy
            endelse
          endif else begin   ; continue saving polygon points 
            plots, lastx, lasty, color=polycolor, /device
            plots, x, y, color=polycolor, /device, /continue
	    ptr_free, maskinfo.polyx
	    ptr_free, maskinfo.polyy
            maskinfo.polyx = ptr_new(xpts)
            maskinfo.polyy = ptr_new(ypts)
          endelse
        endelse
      endif else begin
	if ptr_valid(maskinfo.polyx) then begin
	  xpts = *maskinfo.polyx
	  npt = n_elements(xpts)
	  ypts = *maskinfo.polyy
	  if npt eq 1 then begin
	    plots, xpts[0]-3, ypts[0], color=polycolor, /device
	    plots, xpts[0]+3, ypts[0], color=polycolor, /device, /continue
	    plots, xpts[0], ypts[0]-3, color=polycolor, /device
	    plots, xpts[0], ypts[0]+3, color=polycolor, /device, /continue
	  endif else begin
            plots, xpts[0], ypts[0], color=polycolor, /device
            for i = 1, npt-1 do begin
              plots, xpts[i], ypts[i], color=polycolor, /device, /continue
            endfor
	  endelse
        endif
      endelse
    end
    4: begin
      if event.press eq 1 and maskinfo.region_pressed eq 0 then begin
	maskinfo.region_pressed = 1
        device, cursor_standard = 30
        Widget_Control, maskinfo.maskid,Draw_Motion_Events=0
        Widget_Control, maskinfo.maskid,Draw_Button_Events=0
        tv, *maskinfo.zdisplay
	plots, x-3, y, color=regcolor, /device
	plots, x+3, y, color=regcolor, /device, /continue
	plots, x, y-3, color=regcolor, /device
	plots, x, y+3, color=regcolor, /device, /continue
        drawpoly, xc, yc, thick=2, color=regcolor
        zdisplay = tvrd()
	maskinfo.zdisplay = ptr_new(zdisplay)
        res = polyfillv(xc, yc, maskinfo.xsz, maskinfo.ysz)
        yy = fix(res/maskinfo.xsz)
        xx = res MOD maskinfo.xsz
        xp = xx / maskinfo.zoomfact
        yp = yy / maskinfo.zoomfact
        for i = 0l, n_elements(xp) - 1 do begin
          maskim[xp[i],yp[i]] = 0
          maskcol[xp[i],yp[i]] = regcolor
        endfor
        rsiz = size(xp)
        region = intarr(rsiz[1],2)
        region[*,0] = xp
        region[*,1] = yp
	zdisplay = bmask_display(maskinfo, im, maskim)
	maskinfo.zdisplay = ptr_new(zdisplay)
        if ptr_valid(maskinfo.last_region) then ptr_free,maskinfo.last_region
        maskinfo.last_region = ptr_new(region)
	if ptr_valid(info.maskpix.last_region) $
	  then ptr_free, info.maskpix.last_region
	info.maskpix.last_region = ptr_new(region)
	mask_update = 1
        ; turn cursor back on
        Widget_Control, maskinfo.maskid,Draw_Motion_Events=1
        Widget_Control, maskinfo.maskid,Draw_Button_Events=1
        maskinfo.mouse_mode = 0
	Widget_Control, maskinfo.cursor_buttons, Set_Value=maskinfo.mouse_mode
	maskinfo.region_pressed = 0
      endif
    end
    else:
    endcase
  end
    else: 
  endcase

  info.maskmode = maskinfo.mouse_mode
  info.maskzoom = maskinfo.zoomfact
  if ptr_valid((*imptr).mask) then ptr_free, (*imptr).mask
  (*imptr).mask = ptr_new(maskim)
  (*info.images)[info.moveimage] = imptr
  Widget_Control, maskinfo.info.idp3Window, Set_UValue=info
  if (*imptr).maskvis eq 1 and mask_update eq 1 then idp3_display, info
  maskinfo.cur_mask = maskim
  maskinfo.color_mask = maskcol
  Widget_Control, event.top, Set_UValue=maskinfo

end  

pro idp3_buildmask, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info

  ; If there are no images, return
  c = size(*info.images)
  if (c[0] eq 0 and c[1] le 2) then begin 
    str = 'Buildmask: No data loaded'
    idp3_updatetxt, info, str
    return
  endif

  ; get reference image if on
  ims = info.images
  imptr = (*ims)[info.moveimage]
  if (*imptr).vis ne 1 then begin
    stat = Widget_Message('Reference Image not ON')
    return
  endif
  im = *(*imptr).data
  imsz = size(im)
  refstr = 'Ref: ' + (*imptr).name
  if ptr_valid((*imptr).mask) then begin
    cur_mask = *(*imptr).mask
  endif else begin
    cur_mask = intarr(imsz[1], imsz[2])
    cur_mask[*,*] = 1
  endelse
  bmask_hdr, imptr, cur_mask, hdr
  cur_hdr = hdr
  xcentroid = (*imptr).lccx
  ycentroid = (*imptr).lccy
  tempx = xcentroid
  tempy = ycentroid
  if xcentroid gt 0.0 and ycentroid gt 0.0 then begin
    xoff = (*imptr).xpoff + (*imptr).xoff + info.sxoff
    if xoff gt 0.0 then tempx = tempx - xoff
    if abs((*imptr).zoom - 1.0) gt 0.00001 then tempx = tempx / (*imptr).zoom
    if (*imptr).xpscl ne 1.0 and (*imptr).xpscl ne 0.0 $
      then tempx = tempx / (*imptr).xpscl
    if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
      then tempx = tempx - (*imptr).pad
    yoff = (*imptr).ypoff + (*imptr).yoff + info.syoff
    if yoff gt 0.0 then tempy = tempy - yoff
    if abs((*imptr).zoom - 1.0) gt 0.00001 then tempy = tempy / (*imptr).zoom
    if (*imptr).ypscl ne 1.0 and (*imptr).ypscl ne 0.0 $
      then tempy = tempy / (*imptr).ypscl
    if (*imptr).topad eq 1 and (*imptr).pad gt 0 $
      then tempy = tempy - (*imptr).pad
    xcentroid = tempx
    ycentroid = tempy
  endif 
  color_mask = cur_mask
  bits = info.color_bits
  colors = info.d_colors
  bwcolor = 200
  cursor_color = 1
  mask_color = 5
  if bits eq 0 then dmcolor = bwcolor else dmcolor = mask_color
  if bits eq 0 then pixcolor = bwcolor else pixcolor = mask_color
  if bits eq 0 then crlcolor = bwcolor else crlcolor = blue
  if bits eq 0 then polycolor = bwcolor else polycolor = green
  if bits eq 0 then regcolor = bwcolor else regcolor = red
  disp=0
  mouse_mode = info.maskmode
  radius = 0.
  xcircle = 0
  ycircle = 0
  
  z1 = info.Z1
  z2 = info.Z2
  zoomfact = info.maskzoom
  xsz = imsz[1] * zoomfact
  ysz = imsz[2] * zoomfact
  last_pixel = info.maskpix.last_pixel
  last_region = info.maskpix.last_region
  if zoomfact eq 1 then begin
    zim = im 
    zmask = cur_mask
  endif else begin
    zim = congrid(im, xsz, ysz)
    zmask = congrid(cur_mask, xsz, ysz)
  endelse
  bim = bytscl(zim,top=colors-bits-1,min=z1, max=z2)+bits
  bad = where(zmask eq 0, cnt)
  if cnt gt 0 then bim[bad] = dmcolor
  zim = 0
  zmask = 0
  mask_vlt = info.maskpix.mask_vlt
  mask_vgt = info.maskpix.mask_vgt
  mask_veq = info.maskpix.mask_veq
  autoscale = 0

    maskWindow = Widget_Base(Title='IDP3 Image Mask Builder', /Column, $
	       Group_Leader = event.top, Mbar=menuBar, /TLB_Size_Events, $
	       TLB_Frame_Attr=8, XOffset = info.wpos.rpwp[0], $
	       YOffset = info.wpos.rpwp[1]) 


    ; build menu bar
    mask_fileMenu = Widget_Button(menuBar, Value="File ", /Menu)
    mask_zoomMenu = Widget_Button(menuBar, Value=" Zoom ", /Menu)
    mask_editMenu = Widget_Button(menuBar, Value = " Edit Mask ", /Menu)
    mask_displayMenu = Widget_Button(menuBar, Value=" Display ", /Menu)
    mask_blinkMenu = Widget_Button(menuBar, Value=" Blink ", /Menu)
    mask_colorMenu = Widget_Button(menuBar, Value=" Color ", /Menu)
    mask_helpMenu = Widget_Button(menuBar, Value=" Help", /Menu)
    mask_doneMenu = Widget_Button(menuBar, Value=" Done", /Menu)

    ; Add to File Menu
    mskloadoverButton = Widget_Button(mask_fileMenu, $
      Value='Load Mask', Event_Pro = 'idp3_imaskload')
    masksaveButton = Widget_Button(mask_fileMenu, Value='Save Mask to File', $
      Event_Pro = 'idp3_savemask')
    masksavelistButton = Widget_Button(mask_fileMenu, $
      Value='Save Mask to List File', Event_Pro = 'idp3_savemasklist')
    maskremoveButton = Widget_Button(mask_fileMenu, Value='Remove Mask', $
      Event_Pro = 'bmask_remove')

    ; Add to Zoom Menu
    zoom1Button = Widget_Button(mask_zoomMenu, Value=' 1 ')
    zoom2Button = Widget_Button(mask_zoomMenu, Value=' 2 ')
    zoom4Button = Widget_Button(mask_zoomMenu, Value=' 4 ')
    zoom8Button = Widget_Button(mask_zoomMenu, Value=' 8 ')
    
    ; Add to Edit Menu
    undolastpButton = Widget_Button(mask_editMenu, Value = 'Undo Last Pixel')
    undolastrButton = Widget_Button(mask_editMenu, Value='Undo Last Freehand')
    undoallButton = Widget_Button(mask_editMenu, Value='Undo All')
    InvertButton = Widget_Button(mask_editMenu, Value='Invert Mask')

    ; Add to Display Menu
    showdmButton = Widget_Button(mask_displayMenu, Value = 'Data-Mask ON')
    showdataButton = Widget_Button(mask_displayMenu, Value = 'Data-Mask OFF')
    showmaskButton = Widget_Button(mask_displayMenu, Value = 'Mask')
    showmavButton = Widget_Button(mask_displayMenu, Value = $
       'Mask + Invalid Pixels')
    showdmavButton = Widget_Button(mask_displayMenu, Value = $
       'Data-Mask/Invalid Pixels')

    ; Add to Blink Menu
    blinkddButton = Widget_Button(mask_blinkMenu,Value='Data(MaskON,MaskOFF')
    blinkdmButton = Widget_Button(mask_blinkMenu, Value = 'Data/Mask')

    ; Add to Color Menu
    colorcursorMenu = Widget_Button(mask_colorMenu, Value='Cursor', /Menu)
    colormaskMenu = Widget_Button(mask_colorMenu, Value='Mask', /Menu)

    ; Add to Color Cursor Menu
    blackcursorButton = Widget_Button(colorcursorMenu, Value='Black')
    whitecursorButton = Widget_Button(colorcursorMenu, Value='White')
    redcursorButton   = Widget_Button(colorcursorMenu, Value='Red')
    greencursorButton = Widget_Button(colorcursorMenu, Value='Green')
    bluecursorButton  = Widget_Button(colorcursorMenu, Value='Blue')
    yellowcursorButton = Widget_Button(colorcursorMenu, Value='Yellow')

    ; Add to Color Mask Menu
    blackmaskButton = Widget_Button(colormaskMenu, Value='Black')
    whitemaskButton = Widget_Button(colormaskMenu, Value='White')
    redmaskButton   = Widget_Button(colormaskMenu, Value='Red')
    greenmaskButton = Widget_Button(colormaskMenu, Value='Green')
    bluemaskButton  = Widget_Button(colormaskMenu, Value='Blue')
    yellowmaskButton = Widget_Button(colormaskMenu, Value='Yellow')

    ; Add to Help Menu
    helpButton = Widget_Button(mask_helpMenu, Value='Help')

    ; Add to Done Menu
    maskdoneButton = Widget_Button(mask_doneMenu, Value='Done')

    curbase = Widget_Base(maskWindow, row=1, frame=1, map=1, uvalue='curbase')
    cursor_label = Widget_Label(curbase, Value='Select Mouse Mode: ')
    cursor_button_names = [$
      'None', $
      'Pixel', $
      'Circle', $
      'Polygon', $
      'Freehand' ]
    cursor_button_value = mouse_mode
    cursor_buttons=CW_BGROUP(curbase, cursor_button_names, row=1, exclusive=1,$
      Event_Funct='bmask_cursor', Set_Value=cursor_button_value, /no_release)

    mvalBase = Widget_Base(maskWindow, /Row, /frame)
    mvallab = Widget_Label(mvalBase, Value='Mask Values: ')
    maskveqField = cw_field(mvalBase, Value = mask_veq, uvalue = 'meq', $
       title = 'Equal to', xsize = 8, /Return_Events, /Floating)
    maskvltField = cw_field(mvalBase, Value = mask_vlt, uvalue = 'mlt', $
       title = 'Less than', xsize = 8, /Return_Events, /Floating)
    maskvgtField = cw_field(mvalBase, Value = mask_vgt, uvalue = 'mgt', $
       title = 'Greater than', xsize = 8, /Return_Events, /Floating)

    namlab = Widget_Label(maskWindow, Value = refstr)
    
    pixBase = Widget_Base(maskWindow, /Row)
    xcenField = cw_field(pixbase, value=0, title='Circle: Center X', $
		uvalue='xcen', xsize=5, /Return_Events, /Integer)
    ycenField = cw_field(pixbase, value=0, title=' Y', $
		uvalue='ycen', xsize=5, /Return_Events, /Integer)
    getrefButton = Widget_Button(pixbase, Value='Ref Cntrd', $
                   /align_center)
    radiusField = cw_field(pixbase, value=0, title='Radius:', $
		uvalue='crad', xsize=3, /Return_Events, /Integer)
    updatButton = Widget_Button(pixbase, Value='Update')

    ccbase = Widget_Base(maskWindow, /Row)
    ;cclabel = Widget_Label(ccbase, Value='Cursor Color:')
    ;cc_button_names = ['Black', 'White', 'Red']
    ;cc_buttons = CW_BGroup(ccbase, cc_button_names, row=1, exclusive=1, $
;	  Event_Funct='bmask_ccolor', Set_Value=cursor_color, /no_release)

    pminField = cw_field(ccBase, value=z1, title='Plot: Min', $
		uvalue='pmin', xsize=7, /Return_Events, /Floating)
    pmaxField = cw_field(ccBase, value=z2, title='Max', $
		uvalue='pmax', xsize=7, /Return_Events, /Floating)

    autoButton  = cw_bgroup(ccBase,['Auto'], row = 1,  $
		   set_value = [AutoScale], /nonexclusive)
    pixlab = Widget_Label(ccBase, Value = $
     '                                      ')

    maxx = info.bmaskxsize
    maxy = info.bmaskysize
    if xsz le maxx and ysz le ysz then begin
       maskDraw = Widget_Draw(maskWindow, XSize = maxx, YSize = maxy, $
	       /Motion_Events, /Button_Events, retain=info.retn) 
       scroll = 0
    endif else begin 
       maskDraw = Widget_Draw(maskWindow, XSize = xsz, YSize = ysz, $
	       x_scroll_size=maxx, y_scroll_size=maxy, /scroll, $
	       /Motion_Events, /Button_Events, retain=info.retn)
       scroll = 1
    endelse

    Widget_Control, maskWindow, /Realize

    info.maskWindow = maskWindow
    Widget_Control,info.idp3Window,Set_UValue=info

    Widget_Control, maskDraw, Get_Value = maskid
    wset, maskid
    tv, bim
    ;zzdisplay = tvrd()
    zdisplay = ptr_new(bim) ; ptr_new(zzdisplay)

    maskinfo = { maskWindow      :  maskWindow,      $
		 zoom1Button     :  zoom1Button,     $
		 zoom2Button     :  zoom2Button,     $
		 zoom4Button     :  zoom4Button,     $
		 zoom8Button     :  zoom8Button,     $
		 showdmButton    :  showdmButton,    $
		 showdataButton  :  showdataButton,  $
		 showmaskButton  :  showmaskButton,  $
		 showmavButton   :  showmavButton,   $
		 showdmavButton  :  showdmavButton,  $
		 undolastpButton :  undolastpButton, $
		 undolastrButton :  undolastrButton ,$
		 undoallButton   :  undoallButton,   $
		 InvertButton    :  InvertButton,    $
		 blinkddButton   :  blinkddButton,   $
		 blinkdmButton   :  blinkdmButton,   $
		 cursor_buttons  :  cursor_buttons,  $
		 blackcursorButton :  blackcursorButton, $
		 whitecursorButton :  whitecursorButton, $
		 redcursorButton   :  redcursorButton,   $
		 greencursorButton :  greencursorButton, $
		 bluecursorButton  :  bluecursorButton,  $
		 yellowcursorButton : yellowcursorButton, $
		 blackmaskButton :  blackmaskButton, $
		 whitemaskButton :  whitemaskButton, $
		 redmaskButton   :  redmaskButton,   $
		 greenmaskButton :  greenmaskButton, $
		 bluemaskButton  :  bluemaskButton,  $
		 yellowmaskButton : yellowmaskButton, $
		 helpButton      :  helpButton,      $
		 maskdoneButton  :  maskdoneButton,  $
		 xcenField       :  xcenField,       $
		 ycenField       :  ycenField,       $
		 getrefButton    :  getrefButton,    $
		 updatButton     :  updatButton,     $
		 pixlab          :  pixlab,          $
		 pminField       :  pminField,       $
		 pmaxField       :  pmaxField,       $
		 autoButton      :  autoButton,      $
		 radiusField     :  radiusField,     $
		 maskvltField    :  maskvltField,    $
		 maskvgtField    :  maskvgtField,    $
		 maskveqField    :  maskveqField,    $
		 maskid          :  maskid,          $
		 maskDraw        :  maskDraw,        $
		 scroll          :  scroll,          $
		 zoomfact        :  zoomfact,        $
		 disp            :  disp,            $
		 cur_mask        :  cur_mask,        $
		 cur_hdr         :  cur_hdr,         $
		 color_mask      :  color_mask,      $
		 last_region     :  last_region,     $
		 last_pixel      :  last_pixel,      $
		 zdisplay        :  zdisplay,        $
		 xcentroid       :  xcentroid,       $
		 ycentroid       :  ycentroid,       $
		 xsz             :  xsz,             $
		 ysz             :  ysz,             $
		 maxx            :  maxx,            $
		 maxy            :  maxy,            $
		 mouse_mode      :  mouse_mode,      $
		 cursor_color    :  cursor_color,    $
		 mask_color      :  mask_color,      $
		 bits            :  bits,            $
		 colors          :  colors,          $
		 bwcolor         :  bwcolor,         $
		 dmcolor         :  dmcolor,         $
		 pixcolor        :  pixcolor,        $
		 crlcolor        :  crlcolor,        $
		 polycolor       :  polycolor,       $
		 regcolor        :  regcolor,        $
		 circle_pressed  :  0,               $
		 radius          :  radius,          $
		 xcircle         :  xcircle,         $
		 ycircle         :  ycircle,         $
		 polygon_pressed :  0,               $
		 polyx           :  ptr_new(),       $
		 polyy           :  ptr_new(),       $
		 polydone        :  0,               $
		 polypts         :  0,               $
		 region_pressed  :  0,               $
		 z1              :  z1,              $
		 z2              :  z2,              $
		 autoscale       :  autoscale,       $
	         info            :  info             }

    Widget_Control, info.idp3Window, Set_UValue = info
    Widget_Control, maskWindow, Set_UValue = maskinfo
    XManager, 'idp3_mask', maskWindow, /No_Block, Event_Handler='buildmask_ev'

end

