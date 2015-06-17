pro idp3_cwgtmoment, img, x, y, xcen, ycen, halfbox, coords, autocen
;	Computes the centroid coordinates of a stellar object 
;       This routine is modeled after the CNTRD procedure in
;       the astron library.  It was modified to use a specified
;       box size instead of fwhm.  The user may also constrain the
;       box about the given center to control the data that is fit.
;
 
 sz_image = size(img)
 if sz_image[0] NE 2 then begin
   print, 'ERROR - Image array (first parameter) must be 2 dimensional'
   xcen = -1  & ycen = -1
   return
 endif

 xsize = sz_image[1]
 ysize = sz_image[2]
 dtype = sz_image[3]              ;Datatype

;   Compute size of box needed to compute centroid

 nbox = 2 * halfbox + 1       ;Width of box to be used to compute centroid
 npts = N_elements(x) 
 xcentroid = fltarr(npts)  & ycentroid = xcentroid
 xcen = float(x) & ycen = float(y)
 ix = fix( x + 0.5 )          ;Central X pixel        ;Added 3/93
 iy = fix( y + 0.5 )          ;Central Y pixel
 coords = fltarr(4)
 coords[*] = 0.

 for i = 0,npts-1 do begin        ;Loop over X,Y vector

   pos = strtrim(x[i],2) + ' ' + strtrim(y[i],2)
   xl = x[i] - halfbox
   if xl lt 0 then begin
     print, 'Center too close to left edge'
     xcen[i]=-1 & ycen[i]=-1
     return
   endif
   xr = x[i] + halfbox
   if xr GT xsize-1 then begin
     print, 'Input center too close to right edge'
     xcen[i]=-1 & ycen[i]=-1
     return
   endif
   yb = y[i] - halfbox
   if yb lt 0 then begin
     print, 'Input center too close to bottom edge'
     xcen[i]=-1 & ycen[i]=-1
     return
   endif
   yt = y[i] + halfbox
   if yt gt ysize-1 then begin
     print, 'Input center too close to top edge'
     xcen[i]=-1 & ycen[i]=-1
     return
   endif

   box = img[xl:xr,yb:yt]
   
   if autocen eq 1 then begin
;    Locate maximum pixel in 'BIG' sized subimage 
     mx = max(box, mx_pos)  	;Maximum pixel value in BOX
     idx = mx_pos mod nbox  	;X coordinate of Max pixel
     idy = mx_pos / nbox 		;Y coordinate of Max pixel
     xmax = x[i] - halfbox + idx  ;X coordinate in original image array
     ymax = y[i] - halfbox + idy  ;Y coordinate in original image array
   endif else begin
     xmax = x[i]
     ymax = y[i]
   endelse

;  Extract smaller 'STRBOX' sized subimage centered on maximum pixel 
   strbox = img[xmax-halfbox:xmax+halfbox, ymax-halfbox:ymax+halfbox] 
   if dtype LT 3 then strbox = long(strbox)

   ir = (halfbox-1) > 1 
   dd = indgen(nbox-1) + 0.5 - halfbox

;  Weighting factor W unity in center, 0.5 at end, and linear in between 
   w = 1. - 0.5*(abs(dd)-0.5)/(halfbox-0.5) 
   sumc   = total(w)

;  Find X centroid
;  Shift in X & subtract to get derivative
;  Don't want edges of the array
;  Sum X derivatives over Y direction
   deriv = shift(strbox,-1,0) - strbox 	
   deriv = deriv[0:nbox-2,halfbox-ir:halfbox+ir] 
   deriv = total( deriv, 2 )
   sumd   = total( w*deriv )
   sumxd  = total( w*dd*deriv )
   sumxsq = total( w*dd^2 )

;  Reject if X derivative not decreasing
   if sumxd GT 0 then begin 
     print, 'X derivative not decreasing,', $
  	    'unable to compute X Centroid around position ', pos
     xcen[i]=-1 & ycen[i]=-1
     return
   endif 

;  Reject if centroid outside box
   dx = sumxsq*sumd/(sumc*sumxd)
   if ( abs(dx) GT halfbox ) then begin 
     print, $
       'Computed X centroid for position '+ pos + ' out of range'
     xcen[i]=-1 & ycen[i]=-1 
     return
   endif
;  X centroid in original array
   xcen[i] = xmax - dx 

;  Find Y Centroid
   deriv = shift(strbox,0,-1) - strbox
   deriv = deriv[halfbox-ir:halfbox+ir,0:nbox-2]
   deriv = total( deriv,1 )
   sumd =   total( w*deriv )
   sumxd =  total( w*deriv*dd )
   sumxsq = total( w*dd^2 )

;  Reject if Y derivative not decreasing
   if (sumxd GT 0) then begin 
     print, 'Y derivative not decreasing, ', $
       'Unable to compute Y centroid around position '+ pos
     xcen[i] = -1   & ycen[i] = -1
     return
   endif

;  Reject if computed Y centroid outside box
   dy = sumxsq*sumd/(sumc*sumxd)
   if (abs(dy) GT halfbox) then begin 
     print, $
       'Computed X centroid for position '+ pos + ' out of range'
     xcen[i]=-1 & ycen[i]=-1
     return
   endif 
   ycen[i] = ymax-dy
   coords = [xmax-halfbox, xmax+halfbox, ymax-halfbox, ymax+halfbox]

   endfor
 return
 end

pro idp3_rpcentroid, event
@idp3_errors

  ;forward_function mpfit2dpeak_gauss

  Widget_Control,event.top, Get_UValue = roiinfo
  Widget_control,roiinfo.idp3Window,Get_UValue=info

  roi = *info.roi
  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend
  zoom = roi.roizoom
  Widget_Control, info.rpxcentxt, Get_Value=temp
  xc = float(temp[0])
  xcen = (xc - x1) * zoom
  (*info.rprf).sx = xc
  roi.radxcent = xcen
  info.cent.sx = xcen
  Widget_Control, info.rpycentxt, Get_Value=temp
  yc = float(temp[0])
  ycen = (yc - y1) * zoom
  (*info.rprf).sy = yc
  roi.radycent = ycen
  info.cent.sy = ycen
  setcflags, (*info.roi).cmethod, info.doirs, wm, gf, cwm, ifp
  if wm eq 0 and gf eq 0 and cwm eq 0 and ifp eq 0 then begin
    stat = widget_message('Must select method before centroiding')
    return
  endif
  if ifp eq 1 then begin
    idp3_irs, info=info, /fpm
    return
  endif
  coords = fltarr(4)
  coords[*] = 0.
  if  wm eq 1 or gf eq 1 then begin
    Widget_Control, info.rpfwhmtxt, Get_Value=temp
    if temp[0] eq ' ' then fwhm = 0. else fwhm = float(temp[0])
    if fwhm lt 0.5 then begin
      test = Widget_Message('Must define FWHM before centroiding!')
      return
    endif else info.cent.fwhm = fwhm
  endif
  if cwm eq 1 then begin
    Widget_Control, info.rpwmhbtxt, Get_Value=temp
    if temp[0] eq ' ' then halfbox = 0. else halfbox = float(temp[0])
    if halfbox lt 0.5 then begin
      test = Widget_Message('Must define Half Box Size for Weighted Moment!')
      return
    endif else begin
      info.cent.halfbox = halfbox
    endelse
  endif
  ; Get the ROI array, zoom it appropriately.
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = info.roiioz
  pwcs = 0
  if info.show_wcs gt 0 then begin   ; set up updated world coordinates
    if ptr_valid((*info.images)[info.moveimage]) then begin
      imptr = (*info.images)[info.moveimage]
      if (*imptr).vis eq 1 then tmphdr = idp3_setcoords(*imptr,pwcs)
    endif 
  endif
  ; Calculate the centroid position.
  if wm eq 1 then begin
    fwhm = info.cent.fwhm * zoom
    radwm = fix(fwhm * 0.637) > 2
    radwm = float(radwm) / zoom
    tiim = idp3_congrid((*info.dispim)[x1:x2,y1:y2], xsize, ysize, $
         zoom,ztype,info.pixorg)
    if info.zoomflux eq 1 then tiim[*,*] = tiim[*,*]/(*info.roi).roizoom ^ 2
    idp3_cntrd,tiim,info.cent.sx,info.cent.sy,xcen,ycen,fwhm,coords
    if xcen lt 0. or ycen lt 0. then begin
      print, 'unable to fit'
      return
    endif
    ncoords = fltarr(4)
    ncoords[0] = coords[0] / zoom + x1
    ncoords[1] = coords[1] / zoom + x1
    ncoords[2] = coords[2] / zoom + y1
    ncoords[3] = coords[3] / zoom + y1
;    print, 'Centroid coordinates: ', ncoords
    (*info.roi).wmcoords = ncoords
    (*info.roi).radxcent = xcen
    (*info.roi).radycent = ycen
    (*info.roi).centfit = 1
    xc = xcen/roi.roizoom + roi.roixorig 
    yc = ycen/roi.roizoom + roi.roiyorig
    (*info.rprf).sx = xc
    (*info.rprf).sy = yc
    xcstr = strmid(strtrim(string(xc,'$(f12.5)'),2),0,10)
    Widget_Control, info.rpxcentxt, Set_Value = xcstr
    ycstr = strmid(strtrim(string(yc,'$(f12.5)'),2),0,10)
    Widget_Control, info.rpycentxt, Set_Value = ycstr
    info.cent.wmx = xc
    info.cent.wmy = yc
    info.cent.errwmx = 0.
    info.cent.errwmy = 0.
    if pwcs eq 0 then begin
      print, 'Weighted Moment solution: ', xc, yc  
    endif else begin
      xyad, tmphdr, float(xc), float(yc), xra, xdec
      if info.show_wcs eq 1 then begin
	idp3_conra, xra/15.0, rastr
	idp3_condec, xdec, decstr
      endif else begin
	rastr = string(xra,'$(f12.7)')
	decstr = string(xdec,'$(f12.7)')
      endelse
      print, 'Weighted Moment solution: ', xc, yc 
      print, 'WCS: ', '  ra: ', rastr, '  dec:', decstr
    endelse
    print, 'Radius for weighted moment: ', radwm
    if gf eq 0 then begin
      perror = fltarr(8)
      perror[*] = 0.
    endif
    tiim = 0
  endif
  if gf eq 1 then begin
    fwhm = info.cent.fwhm * zoom
    gzoom = zoom
    Widget_Control, info.rpradiustxt, Get_Value=temp
    rad = float(temp[0])
    zrad = rad * gzoom
    gxcen = (xc - x1) * gzoom
    gycen = (yc - y1) * gzoom
    gxsize = (abs(x2-x1)+1) * gzoom
    gysize = (abs(y2-y1)+1) * gzoom
    gtiim = idp3_congrid((*info.dispim)[x1:x2,y1:y2], gxsize, gysize, $
	 gzoom,ztype,info.pixorg)
    if info.zoomflux eq 1 then gtiim[*,*] = gtiim[*,*]/gzoom ^ 2
    galphaim = congrid((*info.alphaim)[x1:x2,y1:y2], gxsize, gysize)
    moveim = info.moveimage
    numimages = n_elements(*info.images)
    use_wgts = 0
    ;*******************************************************************
    ;special code for weighting the gaussian fit
    if ptr_valid((*(*info.images)[moveim]).wgts) and $
      (*(*info.images)[moveim]).vis eq 1 then begin
      wgts = *(*(*info.images)[moveim]).wgts
      print, 'Weighting data by weight image'
      wsz = size(wgts)
      if wsz[0] ne 2 then begin
	use_wgts = 0
      endif else begin
        use_wgts = 1
        for i = 0, numimages-1 do begin
          if i ne moveim and (*(*info.images)[i]).vis eq 1 then begin
	    print, 'Too many images on to use weights'
	    use_wgts = 0
          endif
        endfor
        if use_wgts eq 1 then begin
	  galphaim = idp3_congrid(wgts[x1:x2,y1:y2], $
		   gxsize, gysize, gzoom, ztype, info.pixorg)
;          if info.zoomflux eq 1 then galphaim = galphaim/gzoom^2
        endif
      endelse
    endif
    ;***************************************************************************
    tmp = intarr(xsize, ysize)
    tmp[*,*] = 1
    if roi.msk eq 1 then begin
      xoff = roi.msk_xoff
      yoff = roi.msk_yoff
      goodval = roi.maskgood
      tmpmsk = idp3_roimask(x1, x2, y1, y2, *(roi.mask), xoff, yoff, goodval)
      roimask = congrid(tmpmsk, gxsize, gysize)
      bad = where(roimask ne goodval, cnt)
      if cnt gt 0 then tmp[bad] = 0
      tmpmsk = 0
      roimask = 0
      bad = 0
      tmpbad = where(tmp eq 0, tcnt)
      if tcnt gt 0 then galphaim(tmpbad) = 0.
      tmpbad = 0
    endif
    xg1 = Round(gxcen - zrad) > 0
    xg2 = Round(gxcen + zrad) < (gxsize-1)
    yg1 = Round(gycen - zrad) > 0
    yg2 = Round(gycen + zrad) < (gysize-1)
    fitcircle = info.cent.fitcircle
    if fitcircle eq 1 then begin
      gmask = fltarr(gxsize, gysize)
      gmask[*,*] = 1.
      thresh = 0.85
      nang = 361
      mpol = 1
      idp3_photcircle,gmask,tmp,nang,thresh,rad,zrad,gxcen,gycen,mpol, $
         nbad, gxsize,gysize
      dontfit = where(gmask lt 0.50, dfcnt)
      if dfcnt gt 0 then galphaim(dontfit) = 0.0
      excl = where(gmask[xg1:xg2,yg1:yg2] lt 0.50, exccnt)
      print, exccnt, ' pixels masked between circle and square
      dontfit = 0
      excl = 0
      gmask = 0
    endif
    if use_wgts eq 0 then begin
      maxwgt = max(sqrt(galphaim))
      galphaim = sqrt(galphaim)/maxwgt
    endif
    fittedpix = where(galphaim[xg1:xg2,yg1:yg2] gt 0., tofitcnt)
    print, tofitcnt, ' pixels fit'
    fitdata = gtiim[xg1:xg2,yg1:yg2]
    tmpalpha = galphaim[xg1:xg2,yg1:yg2]
    if use_wgts eq 0 then begin
      rm1 = moment(fitdata[where(tmpalpha gt 0.)])
      fmin = min(fitdata)
      fminloc = where(fitdata eq fmin)
      tmpalpha[fminloc] = 0.
      rm2 = moment(fitdata[where(tmpalpha gt 0.)])
      if sqrt(rm1[1])/sqrt(rm2[1]) ge 7.5 then begin
        fitalpha = tmpalpha 
        print, 'minimum: ', fmin, ' excluded from fit'
      endif else fitalpha = galphaim[xg1:xg2, yg1:yg2]
    endif else fitalpha = galphaim[xg1:xg2, yg1:yg2]
    gfwhm = info.cent.fwhm * gzoom
    start = fltarr(8)
    fmax = max(gtiim[gxcen-1:gxcen+1,gycen-1:gycen+1])
    if gtiim[gxcen,gycen] lt fmax*0.5 then begin
      start[1]=fmax
      print, 'Resetting gaussian height from ', gtiim[gxcen,gycen],' to ',fmax
    endif else start[1] = gtiim[gxcen,gycen]
    start[2] = gfwhm / 2.534
    start[3] = gfwhm / 2.534
    start[4] = gxcen - xg1
    start[5] = gycen - yg1
    yfit = mpfit2dpeak(fitdata, aa, estimates=start, $
	   perror=perror, weights=fitalpha, bestnorm=bestnorm, /tilt)
;    xrr = indgen(gxsize)
;    ycc = indgen(ysize)
;    xx = xrr # (ycc * 0 + 1)
;    yy = (xrr * 0 + 1) # ycc
;    pp = aa
;    pp[4] = pp[4] + xg1
;    pp[5] = pp[5] + yg1
;    yfitp = mpfit2dpeak_gauss(xx, yy, pp, /tilt)
;    yfit = gauss2dfit(fitdata, aa, /tilt)
    xcp = (aa[4]+xg1)/gzoom + x1
    ycp = (aa[5]+yg1)/gzoom + y1
    info.cent.gfx = xcp
    info.cent.gfy = ycp
    dof = n_elements(fitdata) - n_elements(start)
    scf = sqrt(bestnorm / float(dof))
    info.cent.errgfx = perror[4] * scf
    info.cent.errgfy = perror[5] * scf
    info.cent.fwhmx = (aa[2]*2.354) / gzoom
    info.cent.errgfwhmx = perror[2] * scf
    info.cent.fwhmy = (aa[3]*2.354) / gzoom
    info.cent.errgfwhmy = perror[3] * scf
    info.cent.theta = aa[6] * (180.0d0/!dpi)
    info.cent.errgtheta = perror[6] * scf * (180.0d0/!dpi)
    if pwcs eq 0 then begin
      print, 'Gauss Fit Solution: ', xcp, ycp
    endif else begin
      xyad, tmphdr, float(xcp), float(ycp), xra, xdec
      if info.show_wcs eq 1 then begin
        idp3_conra, xra/15.0, rastr
        idp3_condec, xdec, decstr
      endif else begin
        rastr = string(xra,'$(f12.7)')
	decstr = string(xdec,'$(f12.7)')
      endelse
      print, 'Gauss Fit Solution: ', xcp, ycp
      print, 'WCS: ', '  ra: ', rastr, '  dec:', decstr
    endelse
    print, 'Input radius for gaussian: ', rad
    if ptr_valid(info.rpgaussim1) then ptr_free, info.rpgaussim1
    if ptr_valid(info.rpgaussim2) then ptr_free, info.rpgaussim2
    info.rpgaussim1 = ptr_new(fitdata)
    info.rpgaussim2 = ptr_new(yfit)
    if gf eq 1 and wm eq 0 then begin
      (*info.roi).radxcent = (aa[4] + xg1) * (zoom/gzoom)
      (*info.roi).radycent = (aa[5] + yg1) * (zoom/gzoom)
      (*info.roi).centfit = 1
      (*info.rprf).sx = xcp
      (*info.rprf).sy = ycp
      xcpstr = strmid(strtrim(string(xcp,'$(f12.5)'),2),0,10)
      Widget_Control, info.rpxcentxt, Set_Value = xcpstr
      ycpstr = strmid(strtrim(string(ycp,'$(f12.5)'),2),0,10)
      Widget_Control, info.rpycentxt, Set_Value = ycpstr
    endif
    gtiim = 0
    galphaim = 0
    tmp = 0
    fittedpix = 0
    fitdata = 0
    tmpalpha = 0
    fitalpha = 0
    yfit = 0
;    yfitp = 0
  endif
  if cwm eq 1 then begin
    hb = info.cent.halfbox * zoom
    autocen = info.cent.autocenter
    tiim = idp3_congrid((*info.dispim)[x1:x2,y1:y2], xsize, ysize, $
         zoom,ztype,info.pixorg)
    if info.zoomflux eq 1 then tiim[*,*] = tiim[*,*]/(*info.roi).roizoom ^ 2
    idp3_cwgtmoment,tiim,info.cent.sx,info.cent.sy,xcen,ycen,hb,coords,autocen
    if xcen lt 0. or ycen lt 0. then begin
      print, 'unable to fit'
      return
    endif
    ncoords = fltarr(4)
    ncoords[0] = coords[0] / zoom + x1
    ncoords[1] = coords[1] / zoom + x1
    ncoords[2] = coords[2] / zoom + y1
    ncoords[3] = coords[3] / zoom + y1
;    print, 'Centroid coordinates: ', ncoords
    (*info.roi).wmcoords = ncoords
    (*info.roi).radxcent = xcen
    (*info.roi).radycent = ycen
    (*info.roi).centfit = 1
    xc = xcen/roi.roizoom + roi.roixorig 
    yc = ycen/roi.roizoom + roi.roiyorig
    (*info.rprf).sx = xc
    (*info.rprf).sy = yc
    xcstr = strmid(strtrim(string(xc,'$(f12.5)'),2),0,10)
    Widget_Control, info.rpxcentxt, Set_Value = xcstr
    ycstr = strmid(strtrim(string(yc,'$(f12.5)'),2),0,10)
    Widget_Control, info.rpycentxt, Set_Value = ycstr
    info.cent.cwmx = xc
    info.cent.cwmy = yc
    info.cent.errcwmx = 0.
    info.cent.errcwmy = 0.
    if pwcs eq 0 then begin
      print, 'Constrained Weighted Moment solution: ', xc, yc 
    endif else begin
      xyad, tmphdr, float(xc), float(yc), xra, xdec
      if info.show_wcs eq 1 then begin
        idp3_conra, xra/15.0, rastr
        idp3_condec, xdec, decstr
      endif else begin
        rastr = string(xra,'$(f12.7)')
        decstr = string(xdec,'$(f12.7)')
      endelse
      print, 'Constrained Weighted Moment solution: ', xc, yc 
      print, 'WCS: ', '  ra: ', rastr, '  dec:', decstr
    endelse
    print, 'Input radius for constrained weighted moment: ', info.cent.halfbox
    tiim = 0
  endif

;  print, cwm, info.cent.cwmx, info.cent.cwmy

  ; define centroid values to save in image headers
  if wm eq 1 then begin
    xf = info.cent.wmx
    yf = info.cent.wmy
  endif else if gf eq 1 then begin
    xf = info.cent.gfx
    yf = info.cent.gfy
  endif else if cwm eq 1 then begin
    xf = info.cent.cwmx
    yf = info.cent.cwmy
  endif

  ; Update the Last Centroid Center for all images that are 'on'.
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then begin
      (*(*info.images)[i]).lccx = xf
      (*(*info.images)[i]).lccy = yf
      img = (*info.images)[i]
      olcc = idp3_getolcc(img, xf, yf, info.sxoff, info.syoff)
      (*(*info.images)[i]).olccx = olcc[0]
      (*(*info.images)[i]).olccy = olcc[1]
    endif
  endfor

  ; Load this value into the radial profile center and
  ; update the radial profile.

  Widget_control,roiinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=info
  wset,info.drawid1
  Idp3_Display,info
end

