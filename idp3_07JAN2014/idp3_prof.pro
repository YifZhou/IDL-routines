pro prof_help, Event
  tmp = idp3_findfile('idp3_prof.hlp')
  xdisplayfile, tmp
end

pro prof_replot, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  yplot = *info.xsecy
  xplot = *info.xsecx
  Widget_control, info.profymintxt, Get_Value=pymin
  Widget_control, info.profymaxtxt, Get_Value=pymax
  wset, info.profdraw
  yr = [float(pymin),float(pymax)]
  yt = 'Intensity, YValue'
  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
  if (*info.prof).log eq 0 then begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	xtitle = 'Pixels, XValue', ytitle = yt, /ynozero, yrange=yr
  endif else begin
    plot, xplot, yplot, color=!d.n_colors-1,/ylog,ystyle=ysc,xstyle=xsc, $
      xtitle='Pixels, XValue', ytitle='Intensity, YValue', yrange=yr 
  endelse
end

pro prof_reset, Event
  widget_control, event.top, Get_UValue=tinfo
  widget_control, tinfo.idp3Window, Get_UValue=info
  yplot = *info.xsecy
  (*info.prof).xleft = 0.
  (*info.prof).xright = n_elements(yplot)/(*info.roi).roizoom - 1.
  strl = strtrim(string((*info.prof).xleft),2)
  strr = strtrim(string((*info.prof).xright),2)
  Widget_Control, info.proflefttxt, Set_Value=strl
  Widget_Control, info.profrighttxt, Set_Value=strr
  if info.xs_negpeak eq 0 then begin
    peak = max(yplot)
    basestr = strtrim(string(min(yplot)),2)
  endif else begin
    peak = min(yplot)
    basestr = strtrim(string(max(yplot)),2)
  endelse
  Widget_Control, info.profbasetxt, Set_Value=basestr
  peakloc = where(yplot eq peak, count)
  peakloc = float(peakloc[0]) / float((*info.roi).roizoom)
  peakstr = strtrim(string(peakloc),2)
  Widget_Control, info.profpeaktxt, Set_Value=peakstr
  widget_control, event.top, Set_UValue=tinfo
  widget_control, tinfo.idp3Window, Set_UValue=info
end

pro prof_xindx, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  wset, info.profdraw
  if strlen((*info.prof).coordstr) gt 0 then $
    xyouts, 420, 10, /device, (*info.prof).coordstr, color=!P.background
  x = event.x > 61 < 629
  y = event.y > 41 < 279
  res = convert_coord(x, y, /device, /to_data)
  xval = res[0]
  yval = res[1]
  str = 'XCur:' + string(xval,'$(f9.4)') + '  YCur:' + $
        string(yval, '$(f10.4)')
  if (*info.prof).log eq 1 then str = str + ' [' + $
	string(alog10(yval), '$(f8.4)') + ']'
  if info.color_bits eq 0 then lab_color=200 else lab_color=5
  xyouts, 420, 10, /device, str, color=lab_color
  (*info.prof).coordstr = str
  Widget_Control, info.idp3Window, Set_UValue=info
  if event.type eq 0 then begin
    (*info.prof).xleft = xval
    str = strtrim(string((*info.prof).xleft),2)
    Widget_Control, info.proflefttxt, Set_Value=str
    Widget_Control, info.profymintxt, Get_Value = symin
    Widget_Control, info.profymaxtxt, Get_Value = symax
    dist = float(symax) - float(symin)
    xl = xval
    ylb = yval - 0.03 * dist
    yle = yval + 0.03 * dist
    if info.color_bits gt 0 then lin_color = 4
    oplot, [xl, xl], [ylb, yle], color = lin_color
  endif else begin
    if event.type eq 1 then begin
      (*info.prof).xright = xval
      str = strtrim(string((*info.prof).xright),2)
      Widget_Control, info.profrighttxt, Set_Value=str
      Widget_Control, info.profymintxt, Get_Value = symin
      Widget_Control, info.profymaxtxt, Get_Value = symax
      dist = float(symax) - float(symin)
      xr = xval
      ylb = yval - 0.03 * dist
      yle = yval + 0.03 * dist
      if info.color_bits gt 0 then lin_color = 4
      oplot, [xr, xr], [ylb, yle], color = lin_color
      if (*info.prof).xleft gt 0. and (*info.prof).xright gt 0. then begin
        if (*info.prof).xleft gt (*info.prof).xright then begin
          temp = (*info.prof).xright
          (*info.prof).xright = (*info.prof).xleft
          (*info.prof).xleft = temp
	  str = strtrim(string((*info.prof).xleft),2)
	  Widget_Control, info.proflefttxt, Set_Value=str
	  str = strtrim(string((*info.prof).xright),2)
	  Widget_Control, info.profrighttxt, Set_Value=str
        endif
	if abs((*info.prof).xright - (*info.prof).xleft) lt 0.5 then begin
	  stat = widget_message('Insufficient fitting region defined!')
	  return
        endif
	str = 'CrossSection: Fit Region: ' + string((*info.prof).xleft) + $
	       string((*info.prof).xright)
        idp3_updatetxt, info, str
        x1 = (*info.prof).xleft * (*info.roi).roizoom
        x2 = (*info.prof).xright * (*info.roi).roizoom
        yplot = *info.xsecy
        peak = max(yplot[x1:x2])
        baseline = min(yplot[x1:x2])
        basestr = strtrim(string(min(yplot[x1:x2])),2)
        Widget_Control, info.profbasetxt, Set_Value=basestr
        peakloc = where(yplot[x1:x2] eq peak, count)
	peakloc = float(peakloc[0]+x1) / float((*info.roi).roizoom)
        peakstr = strtrim(string(peakloc),2)
        Widget_Control, info.profpeaktxt, Set_Value=peakstr
      endif
    endif
  endelse
end

pro prof_xleft, event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.proflefttxt, Get_Value = tempstr
  temp = float(tempstr[0])
  if temp ge 0. and temp lt n_elements(*info.xsecx) then begin
    (*info.prof).xleft = temp
    Widget_Control, info.profymintxt, Get_Value = symin
    Widget_Control, info.profymaxtxt, Get_Value = symax
    dist = float(symax) - float(symin)
    xl = temp / (*info.roi).roizoom
    ylb = symin
    yle = symin + 0.04 * dist
    if info.color_bits gt 0 then lin_color = 4
    oplot, [xl, xl], [ylb, yle], color = lin_color
  endif else begin
    str = tempstr + ' is invalid value for left region'
    stat = Widget_Message(str)
    Widget_Control, info.proflefttxt, Set_Value = '0.0'
  endelse
end

pro prof_xright, event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.profrighttxt, Get_Value = tempstr
  temp = float(tempstr[0])
  if temp ge (*info.prof).xleft and temp le n_elements(*info.xsecx) then begin
    (*info.prof).xright = temp
    Widget_Control, info.profymintxt, Get_Value = symin
    Widget_Control, info.profymaxtxt, Get_Value = symax
    dist = float(symax) - float(symin)
    xl = temp / (*info.roi).roizoom
    ylb = symin
    yle = symin + 0.04 * dist
    if info.color_bits gt 0 then lin_color = 4
    oplot, [xl, xl], [ylb, yle], color = lin_color
  endif else begin
    str = tempstr + ' is invalid value for right region'
    stat = Widget_Message(str)
    Widget_Control, info.profrighttxt, Set_Value = '0.0'
  endelse
end

function prof_negpeak, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsnegpeakButton, Get_Value = barray
  if barray[0] eq 0 then info.xs_negpeak=0 else info.xs_negpeak=1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_bkg, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  bkgtype = event.value
  (*info.roi).xsbkg = bkgtype
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_residuals, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsresidbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.roi).xsplotres=0 else (*info.roi).xsplotres=1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_plotgb, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsgbbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.roi).xsplotgb=0 else (*info.roi).xsplotgb=1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_plotgauss, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsgaussbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.roi).xsplotgauss=0 else $
     (*info.roi).xsplotgauss=1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_plotbase, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsbasebutton, Get_Value = barray
  if barray[0] eq 0 then (*info.roi).xsplotbase=0 else (*info.roi).xsplotbase=1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_plotfwhm, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsfwhmbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.roi).xsplotfwhm=0 else (*info.roi).xsplotfwhm=1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro prof_recalcpk, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  xplot = *info.xsecx
  yplot = *info.xsecy
  zoom = (*info.roi).roizoom
  negpk = info.xs_negpeak
  if (*info.prof).xleft ge 0. and (*info.prof).xright gt 0. then begin
    x1 = (*info.prof).xleft * zoom
    x2 = (*info.prof).xright * zoom
  endif else begin
    x1 = 0
    x2 = n_elements(yplot)-1
  endelse
  if negpk eq 0 then begin
    ymin = min(yplot[x1:x2])
    ymax = max(yplot[x1:x2])
    peak = where(ymax eq yplot[x1:x2], cnt)
  endif else begin
    ymin = max(yplot[x1:x2])
    ymax = min(yplot[x1:x2])
    peak = where(ymax eq yplot[x1:x2], cnt)
  endelse
  peak = peak[0] + x1
  peaks = float(peak) / zoom
  peakstr = strtrim(string(peaks),2)
  basestr = strtrim(string(ymin), 2)
  sm = strpos(basestr, 'e')
  if sm gt 0 then begin
    temp = strmid(basestr, 0, 4) + strmid(basestr, sm, 4)
    basestr = temp
  endif
  Widget_Control, info.profpeaktxt, Set_Value = peakstr
  Widget_Control, info.profbasetxt, Set_Value = basestr
  midpt = (ymax + ymin) * 0.5
  if negpk eq 0 then begin
    for i = x1, peak do begin
      if midpt ge yplot[i] and midpt le yplot[i+1] then begin
        pct = (midpt - yplot[i]) / abs(yplot[i]-yplot[i+1])
        xptb = xplot[i] + pct * abs(xplot[i] - xplot[i+1])
      endif
    endfor
    for i = peak, x2-1 do begin
      if midpt le yplot[i] and midpt ge yplot[i+1] then begin
        pct = (midpt - yplot[i+1]) / abs(yplot[i]-yplot[i+1])
        xpte = xplot[i+1] + pct * abs(xplot[i] - xplot[i+1])
      endif 
    endfor
  endif else begin
    for i = x1, peak do begin
      if midpt le yplot[i] and midpt ge yplot[i+1] then begin
	pct = (midpt - yplot[i]) / abs(yplot[i]-yplot[i+1])
	xptb = xplot[i] + pct * abs(xplot[i] - xplot[i+1])
      endif
    endfor
    for i = peak, x2-1 do begin
      if midpt ge yplot[i] and midpt le yplot[i+1] then begin
	pct = (midpt - yplot[i+1]) / abs(yplot[i]-yplot[i+1])
	xpte = xplot[i+1] + pct * abs(xplot[i] - xplot[i+1])
      endif
    endfor
  endelse
  if n_elements(xptb) eq 0 then xptb = 0.
  if n_elements(xpte) eq 0 then xpte = 0.
  fwhm = xpte - xptb
  Widget_Control, info.proffwhmtxt, Set_Value = string(fwhm,'$(f8.4)')
  str = 'CrossSection: Peak:' + string(ymax) + ' Peak pixel:' + $
	string(peaks) +  ' Min:' + string(ymin) + ' Midpoint:' + $
        string( midpt) + ' x coords:' + string(xptb) + string(xpte)
  idp3_updatetxt, info, str
  (*info.prof).ffwhm = fwhm
  str = '  FWHM     PeakPos    PeakValue    BaseValue'
  Widget_Control, info.proffitlab1, Set_Value = str
  str = string(fwhm,'$(f7.4)') + $
	string(peaks,'$(f11.4)') + string(ymax,'$(f12.4)') + $
	string(ymin,'$(f12.4)')
  Widget_Control, info.proffitlab3, Set_Value = str
  Widget_Control, event.top, Set_UValue=info
  Widget_Control, info.idp3Window, Set_UValue=info
end

function prof_type, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  dotype = event.value
  (*info.roi).xsmm = dotype
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  if (*info.prof).width gt 1.0 then idp3_prof, info
end

function prof_scale, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.xsautobutton, Get_Value = barray
  if barray[0] eq 0 then info.xs_autoscl = 0 else info.xs_autoscl = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  idp3_prof, info
end

function prof_oplot, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  widget_control, info.xsoplotbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.prof).oplot = 0 else (*info.prof).oplot = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function prof_logscale, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  widget_control, info.xslogbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.prof).log = 0 else (*info.prof).log = 1
  idp3_display, info
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro prof_idle, Event
  a = 0
end

pro prof_ymin, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_control, info.profymintxt, Get_Value=pymin
  Widget_control, info.profymaxtxt, Get_Value=pymax
  info.xs_autoscl = 0
  Widget_Control, info.xsautobutton, Set_Value = info.xs_autoscl
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  wset, info.profdraw
  (*info.prof).ymin = pymin
  yr = [float(pymin),float(pymax)]
  xplot = *info.xsecx
  yplot = *info.xsecy
  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
  yt = 'Intensity, YValue'
  if (*info.prof).log eq 0 then begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	xtitle = 'Pixels, XValue', ytitle = yt, /ynozero, yrange=yr
  endif else begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	xtitle = 'Pixels, XValue', ytitle = yt, /ynozero, yrange=yr, /ylog
  endelse
end

pro prof_ymax, Event
  widget_control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  Widget_control, info.profymintxt, Get_Value=pymin
  Widget_control, info.profymaxtxt, Get_Value=pymax
  info.xs_autoscl = 0
  Widget_Control, info.xsautobutton, Set_Value = info.xs_autoscl
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  wset, info.profdraw
  (*info.prof).ymax = pymax
  yr = [float(pymin),float(pymax)]
  xplot = *info.xsecx
  yplot = *info.xsecy
  yt = 'Intensity, YValue'
  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
  if (*info.prof).log eq 0 then begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	xtitle = 'Pixels, XValue', ytitle = yt, /ynozero, yrange=yr
  endif else begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	xtitle = 'Pixels, XValue', ytitle = yt, /ynozero, yrange=yr, /ylog
  endelse
end

pro prof_lwidth, Event
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  ; Update the cross section line width in unresampled pixels
  Widget_Control, info.profwidth, Get_Value = temp
  width = float(temp[0])
  (*info.roi).xswidth = width
  (*info.prof).width = width * (*info.roi).roizoom
  if (*info.prof).width gt 1.0 then idp3_prof, info
  widget_control, event.top, Set_UValue=info
  Widget_Control, info.idp3Window, Set_UValue=info
end

pro prof_fwhm, Event
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  xplot = *info.xsecx
  yplot = *info.xsecy
  pix = n_elements(xplot) - 1
  negpeak = info.xs_negpeak
  zoom = (*info.roi).roizoom
  if (*info.prof).xleft gt 0. and (*info.prof).xright gt 0. then begin
    x1 = (*info.prof).xleft * zoom
    x2 = (*info.prof).xright * zoom
  endif else begin
    x1 = 0
    x2 = n_elements(yplot)-1
    (*info.prof).xleft = 0
    (*info.prof).xright = x2 / zoom
  endelse
  Widget_Control, info.profbasetxt, Get_Value=basestr
  ymin = float(basestr[0])
  Widget_Control, info.profpeaktxt, Get_Value=peakstr
  peak = fix(float(peakstr[0])*zoom)
  if peak le x1 + zoom or peak ge x2 - zoom then begin
    stat = Widget_Message('Peak too close to plot edge')
    return
  endif
  ymax = yplot(peak)
  midpt = (ymax + ymin) * 0.5
  if negpeak eq 0 then begin
    for i = x1, peak do begin
      if midpt ge yplot[i] and midpt le yplot[i+1] then begin
        pct = (midpt - yplot[i]) / abs(yplot[i]-yplot[i+1])
        xptb = xplot[i] + pct * abs(xplot[i] - xplot[i+1])
      endif
    endfor
    for i = peak, x2-1 do begin
      if midpt le yplot[i] and midpt ge yplot[i+1] then begin
        pct = (midpt - yplot[i+1]) / abs(yplot[i]-yplot[i+1])
        xpte = xplot[i+1] + pct * abs(xplot[i] - xplot[i+1])
      endif 
    endfor
  endif else begin
    for i = x1, peak do begin
      if midpt le yplot[i] and midpt ge yplot[i+1] then begin
        pct = (midpt - yplot[i]) / abs(yplot[i]-yplot[i+1])
        xptb = xplot[i] + pct * abs(xplot[i] - xplot[i+1])
      endif
    endfor
    for i = peak, x2-1 do begin
      if midpt ge yplot[i] and midpt le yplot[i+1] then begin
        pct = (midpt - yplot[i+1]) / abs(yplot[i]-yplot[i+1])
        xpte = xplot[i+1] + pct * abs(xplot[i] - xplot[i+1])
      endif 
    endfor
  endelse
  if n_elements(xptb) eq 0 then xptb = 0.
  if n_elements(xpte) eq 0 then xpte = 0.
  fwhm = xpte - xptb
  peakdz = float(peak) / zoom
  Widget_Control, info.proffwhmtxt, Set_Value = string(fwhm,'$(f8.4)')
  str = 'CrossSection: Peak:' + string(ymax) + ' Peak pixel:' + $
	string(peak) + ' Min:' + string(ymin) + ' Midpoint:' + $
        string(midpt) + ' x coords:' + string(xptb) + string(xpte)
  idp3_updatetxt, info, str
  (*info.prof).ffwhm = fwhm
  str = '  FWHM     PeakPos    PeakValue    BaseValue'
  Widget_Control, info.proffitlab1, Set_Value = str
  str = string(fwhm,'$(f7.4)') + $
	string(peakdz,'$(f11.4)') + string(ymax,'$(f12.4)') + $
	string(ymin,'$(f12.4)')
  Widget_Control, info.proffitlab3, Set_Value = str
  Widget_Control, info.proflefttxt, Set_Value = $
     strtrim(string((*info.prof).xleft),2)
  Widget_Control, info.profrighttxt, Set_Value = $
     strtrim(string((*info.prof).xright),2)
  Widget_Control, event.top, Set_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Set_UValue=info
end

pro prof_gaussfit, Event
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  wset, info.profdraw
  if info.color_bits eq 0 then lin_color = 200
  xplot = *info.xsecx
  yplot = *info.xsecy
  zoom = (*info.roi).roizoom
  if (*info.prof).xleft ge 0.0 and (*info.prof).xright gt 0.0 then begin
    xg1 = (*info.prof).xleft * zoom
    xg2 = (*info.prof).xright * zoom
  endif else begin
    stat = Widget_Message($
      'Must define Fitting region before gauss fit - Use Cursor')
    return
  endelse
  Widget_Control, info.profbasetxt, Get_Value=basestr
  ymin = float(basestr[0])
  Widget_Control, info.profpeaktxt, Get_Value=peakstr
  cntr = float(peakstr[0])
  zcntr = cntr * zoom
  peakloc = fix(zcntr + 0.5)
  hgt = yplot(peakloc)
  bkg = (*info.roi).xsbkg
  Widget_Control, info.proffwhmtxt, Get_Value = temp
  fwhm = float(temp[0])
  if fwhm le 0. then begin
    stat = Widget_Message($
      'Must define FWHM before gauss fit - Use Calc FWHM!')
    return
  endif
  (*info.prof).ffwhm = fwhm
  zfwhm = fwhm * zoom
  negpk = info.xs_negpeak
  stat = idp3_xsgfit(xplot,yplot,fwhm,zoom,cntr,hgt,ymin,bkg,xg1,xg2,negpk, $
                newy,gplot,baseline,gfwhm,gcntr,ghgt,gb,gx,gx2,ooe,xptb,xpte) 
  if stat eq 0 then begin  
    if info.color_bits gt 0 then lin_color = 1
    if (*info.roi).xsplotbase eq 1 or (*info.roi).xsplotfwhm eq 1 $
      then oplot, xplot, baseline, color = lin_color, linestyle = 3
    basepk = baseline[fix(cntr*zoom+0.5)]
    pk = ghgt
    str = '       FWHM     PeakPos    PeakValue    BaseValue'
    Widget_Control, info.proffitlab2, Set_Value = str
    str = 'Full: ' + string(gfwhm,'$(f7.4)') + $
	string(gcntr,'$(f11.4)') + string(pk,'$(f12.4)') + $
	string(basepk,'$(f12.4)')
    Widget_Control, info.proffitlab4, Set_Value = str
    if (*info.prof).width eq 1.0 then begin
      if info.zoomflux eq 1 then vol = 1.1331 * pk * (zoom * gfwhm) ^ 2 $
	 else vol = 1.1331 * pk * gfwhm ^ 2
      str = 'Gaussian Flux Volume Fit: ' + strtrim(string(vol),2)
      Widget_Control, info.proffitlab5, Set_Value = str
    endif
    if info.color_bits gt 0 then lin_color = 2
    if (*info.roi).xsplotgb eq 1 then oplot, xplot, newy, color = lin_color
    if (*info.roi).xsplotgauss eq 1 then oplot, xplot, gplot, $
      color = lin_color, linestyle=2
    pix = n_elements(xplot) 
    if (*info.roi).xsplotres eq 1 then begin
      residuals = yplot - newy
      tot = total(residuals[xg1:xg2])
      str = 'CrossSection: Residual sum: ' + string(tot)
      idp3_updatetxt, info, str
      if info.color_bits gt 0 then lin_color = 1
      oplot, xplot, residuals, color = lin_color
      if info.color_bits gt 0 then lin_color = 4
      zy = fltarr(pix)
      zy[*] = 0.
      oplot, xplot, zy, linestyle=0, color = lin_color
    endif
    if (*info.roi).xsplotfwhm eq 1 then begin 
      oplot, [gcntr,gcntr], [pk, basepk], linestyle=3
      xx1 = (gcntr - gfwhm*0.5) > 0.
      xx2 = (gcntr + gfwhm*0.5) < (pix-1)
      yfwhm = ghgt * 0.5 
      oplot,[xx1,xx2],[yfwhm,yfwhm],linestyle=3
      hpk = (1.0/2.71828183) * ghgt
      if ooe gt 0. then $
	oplot, [xptb, xpte], [hpk,hpk], linestyle=3
    endif
    if info.color_bits gt 0 then lin_color = 4
    Widget_control, info.profymintxt, Get_Value=symin
    Widget_control, info.profymaxtxt, Get_Value=symax
    dist = (float(symax)-float(symin))
    xl = xg1 / zoom
    ylb = baseline[xg1] - dist * 0.04
    yle = ylb + dist * 0.08
    oplot, [xl,xl], [ylb,yle], color=lin_color
    xr = xg2 / zoom
    yrb = baseline[xg2] - dist * 0.04
    yre = yrb + dist * 0.08
    oplot, [xr,xr], [yrb,yre], color=lin_color
    if basepk ne 0.00 then dem = basepk else dem = 1.0
    ewidg = total(newy[xg1:xg2]-baseline[xg1:xg2])/dem
    ewidm = total(yplot[xg1:xg2]-baseline[xg1:xg2])/dem
    str2 = 'CrossSection: Equivalent width (measured): ' + string(ewidm) + $
	 '  (gaussian): ' + string(ewidg)
    idp3_updatetxt, info, str
    info.xsgfit = ptr_new(newy)
    info.xsbasefit = ptr_new(baseline)
    (*info.roi).xsfwhm = fwhm
    (*info.roi).xs1overe = ooe
    (*info.roi).xspeak = cntr
    (*info.roi).xsheight = pk
    if (*info.roi).xsbkg ge 1 then (*info.roi).xsbase0 = gb $
       else (*info.roi).xsbase0 = 0.
    if (*info.roi).xsbkg ge 2 then (*info.roi).xsbase1 = gx $ 
       else (*info.roi).xsbase1 = 0.
    widget_control, event.top, Set_UValue=tinfo
    Widget_Control, tinfo.idp3Window, Set_UValue=info
  endif
  end

pro prof_lgaussfit, Event
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  if (*info.prof).xleft lt 0. or (*info.prof).xright le 0. then begin
    str = 'Must define FWHM and region before gauss fit - Use Calc FWHM!'
    stat = Widget_Message(str)
    return
  endif
  wset, info.profdraw
  if info.color_bits eq 0 then lin_color = 200
  xplot = *info.xsecx
  yplot = *info.xsecy
  zoom = (*info.roi).roizoom
  Widget_Control, info.profpeaktxt, Get_Value=peakstr
  peak = float(peakstr[0])
  peakz = peak * zoom
  peakfz = fix(peakz + 0.5)
  xg1 = fix((*info.prof).xleft * zoom + 0.5)
  xg2 = peakfz + 1
  Widget_Control, info.profbasetxt, Get_Value=basestr
  ymin = float(basestr[0])
  cntr = peak
  peakloc = fix(cntr*zoom + 0.5)
  hgt = yplot(peakloc)
  Widget_Control, info.proffwhmtxt, Get_Value = temp
  fwhm = float(temp[0])
  if fwhm le 0.0 then begin
    str = 'Must define FWHM before gauss fit - Use Calc FWHM!'
    stat = Widget_Message(str)
    return
  endif
  (*info.prof).ffwhm = fwhm
  bkg = (*info.roi).xsbkg
  negpk = info.xs_negpeak
  stat = idp3_xsgfit(xplot,yplot,fwhm,zoom,cntr,hgt,ymin,bkg,xg1,xg2,negpk, $
                newy,gplot,baseline,gfwhm,gcntr,ghgt,gb,gx,gx2,ooe,xptb,xpte) 
  if stat eq 0 then begin  
    if info.color_bits gt 0 then lin_color = 1
    if (*info.roi).xsplotbase eq 1 or (*info.roi).xsplotfwhm eq 1 $
      then oplot, xplot, baseline, color = lin_color, linestyle = 3
    basepk = baseline[fix(gcntr*zoom+0.5)]
    pk = ghgt
    str = '      FWHM     PeakPos    PeakValue    BaseValue'
    Widget_Control, info.proffitlab2, Set_Value = str
    str = ' Left: ' + string(gfwhm,'$(f7.4)') + $
	string(gcntr,'$(f11.4)') + string(pk,'$(f12.4)') + $
	string(basepk,'$(f12.4)')
    Widget_Control, info.proffitlab4, Set_Value = str
    if (*info.prof).width eq 1.0 then begin
      if info.zoomflux eq 1 then vol = 1.1331 * pk * (zoom * gfwhm) ^ 2 $
	 else vol = 1.1331 * pk * gfwhm ^ 2
      str = 'Gaussian Flux Volume Fit: ' + strtrim(string(vol),2)
      Widget_Control, info.proffitlab5, Set_Value = str
    endif
    if info.color_bits gt 0 then lin_color = 5
    oplot, xplot, newy, color = lin_color
    pix = n_elements(xplot) 
    if (*info.roi).xsplotres eq 1 then begin
      residuals = yplot - newy
      tot = total(residuals[xg1:xg2])
      str = 'CrossSection: Residual sum: ' + string(tot)
      idp3_updatetxt, info, str
      if info.color_bits gt 0 then lin_color = 1
      oplot, xplot, residuals, color = lin_color
      if info.color_bits gt 0 then lin_color = 4
      zy = fltarr(pix)
      zy[*] = 0.
      oplot, xplot, zy, linestyle=0, color = lin_color
    endif
    if (*info.roi).xsplotfwhm eq 1 then begin 
      oplot, [gcntr, gcntr], [pk, basepk], linestyle=3
      xx1 = (gcntr - gfwhm*0.5) > 0.
      xx2 = (gcntr + gfwhm*0.5) < (pix+1)
      yfwhm = ghgt * 0.5 
      oplot,[xx1,xx2],[yfwhm,yfwhm],linestyle=3
      hpk = (1.0/2.71828183) * ghgt
      if ooe gt 0. then $
        oplot, [xptb, xpte], [hpk,hpk], linestyle=3
    endif
    if info.color_bits gt 0 then lin_color = 4
    Widget_control, info.profymintxt, Get_Value=symin
    Widget_control, info.profymaxtxt, Get_Value=symax
    dist = (float(symax)-float(symin))
    xl = xg1/zoom
    ylb = baseline[xg1] - dist*0.04
    yle = ylb + dist*0.08
    oplot, [xl,xl], [ylb,yle], color=lin_color
    xr = xg2/zoom
    yrb = baseline[xg2] - dist*0.04
    yre = yrb + dist*0.08
    oplot, [xr,xr], [yrb,yre], color=lin_color
    if basepk ne 0.00 then dem = basepk else dem = 1.0
    ewidg = total(newy[xg1:xg2]-baseline[xg1:xg2])/dem
    ewidm = total(yplot[xg1:xg2]-baseline[xg1:xg2])/dem
    str2 = 'CrossSection: Equivalent width (measured): ' + string(ewidm) + $
	   '  (gaussian): ' + string(ewidg)
    idp3_updatetxt, info, str2
    info.xsgfit = ptr_new(newy)
    info.xsbasefit = ptr_new(baseline)
    (*info.roi).xsfwhm = gfwhm
    (*info.roi).xs1overe = ooe
    (*info.roi).xspeak = gcntr
    (*info.roi).xsheight = pk
    if (*info.roi).xsbkg ge 1 then (*info.roi).xsbase0 = gb $
       else (*info.roi).xsbase0 = 0.
    if (*info.roi).xsbkg ge 2 then (*info.roi).xsbase1 = gx $ 
       else (*info.roi).xsbase1 = 0.
    widget_control, event.top, Set_UValue=info
    Widget_Control, info.idp3Window, Set_UValue=info
  endif
end

pro prof_rgaussfit, Event
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  if (*info.prof).xleft lt 0. or (*info.prof).xright le 0. then begin
    str = 'Must define FWHM and region before gauss fit - Use Calc FWHM!'
    stat = Widget_Message(str)
    return
  endif
  wset, info.profdraw
  if info.color_bits eq 0 then lin_color = 200
  xplot = *info.xsecx
  yplot = *info.xsecy
  zoom = (*info.roi).roizoom
  Widget_Control, info.profpeaktxt, Get_Value=peakstr
  peak = float(peakstr[0])
  peakz = peak * zoom
  peakfz = fix(peakz)
  xg1 = peakfz - 1
  xg2 = fix((*info.prof).xright * zoom + 0.5)
  Widget_Control, info.profbasetxt, Get_Value=basestr
  ymin = float(basestr[0])
  cntr = peak
  peakloc = fix(cntr*zoom + 0.5)
  hgt = yplot(peakloc)
  Widget_Control, info.proffwhmtxt, Get_Value = temp
  fwhm = float(temp[0])
  if fwhm le 0.0 then begin
    str = 'Must define FWHM before gauss fit - Use Calc FWHM!'
    stat = Widget_Message(str)
    return
  endif
  (*info.prof).ffwhm = fwhm
  bkg = (*info.roi).xsbkg
  negpk = info.xs_negpeak
  stat = idp3_xsgfit(xplot,yplot,fwhm,zoom,cntr,hgt,ymin,bkg,xg1,xg2,negpk, $
                newy,gplot,baseline,gfwhm,gcntr,ghgt,gb,gx,gx2,ooe,xptb,xpte) 
  if stat eq 0 then begin  
    if info.color_bits gt 0 then lin_color = 1
    if (*info.roi).xsplotbase eq 1 or (*info.roi).xsplotfwhm eq 1 $
      then oplot, xplot, baseline, color = lin_color, linestyle = 3
    basepk = baseline[fix(gcntr*zoom+0.5)]
    pk = ghgt
    str = '       FWHM     PeakPos    PeakValue    BaseValue'
    Widget_Control, info.proffitlab2, Set_Value = str
    str = ' Rght: ' + string(gfwhm,'$(f7.4)') + $
	string(gcntr,'$(f11.4)') + string(pk,'$(f12.4)') + $
	string(basepk,'$(f12.4)')
    Widget_Control, info.proffitlab4, Set_Value = str
    if (*info.prof).width eq 1.0 then begin
      if info.zoomflux eq 1 then vol = 1.1331 * pk * (zoom * gfwhm) ^ 2 $
	 else vol = 1.1331 * pk * gfwhm ^ 2
      str = 'Gaussian Flux Volume Fit: ' + strtrim(string(vol),2)
      Widget_Control, info.proffitlab5, Set_Value = str
    endif
    if info.color_bits gt 0 then lin_color = 3
    oplot, xplot, newy, color = lin_color
    pix = n_elements(xplot) 
    if (*info.roi).xsplotres eq 1 then begin
      residuals = yplot - newy
      tot = total(residuals[xg1:xg2])
      str = 'CrossSection: Residual sum: ' + string(tot)
      idp3_updatetxt, info, str
      if info.color_bits gt 0 then lin_color = 1
      oplot, xplot, residuals, color = lin_color
      if info.color_bits gt 0 then lin_color = 4
      zy = fltarr(pix)
      zy[*] = 0.
      oplot, xplot, zy, linestyle=0, color = lin_color
    endif
    if (*info.roi).xsplotfwhm eq 1 then begin 
      oplot, [gcntr, gcntr], [pk, basepk], linestyle=3
      xx1 = (gcntr - gfwhm*0.5) > 0.
      xx2 = (gcntr + gfwhm*0.5) < (pix+1)
      yfwhm = ghgt * 0.5 
      oplot,[xx1,xx2],[yfwhm,yfwhm],linestyle=3
      hpk = (1.0/2.71828183) * ghgt
      if ooe gt 0. then $
	oplot, [xptb, xpte], [hpk,hpk], linestyle=3
    endif
    if info.color_bits gt 0 then lin_color = 4
    Widget_control, info.profymintxt, Get_Value=symin
    Widget_control, info.profymaxtxt, Get_Value=symax
    dist = (float(symax)-float(symin))
    xl = xg1/zoom
    ylb = baseline[xg1] - dist*0.05
    yle = ylb + dist*0.10
    oplot, [xl,xl], [ylb,yle], color=lin_color
    xr = xg2/zoom
    yrb = baseline[xg2] - dist*0.05
    yre = yrb + dist*0.10
    oplot, [xr,xr], [yrb,yre], color=lin_color
    if basepk ne 0.00 then dem = basepk else dem = 1.0
    ewidg = total(newy[xg1:xg2]-baseline[xg1:xg2])/dem
    ewidm = total(yplot[xg1:xg2]-baseline[xg1:xg2])/dem
    str2 = 'CrossSection: Equivalent width (measured): ' + string(ewidm) + $
	   '  (gaussian): ' + string(ewidg)
    idp3_updatetxt, info, str2
    info.xsgfit = ptr_new(newy)
    info.xsbasefit = ptr_new(baseline)
    (*info.roi).xsfwhm = gfwhm
    (*info.roi).xs1overe = ooe
    (*info.roi).xspeak = gcntr
    (*info.roi).xsheight = pk
    if (*info.roi).xsbkg ge 1 then (*info.roi).xsbase0 = gb $
       else (*info.roi).xsbase0 = 0.
    if (*info.roi).xsbkg ge 2 then (*info.roi).xsbase1 = gx $ 
       else (*info.roi).xsbase1 = 0.
    widget_control, event.top, Set_UValue=info
    Widget_Control, info.idp3Window, Set_UValue=info
  endif
end

pro prof_done, Event
  ; Destroy the cross-section widget and erase the line on the ROI.
  geo = Widget_Info(event.top, /geometry)
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  info.wpos.pwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.pwp[1] = geo.yoffset - info.yoffcorr
  Widget_Control, info.idp3Window, Set_UValue=info
  Widget_Control, event.top, /Destroy

  prof = info.prof
  (*prof).ex = -1
  (*prof).ey = -1
  wset, info.drawid1
  roi_display, info
end

pro xsectim_done, Event
  ; Destroy the rotated image widget
  widget_control, event.top, /destroy
end

pro idp3_prof, info
@idp3_errors

  Widget_Control, info.idp3Window, Get_UValue=info

  roi = info.roi
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend
  xsmm = (*roi).xsmm
  xsbkg = (*roi).xsbkg 
  xsplotgb = (*roi).xsplotgb
  xsplotgauss = (*roi).xsplotgauss
  xsplotbase = (*roi).xsplotbase
  xsplotres = (*roi).xsplotres
  xsplotfwhm = (*roi).xsplotfwhm
  if info.xs_autoscl eq 0 then begin
    yminstr = strtrim(string((*info.prof).ymin),2)
    ymaxstr = strtrim(string((*info.prof).ymax),2)
  endif else begin
    yminstr = '0.'
    ymaxstr = '0.'
  endelse
  prof = *info.prof
  xs = (*roi).xsxstart
  ys = (*roi).xsystart
  xe = (*roi).xsxstop
  ye = (*roi).xsystop
  xc = (*roi).xsxcenter
  yc = (*roi).xsycenter
  xlen = (*roi).xslength
  xwid = (*roi).xswidth
  xang = (*roi).xsangle
  sffwhm = string(prof.ffwhm,'$(f8.3)')
  strl = strtrim(string((*info.prof).xleft),2)
  strr = strtrim(string((*info.prof).xright),2)
  if ptr_valid(info.xsgfit) then ptr_free, info.xsgfit
  if ptr_valid(info.xsbasefit) then ptr_free, info.xsbasefit
  blankstr =  '                                                  '
  blankstr1 = '                                                  ' 

  if not XRegistered('idp3_prof') then begin
    idp3prof = widget_base (group_leader=info.idp3Window, $
			  xoffset=info.wpos.pwp[0], $
			  yoffset=info.wpos.pwp[1], $
			  /column,Title='IDP3-ROI Cross Section')
    info.idp3prof = idp3prof
    tbase = Widget_Base(idp3prof, /Row)
    str = 'Line Length:' + string(xlen,'$(f7.2)') + $
	  '    Line Angle:' + string(xang,'$(f7.2)')
    lab6 = Widget_Label(tbase, Value=str)
    labs = Widget_Label(tbase, Value='                                ')
    savButton = Widget_Button(tbase, Value='Save', Event_Pro='idp3_savexsect')
    prntButton = Widget_Button(tbase, Value='Print',Event_Pro='idp3_printxsect')
    helpButton = Widget_Button(tbase, Value='Help', Event_Pro='prof_help')
    doneButton = Widget_Button(tbase, Value='Done', Event_Pro='prof_done')
    txbase = Widget_Base(idp3prof, /Row)
    str = 'XStart:' + string(xs,'$(f9.3)') + '  Center:' + $
	string(xc,'$(f9.3)') + '  Stop:' + string(xe,'$(f9.3)') 
    lab7 = Widget_Label(txbase, Value=str)
    labs1 = Widget_Label(txbase, Value='                               ')
    adjxsButton = Widget_Button(txbase, Value='Adjust', $
       Event_Pro='idp3_adjustxsect')
    repltButton = Widget_Button(txbase, Value='Replot', Event_Pro='prof_replot')
    tybase = Widget_Base(idp3prof, /Row)
    str = 'YStart:' + string(ys,'$(f9.3)') + '  Center:' + $
	string(yc,'$(f9.3)') + '  Stop:' + string(ye,'$(f9.3)')
    lab8 = Widget_Label(tybase, Value=str)
    labs2 = Widget_Label(tybase, Value='               ')
    fitlab5 = Widget_Label(tybase, $
	Value='                                      ')
    prfdraw = widget_draw(idp3prof,xsize=600, ysize=350,UValue='prd',$
      /button_events, /motion_events, Event_Pro='prof_xindx',retain=info.retn)
    buttonbase = Widget_Base(idp3prof,/Row)
    oplotButton = cw_bgroup(buttonbase,['OverPlot'],row = 1, /nonexclusive, $
       set_value=[(*info.prof).oplot], Event_Funct='prof_oplot')
    autoButton = cw_bgroup(buttonbase,['Auto'],row = 1, /nonexclusive, $
       set_value=[info.xs_autoscl], Event_Funct='prof_scale')
    logButton = cw_bgroup(buttonbase,['Log'],row = 1, /nonexclusive, $
       set_value=[(*info.prof).log], Event_Funct='prof_logscale')
    lab12 = Widget_Label(buttonbase, Value='Plot:')
    plotgbButton=cw_bgroup(buttonbase,['Gaussian+Base'],row = 1, $
       /nonexclusive, set_value=[xsplotgb], Event_Funct='prof_plotgb')
    plotgaussButton=cw_bgroup(buttonbase,['Gaussian'],row = 1,/nonexclusive,$
       set_value=[xsplotgauss], Event_Funct='prof_plotgauss')
    plotbaseButton=cw_bgroup(buttonbase,['Base'],row = 1,/nonexclusive,$
       set_value=[xsplotbase], Event_Funct='prof_plotbase')
    residButton = cw_bgroup(buttonbase,['Residual'],row = 1,/nonexclusive, $
       set_value=[xsplotres], Event_Funct='prof_residuals')
    plotfwhmButton=cw_bgroup(buttonbase,['FWHM'],row = 1,/nonexclusive, $
       set_value=[xsplotfwhm], Event_Funct='prof_plotfwhm')
    pbase = Widget_Base(idp3prof, /Row)
    lab1 = Widget_Label(pbase, Value='YDisplay:Min')
    profymintxt = Widget_Text(pbase, Value=yminstr, xsize=7, /Edit, $
        Event_Pro = 'prof_ymin')
    lab2 = Widget_Label(pbase, Value='Max')
    profymaxtxt = Widget_Text(pbase, Value=ymaxstr, xsize=7, /Edit, $
        Event_Pro = 'prof_ymax')
    negButton = cw_bgroup(pbase,['NegPk'],row = 1, /nonexclusive, $
	set_value=[info.xs_negpeak], Event_Funct='prof_negpeak')
    lab31 = Widget_Label(pbase, Value='       XFit: Min')
    flefttxt = Widget_Text(pbase, Value=strl, xsize=7, /Edit, $
             Event_Pro='prof_xleft')
    lab32 = Widget_Label(pbase, Value='Max')
    frighttxt = Widget_Text(pbase, Value=strr, xsize=7, /Edit, $
              Event_Pro='prof_xright')
    resetButton = Widget_Button(pbase, Value='Reset', /align_center, $
       Event_Pro='prof_reset')
    mbase = Widget_Base(idp3prof, /Row)
    lab3 = Widget_Label(mbase, Value='Line Width:')
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    xwidthtxt = Widget_Text(mbase,value=swidstr, xsize=7, $
	      /Edit, Event_Pro = 'prof_lwidth')
    mnames = ['Mean', 'Sum', 'Median']
    mbuttons = cw_bgroup(mbase, mnames, row=1, $
	     Set_Value=xsmm, exclusive=1, Event_Funct='prof_type')
    rnames = ['None', 'Constant', 'Linear']
    rbuttons = cw_bgroup(mbase, rnames, row=1, label_left='     Base:', $
	     Set_Value=xsbkg, exclusive=1, Event_Funct='prof_bkg')
    fbase = Widget_Base(idp3prof, /Row)
    lab4 = Widget_Label(fbase, Value='Peak:')
    profpeaktxt = Widget_Text(fbase, Value='0.', xsize=6, /Edit, $
      Event_Pro = 'prof_idle')
    lab5 = Widget_Label(fbase, Value='Base:')
    profbasetxt = Widget_Text(fbase, Value='0.', xsize=7, /Edit, $
	Event_Pro = 'prof_idle')
    resetpkbutton = Widget_Button(fbase, Value='ReCalc', /align_center, $
	Event_Pro = 'prof_recalcpk')
    fwhmbutton = Widget_Button(fbase, Value='Calc FWHM', /align_center, $
	Event_Pro='prof_fwhm')
    lab55 = Widget_Label(fbase, Value='     FWHM:')
    proffwhmtxt = Widget_Text(fbase, Value=sffwhm, xsize=8, /Edit, $
	Event_Pro = 'prof_idle')
    lab44 = Widget_Label(fbase, Value='Fit:')
    gaussbutton = Widget_Button(fbase, Value='Full', /align_center, $
	Event_Pro = 'prof_gaussfit')
    gleftbutton = Widget_Button(fbase, Value='Left', /align_center, $
      Event_Pro = 'prof_lgaussfit')
    grightbutton = Widget_Button(fbase, Value='Right', /align_center, $
      Event_Pro = 'prof_rgaussfit')
    f1base = Widget_Base(idp3prof, /Row)
    fitlab1 = Widget_Label(f1base, /align_left, Value=blankstr)
    fill1 = Widget_Label(f1base, /align_left, Value='   ')
    fitlab2 = Widget_Label(f1base, /align_left, Value=blankstr1)
    f3base = Widget_Base(idp3prof, /Row)
    fitlab3 = Widget_Label(f3base, /align_left, Value=blankstr)
    fill2 = Widget_Label(f3base, /align_left, Value='  ')
    fitlab4 = Widget_Label(f3base, /align_left, Value=blankstr1)
    ; Realize the widget onto the screen.
    widget_control, idp3prof, /realize

    ; Remember the cross-section draw widget draw ID.
    WIDGET_CONTROL, prfdraw, GET_VALUE=drawfield_id
    wset, drawfield_id
    info.profdraw = drawfield_id
    info.profymintxt = profymintxt
    info.profymaxtxt = profymaxtxt
    info.profwidth = xwidthtxt
    info.proffwhmtxt = proffwhmtxt
    info.profbasetxt = profbasetxt
    info.profpeaktxt = profpeaktxt
    info.proflefttxt = flefttxt
    info.profrighttxt = frighttxt
    info.xsautobutton = autobutton
    info.xsnegpeakbutton = negButton
    info.xsgaussbutton = plotgaussbutton
    info.xsgbbutton = plotgbbutton
    info.xsresidbutton = residbutton
    info.xsfwhmbutton = plotfwhmbutton
    info.xsbasebutton = plotbasebutton
    info.xslogbutton = logbutton
    info.xsoplotbutton = oplotbutton
    info.proffitlab1 = fitlab1
    info.proffitlab2 = fitlab2
    info.proffitlab3 = fitlab3
    info.proffitlab4 = fitlab4
    info.proffitlab5 = fitlab5
    info.proflab1 = lab6
    info.proflab2 = lab7
    info.proflab3 = lab8
    Widget_Control,info.idp3Window,Set_UValue=info
  endif else wset, info.profdraw

  ; Calculate the Y values for the cross section.
  dx = float(prof.sx-prof.ex)
  dy = float(prof.sy-prof.ey)
  if ABS(dx) gt 1 or ABS(dy) gt 1 then begin
    width = prof.width 
;    n = abs(dx) > abs(dy)
    n = fix(sqrt(dx ^ 2 + dy ^ 2))
    r = fltarr(n+1)
    nbins = n + 1 ;11
    if abs(dx) gt abs(dy) then begin
      if prof.ex gt prof.sx then s = 1 else s = -1
      sy = (prof.ey-prof.sy)/abs(dx)
    endif else begin
      if prof.ey gt prof.sy then sy = 1 else sy = -1
      s = (prof.ex-prof.sx)/abs(dy)
    endelse
    xx = long(findgen(nbins)*s+prof.sx)
    yy = long(findgen(nbins)*sy+prof.sy)
    zoom = (*roi).roizoom
    ztype = info.roiioz
    if (width EQ 1) then begin
      sx = (x2-x1+1) * zoom
      sy = (y2-y1+1) * zoom
      tplt = (idp3_congrid((*info.dispim)[x1:x2,y1:y2], $ 
        sx,sy,zoom,ztype,info.pixorg)) [long(yy)*sx + xx]
      if info.zoomflux eq 1 then tplt = tplt/(zoom^2) 
    endif else begin
      tsx = x2 - x1 + 1
      tsy = y2 - y1 + 1
      tsz = tsx > tsy
      pad = fix(0.10 * tsz + 0.5) > 2
      imsz = tsz + 2 * pad
      ttim = fltarr(imsz,imsz)
      ttim[*,*] = 0.
      stim = fltarr(imsz,imsz)
      stim[*,*] = 0.
      xbg = (imsz-tsx) / 2
      ybg = (imsz-tsy) / 2
      xend = xbg + tsx-1
      yend = ybg + tsy-1
      sdispim = idp3_scaldisplay(info)
      stim[xbg:xend,ybg:yend]=sdispim[x1:x2,y1:y2]
      ttim[xbg:xend,ybg:yend]=(*info.dispim)[x1:x2,y1:y2]
      if (*roi).xsangle LE 180.0 then rotadj = 90.0 else rotadj = 270.0 
      ang = (*roi).xsangle - rotadj
      xcen = fix((prof.ex+prof.sx)/2. + 0.5) + xbg * zoom
      ycen = fix((prof.ey+prof.sy)/2. + 0.5) + ybg * zoom
      z1 = info.Z1
      z2 = info.Z2
      szx = imsz * zoom
      szy = imsz * zoom
      maxsz = 800
      if not XRegistered('idp3_xsectim') then begin
        idp3prfim = widget_base (group_leader=info.idp3prof, $
	  xoffset=info.wpos.arwp[0], $
	  yoffset=info.wpos.arwp[1], $
	  /column,Title='Cross Section Rotated Image')
        info.idp3prfim = idp3prfim
        if szx le maxsz $
          then profim = widget_draw(idp3prfim,xsize=szx, ysize=szy,$
	              retain=info.retn) $
	  else profim = widget_draw(idp3prfim,xsize=szx, ysize=szy, $
		      x_scroll_size=maxsz, y_scroll_size=maxsz, /scroll, $
		      retain=info.retn)
        buttonbase = Widget_Base(idp3prfim,/Row)
        donebutton = widget_button (buttonbase, value='Done', $
                     Event_Pro = 'xsectim_done')
        ; Realize the widget onto the screen.
        Widget_Control, idp3prfim, /Realize
        Widget_Control, profim, Get_Value=imfield_id
        info.profim = imfield_id
        Widget_Control,info.idp3Window,Set_UValue=info
        XManager, 'idp3_xsectim', idp3prfim, /no_Block
      endif
      imfield_id = info.profim
      wset, imfield_id
      erase
      zm2 = zoom ^ 2
      tim = idp3_congrid(ttim,szx,szy,zoom, ztype, info.pixorg)
      sim = idp3_congrid(stim,szx,szy,zoom, ztype, info.pixorg)
      if info.zoomflux eq 1 then begin
	tim = tim/zm2
	sim = sim/zm2
      endif
      rtim = idp3_rot(tim, ang, 1.0, xcen, ycen, /pivot, cubic=-0.5, $
        missing=-999.9)
      rstim = idp3_rot(sim, ang, 1.0, xcen, ycen, /pivot, cubic=-0.5, $
        missing=-999.9)
      ttim = 0
      tim = 0
      stim = 0
      sim = 0
      sdispim = 0
      if info.zoomflux eq 0 then begin
        zz1 = z1
        zz2 = z2
      endif else begin
        zz1 = z1/zm2
        zz2 = z2/zm2
      endelse
      ncolors = info.d_colors - info.color_bits - 1
      brtim = bytscl(rstim, top=ncolors, min=zz1, max=zz2)
      brtim = brtim + info.color_bits
      tv, brtim
      ang = (*roi).xsangle * (!pi/180D0)
      yadj1 = fix((*roi).xslength * abs(sin(ang)) * zoom * 0.5 + 0.5)
      yadj2 = fix((*roi).xslength * abs(cos(ang)) * zoom * 0.5 + 0.5)
      yadj = yadj1 > yadj2
      rsz = size(rtim)
      rsy = (ycen - yadj) > 0
      rey = (ycen + yadj) < (rsz[2]-1)
      dmax = FIX(width/2)
      rsx1 = (xcen - dmax) > 0
      rsx2 = (xcen + dmax) < (rsz[1]-1)
      xcl = info.color_xsect
      if xcl lt 0 then xcl = 200
      plots, rsx1, rsy, color=xcl, /device
      plots, rsx2, rsy, color=xcl, /device, /continue
      plots, rsx2, rey, color=xcl, /device, /continue
      plots, rsx1, rey, color=xcl, /device, /continue
      plots, rsx1, rsy, color=xcl, /device, /continue
      wset, info.profdraw 
      tplt = fltarr(rey-rsy+1)
      if (*info.roi).xsmm lt 2 then begin
        tcnt = fltarr(rey-rsy+1)
        for i = rsx1, rsx2 do begin
          tmp = rtim[i,rsy:rey]
	  gpt = (where(tmp ne -999.9, cnt))
	  indx = 1.0
          if width MOD 2 EQ 0 then begin
	    if i EQ rsx1 or i EQ rsx2 then begin
	      tmp = tmp * 0.5
	      indx = 0.5
            endif
          endif
	  if cnt gt 0 then begin
	    tplt[gpt] = tplt[gpt] + tmp[gpt]
	    tcnt[gpt] = tcnt[gpt] + indx
          endif
        endfor
        if (*info.roi).xsmm eq 0 then begin
	  pt = where(tcnt eq 0., cnt)
	  if cnt gt 0 then tcnt[pt] = 1.
	  tplt = tplt/tcnt
        endif
      endif else begin
        for i = rsy, rey do begin
	  tmp = rtim[rsx1:rsx2,i]
	  gpt = (where(tmp ne -999.9, cnt))
	  if cnt gt 0 then tplt[i-rsy] = median(tmp[gpt], /EVEN)
        endfor
      endelse
      if prof.ey lt prof.sy then tplt = reverse(tplt)
    endelse

    ; Increment the line type (in case we are overplotting)
    ; Wrap back to 1 if the line type is 6.
    ls = (info.profline + 1) MOD 6
    info.profline = ls
    if not XRegistered('idp3_prof') then overplot=0 $
       else overplot=(*info.prof).oplot

    ; The X values for the plot are quite simple, allow for the ROI zoom.
    xplt = float(indgen(n_elements(tplt)))/float((*roi).roizoom)

    ; update data pointers for x and y values
    if (ptr_valid(info.xsecx)) then ptr_free, info.xsecx
    if (ptr_valid(info.xsecy)) then ptr_free, info.xsecy
    info.xsecx = ptr_new(xplt)
    info.xsecy = ptr_new(tplt)

    ; Plot the data.
    if overplot eq 1 then begin
      oplot,xplt,tplt,color=!d.n_colors-1,linestyle=ls
    endif else begin
      if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
      if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
      yr = fltarr(2)
      if info.xs_autoscl eq 1 then begin
        yr[0] = min(tplt)
        yr[1] = max(tplt)
        (*info.prof).ymin = yr[0]
        (*info.prof).ymax = yr[1]
        str1 = strtrim(string(yr[0]),2)
        str2 = strtrim(string(yr[1]),2)
        Widget_Control, info.profymintxt, Set_Value=str1
        Widget_Control, info.profymaxtxt, Set_Value=str2
      endif else begin
        Widget_Control, info.profymintxt, Get_Value=str1
        Widget_Control, info.profymaxtxt, Get_Value=str2
        yr[0] = float(str1[0])
        yr[1] = float(str2[0])
      endelse
      if prof.log eq 0 then begin
        plot, xplt, tplt, color=!d.n_colors-1, ystyle=ysc, xstyle=xsc,  $
	    xtitle='Pixels, XValue', ytitle='Intensity, YValue', yrange=yr 
      endif else begin
        plot, xplt, tplt, color=!d.n_colors-1, /ylog, ystyle=ysc, xstyle=xsc, $
	    xtitle='Pixels, XValue', ytitle='Intensity, YValue', yrange=yr 
      endelse
    endelse
    xleft = fix((*info.prof).xleft * (*roi).roizoom + 0.5) > 0
    xright = fix((*info.prof).xright * (*roi).roizoom + 0.5) < $
             (n_elements(tplt)-1)
    if xright le xleft then xright = n_elements(tplt)-1
    ymin = min(tplt[xleft:xright])
    ymax = max(tplt[xleft:xright])
    peak = where(tplt[xleft:xright] eq ymax, cnt)
    peak = float(peak+xleft)/(*info.roi).roizoom
    peakstr = strtrim(string(peak),2)
    peakstr = strmid(peakstr,0,7)
    basestr = strtrim(string(ymin),2)
    sm = strpos(basestr, 'e')
    if sm gt 0 then begin
      temp = strmid(basestr,0,4) + strmid(basestr,sm,4)
      basestr = temp
    endif
    ffwhmstr = string((*info.prof).ffwhm,'$(f8.3)')

    Widget_Control, info.profpeaktxt, Set_Value = peakstr
    Widget_Control, info.profbasetxt, Set_Value = basestr
    Widget_Control, info.proffwhmtxt, Set_Value = ffwhmstr
    Widget_Control, info.proffitlab1, Set_Value = blankstr
    Widget_Control, info.proffitlab2, Set_Value = blankstr
    Widget_Control, info.proffitlab3, Set_Value = blankstr
    Widget_Control, info.proffitlab4, Set_Value = blankstr
    Widget_Control, info.proffitlab5, Set_Value = blankstr

    Widget_Control,info.idp3prof,Set_UValue=info
    Widget_Control,info.idp3Window,Set_UValue=info

    xs = (*roi).xsxstart
    ys = (*roi).xsystart
    xe = (*roi).xsxstop
    ye = (*roi).xsystop
    xc = (*roi).xsxcenter
    yc = (*roi).xsycenter
    xlen = (*roi).xslength
    xang = (*roi).xsangle
    str = 'Line Length:' + string(xlen,'$(f7.2)') + $
	  '    Line Angle:' + string(xang,'$(f7.2)')
    Widget_Control, info.proflab1, Set_Value = str
    str = 'XStart:' + string(xs,'$(f9.3)') + '  Center:' + $
          string(xc,'$(f9.3)') + '  Stop:' + string(xe,'$(f9.3)')
    Widget_Control, info.proflab2, Set_Value = str
    str = 'YStart:' + string(ys,'$(f9.3)') + '  Center:' + $
          string(yc,'$(f9.3)') + '  Stop:' + string(ye,'$(f9.3)')
    Widget_Control, info.proflab3, Set_Value = str
;; 
print, string(xs,'$(f9.3)') + ' ' + string(ys,'$(f9.3)')  ; added by GS for xterm output
print, string(xe,'$(f9.3)') + ' ' + string(ye,'$(f9.3)')  ; added by GS for xterm output
;;
  endif else begin
    str ='Cross section has too few points!'
    idp3_updatetxt, info, str
  endelse

  wset, info.drawid1
  if not XRegistered('idp3_prof') then $
    XManager, 'idp3_prof', idp3prof, /No_Block, Event_Handler='idp3prof_event'

end

