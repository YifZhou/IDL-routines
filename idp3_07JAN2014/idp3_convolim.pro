pro idp3_convolimdone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_convolim_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=convolinfo
  Widget_Control, convolinfo.info.idp3Window, GET_UValue=info

  case event.id of

  convolinfo.selectname: begin
    Widget_Control, convolinfo.selectname, Get_Value = temp
  end

  convolinfo.selectpath: begin
    Widget_Control, convolinfo.selectpath, Get_Value = temp
    path = strtrim(temp[0],2)
    plen = strlen(path)
    if strmid(path, plen-1) ne info.delim then path = path + info.delim
  end

  convolinfo.mButtons: begin
    Widget_Control, convolinfo.mButtons, Get_Value = barray
  end

  convolinfo.sButtons: begin
    Widget_Control, convolinfo.sButtons, Get_Value = barray
  end

  convolinfo.selectkernel: begin
    Widget_Control, convolinfo.selectkernel, Get_Value = kfile
  end

  convolinfo.kbrowseButton: begin
    kfile = Dialog_Pickfile(title='Please select kernel file')
    Widget_Control, convolinfo.selectkernel, Set_Value = kfile
  end

  convolinfo.smnpixField: begin
    Widget_Control, convolinfo.smnpixField, Get_Value = npix
  end

  convolinfo.browseButton: begin
    pathvalue = Dialog_Pickfile(title='Please select output file path')
    ua_decompose, pathvalue, disk, path, file, extn, vers
    fpath = disk + path
    Widget_Control, convolinfo.selectpath, Set_Value = fpath
  end

  convolinfo.computButton: begin
    Widget_Control, convolinfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message('Must select IDP3, File, or both for results')
      return
    endif
    sav2idp3 = barray[0]
    sav2file = barray[1]
    Widget_Control, convolinfo.selectname, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      stat = Widget_Message('Must give name for results')
      return
    endif
    c = size(*info.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'Convolve: No images loaded'
      idp3_updatetxt, info, str
      return
    endif
    ims = (*info.images)
    moveim = info.moveimage
    ref = ims[moveim]
    data = (*info.dispim)
    alpha = (*info.alphaim)

    Widget_Control, convolinfo.mbuttons, Get_Value = meth
    if meth eq 0 then begin
      Widget_Control, convolinfo.selectkernel, Get_Value = temp
      kfile = strtrim(temp[0],2)
      if strlen(kfile) eq 0 then begin
        stat = Widget_Message('Must provide name of kernel file')
        return
      endif
      tmp = file_search(kfile, Count=fcount)
      if fcount le 0 then begin
        str = 'Kernel file: ' + kfile + ' not found'
        stat = Widget_Message(str)
        return
      endif
      ua_fits_read, kfile, kernel, khdr
      final = convol(data, kernel)
      str = 'Convolution with ' + kfile + ' ' + systime()
    endif else begin
      Widget_Control, convolinfo.smnpixField, Get_Value = npix
      if npix lt 2 then begin
	stat = Widget_Message('Invalid npix specification')
	return
      endif
      if info.exclude_invalid gt 0 then begin
	bad = where(data eq info.invalid, cnt)
	if cnt gt 0 then begin
	  testim = data
	  testim[bad] = !values.f_nan
	  print, 'Boxcar smooth: ', cnt, ' pixels excluded'
        endif else print, 'Boxcar smmoth: No pixels to exclude'
      endif else testim = data
      final = smooth(testim, npix, /edge_truncate, missing=0., /nan)
      str = 'Boxcar smoothed with ' + string(npix) + ' ' + systime()
    endelse
    ; update header for all images that contributed
    imsz = size(final)
    fsz = [imsz[1],imsz[2]]
    l1 = 0
    l2 = n_elements(ims)-1
    if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
      else str = 'Flux Conserved'
    idp3_sethdr, ims, moveim, sfits, phdr, ihdr, fsz, l1, l2, str
    sxaddpar, phdr, 'HISTORY', str
    sfits = info.sfits
    if sav2file eq 1 then begin
      Widget_Control, convolinfo.selectpath, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if strlen(filepath) eq 0 then begin
	stat = Widget_Message('Must give path for file')
	return
      endif
      if strmid(filepath, plen-1) ne info.delim $
        then filepath = filepath + info.delim
      filename = filepath + idp3name
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
    if sav2idp3 eq 1 then begin
      ; update images structure
      final_msk = intarr(imsz[1], imsz[2])
      final_msk[*,*] = 1
      b = where(alpha eq 0., bcnt)
      if bcnt gt 0 then final_msk[b] = 0
      newim = ptr_new({idp3im})
      idp3_setimstruct, newim, phdr, ihdr, ref, sav2file
      (*newim).name = idp3name
      (*newim).orgname = idp3name
      (*newim).data = ptr_new(final)
      (*newim).mask = ptr_new(final_msk)
      (*newim).xsiz = imsz[1]
      (*newim).ysiz = imsz[2]
      c = imscale(final,10.0)
      (*newim).z1 = c[0]
      (*newim).z2 = c[1]
      tempimages = [*info.images, newim]
      ptr_free, info.images
      info.images = ptr_new(tempimages)
      Widget_Control, info.idp3Window, Set_UValue=info
      if (XRegistered('idp3_showim')) then begin
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
    if sav2file eq 1 then begin
      if strlen(extn) eq 0 then filename = filename + '.fits'
      temp = file_search (filename, Count = fcount)
      if fcount gt 0 then begin
	idp3_selectval,event.top,'Do you wish to overwrite existing file?',$
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
  end

  endcase

  Widget_Control,convolinfo.info.idp3Window,Get_UValue=tinfo
  convolinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=convolinfo
end

pro idp3_convolim, event

@idp3_structs
@idp3_errors

  if(XRegistered("idp3_convolim")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  sav2idp3 = 0
  sav2file = 0
  saveinpath = info.savepath
  smnpix = 0
  cmeth = 0

  title = 'IDP3 Convolve Display'
  cibase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
 
  cibase1 = Widget_Base (cibase, /row)
  mnames = ['Convolve  ', 'Boxcar Smooth']
  mButtons = cw_bgroup(cibase1, mnames, row=1, uvalue='mbutton', $
      set_value=[cmeth], /exclusive, $
      label_left='Method: ')
  cibase2 = Widget_Base (cibase, /Row)
  cilabel = Widget_Label(cibase2, Value='Convolution Kernel - Select File:')
  kbrowseButton = Widget_Button(cibase2, Value='Browse')
  cibase3 = Widget_Base (cibase, /Row)
  klabel = Widget_Label(cibase3, Value='Name:')
  selectkernel = Widget_Text(cibase3, Value=' ', XSize=40, /Edit)
  smnpixField = cw_field(cibase, value=smnpix, $
    title='Boxcar - Width (pixels): ', $
    uvalue='smth', xsize=5, /Return_Events, /Integer)
  blnklabel = Widget_Label(cibase, Value='    ')
  cibase3 = Widget_Base (cibase, /Column)
  snames = ['IDP3    (name required)', 'File    (name and path required)']
  sButtons = cw_bgroup(cibase3, snames, column=1, uvalue='sbutton', $
      set_value=[sav2idp3,sav2file], /nonexclusive, $
      label_top='Save Results to: ')
  cibase7 = Widget_Base(cibase, /Row)
  label = Widget_Label(cibase7, Value='Name:')
  selectname = Widget_Text(cibase7, Value = ' ', XSize = 40, /Edit)
  cibase6 = Widget_Base(cibase, /Row)
  label2 = Widget_Label(cibase6, Value='Path:')
  selectpath = Widget_Text(cibase6, Value = saveinpath, XSize = 40, /Edit)
  space2 = Widget_Label(cibase, Value = '  ')
  cibase5 = Widget_Base(cibase, /Row)
  browseButton = Widget_Button(cibase5, Value='Browse for Path')
  computButton = Widget_Button(cibase5, Value = ' Compute ')
  doneButton = Widget_Button(cibase5, Value = ' Done ', $
	      Event_Pro='idp3_convolimdone')

  convolinfo =  { sButtons       :   sButtons,       $
		  kbrowseButton  :   kBrowseButton,  $
		  selectkernel   :   selectkernel,   $
		  mButtons       :   mButtons,       $
		  smnpixField    :   smnpixField,    $
	          selectname     :   selectname,     $
	          browseButton   :   browseButton,   $
	          selectpath     :   selectpath,     $
	          computButton   :   computButton,   $
	          info           :   info            }

  Widget_Control, cibase, set_uvalue = convolinfo
  Widget_Control, cibase, /Realize

  XManager, "idp3_convolim", cibase, Event_Handler = "idp3_convolim_ev", $
       /No_Block
          
end
