function idp3_phcalc, pinfo, dataimage, tmp, coords, preset

@idp3_structs
@idp3_errors

   Widget_Control, pinfo.info.idp3Window, Get_UValue=cinfo
    
   tnpix = 0.
   cinfo.phot.tnpix = 0.0
   tnbad = 0
   cinfo.phot.tnbad = 0
   bnpix = 0.
   cinfo.phot.bnpix = 0.0
   bnbad = 0
   cinfo.phot.bnbad = 0
   tmax = 0.0
   cinfo.phot.tmax = 0.0
   ttotal = 0.
   cinfo.phot.ttotal = 0.0
   tmedian = 0.0
   cinfo.phot.tmedian = 0.0
   trms = 0.
   cinfo.phot.trms = 0.0
   t2total = 0.
   cinfo.phot.t2total = 0.0
   t2median = 0.
   cinfo.phot.t2median = 0.0
   corrflux = 0.
   cinfo.phot.corrflux = 0.0
   bmedian = 0.
   cinfo.phot.bmedian = 0.0
   bmean = 0.
   cinfo.phot.bmean = 0.0
   brms = 0.
   cinfo.phot.brms = 0.0
   cinfo.phot.irms = 0.0
   cinfo.phot.imean = 0.0
   cinfo.phot.imedian = 0.0
   brrms = 0.
   cinfo.phot.brrms = 0.0
   brmean = 0.
   cinfo.phot.brmean = 0.0
   brmedian = 0.
   cinfo.phot.brmedian = 0.0
   sharpval = 0.
   cinfo.phot.sharpv = 0.0
   sharpval2 = 0.
   cinfo.phot.sharpv2 = 0.0
   t2npix = 0.
   t2rms = 0.
   btotal = 0.

   ; get parameters
   Widget_Control, pinfo.racenField, Get_Value = racen
   cinfo.phot.photra = racen
   Widget_Control, pinfo.deccenField, Get_Value = deccen
   cinfo.phot.photdec = deccen
   Widget_Control, pinfo.xcenField, Get_Value = sxcen
   xcen = float(sxcen[0])
   cinfo.phot.xcenter = xcen
   Widget_Control, pinfo.ycenField, Get_Value = sycen
   ycen = float(sycen[0])
   cinfo.phot.ycenter = ycen
   Widget_Control, pinfo.tradiusField, Get_Value = trad
   cinfo.phot.tradius = trad
   Widget_Control, pinfo.biradiusField, Get_Value = birad
   cinfo.phot.biradius = birad
   Widget_Control, pinfo.boradiusField, Get_Value = borad
   cinfo.phot.boradius = borad
   Widget_Control, pinfo.mthreshField, Get_Value = med_thresh
   cinfo.phot.med_thresh = med_thresh
   Widget_Control, pinfo.acorrField, Get_Value = ap_corr
   cinfo.phot.ap_corr = ap_corr
   Widget_Control, pinfo.bkgfField, Get_Value = bkg_fract
   cinfo.phot.bkg_fract = bkg_fract
   cinfo.phot.method = 'aperture'

   blnk36 = '                                    '
   blnk32 = '                                '
   blnk30 = '                              '
   blnk10 = '          '
   if preset eq 0 then begin
     Widget_Control, pinfo.tcflabel, Set_Value = blnk36
     Widget_Control, pinfo.shplabel, Set_Value = blnk30
     Widget_Control, pinfo.shpbkglabel, Set_Value = blnk32
     Widget_Control, pinfo.tnamelabel, Set_Value = blnk30
     Widget_Control, pinfo.tfluxlabel, Set_Value = blnk10
     Widget_Control, pinfo.tpixlabel, Set_Value = blnk10
     Widget_Control, pinfo.tmfluxlabel, Set_Value = blnk10
     Widget_Control, pinfo.trmslabel, Set_Value = blnk10
     Widget_Control, pinfo.btnamelabel, Set_Value = blnk30
     Widget_Control, pinfo.btfluxlabel, Set_Value = blnk10
     Widget_Control, pinfo.btmfluxlabel, Set_Value = blnk10
     Widget_Control, pinfo.btpixlabel, Set_Value = blnk10
     Widget_Control, pinfo.btrmslabel, Set_Value = blnk10
     Widget_Control, pinfo.bnamelabel, Set_Value = blnk30
     Widget_Control, pinfo.bfluxlabel, Set_Value = blnk10
     Widget_Control, pinfo.bpixlabel, Set_Value = blnk10
     Widget_Control, pinfo.bmfluxlabel, Set_Value = blnk10
     Widget_Control, pinfo.brmslabel, Set_Value = blnk10
   endif
   tstr = 'Target region cannot fall outside the ROI!'
   bstri = 'Background inner region falls outside the ROI!'
   bstro = 'Background outer region falls outside the ROI!'

   roi = *(cinfo.roi)
   x1 = coords[0]
   x2 = coords[1]
   y1 = coords[2]
   y2 = coords[3]
   zoom = roi.roizoom
   xsize = (abs(x2-x1)+1) * zoom
   ysize = (abs(y2-y1)+1) * zoom
    
   nang = 361
   thresh = 0.85

   etstr = 'Less than 2 pixels in target aperture - check radius & threshold'
   ebstr = 'Less than 2 pixels in bkg aperture - check radius & threshold'
   sharp = cinfo.phot.sharp

   if cinfo.color_bits eq 0 then begin
     vt = 200
     vbi = 200
     vbo = 200
   endif else begin
     vt = 4
     vbi = 3
     vbo = 3
   endelse

   if trad gt 0. then begin
     tledge = xcen - trad
     tredge = xcen + trad
     ttop = ycen + trad
     tbottom = ycen - trad
     if tledge lt x1 or tredge gt x2 or tbottom lt y1 or ttop gt y2 then begin
       stat = Widget_Message(tstr)
       targ = 0
       return, -1
     endif else begin
       cinfo.phot.tradius = trad
       targ = 1
       if cinfo.cent.fwhm gt 0.0 then begin
	 str = 'FWHM: ' + string(cinfo.cent.fwhm) + '  Target Radius: ' + $
	       string(trad) + '  radius/fwhm ' + string(trad/cinfo.cent.fwhm)
         idp3_updatetxt, cinfo, str
       endif
     endelse
   endif else targ = 0
   if birad gt 0. and borad gt birad then begin
     biledge = xcen - birad
     biredge = xcen + birad
     bitop = ycen + birad
     bibottom = ycen - birad
     if biledge lt x1 or biredge gt x2 or bibottom lt y1 or bitop gt y2 then $
       stat=Widget_Message(bstri)
     cinfo.phot.biradius = birad
     backgrd = 1
     boledge = xcen - borad
     boredge = xcen + borad
     botop = ycen + borad
     bobottom = ycen - borad
     if boledge lt x1 or boredge gt x2 or bobottom lt y1 or botop gt y2 then $
       stat=Widget_Message(bstro)
     cinfo.phot.boradius = borad
   endif else backgrd = 0
   if targ eq 0 and backgrd eq 0 then begin
     stat = Widget_Message('No photometry computed')
     return, -1
   endif
   if roi.msk eq 1 then begin
     xoff = roi.msk_xoff
     yoff = roi.msk_yoff
     goodval = roi.maskgood
     tmpmsk = idp3_roimask(x1, x2, y1, y2, *(roi.mask), xoff, yoff, goodval)
     roimask = congrid(tmpmsk, xsize, ysize)
     bad = where(roimask ne goodval, cnt)
     if cnt gt 0 then tmp[bad] = 0
     tmpmsk = 0
     roimask = 0
   endif
   good = where(tmp eq 1, count)
   res = moment(dataimage[good])
   cinfo.phot.irms = sqrt(res[1])
   cinfo.phot.imean = res[0]
   cinfo.phot.imedian = median(dataimage[good], /even)

   ; set up photometry regions
   wset, roi.drawid2
   zxcen = (xcen - x1) * zoom
   zycen = (ycen - y1) * zoom
   openw, qlun, 'phot.dmp', /get_lun, /append
   printf, qlun, string(zxcen,'$(f10.5)'), '  ', string(zycen,'$(f10.5)'), $
		 string(xcen,'$(f10.5)'), string(ycen,'$(f10.5)')
   close, qlun
   free_lun, qlun
   zxplot = (xcen - x1) * zoom
   zyplot = (ycen - y1) * zoom
   if cinfo.phot.shape eq 0 then begin
     th = fltarr(nang)
     for i=0, nang-1 do th(i)=float(i)*(!pi/180.)
   endif
   if backgrd eq 1 then begin
     zbir = birad * zoom
     zbor = borad * zoom
     fbmask = fltarr(xsize, ysize)
     fbmask[*,*] = 0.0
     if cinfo.phot.shape eq 0 then begin
       ; circular aperture for background 
       xe = zbor * cos(th) + zxcen
       ye = zbor * sin(th) + zycen
       ; outer circle
       mpol = 1
       idp3_photcircle,fbmask,tmp,nang,thresh,borad,zbor,zxcen, $
		    zycen, mpol, nbad, xsize,ysize
       ; inner circle
       mpol = 0
       idp3_photcircle,fbmask,tmp,nang,thresh,birad,zbir,zxcen, $
		    zycen, mpol, nbad, xsize, ysize
       plots,zbir*cos(th)+zxplot,zbir*sin(th)+zyplot,color=vbi,/device
       plots,zbor*cos(th)+zxplot,zbor*sin(th)+zyplot,color=vbo,/device
     endif else begin
       ; square aperture for background
       idp3_photsquare, tmp,zxcen,zycen,0,zbir,zbor,0,fbmask,nbad
       zboledge = zxcen - zbor
       zboredge = zxcen + zbor
       zbotop = zycen + zbor
       zbobottom = zycen - zbor
       zbiledge = zxcen - zbir
       zbiredge = zxcen + zbir
       zbibottom = zycen - zbir
       zbitop = zycen + zbir
       plots, zbiledge, zbibottom, color=vbi, /device
       plots, zbiredge, zbibottom, color=vbi, /device, /continue
       plots, zbiredge, zbitop, color=vbi, /device, /continue
       plots, zbiledge, zbitop, color=vbi, /device, /continue
       plots, zbiledge, zbibottom, color=vbi, /device, /continue
       plots, zboledge, zbobottom, color=vbo, /device
       plots, zboredge, zbobottom, color=vbo, /device, /continue
       plots, zboredge, zbotop, color=vbo, /device, /continue
       plots, zboledge, zbotop, color=vbo, /device, /continue
       plots, zboledge, zbobottom, color=vbo, /device, /continue
     endelse
     bgood = where(fbmask gt 0., bcnt)
     bmgood = where(fbmask ge med_thresh, bmcnt)
     if bcnt gt 1 then begin
       btotal = total(dataimage[bgood] * fbmask[bgood])
       bnpix = total(fbmask[bgood])
       if bmcnt gt 1 then begin
	 bmedian = median(dataimage[bmgood], /even)
	 bc = moment(dataimage[bmgood])
	 bmean = bc[0]
	 brms = SQRT(bc[1])
	 str = 'BKG: ' + string(bmcnt) + string(brms) + string(bmean) + $
	       string(bmedian)
         idp3_updatetxt, cinfo, str
       endif else begin
	 bmedian = 0.
	 bmean = 0.
	 brms = 0.
	 stat = Widget_Message(ebstr)
       endelse
       cinfo.phot.bnpix = bnpix
       cinfo.phot.bnbad = nbad
       cinfo.phot.bmedian = bmedian
       cinfo.phot.bmean = bmean
       cinfo.phot.brms = brms
       Widget_Control, pinfo.bnamelabel, Set_Value = $
		          '               Background:'
       Widget_Control, pinfo.bfluxlabel, Set_Value = strtrim(string(btotal),2)
       Widget_Control, pinfo.bpixlabel, Set_Value = strtrim(string(bnpix),2)
       Widget_Control, pinfo.bmfluxlabel, Set_Value = strtrim(string(bmedian),2)
       Widget_Control, pinfo.brmslabel, Set_Value = strtrim(string(brms),2)
       str = '                  Total       NPix    Median     RMS    Mean'
       idp3_updatetxt, cinfo, str
       str = 'Background:' + string(btotal) + string(bnpix) + $
			string(bmedian) +  string(brms) + string(bmean)
       idp3_updatetxt, cinfo, str
       dataim2 = dataimage - bmedian
     endif
     fbmask = 0
   endif  
   if targ eq 1 then begin
     ztr = trad * zoom
     ftmask = fltarr(xsize, ysize)
     ftmask[*,*] = 0.0
     ; circular aperture for target
     if cinfo.phot.shape eq 0 then begin
       mpol = 1
       idp3_photcircle,ftmask,tmp,nang,thresh,trad,ztr,zxcen, $
		      zycen, mpol, nbad, xsize, ysize
       plots, ztr*cos(th)+zxplot,ztr*sin(th)+zyplot,color=vt,/device
     endif else begin
       ; square aperture for target
       idp3_photsquare, tmp, zxcen, zycen, ztr, 0, 0, 1, ftmask,nbad
       ztledge = zxcen - ztr
       ztredge = zxcen + ztr
       ztbottom = zycen - ztr
       zttop = zycen + ztr
       plots, ztledge, ztbottom, color=vt, /device
       plots, ztredge, ztbottom, color=vt, /device, /continue
       plots, ztredge, zttop, color=vt, /device, /continue
       plots, ztledge, zttop, color=vt, /device, /continue
       plots, ztledge, ztbottom, color=vt, /device, /continue
     endelse
     tgood = where(ftmask gt 0.0, tcnt)
     tmgood = where(ftmask ge med_thresh, tmcnt)
     if tcnt gt 1 then begin
       ttotal = total(dataimage[tgood] * ftmask[tgood])
       tnpix = total(ftmask)
       tmax = max(dataimage[tgood])
       if tmcnt gt 1 then begin
         tmedian = median(dataimage[tmgood], /even)
         tc = moment(dataimage[tmgood])
         tmean = tc[0]
         trms = SQRT(tc[1])
         if backgrd eq 1 then begin
	   fbrmask = fltarr(xsize, ysize)
	   fbrmask[*,*] = 1.
           mpol = 0
           idp3_photcircle,fbrmask,tmp,nang,thresh,birad,zbir,zxcen, $
		    zycen, mpol, nbad, xsize, ysize
   	   brmgood = where(fbrmask ge med_thresh, brmcnt)
	   if brmcnt gt 1 then begin
	     res = moment(dataimage[brmgood])
	     cinfo.phot.brrms = sqrt(res[1])
	     cinfo.phot.brmean = res[0]
	     cinfo.phot.brmedian = median(dataimage[brmgood], /even)
	     str = 'BRR: ' + string(brmcnt) + string(cinfo.phot.brrms) + $
	         string(cinfo.phot.brmean) + string(cinfo.phot.brmedian)
             idp3_updatetxt, cinfo, str
           endif else begin
	     cinfo.phot.brrms = 0.
	     cinfo.phot.brmean = 0.
	     cinfo.phot.brmedian = 0.
	     stat = Widget_Message(ebstr)
           endelse
         endif
       endif else begin
	 cinfo.phot.brrms = 0.
	 cinfo.phot.brmean = 0.
	 cinfo.phot.brmedian = 0.
       endelse
      endif else begin
        tmedian = 0.
        tmean = 0.
        trms = 0.
        stat = Widget_Message(etstr)
      endelse

      tnpix = total(ftmask[tgood])
      str = '                  Total         NPix      Median         RMS'
      idp3_updatetxt, cinfo, str
      str = '    Target:' + string(ttotal) + string(tnpix) + $
		string(tmedian) + string(trms)
      idp3_updatetxt, cinfo, str
      Widget_Control, pinfo.tnamelabel, Set_Value = $
	          '                   Target:'
      Widget_Control, pinfo.tfluxlabel, Set_Value = strtrim(string(ttotal),2)
      Widget_Control, pinfo.tpixlabel, Set_Value = strtrim(string(tnpix),2)
      Widget_Control, pinfo.tmfluxlabel, Set_Value = strtrim(string(tmedian),2)
      Widget_Control, pinfo.trmslabel, Set_Value = strtrim(string(trms),2)
      if sharp eq 1 then begin
	sharp1 = total((dataimage[tgood]*ftmask[tgood])^2)
	sharp2 = ttotal ^ 2
	sharpval = sharp1 / sharp2
	str = 'Sharpness (no background removed): ' + $
		  string(sharp1) + string(sharp2) + string(sharpval)
        idp3_updatetxt, cinfo, str
        str = '  Sharpness: ' + strtrim(string(sharpval),2)
	Widget_Control, pinfo.shplabel, Set_Value=str
	cinfo.phot.sharpv = sharpval
      endif 
      if ap_corr gt 0.0 and backgrd eq 0 then begin
	corrflux = (ttotal * (1.0 + (bkg_fract*tnpix)))/ap_corr
	str = 'Corrected flux: ' + string(corrflux)
	idp3_updatetxt, cinfo, str
	str = 'Target Corrected Flux: ' + strtrim(string(corrflux),2)
        Widget_Control, pinfo.tcflabel, Set_Value=str
	cinfo.phot.corrflux = corrflux
      endif
      if backgrd eq 1 then begin
	t2total = total(dataim2[tgood] * ftmask[tgood])
        t2npix = total(ftmask)
	if tmcnt gt 1 then begin
	  t2median = median(dataim2[tmgood], /even)
	  t2c = moment(dataim2[tmgood])
	  t2mean = t2c[0]
	  t2rms = SQRT(t2c[1])
        endif else begin
          t2median = 0.
	  t2mean = 0.
	  t2rms = 0.
          stat = Widget_Message(etstr)
        endelse
        str = 'Bkg removed:' + string(t2total) + string(t2npix) + $
		  string(t2median) + string(t2rms)
        idp3_updatetxt, cinfo, str
	Widget_Control, pinfo.btnamelabel, Set_Value = $
	            '   Target(bkg subtracted):'
        Widget_Control, pinfo.btfluxlabel, Set_Value=strtrim(string(t2total),2)
        Widget_Control, pinfo.btpixlabel, Set_Value = strtrim(string(t2npix),2)
	Widget_Control, pinfo.btmfluxlabel,Set_Value=strtrim(string(t2median),2)
	Widget_Control, pinfo.btrmslabel, Set_Value = strtrim(string(t2rms),2)
	if ap_corr gt 0.0 then begin
	  corrflux = (t2total * (1.0 + (bkg_fract*t2npix)))/ap_corr
	  str = 'Corrected flux: ' + string(corrflux)
	  idp3_updatetxt, cinfo, str
	  str = 'Target Corrected Flux: ' + strtrim(string(corrflux),2)
          Widget_Control, pinfo.tcflabel, Set_Value=str
	  cinfo.phot.corrflux = corrflux
        endif
        if sharp eq 1 then begin
	  sharp12 = total((dataim2[tgood]*ftmask[tgood])^2)
	  sharp22 = t2total ^ 2
  	  sharpval2 = sharp12 / sharp22
	  str = 'Sharpness ( background removed): ' + $
		  string(sharp12) + string(sharp22) + string(sharpval2)
          idp3_updatetxt, cinfo, str
	  str = '  Sharpness(-bkg): ' + strtrim(string(sharpval2),2)
	  Widget_Control, pinfo.shpbkglabel, Set_Value=str
	  cinfo.phot.sharpv2 = sharpval2
        endif
      endif
      cinfo.phot.tnpix = tnpix
      cinfo.phot.tnbad = nbad
      cinfo.phot.tmax = tmax
      cinfo.phot.ttotal = ttotal
      cinfo.phot.tmedian = tmedian
      cinfo.phot.trms = trms
      cinfo.phot.t2total = t2total
      cinfo.phot.t2median = t2median
      Widget_Control, pinfo.info.idp3Window, Set_UValue = cinfo
    endif
    dataim2 = 0
    ftmask = 0
    fbrmask = 0
    return, 0
end
