function idp3_xsgfit, xp,yp,fwhm,zoom,cntr,hgt,basln,bkg,xg1,xg2,ngpk, $
                      yfit,gfit,bfit,gfwhm,gcntr,ghgt,gb,gx,gx2,ooe,xe1,xe2

  pix = n_elements(xp)
  ep = fltarr(pix)
  ep[*] = 1.0
  xx = xp[xg1:xg2]
  yy = yp[xg1:xg2]
  ee = ep[xg1:xg2]
  bfit = fltarr(pix)
  nt = bkg + 3
  oxg1 = xg1 / zoom
  oxg2 = xg2 / zoom
  case nt of

  3: Begin
    start = double([hgt, cntr, fwhm/2.354d0])
    yf = mpfitpeak(xx, yy, aa, estimates=start, nterms=3, perror=perror)
    if aa[1] ge oxg1 then begin
      gfit = gauss1(xp, [aa[1],aa[2],aa[0]],/peak)
      bfit[*] = 0.
      yfit = gfit + bfit
      ghgt = aa[0]
      gcntr = aa[1]
      gfwhm = aa[2] * 2.354
      gb = 0.
      eb = 0.
      gx = 0.
      ex = 0.
      gx2 = 0.
      ex2 = 0.
      if n_elements(perror) gt 0 then begin
        egfwhm = perror[2]
        egcntr = perror[1]
      endif else begin
        egfwhm = 0.
        egcntr = 0.
      endelse
     endif else begin
       print, 'Bad fit'
       return, -1
     endelse
    end

  4: Begin
    start = double([hgt, cntr, fwhm/2.354d0, basln])
    yf = mpfitpeak(xx, yy, aa, estimates=start, nterms=4, perror=perror)
    if aa[1] ge oxg1 then begin
      gfit = gauss1(xp, [aa[1],aa[2],aa[0]],/peak)
      bfit[*] = aa[3]
      yfit = gfit + bfit
      ghgt = aa[0]
      gcntr = aa[1]
      gfwhm = aa[2] * 2.354
      gb = aa[3]
      gx = 0.
      ex = 0.
      gx2 = 0.
      ex2 = 0.
      if n_elements(perror) gt 0 then begin
        egfwhm = perror[2]
        egcntr = perror[1]
        eb = perror[3]
      endif else begin
        egfwhm = 0.
        egcntr = 0.
        eb = 0.
      endelse
     endif else begin
       print, 'Bad fit'
       return, -1
     endelse
    end

  5: Begin
     start = double([hgt, cntr, fwhm/2.354d0, basln, 0.0])
     yf = mpfitpeak(xx, yy, aa, estimates=start, nterms=5, perror=perror)
     if aa[1] ge oxg1 then begin
       gfit = gauss1(xp, [aa[1],aa[2],aa[0]],/peak)
       bfit = aa[3] + aa[4] * xp
       yfit = gfit + bfit
       ghgt = aa[0]
       gcntr = aa[1]
       gfwhm = aa[2] * 2.354
       gb = aa[3]
       gx = aa[4]
       gx2 = 0.
       ex2 = 0.
       if n_elements(perror) gt 0 then begin
         egfwhm = perror[2]
         egcntr = perror[1]
         eb = perror[3]
         ex = perror[4]
       endif else begin
         egfwhm = 0.
         egcntr = 0.
         eb = 0.
         ex = 0.
       endelse
      endif else begin
	print, 'Bad Fit'
	return, -1
      endelse
     end

   else: begin
     print, 'Unknown baseline'
     return, -1
     end

  endcase
  str2 = 'Measured     - FWHM:' + string(fwhm,'$(f10.4)') + '  XPeak:' + $
       string(cntr,'$(f10.4)') + '  YValue:' + string(hgt,'$(f15.7)')
  print, str2
  str3 = 'Gaussian fit - FWHM:' + string(gfwhm,'$(f10.4)') + ' (' + $
       strtrim(string(egfwhm,'$(f10.7)'),2) + ')' + '  XPeak:' + $
       string(gcntr,'$(f10.4)') + ' (' + strtrim(string(egcntr,'$(f10.7)'),2) $ 
       + ')' + '  YValue:' + string(ghgt,'$(f15.7)')
  print, str3
  if bkg eq 1 then begin
    str4 = 'Background constant: ' + strtrim(string(gb,'$(f15.7)'),2) + $
       ' (' + strtrim(string(eb,'$(f15.7)'),2) + ')'
    print, str4
  endif else if bkg eq 2 then begin
    str4 = 'Background linear: intercept = ' + $
	   strtrim(string(gb,'$(f15.7)'),2) + $
           ' (' + strtrim(string(eb,'$(f15.7)'),2) + ')' + $
	   '   slope = ' + strtrim(string(gx, '$(f15.7)'),2) + $
	   ' (' + strtrim(string(ex,'$(f15.7)'),2) + ')'
    print, str4
  endif 
  hpk = (1.0/2.71828183) * ghgt
;  adjy = yfit
  adjy = gfit
  xcen = fix(gcntr + 0.5) * zoom
  if ngpk eq 0 then begin
    for i = xcen, 1, -1 do begin
      if hpk le adjy[i] and hpk ge adjy[i-1] then begin
        pct = (adjy[i]-hpk) / abs(adjy[i]-adjy[i-1])
        xe1 = xp[i] - pct * abs(xp[i] - xp[i-1])
      endif
    endfor
    for i = xcen, n_elements(adjy)-2 do begin
      if hpk le adjy[i] and hpk ge adjy[i+1] then begin
        pct = (adjy[i]-hpk) / abs(adjy[i]-adjy[i+1])
        xe2 = xp[i] + pct * abs(xp[i] - xp[i+1])
      endif 
    endfor
  endif else begin
    for i = xcen, 1, -1 do begin
      if hpk le adjy[i-1] and hpk ge adjy[i] then begin
	pct = (adjy[i-1]-hpk) / abs(adjy[i-1]-adjy[i])
	xe1 = xp[i] - pct * abs(xp[i] - xp[i-1])
      endif
    endfor
    for i = xcen, n_elements(adjy)-2 do begin
      if hpk ge adjy[i] and hpk le adjy[i+1] then begin
	pct = abs(adjy[i]-hpk) / abs(adjy[i]-adjy[i+1])
	xe2 = xp[i] + pct * abs(xp[i] - xp[i+1])
      endif
    endfor
  endelse
  if n_elements(xe1) gt 0 and n_elements(xe2) gt 0 then ooe = xe2 - xe1 $
    else ooe = 0.
  ooe = ooe / zoom
  str5 = '1/e Width: ' + string(ooe,'$(f10.4)')
  print, str5
  return, 0
end
