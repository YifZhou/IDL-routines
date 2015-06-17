pro setcen, indx, xcen, ycen

  search = 0.5
  case indx of
    1:   
    2:    xcen = xcen - search
    3:    ycen = ycen + search
    4:    xcen = xcen + search
    5:    xcen = xcen + search
    6:    ycen = ycen - search
    7:    ycen = ycen - search
    8:    xcen = xcen - search
    9:    xcen = xcen - search
    else:
  endcase
end

function idp3_asymmetry, image, x, y, rad, bkg, stdd, bkg_crd, bkg_msk, eta_val

  res = fltarr(5)
  search = 0.5
  imsz = size(image)
  maxsz = (imsz[1]-2) < (imsz[2]-2)
  x1 = bkg_crd[0]
  x2 = bkg_crd[1]
  y1 = bkg_crd[2]
  y2 = bkg_crd[3]
  bgx = (x2-x1) / 2 + 5
  bgy = (y2-y1) / 2 + 5
  btakeout = bkg
  temp = image - btakeout
  bisqr = abs(temp)
  
  if x1 ge 0 and x2 gt x1 then begin
    cflag = 0
    while cflag eq 0 do begin
      bxcen = bgx
      bycen = bgy
      for kk = 1, 9 do begin
        setcen, kk, bxcen, bycen
        brot = rot(temp,180.0,1.0,bxcen,bycen, cubic=-0.5, /pivot, missing=0.)
        bsqr = abs(brot - temp)
	good = where(bkg_msk eq 1, count)
	takeout = mean(bsqr[good])
        if kk eq 1 then begin
  	  symm = takeout
	  centr = symm
	  osymm = takeout
	  stdd = stddev(bsqr[good])
        endif
        tsymm = takeout
        if tsymm lt symm then begin
	  symm = tsymm
	  bgx = bxcen
	  bgy = bycen 
        endif
      endfor
      if symm eq centr then cflag = 1
    endwhile
  endif else begin
    symm = 0.
    takeout = symm
  endelse

  cflag = 0
  oldrad = rad
  newrad = rad

  ; search for radius where eta ~ etalim
    etalim = eta_val
    if etalim gt 0. and etalim lt 1. then begin
      rad = oldrad
      beg = fix(rad*0.01) > 1
      endd = beg + oldrad + fix(rad*0.2)
      lasteta = -1.
      newrad = -1.
      xf = fix(x + 0.5)
      yf = fix(y + 0.5)
      openw, dlun, 'asymmetry.dmp', /get_lun
      for i = beg, endd do begin
        x1box = (xf - i) > 0
        x2box = (xf + i) < maxsz
        y1box = (yf - i) > 0
        y2box = (yf + i) < maxsz
        tmpim = image - btakeout
        tnpts = (x2box - x1box + 1) * (y2box - y1box + 1)
        npts = (y2box - y1box + 1) * 2 + (x2box - x1box - 1) * 2
        tmn = total(tmpim[x1box:x2box,y1box:y2box]) / float(tnpts)
	mn1 = total(tmpim[x1box,y1box:y2box])
	mn2 = total(tmpim[x2box,y1box:y2box])
	xb = x1box + 1
	xe = x2box - 1
	mn3 = total(tmpim[xb:xe,y1box])
	mn4 = total(tmpim[xb:xe,y2box])
	mn = (mn1 + mn2 + mn3 + mn4) / float(npts)
        eta = mn/tmn
        printf, dlun, x1box, x2box, y1box, y2box 
	printf, dlun, mn1, mn2, mn3, mn4 
	printf, dlun, tmn, mn, eta
        if lasteta gt etalim and eta le etalim then begin
          newrad = float(i) - (etalim - eta) / etalim
        endif
        lasteta = eta
      endfor
    endif
    close, dlun
    free_lun, dlun
    print, 'eta:', etalim, '  old radius:', rad, '  new radius:', newrad
    if newrad lt 0. then begin
      str = 'Radius too small, eta=' + strtrim(string(etalim),2) + ' not found!'
      test = Widget_Message(str)
      res[0:3] = -1
      res[4] = etalim
    endif else begin
      ccount = 1
      rad = newrad
      xorg = x
      yorg = y
      ixx1 = fix(xorg - rad + 0.5)
      ixx2 = fix(xorg + rad + 0.5)
      iyy1 = fix(yorg - rad + 0.5)
      iyy2 = fix(yorg + rad + 0.5)
      x = rad + 5
      y = rad + 5
      num = (rad*2 + 1) ^ 2
      sig = total(image[ixx1:ixx2,iyy1:iyy2])/float(num)
      snr = sig / stdd

      while cflag eq 0 do begin
        cutout = image[ixx1-5:ixx2+5, iyy1-5:iyy2+5]
        temp = cutout - btakeout
        xcen = x
        ycen = y
        for kk = 1, 9 do begin
          setcen, kk, xcen, ycen 
          rotim = rot(temp,180.,1.0,xcen,ycen,cubic=-0.5,/pivot,missing=0.)
          sub = rotim - temp
          sqr = abs(sub)
          imsqr = abs(temp)
          if kk eq 1 then begin
            result = moment(imsqr[5:ixx2-ixx1+5, 5:iyy2-iyy1+5])
            bottom = result[0]
            istd = sqrt(result[1])
            pix = n_elements(imsqr[5:ixx2-ixx1+5, 5:iyy2-iyy1+5])
          endif
          top = mean(sqr[5:ixx2-ixx1+5, 5:iyy2-iyy1+5])
          if kk eq 1 then begin
            symm = (top - takeout) / bottom
            centr = symm
	    osymm = top / bottom
          endif
          tsymm = (top - takeout) / bottom
          tosymm = top / bottom
          err = stdd / (2*(bottom+istd))
          if tsymm lt symm then begin
            symm = tsymm
	    osymm = tosymm
	    x = xcen
	    y = ycen
          endif
        endfor
        if symm eq centr then cflag = 1
        ccount = ccount + 1
      endwhile
  
      res[0] = symm
      res[1] = err
      res[2] = snr

      totalflux = 0.
      rndrad = fix(rad + 0.5)
      maxx = (fix(rndrad+0.5) * 2 + 1) < maxsz
      maxy = (fix(rndrad+0.5) * 2 + 1) < maxsz
      nbins = fix(rndrad + 0.5) + 1
      radflux = fltarr(nbins)
      sumflux = fltarr(nbins)
      ixx1 = fix(xorg - rndrad)
      ixx2 = fix(xorg + rndrad)
      iyy1 = fix(yorg - rndrad)
      iyy2 = fix(yorg + rndrad)
      dimage = image[ixx1:ixx2,iyy1:iyy2]
      xcen = rndrad
      ycen = rndrad
      rsz = size(radflux)
      for jj = 0, maxy do begin
        for ii = 0, maxx do begin
          r = fix(sqrt((ii-xcen)^2 + (jj-ycen)^2) + 0.5)
          if r ge 0 and r le rndrad  and r le rsz[1] then begin
	    totalflux = totalflux + dimage[ii,jj]
	    radflux[r] = radflux[r] + dimage[ii,jj]
          endif
        endfor
      endfor
      for ii = 0, nbins - 1 do begin
        sumflux[ii] = total(radflux[0:ii])
      endfor
      flux20 = totalflux * 0.2
      flux80 = totalflux * 0.8
      i80 = -1
      i20 = -1
      for ii = 0, nbins-2 do begin
        if sumflux[ii] le flux20 and sumflux[ii+1] ge flux20 then i20 = ii
        if sumflux[ii] le flux80 and sumflux[ii+1] ge flux80 then i80 = ii
      endfor
      r20=(abs(flux20-sumflux[i20])/abs(sumflux[i20+1]-sumflux[i20])) $
	  + float(i20)
      r80=(abs(flux80-sumflux[i80])/abs(sumflux[i80+1]-sumflux[i80])) $
	  + float(i80)
      rat = r80 / r20
      cc = alog10(rat) * 5.0
      print, r20, r80, cc
      res[3] = cc
      res[4] = etalim
    endelse
  return, res
end
