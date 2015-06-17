pro Idp3_LoadImErr, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  loaddata = 0

  ; We keep track of the path the user picks files from.
  inpath = cinfo.imagepath
  infilt = cinfo.imfilter
  filename = Dialog_Pickfile(/Read, Get_Path=outpath, $
	     Path=inpath, Filter=infilt, Title='Please Select Image File')
  cinfo.imagepath = outpath
  ename = cinfo.extnam
  filename = strtrim(filename(0), 2)
  exnum = -1
  extb = strpos(filename, '[')
  exte = strpos(filename, ']')
  if extb gt 0 and exte gt extb then begin
    exnum = fix(strmid(filename, extb+1, exte-extb+1))
    filename = strmid(filename, 0, extb)
  endif

  ; Check if filename is null string (user cancelled)
  if strlen(filename) eq 0 then return

  ; Check to see if this image exists.
  temp = file_search (filename, Count = fcount)
  if fcount gt 0 then begin
    ilen = strlen(filename)
    ua_decompose, filename, disk, path, name, extn, version
    lextn = strlowcase(extn)
    if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
    findx = 0
    lindx = 0
    Case lextn of

      '.fit': Begin
       ; FITS format
       ua_fits_open, filename, fcb
       nextn = fcb.nextend
       if nextn gt 0 then if  fcb.xtension[1] eq 'TABLE' $
	 then nextn = 0
       if nextn gt 0 then begin
         ua_fits_read, fcb, temp, phdr, Exten_No=0, /Header_Only, /no_abort
         maxver = idp3_extver(nextn, fcb.extname, ename)
         if maxver le 0 and exnum ne -1 then begin
	   str = 'Loadimerr: Error in extension name'
	   idp3_updatetxt, cinfo, str
	   loaddata = 0
         endif else begin
	   if exnum lt 0 then exnum = 1
	   exread = exnum < maxver
	   ua_fits_read, fcb, tempdata, ihdr, Extver=exread, Extname=ename, $
	     /NO_PDU, /no_abort
           if n_elements(ihdr) eq 0 then begin
	     ua_fits_close, fcb
	     ua_fits_open, filename, fcb
	     ua_fits_read, fcb, tempdata, phdr, /no_abort
	     ihdr = ['','']
	     exnum = -1
           endif
	   imsz = size(tempdata)
	   loaddata = 1
         endelse
       endif else begin
         ua_fits_read, fcb, tempdata, phdr, /no_abort
 	 imsz = size(tempdata)
	 if imsz[0] ne 3 then begin
	   str = 'Loadimerr: Input image is not 3-D!'
	   idp3_updatetxt, cinfo, str
	   return
         endif
	 ihdr = ['','']
	 loaddata = 1
       endelse
       ua_fits_close, fcb
       end

     else: Begin
      ; Assume HDF format.
      ua_hdf_read, filename, phdr, tempdata, hdr_flag, image_flag
      nextn = 0
      if image_flag eq 1 then begin
	ihdr = ['','']
	if hdr_flag eq 0 then begin
	  phdr = ['','']
	  str = 'Loadimerr: No fits header found in file ' + filename
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
      newim = ptr_new({idp3im})
      if imsz[0] eq 3 then begin
	tdata = tempdata[*,*,0]
	(*newim).name = disk + path + name + extn
	(*newim).extver = 1
	(*newim).extnam = ''
	(*newim).orgname = filename

        ; Set up stuff in the new image structure.
        idp3_imstruct, cinfo, newim, tdata, phdr, ihdr
	errors = tempdata[*,*,1]
        (*newim).errs = ptr_new(errors)
	str = 'Loadimerr: Errors: ' + string(min(errors)) + string(max(errors))
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
      endif
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
    endif
  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  if loaddata eq 0 then begin
    Widget_Control, info.idp3Window, Set_UValue=cinfo
    Widget_Control, info.idp3Window, Get_UValue=info
  endif
 Widget_Control, event.top, Set_UValue=info
end

