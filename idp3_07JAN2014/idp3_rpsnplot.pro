pro rpsnplot_done, Event
  Widget_Control, event.top, /Destroy
end

pro idp3_rpsnplot, Event

  Widget_Control, event.top, Get_UValue = info
  Widget_Control, info.idp3Window, Get_UValue = info

  xplot = *info.radpx
  yplot = *info.radpy
  stdplot = *info.radstd
  npts = *info.radnpt
  fix = where(npts lt 2, cnt)
  if cnt gt 0 then npts(fix) = 2
  seplot = stdplot / sqrt(npts)
  etype = (*info.roi).rpeplot
  ptype = (*info.roi).rpmm
  if etype eq 0 then begin
    test = Widget_Message('No Error selection made, cannot plot!')
  endif else begin
    if etype eq 1 then begin
      pstr = '(Pixel)'
      sndat = yplot / stdplot
    endif else begin
      if ptype eq 0 then pstr = '(Mean)' else pstr = '(Median)'
      sndat = yplot / seplot
    endelse
    tstr = 'Signal to Noise Plot ' + pstr
    if not XRegistered('idp3_rpsnplt') then begin
      idp3rpsnp = Widget_Base(group_leader = info.idp3rprf, $
                xoffset = info.wpos.arwp[0], $
	        yoffset = info.wpos.arwp[1], $
	        /column, Title = 'IDP3-ROI Radial Profile Signal to Noise Plot')
      info.idp3rpsnp = idp3rpsnp
      snplot = Widget_Draw(idp3rpsnp, xsize=500, ysize=300, retain=info.retn)
      buttonbase = Widget_Base(idp3rpsnp, /Row)
      label1 = Widget_Label(buttonbase, $
	 Value='                                       ') 
      donebutton = Widget_Button(buttonbase, value = 'Done', $
	   Event_Pro = 'rpsnplot_done')
      Widget_Control, idp3rpsnp, /Realize
      Widget_Control, snplot, Get_Value = snplot_id
      info.snplot = snplot_id
      info.snlab = label1
      Widget_Control, info.idp3Window, Set_UValue = info
      XManager, 'idp3_rpsnplt', idp3rpsnp, /No_Block
    endif
    snplot_id = info.snplot
    snplot_lab = info.snlab
    wset, snplot_id
    erase
    if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
    if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
    plot, xplot, sndat, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	    xtitle = 'Radius', ytitle = 'Signal to Noise', /ynozero
    Widget_Control, snplot_lab, Set_Value = tstr
  endelse
end  
