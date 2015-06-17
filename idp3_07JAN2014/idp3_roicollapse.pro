pro roi_collapse, info, newroi
@idp3_errors

  numon = 0
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    m = (*info.images)[i]
    if (*m).vis eq 1 then numon = numon+1
  endfor
  roi = *info.roi
  if numon gt 0 then begin
    x1 = roi.roixorig
    y1 = roi.roiyorig
    x2 = roi.roixend
    y2 = roi.roiyend
    zoom = roi.roizoom
    xsize = (abs(x2-x1)+1) * zoom
    ysize = (abs(y2-y1)+1) * zoom
    ztype = info.roiioz
    pixrep = 2
    talph = (*info.alphaim)[x1:x2,y1:y2]
    talph[*,*] = 1.
    bad = where((*info.alphaim)[x1:x2,y1:y2] eq 0., bcnt)
    if bcnt gt 0 then talph[bad] = 0.
    if info.exclude_invalid gt 0 then begin
      bad2 = where((*info.dispim)[x1:x2,y1:y2] eq info.invalid, b2cnt)
      if b2cnt gt 0 then talph[bad2] = 0.
    endif
    tiim = idp3_congrid((*info.dispim)[x1:x2,y1:y2], xsize, ysize, $
      zoom, ztype, info.pixorg)
    alpha = idp3_congrid(talph, xsize, ysize, zoom, ztype, info.pixorg)
    idp3_checktol, alpha, info.masktol
    bad = where(alpha eq 0., bcount)
    goodval = roi.maskgood
    if roi.msk eq 1 then begin
      tmpmask = *((*info.roi).mask)
      xoff = roi.msk_xoff
      yoff = roi.msk_yoff
      mask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
      roimask = congrid(mask, xsize, ysize)
    endif else begin
      roimask = intarr(xsize,ysize)
      roimask[*,*] = goodval
    endelse
    bd = where(alpha eq 0, count)
    if goodval eq 0 then mskval = 1 else mskval = 0
    if count gt 0 then roimask[bd] = mskval
    newroi = fltarr(xsize, ysize)
    val = roi.collapse_type + roi.collapse_dir * 2
    Case val of
    0: begin   ; row median
      for i = 0, xsize-1 do begin
	good = where(roimask[i,*] eq goodval, count)
	row = tiim[i,*]
	if count gt 0 then newroi[i,*] = median(row[good], /even) $
	  else newroi[i,*] = 0.
      endfor
      end
    1: begin   ; row mean
      for i = 0, xsize-1 do begin
	good = where(roimask[i,*] eq goodval, count)
	row = tiim[i,*]
	if count gt 0 then newroi[i,*] = mean(row[good]) $
	  else newroi[i,*] = 0.
      endfor
      end
    2: begin   ; column median
      for j = 0, ysize-1 do begin
	good = where(roimask[*,j] eq goodval, count)
	col = tiim[*,j]
	if count gt 0 then newroi[*,j] = median(col[good], /even) $
	  else newroi[i,*] = 0.
      endfor
      end
    3: begin
      for j = 0, ysize-1 do begin
	good = where(roimask[*,j] eq goodval, count)
	col = tiim[*,j]
	if count gt 0 then newroi[*,j] = mean(col[good]) $
	  else newroi[i,*] = 0.
      endfor
      end
    endcase
    tiim = 0
  endif else newroi = 0
end

pro idp3_roicollapsedone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_roicollapse_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=collapseinfo
  Widget_Control, collapseinfo.info.idp3Window, GET_UValue=info

  case event.id of

  collapseinfo.selectname: begin
    Widget_Control, collapseinfo.selectname, Get_Value = temp
    collapseinfo.saveiname = strtrim(temp[0],2)
  end

  collapseinfo.selectpath: begin
    Widget_Control, collapseinfo.selectpath, Get_Value = temp
    path = strtrim(temp[0],2)
    plen = strlen(path)
    if strmid(path, plen-1) ne info.delim then path = path + info.delim
    collapseinfo.saveinpath = path
  end

  collapseinfo.sButtons: begin
    Widget_Control, collapseinfo.sButtons, Get_Value = barray
    info.srsav2idp3 = barray[0]
    info.srsav2file = barray[1]
    Widget_Control, collapseinfo.info.idp3Window, Set_UValue=info
  end

  collapseinfo.ynButtons: begin
    Widget_Control, collapseinfo.ynButtons, Get_Value = barray
    info.roifillarr = barray[0]
    Widget_Control, collapseinfo.info.idp3Window, Set_UValue=info
  end

  collapseinfo.tButtons: begin
    Widget_Control, collapseinfo.tButtons, Get_Value = barray
    case barray[0] of
    0: begin
      (*info.roi).collapse_type = 0
      (*info.roi).collapse_dir = 0
      fillstr = '   Fill Y-Axis: '
      end
    1: begin
      (*info.roi).collapse_type = 1
      (*info.roi).collapse_dir = 0
      fillstr = '   Fill Y-Axis: '
      end
    2: begin
      (*info.roi).collapse_type = 0
      (*info.roi).collapse_dir = 1
      fillstr = '   Fill X-Axis: '
      end
    3: begin
      (*info.roi).collapse_type = 1
      (*info.roi).collapse_dir = 1
      fillstr = '   Fill X-Axis: '
      end
    else: fillstr = '  '
    endcase
    Widget_Control, collapseinfo.fillabel, Set_Value=fillstr
    Widget_Control, collapseinfo.info.idp3Window, Set_UValue=info
  end

  collapseinfo.browseButton: begin
    pathvalue = Dialog_Pickfile(title='Please select output file path')
    ua_decompose, pathvalue, disk, path, file, extn, vers
    fpath = disk + path
    Widget_Control, collapseinfo.selectpath, Set_Value = fpath
  end

  collapseinfo.computeButton: begin
    Widget_Control, collapseinfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message('Must select IDP3, File, or both for results')
      return
    endif
    info.srsav2idp3 = barray[0]
    info.srsav2file = barray[1]
    Widget_Control, collapseinfo.tButtons, Get_Value = barray
    case barray[0] of
    0: begin
      (*info.roi).collapse_type = 0
      (*info.roi).collapse_dir = 0
      fillstr = '   Fill Y-Axis: '
      end
    1: begin
      (*info.roi).collapse_type = 1
      (*info.roi).collapse_dir = 0
      fillstr = '   Fill Y-Axis: '
      end
    2: begin
      (*info.roi).collapse_type = 0
      (*info.roi).collapse_dir = 1
      fillstr = '   Fill X-Axis: '
      end
    3: begin
      (*info.roi).collapse_type = 1
      (*info.roi).collapse_dir = 1
      fillstr = '   Fill X-Axis: '
      end
    else: fillstr = '  '
    endcase
    Widget_Control, collapseinfo.fillabel, Set_Value=fillstr
    Widget_Control, collapseinfo.ynButtons, Get_Value = barray
    fillarr = barray[0]
    info.roifillarr = fillarr
    Widget_Control, collapseinfo.selectname, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      stat = Widget_Message('Must give name for results')
      return
    endif
    collapseinfo.saveiname = idp3name
    c = size(*info.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'ROICollapse: No images loaded'
      idp3_updatetxt, info, str
      return
    endif
    moveim = info.moveimage
    ims = (*info.images)
    ref = (*info.images)[moveim]
    x1 = (*info.roi).roixorig
    x2 = (*info.roi).roixend
    y1 = (*info.roi).roiyorig
    y2 = (*info.roi).roiyend
    roi_collapse, info, tempim
    if n_elements(tempim) le 2 then begin
      stat = Widget_Message('No collapsed ROI to save')
      return
    end
    if fillarr eq 1 then begin
      osz = size(tempim)
      dir = (*info.roi).collapse_dir
      if dir eq 0 then begin
	y1 = 0
	y2 = (*ref).ysiz-1
	final = fltarr(osz[1], y2+1)
	for i = 0, osz[1]-1 do begin
	  final[i,*] = tempim[i,0]
        endfor
      endif else begin
	x1 = 0
	x2 = (*ref).xsiz-1
	final = fltarr(x2+1,osz[2])
	for i = 0, osz[2]-1 do begin
	  final[*,i] = tempim[0,i]
        endfor
      endelse
    endif else final = tempim
    if ptr_valid(info.rcollapsim) then ptr_free, info.rcollapsim
    info.rcollapsim = ptr_new(final)
    sfits = info.sfits
    if info.srsav2file eq 1 then begin
      Widget_Control, collapseinfo.selectpath, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if strlen(filepath) eq 0 then begin
	stat = Widget_Message('Must give path for file')
	return
      endif
      if strmid(filepath, plen-1) ne info.delim $
        then filepath = filepath + info.delim
      collapseinfo.saveinpath = filepath
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
    if (*ref).vis eq 0 then begin
      str = 'ROICollapse: Reference image not ON'
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
    if (*info.roi).collapse_dir eq 0 then str = 'Row ' else str = 'Column '
    if (*info.roi).collapse_type eq 0 then str = str + 'Median 1D Image' $
       else str = str + 'Mean 1D Image'
    sxaddpar, phdr, 'HISTORY', str
    if info.srsav2idp3 eq 1 then begin
      ; update images structure
      final_msk = intarr(imsz[1], imsz[2])
      final_msk[*,*] = 1
      newim = ptr_new({idp3im})
      idp3_setimstruct, newim, phdr, ihdr, ref, info.srsav2file
      (*newim).name = collapseinfo.saveiname
      (*newim).orgname = collapseinfo.saveiname
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
    Widget_Control, collapseinfo.info.idp3Window, Set_UValue=info
  end

  collapseinfo.helpButton: begin
    tmp = idp3_findfile('idp3_roicollapse.hlp')
    xdisplayfile, tmp
  end

  endcase

  Widget_Control, collapseinfo.info.idp3Window,Get_UValue=tinfo
  collapseinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=collapseinfo
end

pro idp3_roicollapse, event

@idp3_structs
@idp3_errors

  if(XRegistered("roi_collapse")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  sav2idp3 = info.srsav2idp3
  sav2file = info.srsav2file
  saveiname = '  '
  saveinpath = info.savepath
  colap_type = (*info.roi).collapse_type
  colap_dir = (*info.roi).collapse_dir
  collapse = colap_type + colap_dir * 2
  fillarr = info.roifillarr

  if colap_dir eq 0 then fillstr = '   Fill Y-Axis: ' $
      else fillstr = '   Fill X-Axis: '

  title = 'ROI 1D Collapse'
  srbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
  
  srbase1 = Widget_Base (srbase, /Column)
  tnames = ['ROW Median', 'ROW Mean', 'COLUMN Median', 'COLUMN Mean'] 
  tButtons = cw_bgroup(srbase1, tnames, column = 1, uvalue='tbutton', $
     set_value=collapse, /exclusive, /no_release, $
     label_top='Compute ROI 1-D Collapse')
  srbase2 = Widget_Base(srbase, /Column)
  snames = ['IDP3    (name required)', 'File    (name and path required)']
  sButtons = cw_bgroup(srbase2, snames, column=1, uvalue='sbutton', $
      set_value=[sav2idp3,sav2file], /nonexclusive, $
      label_top='Save Results to: ')
  srbase3 = Widget_Base(srbase, /Row)
  fillabel = Widget_Label(srbase3, Value=fillstr)
  ynnames = ['No', 'Yes']
  ynButtons = cw_bgroup(srbase3, ynnames, row=1, uvalue='ynbutton', $
      set_value=fillarr, /exclusive, /no_release)
  srbase4 = Widget_Base(srbase, /Row)
  label = Widget_Label(srbase4, Value='Name:')
  selectname = Widget_Text(srbase4, Value = saveiname, XSize = 32, /Edit)
  srbase5 = Widget_Base(srbase, /Row)
  label2 = Widget_Label(srbase5, Value='Path:')
  selectpath = Widget_Text(srbase5, Value = saveinpath, XSize = 32, /Edit)
  space2 = Widget_Label(srbase, Value = '  ')
  srbase6 = Widget_Base(srbase, /Row)
  browseButton = Widget_Button(srbase6, Value='Browse')
  computeButton = Widget_Button(srbase6, Value = 'Compute')
  splab = Widget_Label(srbase6, Value='      ')
  helpButton = Widget_Button(srbase6, Value='Help')
  doneButton = Widget_Button(srbase6, Value = ' Done ', $
	      Event_Pro='idp3_roicollapsedone')

  collapseinfo = { sButtons       :   sButtons,       $
 	           selectname     :   selectname,     $
	           tButtons       :   tButtons,       $
	           browseButton   :   browseButton,   $
	           selectpath     :   selectpath,     $
	           computeButton  :   computeButton,  $
		   helpButton     :   helpButton,     $
		   fillabel       :   fillabel,       $
		   ynButtons      :   ynButtons,      $
	           saveiname      :   saveiname,      $
	           saveinpath     :   saveinpath,     $
	           info           :   info            }

  Widget_Control, srbase, set_uvalue = collapseinfo
  Widget_Control, srbase, /Realize

  XManager, "roi_collapse", srbase, Event_Handler = "idp3_roicollapse_ev", $
       /No_Block
          
end
