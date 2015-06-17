Pro roi_nothing, event
  a = 1
end

pro big_cursor, ix, iy, ix0, iy0
 
  device, get_graphics_function=g_fnc  ;save graphics function
  device, set_graphics_function=10      ;Use XOR writing mode
  if (ix0 GT -1) then begin    ;Erase old mark
    plots, [0, ix0-3], [iy0,iy0],/dev
    plots, [ix0-1, ix0+1], [iy0,iy0],/dev
    plots, [ix0+3, !d.x_size-1], [iy0,iy0],/dev
    plots,[ix0,ix0],[0, iy0-3],/dev
    plots, [ix0, ix0], [iy0-1,iy0+1],/dev
    plots,[ix0,ix0],[iy0+3, !d.y_size-1],/dev
  endif
  plots, [0, ix-3], [iy,iy],/dev
  plots, [ix-1, ix+1], [iy,iy],/dev
  plots, [ix+3, !d.x_size-1], [iy,iy],/dev
  plots,[ix,ix],[0, iy-3],/dev
  plots, [ix, ix], [iy-1,iy+1],/dev
  plots,[ix,ix],[iy+3, !d.y_size-1],/dev
  device, set_graphics_function=g_fnc
end

pro set_bits, info
  c1 = info.color_radpf
  c2 = info.color_poly
  c3 = info.color_innernpf
  c4 = info.color_outernpf
  c5 = info.color_xsect
  c6 = info.color_spsh
  c7 = info.color_roi
  if c1 ge 0 or c2 ge 0 or c3 ge 0 or c4 ge 0 or c5 ge 0 or c6 ge 0 or c7 ge 0 $
     then begin
       info.color_bits = 6 
       color6
  endif else info.color_bits = 0
end

pro roi_mousehelp, event
  tmp = idp3_findfile('idp3_roi_mouse.hlp')
  xdisplayfile, tmp
end

pro roi_help, event
  tmp = idp3_findfile('idp3_roi.hlp')
  xdisplayfile, tmp
end

pro roi_redisplay, event
@idp3_errors
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  roi = *info.roi
  wset, roi.drawid2
  ; Clear graphics display.
  if ptr_valid(tim) then ptr_free, tim
  tim = ptr_new(fltarr(roi.roixsize,roi.roiysize))
  tv,*tim
  ptr_free,tim
  roi_display, info
end

pro idp3_roiswitchcurs, event
@idp3_errors
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  ; Toggle cursor type.
  if (*info.roi).curs eq 0 then begin
    (*info.roi).curs = 1
    (*info.roi).fix0 = -1
    (*info.roi).fiy0 = -1
    ; Turn off cursor.
    image = intarr(16)      ; all zero for all blank
    device, cursor_image=image
  endif else begin
    ; Erase last big cursor.
    if (*info.roi).fix0 ge 0 then begin
      wset,(*info.roi).drawid2
      device, get_graphics_function=g_fnc  ;save graphics function
      device, set_graphics_function=10      ;Use XOR writing mode
      ix0 = (*info.roi).fix0
      iy0 = (*info.roi).fiy0
      plots, [0, ix0-3], [iy0,iy0],/dev
      plots, [ix0-1, ix0+1], [iy0,iy0],/dev
      plots, [ix0+3, !d.x_size-1], [iy0,iy0],/dev
      plots,[ix0,ix0],[0, iy0-3],/dev
      plots, [ix0, ix0], [iy0-1,iy0+1],/dev
      plots,[ix0,ix0],[iy0+3, !d.y_size-1],/dev
      device, set_graphics_function=g_fnc
      wset,info.drawid1
    endif
    (*info.roi).curs = 0
    ; Turn on cursor.
    device, cursor_standard=30
  endelse

  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
end

; routines for setting various colors in the roi
pro roi_setrpcolor, event
@idp3_errors
  ; set color of radial profile area circle
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  colors = ['Black', 'White', 'Red', 'Green', 'Blue', 'Yellow','Default']
  title = 'Select Color for Radial Profile Circle'
  idp3_selectval, tinfo.idp3Window, title, colors, value
  if value lt 6 then info.color_radpf = value else info.color_radpf = -1
  set_bits, info
  if value lt 0 then value = 200
  if XRegistered('idp3_radprof') then begin
    ; Redraw the radial profile.
    wset,(*info.roi).drawid2
    th=fltarr(361)
    for i=0,360 do th(i)=float(i)*(!pi/180.)
    plots,(*info.roi).radradius*cos(th)+(*info.roi).radxcent, $
      (*info.roi).radradius*sin(th)+(*info.roi).radycent,color=value,/device
  endif
  Widget_Control, tinfo.idp3Window, Set_UValue=info
end

pro roi_setxscolor, event
@idp3_errors
  ; set color of cross section line 
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  colors = ['Black', 'White', 'Red', 'Green', 'Blue', 'Yellow','Default']
  title = 'Select Color for Cross Section Line'
  idp3_selectval, tinfo.idp3Window, title, colors, value
  if value lt 6 then info.color_xsect = value else info.color_xsect = -1
  set_bits, info
  if value lt 0 then value = 200
  if XRegistered('idp3_prof') then begin
    ; Redraw the cross section.
    wset,(*info.roi).drawid2
    roi = *info.roi
    sx = (roi.xsxstart-roi.roixorig) * roi.roizoom
    sy = (roi.xsystart-roi.roiyorig) * roi.roizoom
    ex = (roi.xsxstop-roi.roixorig) * roi.roizoom
    ey = (roi.xsystop-roi.roiyorig) * roi.roizoom
    plots, [sx,ex], [sy,ey], color=value, /device
  endif
  Widget_Control, tinfo.idp3Window, Set_UValue=info
end

pro roi_setpolycolor, event
@idp3_errors
  ; set color of polygon
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  colors = ['Black', 'White', 'Red', 'Green', 'Blue', 'Yellow','Default']
  title = 'Select Color for Radial Profile Circle'
  idp3_selectval, tinfo.idp3Window, title, colors, value
  if value lt 6 then info.color_poly = value else info.color_poly = -1
  set_bits, info
  if value lt 0 then value = 200
  if XRegistered('idp3_polystatistics') then begin
    ; Redraw the polygon.
    wset,(*info.roi).drawid2
    roi = *info.roi
    pts = roi.polypts
    x1 = roi.roixorig
    x2 = roi.roixend
    y1 = roi.roiyorig
    y2 = roi.roiyend
    if pts ge 3 then begin
      zoom = roi.roizoom
      xpts = (*roi.polyx - x1) * zoom
      ypts = (*roi.polyy - y1) * zoom
      out_of_bounds = 0
      for i = 0, pts-1 do begin
	if xpts[i] gt (x2-x1+1)*zoom then out_of_bounds = 1
	if ypts[i] gt (y2-y1+1)*zoom then out_of_bounds = 1
      endfor
      if out_of_bounds eq 0 then begin
        plots, xpts[0], ypts[0], color=value, /device
	for i = 1, pts do begin
	  plots, xpts[i],ypts[i], color=value, /device, /continue
	endfor
      endif
    endif
  endif
  Widget_Control, tinfo.idp3Window, Set_UValue=info
end

pro roi_setnpcolor, event
@idp3_errors
  ; set color of noise profile radii
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  colors = ['Black', 'White', 'Red', 'Green', 'Blue', 'Yellow','Default']
  title = 'Select Color for Inner Edge of Noise Profile Annuli'
  idp3_selectval, tinfo.idp3Window, title, colors, vali
  if vali lt 6 then info.color_innernpf = vali else info.color_innernpf = -1
  title = 'Select Color for Outer Edge of Noise Profile Annuli'
  idp3_selectval, tinfo.idp3Window, title, colors, valo
  if valo lt 6 then info.color_outernpf = valo else info.color_outernpf = -1
  set_bits, info
  if vali lt 0 then vali = 200
  if valo lt 0 then valo = 200
  if XRegistered('idp3_noiseprof') then begin
    ; Redraw the noise profile.
    wset,(*info.roi).drawid2
    roi = *info.roi
    th=fltarr(361)
    xcenter = (roi.npxcenter - roi.roixorig) * roi.roizoom
    ycenter = (roi.npycenter - roi.roiyorig) * roi.roizoom
    nannuli = fix((roi.lacenter - roi.facenter)/roi.aincr + 0.5) + 1
    for i=0,360 do th(i)=float(i)*(!pi/180.)
    for j = 0, nannuli - 1 do begin
      inner=((roi.facenter-(roi.awidth*0.5)+(j*roi.aincr))/roi.pxscale) $
	  *roi.roizoom
      plots,inner*cos(th)+xcenter,inner*sin(th)+ycenter,color=vali,/device
    endfor
    for j = 0, nannuli - 1 do begin
      outer=((roi.facenter+(roi.awidth*0.5)+(j*roi.aincr))/roi.pxscale) $
	* roi.roizoom
      plots,outer*cos(th)+xcenter,outer*sin(th)+ycenter,color=valo,linestyle=1,$
	 /device
    endfor
  endif
  Widget_Control, tinfo.idp3Window, Set_UValue=info
end

pro roi_polyundo, event
@idp3_errors
  ; restore last defined polygon
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  if (*info.roi).polypts ge 3 and (*info.roi).spolypts ge 3 then begin 
    wset, (*info.roi).drawid2
    tv, *(*info.roi).roiimage
    zoom = (*info.roi).roizoom
    xo = (*info.roi).roixorig 
    yo = (*info.roi).roiyorig
    ptr_free, (*info.roi).polyx
    ptr_free, (*info.roi).polyy
    xpts = *(*info.roi).savpolyx
    ypts = *(*info.roi).savpolyy
    pts = (*info.roi).spolypts
    (*info.roi).polyx = ptr_new(xpts)
    (*info.roi).polyy = ptr_new(ypts)
    ptr_free, (*info.roi).savpolyx
    ptr_free, (*info.roi).savpolyy
    (*info.roi).spolypts = 0
    pcl = info.color_poly
    if pcl lt 0 then pcl = 200
    plots, (xpts[0]-xo)*zoom,(ypts[0]-yo)*zoom, color=pcl, /device
    for i = 1, pts do begin
      plots,(xpts[i]-xo)*zoom,(ypts[i]-yo)*zoom,color=pcl,/device,/continue
    endfor
    geo = Widget_Info(info.polystats, /geometry)
    info.wpos.pswp[0] = geo.xoffset - info.xoffcorr
    info.wpos.pswp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, info.polystats, /Destroy
    idp3_polystatistics, info
    Widget_Control, tinfo.idp3Window, Set_UValue=info
    Widget_Control, event.top, Set_UValue=tinfo
  endif
end

pro roi_polymask, event
; set special mask to polygon region
@idp3_errors
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  x1 = (*info.roi).roixorig
  y1 = (*info.roi).roiyorig
  x2 = (*info.roi).roixend
  y2 = (*info.roi).roiyend
  if (*info.roi).polymsk gt 0 and ptr_valid((*info.roi).polymask) then begin
    pmask = *((*info.roi).polymask)
    pmsz = size(pmask)
    px2 = pmsz[1]-1
    py2 = pmsz[2]-1
    if (*info.roi).msk gt 0 then begin
      mask = *((*info.roi).mask)
      msz = size(mask)
      mx2 = msz[1]-1
      my2 = msz[2]-1
      if x2 gt mx2 then xdelt = x2-mx2 else xdelt=0
      if y2 gt my2 then ydelt = y2-my2 else ydelt=0
      bad = where(mask ne (*info.roi).maskgood, count)
      if count gt 0 then badval = mask[bad] 
      mask[x1:x2-xdelt,y1:y2-ydelt] = pmask[0:px2-xdelt,0:py2-ydelt]
      if count gt 0 then mask[bad] = badval 
    endif else begin
      title = 'Enter dimensions of mask'
      valstr = idp3_getvals(title, '256', ds2='256', lab1='X:', lab2='Y:', $
	groupleader=info.idp3Window, cancel=cancel, ws=10, xp=400, yp=400)
      if cancel eq 1 then begin
	str = 'ROI: Entry Cancelled'
	idp3_updatetxt, info, str
	return
      endif
      mxsz = fix(valstr[0])
      mysz = fix(valstr[1])
      mask = intarr(mxsz,mysz)
      mask[*,*] = (*info.roi).maskgood
      mx2 = mxsz-1
      my2 = mysz-1
      if x2 gt mx2 then xdelt = x2-mx2 else xdelt=0
      if y2 gt my2 then ydelt = y2-my2 else ydelt=0
      bad = where(mask ne (*info.roi).maskgood, count)
      if count gt 0 then badval = mask[bad] 
      mask[x1:x2-xdelt,y1:y2-ydelt] = pmask[0:px2-xdelt,0:py2-ydelt]
      if count gt 0 then mask[bad] = badval 
      (*info.roi).msk = 1
    endelse
    if ptr_valid((*info.roi).mask) then ptr_free, (*info.roi).mask
    (*info.roi).mask = ptr_new(mask)
    roi_display, info
    Widget_Control, tinfo.idp3Window, Set_UValue=info
    Widget_Control, event.top, Set_UValue=tinfo
  endif
end

pro roi_polyundomask, event
; remove polygon region from mask
@idp3_errors
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  str = 'ROI: removing last polygon mask'
  idp3_updatetxt, info, str
  x1 = (*info.roi).roixorig
  y1 = (*info.roi).roiyorig
  x2 = (*info.roi).roixend
  y2 = (*info.roi).roiyend
  if (*info.roi).polymsk gt 0 and (*info.roi).msk gt 0 then begin
    if ptr_valid((*info.roi).polymask) and ptr_valid((*info.roi).mask) $
      then begin
      (*info.roi).polymsk = 0
      mask = *((*info.roi).mask)
      pmask = *((*info.roi).polymask)
      pmsz = size(pmask)
      msz = size(mask)
      mx2 = msz[1]-1
      my2 = msz[2]-1
      px2 = pmsz[1]-1
      py2 = pmsz[2]-1
      if x2 gt mx2 then xdelt = x2-mx2 else xdelt=0
      if y2 gt py2 then ydelt = y2-my2 else ydelt=0
      omask = mask[x1:x2-xdelt,y1:y2-ydelt]
      mask[x1:x2-xdelt,y1:y2-ydelt] = pmask[0:px2-xdelt,0:py2-ydelt]
      bad = where(pmask[0:px2-xdelt,0:py2-ydelt] ne (*info.roi).maskgood, count)
      if count gt 0 then begin
        omask[bad] = (*info.roi).maskgood
        mask[x1:x2-xdelt,y1:y2-ydelt] = omask
	bad = where(mask ne (*info.roi).maskgood, count)
        ptr_free, (*info.roi).mask
        (*info.roi).mask = ptr_new(mask)
      endif
      roi_display, info
      Widget_Control, tinfo.idp3Window, Set_UValue=info
      Widget_Control, event.top, Set_UValue=tinfo
    endif else begin
      str = 'ROI: invalid mask data'
      idp3_updatetxt, info, str
    endelse
  endif else begin
    str = 'ROI: invalid  mask flags'
    idp3_updatetxt, info, str
  endelse
end

pro roi_Zoom1, event
@idp3_errors
  ; Set the ROI Zoom to 1.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 1
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_Zoom2, event
@idp3_errors
  ; Set the ROI Zoom to 2.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 2
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_Zoom4, event
@idp3_errors
  ; Set the ROI Zoom to 4.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 4
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_Zoom8, event
@idp3_errors
  ; Set the ROI Zoom to 8.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 8
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_Zoom16, event
@idp3_errors
  ; Set the ROI Zoom to 16.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 16 
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_Zoom32, event
@idp3_errors
  ; Set the ROI Zoom to 32.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 32
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_Zoom64, event
@idp3_errors
  ; Set the ROI Zoom to 64.
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  zoom = 64
  (*tinfo.roi).roizoom = zoom 
  (*info.roi).roizoom =  zoom
  if XRegistered('idp3_radprof') then begin
    newxc = ((*info.rprf).sx - (*info.roi).roixorig) * zoom 
    newyc = ((*info.rprf).sy - (*info.roi).roiyorig) * zoom 
    newrad = (*info.rprf).r * zoom
    (*tinfo.roi).radxcent = newxc
    (*info.roi).radxcent = newxc
    (*tinfo.roi).radycent = newyc
    (*info.roi).radycent = newyc
    (*tinfo.roi).radradius = newrad
    (*info.roi).radradius = newrad
  endif
  if XRegistered('idp3_prof') then begin
    xwid = float((*info.prof).width) / float(zoom)
    widstr = strtrim(string(xwid),2)
    swidstr = strmid(widstr,0,7)
    Widget_Control, info.profwidth, Set_Value = swidstr
    (*info.roi).xswidth = xwid
  endif
  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  Widget_Control, info.roiBase, /Destroy
  idp3_roi,info.idp3Window
end

pro roi_removemask, event
@idp3_errors
  ; Remove mask by resetting flag
  geo = Widget_Info(event.top, /geometry)
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  (*tinfo.roi).msk = 0
  (*tinfo.roi).msk_xoff = 0
  (*tinfo.roi).msk_yoff = 0
  ptr_free, (*tinfo.roi).mask
  Widget_Control, tinfo.idp3Window, Set_UValue=info
  Widget_Control, event.top, Set_UValue=tinfo
  roi_display, info
  Widget_control, info.roiBase, /Destroy
  idp3_roi, info.idp3Window
end

pro roi_orient, event
  ; Toggle orient vector flag
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  if event.select eq 1 then (*info.roi).orivec = 1 else (*info.roi).orivec = 0
  roi_display, info
end
  
pro roi_maskonoff, event

@idp3_errors
  ; Toggle mask flag
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info

  if event.select eq 1 then begin
    if ptr_valid((*info.roi).mask) then begin
      sz = size(*(*info.roi).mask)
      if sz[0] ge 2 and sz[1] gt 0 then begin
        (*tinfo.roi).msk = 1
	valid = 1
      endif else begin
	(*tinfo.roi).msk = 0
	Widget_Control, tinfo.roimskonof, Set_Button=(*tinfo.roi).msk
	valid = 0
      endelse
    endif else begin
      (*tinfo.roi).msk = 0
      valid = 0
      Widget_Control, tinfo.roimskonof, Set_Button=(*tinfo.roi).msk
    endelse
  endif else begin
    (*tinfo.roi).msk = 0
    valid = 1
  endelse
    
  Widget_Control, tinfo.idp3Window, Set_UValue=info
  Widget_Control, event.top, Set_UValue=tinfo

  if valid eq 1 then begin
    roi_display, info
    geo = Widget_Info(info.roiBase, /geometry)
    info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_control, info.roiBase, /Destroy
    idp3_roi, info.idp3Window
  endif else begin
    test = Dialog_Message("Sorry, no mask currently loaded")

  endelse
end

pro roi_maskon, event
@idp3_errors
  ; Turn loaded mask back on
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  if ptr_valid((*info.roi).mask) then begin
    sz = size(*(*info.roi).mask)
    if sz[0] ge 2 and sz[1] gt 0 then begin
      (*tinfo.roi).msk = 1
      Widget_Control, tinfo.idp3Window, Set_UValue=info
      Widget_Control, event.top, Set_UValue=tinfo
      roi_display, info
      geo = Widget_Info(info.roiBase, /geometry)
      info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
      info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
      Widget_Control, info.idp3Window, Set_UValue=info
      Widget_control, info.roiBase, /Destroy
      idp3_roi, info.idp3Window
    endif else begin
      test = Dialog_Message("Sorry, no mask currently loaded")
    endelse
  endif
end

pro roi_maskoff, event
@idp3_errors
  ; Turn loaded mask off 
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  (*tinfo.roi).msk = 0
  Widget_Control, tinfo.idp3Window, Set_UValue=info
  Widget_Control, event.top, Set_UValue=tinfo
  roi_display, info
  geo = Widget_Info(info.roiBase, /geometry)
  info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
  Widget_Control, info.idp3Window, Set_UValue=info
  Widget_control, info.roiBase, /Destroy
  idp3_roi, info.idp3Window
end

pro roi_maskinv, event
@idp3_errors
  ; Invert mask 
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  if ptr_valid((*info.roi).mask) then begin
    newmask = *(*info.roi).mask
    newmask[*,*] = (*info.roi).maskgood
    newbad = where(*(*info.roi).mask eq (*info.roi).maskgood, count)
    if count gt 0 then begin
      if (*info.roi).maskgood eq 0 then maskbad = 1 else maskbad = 0
      newmask[newbad] = maskbad
      str = 'ROI: Mask inverted with ' +  strtrim(string(count),2) + $
	' bad pixels'
      idp3_updatetxt, info, str
      ptr_free, (*info.roi).mask
      (*info.roi).mask = ptr_new(newmask)
    endif
    Widget_Control, tinfo.idp3Window, Set_UValue=info
    Widget_Control, event.top, Set_UValue=tinfo
    roi_display, info
    geo = Widget_Info(info.roiBase, /geometry)
    info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_control, info.roiBase, /Destroy
    idp3_roi, info.idp3Window
  endif
end

pro Roi_PlateScale_Event, event
@idp3_errors
  Widget_Control,event.top, Get_UValue = pinfo
  Widget_control,pinfo.info.idp3Window,Get_UValue=info

  Widget_Control,pinfo.pxtext,Get_Value=pxscl
  (*info.roi).pxscale = float(pxscl[0])
  Widget_Control,pinfo.pytext,Get_Value=pyscl
  (*info.roi).pyscale = float(pyscl[0])
  Widget_Control,event.top,/Destroy

  Widget_control,pinfo.info.idp3Window,Set_UValue=info
  pinfo.info = info
end

pro Roi_Setplate, roiinfo
@idp3_errors
  Widget_control,roiinfo.idp3Window,Get_UValue=info
  sclfnd = 0
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    m = (*info.images)[i]
    if (*m).vis eq 1 then begin
      if sclfnd eq 0 then begin
	 defxscl = (*m).xplate / (*m).zoom
	 defyscl = (*m).yplate / (*m).zoom
	 sclfnd = 1
       endif
    endif
  endfor
  if defxscl eq 0.0 and defyscl eq 0.0 then begin
    defxscl = (*info.roi).pxscale
    defyscl = (*info.roi).pyscale
  endif	
  xsclstr=string(defxscl) 
  ysclstr=string(defyscl) 
  
  psclmain = Widget_Base(xoffset=info.wpos.cfwp[0],yoffset=info.wpos.cfwp[1], $
		 /Row, Title='IDP3-ROI Polygon Statistics, Request Plate Scale')
  pxtext = Widget_Text  (psclmain, Value = xsclstr, XSize = 20, /Edit, $
			   Event_Pro='Idp3_Nothing')
  pytext = Widget_Text  (psclmain, Value = ysclstr, XSize = 20, /Edit, $
			   Event_Pro='Idp3_Nothing')
  psdone = Widget_Button(psclmain, Value = 'Done', $
			   Event_Pro='Roi_PlateScale_Event')
  psclinfo = {pxtext : pxtext, $
	      pytext : pytext, $
	      psdone : psdone, $
	      info     : info      }

  Widget_Control, psclmain, set_uvalue = psclinfo

  Widget_Control,psclmain,/Realize
  Xmanager,'psclmain',psclmain

end

pro Roi_DefineROD, event
@idp3_errors
  Widget_Control,event.top, Get_UValue = roiinfo
  Widget_control,roiinfo.idp3Window,Get_UValue=info
  
  ; Turn off events in the ROI window so the "annotate" widget has control.
  Widget_control,(*info.roi).roiDraw,Draw_Motion_Events=0
  Widget_control,(*info.roi).roiDraw,Draw_Button_Events=0

  ; Set draw focus to the roi draw widget and call annotate.
  wset,(*info.roi).drawid2
  annotate

  ; Read the gif file written by annotate, create the ROD.
  rod_data = read_tiff('annotate.tif')
  if ptr_valid((*info.roi).rodmask) then ptr_free,(*info.roi).rodmask
  if ptr_valid((*info.roi).roddmask) then ptr_free,(*info.roi).roddmask
  x1 = (*info.roi).roixorig
  y1 = (*info.roi).roiyorig
  x2 = (*info.roi).roixend
  y2 = (*info.roi).roiyend

  rsz = size(rod_data)
  yz = rsz[2] - 1
  nrod_data = bytarr(rsz[1],rsz[2])
  for ii = 0, yz do begin
    nrod_data[*,ii] = rod_data[*,yz-ii]
  endfor
  rodval = min(nrod_data)
  tmprod = where(nrod_data eq rodval, cnt)
  tmprodd = where(nrod_data ne rodval, dcnt)
  if cnt gt 0 and dcnt gt 0 then begin
    (*info.roi).rodmask = ptr_new(tmprod)
    (*info.roi).roddmask = ptr_new(tmprodd)
    (*info.roi).rod = 1
  endif
  Widget_control,(*info.roi).roiDraw,Draw_Motion_Events=1
  Widget_control,(*info.roi).roiDraw,Draw_Button_Events=1
  Widget_control,roiinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=info
  wset,info.drawid1
  roi_display,info
end
			   

pro roi_Display, roiinfo, roi_blink=roi_blink
@idp3_structs
@idp3_errors

  Widget_control,roiinfo.idp3Window,Get_UValue=info
  wset,(*info.roi).drawid2
  roi = *info.roi
  bits = info.color_bits
  pcl = info.color_poly
  if pcl lt 0 then pcl = 200
  rcl = info.color_radpf
  if rcl lt 0 then rcl = 200
  xcl = info.color_xsect
  if xcl lt 0 then xcl = 200
  nicl = info.color_innernpf
  if nicl lt 0 then nicl = 200
  nocl = info.color_outernpf
  if nocl lt 0 then nocl = 200
  ; special addition to turn off screen erase when blinking
  if (n_elements(roi_blink) GT 0) then rbk = 1 else rbk = 0

  ; In case the cross-hair cursor is on, reset it.
  (*info.roi).fix0 = -1
  (*info.roi).fiy0 = -1

  numon = 0
  numimages = n_elements(*info.images)
  for i = 0, numimages-1 do begin
    if ptr_valid((*info.images)[i]) then begin
      m = (*info.images)[i]
      if (*m).vis eq 1 then numon = numon + 1
    endif
  endfor
  if numon gt 0 then begin
    x1 = roi.roixorig
    y1 = roi.roiyorig
    x2 = roi.roixend
    y2 = roi.roiyend
    zoom = roi.roizoom
    xsize = (abs(x2-x1)+1) * zoom
    ysize = (abs(y2-y1)+1) * zoom
    z1 = roiinfo.z1
    z2 = roiinfo.z2
    ztype = info.roiioz
    ; Extract the ROI from the display image,zoom it appropriately,display it.
    sdispim = idp3_scaldisplay(info)
    tiim = idp3_congrid(sdispim[x1:x2,y1:y2], xsize, ysize, $
           zoom, ztype, info.pixorg)
    sdispim = 0
    alphaim = congrid((*info.alphaim)[x1:x2,y1:y2], xsize, ysize)
    bad = where(alphaim eq 0., count)
    alphaim = 0
    ; If the user in conserving flux, divide zoomed image by zoom^2.
    ; Also, in this case, divide the Z1 and Z2 by zoom^2 so it looks the same.
    if info.zoomflux eq 1 then begin
      tiim = tiim/(zoom * zoom)
      newtiim = bytscl(tiim,top=info.d_colors-bits-1, $
                min=z1/(zoom*zoom),max=z2/(zoom*zoom))
    endif else begin
      newtiim = bytscl(tiim,top=info.d_colors-bits-1,min=z1,max=z2)
    endelse
    tiim = 0
    newtiim = newtiim + bits
    if roi.rod eq 1 and n_elements(*roi.rodmask) gt 0 then begin
      ; Remark the region of disinterest.
      newtiim[*roi.rodmask] = 0
    endif
    if roi.msk eq 1 then begin
      ; Remark the masked pixels
      tmpmask = (*roi.mask)
      xoff = roi.msk_xoff
      yoff = roi.msk_yoff
      goodval = roi.maskgood
      mask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
      mzxsize = (x2 - x1 + 1) * zoom
      mzysize = (y2 - y1 + 1) * zoom
      roimask = congrid(mask, mzxsize, mzysize)
      bad = where(roimask NE roi.maskgood, count)
      if count gt 0 then begin
        newtiim[bad] = 0
      endif
    endif

    ; Display it.
    tv, newtiim
    newtiim = 0
; *******
    if (*info.roi).orivec eq 1 then idp3_orientv, info, 'roi'
; *******
    if rbk eq 0 then begin
      ; Update various widgets whose contents depend on the contents of the ROI.
      if (XRegistered('idp3_roistatistics')) then begin
        Widget_Control, info.roistats, /Destroy
        idp3_roistatistics, $
		 {WIDGET_BUTTON,ID:0L,TOP:info.idp3Window,HANDLER:0L,SELECT:0}
        Widget_Control,info.idp3Window,Get_UValue=info
        roiinfo = info
      endif
      if (XRegistered('idp3_polystatistics')) then begin
        wset, roi.drawid2
        pts = roi.polypts
        if pts ge 3 then begin
          zoom = roi.roizoom
          xpts = (*roi.polyx - x1) * zoom
          ypts = (*roi.polyy - y1) * zoom
          out_of_bounds = 0
          for i = 0, pts-1 do begin
            if xpts[i] gt (x2-x1+1)*zoom then out_of_bounds = 1
            if ypts[i] gt (y2-y1+1)*zoom then out_of_bounds = 1
          endfor
          if (out_of_bounds eq 1) then begin
            str = 'ROI: ' + $
	       'Cannot perform statistics, polygon outside roi field of view'
	    idp3_updatetxt, info, str
          endif else begin
	    plots, xpts[0], ypts[0], color=pcl, /device
	    for i = 1, pts do begin
	      plots, xpts[i],ypts[i], color=pcl, /device, /continue
            endfor
            geo = Widget_Info(info.polystats, /geometry)
            info.wpos.pswp[0] = geo.xoffset - info.xoffcorr
            info.wpos.pswp[1] = geo.yoffset - info.yoffcorr
            Widget_Control, info.idp3Window, Set_UValue=info
            Widget_Control, info.polystats, /Destroy
            idp3_polystatistics, info 
          endelse
        endif else begin
          str = 'ROI: Insufficient number of points for polygon!'
	  idp3_updatetxt, info, str
        endelse
      endif
      if (XRegistered('idp3_spreadsheet')) then begin
        geo = Widget_Info(info.spread, /geometry)
        info.wpos.sswp[0] = geo.xoffset - info.xoffcorr
        info.wpos.sswp[1] = geo.yoffset - info.yoffcorr
        Widget_Control, info.idp3Window, Set_UValue=info
        Widget_Control, info.spread, /Destroy
        idp3_spreadsheet, $
		 {WIDGET_BUTTON,ID:0L,TOP:info.idp3Window,HANDLER:0L,SELECT:0}
        Widget_Control,info.idp3Window,Get_UValue=info
        roiinfo=info
      endif
      if (XRegistered('idp3_roihist')) then begin
        geo = Widget_Info(info.histbase, /geometry)
        info.wpos.rhwp[0] = geo.xoffset - info.xoffcorr
        info.wpos.rhwp[1] = geo.yoffset - info.yoffcorr
        Widget_Control, info.idp3Window, Set_UValue=info
        Widget_Control, info.histbase, /Destroy
        idp3_roihist, $
		 {WIDGET_BUTTON,ID:0L,TOP:info.idp3Window,HANDLER:0L,SELECT:0}
        Widget_Control,info.idp3Window,Get_UValue=info
        roiinfo=info
      endif
      if (XRegistered('idp3_prof')) then begin
        ; Redraw the profile.
        if fix(roi.xsxstart) lt x1 or fix(roi.xsxstop) gt x2 or $
           fix(roi.xsystart) lt y1 or fix(roi.xsystop) gt y2 then begin
          str = 'ROI: ' + $
	    'Cannot update cross section, line outside the roi field of view'
          print, x1, roi.xsxstart, x2, roi.xsxstop
          print, y1, roi.xsystart, y2, roi.xsystop
          idp3_updatetxt, info, str
        endif else begin
          prof = *info.prof
          prof.sx = (roi.xsxstart-x1) * roi.roizoom
          prof.sy = (roi.xsystart-y1) * roi.roizoom
          prof.ex = (roi.xsxstop-x1) * roi.roizoom
          prof.ey = (roi.xsystop-y1) * roi.roizoom
          *info.prof = prof
	  wset,(*info.roi).drawid2
          plots, [prof.sx,prof.ex], [prof.sy,prof.ey], color=xcl, /device
          idp3_prof,info
        endelse
      endif
      if (XRegistered('idp3_radprof')) then begin
        xcen = ((*info.rprf).sx - (*info.roi).roixorig) * $
           (*info.roi).roizoom
        ycen = ((*info.rprf).sy - (*info.roi).roiyorig) * $
           (*info.roi).roizoom
        (*info.roi).radxcent = xcen
        (*info.roi).radycent = ycen
        xb = x1 < x2
        xe = x2 > x1
        yb = y1 < y2
        ye = y2 > y1
        xc = (*info.rprf).sx
        yc = (*info.rprf).sy
        if xc le xb or xc ge xe or yc le yb or yc ge ye then begin
	  xcstr = strtrim(string(xc),2)
	  ycstr = strtrim(string(yc),2)
          if info.rpcofov eq 1 then begin
            str = 'ROI: Radial profile, Center (' + strtrim(string(xcstr),2) $
		  + ',' + strtrim(string(ycstr),2) + $
	          ') outside field of view, but flag set, updating profile!'
            idp3_updatetxt, info, str
	    doanyway = 1
          endif else begin
	    doanyway = 0
            str ='ROI: Radial profile, Center (' + strtrim(string(xcstr),2) $
		 + ',' + strtrim(string(ycstr),2) +  $
	         ') outside field of view, Cannot update profile'
            idp3_updatetxt, info, str
          endelse
        endif else doanyway = 1
        if doanyway eq 1 then begin
          ; Redraw the radial profile.
          wset,(*info.roi).drawid2
          th=fltarr(361)
          for i=0,360 do th(i)=float(i)*(!pi/180.)
          plots,roi.radradius*cos(th)+roi.radxcent, $
	      roi.radradius*sin(th)+roi.radycent,color=rcl,/device
          idp3_radprof,info
        endif
      endif
      if (XRegistered('idp3_noiseprof')) then begin
        ; draw the annuli.
        if roi.npxcenter lt x1 or roi.npxcenter gt x2 or $
           roi.npycenter lt y1 or roi.npycenter gt y2 then begin
          str = 'ROI: ' + $
	     'Cannot update noise profile, center outside roi field of view'
          idp3_updatetxt, info, str
        endif else begin
          wset,(*info.roi).drawid2
	  tempimage = tvrd()
	  if ptr_valid((*info.roi).roiimage) then ptr_free,(*info.roi).roiimage
  	  (*info.roi).roiimage = ptr_new(tempimage)
	  tempimage = 0
          th=fltarr(361)
          xcenter = (roi.npxcenter - x1) * zoom
          ycenter = (roi.npycenter - y1) * zoom
          nannuli = fix((roi.lacenter - roi.facenter)/roi.aincr + 0.5) + 1
          for i =0,360 do th(i)=float(i)*(!pi/180.)
	  for j = 0, nannuli - 1 do begin
	    inner=(((roi.facenter-roi.awidth*0.5)+j*roi.aincr)/roi.pxscale)*zoom
	    plots,inner*cos(th)+xcenter,inner*sin(th)+ycenter,color=nicl,/device
          endfor
	  for j = 0, nannuli - 1 do begin
	    outer=(((roi.facenter+roi.awidth*0.5)+j*roi.aincr)/roi.pxscale)*zoom 
            plots, outer*cos(th)+xcenter, outer*sin(th)+ycenter, color=nocl, $
	      linestyle=1, /device
          endfor
          idp3_noiseprof, event
        endelse
      endif
      if XRegistered('idp3_roicntr') then begin
	Widget_Control, info.roicntrBase, /Destroy
;	idp3_conturoi, event
      endif
      if XRegistered('idp3_catalog') then begin
	if info.catalog.entries gt 0 and info.catdisp gt 0 then begin
	  xloc = round(*info.catalog.xpos)
	  yloc = round(*info.catalog.ypos)
	  minshift = info.catminred
	  maxshift = info.catmaxred
	  redshift = *info.catalog.zpf > minshift < maxshift
	  wset, (*info.roi).drawid2
	  x1 = (*info.roi).roixorig
	  x2 = (*info.roi).roixend
	  y1 = (*info.roi).roiyorig
	  y2 = (*info.roi).roiyend
	  zoom = (*info.roi).roizoom
	  if info.catdisp eq 1 or info.catdisp eq 3 then begin
	    th=fltarr(361)
	    for i=0,360 do th(i)=float(i)*(!pi/180.)
	    ncolor=info.color_bits
	    rad = info.catradius
	    zrad = rad * zoom
	    shift_range = maxshift-minshift
	    fcolor = float(ncolor-1)
	    for i = 0, info.catalog.entries-1 do begin
	      ctemp = fix(((redshift[i]-minshift) / shift_range) * fcolor + 0.5)
	      xx = xloc[i]
	      yy = yloc[i]
	      if xx ge x1 and xx le x2 and yy ge y1 and yy le y2 then begin
		zxx = (xx - x1) * zoom
		zyy = (yy - y1) * zoom
		plots, zrad*cos(th)+zxx,zrad*sin(th)+zyy,color=ctemp,/device
              endif
            endfor
          endif
	  if info.catdisp eq 2 or info.catdisp eq 3 then begin
	    for i = 0, info.catalog.entries-1 do begin
	      id = *info.catalog.id
	      xx = xloc[i]
	      yy = yloc[i]
	      if xx ge x1 and xx le x2 and yy ge y1 and yy le y2 then begin
		zxx = (xx - x1) * zoom
		zyy = (yy - y1) * zoom
		str = strtrim(string(round(id[i])),2)
		xyouts, xx, yy, str, /device, color=green
              endif
            endfor
          endif
        endif
      endif
    endif
  endif else begin
    ; Clear graphics display.
    if ptr_valid(tim) then ptr_free, tim
    tim = ptr_new(fltarr(roi.roixsize,roi.roiysize))
    tv,*tim
    ptr_free,tim
  endelse
  wset,(*info.roi).drawid2 
  if ptr_valid((*info.roi).roiimage) then ptr_free, (*info.roi).roiimage
  (*info.roi).roiimage = ptr_new(tvrd())
  wset,info.drawid1
  roiinfo=info
  Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
end

pro Roi_Resize, event
@idp3_errors
  ; The user resized the roi window so resize the draw window appropriately.
  ; Users really shouldn't be doing this!
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=roiinfo
  Widget_Control, (*roiinfo.roi).roiDraw, Draw_XSize = event.x - 5, $
				          Draw_YSize = event.y - 40

  ; Save the new size in the info structure
  (*roiinfo.roi).roixsize = event.x - 5
  (*roiinfo.roi).roiysize = event.y - 40

  ; Update graphics display
  roi_display,roiinfo

  Widget_Control, event.top, Set_UValue=roiinfo
  Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
end

pro roi_Close, event
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  closeroi = 1
  idp3_roiclose, info, closeroi
  Widget_Control, tinfo.idp3Window, Set_UValue=info
end

pro rod_Close, event
@idp3_errors
  
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  ; Turn off ROD.
  (*info.roi).rod = 0

  Widget_Control, info.idp3Window, Set_UValue=info

  ; The statistics widget needs to be updated.
  if (XRegistered('idp3_roistatistics')) then begin
    Widget_Control, info.roistats, /Destroy
    idp3_roistatistics, $
		 {WIDGET_BUTTON,ID:0L,TOP:info.idp3Window,HANDLER:0L,SELECT:0}
    Widget_Control, info.idp3Window, Get_UValue=tinfo
    info=tinfo
  endif

  roi_Display, info
  Widget_Control, info.idp3Window, Set_UValue=info
end


pro roi_Draw, event
@idp3_errors
  Widget_Control, event.top, Get_UValue=tempinfo
  Widget_Control, tempinfo.idp3Window, Get_UValue=roiinfo
  wset,(*roiinfo.roi).drawid2
  if not(ptr_valid(roiinfo.dispim)) then return

  pcl = roiinfo.color_poly
  if pcl lt 0 then pcl = 200
  rcl = roiinfo.color_radpf
  if rcl lt 0 then rcl = 200
  xcl = roiinfo.color_xsect
  if xcl lt 0 then xcl = 200
  nicl = roiinfo.color_innernpf
  if nicl lt 0 then nicl = 200
  nocl = roiinfo.color_outernpf
  if nocl lt 0 then nocl = 200
  ; Cursor readback.
  x1 = (*roiinfo.roi).roixorig
  y1 = (*roiinfo.roi).roiyorig
  x2 = (*roiinfo.roi).roixend
  y2 = (*roiinfo.roi).roiyend
  zoom = (*roiinfo.roi).roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  x = event.x < (xsize-1)
  y = event.y < (ysize-1)

  if (*roiinfo.roi).curs eq 1 then begin
    big_cursor, x, y, (*roiinfo.roi).fix0, (*roiinfo.roi).fiy0
    (*roiinfo.roi).fix0 = x
    (*roiinfo.roi).fiy0 = y
  endif

  if min((*roiinfo.dispim)) eq 0. and max((*roiinfo.dispim)) eq 0. then begin
    return
  endif

  ; Special code for Centroid.
  if roiinfo.cent.ccmain gt 0 and event.press eq 1 then begin
    ; Remember where the user clicked, this is the first guess at the center.
    roiinfo.cent.sx = x
    roiinfo.cent.sy = y
    Widget_Control,roiinfo.cent.ccmain,/Destroy
    Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
    Widget_Control, event.top, Set_UValue=roiinfo
    return
  endif
  if roiinfo.cent.ccmain gt 0 and event.release eq 1 then begin
    roiinfo.cent.ccmain = -1
    Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
    Widget_Control, event.top, Set_UValue=roiinfo
    return
  endif

  xof = roiinfo.sxoff
  yof = roiinfo.syoff
  roi = roiinfo.roi
  dispimsz = size((*roiinfo.dispim))
  xp = float(x)/(*roi).roizoom + 1.0 + (*roi).roixorig 
  yp = float(y)/(*roi).roizoom + 1.0 + (*roi).roiyorig
  if roiinfo.pixorg eq 0 then begin
    xindx = fix(xp - 0.5) > 0 < (dispimsz[1]-1)
    yindx = fix(yp - 0.5) > 0 < (dispimsz[2]-1)
  endif else begin
    xindx = fix(xp - 1.) > 0 < (dispimsz[1]-1)
    yindx = fix(yp - 1.) > 0 < (dispimsz[2]-1)
  endelse
  sdispim = idp3_scaldisplay(roiinfo)
  if finite(sdispim[xindx,yindx]) then begin
    d = sdispim[xindx,yindx]
    case roiinfo.imscl of
    0: begin  ; linear
      if roiinfo.zoomflux eq 1 then d = d/(zoom^2)
      dstr = strtrim(string(d, format="(f)"), 2)
      dlen = strlen(dstr)
      if dlen gt 9 then dstr = strmid(dstr,0,9)
      ts = string(format="('X:',f8.3,' Y:',f8.3,'  Value: ')",xp-1., yp-1.)+dstr
      Widget_Control,roiinfo.pixval,Set_Value=ts
      ts1 = string(format="(' Zoom:',i2)", zoom)
      if roiinfo.dispbias ne 0.0 then ts1 = ts1 + 'Display bias: ' + $
	 strtrim(string(roiinfo.dispbias,'$(f10.4)'),2)
      Widget_Control,roiinfo.pixval2,Set_Value=ts1
      end
    1: begin
      if roiinfo.zoomflux eq 1 then d = d - alog10(zoom^2)
      dd = 10.0 ^ d
      dstr = strtrim(string(dd, format="(f)"), 2)
      dlen = strlen(dstr)
      if dlen gt 9 then dstr = strmid(dstr,0,9)
      ts = string(format="('X:',f8.3,' Y:',f8.3,'  Value: ')",xp-1., yp-1.)+dstr
      dstr = strtrim(string(d, format="(f)"), 2)
      dlen = strlen(dstr)
      if dlen gt 9 then dstr = strmid(dstr,0,9)
      ts = ts + '  [' + dstr + ']' 
      Widget_Control,roiinfo.pixval,Set_Value=ts
      ts1 = string(format="(' Zoom:',i2)", zoom)
      if roiinfo.dispbias ne 0.0 then begin
        logbias = alog10(roiinfo.dispbias)
        ts1=ts1 + 'Display bias: ' + $
	  strtrim(string(roiinfo.dispbias,'$(f10.4)'),2) $
          + ' [' + strtrim(string(logbias,'$(f8.4)') + ']',2)
      endif
      Widget_Control,roiinfo.pixval2,Set_Value=ts1
      end
    2: begin
     if roiinfo.zoomflux eq 1 then d = d/(zoom^2)
      dd = sqrt(d)
      dstr = strtrim(string(dd, format="(f)"), 2)
      dlen = strlen(dstr)
      if dlen gt 9 then dstr = strmid(dstr,0,9)
      ts = string(format="('X:',f8.3,' Y:',f8.3,'  Value: ')",xp-1., yp-1.)+dstr
      dstr = strtrim(string(d, format="(f)"), 2)
      dlen = strlen(dstr)
      if dlen gt 9 then dstr = strmid(dstr,0,9)
      ts = ts + '  [' + dstr + ']' 
      Widget_Control,roiinfo.pixval,Set_Value=ts
      ts1 = string(format="(' Zoom:',i2)", zoom)
      if roiinfo.dispbias ne 0.0 then begin
        sqbias = sqrt(roiinfo.dispbias)
        ts1=ts1 + '   Display bias: ' + $
	  strtrim(string(roiinfo.dispbias,'$(f10.4)'),2) $
          + ' [' + strtrim(string(sqbias,'$(f8.4)') + ']',2)
      endif
      Widget_Control,roiinfo.pixval2,Set_Value=ts1
     end
    else:
    endcase
  endif else begin
    ts = string(format="('X:',f8.3,' Y:',f8.3,'  Value: ')",xp-1., yp-1.) + $
      'Nan'
    Widget_Control,roiinfo.pixval,Set_Value=ts
    Widget_Control,roiinfo.pixval2,Set_Value='                       '
  endelse
  if roiinfo.show_wcs gt 0 then begin
    if ptr_valid((*roiinfo.images)[roiinfo.moveimage]) then begin 
      imptr = (*roiinfo.images)[roiinfo.moveimage]
      if (*imptr).vis eq 1 then begin
	idp3_getcoords, 0, xp-1., yp-1, xra, xdec, imstr=imptr
	if xra ge 0. then begin
	  if roiinfo.show_wcs eq 1 then begin
            idp3_conra, xra/15.0, rastr
            idp3_condec, xdec, decstr
	    strp = 'ra:' + rastr + '   dec:' + decstr
          endif else begin
	    strp = 'ra:' + string(xra,'$(f12.7)') + '   dec:' + $
		        string(xdec,'$(f12.7)')
          endelse
	  fname = (*imptr).name
	  ua_decompose, fname,disk,path,name,extn,version
	  strp = strp + ' ref: ' + name
        endif else strp = '                                     '
      endif else strp = '                                     ' 
    endif else strp = '                                     '
  endif else strp = '                                     '
  Widget_Control, roiinfo.rwcslab, Set_Value=strp

  ; catalog
  if event.press eq 1 and (*roi).mouse_mode eq 0 then begin
    name = strtrim(roiinfo.catalog.name, 2)
    if strlen(name) gt 1 and roiinfo.catalog.entries gt 1 then begin
      xp = float(x)/(*roi).roizoom + (*roi).roixorig
      yp = float(y)/(*roi).roizoom + (*roi).roiyorig
      xloc = *roiinfo.catalog.xpos
      yloc = *roiinfo.catalog.ypos
      id = *roiinfo.catalog.id
      ra = *roiinfo.catalog.ra
      dec = *roiinfo.catalog.dec
      zpf = *roiinfo.catalog.zpf
      ebvpf = *roiinfo.catalog.ebvpf
      tempnum = *roiinfo.catalog.tempnum
      apmag = *roiinfo.catalog.apmag
      dist = 15.
      inum = -1
      qq = where(abs(xloc - xp) le 10. and abs(yloc - yp) le 10., count)
      if count ge 1 then begin
        for i = 0, count-1 do begin
	  indx = qq[i]
	  tdist = sqrt((xloc[indx] - xp) ^ 2 + (yloc[indx] - yp) ^ 2)
	  if tdist lt dist then begin
	    dist = tdist
	    inum = indx
          endif
        endfor
;	openw, clun, 'catfind.txt', /get_lun
	catstrs = strarr(5)
	ua_decompose, roiinfo.catalog.name, disk, path, catname, extn, vers
	titlestr = 'Catalog: ' + catname + extn + '  ID: ' + $
		    strtrim(string(round(id[inum])),2)
	catstrs[0] = 'Catalog: ' + roiinfo.catalog.name
	catstrs[1] = 'ID Number: ' + string(id[inum],'$(f8.2)') + $
		     '  X: ' + string(xloc[inum], '$(f9.2)') + $
		     '  Y: ' + string(yloc[inum], '$(f9.2)')
	catstrs[2] = 'RA: ' + ra[inum] + '   Dec: ' + dec[inum]
	apm = apmag[0,*,inum]
	catstrs[3] = 'APMag: ' + string(apm, '$(6f9.4)')
	catstrs[4] = 'Redshift: ' + strtrim(string(zpf[inum]),2) + $
		     '  E(B-V): ' + strtrim(string(ebvpf[inum]),2) + $
		     '  SED: ' + strtrim(string(tempnum[inum]),2)
	xdisplayfile, 'jnk', text=catstrs, title=titlestr, height=6
      endif else begin
	str = 'ROI: No catalog entries close to ' + string(xp) + string(yp)
	idp3_updatetxt, roiinfo, str
      endelse
    endif else begin
      str = 'ROI: No catalog loaded'
      idp3_updatetxt, roiinfo, str
    endelse
  endif

  ; Profile (cross section).
  if (event.press ge 1 and (*roi).mouse_mode eq 1) then begin
  ; Remember this end.
    (*roiinfo.prof).pressed = 1
    if (*roiinfo.prof).ex ne -1 and (*roiinfo.prof).ey ne -1 then begin
    ; Erase the old line.
      tv, *(*roiinfo.roi).roiimage
    endif else begin
      if ptr_valid((*roiinfo.roi).roiimage) $
	 then ptr_free,(*roiinfo.roi).roiimage
      (*roiinfo.roi).roiimage = ptr_new(tvrd())
    endelse

    ; Set up for new line.
    (*roiinfo.prof).sx = event.x > 0 < (xsize-1)
    (*roiinfo.prof).sy = event.y > 0 < (ysize-1)
    (*roiinfo.prof).ex = -1
    (*roiinfo.prof).ey = -1
    (*roiinfo.prof).width = 1
    Widget_Control, event.top, Set_UValue=roiinfo
  endif
  if ((*roiinfo.prof).pressed eq 1) then begin
    ; Draw a line.
    prof = *roiinfo.prof
    if prof.ex ne -1 and prof.ey ne -1 then begin
      ; Erase the old line
      tv, *(*roiinfo.roi).roiimage
    endif
    prof.ex = event.x > 0 < (xsize-1)
    prof.ey = event.y > 0 < (ysize-1)
    plots, [prof.sx,prof.ex], [prof.sy,prof.ey], color=xcl, /device
    ptr_free,roiinfo.prof
    roiinfo.prof = ptr_new(prof)
    Widget_Control, event.top, Set_UValue=roiinfo
  endif
  if(event.release ge 1 and (*roi).mouse_mode eq 1) then begin
    prof = *roiinfo.prof
    prof.pressed = 0
    if prof.ex ne -1 and prof.ey ne -1 then begin
      ; Erase the last line.
      tv, *(*roiinfo.roi).roiimage
    endif

    ; Remember some of this in the prof structure.
    prof.ex = event.x > 0 < (xsize-1)
    prof.ey = event.y > 0 < (ysize-1)
    if ABS(prof.ex - prof.sx) gt 1 or ABS(prof.ey - prof.sy) gt 1 then begin
      prof.new = 1
      zoom = (*roi).roizoom
      (*roi).xsxstart = float(prof.sx)/zoom + (*roi).roixorig 
      (*roi).xsystart = float(prof.sy)/zoom + (*roi).roiyorig
      (*roi).xsxstop = float(prof.ex)/zoom + (*roi).roixorig 
      (*roi).xsystop = float(prof.ey)/zoom + (*roi).roiyorig
      (*roi).xsxcenter = ((*roi).xsxstop + (*roi).xsxstart) * 0.5
      (*roi).xsycenter = ((*roi).xsystop + (*roi).xsystart) * 0.5
      xl = float(prof.ex) - float(prof.sx)
      yl = float(prof.ey) - float(prof.sy)
      (*roi).xslength = FLOAT(FIX(SQRT(xl^2 + yl^2)))/zoom
      (*roi).xswidth = 1.0/zoom
      ;ang = ATAN(yl,xl) * 180.0D0/!pi
      val = yl/xl
      ang = ATAN(val) * 180.0D0/!pi
      ;ang = ang + 90.
      ;if (ang LT 0.) then ang = ang + 360.0D0 
      ;if ang ge 0. then ang = ang - 90. else ang = ang + 90.
      (*roi).xsangle = ang
      if (XRegistered('idp3_adjustxsect')) then begin
        Widget_Control, roiinfo.axsBase, Get_UValue = tempaxsinfo
        Widget_Control, tempaxsinfo.xxstartField, Set_Value = (*roi).xsxstart
        Widget_Control, tempaxsinfo.xystartField, Set_Value = (*roi).xsystart
        Widget_Control, tempaxsinfo.xxstopField, Set_Value = (*roi).xsxstop
        Widget_Control, tempaxsinfo.xystopField, Set_Value = (*roi).xsystop
        Widget_Control, tempaxsinfo.sxstartField, Set_Value = (*roi).xsxstart
        Widget_Control, tempaxsinfo.systartField, Set_Value = (*roi).xsystart
        Widget_Control, tempaxsinfo.sangleField, Set_Value = ang
        Widget_Control, tempaxsinfo.slengthField, Set_Value = (*roi).xslength
        Widget_Control, tempaxsinfo.cxcenterField, Set_Value = (*roi).xsxcenter
        Widget_Control, tempaxsinfo.cycenterField, Set_Value = (*roi).xsycenter
        Widget_Control, tempaxsinfo.cangleField, Set_Value = ang
        Widget_Control, tempaxsinfo.clengthField, Set_Value = (*roi).xslength
      endif

      ; Plot the final line.
      plots, [prof.sx,prof.ex], [prof.sy,prof.ey], color=xcl, /device
      ptr_free,roiinfo.prof
      roiinfo.prof = ptr_new(prof)
      Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo

      ; Call the prof procedure.
      idp3_prof,roiinfo
      Widget_Control, roiinfo.idp3Window, get_UValue=roiinfo
    endif else begin
      str = 'ROI: Cross Section has too few points!'
      idp3_updatetxt, roiinfo, str
    endelse
  endif

  ; Polygon statistics
  if (event.press ge 1 and (*roi).mouse_mode eq 3) then begin
    if (*roi).polypts lt 0 then begin
      if ptr_valid((*roi).roiimage) then ptr_free, (*roi).roiimage 
      (*roi).roiimage = ptr_new(tvrd())
    endif
    xo = x1
    yo = y1
    xx = fix(float(x)/zoom) + xo
    yy = fix(float(y)/zoom) + yo
    if (*roi).polydone eq 1 then begin
      wset, (*roi).drawid2
      pts = (*roi).polypts
      zoom = (*roi).roizoom
      xpts = *(*roi).polyx
      ypts = *(*roi).polyy
      if ptr_valid((*roi).savpolyx) then begin
	ptr_free, (*roi).savpolyx
	ptr_free, (*roi).savpolyy
      endif
      (*roi).savpolyx = ptr_new(xpts)
      (*roi).savpolyy = ptr_new(ypts)
      (*roi).spolypts = pts
      plots, (xpts[0]-xo)*zoom, (ypts[0]-yo)*zoom, color=pcl, /device
      for i = 1, pts do begin
        plots, (xpts[i]-xo)*zoom,(ypts[i]-yo)*zoom,color=pcl,/device,/continue
      endfor
      (*roi).polydone = 0
      (*roi).polypts = 0
    endif
    if (*roi).polypts le 0 then begin  ; start new polygon 
      if ptr_valid((*roi).polyx) then ptr_free,(*roi).polyx
      if ptr_valid((*roi).polyy) then ptr_free,(*roi).polyy
      (*roi).polyx = ptr_new(intarr(2))
      (*roi).polyy = ptr_new(intarr(2))
      *(*roi).polyx[0] = xx
      *(*roi).polyy[0] = yy 
      (*roi).polypts = 1
      (*roi).polyxold = x
      (*roi).polyyold = y
    endif else begin
      lastpt = (*roi).polypts
      xpt = intarr(lastpt+1)
      ypt = intarr(lastpt+1)
      xpt[*] = 0
      ypt[*] = 0
      xpt[0:lastpt-1] = *(*roi).polyx
      ypt[0:lastpt-1] = *(*roi).polyy
      ptr_free, (*roi).polyx
      ptr_free, (*roi).polyy
      lastx = xpt[lastpt-1]
      lasty = ypt[lastpt-1]
      oldx = (*roi).polyxold
      oldy = (*roi).polyyold
      if ABS(x-oldx) LE 2 AND ABS(y-oldy) LE 2 then begin 
      ; end of polygon
	if lastpt ge 3 then begin
          xpt[lastpt] = xpt[0]
          ypt[lastpt] = ypt[0]
          xsz = ABS(x2-x1) + 1
          ysz = ABS(y2-y1) + 1
          plots, (xx-xo)*zoom, (yy-yo)*zoom, color=pcl, /device
	  plots, (xpt[0]-xo)*zoom, (ypt[0]-yo)*zoom,/device,color=pcl,/continue
	  roi_SetPlate, roiinfo
	  (*roi).polyx = ptr_new(xpt)
	  (*roi).polyy = ptr_new(ypt)
	  if XRegistered('idp3_polystatistics') then begin
            geo = Widget_Info(roiinfo.polystats, /geometry)
            roiinfo.wpos.pswp[0] = geo.xoffset - roiinfo.xoffcorr
            roiinfo.wpos.pswp[1] = geo.yoffset - roiinfo.yoffcorr
            Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
	    Widget_Control, roiinfo.polystats, /Destroy 
          endif
          idp3_polystatistics, roiinfo
	  (*roi).polydone = 1
	  Widget_Control, roiinfo.idp3Window, Get_UValue=roiinfo
        endif else begin
	  str = 'ROI: Insufficent number of points in polygon!'
	  idp3_updatetxt, roiinfo, str
	  tv, (*roi).roiimage
	  (*roi).polypts = 0
	  (*roi).polydone = 0
        endelse
      endif else begin   ; continue saving polygon points 
        plots, (lastx-xo)*zoom, (lasty-yo)*zoom, color=pcl, /device
        plots, (xx-xo)*zoom, (yy-yo)*zoom,color=pcl,/device,/continue
        xpt[lastpt] = xx
        ypt[lastpt] = yy
	xsz = size(xpt)
        (*roi).polypts = (*roi).polypts + 1
        (*roi).polyx = ptr_new(xpt)
        (*roi).polyy = ptr_new(ypt)
	(*roi).polyxold = x
	(*roi).polyyold = y
      endelse
    endelse
  endif

  ; Radial Profile.
  if(event.press ge 1 and (*roi).mouse_mode eq 2) then begin
  ; Remember the center.
    if (*roi).radradius gt -0.5 then begin
      ; Erase the old circle if there was one.
       tv, *(*roi).roiimage
    endif else begin
      ; Save current display
      if ptr_valid((*roi).roiimage) then ptr_free, (*roi).roiimage
      (*roi).roiimage = ptr_new(tvrd())
    endelse

    ; Remember the center, set radius to none, keep track of the button press.
    (*roi).radxcent = float(x)
    (*roi).radycent = float(y)
    (*roi).centfit = 0
    (*roi).radradius = -1.0
    xc = float(x)/(*roi).roizoom + (*roi).roixorig
    yc = float(y)/(*roi).roizoom + (*roi).roiyorig
    (*roiinfo.rprf).sx = xc
    (*roiinfo.rprf).sy = yc
    (*roi).pressed = 1

    ; If the radprof widget is up, update the center.
    if (XRegistered('idp3_radprof')) then begin
      Widget_Control, roiinfo.rpxcentxt, Set_Value = string(xc,'$(f7.3)') 
      Widget_Control, roiinfo.rpycentxt, Set_Value = string(yc,'$(f7.3)') 
    endif
  endif
  if ((*roi).pressed eq 1) then begin
    ; Update the circle as the user drags the cursor.
    ; Erase the old one.
    if (*roi).radradius gt -0.5 then begin
       tv, *(*roi).roiimage
    endif
    ; Plot the new one.
    deltax = abs((*roi).radxcent - float(event.x))
    deltay = abs((*roi).radycent - float(event.y))
    if deltax gt 1.0 or deltay gt 1.0 then begin
      (*roi).radradius = sqrt(float(deltax)^2 + float(deltay)^2)
      (*roiinfo.rprf).r = (*roi).radradius/(*roi).roizoom

      ; If the adjust radprof widget is up, update the radius on the fly.
      if (XRegistered('idp3_radprof')) then begin
        rr = float((*roi).radradius)/(*roi).roizoom
        Widget_Control, roiinfo.rpradiustxt, Set_Value = string(rr,'$(f6.3)')
      endif
      th=fltarr(361)
      for i=0,360 do th(i)=float(i)*(!pi/180.)
      plots,(*roi).radradius*cos(th)+(*roi).radxcent, $
	  (*roi).radradius*sin(th)+(*roi).radycent,color=rcl,/device
      (*roiinfo.rprf).drag = 1
    endif else begin
      (*roiinfo.rprf).drag = 0
    endelse
  endif
  if(event.release ge 1 and (*roi).mouse_mode eq 2) then begin
    (*roi).pressed = 0
    if (*roiinfo.rprf).drag eq 0 then begin
      (*roi).radradius = roiinfo.rpradius * (*roi).roizoom
      (*roiinfo.rprf).r = roiinfo.rpradius
      th=fltarr(361)
      for i=0,360 do th(i)=float(i)*(!pi/180.)
      plots,(*roi).radradius*cos(th)+(*roi).radxcent, $
	  (*roi).radradius*sin(th)+(*roi).radycent,color=rcl,/device
    endif
    ; Check to see if they went off the edge, reset radius if so.
    txc = (*roi).radxcent
    tyc = (*roi).radycent
    trad = (*roi).radradius
    txs = (*roi).roixsize
    tys = (*roi).roiysize
    if trad gt txc or trad gt tyc or (txc + trad) gt txs or $
				     (tyc + trad) gt tys then begin
      ; Update radius and redraw circle.
      ; Erase the old circle first.
      if (*roi).radradius gt -0.5 then begin
	tv, *(*roi).roiimage
      endif
      ; Update radius.
      (*roi).radradius = min([txc,tyc,txs-txc,tys-tyc])
      rr = float((*roi).radradius)/(*roi).roizoom
      (*roiinfo.rprf).r = rr
      ; If the radprof widget is up, update the radius on the fly.
      if (XRegistered('idp3_radprof')) then begin
        Widget_Control, roiinfo.rpradiustxt, Set_Value = string(rr,'$(f6.3)') 
      endif
      ; Draw the new circle.
      th=fltarr(361)
      for i=0,360 do th(i)=float(i)*(!pi/180.)
      plots,(*roi).radradius*cos(th)+(*roi).radxcent, $
	    (*roi).radradius*sin(th)+(*roi).radycent,color=rcl,/device
      (*roiinfo.rprf).drag = 0
    endif
    ; Circle drawing done, call the radial profile routine.
    if (*roi).radradius gt 1 then begin
      idp3_radprof,roiinfo
    endif else begin
      str = 'ROI: Radius of radial profile too small!'
      idp3_updatetxt, roiinfo, str
    endelse
  endif

  ; move polygon
  if XRegistered('idp3_polystatistics') and (*roi).mouse_mode eq 4 and $
    (*roi).polypts ge 3 then begin
    xo = x1
    yo = y1
    xx = fix(float(x)/zoom) + xo
    yy = fix(float(y)/zoom) + yo
    pts = (*roi).polypts
    xpts = *(*roi).polyx
    ypts = *(*roi).polyy
    wset, (*roi).drawid2
    if event.press ge 1 then begin
      (*roi).polyxb = xx
      (*roi).polyyb = yy
      (*roi).savpolyx = ptr_new(xpts)
      (*roi).savpolyy = ptr_new(ypts)
      (*roi).spolypts = pts
    endif
    if (*roi).polyxb ge 0 then begin
      xl = xx - (*roi).polyxb
      yl = yy - (*roi).polyyb
      if xl ne 0 or yl ne 0 then begin
        length = sqrt(xl^2 + yl^2)
	angle = atan(yl/xl)
	;if angle lt 0. then angle = angle + 2.0 * !pi
	nxpts = xpts + length * cos(angle) > x1 < x2
	nypts = ypts + length * sin(angle) > y1 < y2
	tv, *(*roi).roiimage
	plots, (nxpts[0]-xo)*zoom,(nypts[0]-yo)*zoom, color=pcl, /device
	for i = 1, pts do begin
	  plots, (nxpts[i]-xo)*zoom,(nypts[i]-yo)*zoom, color=pcl, /device, $
	    /continue
        endfor
      endif
      if event.release eq 1 then begin
	if n_elements(nxpts) gt 0 then begin
	  if ptr_valid((*roi).polyx) then ptr_free, (*roi).polyx
	  if ptr_valid((*roi).polyy) then ptr_free, (*roi).polyy
          (*roi).polyx = ptr_new(nxpts)
	  (*roi).polyy = ptr_new(nypts)
          geo = Widget_Info(roiinfo.polystats, /geometry)
          roiinfo.wpos.pswp[0] = geo.xoffset - roiinfo.xoffcorr
          roiinfo.wpos.pswp[1] = geo.yoffset - roiinfo.yoffcorr
          Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
	  Widget_Control, roiinfo.polystats, /Destroy
	  idp3_polystatistics, roiinfo
        endif
	(*roi).polyxb = -1
	(*roi).polyyb = -1
      endif
    endif
  endif
  
  ; edit polygon
  if XRegistered('idp3_polystatistics') and (*roi).mouse_mode eq 5 and $
    (*roi).polypts ge 3 then begin
    xo = x1
    yo = y1
    xx = fix(float(x)/zoom) + xo
    yy = fix(float(y)/zoom) + yo
    pts = (*roi).polypts
    xpts = *(*roi).polyx
    ypts = *(*roi).polyy
    polyxy = intarr(2,pts+1)
    polyxy[0,*] = xpts
    polyxy[1,*] = ypts
    wset, (*roi).drawid2
    if event.press ge 1 then begin
      (*roi).edpt = -1
      (*roi).polymnd = 10.
      (*roi).savpolyx = ptr_new(xpts)
      (*roi).savpolyy = ptr_new(ypts)
      (*roi).spolypts = pts
      for i = 0, pts do begin
	dist = sqrt((xx - xpts[i])^2 + (yy - ypts[i])^2)
	if dist lt (*roi).polymnd then begin
	  (*roi).polymnd = dist
	  (*roi).edpt = i
        endif
      endfor
    endif
    if (*roi).edpt ge 0 then begin
      tv, *(*roi).roiimage
      indx = (*roi).edpt
      polyxy[0,indx] = xx
      polyxy[1,indx] = yy
      if indx eq 0 then begin
	polyxy[0,pts] = xx
	polyxy[1,pts] = yy
      endif
      if XRegistered('idp3_adjustpoly') then begin
	Widget_Control, roiinfo.apolyBase, Get_UValue = tempapolyinfo
	Widget_Control, tempapolyinfo.polyTable, Set_Value = polyxy
      endif
      xpts[indx] = xx
      ypts[indx] = yy
      if indx eq 0 then begin
	xpts[pts] = xx
	ypts[pts] = yy
      endif
      plots, (xpts[0]-xo)*zoom, (ypts[0]-yo)*zoom, color=pcl, /device
      for i = 1, pts do begin
        plots, (xpts[i]-xo)*zoom, (ypts[i]-yo)*zoom, color=pcl, $
	  /device, /continue
      endfor
      if event.release ge 1 then begin
	ptr_free, (*roi).polyx
	ptr_free, (*roi).polyy
	(*roi).polyx = ptr_new(xpts)
	(*roi).polyy = ptr_new(ypts)
	(*roi).polypts = n_elements(xpts)-1
        geo = Widget_Info(roiinfo.polystats, /geometry)
        roiinfo.wpos.pswp[0] = geo.xoffset - roiinfo.xoffcorr
        roiinfo.wpos.pswp[1] = geo.yoffset - roiinfo.yoffcorr
        Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
	Widget_Control, roiinfo.polystats, /Destroy
	idp3_polystatistics, roiinfo
	(*roi).edpt = -1
      endif
    endif
  endif
  wset,roiinfo.drawid1
  Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
  Widget_Control, event.top, Set_UValue=roiinfo
end

pro idp3_roi, leader

@idp3_structs
@idp3_errors

  Widget_Control, leader, Get_UValue=roiinfo

  roiBase = Widget_Base( $
            Title = "IDP3 Region of Interest", $
            Mbar=menuBar, /Column, /TLB_Size_Events, Group_Leader = leader, $
            TLB_Frame_Attr=8, XOffset = roiinfo.wpos.rwp[0],  $
	    YOffset = roiinfo.wpos.rwp[1])

  ; Build roi menubar.
  roi_fileMenu = Widget_Button(menuBar, Value=" File    ", /Menu)
  roi_dispMenu = Widget_Button(menuBar, Value=" Adjust    ", /Menu) 
  roi_zoomMenu = Widget_Button(menuBar, Value=" Zoom    ", /Menu)
  roi_alignMenu = Widget_Button(menuBar, Value=" Align/Scale    ", /Menu)
  roi_maskMenu = Widget_Button(menuBar, Value=" Mask    ", /Menu)
  roi_plotMenu = Widget_Button(menuBar, Value=" Plot    ", /Menu)
  roi_textMenu = Widget_Button(menuBar, Value=" Statistics    ", /Menu)
;  roi_colorMenu = Widget_Button(menuBar, Value=" Set Color ", /Menu)
  roi_helpMenu = Widget_Button(menuBar, Value=" Help ", /Menu)
;  roi_doneMenu = Widget_Button(menuBar, Value=" Done", /Menu)

  ; Add to file Menu
  loadMenu    = Widget_Button(roi_fileMenu, Value='Load', /menu)
  readmaskButton = Widget_Button(loadMenu, Value='ROI Mask', $
			      Event_Pro = 'idp3_readmask')
  readrodButton  = Widget_Button(loadMenu, Value='Region Of DisInterest', $
			      Event_Pro = 'idp3_readrod')
  printMenu   = Widget_Button(roi_fileMenu, Value='Print', /menu)
  roiprintButton = Widget_Button(printMenu, Value='Region Of Interest', $
    Event_Pro = 'idp3_printroi')
  saveMenu   = Widget_Button(roi_fileMenu, Value='Save', /menu)
  roisaveButton  = Widget_Button(saveMenu, Value='Region Of Interest', $
                              Event_Pro = 'idp3_saveroi')
  savemaskButton = Widget_Button(saveMenu, Value='ROI Mask', $
			      Event_Pro = 'idp3_saveroimask')
  saverodButton  = Widget_Button(saveMenu, Value='Region Of DisInterest', $
			      Event_Pro = 'idp3_saverod')
  savcntButton   = Widget_Button(saveMenu, Value='Centroid Solutions', $
  			      Event_Pro = 'idp3_savecentroid', /Separator)
;  ffill3Button   = Widget_Button(roi_fileMenu, Value='      ', $
;			      Event_Pro = 'roi_nothing')
  closeButton    = Widget_Button(roi_fileMenu, Value='Close ROI', $
			      Event_Pro = 'roi_Close', /Separator)

 ; Add to Help Menu
  roihelpButton = Widget_Button(roi_helpMenu, Value='Help', $
                              Event_Pro = 'roi_help')
  roihelpmmButton = Widget_Button(roi_helpMenu, Value='Mouse Modes', $
                              Event_Pro = 'roi_mousehelp')

  ; Add to Done Menu
;  doneButton  = Widget_Button(roi_doneMenu, Value='Close ROI', $
;		              Event_Pro = 'roi_Close')
  ; Add to Adjust Menu
  displayroiButton = Widget_Button(roi_dispMenu, Value='Adjust display', $
                              Event_Pro = 'idp3_roidisplay')
  adjustroiButton = Widget_Button(roi_dispMenu, Value='Adjust coordinates', $
                              Event_Pro = 'idp3_adjustroi')
  ; Cursor Toggle
  scursButton = Widget_Button(roi_dispMenu, Value='Toggle Cursor', $
			       Event_Pro = 'idp3_roiswitchcurs', /Separator)
  roi_colorMenu = Widget_Button(roi_dispMenu, Value=" Set Color ", /Menu, $
      /Separator)
 ; Add to Set Color Menu
  xscolorButton = Widget_Button(roi_colorMenu, Value='Cross Section', $
			      Event_Pro = 'roi_setxscolor')
  rpcolorButton = Widget_Button(roi_colorMenu, Value='Radial Profile', $
			      Event_Pro = 'roi_setrpcolor')
  npcolorButton = Widget_Button(roi_colorMenu, Value='Noise Profile', $
			      Event_Pro = 'roi_setnpcolor')
  pgcolorButton = Widget_Button(roi_colorMenu, Value='Polygon', $
			      Event_Pro = 'roi_setpolycolor')


  ; Create and add to radial profile Menu
  rpMenu   = Widget_Button(roi_plotMenu, Value='Radial Profile', /menu)
  rpsButton = Widget_Button(rpMenu, Value='Last Profile', $
			      Event_Pro = 'idp3_lastradprof')
  rpssButton  = Widget_Button(rpMenu, Value='Stack Profile', $
			      Event_Pro = 'idp3_rpstack')

  ; Create and add to polygon Menu
  pgMenu   = Widget_button(roi_plotMenu, Value='Polygon', /menu)
  undoButton = Widget_Button(pgMenu, Value='Undo', $
			      Event_Pro = 'roi_polyundo')
  adjustpolyButton  = Widget_Button(pgMenu, Value='Adjust', $
			       Event_Pro = 'idp3_adjustpoly')
  makemaskButton = Widget_Button(pgMenu, Value='Make Mask', $
			       Event_Pro = 'roi_polymask')
  undomaskButton = Widget_Button(pgMenu, Value='Undo Mask', $
			       Event_Pro = 'roi_polyundomask')
  
  ; Add to Align Menu
  wcscentroidButton = Widget_Button(roi_alignMenu, $
			      Value='Centroid by Reference WCS', $
			      Event_Pro = 'idp3_wcscentroid')
  iwcscentroidButton = Widget_Button(roi_alignMenu, $
			      Value='Centroid by Individual WCS',$
			      Event_Pro = 'idp3_indwcscentroid')
  alwcs =         Widget_Button(roi_alignMenu, Value='Align by WCS', $
			       Event_pro = 'idp3_alignwcs', /Separator)
  alcntButton  =  Widget_Button(roi_alignMenu, Value='Align by Centroids', $
  			      Event_Pro = 'idp3_align')
  realignButton = Widget_Button(roi_alignMenu, Value='ReAlign by Centroids', $
			      Event_Pro = 'idp3_realign')
  alignxyButton = Widget_Button(roi_alignMenu, Value='Align by X/Y Positions',$
			      Event_Pro = 'idp3_alignxy')
  unalignButton = Widget_Button(roi_alignMenu, Value='Undo Alignment', $
			      Event_Pro = 'idp3_undoalign')
  afluxsclButton = Widget_Button(roi_alignMenu, Value = 'Auto Flux Scale', $
                              Event_pro = 'idp3_autofluxscl', /Separator)
  unafluxsclButton = Widget_Button(roi_alignMenu, Value='Undo Auto Flux Scale',$
                              Event_Pro = 'idp3_undo_autofluxscl')

  ; Create and add to the Surface Plots Menu
  surfsMenu  = Widget_Button(roi_plotMenu, Value='Surface Plots', /menu)
  surfButton  = Widget_Button(surfsMenu, Value='Surface', $
			       Event_Pro = 'idp3_roisurf')
  shdsrfButton = Widget_Button(surfsMenu, Value='Shade_Surf', $
			       Event_Pro = 'idp3_roishadesurf')
  splayButton = Widget_Button(surfsMenu, Value='Surf_Play', $
			       Event_Pro = 'idp3_roisurfplay')

  ; Add to the plot Menu
  ; Noise Profile
  nprofButton = Widget_Button(roi_plotMenu, Value='Noise Profile', $
			       Event_Pro = 'idp3_noiseprof')
  ; Collapse 1D 
  roi_collapse = Widget_Button(roi_plotMenu, Value="Collapse 1D", $
      Event_Pro = 'idp3_roicollapse')
  ; Histogram
  histButton = Widget_Button(roi_plotMenu, Value='Histogram', $
			       Event_pro = 'idp3_roihist')
  ; Contour Map
  contourButton = Widget_Button(roi_plotMenu, Value='Contour Map', $
			       Event_Pro = 'idp3_conturoi')

  ; Add to the statstics Menu
  sprdshtButton = Widget_Button(roi_textMenu, Value='SpreadSheet', $
				Event_Pro = 'idp3_Spreadsheet')
  statsButton   = Widget_Button(roi_textMenu, Value='Statistics', $
			        Event_Pro = 'idp3_roiStatistics')
  photButton = Widget_Button(roi_textMenu, Value='Aperture Photometry', $
			      Event_Pro = 'idp3_phot')
  asymButton = Widget_Button(roi_textMenu, Value='Galactic Asymmetry', $
			       Event_pro = 'idp3_galasym')

  ; Add to mask Menu
  movemaskButton = Widget_Button(roi_maskMenu, Value='Move ROI Mask', $
				 Event_Pro = 'idp3_movemask')
  maskinvButton  = Widget_Button(roi_maskMenu, Value='Invert ROI Mask', $
				 Event_pro = 'roi_maskinv')
  rmovmaskButton = Widget_Button(roi_maskMenu, Value='Remove ROI Mask', $
				 Event_Pro = 'roi_removemask')
;  fill3Button    = Widget_button(roi_maskMenu, Value='      ', $
;				 Event_Pro = 'roi_nothing')
  rodButton = Widget_Button(roi_maskMenu, Value='Define ROD', $
			    Event_Pro = 'roi_definerod', /Separator)
  moverodButton = Widget_Button(roi_maskMenu, Value='Move ROD', $
				 Event_Pro = 'idp3_moverod')
  closerodButton  = Widget_Button(roi_maskMenu, Value='Remove ROD', $
			       Event_Pro = 'rod_Close')
  ; Add to zoom Menu
  z1Button = Widget_Button(roi_zoomMenu, Value=' 1 ', $
			   Event_Pro = 'roi_Zoom1')
  z2Button = Widget_Button(roi_zoomMenu, Value=' 2 ', $
			   Event_Pro = 'roi_Zoom2')
  z4Button = Widget_Button(roi_zoomMenu, Value=' 4 ', $
			   Event_Pro = 'roi_Zoom4')
  z8Button = Widget_Button(roi_zoomMenu, Value=' 8 ', $
			   Event_Pro = 'roi_Zoom8')
  z16Button = Widget_Button(roi_zoomMenu, Value=' 16 ', $
			   Event_Pro = 'roi_Zoom16')
  z32Button = Widget_Button(roi_zoomMenu, Value=' 32 ', $
			   Event_Pro = 'roi_Zoom32')
  z64Button = Widget_Button(roi_zoomMenu, Value=' 64 ', $
			   Event_Pro = 'roi_Zoom64')

  roizoom = (*roiinfo.roi).roizoom

  ; Get various information from the ROI structure,
  ; use this information to calculate new info to store back into the ROI.
  if (*roiinfo.roi).tempxbox gt (*roiinfo.roi).boxx0 then begin
    x1 = (*roiinfo.roi).boxx0
    x2 = (*roiinfo.roi).tempxbox
  endif else begin
    x2 = (*roiinfo.roi).boxx0
    x1 = (*roiinfo.roi).tempxbox
  endelse
  if (*roiinfo.roi).tempybox gt (*roiinfo.roi).boxy0 then begin
    y1 = (*roiinfo.roi).boxy0
    y2 = (*roiinfo.roi).tempybox
  endif else begin
    y2 = (*roiinfo.roi).boxy0
    y1 = (*roiinfo.roi).tempybox
  endelse

  roixsize = (abs(x1-x2)+1) * roizoom
  roiysize = (abs(y1-y2)+1) * roizoom
  (*roiinfo.roi).roixsize = roixsize
  (*roiinfo.roi).roiysize = roiysize
  roi_xmax = roiinfo.roi_xmax
  roi_ymax = roiinfo.roi_ymax
  (*roiinfo.roi).roixorig = x1 
  (*roiinfo.roi).roiyorig = y1 
  (*roiinfo.roi).roixend = x2
  (*roiinfo.roi).roiyend = y2

  boxbase = Widget_Base(roibase, Column=2)
  cur0base = Widget_Base(boxbase, column=1, /frame)
  cursor_label = Widget_Label(cur0base, Value='Select Mouse Mode: ')
  curbase = Widget_Base(cur0Base, row=1, map=1, uvalue='curbase')
  cursor_button_names = [$
    'None', $
    'CrossSection', $
    'RadialProfile', $
    'Polygon', $
    'MovePoly', $
    'EditPoly' ]
  cursor_button_value = (*roiinfo.roi).mouse_mode
  cursor_buttons = CW_BGROUP(curbase, cursor_button_names, row=1, exclusive=1,$
    Event_Funct='idp3_cursor', Set_Value=cursor_button_value, /no_release)

  ; Line for world coordinates 
  wcsstr = strmid(roiinfo.wcs_str, 0, 85)
  wcsLabel = Widget_Label(boxBase, Value = wcsstr)
  roiinfo.rwcslab = wcsLabel
 
  mask0base = Widget_Base(boxbase, column=2, /frame)
  mask1base = Widget_Base(mask0base, /column)
  
  redispButton = Widget_Button(mask1base, Value='Redisplay', $
    Event_Pro = 'roi_redisplay')
  mask2base = Widget_Base(mask1Base, /column, /nonexclusive)
  roimaskonoffButton = Widget_Button(mask2base, Value='ROIMaskOn', $
	     Event_Pro='roi_maskonoff')
  Widget_Control,roimaskonoffButton,Set_Button=(*roiinfo.roi).msk
  mask3base = Widget_Base(mask1base, /column, /nonexclusive)
  orientonoffButton = Widget_Button(mask3base, Value='Orient Vector', $
      Event_Pro = 'roi_orient')
  Widget_Control, orientonoffButton, Set_Button=(*roiinfo.roi).orivec


  ; Graphics window.
  rflg = 0
  if roixsize gt roi_xmax then begin
    rflg = rflg + 1
    roi_xscroll = roi_xmax
  endif else roi_xscroll = roixsize ;+ 1
  if roiysize gt roi_ymax then begin
    rflg = rflg + 2
    roi_yscroll = roi_ymax
  endif else roi_yscroll = roiysize ;+ 1 
  if rflg eq 0 then begin
    roiDraw = Widget_Draw(roiBase, XSize = roixsize, YSize = roiysize, $
			 /Motion_Events, /Button_Events, $
                         Event_Pro = 'Roi_Draw', Retain=roiinfo.retn)
  endif else begin
    roiDraw = Widget_Draw(roiBase, XSize = roixsize, YSize = roiysize, $
		 x_scroll_size = roi_xscroll, y_scroll_size = roi_yscroll, $
		 /scroll, /Motion_Events, /Button_Events, $
		 Event_Pro = 'Roi_Draw', Retain=roiinfo.retn)
  endelse
  pixvalLabel = Widget_Label(roiBase, Value = roiinfo.wcs_str)
  roiinfo.pixval = pixvalLabel
  pixval2Label = Widget_Label(roiBase, Value = roiinfo.wcs_str)
  roiinfo.pixval2 = pixval2Label
  roiinfo.roimskonof = roimaskonoffButton

  Widget_Control, roiBase, /Realize             ; Show the GUI

  Widget_Control, roiDraw, Get_Value = drawid2  ; Get the window index number

  roiinfo.roiBase = roiBase
  (*roiinfo.roi).drawid2 = drawid2
  (*roiinfo.roi).roiDraw = roiDraw

  Widget_Control, roiinfo.idp3Window, Set_UValue=roiinfo
  Widget_Control, leader, Set_UValue=roiinfo
  
  ; Write some stuff into the draw widget.
  roi_Display,roiinfo

  ; Save the info structure in the main widget base uvalue.
  Widget_Control, roibase, Set_UValue = roiinfo
  Widget_Control, roiinfo.idp3Window, Set_UValue = roiinfo

  XManager, 'idp3_roi', roiBase, /No_Block, Event_Handler='Roi_Resize'

end
