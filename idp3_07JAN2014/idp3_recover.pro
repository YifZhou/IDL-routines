pro idp3_recover, info

@idp3_structs
@idp3_errors

    path = info.savepath
    filename = path + 'idp3_recover.par'
    print, 'Writing image parameters to ', filename
    titlestr = 'Filename                                                    ' $
	+ '                              ' $
	+ '   xoffset   yoffset  rotation     scale      bias      zoom    '  $
        + 'MovAmt    RotAmt    SclAmt'
      openw, lun, filename, /GET_LUN
      printf, lun, titlestr
      field = '                                              ' + $
	      '                                              '
      ims = (*info.images)
      delim = info.name_delim
      for i = 0, n_elements(ims)-1 do begin
        name = (*ims[i]).name
	if strlen(delim) eq 1 then name = name + delim
        scl = (*ims[i]).scl
        bias = (*ims[i]).bias
        zoom = (*ims[i]).zoom
        rot = (*ims[i]).rot
        rotx = (*ims[i]).rotcx
        roty = (*ims[i]).rotcy
	pad = (*ims[i]).topad
	rotxpad = (*ims[i]).rotxpad
	rotypad = (*ims[i]).rotypad
	xpscl = (*ims[i]).xpscl
	ypscl = (*ims[i]).ypscl
	sclamt = (*ims[i]).sclamt
	movamt = (*ims[i]).movamt
	rotamt = (*ims[i]).rotamt
        xo = (*ims[i]).xoff + (*ims[i]).xpoff
        yo = (*ims[i]).yoff + (*ims[i]).ypoff
	flipy = (*ims[i]).flipy
	clipmin = (*ims[i]).clipbottom
	cmin = (*ims[i]).clipmin
	cminval = (*ims[i]).cminval
	clipmax = (*ims[i]).cliptop
	cmax = (*ims[i]).clipmax
	cmaxval = (*ims[i]).cmaxval
	xpix = (*ims[i]).xplate
	ypix = (*ims[i]).yplate
	nxpix = (*ims[i]).nxplate
	nypix = (*ims[i]).nyplate
	lccx = (*ims[i]).olccx
	lccy = (*ims[i]).olccy
	dispf = (*ims[i]).dispf
	vis = (*ims[i]).vis
	namefield = field
	strput, namefield, name
	formstr = '(a90,6f10.4,3i8,2f10.4,2f12.8,3f10.4,2i4,2f15.4,i4,' + $
	  '2f15.4,4f12.7,2f12.4,2i4)'
	printf, lun, namefield, xo, yo, rot, scl, bias, zoom, pad, $
	  rotxpad, rotypad, rotx, roty, xpscl, ypscl, movamt, rotamt, $
	  sclamt, flipy, clipmin, cmin, cminval, clipmax, cmax, cmaxval, $
	  xpix, ypix, nxpix, nypix, lccx, lccy, dispf, vis, FORMAT=formstr 
      endfor
      close, lun
      free_lun, lun
end
