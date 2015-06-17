pro idp3_savemaindone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_savemain_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=savmaininfo
  Widget_Control, savmaininfo.info.idp3Window, GET_UValue=info

  case event.id of

  savmaininfo.selectname: begin
    Widget_Control, savmaininfo.selectname, Get_Value = temp
    savmaininfo.saveiname = strtrim(temp[0],2)
  end

  savmaininfo.selectpath: begin
    Widget_Control, savmaininfo.selectpath, Get_Value = temp
    path = strtrim(temp[0],2)
    plen = strlen(path)
    if strmid(path, plen-1) ne info.delim then path = path + info.delim
    savmaininfo.saveinpath = path
  end

  savmaininfo.sButtons: begin
    Widget_Control, savmaininfo.sButtons, Get_Value = barray
    info.smsav2idp3 = barray[0]
    info.smsav2file = barray[1]
  end

  savmaininfo.tButtons: begin
    Widget_Control, savmaininfo.tButtons, Get_Value = barray
    savmaininfo.smsavdata = barray[0]
  end

  savmaininfo.browseButton: begin
    pathvalue = Dialog_Pickfile(title='Please select output file path')
    ua_decompose, pathvalue, disk, path, file, extn, vers
    fpath = disk + path
    Widget_Control, savmaininfo.selectpath, Set_Value = fpath
  end

  savmaininfo.saveButton: begin
    Widget_Control, savmaininfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message('Must select IDP3, File, or both for results')
      return
    endif
    info.smsav2idp3 = barray[0]
    info.smsav2file = barray[1]
    Widget_Control, savmaininfo.tButtons, Get_Value = barray
    savmaininfo.smsavdata = barray[0]
    Widget_Control, savmaininfo.selectname, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      stat = Widget_Message('Must give name for results')
      return
    endif
    savmaininfo.saveiname = idp3name
    c = size(*info.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'SaveMain: No images loaded'
      idp3_updatetxt, info, str
      return
    endif
    moveim = info.moveimage
    ims = (*info.images)
    ref = ims[moveim]
    maxx = info.maxxpoint
    maxy = info.maxypoint
    sfits = info.sfits
    if info.smsav2file eq 1 then begin
      Widget_Control, savmaininfo.selectpath, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if strlen(filepath) eq 0 then begin
	stat = Widget_Message('Must give path for file')
	return
      endif
      if strmid(filepath, plen-1) ne info.delim $
        then filepath = filepath + info.delim
      savmaininfo.saveinpath = filepath
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
    if savmaininfo.smsavdata eq 0 then begin
      final = (*info.dispim)[0:maxx-1,0:maxy-1]
      alpha = (*info.alphaim)[0:maxx-1,0:maxy-1]
      ; update header for all images that contributed
      imsz = size(final)
      fsz = [imsz[1],imsz[2]]
      l1 = 0
      l2 = n_elements(ims)-1
      if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	else str = 'Flux Conserved'
      idp3_sethdr, ims, moveim, sfits, phdr, ihdr, fsz, l1, l2, str
      if info.smsav2idp3 eq 1 then begin
        ; update images structure
        final_msk = intarr(imsz[1], imsz[2])
        final_msk[*,*] = 1
        b = where(alpha eq 0., bcnt)
        if bcnt gt 0 then final_msk[b] = 0
        newim = ptr_new({idp3im})
        idp3_setimstruct, newim, phdr, ihdr, ref, info.smsav2file
        (*newim).name = savmaininfo.saveiname
        (*newim).orgname = savmaininfo.saveiname
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
      if info.smsav2file eq 1 then begin
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
    endif else begin
      if info.smsav2file eq 1 then begin
        filename = filepath + idp3name
        ua_decompose, filename, disk, path, name, extn, vers
      endif
      if info.smsav2idp3 eq 1 then $
        ua_decompose, idp3name, idisk, ipath, iname, iextn, ivers
      outim = fltarr(maxx,maxy)
      outalpha = fltarr(maxx, maxy)
      outmask = intarr(maxx, maxy)
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
	  xsiz = (imc.xsiz + 2 * imc.pad) * imc.zoom * imc.xpscl
	  ysiz = (imc.ysiz + 2 * imc.pad) * imc.zoom * imc.ypscl
	  idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax,$
		dymin,dymax,gxmin,gxmax,gymin,gymax,err
          outbound = 0
	  if err eq -1 then begin
	    str = 'SaveMain:  X offset out of bounds'
	    idp3_updatetxt, info, str
	    outbound = 1
          endif
	  if err eq -2 then begin
	    str = 'SaveMain:  Y offset out of bounds'
	    idp3_updatetxt, info, str
	    outbound = 2
          endif
	  if outbound eq 0 then begin
	    outim[*,*] = 0.
	    outalpha[*,*] = 0.
	    outim[gxmin:gxmax,gymin:gymax] = mds[dxmin:dxmax,dymin:dymax]
	    outalpha[gxmin:gxmax,gymin:gymax] = mds[dxmin:dxmax,dymin:dymax]
	    imsz = size(outim)
	    dsz=[imsz[1],imsz[2]]
	    lim1 = i
	    lim2 = i
	    phead = *imc.phead
	    ihead = *imc.ihead
	    if info.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	      else str = 'Flux Conserved'
	    idp3_sethdr, ims, i, sfits, phead, ihead, dsz, lim1, lim2, str
	    sindx = setnum(indx, numon, 1)
	    if info.smsav2idp3 eq 1 then begin
	      fname = iname + sindx + iextn
	      ; update images structure
	      outmask[*,*] = 1
	      bad = where(outalpha eq 0., cnt)
	      if cnt gt 0 then outmask[bad] = 0
              newim = ptr_new({idp3im})
              idp3_setimstruct, newim, phead, ihead, ref, info.smsav2file
              (*newim).name = fname
              (*newim).orgname = fname
              (*newim).data = ptr_new(outim)
              (*newim).mask = ptr_new(outmask)
              (*newim).xsiz = imsz[1]
              (*newim).ysiz = imsz[2]
              (*newim).vis = 0
              c = imscale(outim,10.0)
              (*newim).z1 = c[0]
              (*newim).z2 = c[1]
              tempimages = [*info.images, newim]
              ptr_free, info.images
              info.images = ptr_new(tempimages)
	      Widget_Control, info.idp3Window, Set_UValue=info
            endif 
            if info.smsav2file eq 1 then begin
	      fname = disk + path + name + sindx + extn
              if strlen(extn) eq 0 then fname = fname + '.fits'
              temp = file_search (fname, Count = fcount)
              if fcount gt 0 then begin
	        idp3_selectval,event.top,'Do you wish to overwrite existing file?',$
	          ['no','yes'], val
                if val eq 0 then return
              endif 
	      ua_fits_open, fname, fcb, /Write
	      if n_elements(ihead) le 2 then begin
	        ua_fits_write, fcb, outim, phead, /noextend
              endif else begin
	        ua_fits_write, fcb, 0, phead
	        ua_fits_write, fcb, outim, ihead, extname='SCI', extver=1
              endelse
	      ua_fits_close, fcb
            endif
          endif
        endif
      endfor
      if info.smsav2idp3 eq 1 then begin
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

  Widget_Control,savmaininfo.info.idp3Window,Get_UValue=tinfo
  savmaininfo.info = tinfo
  Widget_Control, event.top, Set_UValue=savmaininfo
end

pro idp3_savemain, event

@idp3_structs
@idp3_errors

  if(XRegistered("idp3_savemain")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  sav2idp3 = info.smsav2idp3
  sav2file = info.smsav2file
  saveiname = '  '
  saveinpath = info.savepath
  smsavdata = 0

  title = 'IDP3 Save Display'
  smbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
  
  smbase1 = Widget_Base (smbase, /Column)
  tnames = ['Current Display', 'Individual Images'] 
  tButtons = cw_bgroup(smbase1, tnames, column = 1, uvalue='tbutton', $
     set_value=smsavdata, /exclusive, /no_release, $
     label_top='Save Data in Main Display')
  smbase8 = Widget_Base(smbase, /Column)
  snames = ['IDP3    (name required)', 'File    (name and path required)']
  sButtons = cw_bgroup(smbase8, snames, column=1, uvalue='sbutton', $
      set_value=[sav2idp3,sav2file], /nonexclusive, $
      label_top='Save Results to: ')
  smbase7 = Widget_Base(smbase, /Row)
  label = Widget_Label(smbase7, Value='Name:')
  selectname = Widget_Text(smbase7, Value = saveiname, XSize = 32, /Edit)
  smbase6 = Widget_Base(smbase, /Row)
  label2 = Widget_Label(smbase6, Value='Path:')
  selectpath = Widget_Text(smbase6, Value = saveinpath, XSize = 32, /Edit)
  space2 = Widget_Label(smbase, Value = '  ')
  smbase5 = Widget_Base(smbase, /Row)
  browseButton = Widget_Button(smbase5, Value='Browse for Path')
  saveButton = Widget_Button(smbase5, Value = ' Save ')
  doneButton = Widget_Button(smbase5, Value = ' Done ', $
	      Event_Pro='idp3_savemaindone')

  savmaininfo = { sButtons       :   sButtons,       $
	          selectname     :   selectname,     $
	          tButtons       :   tButtons,       $
	          browseButton   :   browseButton,   $
	          selectpath     :   selectpath,     $
	          saveButton     :   saveButton,     $
	          saveiname      :   saveiname,      $
	          saveinpath     :   saveinpath,     $
		  smsavdata      :   smsavdata,      $
	          info           :   info            }

  Widget_Control, smbase, set_uvalue = savmaininfo
  Widget_Control, smbase, /Realize

  XManager, "idp3_savemain", smbase, Event_Handler = "idp3_savemain_ev", $
       /No_Block
          
end
