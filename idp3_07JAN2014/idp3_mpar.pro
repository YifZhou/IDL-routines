pro idp3_mpar, ims, filename, xoo, yoo

@idp3_structs
@idp3_errors

      maxlen = 120
      openw, lun, filename, /GET_LUN, width=400
      field = '                                                       ' + $
	      '                                                       '
      q = "|"
      for i = 0, n_elements(ims)-1 do begin
        if (*ims[i]).vis eq 1 then begin
           name = (*ims[i]).orgname
	   rno = (*ims[i]).extver
	   extnam = (*ims[i]).extnam
	   if strlen(extnam) eq 0 then extnam = 'None'
	   xsz = (*ims[i]).xsiz
	   ysz = (*ims[i]).ysiz
           scl = (*ims[i]).scl
           bias = (*ims[i]).bias
           zoom = (*ims[i]).zoom
           rot = (*ims[i]).rot
           rotx = (*ims[i]).rotcx
           roty = (*ims[i]).rotcy
	   pad = (*ims[i]).pad
	   xpscl = (*ims[i]).xpscl
	   ypscl = (*ims[i]).ypscl
           xo = (*ims[i]).xoff + (*ims[i]).xpoff + xoo
           yo = (*ims[i]).yoff + (*ims[i]).ypoff + yoo
	   flipy = (*ims[i]).flipy
	   clipbottom = (*ims[i]).clipbottom
	   clipmin = (*ims[i]).clipmin
	   cminval = (*ims[i]).cminval
	   cliptop = (*ims[i]).cliptop
	   clipmax = (*ims[i]).clipmax
	   cmaxval = (*ims[i]).cmaxval
	   nlen = strlen(name)
	   if nlen eq maxlen then begin
	     namefield = name
           endif else begin
	     if nlen lt maxlen then begin
	       diff = maxlen - nlen
	       blnk = strmid(field, 0, diff)
	       namefield = name + blnk
             endif else namefield = strmid(name, 0, maxlen)
           endelse
	   formstr ='(a1,a120,a1,i4,1x,a4,4(1x,i8),8(1x,f10.4),2(1x,f12.8),' + $
	     '1x,i4,2(1x,f12.4),1x,i4,2(1x,f12.4))' 
	   printf, lun, q, namefield, q, rno, extnam,xsz,ysz,pad,flipy,xo,yo, $
	     rot, scl, bias, zoom, rotx, roty, xpscl, ypscl, clipbottom, $
	     clipmin, cminval, cliptop, clipmax, cmaxval, $
	     FORMAT = formstr
;	     FORMAT='(a1,a90,a1,4I8,8f10.4,2f12.8,i4,2f12.4,i4,2f12.4)' 
        endif
      endfor
      close, lun
      free_lun, lun
end
