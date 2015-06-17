function getimask, filename, temphead, info 

  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin
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
	str = 'LoadMask: reading mask from file ' + filename
	idp3_updatetxt, info, str
	msz = size(tempmask)
	if msz[0] eq 3 then begin
	  title = 'Which plane in the 3-D image'
	  label = 'Plane 0-' + strtrim(string(imsz[3]-1),2)
	  valstr = idp3_getvals(title, '0', groupleader=info.idp3Window, $
	    lab1=label, cancel=cancel, xp=200, yp=200)
          if cancel eq 1 then begin
	    str = 'Load Mask: Nothing loaded'
	    idp3_updatetxt, info, str
	    return, -1
          endif
	  pln = fix(valstr)
	  if pln ge 0 and pln lt msz[3]-1 then begin
	    tempmask = tempmask[*,*,pln]
	    getmask = 1
          endif else begin
	    str = 'Load Mask: Incorrect plane for mask'
	    idp3_updatetxt, info, str
          endelse
	endif else getmask = 1
      endif else begin
	for i = 1, fcb.nextend do begin
	  if fcb.extname[i] eq 'DQ' and getmask eq 0 then begin
	    ua_fits_read, fcb, tempmask, temphead, extname='DQ', /no_abort
	    str = 'LoadMask: reading data quality extension from file '+ $
		   filename
            idp3_updatetxt, info, str
	    getmask = 1
          endif
        endfor
	if getmask eq 0 then begin
	  test = Widget_Message('Data Quality extension not found!')
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
	str = 'LoadMask: reading mask from hdf file ' + filename
	idp3_updatetxt, info, str
        if hdr_flag eq 0 then begin
	  temphead = ['','']
	  str = 'LoadMask: No fits header found in file ' + filename
	  idp3_updatetxt, info, str 
        endif
      endif else begin
	str = 'File ' + filename + ' not recognized as fits or hdf format'
	a = Widget_Message(str)
      endelse
    end
    endcase
    if getmask eq 1 then begin
      return, tempmask
    endif else begin
      return, -1
    endelse
  endif else begin
    stat = Widget_Message('File not found')
    temphdr = ['  ', '  ']
    return, -1
  endelse
  end

pro imaskload_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=loadmaskinfo
  Widget_Control, loadmaskinfo.maskinfo.maskWindow, Get_UValue = maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue=info

  ims = info.images
  imptr = (*ims)[info.moveimage]
  im = *(*imptr).data
  maskim = maskinfo.cur_mask
  msz = size(maskim)

  case event.id of

    loadmaskinfo.selectfile: begin
      Widget_Control, loadmaskinfo.selectfile, Get_Value = filename
      filename = strtrim(filename(0), 2)
      ua_decompose, filename, disk, path, name, extn, version
      if strlen(extn) eq 0 then filename = filename + '.fit'
      info.imagepath = disk + path
      temp = file_search (filename, Count = fcount)
      if (strlen(filename) le 0 or fcount le 0) then begin
	stat = Widget_Message('File not found')
      endif
    end

    loadmaskinfo.browseButton: begin
      inpath = info.imagepath
      infilt = info.imfilter
      filename = Dialog_Pickfile(/Read,Title='Select Mask File', $
	   Get_Path=outpath, Path=inpath, Filter=infilt)
      filename = strtrim(filename[0], 2)
      info.imagepath = outpath
      Widget_Control, loadmaskinfo.selectfile, set_value=filename
    end

    loadmaskinfo.loadButton: begin
     Widget_Control, loadmaskinfo.selectfile, Get_Value = filename
     filename = strtrim(filename(0), 2)
     ua_decompose, filename, disk, path, name, extn, version
     if strlen(extn) eq 0 then filename = filename + '.fit'
     info.imagepath = disk + path
     mask = getimask(filename, tmphdr, info)
     if n_elements(mask) le 1 then begin
       str = 'Load Mask: No mask'
       idp3_updatetxt, info, str
     endif else begin
       Widget_Control, loadmaskinfo.gvalField, Get_Value=temp
       goodval=round(temp)
       info.maskpix.mask_good = goodval
       tmsz = size(mask)
       if tmsz[1] ne msz[1] or tmsz[2] ne msz[2] then begin
	 tempmask = intarr(msz[1],msz[2])
	 tempmask[*,*] = goodval
	 if msz[1] lt tmsz[1] then begin
	   dx = msz[1]
	   sx = msz[1]
         endif else begin
	   dx = tmsz[1]
	   sx = tmsz[1]
         endelse
	 if msz[2] lt tmsz[2] then begin
	   dy = msz[2]
	   sy = msz[2]
         endif else begin
	   dy = tmsz[2]
	   sy = tmsz[2]
         endelse
	 tempmask(0:dx-1,0:dy-1) = mask[0:sx-1,0:sy-1]
       endif else tempmask = mask
       good = where(tempmask eq goodval, gcnt)
       bad = where(tempmask ne goodval, bcnt)
       if bcnt gt 0 then maskim[bad] = 0
       str= 'Mask: ' + filename + string(bcnt) +  ' pixels masked'
       idp3_updatetxt, info, str
       zdisplay = bmask_display(maskinfo, im, maskim)
       maskinfo.zdisplay = ptr_new(zdisplay)
       maskinfo.cur_mask = maskim
       Widget_Control, loadmaskinfo.maskinfo.maskWindow, Set_UValue=maskinfo
       if ptr_valid((*imptr).mask) then ptr_free, (*imptr).mask
       (*imptr).mask = ptr_new(maskim)
       (*info.images)[info.moveimage] = imptr
       Widget_Control, maskinfo.info.idp3Window, Set_UValue=info
       if (*imptr).maskvis eq 1 then idp3_display, info
       tempmask = 0
     endelse	 
    end

   loadmaskinfo.statsButton: begin
     Widget_Control, loadmaskinfo.selectfile, Get_Value = filename
     filename = strtrim(filename(0), 2)
     ua_decompose, filename, disk, path, name, extn, version
     if strlen(extn) eq 0 then filename = filename + '.fit'
     info.imagepath = disk + path
     mask = getimask(filename, tmphdr, info)
     if n_elements(mask) le 1 then begin
       str = 'BuildMask: No mask'
       idp3_updatetxt, info, str
     endif else begin
       Widget_Control, loadmaskinfo.gvalField, Get_Value=temp
       goodval=round(temp)
       info.maskpix.mask_good = goodval
       good = where(mask eq goodval, gcnt)
       bad = where(mask ne goodval, bcnt)
       str = 'Mask: ' + filename
       idp3_updatetxt, info, str
       str = string(gcnt) + ' pixels good ' + string(bcnt) + ' bad'
       idp3_updatetxt, info, str
     endelse	 
    end

   loadmaskinfo.gvalField: begin
     Widget_Control, loadmaskinfo.gvalField, Get_Value = temp
   end

   loadmaskinfo.doneButton: begin
     Widget_Control, event.top, /Destroy
     return
   end

  endcase
end


pro idp3_imaskload, event

@idp3_errors

  if(XRegistered("idp3_imaskload")) then return
  Widget_Control, event.top, Get_UValue = maskinfo
  Widget_Control, maskinfo.info.idp3Window, Get_UValue = info

  goodval = info.maskpix.mask_good

  title      = 'IDP3 Load/Overlay Mask'
  loadbase   = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
			     xoffset=info.wpos.savwp[0], $
			     yoffset=info.wpos.savwp[1])
  load2base = Widget_Base  (loadbase, /Row)
  label      = Widget_Label (load2base, Value='Filename:') 
  selectfile = Widget_Text  (load2base, Value = ' ', XSize = 50, /Edit)
  browseButton = Widget_Button(load2base, Value='Browse')
  load3base = Widget_Base  (loadbase, /Row)
  gvalField = cw_field(load3Base, value=goodval, title='Mask Good Value:', $
      uvalue='gval', xsize=4, /Return_Events, /Floating)
  statsButton = Widget_Button(load3base, Value = 'Mask Statistics')
  loadButton = Widget_Button(load3base, Value = 'Load Mask')
  doneButton = Widget_Button(load3base, Value = 'Done')

  loadmaskinfo = {gvalField     :     gvalField,    $
		  selectfile    :     selectfile,   $
		  browseButton  :     browseButton, $
		  statsButton   :     statsButton,  $
		  loadButton    :     loadButton,   $
		  doneButton    :     doneButton,   $
		  maskinfo      :     maskinfo      }

  Widget_Control, loadbase, set_uvalue = loadmaskinfo
  Widget_Control, loadbase, /Realize

  XManager, "idp3_imaskload",loadbase,/NO_Block,Event_Handler = "imaskload_ev"
          
end
