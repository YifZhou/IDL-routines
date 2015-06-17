pro idp3_saveroidone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_saveroihelp, event
  tmp = idp3_findfile('idp3_saveroi.hlp')
  xdisplayfile, tmp
end

pro idp3_saveroi_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savroiinfo
  Widget_Control, savroiinfo.info.idp3Window, GET_UValue=info

  case event.id of

  savroiinfo.selectname: begin
    Widget_Control, savroiinfo.selectname, Get_Value = temp
    savroiinfo.saveiname = strtrim(temp[0],2)
  end

  savroiinfo.fillField: begin
    Widget_Control, savroiinfo.fillField, Get_Value = fillval
    info.roifillval = fillval
    Widget_Control, savroiinfo.info.idp3Window, Set_UValue=info
  end

  savroiinfo.selectpath: begin
    Widget_Control, savroiinfo.selectpath, Get_Value = temp
    path = strtrim(temp[0],2)
    plen = strlen(path)
    if strmid(path, plen-1) ne info.delim then path = path + info.delim
    savroiinfo.saveinpath = path
  end

  savroiinfo.sButtons: begin
    Widget_Control, savroiinfo.sButtons, Get_Value = barray
    info.srsav2idp3 = barray[0]
    info.srsav2file = barray[1]
  end

  savroiinfo.tButtons: begin
    Widget_Control, savroiinfo.tButtons, Get_Value = barray
    savroiinfo.srsavdata = barray[0]
  end

  savroiinfo.oButtons: begin
    Widget_Control, savroiinfo.oButtons, Get_Value = barray
    savroiinfo.sroiorig = barray[0]
  end

  savroiinfo.browseButton: begin
    pathvalue = Dialog_Pickfile(title='Please select output file path')
    ua_decompose, pathvalue, disk, path, file, extn, vers
    fpath = disk + path
    Widget_Control, savroiinfo.selectpath, Set_Value = fpath
  end

  savroiinfo.saveButton: begin
    Widget_Control, savroiinfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message('Must select IDP3, File, or both for results')
      return
    endif
    info.srsav2idp3 = barray[0]
    info.srsav2file = barray[1]
    Widget_Control, savroiinfo.tButtons, Get_Value = barray
    savroiinfo.srsavdata = barray[0]
    Widget_Control, savroiinfo.fillField, Get_Value = fillval
    Widget_Control, savroiinfo.selectname, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      stat = Widget_Message('Must give name for results')
      return
    endif
    savroiinfo.saveiname = idp3name
    c = size(*info.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'SaveROI: No images loaded'
      idp3_updatetxt, info, str
      return
    endif
    moveim = info.moveimage
    ims = (*info.images)
    ref = (*info.images)[moveim]
    maxx = info.maxxpoint
    maxy = info.maxypoint
    sfits = info.sfits
    x1 = (*info.roi).roixorig
    x2 = (*info.roi).roixend
    y1 = (*info.roi).roiyorig
    y2 = (*info.roi).roiyend
    if info.srsav2file eq 1 then begin
      Widget_Control, savroiinfo.selectpath, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if strlen(filepath) eq 0 then begin
	stat = Widget_Message('Must give path for file')
	return
      endif
      if strmid(filepath, plen-1) ne info.delim $
        then filepath = filepath + info.delim
      savroiinfo.saveinpath = filepath
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
    zoom = (*info.roi).roizoom
    xsiz = (x2 - x1 + 1) * zoom
    ysiz = (y2 - y1 + 1) * zoom
    ztype = info.roiioz
    pixorg = info.pixorg
    if savroiinfo.srsavdata eq 0 then begin
      roi = (*info.dispim)[x1:x2,y1:y2]
      ralph = (*info.alphaim)[x1:x2,y1:y2]
      if zoom gt 1 then begin
	ndat = idp3_congrid(roi,xsiz,ysiz,zoom,ztype,pixorg)
	nalph = idp3_congrid(ralph,xsiz,ysiz,zoom,ztype,pixorg)
      endif else begin
	ndat = roi
	nalph = ralph
      endelse
      roi = 0
      ralph = 0
      if savroiinfo.sroiorig eq 1 then begin
	rmaxx = max([maxx, xsiz + xsiz-1])
	rmaxy = max([maxy, ysiz + ysiz-1])
	final = fltarr(rmaxx,rmaxy)
	final[*,*] = fillval
	final[x1:x1+xsiz-1, y1:y1+ysiz-1] = ndat
	alpha = fltarr(rmaxx, rmaxy)
	alpha[*,*] = 0.
	alpha[x1:x1+xsiz-1,y1:y1+ysiz-1] = nalph
      endif else begin
	final = ndat
	alpha = nalph
      endelse
      ; update header for all images that contributed
      imsz = size(final)
      fsz = [imsz[1],imsz[2]]
      l1 = 0
      l2 = n_elements(ims)-1
      if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	else str = 'Flux Conserved'
      idp3_sethdr, ims, moveim, sfits, phdr, ihdr, fsz, l1, l2, str
      sxaddpar, phdr, 'ROIXORIG', x1
      sxaddpar, phdr, 'ROIXEND', x2
      sxaddpar, phdr, 'ROIYORIG', y1
      sxaddpar, phdr, 'ROIYEND', y2
      if zoom ne 1 then begin
	if info.zoomflux eq 0 then str = 'Flux not conserved' else $
	  str = 'Flux conserved'
        sxaddpar, phdr, 'ROIZOOM', zoom, str
      endif
      rotcx = sxpar(phdr, 'ROTCX')
      rotcy = sxpar(phdr, 'ROTCY')
      if savroiinfo.sroiorig eq 0 then begin
	rotcx = rotcx - x1
	rotcy = rotcy - y1
      endif
      rotcx = rotcx * (*info.roi).roizoom
      rotcy = rotcy * (*info.roi).roizoom
      sxaddpar, phdr, 'ROTCX', rotcx
      sxaddpar, phdr, 'ROTCY', rotcy
      if info.srsav2idp3 eq 1 then begin
        ; update images structure
        final_msk = intarr(imsz[1], imsz[2])
        final_msk[*,*] = 1
        b = where(alpha eq 0., bcnt)
        if bcnt gt 0 then final_msk[b] = 0
        newim = ptr_new({idp3im})
        idp3_setimstruct, newim, phdr, ihdr, ref, info.srsav2file
        (*newim).name = savroiinfo.saveiname
        (*newim).orgname = savroiinfo.saveiname
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
      Widget_Control, savroiinfo.info.idp3Window, Set_UValue=info
    endif else begin
      if info.srsav2file eq 1 then begin
        filename = filepath + idp3name
        ua_decompose, filename, disk, path, name, extn, vers
      endif
      if info.srsav2idp3 eq 1 then ua_decompose, idp3name, idisk, $
            ipath, iname, iextn, ivers
      outim = fltarr(maxx,maxy)
      outalpha = fltarr(maxx, maxy)
      indx = 0
      numon = n_elements(ims)
      for i = 0, numon-1 do begin
	if (*ims[i]).vis eq 1 then begin
	  indx = indx + 1
	  mdst = idp3_setdata (info, i)
	  mds = mdst[*,*,0]
	  alph = mdst[*,*,1]
	  ; check boundaries
	  imc = *ims[i]
	  xoff = imc.xoff
	  yoff = imc.yoff
	  oxsiz = (imc.xsiz + 2 * imc.pad) * imc.zoom * imc.xpscl
	  oysiz = (imc.ysiz + 2 * imc.pad) * imc.zoom * imc.ypscl
	  idp3_checkbounds,maxx,maxy,oxsiz,oysiz,xoff,yoff,dxmin,dxmax,$
		dymin,dymax,gxmin,gxmax,gymin,gymax,err
          outbound = 0
	  if err eq -1 then begin
	    str = 'SaveROI:  X offset out of bounds'
	    idp3_updatetxt, info, str
	    outbound = 1
          endif
	  if err eq -2 then begin
	    str = 'SaveROI:  Y offset out of bounds'
	    idp3_updatetxt, info, str
	    outbound = 2
          endif
	  if outbound eq 0 then begin
	    outim[*,*] = 0.
	    outalpha[*,*] = 0.
	    outim[gxmin:gxmax,gymin:gymax] = mds[dxmin:dxmax,dymin:dymax]
	    outalpha[gxmin:gxmax,gymin:gymax] = mds[dxmin:dxmax,dymin:dymax]
	    roi = outim[x1:x2,y1:y2]
	    ralph = outalpha[x1:x2,y1:y2]
	    if zoom gt 1 then begin
	      ndat = idp3_congrid(roi,xsiz,ysiz,zoom,ztype,pixorg)
	      nalph = idp3_congrid(ralph,xsiz,ysiz,zoom,ztype,pixorg)
            endif else begin
	      ndat = roi
	      nalph = ralph
            endelse
	    roi = 0
	    ralph = 0
	    if savroiinfo.sroiorig eq 1 then begin
	      rmaxx = max([maxx, x1 + xsiz-1])
	      rmaxy = max([maxy, y1 + ysiz-1])
	      final = fltarr(rmaxx,rmaxy)
	      final[x1:x1+xsiz-1, y1:y1+ysiz-1] = ndat
	      alpha = fltarr(rmaxx, rmaxy)
	      alpha[*,*] = 0.
	      alpha[x1:x1+xsiz-1,y1:y1+ysiz-1] = nalph
            endif else begin
	      final = ndat
	      alpha = nalph
            endelse
	    ndat = 0
	    nalph = 0
	    imsz = size(final)
	    dsz=[imsz[1],imsz[2]]
	    lim1 = i
	    lim2 = i
	    if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	      else str = 'Flux Conserved'
	    idp3_sethdr, ims, i, sfits, phdr, ihdr, dsz, lim1, lim2, str
	    sxaddpar, phdr, 'ROIXORIG', x1
	    sxaddpar, phdr, 'ROIXEND', x2
	    sxaddpar, phdr, 'ROIYORIG', y1
	    sxaddpar, phdr, 'ROIYEND', y2
	    if zoom ne 1 then begin
	      if info.zoomflux eq 0 then str = 'Flux not conserved' else $
		  str = 'Flux conserved'
              sxaddpar, phdr, 'ROIZOOM', zoom, str
            endif
            rotcx = sxpar(phdr, 'ROTCX')
            rotcy = sxpar(phdr, 'ROTCY')
            if savroiinfo.sroiorig eq 0 then begin
	      rotcx = rotcx - x1
	      rotcy = rotcy - y1
            endif
            rotcx = rotcx * (*info.roi).roizoom
            rotcy = rotcy * (*info.roi).roizoom
            sxaddpar, phdr, 'ROTCX', rotcx
            sxaddpar, phdr, 'ROTCY', rotcy
	    sindx = setnum(indx, numon, 1)
	    if info.srsav2idp3 eq 1 then begin
	      fname = iname + sindx + iextn
	      ; update images structure
	      final_msk = intarr(imsz[1], imsz[2])
	      final_msk[*,*] = 1
	      bad = where(alpha eq 0., cnt)
	      if cnt gt 0 then final_msk[bad] = 0
              newim = ptr_new({idp3im})
              idp3_setimstruct, newim, phdr, ihdr, ref, info.srsav2file
              (*newim).name = fname
              (*newim).orgname = fname
              (*newim).data = ptr_new(final)
              (*newim).mask = ptr_new(final_msk)
              (*newim).xsiz = imsz[1]
              (*newim).ysiz = imsz[2]
              (*newim).vis = 0
              c = imscale(outim,10.0)
              (*newim).z1 = c[0]
              (*newim).z2 = c[1]
              tempimages = [*info.images, newim]
              ptr_free, info.images
              info.images = ptr_new(tempimages)
	      Widget_Control, event.top, Set_UValue=info
            endif 
            if info.srsav2file eq 1 then begin
	      fname = disk + path + name + sindx + extn
              if strlen(extn) eq 0 then fname = fname + '.fits'
              temp = file_search (fname, Count = fcount)
              if fcount gt 0 then begin
	        idp3_selectval, event.top, $
	            'Do you wish to overwrite existing file?',$
	            ['no','yes'], val
                if val eq 0 then return
              endif 
	      ua_fits_open, fname, fcb, /Write
	      if n_elements(ihdr) le 2 then begin
	        ua_fits_write, fcb, final, phdr, /noextend
              endif else begin
	        ua_fits_write, fcb, 0, phdr
	        ua_fits_write, fcb, final, ihdr, extname='SCI', extver=1
              endelse
	      ua_fits_close, fcb
            endif
            Widget_Control, savroiinfo.info.idp3Window, Set_UValue=info
          endif
        endif
      endfor
      if info.srsav2idp3 eq 1 then begin
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
    endelse
  end

  endcase

  Widget_Control,savroiinfo.info.idp3Window,Get_UValue=tinfo
  savroiinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=savroiinfo
end

pro idp3_saveroi, event

@idp3_structs
@idp3_errors

  if(XRegistered("idp3_saveroi")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  sav2idp3 = info.srsav2idp3
  sav2file = info.srsav2file
  saveiname = '  '
  saveinpath = info.savepath
  srsavdata = 0
  sroiorig = 0
  roifillval = info.roifillval
  x1 = (*info.roi).roixorig
  y1 = (*info.roi).roiyorig
  lowleft = 'Lower Left Corner (0,0)'
  ROIleft = 'ROI Origin (' + strtrim(string(x1),2) + ',' + $
	      strtrim(string(y1),2) + ')'

  title = 'IDP3 Save ROI'
  srbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
  
  srbase1 = Widget_Base (srbase, /Column)
  tnames = ['Current ROI', 'Individual Images of ROI'] 
  tButtons = cw_bgroup(srbase1, tnames, column = 1, uvalue='tbutton', $
     set_value=srsavdata, /exclusive, /no_release, $
     label_top='Save Data in ROI')
  srbase8 = Widget_Base(srbase, /Column)
  snames = ['IDP3    (name required)', 'File    (name and path required)']
  sButtons = cw_bgroup(srbase8, snames, column=1, uvalue='sbutton', $
      set_value=[sav2idp3,sav2file], /nonexclusive, $
      label_top='Save Results to: ')
  srbase4 = Widget_Base(srbase, /Column)
  onames = [lowleft, ROIleft]
  oButtons = cw_bgroup(srbase4, onames, column=1, uvalue='obutton', $
      set_value=sroiorig, /exclusive, /no_release, $
      label_top='Place ROI Origin at')
  fillField = cw_Field(srbase, value=roifillval, title='Fill Value: ', $
	      uvalue='rfill', xsize=6, /Return_Events, /Floating)
  srbase7 = Widget_Base(srbase, /Row)
  label = Widget_Label(srbase7, Value='Name:')
  selectname = Widget_Text(srbase7, Value = saveiname, XSize = 32, /Edit)
  srbase6 = Widget_Base(srbase, /Row)
  label2 = Widget_Label(srbase6, Value='Path:')
  selectpath = Widget_Text(srbase6, Value = saveinpath, XSize = 32, /Edit)
  space2 = Widget_Label(srbase, Value = '  ')
  srbase5 = Widget_Base(srbase, /Row)
  browseButton = Widget_Button(srbase5, Value='Browse for Path')
  saveButton = Widget_Button(srbase5, Value = ' Save ')
  helpButton = Widget_Button(srbase5, Value = ' Help ', $
	      Event_Pro = 'idp3_saveroihelp')
  doneButton = Widget_Button(srbase5, Value = ' Done ', $
	      Event_Pro='idp3_saveroidone')

  savroiinfo = { sButtons       :   sButtons,       $
	         selectname     :   selectname,     $
	         tButtons       :   tButtons,       $
		 oButtons       :   oButtons,       $
		 fillField      :   fillField,      $
	         browseButton   :   browseButton,   $
	         selectpath     :   selectpath,     $
	         saveButton     :   saveButton,     $
	         saveiname      :   saveiname,      $
	         saveinpath     :   saveinpath,     $
	         srsavdata      :   srsavdata,      $
		 sroiorig       :   sroiorig,       $
	         info           :   info            }

  Widget_Control, srbase, set_uvalue = savroiinfo
  Widget_Control, srbase, /Realize

  XManager, "idp3_saveroi", srbase, Event_Handler = "idp3_saveroi_ev", $
       /No_Block
end
