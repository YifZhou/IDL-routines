pro idp3_pct, info, totx, toty, rown
  ; calculate what percentage of image is completed
  npix = float(totx) * float(toty)
  don = float(rown+1) * float(totx)
  pct = (don / npix) * 100.
  str = 'IMCOMBINE: Row: ' + string(rown, '$(i5)') + ' completed  ' + $
      string(pct,'$(f7.3)') + ' percent done.'
  idp3_updatetxt, info, str
end

function csig, array, good, final, sdev
  acount = n_elements(array)
  gcount = n_elements(good)
  nsig = fltarr(acount)
  nsig[*] = 0.
  gmax = max(good)
  if gcount gt 1 and acount gt gmax then begin
    for i = 0, gcount-1 do begin
      ipix = good[i]
      nsig[ipix] = (array[ipix] - final) / sdev
    endfor
  endif
  return, nsig
end

function idp3_combinemm, info, phdr, final, stev, nsigma, npix, costr     
@idp3_structs
@idp3_errors

    cstr = [' Mean combined ', ' Median combined ', $
	    ' Sigma Clipped Mean combined ', ' Sigma Clipped Median combined ']
    qt = "'"
    lsig = abs(info.negsig)
    usig = abs(info.possig)
    numimages = n_elements(*info.images)
    non = 0
    for i = 0, numimages-1 do begin
      if (*(*info.images)[i]).vis eq 1 then non = non + 1
    endfor
    if non le 1 then begin
      str = 'Imcombine: Not enough images ON'
      idp3_updatetxt, info, str
      return, -1
    endif
    maxx = 0
    maxy = 0
    xs = intarr(non)
    ys = intarr(non)
    xoff = intarr(non)
    yoff = intarr(non)
    xsiz = intarr(non)
    ysiz = intarr(non)
    ncombine = intarr(non)
    cnt = 0
    for i = 0, numimages-1 do begin
      im = (*info.images)[i]
      if (*im).vis eq 1 then begin
        xs[cnt] = ((*im).xsiz + 2 * (*im).pad) * (*im).xpscl * (*im).zoom
        ys[cnt] = ((*im).ysiz + 2 * (*im).pad) * (*im).ypscl * (*im).zoom
	xoff[cnt] = (*im).xoff + info.sxoff
	yoff[cnt] = (*im).yoff + info.syoff
	xsiz[cnt] = xs[cnt] + xoff[cnt]
	ysiz[cnt] = ys[cnt] + yoff[cnt]
	hdr = [*(*im).phead, *(*im).ihead]
	ncombine[cnt] = sxpar(hdr, 'NCOMBINE') > 1
        cnt = cnt + 1
      endif
    endfor
    maxx = max(xsiz)
    maxy = max(ysiz)
    data = fltarr(maxx, maxy, non)
    mask = intarr(maxx, maxy, non)
    costr = 'Imcombine: ' + systime()
    costr = [costr, string(non) + ' images ' + cstr[info.combim] + $
       ': output size='+ $
       strtrim(string(maxx),2) + ' X ' + strtrim(string(maxy),2)]
    idp3_updatetxt, info, costr[0]
    idp3_updatetxt, info, costr[1]
    count = 0
    for i = 0, numimages-1 do begin
      if (*(*info.images)[i]).vis eq 1 then begin
	mdst = idp3_setdata(info, i)
	mds = mdst[*,*,0]
	alpha = mdst[*,*,1]
	idp3_checkbounds,maxx,maxy,xs[count],ys[count],$
			 xoff[count],yoff[count],dxmin,dxmax, $
			 dymin,dymax,gxmin,gxmax,gymin,gymax,err
        if err lt 0 then begin
	  test = Widget_Message('Offset out of bounds')
	  data[*,*,count] = 0.
	  mask[*,*,count] = 0
        endif else begin
	  data[gxmin:gxmax,gymin:gymax,count] = mds[dxmin:dxmax,dymin:dymax]
	  mask[gxmin:gxmax,gymin:gymax,count] = alpha[dxmin:dxmax,dymin:dymax]
        endelse
	count = count + 1
      endif
    endfor
    mdst = 0
    mds = 0
    alpha = 0
    dsz = size(data)
    maxx = dsz[1]
    maxy = dsz[2]
    numimages = dsz[3]
    final = fltarr(maxx, maxy)
    stev = fltarr(maxx, maxy)
    final[*,*] = 0.
    stev[*,*] = 0.
    sigcalc = info.cbnsigma
    if sigcalc eq 1 then begin
      nsigma = fltarr(maxx, maxy, non)
      nsigma[*,*,*] = 0.
    endif
    npix = intarr(maxx, maxy)
    npix[*,*] = 0
    mone = -1.0
    case info.combim of
    0: begin  ; mean
      for j = 0, maxy-1 do begin
	for i = 0, maxx-1 do begin
	  arr = data[i,j,*]
	  msk = mask[i,j,*]
	  good = where(msk eq 1, count)
          if count gt 0 then begin
	    newarr = arr[good]
	    amean = total(newarr) / float(count)
	    final[i,j] = amean
	    if count gt 1 then begin
	      sdev = stddev(newarr)
	      stev[i,j] = sdev
	      npix[i,j] = count
	      if sigcalc eq 1 then nsigma[i,j,*] = csig(arr,good,amean,sdev)
            endif else begin
	      stev[i,j] = 0. 
              npix[i,j] = count
	      if sigcalc eq 1 then nsigma[i,j,*] = 0.
            endelse
          endif else begin
	    final[i,j] = 0.
	    stev[i,j] = 0.
	    npix[i,j] = 0
	    if sigcalc eq 1 then nsigma[i,j,*] = 0.
          endelse
	endfor
	if j mod 20 eq 0 then idp3_pct, info, maxx, maxy, j
      endfor
      stat = 0
    end

    1: begin  ; median
    for j = 0, maxy-1 do begin
      for i = 0, maxx-1 do begin
	arr = data[i,j,*]
	msk = mask[i,j,*]
	good = where(msk eq 1, count)
	if count gt 0 then begin
	  newarr = arr[good]
	  amedian = median(newarr, /even)
	  final[i,j] = amedian
	  if count gt 1 then begin
	    sdev = sqrt(total((newarr-amedian)^2) / float(count-1))
	    stev[i,j] = sdev
	    npix[i,j] = count
	    if sigcalc eq 1 then nsigma[i,j,*] = csig(arr,good,amedian,sdev)
          endif else begin
	    stev[i,j] = 0. 
            npix[i,j] = count
	    if sigcalc eq 1 then nsigma[i,j,*] = 0.
          endelse
        endif else begin
	  final[i,j] = 0.
	  stev[i,j] = 0.
	  npix[i,j] = 0
	  if sigcalc eq 1 then nsigma[i,j,*] = 0.
        endelse
      endfor
      if j mod 20 eq 0 then idp3_pct, info, maxx, maxy, j
    endfor
    stat = 0
    end

    2: begin    ; sigma clipped mean
    for j = 0, maxy-1 do begin
      for i = 0, maxx-1 do begin
	arr = data[i,j,*]
	msk = mask[i,j,*]
	good = where(msk eq 1, count)
	if count le 1 then begin
	  if count eq 1 then begin
	    gs = good[0]
	    final[i,j] = arr[gs]
          endif else final[i,j] = 0.
	  stev[i,j] = 0.
	  npix[i,j] = count
	  if sigcalc eq 1 then nsigma[i,j,*] = 0.
        endif else begin
          newarr = arr[good]
	  amean = total(newarr) / float(count)
	  sdev = stddev(newarr)
          if count lt 5 then begin
	    final[i,j] = amean
	    stev[i,j] = sdev
	    npix[i,j] = count
	    if sigcalc eq 1 then nsigma[i,j,*] = csig(arr,good,amean,sdev)
          endif else begin
	    dmask = intarr(count)
	    dmask[*] = 1
	    bad1 = where((newarr-amean) lt mone*lsig*sdev, nbad1)
	    if nbad1 gt 0 then dmask[bad1] = 0
	    bad2 = where((newarr-amean) gt usig*sdev, nbad2)
	    if nbad2 gt 0 then dmask[bad2] = 0
	    goodpix = where(dmask eq 1, ngood)
     	    if ngood gt 0 then begin
	      nmean = total(newarr[goodpix])/float(ngood)
	      final[i,j] = nmean
	      npix[i,j] = ngood
	      if ngood gt 1 then begin
	        nsdev = stddev(newarr[goodpix])
	        stev[i,j] = nsdev
	        if sigcalc eq 1 then nsigma[i,j,*] = csig(arr,good,nmean,nsdev)
              endif else begin
		stev[i,j] = 0.
		if sigcalc eq 1 then nsigma[i,j,*] = 0.
              endelse
            endif
          endelse
        endelse
      endfor
      if j mod 20 eq 0 then idp3_pct, info, maxx, maxy, j
    endfor
    stat = 0
    sigstr = 'LO_SIGMA =' + string(lsig) + '  HI_SIGMA =' + string(usig) + $
      ' clipping limits'
    costr = [costr, sigstr]
    end

    3: begin    ; sigma clipped median
    for j = 0, maxy-1 do begin
      for i = 0, maxx-1 do begin
	arr = data[i,j,*]
	msk = mask[i,j,*]
	good = where(msk eq 1, count)
	if count le 1 then begin
	  if count eq 1 then begin
	    gs = good[0]
	    final[i,j] = arr[gs]
          endif else final[i,j] = 0.
	  stev[i,j] = 0.
	  npix[i,j] = 0
	  if sigcalc eq 1 then nsigma[i,j,*] = 0.
        endif else begin
          newarr = arr[good]
	  amedian = median(newarr, /even)
	  sdev = sqrt(total((newarr-amedian)^2) / float(count-1))
          if count lt 5 then begin
	    final[i,j] = amedian
	    stev[i,j] = sdev
	    npix[i,j] = count
	    if sigcalc eq 1 then nsigma[i,j,*] = csig(arr,good,amedian,sdev)
          endif else begin
	    dmask = intarr(count)
	    dmask[*] = 1
	    bad1 = where((newarr-amedian) lt mone*lsig*sdev, nbad1)
	    if nbad1 gt 0 then dmask[bad1] = 0
	    bad2 = where((newarr-amedian) gt usig*sdev, nbad2)
	    if nbad2 gt 0 then dmask[bad2] = 0
	    goodpix = where(dmask eq 1, ngood)
     	    if ngood gt 0 then begin
	      nmedian = median(newarr[goodpix], /even)
	      final[i,j] = nmedian
	      npix[i,j] = ngood
	      if ngood gt 1 then begin
		cc = float(ngood - 1)
	        nsdev = sqrt(total((newarr[goodpix]-final[i,j])^2)/cc)
	        stev[i,j] = nsdev
	        if sigcalc eq 1 then nsigma[i,j,*]=csig(arr,good,nmedian,nsdev)
              endif else begin
		stev[i,j] = 0.
		if sigcalc eq 1 then nsigma[i,j,ngood] = 0.
              endelse
            endif
          endelse
        endelse
      endfor
      if j mod 20 eq 0 then idp3_pct, info, maxx, maxy, j
    endfor
    stat = 0
    sigstr = 'LO_SIGMA =' + string(lsig) + '  HI_SIGMA =' + string(usig) + $
      ' clipping limits'
    costr = [costr, sigstr]
    end

    else: stat = -1
  endcase
  return, stat
  end

pro idp3_combindone, event
  Widget_Control, event.top, /Destroy
end

pro idp3_combinhlp, event
  Widget_Control, event.top, Get_UValue=combinfo
  Widget_Control, combinfo.info.idp3Window, GET_UValue=cinfo
  if cinfo.pdf_viewer eq '' then begin
    tmp = idp3_findfile('idp3_imcombine.hlp')
    xdisplayfile, tmp
  endif else begin
    tmp = idp3_findfile('idp3_imcombine.pdf')
    str = cinfo.pdf_viewer + ' ' + tmp
    if !version.os eq 'darwin' then str = 'open -a ' + str
    spawn, str
  endelse
end

pro idp3_imcombine_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=combinfo
  Widget_Control, combinfo.info.idp3Window, GET_UValue=cinfo

  case event.id of

  combinfo.cButtons: begin
   combmethod = event.value
   cinfo.combim = combmethod
  end

  combinfo.lowerField: begin
    Widget_Control, combinfo.lowerField, Get_Value = temp
    cinfo.negsig = temp
  end

  combinfo.upperField: begin
    Widget_Control, combinfo.upperField, Get_Value = temp
    cinfo.possig = temp
  end

  combinfo.selectname: begin
    Widget_Control, combinfo.selectname, Get_Value = temp
    combinfo.combiname = strtrim(temp[0],2)
  end

  combinfo.selectpath: begin
    Widget_Control, combinfo.selectpath, Get_Value = temp
    path = strtrim(temp[0],2)
    plen = strlen(path)
    if strmid(path, plen-1) ne cinfo.delim then path = path + cinfo.delim
    combinfo.combinpath = path
  end

  combinfo.sButtons: begin
    Widget_Control, combinfo.sButtons, Get_Value = barray
    cinfo.cbsav2idp3 = barray[0]
    cinfo.cbsav2file = barray[1]
  end

  combinfo.browseButton: begin
    pathvalue = Dialog_Pickfile(title='Please select output file path')
    ua_decompose, pathvalue, disk, path, file, extn, vers
    fpath = disk + path
    Widget_Control, combinfo.selectpath, Set_Value = fpath
  end

  combinfo.aButtons: begin
   Widget_Control, combinfo.aButtons, Get_Value = barray
   cinfo.cbstdev = barray[0]
   cinfo.cbnpixels = barray[1]
   cinfo.cbnsigma = barray[2]
  end

  combinfo.computeButton: begin
    cstr = [' Mean combined ', ' Median combined ', $
	    ' Sigma Clipped Mean combined ', ' Sigma Clipped Median combined ']
    Widget_Control, combinfo.cButtons, Get_Value = barray
    cinfo.combim = barray[0]
    Widget_Control, combinfo.lowerField, Get_Value = temp
    cinfo.negsig = temp
    Widget_Control, combinfo.upperField, Get_Value = temp
    cinfo.possig = temp
    Widget_Control, combinfo.aButtons, Get_Value = barray
    cinfo.cbstdev = barray[0]
    cinfo.cbnpixels = barray[1]
    cinfo.cbnsigma = barray[2]
    Widget_Control, combinfo.sButtons, Get_Value = barray
    if total(barray) eq 0 then begin
      stat = Widget_Message($
       'Must select IDP3, File, or both for results')
      return
    endif
    cinfo.cbsav2idp3 = barray[0]
    cinfo.cbsav2file = barray[1]
    if cinfo.cbnsigma eq 1 and cinfo.cbsav2file eq 0 then begin
      str = 'Must select FILE option when saving NSIGMA image!'
      stat = Widget_Message(str)
      return
    endif
    Widget_Control, combinfo.selectname, Get_Value = temp
    idp3name = strtrim(temp[0],2)
    if strlen(idp3name) eq 0 then begin
      stat = Widget_Message('Must give name for results')
      return
    endif
    combinfo.combiname = idp3name
    c = size(*cinfo.images)
    if c[0] eq 0 and c[1] eq 2 then begin
      str = 'Imcombine: No images loaded'
      idp3_updatetxt, cinfo, str
      return
    endif
    moveim = cinfo.moveimage
    ref = (*cinfo.images)[moveim]
    if (*ref).vis eq 0 then begin
      str = 'Imcombine: Reference image not ON'
      idp3_updatetxt, cinfo, str
      return
    endif
    if cinfo.cbsav2file eq 1 then begin
      Widget_Control, combinfo.selectpath, Get_Value = temp
      filepath = strtrim(temp[0],2)
      plen = strlen(filepath)
      if strlen(filepath) eq 0 then begin
	stat = Widget_Message('Must give path for file')
	return
      endif
      if strmid(filepath, plen-1) ne cinfo.delim $ 
	 then filepath = filepath + cinfo.delim
      combinfo.combinpath = filepath
      filename = filepath + idp3name
      ua_decompose, filename, disk, path, name, extn, vers
      if strlen(extn) eq 0 then filename = filename + '.fits'
      temp = file_search (filename, Count = fcount)
      if fcount gt 0 then begin
	idp3_selectval,event.top,'Do you wish to overwrite existing file?',$
	  ['no','yes'], val
        if val eq 0 then return
      endif else begin
	openw, lun, filename, error=err, /get_lun
	if err ne 0 then begin
	  stat = Widget_Message('Error in Path')
	  return
        endif else begin
	  close, lun
	  free_lun, lun
        endelse
      endelse
    endif
    phdr = *(*ref).phead
    ihdr = *(*ref).ihead
    stat = idp3_combinemm(cinfo, phdr, final, stev, nsigma, npix, costr)
    ; update header for all images that contributed
    if stat ge 0 then begin
      ims = (*cinfo.images)
      sfits = cinfo.sfits
      imsz = size(final)
      fsz = [imsz[1],imsz[2]]
      l1 = 0
      l2 = n_elements(ims)-1
      if cinfo.zoomflux eq 0 then str = 'Flux NOT Conserved' $
	else str = 'Flux Conserved'
      idp3_sethdr, ims, moveim, sfits, phdr, ihdr, fsz, l1, l2, str
      sxaddpar, phdr, 'HISTORY', costr[0]
      sxaddpar, phdr, 'HISTORY', costr[1]
      if n_elements(costr) eq 3 then sxaddpar, phdr, 'HISTORY', costr[2]
      if cinfo.cbsav2idp3 eq 1 then begin
        ; update images structure
        final_msk = intarr(imsz[1], imsz[2])
        final_msk[*,*] = 1
        b = where(npix eq 0, bcnt)
        if bcnt gt 0 then final_msk[b] = 0
        newim = ptr_new({idp3im})
        idp3_setimstruct, newim, phdr, ihdr, ref, cinfo.cbsav2file
        (*newim).name = combinfo.combiname
        (*newim).orgname = combinfo.combiname
        (*newim).data = ptr_new(final)
        (*newim).mask = ptr_new(final_msk)
        (*newim).xsiz = imsz[1]
        (*newim).ysiz = imsz[2]
        (*newim).vis = 0
        c = imscale(final,10.0)
        (*newim).z1 = c[0]
        (*newim).z2 = c[1]
        tempimages = [*cinfo.images, newim]
        ptr_free, cinfo.images
        cinfo.images = ptr_new(tempimages)
      endif
      if cinfo.cbsav2file eq 1 then begin
	ua_fits_open, filename, fcb, /Write
	if n_elements(ihdr) le 2 then begin
	  ua_fits_write, fcb, final, phdr, /noextend
        endif else begin
	  ua_fits_write, fcb, 0, phdr
	  ua_fits_write, fcb, final, ihdr, extname='SCI', extver=1
        endelse
	ua_fits_close, fcb
      endif
      if cinfo.cbstdev eq 1 then begin
	if cinfo.cbsav2idp3 eq 1 then begin
	  ua_decompose, idp3name, disk, path, name, extn, vers
	  iname = disk + path + name + '_sdv' + extn
          final_msk = intarr(imsz[1], imsz[2])
          final_msk[*,*] = 1
          b = where(npix eq 0, bcnt)
          if bcnt gt 0 then final_msk[b] = 0
          newim = ptr_new({idp3im})
          idp3_setimstruct, newim, phdr, ihdr, ref, cinfo.cbsav2file 
          (*newim).name = iname
          (*newim).orgname = iname
          (*newim).data = ptr_new(stev)
          (*newim).mask = ptr_new(final_msk)
          (*newim).xsiz = imsz[1]
          (*newim).ysiz = imsz[2]
          (*newim).vis = 0
          c = imscale(stev,10.0)
          (*newim).z1 = c[0]
          (*newim).z2 = c[1]
          tempimages = [*cinfo.images, newim]
          ptr_free, cinfo.images
          cinfo.images = ptr_new(tempimages)
        endif
  	if cinfo.cbsav2file eq 1 then begin
	  ua_decompose, filename, disk, path, name, extn, vers
	  dname = disk + path + name + '_sdv' + extn
	  ua_fits_open, dname, fcb, /Write
	  if n_elements(ihdr) le 2 then begin
	    ua_fits_write, fcb, stev, phdr, /noextend
          endif else begin
	    ua_fits_write, fcb, 0, phdr
	    ua_fits_write, fcb, stev, ihdr, extname='STDDEV', extver=1
          endelse
	  ua_fits_close, fcb
        endif
      endif
      if cinfo.cbnpixels eq 1 then begin
	ua_decompose, idp3name, disk, path, name, extn, vers
	iname = disk + path + name + '_npix' + extn
	if cinfo.cbsav2idp3 eq 1 then begin
          final_msk = intarr(imsz[1], imsz[2])
          final_msk[*,*] = 1
          b = where(npix eq 0, bcnt)
          if bcnt gt 0 then final_msk[b] = 0
          newim = ptr_new({idp3im})
          idp3_setimstruct, newim, phdr, ihdr, ref, cinfo.cbsav2file
          (*newim).name = iname
          (*newim).orgname = iname
          (*newim).data = ptr_new(npix)
          (*newim).mask = ptr_new(final_msk)
          (*newim).xsiz = imsz[1]
          (*newim).ysiz = imsz[2]
          (*newim).vis = 0
          c = imscale(stev,10.0)
          (*newim).z1 = c[0]
          (*newim).z2 = c[1]
          tempimages = [*cinfo.images, newim]
          ptr_free, cinfo.images
          cinfo.images = ptr_new(tempimages)
        endif
        if cinfo.cbsav2file eq 1 then begin
	  ua_decompose, filename, disk, path, name, extn, vers
	  dname = disk + path + name + '_npix' + extn
	  ua_fits_open, dname, fcb, /Write
	  if n_elements(ihdr)  le 2 then begin
	    ua_fits_write, fcb, npix, phdr, /noextend
          endif else begin
	    ua_fits_write, fcb, 0, phdr
	    ua_fits_write, fcb, npix, ihdr, extname='SCI', extver=1
          endelse
	  ua_fits_close, fcb
	endif
      endif
      if cinfo.cbnsigma eq 1 then begin
	ua_decompose, filename, disk, path, name, extn, vers
	signame = disk + path + name + '_nsigma' + extn
	ua_fits_open, signame, fcb, /Write
	if n_elements(ihdr) le 2 then begin
	  ua_fits_write, fcb, nsigma, phdr, /noextend
        endif else begin
	  ua_fits_write, fcb, 0, phdr
	  ua_fits_write, fcb, nsigma, ihdr, extname='SCI', extver=1
        endelse
	ua_fits_close, fcb
      endif
      Widget_Control, combinfo.info.idp3Window, Set_UValue=cinfo
      if (XRegistered('idp3_showim')) then begin
	geo = Widget_Info(cinfo.ShowImBase, /geometry)
	cinfo.wpos.siwp[0] = geo.xoffset - cinfo.xoffcorr
	cinfo.wpos.siwp[1] = geo.yoffset - cinfo.yoffcorr
	Widget_Control, combinfo.info.idp3Window, Set_UValue=cinfo
	Widget_Control, cinfo.ShowImBase, /Destroy
      endif
      idp3_showim,{WIDGET_BUTTON,ID:0L,TOP:cinfo.idp3Window,HANDLER:0L,SELECT:0}
      Widget_Control, cinfo.idp3Window, Get_UValue=info
      idp3_display,info
    endif
  end

  endcase

  Widget_Control,combinfo.info.idp3Window,Get_UValue=tinfo
  combinfo.info = tinfo
  Widget_Control, event.top, Set_UValue=combinfo
end

pro idp3_imcombine, event

@idp3_structs
@idp3_errors

  if(XRegistered("idp3_imcombine")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  lsig = info.negsig
  usig = info.possig
  meth = info.combim
  stdev = info.cbstdev
  npix = info.cbnpixels
  nsigma = info.cbnsigma
  sav2idp3 = info.cbsav2idp3
  sav2file = info.cbsav2file
  combiname = '  '
  combinpath = info.savepath

  title = 'IDP3 Image Combine'
  imcbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
  
  imcbase1 = Widget_Base (imcbase, /Column)
  cnames = ['Mean', 'Median', 'Sigma-clipped Mean', 'Sigma-clipped Median'] 
  cButtons = cw_bgroup(imcbase1, cnames, column = 1, uvalue='cbutton', $
     set_value=meth, /exclusive, /no_release, label_top='Combination Method')
  cliplabel = Widget_Label(imcbase, Value = 'Clipping Limits (# sigma):')
  imcbase2 = Widget_Base (imcbase, /Row)
  lowerField = cw_field(imcbase2, Value=lsig, xsize=5, title=$
    'Lower:', /Return_Events, /Floating)
  upperField = cw_field(imcbase2, Value=usig, xsize=5, title=$
    'Upper:', /Return_Events, /Floating)
  imcbase4 = Widget_Base (imcbase, /Column)
  anames = ['STDEV        (name_stdev)', $
            'No of Pixels (name_npix)', $
	    'NSIGMA       (name_nsigma - File only)']
  aButtons = cw_bgroup(imcbase4, anames, column=1, uvalue='abutton', $
      set_value=[stdev,nsigma,npix], /nonexclusive, $
      label_top='Auxilliary Images:')
  imcbase8 = Widget_Base(imcbase, /Column)
  snames = ['IDP3    (name required)', 'File    (name & path required)']
  sButtons = cw_bgroup(imcbase8, snames, column=1, uvalue='sbutton', $
      set_value=[sav2idp3,sav2file], /nonexclusive, $
      label_top='Save Results to: ')
  imcbase7 = Widget_Base(imcbase, /Row)
  label = Widget_Label(imcbase7, Value='Name:')
  selectname = Widget_Text(imcbase7, Value = combiname, XSize = 32, /Edit)
  imcbase6 = Widget_Base(imcbase, /Row)
  label2 = Widget_Label(imcbase6, Value='Path:')
  selectpath = Widget_Text(imcbase6, Value = combinpath, XSize = 32, /Edit)
  space2 = Widget_Label(imcbase, Value = '  ')
  imcbase5 = Widget_Base(imcbase, /Row)
  browseButton = Widget_Button(imcbase5, Value='Browse for Path')
  computeButton = Widget_Button(imcbase5, Value = ' Compute')
  helpButton = Widget_Button(imcbase5, Value= ' Help ', $
	      Event_Pro='idp3_combinhlp')
  doneButton = Widget_Button(imcbase5, Value = ' Done ', $
	      Event_Pro='idp3_combindone')

  combinfo = { cButtons       :   cButtons,       $
 	       lowerField     :   lowerField,     $
	       upperField     :   upperField,     $
	       selectname     :   selectname,     $
	       aButtons       :   aButtons,       $
	       sButtons       :   sButtons,       $
	       browseButton   :   browseButton,   $
	       selectpath     :   selectpath,     $
	       computeButton  :   computeButton,  $
	       combiname      :   combiname,      $
	       combinpath     :   combinpath,     $
	       info           :   info            }

  Widget_Control, imcbase, set_uvalue = combinfo
  Widget_Control, imcbase, /Realize

  XManager, "idp3_imcombine", imcbase, Event_Handler = "idp3_imcombine_ev", $
       /No_Block
          
end
