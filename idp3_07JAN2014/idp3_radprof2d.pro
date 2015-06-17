pro idp3_radprof2ddone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_radprof2d_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=rp2dinfo
  Widget_Control, rp2dinfo.info.idp3Window, GET_UValue=info

  case event.id of

  rp2dinfo.swidtxt: begin
    Widget_Control, rp2dinfo.swidtxt, Get_Value = swid
    Widget_Control, info.rpsmxtxt, Set_Value = swid[0]
    info.rpsmoothwid = fix(swid[0])
    Widget_Control, rp2dinfo.info.idp3Window, Set_UValue=info
  end

  rp2dinfo.smoothButton: begin
    Widget_Control, rp2dinfo.swidtxt, Get_Value = swid
    Widget_Control, info.rpsmxtxt, Set_Value = swid[0]
    smwidth = fix(swid[0])
    info.rpsmoothwid = smwidth
    if smwidth gt 1 then begin
      (*info.roi).rpsmooth = 1
      idp3_rpsmooth, info
      Widget_Control, rp2dinfo.info.idp3Window, Set_UValue=info
    endif else begin
      stat = Widget_Message('Smoothing Width must be greater than 1.')
    endelse
  end

  rp2dinfo.undoButton: begin
    (*info.roi).rpsmooth = 0
    info.rpsmoothwid = 1
    widstr = strtrim(string(info.rpsmoothwid),2)
    Widget_Control, info.rpsmxtxt, Set_Value = widstr
    Widget_Control, rp2dinfo.swidtxt, Set_Value = widstr
    Widget_Control, info.idp3Window, Set_UValue=info
    idp3_radprof, info
  end

  rp2dinfo.selectname: begin
    Widget_Control, rp2dinfo.selectname, Get_Value = temp
    rp2dinfo.saveiname = strtrim(temp[0],2)
  end

  rp2dinfo.selectpath: begin
    Widget_Control, rp2dinfo.selectpath, Get_Value = temp
    path = strtrim(temp[0],2)
    plen = strlen(path)
    if strmid(path, plen-1) ne info.delim then path = path + info.delim
    rp2dinfo.saveinpath = path
  end

  rp2dinfo.sButtons: begin
    Widget_Control, rp2dinfo.sButtons, Get_Value = barray
    info.srsav2idp3 = barray[0]
    info.srsav2file = barray[1]
    Widget_Control, rp2dinfo.info.idp3Window, Set_UValue=info
  end

  rp2dinfo.browseButton: begin
    pathvalue = Dialog_Pickfile(title='Please select output file path')
    ua_decompose, pathvalue, disk, path, file, extn, vers
    fpath = disk + path
    Widget_Control, rp2dinfo.selectpath, Set_Value = fpath
  end

  rp2dinfo.saveButton: begin
    Widget_Control, rp2dinfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message('Must select IDP3, File, or both for results')
      return
    endif
    info.srsav2idp3 = barray[0]
    info.srsav2file = barray[1]
    Widget_Control, rp2dinfo.selectname, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      stat = Widget_Message('Must give name for results')
      return
    endif
    rp2dinfo.saveiname = idp3name
    c = size(*info.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'RadProf 2-D: No images loaded'
      idp3_updatetxt, info, str
      return
    endif
    moveim = info.moveimage
    ims = (*info.images)
    ref = (*info.images)[moveim]
    roi = info.roi
    x1 = (*roi).roixorig
    x2 = (*roi).roixend
    y1 = (*roi).roiyorig
    y2 = (*roi).roiyend
    zoom = (*roi).roizoom
    xsize = (abs(x2-x1)+1) * zoom
    ysize = (abs(y2-y1)+1) * zoom
    tmpim = fltarr(xsize, ysize)
    xcent = (*roi).radxcent
    ycent = (*roi).radycent
    trad = (*roi).radradius
    profile = *info.radpy
    minx = xcent - trad > 0.
    maxx = xcent + trad < (xsize-1)
    miny = ycent - trad > 0
    maxy = ycent + trad < (ysize-1)
    minx = float(round(minx))
    maxx = float(round(maxx))
    miny = float(round(miny))
    maxy = float(round(maxy))

    tmpim[*,*] = 0.
    for j = miny, maxy do begin
      for i = minx, maxx do begin
	r = round(sqrt((i-xcent)^2 + (j-ycent)^2))
	if r le fix(trad-1.) then tmpim[i,j] = profile[r]
      endfor
    endfor

    if ptr_valid(info.radpfim) then ptr_free, info.radpfim
    info.radpfim = ptr_new(tmpim)

    sfits = info.sfits
    if info.srsav2file eq 1 then begin
      Widget_Control, rp2dinfo.selectpath, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if strlen(filepath) eq 0 then begin
	stat = Widget_Message('Must give path for file')
	return
      endif
      if strmid(filepath, plen-1) ne info.delim $
        then filepath = filepath + info.delim
      rp2dinfo.saveinpath = filepath
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
    final = tmpim
    if (*ref).vis eq 0 then begin
      str = 'Radprof 2-D: Reference image not ON'
      idp3_updatetxt, info, str
      return
    endif
    ; update header for all images that contributed
    imsz = size(final)
    fsz = [imsz[1],imsz[2]]
    l1 = 0
    l2 = n_elements(ims)-1
    if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
      else str = 'Flux Conserved'
    idp3_sethdr, ims, moveim, sfits, phdr, ihdr, fsz, l1, l2, str
    sxaddpar, phdr, 'ROIXORIG', x1
    sxaddpar, phdr, 'ROIYORIG', y1
    sxaddpar, phdr, 'ROIXEND', x2
    sxaddpar, phdr, 'ROIYEND', y2
    if info.zoomflux eq 0 then str = 'Flux not conserved' else $
      str = 'Flux conserved'
    sxaddpar, phdr, 'ROIZOOM', (*info.roi).roizoom, str
    if (*info.roi).msk eq 1 then begin
      str = (*info.roi).maskname + ' mask applied to data'
      sxaddpar, phdr, 'HISTORY', str
    endif
    if info.srsav2idp3 eq 1 then begin
      ; update images structure
      final_msk = intarr(imsz[1], imsz[2])
      final_msk[*,*] = 1
      newim = ptr_new({idp3im})
      idp3_setimstruct, newim, phdr, ihdr, ref, info.srsav2file
      (*newim).name = rp2dinfo.saveiname
      (*newim).orgname = rp2dinfo.saveiname
      (*newim).data = ptr_new(final)
      (*newim).mask = ptr_new(final_msk)
      (*newim).xsiz = imsz[1]
      (*newim).ysiz = imsz[2]
      (*newim).vis = 0
      c = imscale(final,10.0)
      (*newim).z1 = c[0]
      (*newim).z2 = c[1]
      tempimages = [*info.images, newim]
      ptr_free, info.images
      info.images = ptr_new(tempimages)
      Widget_Control, event.top, Set_UValue=info
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
    if info.srsav2file eq 1 then begin
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
    Widget_Control, rp2dinfo.info.idp3Window, Set_UValue=info
  end

  endcase

  Widget_Control, rp2dinfo.info.idp3Window,Get_UValue=tinfo
  rp2dinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=rp2dinfo
end

pro idp3_radprof2d, event

@idp3_structs
@idp3_errors

  if(XRegistered("radprof2d")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  sav2idp3 = info.srsav2idp3
  sav2file = info.srsav2file
  saveiname = '  '
  saveinpath = info.savepath
  Widget_Control, info.rpsmxtxt, Get_Value = strwid

  title = 'Radial Profile 2-D'
  srbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
 
  smlabel = Widget_Label(srbase, Value='Smooth Radial Profile')
  srbase1 = Widget_Base(srbase, /Row)
  swlabel = Widget_Label(srbase1, Value='No.Pixels:')
  swidtxt = Widget_Text(srbase1, Value=strwid[0], xsize=2, /Edit)
  smoothButton = Widget_Button(srbase1, Value='Smooth')
  undoButton = Widget_Button(srbase1, Value='Undo Smooth')
  srbase2 = Widget_Base(srbase, /Column)
  snames = ['IDP3    (name required)', 'File    (name and path required)']
  sButtons = cw_bgroup(srbase2, snames, column=1, uvalue='sbutton', $
      set_value=[sav2idp3,sav2file], /nonexclusive, $
      label_top='Save Results to: ')
  srbase4 = Widget_Base(srbase, /Row)
  label = Widget_Label(srbase4, Value='Name:')
  selectname = Widget_Text(srbase4, Value = saveiname, XSize = 32, /Edit)
  srbase5 = Widget_Base(srbase, /Row)
  label2 = Widget_Label(srbase5, Value='Path:')
  selectpath = Widget_Text(srbase5, Value = saveinpath, XSize = 32, /Edit)
  space2 = Widget_Label(srbase, Value = '  ')
  srbase6 = Widget_Base(srbase, /Row)
  browseButton = Widget_Button(srbase6, Value='Browse')
  saveButton = Widget_Button(srbase6, Value = 'Save')
  splab = Widget_Label(srbase6, Value='      ')
  doneButton = Widget_Button(srbase6, Value = ' Done ', $
	      Event_Pro='idp3_radprof2ddone')

  rp2dinfo = {     sButtons       :   sButtons,       $
 	           selectname     :   selectname,     $
	           browseButton   :   browseButton,   $
	           selectpath     :   selectpath,     $
	           saveButton     :   saveButton,     $
		   swidtxt        :   swidtxt,        $
		   smoothButton   :   smoothButton,   $
		   undoButton     :   undoButton,     $
	           saveiname      :   saveiname,      $
	           saveinpath     :   saveinpath,     $
	           info           :   info            }

  Widget_Control, srbase, set_uvalue = rp2dinfo
  Widget_Control, srbase, /Realize

  XManager, "radprof2d", srbase, Event_Handler = "idp3_radprof2d_ev", $
       /No_Block
          
end
