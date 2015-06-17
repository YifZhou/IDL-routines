function rhist_scale, Event
  widget_control, event.top, Get_UValue=histinfo
  widget_control, histinfo.info.idp3Window, Get_UValue=info
  widget_control, info.rhautobutton, Get_Value = barray
  if barray[0] eq 0 then info.rh_autoscl = 0 else info.rh_autoscl = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  roi_display, info
end

function rhist_log, Event
  widget_control, event.top, Get_UValue=histinfo
  widget_control, histinfo.info.idp3Window, Get_UValue=info
  widget_control, info.rhlogbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.rhist).log = 0 else (*info.rhist).log = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  idp3_display, info
end
  
pro roi_histdraw, histinfo

  hxtitle = 'Pixel Values'
  hxltitle = 'Log(Pixel Values)'
  hxstitle = 'Sqrt(Pixel Values)'
  hytitle = 'Number of Pixels'
  hyltitle = 'Log(Number of Pixels)'

  roi = histinfo.info.roi
  info = histinfo.info
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend
  zoom = (*roi).roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = info.roiioz
  sdispim = idp3_scaldisplay(info)
  if zoom ne 1.0 then begin
    data = idp3_congrid(sdispim[x1:x2,y1:y2],xsize,ysize,zoom,ztype,info.pixorg)
    if info.zoomflux eq 1 then data = data / (zoom*zoom)
  endif else begin
    data = sdispim[x1:x2,y1:y2]
  endelse
  sdispim = 0
  roimask = intarr(xsize,ysize)
  roimask[*,*] = (*roi).maskgood
  if (*roi).maskgood eq 1 then maskbad = 0 else maskbad = 1
  if info.imscl eq 1 then begin
    data = alog10(data)
    xstr = hxltitle
  endif else if info.imscl eq 2 then begin
    data = sqrt(data)
    xstr = hxstitle
  endif else xstr = hxtitle
  if (*roi).msk eq 1 then begin
    tmpmask = (*(*roi).mask)
    xoff = (*roi).msk_xoff
    yoff = (*roi).msk_yoff
    goodval = (*roi).maskgood
    mask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
    roimask = congrid(mask,xsize,ysize)
  endif
  if info.exclude_invalid gt 0 then begin
    tmpoim = *(info.dispim)
    tmpim = congrid(tmpoim[x1:x2,y1:y2], xsize, ysize)
    bad = where(tmpim eq info.invalid, bcnt)
    if bcnt gt 0 then roimask[bad] = maskbad
  endif
  good = where(roimask eq (*roi).maskgood, cnt)
  btotal = where(roimask ne (*roi).maskgood, bcnt)
  print, 'Histogram: ', bcnt, ' bad pixels found'
  Widget_Control, histinfo.nbinsField, Get_Value=numbins
  if numbins lt 1 then numbins = 1
  if histinfo.info.rh_autoscl eq 0 then begin
    Widget_Control, histinfo.hminField, Get_Value=hmin
    Widget_Control, histinfo.hmaxField, Get_Value=hmax
  endif else begin
    if cnt gt 0 then begin
      hmin = min(data[good])
      hmax = max(data[good])
    endif else begin
      hmin = min(data)
      hmax = max(data)
    endelse
    Widget_Control, histinfo.hminField, Set_Value = hmin
    Widget_Control, histinfo.hmaxField, Set_Value = hmax
    histinfo.info.histmin = hmin
    histinfo.info.histmax = hmax
  endelse
  binsize = (hmax-hmin) / numbins
  histinfo.info.histbins = numbins
  if (binsize eq 0.0) then binsize = 1.0
  if cnt gt 0 then begin
    hist = histogram(data[good],binsize=binsize,min=hmin,max=hmax,$
           omin=omin,omax=omax) 
    aa = where(data[good] eq 0., histcnt)
    print, histcnt, ' pixels = 0.'
  endif else begin
    hist = histogram(data,binsize=binsize,min=hmin,max=hmax, $
	   omin=omin,omax=omax) 
  endelse
  x_ax = findgen(n_elements(hist)+1)+float(omin/binsize)
  x_ax = x_ax*binsize
  histf = float(hist)
  if (*info.rhist).log eq 0 then begin
    ystr = hytitle
    plot,x_ax,histf,xtitle=xstr,ytitle=ystr, xstyle=1,ystyle=2,psym=10,$
      position=[.15,.15,.95,.90], xrange=[min(x_ax),max(x_ax)],/noclip
  endif else begin
    ystr = hyltitle
    plot,x_ax,histf,xtitle=xstr,ytitle=ystr, xstyle=1,ystyle=2,psym=10,$
      position=[.15,.15,.95,.90], xrange=[min(x_ax),max(x_ax)],/noclip, /ylog
  endelse
  npt = n_elements(histf) - 1
  hxlo = x_ax[0]
  hxhi = x_ax[npt]
  Widget_Control, histinfo.hminField, SET_VALUE = hxlo
  Widget_Control, histinfo.hmaxField, SET_VALUE = hxhi
  histinfo.info.histmin = hxlo
  histinfo.info.histmax = hxhi
  if ptr_valid(histinfo.info.rhisto) then ptr_free, histinfo.info.rhisto
  histinfo.info.rhisto = ptr_new(histf)
  if ptr_valid(histinfo.info.rh_xax) then ptr_free, histinfo.info.rh_xax
  histinfo.info.rh_xax = ptr_new(x_ax)
end

pro Hist_Done, event
  Widget_Control, event.top, /Destroy
end

pro Hist_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=histinfo
  Widget_Control, histinfo.info.idp3Window, Get_UValue=tempinfo
  histinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=histinfo

  histfield_id = histinfo.info.histdraw
  wset, histfield_id
  histf = *(histinfo.info.rhisto)
  x_ax = *(histinfo.info.rh_xax)
  Widget_Control, histinfo.hmaxField, Get_Value = hmax
  Widget_Control, histinfo.hminField, Get_Value = hmin
  Widget_Control, histinfo.nbinsField, Get_Value = numbins
  binsize = (hmax-hmin) / numbins

  case event.id of

    histinfo.histField: begin
      n = n_elements(histf)
      if n gt 0 then begin
        x = event.x
        y = event.y
        c = convert_coord(x,y, /device, /to_data)
        c2 = convert_coord(x,y,/device, /to_normal)
        x = c(0)
        off = ((c2[0]-.15)/.80) * n 
	offset = off * binsize
        if (off gt 0 and off lt (n-1)) then begin
            press = event.press
	    Widget_Control, histinfo.hminField, Get_Value = hxlo_old
            if press eq 1 then begin
              ; they pressed the left mouse button, reset the minimum.
	      hxlo = offset + hxlo_old
	      Widget_Control, histinfo.hminField, Set_Value = hxlo
              histinfo.info.histmin = hxlo
	      histinfo.info.rh_autoscl = 0
	      Widget_Control, histinfo.info.rhautobutton, Set_Value = 0
              Widget_Control, histinfo.nsigField, SET_VALUE = ''
	      roi_histdraw, histinfo
            endif else if (press eq 4) then begin
              ; they pressed the non-left mouse button, reset the maximum.
	      hxhi = offset + hxlo_old
	      Widget_Control, histinfo.hmaxField, Set_Value = hxhi
              Widget_Control, histinfo.nsigField, SET_VALUE = ''
              histinfo.info.histmax = hxhi
	      histinfo.info.rh_autoscl = 0
	      Widget_Control, histinfo.info.rhautobutton, Set_Value = 0
	      roi_histdraw, histinfo
            endif
        endif
      endif
    end

  histinfo.hminField: BEGIN
    Widget_Control, histinfo.hminField, GET_VALUE = hxlo
    Widget_Control, histinfo.hmaxField, GET_VALUE = hxhi
    histinfo.info.histmin = hxlo
    histinfo.info.histmax = hxhi
    histinfo.info.rh_autoscl = 0
    Widget_Control,histinfo.info.rhautobutton,Set_Value=0
    if hxlo lt hxhi then begin
      roi_histdraw, histinfo
      Widget_Control, histinfo.nsigField, SET_VALUE = ''
    endif
  end

  histinfo.hmaxField: BEGIN
    Widget_Control, histinfo.hmaxField, GET_VALUE = hxhi
    Widget_Control, histinfo.hminField, GET_VALUE = hxlo
    histinfo.info.histmin = hxlo
    histinfo.info.histmax = hxhi
    histinfo.info.rh_autoscl = 0
    Widget_Control, histinfo.info.rhautobutton,Set_Value=0
    if hxhi gt hxlo then begin
      roi_histdraw, histinfo
      Widget_Control, histinfo.nsigField, SET_VALUE = ''
    endif
  end

  histinfo.nsigField: BEGIN
    Widget_Control, histinfo.hmaxField, GET_VALUE = hxhi_old
    Widget_Control, histinfo.hminField, GET_VALUE = hxlo_old
    Widget_Control, histinfo.nsigField, GET_VALUE = snsig
    nsig = float(snsig)
    roi = histinfo.info.roi
    info = histinfo.info
    x1 = (*roi).roixorig
    y1 = (*roi).roiyorig
    x2 = (*roi).roixend
    y2 = (*roi).roiyend
    zoom = (*roi).roizoom
    xsize = (abs(x2-x1)+1) * zoom
    ysize = (abs(y1-y1)+1) * zoom
    ztype = info.roiioz
    roimask = intarr(xsize,ysize)
    roimask[*,*] = (*roi).maskgood
    if (*roi).maskgood eq 1 then maskbad = 0 else maskbad = 1
    if (*roi).msk eq 1 then begin
      tmpmask = (*(*roi).mask)
      xoff = (*roi).msk_xoff
      yoff = (*roi).msk_yoff
      goodval = (*roi).maskgood
      mask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
      roimask = congrid(mask,xsize,ysize)
    endif
    if info.exclude_invalid gt 0 then begin
      tmpoim = *(info.dispim)
      tmpim = congrid(tmpoim[x1:x2,y1:y2], xsize, ysize)
      bad = where(tmpim eq info.invalid, bcnt)
      if bcnt gt 0 then roimask[bad] = maskbad
    endif
    good = where(roimask eq (*roi).maskgood, cnt)
    bad = where(roimask ne (*roi).maskgood, bcnt)
    print, 'Histogram: ', bcnt, ' bad pixels found'
    sdispim = idp3_scaldisplay(info)
    if zoom ne 1.0 then begin
      data = idp3_congrid(sdispim[x1:x2,y1:y2], xsize, ysize, zoom,$
	     ztype,info.pixorg)
      if info.zoomflux eq 1 then data = data / (zoom*zoom)
    endif else begin
      data = sdispim[x1:x2,y1:y2]
    endelse
    sdispim = 0
    if info.imscl eq 1 then data = alog10(data)
    if info.imscl eq 2 then data = sqrt(data)
    if cnt gt 0 then begin
      mdata = data[good]
    endif else begin
      mdata = data
    endelse
    good2 = where(mdata ge hxlo_old and mdata le hxhi_old, cnt2)
    if cnt2 gt 0 then begin
      res = moment(mdata[good2])
      hxlo = res[0] - nsig * sqrt(res[1])
      hxhi = res[0] + nsig * sqrt(res[1])
    endif else begin
      hxlo = hxlo_old
      hxhi = hxhi_old
    endelse
    Widget_Control, histinfo.hminField, Set_Value = hxlo
    Widget_Control, histinfo.hmaxField, Set_Value = hxhi
    histinfo.info.rh_autoscl = 0
    Widget_Control,histinfo.info.rhautobutton,Set_Value=0
    histinfo.info.histmin = hxlo
    histinfo.info.histmax = hxhi
    roi_histdraw, histinfo
  end

  histinfo.nbinsField: BEGIN
    Widget_Control, histinfo.nbinsField, Get_Value=numbins
    if numbins gt 0 then begin
      histinfo.info.histbins = numbins
      roi_histdraw, histinfo
    endif
  end

  histinfo.hfullbutton: BEGIN
    histinfo.info.rh_autoscl = 1
    Widget_Control,histinfo.info.rhautobutton,Set_Value=1
    roi_histdraw, histinfo
  end

  else:
  endcase

  Widget_Control, histinfo.info.idp3Window, Set_UValue=histinfo.info
  Widget_Control, event.top, Set_UValue=histinfo

end

pro idp3_roihist, event

@idp3_structs
@idp3_errors
 
  if XRegistered('idp3_roihist') then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  nbins = info.histbins
  hmin = info.histmin
  hmax = info.histmax
  autoscale = info.rh_autoscl
  logscale = (*info.rhist).log

  histWindow = Widget_base(Title = 'IDP3-ROI Histogram ', /Column, $
	      Group_Leader = info.idp3Window, xoffset=info.wpos.rhwp[0], $
	      yoffset=info.wpos.rhwp[1])
    
  info.histbase = histWindow
  Widget_Control, info.idp3Window, Set_UValue=info

  histField = widget_draw(histWindow, xsize=500, ysize=300, /button_events, $
	      retain=info.retn)

  histbase = Widget_Base(histWindow, /row)
  hminField = cw_field(histbase, value=hmin, title='xmin ', $
      uvalue='hmin', xsize=8, /RETURN_EVENTS, /FLOATING)
  hmaxField = cw_field(histbase, value=hmax, title=' xmax ', $
      uvalue='hmax', xsize=8, /RETURN_EVENTS, /FLOATING)
  logbutton = cw_bgroup(histbase, ['Log Scale (Y)'], row = 1,  $
       set_value = [logscale], /nonexclusive, Event_Funct = 'rhist_log')
  autobutton = cw_bgroup(histbase, ['Auto'], row = 1,  $
       set_value = [autoscale], /nonexclusive, Event_Funct='rhist_scale')
  hist2base = Widget_Base(histWindow, /row)
  nbinsField = cw_field(hist2base, value=nbins, title='Number of bins', $
      uvalue='nbins', xsize=4, /RETURN_EVENTS, /INTEGER)
  nsigField = cw_field(hist2base, value='', title=' nsigma ', $
      uvalue='nsig', xsize=5, /RETURN_EVENTS, /STRING)
  hfullbutton = Widget_Button(hist2base, value='Full')
  printbutton = widget_button (hist2base, value='Print', Event_Pro=$
             'idp3_printhist')
  donebutton = widget_button (hist2base, value='Done', Event_Pro=$
             'hist_done')

  histinfo = { histField   : histField,   $
               hminField   : hminField,   $
	       hmaxField   : hmaxField,   $
	       nsigField   : nsigField,   $
	       nbinsField  : nbinsField,  $
	       hfullbutton : hfullbutton, $
	       info        : info         }

  Widget_Control, histWindow, Set_UValue=histinfo
  Widget_Control, histWindow, /Realize

  Widget_Control, histField, GET_VALUE = histfield_id
  histinfo.info.histdraw = histfield_id
  histinfo.info.rhautobutton = autobutton
  histinfo.info.rhlogbutton = logbutton
  Widget_Control, histinfo.info.idp3Window, Set_UValue=histinfo.info

  XManager, 'idp3_roihist', histWindow, /No_Block, $
        Event_Handler='hist_event'

  roi = info.roi
  histfield_id = histinfo.info.histdraw
  wset, histfield_id
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend
  zoom = (*roi).roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y1-y1)+1) * zoom
  ztype = info.roiioz
  if (*roi).msk eq 1 then begin
    tmpmask = (*(*roi).mask)
    xoff = (*roi).msk_xoff
    yoff = (*roi).msk_yoff
    goodval = (*roi).maskgood
    tmpmsk = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
    roimask = congrid(tmpmsk,xsize,ysize)
    good = where(roimask eq (*roi).maskgood, cnt)
  endif else cnt = -1
  sdispim = idp3_scaldisplay(info)
  if zoom ne 1.0 then begin
    data = idp3_congrid(sdispim[x1:x2,y1:y2], xsize, ysize, zoom, $
           ztype, info.pixorg)
    if info.zoomflux eq 1 then data = data / (zoom*zoom)
  endif else begin
    data = sdispim[x1:x2,y1:y2]
  endelse
  sdispim = 0
  if info.imscl eq 1 then data = alog10(data)
  if info.imscl eq 2 then data = sqrt(data)
  Widget_Control, histinfo.hminField, Get_Value=hmin
  Widget_Control, histinfo.hmaxField, Get_Value=hmax
  if autoscale eq 1 then begin
    if cnt gt 0 then begin
      hmin = min(data[good])
      hmax = max(data[good])
    endif else begin
      hmin = min(data)
      hmax = max(data)
    endelse
  endif
  Widget_Control, histinfo.hminField, Set_Value=hmin
  Widget_Control, histinfo.hmaxField, Set_Value=hmax
  roi_histdraw, histinfo

  Widget_Control, event.top, Set_UValue=histinfo.info
  Widget_Control, histinfo.info.idp3Window, Set_UValue=histinfo.info
 
  Widget_Control, histWindow, Set_UValue=histinfo
 end

