pro Idp3_Loadwgts, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=cinfo

  c = size(*cinfo.images)
  if (c[0] eq 0 and c[1] eq 2) then begin
    stat = Widget_Message('Cannot load weight image - no images loaded!')
    return
  endif
  moveim = cinfo.moveimage

  ; We keep track of the path the user picks files from.
  inpath = cinfo.imagepath
  infilt = cinfo.imfilter
  filename = Dialog_Pickfile(/Read, Get_Path=outpath, $
	     Path=inpath, Filter=infilt, Title='Please Select Weight File')
  
  ; Check if filename is null string (user cancelled)
  if strlen(filename) eq 0 then return

  ; Check to see if this image exists.
  temp = file_search (filename, Count = fcount)
  if fcount gt 0 then begin
    ilen = strlen(filename)
    ua_decompose, filename, disk, path, name, extn, version
    lextn = strlowcase(extn)
    if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
    if lextn eq '.fit' then begin
       ua_fits_open, filename, fcb
       ua_fits_read, fcb, tempdata, hdr
       ua_fits_close, fcb
       imsz = size(tempdata)
       if imsz[0] eq 2 then loaddata = 1 else loaddata = 0
     endif else begin
       ; Assume HDF format.
       ua_hdf_read, filename, phdr, tempdata, hdr_flag, image_flag
       if image_flag eq 1 then begin
	 imsz = size(tempdata)
  	 loaddata = 1
       endif else begin
	 str = 'File ' + filename + ' not recognized as fits or hdf format'
	 a = Widget_Message(str)
 	 loaddata = 0
       endelse
     endelse
  endif
  ims = (*cinfo.images)
  if loaddata eq 1 then begin
    data = *(*(*cinfo.images)[moveim]).data
    dsz = size(data)
    if dsz[1] ne imsz[1] or dsz[2] ne imsz[2] then begin
      stat = Widget_Message('Weight image size does not match data')
      return
    endif
    (*(*cinfo.images)[moveim]).wgts = ptr_new(tempdata)
    print, 'Loading weights from ', filename, ' for image ', $
      (*(*cinfo.images)[moveim]).name
    Widget_Control, cinfo.idp3Window, Set_UValue=cinfo
  endif
 Widget_Control, event.top, Set_UValue=info
end

