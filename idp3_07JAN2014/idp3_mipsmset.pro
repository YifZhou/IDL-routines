pro idp3_mipsmset, pp, info, data, mask, mphdr, mihdr 
@idp3_structs
@idp3_errors

 data = 0
 mask = 0
 mphdr = ['','']
 mihdr = ['','']

 ims = (*info.images)
 pixorg = info.pixorg
 mdioz = info.mdioz
 mddz = info.mddz
 zoomflux = info.zoomflux
 moveim = info.moveimage
 numimages = n_elements(ims)

 maxx = 0
 maxy = 0
 numon = 0
 for i = 0, numimages-1 do begin
   if (*ims[i]).vis eq 1 then begin
     x2 = ((*ims[i]).xsiz + 2 * (*ims[i]).pad) * (*ims[i]).xpscl * $
	  (*ims[i]).zoom + (*ims[i]).xoff
     y2 = ((*ims[i]).ysiz + 2 * (*ims[i]).pad) * (*ims[i]).ypscl * $
	  (*ims[i]).zoom + (*ims[i]).yoff
     if x2 gt maxx then maxx = fix(x2)
     if y2 gt maxy then maxy = fix(y2)
     numon = numon + 1
   endif
 endfor
 mphdr = *(*ims[moveim]).phead
 mihdr = *(*ims[moveim]).ihead
 if info.sfits eq 1 then begin
   if n_elements(mihdr) gt 2 then begin
     sxdelpar, mphdr, 'NEXTEND'
     sxdelpar, mphdr, 'END'
     sxdelpar, mihdr, 'XTENSION'
     sxdelpar, mihdr, 'INHERIT'
     sxdelpar, mihdr, 'EXTNAME'
     sxdelpar, mihdr, 'EXTVER'
     sxdelpar, mihdr, 'EXTLEVEL'
     sxdelpar, mihdr, 'BITPIX'
     sxdelpar, mihdr, 'NAXIS'
     sxdelpar, mihdr, 'NAXIS1'
     sxdelpar, mihdr, 'NAXIS2'
     sxdelpar, mihdr, 'GCOUNT'
     mphdr = [mphdr, mihdr]
     sxaddpar, mphdr, 'NAXIS', 2
     sxaddpar, mphdr, 'NAXIS1', x2, AFTER='NAXIS'
     sxaddpar, mphdr, 'NAXIS2', y2, AFTER='NAXIS1'
   endif
 endif
 data = fltarr(maxx, maxy, numon)
 data[*,*,*] = 0.0
 mask = intarr(maxx, maxy, numon)
 mask[*,*,*] = 0
 dispf = intarr(numon)
 indx = 0
 for i = 0, numimages-1 do begin
   if (*ims[i]).vis eq 1 then begin
     ct = string(format='(I2.2)',indx)
     sxaddpar, mphdr, pp+'IMAGE'+ct, (*ims[i]).orgname, 'data image'
     if (*ims[i]).extver ge 0 then begin
       hstr = 'Read number: ' + strtrim(string((*ims[i]).extver),2)
       sxaddpar, mphdr, 'HISTORY', hstr
     endif

     dispf(indx) = (*ims[i]).dispf
     rotx = (*ims[i]).rotcx
     roty = (*ims[i]).rotcy
     tempmask = intarr((*ims[i]).xsiz, (*ims[i]).ysiz)
     tempmask[*,*] = 1

     tempdata = *(*ims[i]).data
     ; Should data be clipped
     ; is lower flag set
     if (*ims[i]).clipbottom eq 1 then begin
       d = where(tempdata lt (*ims[i]).clipmin, bcount)
       if bcount gt 0 then begin
         str = string(bcount) + ' minimum pixels reset to ' + $
	   string((*ims[i]).cminval)
         sxaddpar, mphdr, 'HISTORY', str
         tempdata(d) = (*ims[i]).cminval
       endif
     endif

     ; is upper flag set
     if (*ims[i]).cliptop eq 1 then begin
       d = where(tempdata gt (*ims[i]).clipmax, tcount)
       if tcount gt 0 then begin
         str = string(tcount) + ' maximum pixels reset to ' + $
	       string((*ims[i]).cmaxval)
         sxaddpar, mphdr, 'HISTORY', str
         tempdata[d] = (*ims[i]).cmaxval
       endif
     endif
     
     ; Should the Y axis be flipped?
     if (*ims[i]).flipy eq 1 then begin
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
     if (*ims[i]).pad gt 0 then begin
       txsiz = (*ims[i]).xsiz + 2 * (*ims[i]).pad
       tysiz = (*ims[i]).ysiz + 2 * (*ims[i]).pad
       tdata = fltarr(txsiz, tysiz) 
       tdata[*,*] = 0.
       tmask = intarr(txsiz, tysiz)
       tmask[*,*] = 0
       xbeg = (*ims[i]).pad
       ybeg = (*ims[i]).pad
       xend = xbeg + (*ims[i]).xsiz - 1
       yend = ybeg + (*ims[i]).ysiz - 1
       tdata[xbeg:xend,ybeg:yend] = mdata
       tmask[xbeg+1:xend-1,ybeg+1:yend-1] = mmask[1:xend-xbeg-1,1:yend-ybeg-1]
       mdata = tdata
       mmask = tmask
       tdata = 0
       tmask = 0
       rotx = rotx + (*ims[i]).pad
       roty = roty + (*ims[i]).pad
       sxaddpar,mphdr,pp+'XRPAD'+ct, (*ims[i]).pad,'X padding before rotation'
       sxaddpar,mphdr,pp+'YRPAD'+ct, (*ims[i]).pad,'Y padding before rotation'
     endif

     ; is a pixel scale correction to be applied?
     if (*ims[i]).xpscl ne 1.0 or (*ims[i]).ypscl ne 1.0 then begin
       newxsz = float((*ims[i]).xsiz + 2 * (*ims[i]).pad) * (*ims[i]).xpscl
       newysz = float((*ims[i]).ysiz + 2 * (*ims[i]).pad) * (*ims[i]).ypscl
       mdata = congrid(mdata, newxsz, newysz, cubic=-0.5)
       mmask = congrid(mmask, newxsz, newysz, cubic=-0.5)
       newsz = size(mdata)
       rotx = rotx * (*ims[i]).xpscl
       roty = roty * (*ims[i]).ypscl
       if zoomflux eq 1 then mdata = mdata/((*ims[i]).xpscl*(*ims[i]).ypscl)
       sxaddpar,mphdr,pp+'XPSCL'+ct,(*ims[i]).xpscl,$
	 'X Pixel Scale Factor Final Data'
       sxaddpar,mphdr,pp+'YPSCL'+ct,(*ims[i]).ypscl,$
	 'Y Pixel Scale Factor Final Data'
     endif

     ; Zoom it.  Don't worry about zooming if the zoom is close to one.
     zms = [0.50, 0.333, 0.25, 0.20, 0.10]
     facts = [2, 3, 4, 5, 10]
     if (abs((*ims[i]).zoom - 1.0) gt .00001) then begin
       match = -1
       for j = 0, n_elements(zms)-1 do begin
         if abs((*ims[i]).zoom - zms[j]) le 0.01 then match = j
       endfor
       ;if match gt -1 then image is being dezoomed an integral amount
       if match gt -1 then begin
         xsz = fix(((*ims[i]).xsiz + 2.0 * (*ims[i]).pad) * (*ims[i]).xpscl $
	    * (*ims[i]).zoom[i])
         ysz = fix(((*ims[i]).ysiz + 2.0 * (*ims[i]).pad) * (*ims[i]).ypscl $
	    * (*ims[i]).zoom[i])
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
	 newxsiz = ((*ims[i]).xsiz + 2.0 * (*ims[i]).pad) * (*ims[i]).xpscl $
	      * (*ims[i]).zoom
	 newysiz = ((*ims[i]).ysiz + 2.0 * (*ims[i]).pad) * (*ims[i]).ypscl $
	      * (*ims[i]).zoom
         mds = idp3_congrid(mdata, newxsiz, newysiz, (*ims[i]).zoom, mdioz, $
	      pixorg) 
         nmsk = idp3_congrid(mmask, newxsiz, newysiz, (*ims[i]).zoom, mdioz, $
	      pixorg) 
       endelse
     endif else begin
       mds = mdata   ; Zoom is one, just copy the data.
       nmsk = mmask
     endelse
     mdata = 0
     mmask = 0
     rotx = rotx * (*ims[i]).zoom
     roty = roty * (*ims[i]).zoom
     sxaddpar, mphdr, pp+'ZOOM'+ct, (*ims[i]).zoom, 'Data image zoom'
  
     ; The user wants to conserve total flux, divide by square of zoom.
     if zoomflux eq 1 then begin
       mds = mds/((*ims[i]).zoom * (*ims[i]).zoom) 
       sxaddpar, mphdr, 'HISTORY', 'Flux is conserved - data/zoom^2'
     endif

     ; Do rotations, if necessary.
     if abs((*ims[i]).rot) gt .0001 then begin
       mds =idp3_rot(mds, (*ims[i]).rot, 1.0,rotx,roty,/pivot,cubic=-0.5, $
            missing=0.0, pixdef=pixorg)
       nmsk=idp3_rot(nmsk, (*ims[i]).rot, 1.0,rotx,roty,/pivot,cubic=-0.5, $
   	    missing=0.0, pixdef=pixorg)
       sxaddpar,mphdr,pp+'ROT'+ct,(*ims[i]).rot,'data image rotation'
       sxaddpar,mphdr,pp+'ROTX'+ct,rotx, 'data image rotation X center'
       sxaddpar,mphdr,pp+'ROTY'+ct,roty, 'data image rotation Y center'
     endif

     ; Do fractional pixel shifts.  Don't do it if the fraction is too small.
     if (abs((*ims[i]).xpoff) gt .0001 or abs((*ims[i]).ypoff) gt .0001) $
       then begin
       sz = size(mds)
       x = findgen(sz(1))-(*ims[i]).xpoff
       y = findgen(sz(2))-(*ims[i]).ypoff
       mds = interpolate(mds,x,y,cubic=-.5,/grid)      ; bicubic
       nmsk = interpolate(nmsk,x,y,cubic=-.5,/grid)      ; bicubic
     endif

     ; Scale it.
     if (abs((*ims[i]).scl - 1.0) gt .0001) then begin
       mds = mds * (*ims[i]).scl
       sxaddpar,mphdr,pp+'SCL'+ct,(*ims[i]).scl,'data image multiplier'
     endif

     ; Apply bias.
     if ((*ims[i]).bias NE 0.0) then begin
       mds = mds + (*ims[i]).bias
       sxaddpar,mphdr,pp+'BIAS'+ct,(*ims[i]).bias,'bias applied to data'
     endif
     
     xo = float((*ims[i]).xoff) + (*ims[i]).xpoff
     yo = float((*ims[i]).yoff) + (*ims[i]).ypoff
     sxaddpar,mphdr,pp+'XOFF'+ct,xo,'data image X offset'
     sxaddpar,mphdr,pp+'YOFF'+ct,yo,'data image Y offset'

     xsz = ((*ims[i]).xsiz + 2 * (*ims[i]).pad) * (*ims[i]).zoom * $
         (*ims[i]).xpscl
     ysz = ((*ims[i]).ysiz + 2 * (*ims[i]).pad) * (*ims[i]).zoom * $
         (*ims[i]).ypscl

     idp3_checkbounds,maxx,maxy,xsz,ysz,(*ims[i]).xoff,(*ims[i]).yoff,$
      		  dxmin,dxmax,dymin,dymax,gxmin,gxmax,gymin,gymax,err

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
       data[gxmin:gxmax,gymin:gymax,i] = mds[dxmin:dxmax,dymin:dymax]
       mask[gxmin:gxmax,gymin:gymax,i] = nmsk[dxmin:dxmax,dymin:dymax]
     endif
     indx = indx + 1
   endif
 endfor

 newdat = fltarr(maxx, maxy, numon)
 newmask = intarr(maxx, maxy, numon)
 ; now check for images (PSFs) to subtract
 indx = 0
 for i = 0, numon-2, 2 do begin
   if dispf[i] eq ADD and dispf[i+1] eq SUB then begin
     newdat[*,*,indx] = data[*,*,i] - data[*,*,i+1]
     newmask[*,*,indx] = mask[*,*,i]
     indx = indx + 1
   endif else begin
     newdat[*,*,indx] = data[*,*,i]
     newmask[*,*,indx] = mask[*,*,i]
     newdat[*,*,indx+1] = data[*,*,i+1]
     newmask[*,*,indx+1] = mask[*,*,i+1]
     indx = indx + 2
   endelse
 endfor
 if indx lt numon then begin
   data = newdat[*,*,0:indx-1]
   mask = newmask[*,*,0:indx-1]
 endif
 print, numon, '  images, ', indx, '  median combined, size= ', maxx, maxy
 newdat = 0
 newmask = 0
 return
end
