pro idp3_mset,pp,input,pixorg,mdioz,mddz,zoomflux,sfits,data,mask,mphdr,mihdr 

 data = 0
 mask = 0
 phdr = ['','']
 ihdr = ['','']
 sethdr = 0
 q = "|"

 temp = file_search (input, Count = fcount)
 if fcount ne 0 then begin
   openr, lun, input, /get_lun
   numimages = 0
   while not eof(lun) do begin
     lineofText = ' '
     readf, lun, lineofText
     lineofText = strtrim(lineofText,2)
     len = strlen(lineofText)
     lineofText = strmid(lineofText, 1, len-1)
     xtmpstr = strsplit(lineofText, q, /extract)
     ttmpstr = strsplit(xtmpstr[1], /extract)
     if numimages eq 0 then begin
       fname = strtrim(xtmpstr[0])
       srno = ttmpstr[0]
       extnam = ttmpstr[1]
       sxsiz = ttmpstr[2]
       sysiz = ttmpstr[3]
       spad = ttmpstr[4]
       sflipy = ttmpstr[5]
       sxoff = ttmpstr[6]
       syoff = ttmpstr[7]
       srot = ttmpstr[8]
       sscl = ttmpstr[9]
       sbias = ttmpstr[10]
       szoom = ttmpstr[11]
       srotx = ttmpstr[12]
       sroty = ttmpstr[13]
       sxpscl = ttmpstr[14]
       sypscl = ttmpstr[15]
       sclipbottom = ttmpstr[16]
       sclipmin = ttmpstr[17]
       scminval = ttmpstr[18]
       scliptop = ttmpstr[19]
       sclipmax = ttmpstr[20]
       scmaxval = ttmpstr[21]
       numimages = numimages + 1
     endif else begin
       fname = [fname,strtrim(xtmpstr[0])]
       srno = [srno,ttmpstr[0]]
       extnam = [extnam,ttmpstr[1]]
       sxsiz = [sxsiz,ttmpstr[2]]
       sysiz = [sysiz,ttmpstr[3]]
       spad = [spad,ttmpstr[4]]
       sflipy = [sflipy,ttmpstr[5]]
       sxoff = [sxoff,ttmpstr[6]]
       syoff = [syoff,ttmpstr[7]]
       srot = [srot,ttmpstr[8]]
       sscl = [sscl,ttmpstr[9]]
       sbias = [sbias,ttmpstr[10]]
       szoom = [szoom,ttmpstr[11]]
       srotx = [srotx,ttmpstr[12]]
       sroty = [sroty,ttmpstr[13]]
       sxpscl = [sxpscl,ttmpstr[14]]
       sypscl = [sypscl,ttmpstr[15]]
       sclipbottom = [sclipbottom,ttmpstr[16]]
       sclipmin = [sclipmin,ttmpstr[17]]
       scminval = [scminval,ttmpstr[18]]
       scliptop = [scliptop,ttmpstr[19]]
       sclipmax = [sclipmax,ttmpstr[20]]
       scmaxval = [scmaxval, ttmpstr[21]]
       numimages = numimages + 1
     endelse
   endwhile

   rno = fix(srno)
   xoff = fix(sxoff)
   xpoff = float(sxoff) - float(xoff)
   yoff = fix(syoff)
   ypoff = float(syoff) - float(yoff)
   rot = float(srot)
   scl = float(sscl)
   bias = float(sbias)
   zoom = float(szoom)
   xsiz = float(sxsiz)
   ysiz = float(sysiz)
   arotx = float(srotx)
   aroty = float(sroty)
   pad = fix(spad)
   flipy = fix(sflipy)
   xpscl = float(sxpscl)
   ypscl = float(sypscl)
   clipbottom = fix(sclipbottom)
   clipmin = float(sclipmin)
   cminval = float(scminval)
   cliptop = fix(scliptop)
   clipmax = float(sclipmax)
   cmaxval = float(scmaxval)
   maxx = 0
   maxy = 0
   for i = 0, numimages-1 do begin
     x2 = (xsiz[i] + 2 * pad[i]) * xpscl[i] * zoom[i] + xoff[i]
     y2 = (ysiz[i] + 2 * pad[i]) * ypscl[i] * zoom[i] + yoff[i]
     if x2 gt maxx then maxx = fix(x2)
     if y2 gt maxy then maxy = fix(y2)
   endfor
   data = fltarr(maxx, maxy, numimages)
   data[*,*,*] = 0.0
   mask = intarr(maxx, maxy, numimages)
   mask[*,*,*] = 0
   ztype = 0
   print, numimages, '  images mean/median combined, size= ', maxx, maxy
   for i = 0, numimages -1 do begin
     tempfname = fname[i]
     ua_decompose, tempfname, disk, path, name, extn, version
     lextn = strlowcase(extn)
     if strlen(lextn) gt 4 then lextn = strmid(lextn, 0, 4)
     Case lextn of

       '.fit': Begin
       ; FITS format
       ua_fits_open, tempfname, fcb
       nextn = fcb.nextend
       if nextn gt 0 then if  fcb.xtension[1] eq 'TABLE' $
	 then nextn = 0
       hdr_flag = 1
       if nextn gt 0 then begin
	 ua_fits_read, fcb, temp,phdr,exten_no=0,/Header_Only,/no_abort
	 if strlowcase(extnam[i]) ne 'none' then begin
	   maxver = idp3_extver(nextn, fcb.extname, extnam[i])
	   if maxver le 0 then begin
	     print, 'Error in extension name'
	     return
           endif
         endif
	 inst = strtrim(sxpar(phdr, 'INSTRUME'), 2)
	 if inst eq 'NICMOS' then begin
	   if rno[i] lt 0 then begin
	     if maxver gt 1 then rno[i] = (maxver-1)
	     exread = 1
           endif else begin
	     rno[i] = rno[i] < (maxver-1)
	     exread = maxver - rno[i]
           endelse
	   if maxver gt 1 then print, 'Loading ', extnam[i], ' extension ', $
	     strtrim(string(exread),2), ' which is sample ', $
	     strtrim(string(rno[i]),2), ' (time order)'
         endif else begin
           if rno[i] le 0 then rno[i] = 1
	   exread = rno[i]
         endelse
	 if strlowcase(extnam[i]) ne 'none' then begin
           ua_fits_read,fcb,tempdata, ihdr, Extver=exread, Extname=extnam[i], $
	      /NO_PDU,/no_abort
         endif else begin
	   ua_fits_read,fcb,tempdata, ihdr, Exten_no=exread, /NO_PDU,/no_abort
         endelse
       endif else begin
         ua_fits_read, tempfname, tempdata, phdr, /no_abort
	 tsz = size(tempdata)
	 if tsz[0] eq 3 then tempdata = tempdata[*,*,rno[i]]
       endelse
       ua_fits_close, fcb
     end

     '.pic': Begin
       ; this is a Macintosh pict file
       read_pict, tempfname, tempdata
       ihdr = ['','']
       phdr = ['','']
       hdr_flag = 0
     end

     '.tif': Begin
      ; this is a tiff file
      tdata = read_tiff(tempfname)
      imsz = size(tdata)
      if imsz[0] eq 3 then begin
	pln = srno[i]
	tmp = bytarr(imsz[2],imsz[3],imsz[1])
	tmp[*,*,0] = tdata[0,*,*]
	tmp[*,*,1] = tdata[1,*,*]
	tmp[*,*,2] = tdata[2,*,*]
	tempdata = tmp
	tmp = 0
	tempdata = tempdata[*,*,pln]
      endif else tempdata = tdata
      tdata = 0
      ihdr = ['','']
      phdr = ['','']
      hdr_flag = 0
    end

    else: Begin
       ; Assume HDF format.
       ua_hdf_read, tempfname, phdr, tempdata, hdr_flag, image_flag
       if image_flag ne 1 then begin
	 str = 'File ' + tempfname + ' not recognized as fits or hdf format'
	 print, str
       endif
     end
   endcase
   if hdr_flag eq 0 then begin
     ; Header empty, build mimimal fits header
      phdr = $
['SIMPLE  =                    T /image conforms to FITS standard           ', $
 'NAXIS   =                    2 /number of axes                            ', $
 'END                                                                       ']
     sxaddpar,phdr,'NAXIS1', x2
     sxaddpar,phdr,'NAXIS2', y2
   endif
     if sethdr eq 0 then begin
       sethdr = 1
       if sfits eq 0 then begin
         mihdr = ihdr
       endif else begin
	 if n_elements(ihdr) gt 2 then begin
	   sxdelpar, phdr, 'NEXTEND'
	   sxdelpar, phdr, 'END'
	   sxdelpar, ihdr, 'XTENSION'
	   sxdelpar, ihdr, 'INHERIT'
	   sxdelpar, ihdr, 'EXTNAME'
	   sxdelpar, ihdr, 'EXTVER'
	   sxdelpar, ihdr, 'EXTLEVEL'
	   sxdelpar, ihdr, 'BITPIX'
	   sxdelpar, ihdr, 'NAXIS'
	   sxdelpar, ihdr, 'NAXIS1'
	   sxdelpar, ihdr, 'NAXIS2'
	   sxdelpar, ihdr, 'GCOUNT'
	   phdr = [phdr, ihdr]
	   sxaddpar, phdr, 'NAXIS', 2
	   sxaddpar, phdr, 'NAXIS1', x2, AFTER='NAXIS'
	   sxaddpar, phdr, 'NAXIS2', y2, AFTER='NAXIS1'
         endif
       endelse
       mphdr = phdr
     endif

     ct = string(format='(I2.2)',i)
     sxaddpar, mphdr, pp+'IMAGE'+ct, fname[i], 'data image'
     if rno[i] ge 0 then begin
       hstr = 'Read number: ' + strtrim(string(rno[i]),2)
       sxaddpar, mphdr, 'HISTORY', hstr
     endif
     sz = size(tempdata)
     tempmask = intarr(sz[1],sz[2])
     tempmask[*,*] = 1

     rotx = arotx[i]
     roty = aroty[i]

     ; Should data be clipped
       ; is lower flag set
       if clipbottom[i] eq 1 then begin
	 d = where(tempdata lt clipmin[i], bcount)
	 if bcount gt 0 then begin
	   str = string(bcount) + ' minimum pixels reset to ' + $
	     string(cminval[i])
           sxaddpar, mphdr, 'HISTORY', str
	   tempdata(d) = cminval[i]
         endif
       endif
       ; is upper flag set
       if cliptop[i] eq 1 then begin
	 d = where(tempdata gt clipmax[i], tcount)
	 if tcount gt 0 then begin
	   str = string(tcount) + ' maximum pixels reset to ' + $
	     string(cmaxval[i])
           sxaddpar, mphdr, 'HISTORY', str
           tempdata[d] = cmaxval[i]
         endif
       endif
     
     ; Should the Y axis be flipped?
     if flipy[i] eq 1 then begin
       tempsz = size(tempdata)
       mdata = tempdata
       yflip = fix(tempsz[2]/2)-1
       for ii = 0, yflip do begin
	 oi = tempsz[2] - 1 - ii
	 mdata[*,ii] = tempdata[*,oi]
	 mdata[*,oi] = tempdata[*,ii]
       endfor
       mmask = tempmask
       temp=0
       roty = tempsz[2] - roty - 1
       sxaddpar, mphdr, 'HISTORY', 'Data has been flipped in Y'
     endif else begin
       mdata = tempdata
       mmask = tempmask
     endelse

     ; Should image be padded
     if pad[i] gt 0 then begin
       tdata = fltarr(xsiz[i] + 2 * pad[i], ysiz[i] + 2 * pad[i])
       tdata[*,*] = 0.
       tmask = intarr(xsiz[i] + 2 * pad[i], ysiz[i] + 2 * pad[i])
       tmask[*,*] = 0
       xbeg = pad[i]
       ybeg = pad[i]
       xend = xbeg + xsiz[i] - 1
       yend = ybeg + ysiz[i] - 1
       tdata[xbeg:xend,ybeg:yend] = mdata
       tmask[xbeg+1:xend-1,ybeg+1:yend-1] = mmask[1:xend-xbeg-1,1:yend-ybeg-1]
       mdata = tdata
       mmask = tmask
       tdata = 0
       tmask = 0
       rotx = rotx + pad[i]
       roty = roty + pad[i]
       sxaddpar,mphdr,pp+'XRPAD'+ct, pad[i],'X padding before rotation'
       sxaddpar,mphdr,pp+'YRPAD'+ct, pad[i],'Y padding before rotation'
     endif

     ; is a pixel scale correction to be applied?
     if xpscl[i] ne 1.0 or ypscl[i] ne 1.0 then begin
       newxsz = float(xsiz[i] + 2 * pad[i]) * xpscl[i]
       newysz = float(ysiz[i] + 2 * pad[i]) * ypscl[i]
       mdata = congrid(mdata, newxsz, newysz, cubic=-0.5)
       mmask = congrid(mmask, newxsz, newysz, cubic=-0.5)
       newsz = size(mdata)
       rotx = rotx * xpscl[i]
       roty = roty * ypscl[i]
       if zoomflux eq 1 then mdata = mdata/(xpscl[i]*ypscl[i])
       sxaddpar,mphdr,pp+'XPSCL'+ct,xpscl[i],$
	 'X Pixel Scale Factor Final Data'
       sxaddpar,mphdr,pp+'YPSCL'+ct,ypscl[i],$
	 'Y Pixel Scale Factor Final Data'
     endif

     ; Zoom it.  Don't worry about zooming if the zoom is close to one.
     zms = [0.50, 0.333, 0.25, 0.20, 0.10]
     facts = [2, 3, 4, 5, 10]
     if (abs(zoom[i] - 1.0) gt .00001) then begin
       match = -1
       for j = 0, n_elements(zms)-1 do begin
         if abs(zoom[i] - zms[j]) le 0.01 then match = j
       endfor
       ;if match gt -1 then image is being dezoomed an integral amount
       if match gt -1 then begin
         xsz = fix((xsiz[i] + 2.0 * pad[i]) * xpscl[i] * zoom[i])
         ysz = fix((ysiz[i] + 2.0 * pad[i]) * ypscl[i] * zoom[i])
         zscl = 1.0 / (facts[match]^2)
         mds = fltarr(xsz,ysz)
	 nmsk = intarr(xsz,ysz)
         CASE mddz of

	   0: begin
	     for j = 0, ysz-1 do begin
	       for jj = 0, xsz-1 do begin
		 pz = facts[match]
		 mds[jj,j]=total(mdata[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1])*zscl
		 nmsk[jj,j]=total(mmask[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1])*zscl
               endfor
             endfor
	     end

	   1: begin
	     for j = 0, ysz-1 do begin
	       for jj = 0, xsz-1 do begin
	 	 pz = facts[match]
		 mds[jj,j]=$
		   median(mdata[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1],/even)
                 nmsk[jj,j] = $
		   median(mmask[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1],/even)
               endfor
             endfor
	     end
          
	   2: begin
	     for j = 0, ysz-1 do begin
	       for jj = 0, xsz-1 do begin
	  	 pz = facts[match]
		 mds[jj,j]=max(mdata[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1])
		 nmsk[jj,j]=max(mmask[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1])
               endfor
             endfor
	     end
	  
	   3: begin
	     for j = 0, ysz-1 do begin
	       for jj = 0, xsz-1 do begin
		 pz = facts[match]
		 mds[jj,j]=min(mdata[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1])
		 nmsk[jj,j]=min(mmask[jj*pz:(jj+1)*pz-1,j*pz:(j+1)*pz-1])
               endfor
             endfor
	     end

           else:
	   endcase
       endif else begin
         ; Check interpolation type and zoom accordingly, default to bicubic.
	 newxsiz = (xsiz[i] + 2.0 * pad[i]) * xpscl[i] * zoom[i]
	 newysiz = (ysiz[i] + 2.0 * pad[i]) * ypscl[i] * zoom[i]
         mds = idp3_congrid(mdata, newxsiz, newysiz, zoom[i], mdioz, pixorg) 
         nmsk = idp3_congrid(mmask, newxsiz, newysiz, zoom[i], mdioz, pixorg) 
       endelse
     endif else begin
       mds = mdata   ; Zoom is one, just copy the data.
       nmsk = mmask
     endelse
     mdata = 0
     mmask = 0
     rotx = rotx * zoom[i]
     roty = roty * zoom[i]
     sxaddpar, mphdr, pp+'ZOOM'+ct, zoom[i], 'Data image zoom'
  
     ; The user wants to conserve total flux, divide by square of zoom.
     if zoomflux eq 1 then begin
       mds = mds/(zoom[i] * zoom[i]) 
       sxaddpar, mphdr, 'HISTORY', 'Flux is conserved - data/zoom^2'
     endif

     ; Do rotations, if necessary.
     if abs(rot[i]) gt .0001 then begin
       mds = idp3_rot(mds, rot[i], 1.0, rotx, roty, /pivot, cubic=-0.5, $
 	 missing=0.0, pixdef=pixorg)
       nmsk = idp3_rot(nmsk, rot[i], 1.0, rotx, roty, /pivot, cubic=-0.5, $
 	 missing=0.0, pixdef=pixorg)
       sxaddpar,mphdr,pp+'ROT'+ct,rot[i],'data image rotation'
       sxaddpar,mphdr,pp+'ROTX'+ct,rotx, 'data image rotation X center'
       sxaddpar,mphdr,pp+'ROTY'+ct,roty, 'data image rotation Y center'
     endif

     ; Do fractional pixel shifts.  Don't do it if the fraction is too small.
     if (abs(xpoff[i]) gt .0001 or abs(ypoff[i]) gt .0001) then begin
       sz = size(mds)
       x = findgen(sz(1))-xpoff[i]
       y = findgen(sz(2))-ypoff[i]
       mds = interpolate(mds,x,y,cubic=-.5,/grid)      ; bicubic
       nmsk = interpolate(nmsk,x,y,cubic=-.5,/grid)      ; bicubic
     endif

     ; Scale it.
     if (abs(scl[i] - 1.0) gt .0001) then begin
       mds = mds * scl[i]
       sxaddpar,mphdr,pp+'SCL'+ct,scl[i],'data image multiplier'
     endif

     ; Apply bias.
     if (bias[i] NE 0.0) then begin
       mds = mds + bias[i]
       sxaddpar,mphdr,pp+'BIAS'+ct,bias[i],'bias applied to data'
     endif
     
     xo = float(xoff[i]) + xpoff[i]
     yo = float(yoff[i]) + ypoff[i]
     sxaddpar,mphdr,pp+'XOFF'+ct,xo,'data image X offset'
     sxaddpar,mphdr,pp+'YOFF'+ct,yo,'data image Y offset'

     xsz = (xsiz[i] + 2 * pad[i]) * zoom[i] * xpscl[i]
     ysz = (ysiz[i] + 2 * pad[i]) * zoom[i] * ypscl[i]

     idp3_checkbounds,maxx,maxy,xsz,ysz,xoff[i],yoff[i],dxmin,dxmax,dymin, $
      		       dymax,gxmin,gxmax,gymin,gymax,err

     outbound = 0
     if err eq -1 then begin
       test = widget_message(' X offset out of bounds')
       outbound = 1
     endif
     if err eq -2 then begin
       test = widget_message(' Y offset out of bounds')
       outbound = 1
     endif
     if outbound eq 0 then begin
       data[gxmin:gxmax,gymin:gymax,i] = $
	             mds[dxmin:dxmax,dymin:dymax]
       mask[gxmin:gxmax,gymin:gymax,i] = $
	             nmsk[dxmin:dxmax,dymin:dymax]
     endif
   endfor
   close, lun
   free_lun, lun
 endif
end
