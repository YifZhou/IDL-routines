pro noiseprof_help, Event
  tmp = idp3_findfile('idp3_noiseprof.hlp')
  xdisplayfile, tmp
end

pro NoiseProf_Done, event
  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=npinfo
  Widget_Control, npinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.npwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.npwp[1] = geo.yoffset - tempinfo.yoffcorr
  wset, (*tempinfo.roi).drawid2
  tv, *(*tempinfo.roi).roiimage
  Widget_Control, npinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy
end

function noiseprof_scale, Event
  widget_control, event.top, Get_UValue=npinfo
  widget_control, npinfo.info.idp3Window, Get_UValue=info
  Widget_Control, info.npautobutton, Get_Value = barray
  if barray[0] eq 0 then begin
    info.np_autoscl = 0 
  endif else begin
    info.np_autoscl = 1
    wset, info.npfdraw
    if ptr_valid(info.noispx) and ptr_valid(info.noispy) then begin
      xplot = *(info).noispx
      yplot = *(info).noispy
      yr = fltarr(2)
      yr[0] = min(yplot)
      yr[1] = max(yplot)
      xt = 'Radius of Annulus Center'
      if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
      if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
      yt='One Sigma'
      if (*info.nprf).log eq 0 then begin
        plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $  
          xtitle = xt, ytitle = yt, yrange=yr 
      endif else begin
        plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
  	  xtitle = xt, ytitle = yt, yrange=yr, /ylog
      endelse
    endif
    Widget_control, info.npfymintxt, Set_Value=strtrim(string(yr[0]),2)
    Widget_control, info.npfymaxtxt, Set_Value=strtrim(string(yr[1]),2)
  endelse
  widget_control, event.top, Set_UValue=npinfo
  widget_control, info.idp3Window, Set_UValue=info
end

function noiseprof_oplot, Event
  widget_control, event.top, Get_UValue=npinfo
  widget_control, npinfo.info.idp3Window, Get_UValue=info
  widget_control, info.npoplotbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.nprf).oplot = 0 else (*info.nprf).oplot = 1
  widget_control, event.top, Set_UValue=npinfo
  widget_control, info.idp3Window, Set_UValue=info
end

function noiseprof_logscale, Event
  widget_control, event.top, Get_UValue=npinfo
  widget_control, npinfo.info.idp3Window, Get_UValue=info
  widget_control, info.nplogbutton, Get_Value = barray
  yt='One Sigma'
  if barray[0] eq 0 then begin
    (*info.nprf).log = 0 
  endif else begin
    (*info.nprf).log = 1
;    (*info.nprf).oplot = 0
    widget_control, info.npoplotbutton, Set_Value=(*info.nprf).oplot
  endelse
  Widget_control, info.npfymintxt, Get_Value=npymin
  Widget_control, info.npfymaxtxt, Get_Value=npymax
  wset, info.npfdraw
  yr = fltarr(2)
  yr[0] = float(npymin)
  yr[1] = float(npymax)
  xt = 'Radius of Annulus Center'
  if ptr_valid(info.noispx) and ptr_valid(info.noispy) then begin
    xplot = *(info).noispx
    yplot = *(info).noispy
    if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
    if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
    yt='One Sigma'
    if (*info.nprf).log eq 0 then begin
      plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $  
        xtitle = xt, ytitle = yt, yrange=yr 
    endif else begin
      plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
        xtitle = xt, ytitle = yt, yrange=yr, /ylog
    endelse
  endif
  widget_control, event.top, Set_UValue=npinfo
  widget_control, info.idp3Window, Set_UValue=info
end

pro noiseplot_ymin, Event
  Widget_Control, event.top, Get_UValue=npinfo
  Widget_Control, npinfo.info.idp3Window, Get_UValue=info
  Widget_control, info.npfymintxt, Get_Value=npymin
  Widget_control, info.npfymaxtxt, Get_Value=npymax
  info.np_autoscl = 0
  Widget_Control, info.npautobutton, Set_Value = info.np_autoscl
  widget_control, event.top, Set_UValue=npinfo
  widget_control, info.idp3Window, Set_UValue=info
  wset, info.npfdraw
  yr = fltarr(2)
  yr[0] = float(npymin)
  yr[1] = float(npymax)
  if ptr_valid(info.noispx) and ptr_valid(info.noispy) then begin
    xplot = *(info).noispx
    yplot = *(info).noispy
    xt = 'Radius of Annulus Center'
    if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
    if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
    yt='One Sigma'
    if (*info.nprf).log eq 0 then begin
      plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $  
        xtitle = xt, ytitle = yt, yrange=yr 
    endif else begin
      yt='One Sigma'
      plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
        xtitle = xt, ytitle = yt, yrange=yr, /ylog
    endelse
  endif
  end

pro noiseplot_ymax, Event
  Widget_Control, event.top, Get_UValue=npinfo
  Widget_Control, npinfo.info.idp3Window, Get_UValue=info
  Widget_control, info.npfymintxt, Get_Value=npymin
  Widget_control, info.npfymaxtxt, Get_Value=npymax
  info.np_autoscl = 0
  Widget_Control, info.npautobutton, Set_Value = info.np_autoscl
  widget_control, event.top, Set_UValue=npinfo
  widget_control, info.idp3Window, Set_UValue=info
  wset, info.npfdraw
  yr = fltarr(2)
  yr[0] = float(npymin)
  yr[1] = float(npymax)
  if ptr_valid(info.noispx) and ptr_valid(info.noispy) then begin
    xplot = *(info).noispx
    yplot = *(info).noispy
    xt = 'Radius of Annulus Center'
    if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
    if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
    yt='One Sigma'
    if (*info.nprf).log eq 0 then begin
      plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $  
        xtitle = xt, ytitle = yt, yrange=yr 
    endif else begin
      plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
        xtitle = xt, ytitle = yt, yrange=yr, /ylog
    endelse
  endif
  end

pro NoiseProf_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=npinfo
  Widget_Control, npinfo.info.idp3Window, Get_UValue=tempinfo
  npinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=npinfo

  case event.id of
    npinfo.npxcenterField: begin
      ; Just read the value and save it.
      Widget_Control, npinfo.npxcenterField, Get_Value = temp
      (*npinfo.info.roi).npxcenter = temp
      end
    npinfo.npycenterField: begin
      Widget_Control, npinfo.npycenterField, Get_Value = temp
      (*npinfo.info.roi).npycenter = temp
      end
    npinfo.centButton: begin
      xc = float((*npinfo.info.roi).radxcent)/(*npinfo.info.roi).roizoom + $
	(*npinfo.info.roi).roixorig
      yc = float((*npinfo.info.roi).radycent)/(*npinfo.info.roi).roizoom + $
	(*npinfo.info.roi).roiyorig
      (*npinfo.info.roi).npxcenter = xc
      (*npinfo.info.roi).npycenter = yc
      Widget_Control, npinfo.npxcenterField, Set_Value = xc
      Widget_Control, npinfo.npycenterField, Set_Value = yc
      end
    npinfo.facenterField: begin
      Widget_Control, npinfo.facenterField, Get_Value = temp
      (*npinfo.info.roi).facenter = temp[0]
      end
    npinfo.lacenterField: begin
      Widget_Control, npinfo.lacenterField, Get_Value = temp
      (*npinfo.info.roi).lacenter = temp[0]
      end
    npinfo.awidthField: begin
      Widget_Control, npinfo.awidthField, Get_Value = temp
      (*npinfo.info.roi).awidth = temp[0]
      end
    npinfo.aincrField: begin
      Widget_Control, npinfo.aincrField, Get_Value = temp
      (*npinfo.info.roi).aincr = temp[0]
      end
    npinfo.xpixField: begin
      Widget_Control, npinfo.xpixField, Get_Value = temp
      (*npinfo.info.roi).pxscale = temp[0]
      end
    npinfo.ypixField: begin
      Widget_Control, npinfo.ypixField, Get_Value = temp
      (*npinfo.info.roi).pyscale = temp[0]
      end
    npinfo.mButtons: begin
      ; set to compute mean or median
      (*npinfo.info.roi).npmm = event.value
      end
    npinfo.computeButton: begin
      x1 = (*npinfo.info.roi).roixorig
      x2 = (*npinfo.info.roi).roixend
      y1 = (*npinfo.info.roi).roiyorig
      y2 = (*npinfo.info.roi).roiyend
      Widget_Control, npinfo.npxcenterField, Get_Value = temp
      (*npinfo.info.roi).npxcenter = temp
      xcen = temp
      if xcen lt x1 or xcen gt x2 then begin
	test = Dialog_Message('xcenter outside ROI area')
	return
      endif
      Widget_Control, npinfo.npycenterField, Get_Value = temp
      (*npinfo.info.roi).npycenter = temp
      ycen = temp
      if ycen lt y1 or ycen gt y2 then begin
	test = Dialog_Message('ycenter outside ROI area')
	return
      endif
      Widget_Control, npinfo.awidthField, Get_Value = temp
      (*npinfo.info.roi).awidth = temp[0]
      wid = temp[0]
      if wid lt 0.01 then begin
	test = Dialog_Message('Invalid value for annulus width')
	return
      endif
      Widget_Control, npinfo.facenterField, Get_Value = temp
      (*npinfo.info.roi).facenter = temp[0]
      bgann = temp[0]
      if bgann lt wid*0.5 then begin
	test = Dialog_Message('Beginning center too small')
	return
      endif
      Widget_Control, npinfo.lacenterField, Get_Value = temp
      (*npinfo.info.roi).lacenter = temp[0]
      enann = temp[0]
      if enann lt bgann then begin
	test = Dialog_Message('Ending center must be >= beginning center')
	return
      endif
      Widget_Control, npinfo.aincrField, Get_Value = temp
      (*npinfo.info.roi).aincr = temp[0]
      incr = temp[0]
      if incr lt 0.01 then begin
	test = Dialog_Message('Invalid value for increment')
	return
      endif
      Widget_Control, npinfo.xpixField, Get_Value = temp
      (*npinfo.info.roi).pxscale = temp[0]
      pxscale = temp[0]
      if pxscale le 0.0 then begin
	test = Dialog_Message('Invalid x pixel scale')
	return
      endif
      Widget_Control, npinfo.ypixField, Get_Value = temp
      (*npinfo.info.roi).pyscale = temp[0]
      pyscale = temp[0]
      if pyscale le 0.0 then begin
	test = Dialog_Message('Invalid y pixel scale')
	return
      endif

      xb = x1 < x2
      xb = xb > 0
      xe = x2 > x1
      yb = y1 < y2
      yb = yb > 0
      ye = y2 > y1
      if (*npinfo.info.roi).msk EQ 1 then begin
	tmpmask = *(*npinfo.info.roi).mask
	xoff = (*npinfo.info.roi).msk_xoff
	yoff = (*npinfo.info.roi).msk_yoff
	goodval = (*npinfo.info.roi).maskgood
	mask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
      endif
      nannuli = fix((enann - bgann)/incr + 0.5) + 1
      if nannuli le 0 or nannuli gt 400 then begin
	test = Dialog_Message('Too few/many annuli - check parameters!')
	return
      endif
      means = fltarr(nannuli)
      stdev = fltarr(nannuli)
      npts = intarr(nannuli)
      area = fltarr(nannuli)
      acntr = fltarr(nannuli)
      nrej = intarr(nannuli)
      nrej[*] = 0
      pospts = (xe - xb + 1) * (ye - yb + 1)
      dat = fltarr(pospts)
      for k = 0, nannuli-1 do begin
	inner = bgann - (wid*0.5) + (k * incr)
	outer = inner + wid
	acntr[k] = bgann + k * incr
	inner_x = inner/pxscale
	outer_x = outer/pxscale
	inner_y = inner/pyscale
	outer_y = outer/pyscale
	minx = FIX(xcen - outer_x + 0.5) > xb
	maxx = FIX(xcen + outer_x + 0.5) < xe
	miny = FIX(ycen - outer_y + 0.5) > yb
	maxy = FIX(ycen + outer_y + 0.5) < ye
	npt = 0
	for j = miny, maxy do begin
	  for i = minx, maxx do begin
	    r = sqrt((i-xcen)^2 + (j-ycen)^2) 
	    if (r LE outer_x) AND (r GE inner_x) then begin
	      if (*npinfo.info.roi).msk EQ 0 then begin
		dat[npt] = (*npinfo.info.dispim)[i,j]
		npt = npt + 1
	      endif else begin	
	        if mask[i,j] EQ (*npinfo.info.roi).maskgood then begin 
		    dat[npt] = (*npinfo.info.dispim)[i,j]
		    npt = npt + 1
                endif else begin
		  nrej[k] = nrej[k] + 1
                endelse
              endelse
            endif
          endfor
        endfor
	npts[k] = npt
	domedian = (*npinfo.info.roi).npmm
	if npt gt 1 then begin
	  if domedian eq 0 then begin
	    results = moment(dat[0:npt-1])
	    means[k] = results[0]
	    stdev[k] = sqrt(results[1])
	    area[k] = pxscale * pyscale * npt
          endif else begin
	    med = median(dat[0:npt-1], /Even)
	    std = sqrt(total((dat[0:npt-1]-med)^2)/(npt-1))
	    means[k] = med
	    stdev[k] = std
	    area[k] = pxscale * pyscale * npt
          endelse
        endif else if npt eq 1 then begin
	  means[k] = dat[0]
	  stdev[k] = 0.
	  area[k] = pxscale * pyscale
        endif else begin
	  means[k] = 0.
	  stdev[k] = 0.
	  area[k] = 0.
        endelse
	if k eq 0 then begin 
	  st1 = 'stddev   no.points    area      rej pix'
	  st2 = 'NoiseProf: cntr radius    '
	  if domedian eq 0 $
	     then str = st2 + 'mean        ' + st1 $
             else str = st2 + 'median       ' + st1
	  idp3_updatetxt, npinfo.info, str
        endif
	cntr = string(acntr[k],'$(f8.3)')
	str = 'NoiseProf: ' +  cntr + string(means[k]) + string(stdev[k]) + $
	  string(npts[k]) + string(area[k]) + string(nrej[k])
        idp3_updatetxt, npinfo.info, str
      endfor
      if nannuli gt 2 then begin
        drawfield_id = npinfo.info.npfdraw
	wset, drawfield_id
	if (*npinfo.info.nprf).oplot eq 0 then begin
  	  erase
	  yr = fltarr(2)
	  if npinfo.info.np_autoscl eq 1 then begin
	    yr[0] = min(stdev)
	    yr[1] = max(stdev)
	    str1 = strtrim(string(yr[0]),2)
	    str2 = strtrim(string(yr[1]),2)
	    Widget_Control, npinfo.info.npfymintxt, Set_Value=str1
	    Widget_Control, npinfo.info.npfymaxtxt, Set_Value=str2
          endif else begin
	    Widget_Control, npinfo.info.npfymintxt, Get_Value = temp
	    yr[0] = float(temp)
	    Widget_Control, npinfo.info.npfymaxtxt, Get_Value = temp
	    yr[1] = float(temp)
          endelse
	  if npinfo.info.plot_xscale eq 1 then xsc = 1 else xsc = 2
	  if npinfo.info.plot_yscale eq 1 then ysc = 1 else ysc = 2
	  if (*npinfo.info.nprf).log eq 0 then $
	    plot, acntr, stdev, color=!d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	      xtitle = 'Radius of Annulus Center', $
	      ytitle = 'One Sigma', yrange=yr else $
            plot, acntr, stdev, color=!d.n_colors-1, ystyle=ysc, xstyle=xsc, $
	      xtitle = 'Radius of Annulus Center', $
	      ytitle = 'One Sigma', yrange=yr, /ylog
        endif else begin
	  linsty = (npinfo.info.nprfline + 1) MOD 6
	  oplot, acntr, stdev, linestyle=linsty
	  npinfo.info.nprfline = linsty
        endelse
      endif
      if ptr_valid(npinfo.info.noispx) then ptr_free,npinfo.info.noispx
      npinfo.info.noispx = ptr_new(acntr)
      if ptr_valid(npinfo.info.noispy) then ptr_free,npinfo.info.noispy
      npinfo.info.noispy = ptr_new(stdev)
      if ptr_valid(npinfo.info.noispm) then ptr_free,npinfo.info.noispm
      npinfo.info.noispm = ptr_new(means)
      if ptr_valid(npinfo.info.noispp) then ptr_free,npinfo.info.noispp
      npinfo.info.noispp = ptr_new(npts)
      if ptr_valid(npinfo.info.noispa) then ptr_free, npinfo.info.noispa
      npinfo.info.noispa = ptr_new(area)
      if ptr_valid(npinfo.info.noispr) then ptr_free, npinfo.info.noispr
      npinfo.info.noispr = ptr_new(nrej)
      ; Make sure we've got a fresh copy of the 'info' structure to pass to 
      ; display.
      Widget_Control, event.top, Set_UValue=npinfo
      Widget_Control, npinfo.info.idp3Window, Set_UValue=npinfo.info

      ;Update the display.
      idp3_display,npinfo.info

      ; Make sure we save the updated 'info' structure back into this widget's
      ; 'npinfo' structure.
      Widget_Control, npinfo.info.idp3Window, Get_UValue=tempinfo
      npinfo.info = tempinfo
      Widget_Control, event.top, Set_UValue=npinfo
      end
  else:
  endcase

  ; Make sure we've got a fresh copy of the 'info' structure to pass to display.
  Widget_Control, event.top, Set_UValue=npinfo
  Widget_Control, npinfo.info.idp3Window, Set_UValue=npinfo.info

   ;Update the display.
   ;idp3_display,npinfo.info

  ; Make sure we save the updated 'info' structure back into this widget's
  ; 'npinfo' structure.
  Widget_Control, npinfo.info.idp3Window, Get_UValue=tempinfo
  npinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=npinfo

end


pro Idp3_NoiseProf, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_noiseprof')) then return

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  sclfnd = 0
  domm = (*info.roi).npmm
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    m = (*info.images)[i]
    if (*m).vis eq 1 then begin
      if (*m).xplate LE 0.0 OR (*m).yplate LE 0.0 then begin
	str = 'Image: ' + (*m).name + ' has undefined pixel scale'
	test = Dialog_Message(str)
      endif else begin
	if sclfnd eq 0 then begin
	  defxscl = (*m).xplate / (*m).zoom
	  defyscl = (*m).yplate / (*m).zoom
	  sclfnd = 1
        endif else begin
	  deltax = abs(((*m).xplate / (*m).zoom) - defxscl)
	  deltay = abs(((*m).yplate / (*m).zoom) - defyscl)
	  if deltax gt defxscl * 0.02 then begin
	    str = 'X pixel scale for ' + (*m).name + ' deviates by more than 2%'
	    test = Dialog_Message(str)
          endif
	  if deltay gt defyscl * 0.02 then begin
	    str = 'Y pixel scale for ' + (*m).name + ' deviates by more than 2%'
	    test = Dialog_Message(str)
          endif
	endelse
      endelse
    endif
  endfor
  if n_elements(defxscl) GT 0 then (*info.roi).pxscale = defxscl else $
    (*info.roi).pxscale = 0.0
  if n_elements(defyscl) GT 0 then (*info.roi).pyscale = defyscl else $
    (*info.roi).pyscale = 0.0
   
  npWindow = Widget_base(Title = 'IDP3-ROI Noise Profile', /Column, $
			 Group_Leader = info.idp3Window, $
			 XOffset = info.wpos.npwp[0], $
			 YOffset = info.wpos.npwp[1])
  info.npBase = npWindow
  Widget_Control, tinfo.idp3Window, Set_UValue=info
  
  mBase = Widget_Base(npWindow,/Row)
;  mnames = ['Mean', 'Median']
;  mButtons = cw_bgroup(mbase, mnames, row=1, $
;    label_left = 'Type: ', uvalue='mbutton', $
;    set_value = domm, exclusive=1)
;  computeButton = Widget_Button(mBase, Value='Compute')
  lab = Widget_Label(mbase, Value=$
    '                                                       ')
  saveButton = Widget_Button(mbase, Value='Save', $
      Event_Pro = 'idp3_savenoiseprof')
  printButton = Widget_Button(mbase, Value='Print', $
      Event_Pro = 'idp3_printnoiseprof')
  helpButton = Widget_Button(mbase, Value='Help', $
      Event_Pro = 'noiseprof_help')
  doneButton = Widget_Button(mBase,Value='Done',Event_Pro='NoiseProf_Done')
  npfdraw = Widget_Draw(npWindow, xsize=520, ysize=350, retain=info.retn)
  pBase = Widget_Base(npWindow, /Row)
  autoButton = cw_bgroup(pbase, ['Autoscale'], row = 1, $
    /nonexclusive, Set_Value=[info.np_autoscl], Event_Funct='noiseprof_scale')
  logButton = cw_bgroup(pbase, ['Log Scale'], row=1, /nonexclusive, $
    Set_Value=[(*info.nprf).log], Event_Funct='noiseprof_logscale')
  oplotbutton = cw_bgroup(pbase, ['OverPlot'], row=1, /nonexclusive, $
    Set_Value = [(*info.nprf).oplot], Event_funct='noiseprof_oplot')
  lab1 = Widget_Label(pbase, Value='    Ymin:')
  npfymintxt = Widget_Text(pbase, Value='0.', xsize=9, $
    Event_Pro='noiseplot_ymin', /Edit)
  lab2 = Widget_Label(pbase, Value='Ymax:')
  npfymaxtxt = Widget_Text(pbase, Value='0.', xsize=9, $
    Event_Pro='noiseplot_ymax', /Edit)
  zBase = Widget_Base(npWindow, /Row)
  npxcenterField = cw_field(zBase,value=(*info.roi).npxcenter,$
			  title='xcenter:', $
                          uvalue='xcenter', xsize=8, /Return_Events, /Floating)
  npycenterField = cw_field(zBase,value=(*info.roi).npycenter,$
			  title=' ycenter:', $
                          uvalue='ycenter', xsize=8, /Return_Events, /Floating)
  lab4 = Widget_Label(zBase, Value='     ')
  centbutton = Widget_Button(zBase, Value='Get Centroid x,y')
  lab3 = Widget_Label(npWindow, Value=$
    '  Annulus Parameters (arcsec)')
  dBase = Widget_Base(npWindow,/Row)
  facenterField = cw_field(dBase,value=(*info.roi).facenter,title=$
			'center radii first:', $
                        uvalue='facenter', xsize=7, /Return_Events, /Floating)
  lacenterField = cw_field(dBase,value=(*info.roi).lacenter,title=$
			'last:', $
                        uvalue='lacenter', xsize=7, /Return_Events, /Floating)
  awidthField = cw_field(dBase,value=(*info.roi).awidth,title=$
			'width:', $
                        uvalue='awidth', xsize=7, /Return_Events, /Floating)
  aincrField = cw_field(dBase,value=(*info.roi).aincr,title=$
			'incr:', $
                        uvalue='aincr', xsize=7, /Return_Events, /Floating)
  pBase = Widget_Base(npWindow,/Row)
  xpixField = cw_field(pBase,value=(*info.roi).pxscale,title=$
			'pixel scale x:', $
                        uvalue='xpix', xsize=9, /Return_Events, /Floating)
  ypixField = cw_field(pBase,value=(*info.roi).pyscale,title=$
			'y:', $
                        uvalue='ypix', xsize=9, /Return_Events, /Floating)
  mnames = ['Mean', 'Median']
  mButtons = cw_bgroup(pBase, mnames, row=1, $
    label_left = '   Type:', uvalue='mbutton', $
    set_value = domm, exclusive=1)
  computeButton = Widget_Button(pBase, Value='Compute')

  npinfo = { npxcenterField   : npxcenterField, $
             npycenterField   : npycenterField, $
	     centButton       : centButton,     $
             facenterField    : facenterField,  $
             lacenterField    : lacenterField,  $
             awidthField      : awidthField,    $
	     aincrField       : aincrField,     $
	     xpixField        : xpixField,      $
	     ypixField        : ypixField,      $
	     mButtons         : mButtons,       $
             computeButton    : computeButton,  $
	     info             : info          }

  Widget_Control, npWindow, Set_UValue=npinfo

  Widget_Control, npWindow, /Realize

  Widget_Control, npfdraw, Get_Value=drawfield_id
  wset, drawfield_id
  npinfo.info.npfdraw = drawfield_id
  npinfo.info.npfymintxt = npfymintxt
  npinfo.info.npfymaxtxt = npfymaxtxt
  npinfo.info.nplogbutton = logbutton
  npinfo.info.npautobutton = autobutton
  npinfo.info.npoplotbutton = oplotbutton
  Widget_Control,npinfo.info.idp3Window,Set_UValue=npinfo.info
  Widget_Control,event.top, set_UValue=npinfo.info
  XManager, 'idp3_noiseprof', npWindow, /No_Block,  $
	    Event_Handler='NoiseProf_Event'
end

