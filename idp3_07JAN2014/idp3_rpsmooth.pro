pro idp3_rpsmooth, info

  ; smooth radial profile and redisplay
  smwidth = info.rpsmoothwid
  if (*info.rprf).ee eq 0 then begin
    yplot = *info.radpy
    yt = 'Intensity'
  endif else begin
    yplot = *info.radee
    yt = 'Enc Energy'
  endelse
  yplotp = smooth(yplot, smwidth)
  str ='Radial Profile boxcar smoothed with width of' + string(smwidth)
  idp3_updatetxt, info, str
  Widget_control, info.rpymintxt, Get_Value=rpymin
  Widget_control, info.rpymaxtxt, Get_Value=rpymax
  wset, info.rprfdraw
  yr = [rpymin,rpymax]
  xplot = *info.radpx
  stdplot = *info.radstd
  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
  xmax = max(xplot)
  xr = [0.,xmax]
  if (*info.rprf).log eq 0 then begin
    plot, xplot, yplotp, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
      xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr 
    if (*info.rprf).ee eq 0 and (*info.roi).rpeplot gt 0 then begin
      if (*info.roi).rpeplot eq 1 then begin 
        idp3_errbars, xplot, yplot, yerr=stdplot, color=2
      endif else begin
        npts = *info.radnpt
	fix = where(npts lt 2, cnt)
	if cnt gt 0 then npts(fix) = 2
        seplot = stdplot / sqrt(npts-1)
	idp3_errbars, xplot, yplotp, yerr=seplot, color=2
      endelse
    endif
  endif else begin
    plot, xplot, yplotp, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
       xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr, /ylog
  endelse
  if (*info.rprf).ee eq 0 then begin
    ptr_free, info.radpy
    info.radpy = ptr_new(yplotp)
  endif else begin
    ptr_free, info.radee
    info.radee = ptr_new(yplotp)
  endelse
end

