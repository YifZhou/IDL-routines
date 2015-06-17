
pro Idp3_ReadMask, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  filename = Dialog_Pickfile(/Read, /Must_Exist)
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
	str = 'ReadMask: reading mask from file ' + filename
	idp3_updatetxt, info, str
        getmask = 1
      endif else begin
	for i = 1, fcb.nextend do begin
	  if fcb.extname[i] eq 'DQ' then begin
	    ua_fits_read, fcb, tempmask, temphead, extname='DQ', /no_abort
	    str = 'ReadMask: reading data quality extension from file ' + $
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
	str = 'ReadMask: reading mask from hdf file ' + filename
	idp3_updatetxt, info, str
        if hdr_flag eq 0 then begin
	  temphead = ['','']
	  str = 'ReadMask: No fits header found in file ' + filename
	  idp3_updatetxt, info, str
        endif
      endif else begin
	str = 'File ' + filename + ' not recognized as fits or hdf format'
	a = Widget_Message(str)
      endelse
    end
    endcase

    if getmask eq 1 then begin
      ; If there is already a pointer to mask, free it.
      if ptr_valid((*info.roi).mask) then ptr_free,(*info.roi).mask
   
      (*info.roi).mask = ptr_new(tempmask) 
      bad = where(tempmask ne (*info.roi).maskgood,count)
      (*info.roi).msk = 1
      (*info.roi).maskname = filename
    endif
  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  ; Update graphics display.
  roi_display,info
  Widget_Control, info.roimskonof, Set_Button=(*info.roi).msk

  Widget_Control, event.top, Set_UValue=info
  Widget_Control, info.idp3Window, Set_UValue=info

end

