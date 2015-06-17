pro idp3_savepar, ims, filename, delim=delim

@idp3_structs
@idp3_errors

      field = '                                                  ' + $
	      '                                                  ' + $
	      '                                                  ' + $
	      '                                                  ' + $
	      '                                                  '
      len = 0
      for i = 0, n_elements(ims)-1 do begin
	if (*ims[i]).memory_only eq 0 then begin
	  nlen = strlen((*ims[i]).orgname)
	  len = max([len, nlen])
        endif
      endfor
      if n_elements(delim) gt 0 then len = len + 1
      tlen = len - 8 
      tstr1 = 'Filename' + strmid(field,0,tlen)
      tstr2 = $
         '    xoffset    yoffset  xno  name   rotation         scale      ' $
       + '     bias       zoom    '  $
       + '   pad     xpad     ypad    rotxcen    rotycen  '$
       + '  xpixscale    ypixscale' $
       + '     MovAmt     RotAmt     SclAmt  flipy clipmin    cmin' $
       + '          cminval' $
       + '   clipmax     cmax           cmaxval' $
       + '         xpix         ypix        nxpix        nypix'$
       + '       centroidx    centroidy  display  visible' 
      titlestr = tstr1 + tstr2 
      openw, lun, filename, /GET_LUN
      printf, lun, titlestr
      str1 = '(a' + strtrim(string(len),2)
      str2 = '2(1x,f10.4),i4,2x,a4,1x,f11.4,2(1x,g14.6),1x,f10.4,' + $
	     '3(1x,i8),2(1x,f10.4),2(1x,f12.8),' + $
	     '3(1x,f10.4),1x,i4,3x,i2,2(1x,f15.4),1x,i4,2(1x,f15.4),' + $
	     '4(1x,f12.7),2(1x,f12.4),2(1x,i7))'
      formstr = str1 + ',' + str2
      for i = 0, n_elements(ims)-1 do begin
        name = (*ims[i]).orgname
	if (*ims[i]).memory_only eq 1 then begin
	  str = 'Image ' + name + ' only saved to memory! No SavePar entry!'
	  print, str
          if (*ims[i]).vis eq 1 then stat = Widget_Message(str)
        endif else begin
	  if n_elements(delim) eq 1 then name = name + delim
	  rno = (*ims[i]).extver
	  extnam = (*ims[i]).extnam
	  if strlen(extnam) eq 0 then extnam = '-'
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
	  xpix = (*ims[i]).oxplate
	  ypix = (*ims[i]).oyplate
	  nxpix = (*ims[i]).xplate
	  nypix = (*ims[i]).yplate
	  lccx = (*ims[i]).olccx
	  lccy = (*ims[i]).olccy
	  dispf = (*ims[i]).dispf
	  vis = (*ims[i]).vis
;	  namefield = field
;	  strput, namefield, name
;	  formstr = '(a90,2(1x,f10.4),i4,2x,a4,1x,f11.4,2(1x,g14.6),1x,f10.4,' $
;	    + '3(1x,i8),2(1x,f10.4),2(1x,f12.8),' + $
;	    '3(1x,f10.4),1x,i4,3x,i2,2(1x,f15.4),1x,i4,2(1x,f15.4),' + $
;	    '4(1x,f12.7),2(1x,f12.4),2(1x,i7))'
	  printf, lun, name, xo, yo, rno, extnam, rot, scl, bias, zoom, $
	    pad, rotxpad, rotypad, rotx, roty, xpscl, ypscl, movamt, rotamt, $
	    sclamt, flipy, clipmin, cmin, cminval, clipmax, cmax, cmaxval, $
	    xpix, ypix, nxpix, nypix, lccx, lccy, dispf, vis, FORMAT= formstr
        endelse
      endfor
      close, lun
      free_lun, lun
end
