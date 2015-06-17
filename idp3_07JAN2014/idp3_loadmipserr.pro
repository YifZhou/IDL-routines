pro Idp3_LoadMIPSErr, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  ; We keep track of the path the user picks files from.
  inpath = cinfo.imagepath
  infilt = cinfo.imfilter
  extnam = cinfo.extnam
  filename = Dialog_Pickfile(/Read, /Must_Exist, Get_Path=outpath, $
	     Path=inpath, Filter=infilt, Title='Please Select Image File')
  cinfo.imagepath = outpath
  filename = strtrim(filename(0), 2)

  ; Check if selection cancelled
  if strlen(filename) eq 0 then return

  ; Check to see if this image exists.
  temp = file_search (filename, Count = fcount)
  if fcount ne 0 then begin
    newim = ptr_new({idp3im})

    ilen = strlen(filename)
    ua_decompose, filename, disk, path, name, extn, version
    lextn = strlowcase(extn)
    if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
    if lextn ne '.fit' then begin
      str = 'LoadMIPSerr only works with MIPS multi-extension fits files!'
      idp3_updatetxt, cinfo, str
      return
    endif
    ua_fits_open, filename, fcb
    nextend = fcb.nextend
    if nextend le 1 then begin
      str = 'LoadMIPSerr only works with MIPS multi-extension fits files!'
      idp3_updatetxt, cinfo, str
      return
    endif
    title = 'Select reads to load, max= ' + strtrim(string(nextend),2)
    idp3_getread, title, 20, '*', value
    all = strpos(value, '*')
    if all lt 0 then begin 
      n1 = fix(value) > 1
      n2 = n1
    endif else begin
      n1 = 1
      n2 = nextend
    endelse
    ua_fits_read, fcb, temp, phdr, Exten_No=0, /Header_Only, /no_abort
    for i = n1, n2 do begin
      ua_fits_read, fcb, tempdata, ihdr, Exten_No=i, $
	 /NO_PDU, /no_abort
      if n_elements(ihdr) le 0 then ihdr = '    '
      imsz = size(tempdata)
      if imsz[0] eq 3 then begin
	implane = 0
	errplane = 1
	tdata = tempdata[*,*,implane]
	errors = tempdata[*,*,errplane]
      endif else begin
	str = 'LoadMIPSerr: No errors present, must abort'
	idp3_updatetxt, cinfo, str
	return
      endelse
      notnan = finite(tdata)
      bad = where(notnan eq 0, bcount)
      num = float(n_elements(tdata))
      badpct = (float(bcount)/num) * 100.
      if badpct gt info.m_pctnan then begin
	str = 'LoadMIPSerr: ' + string(badpct) + '% pixels bad (' + $
	      strtrim(string(bcount),2) + ' pixels), image omitted'
        idp3_updatetxt, cinfo, str
      endif else begin
        newim = ptr_new({idp3im})
        indx = setnum(i, nextend, 1)
        (*newim).name = disk + path + name + '_' + indx + extn 
        str = 'LoadMIPSerr: ' +  (*newim).name 
	idp3_updatetxt, cinfo, str
        (*newim).extnam = 'None'
        (*newim).extver = i
        (*newim).orgname = filename

        ; set up image structure
        idp3_imstruct, cinfo, newim, tdata, phdr, ihdr
        (*newim).errs = ptr_new(errors)
	str = 'LoadMIPSerr: Errors: ' + string(min(*(*newim).errs)) + $
	       string(max(*(*newim).errs))
        idp3_updatetxt, cinfo, str

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
      endelse
    endfor
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
    idp3_showim, {WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,SELECT:0}
    Widget_Control, cinfo.idp3Window, Get_UValue=info
  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  ; Update graphics display.
  idp3_display,info

  Widget_Control, event.top, Set_UValue=info

end

