pro setcflags, cm, doirs, wm, gf, cwm, ifp

  case cm of
  0: begin
     wm = 0
     gf = 0
     cwm = 0
     ifp = 0
     end
  2: begin
     wm = 1
     gf = 0
     cwm = 0
     ifp = 0
     end
  4: begin
     wm = 0
     gf = 1
     cwm = 0
     ifp = 0
     end
  6: begin
     wm = 1
     gf = 1
     cwm = 0
     ifp = 0
     end
  8: begin
     wm = 0
     gf = 0
     if doirs eq 0 then begin
       cwm = 1
       ifp = 0
     endif else begin
       cwm = 0
       ifp = 1
     endelse
     end
 10: begin
     wm = 1
     gf = 0
     if doirs eq 0 then begin
       cwm = 1
       ifp = 0
     endif else begin
       cwm = 0
       ifp = 1
     endelse
     end
 12: begin
     wm = 0
     gf = 1
     if doirs eq 0 then begin
       cwm = 1
       ifp = 0
     endif else begin
       cwm = 0
       ifp = 1
     endelse
     if doirs eq 0 then begin
       cwm = 1
       ifp = 0
     endif else begin
       cwm = 0
       ifp = 1
     endelse
     cwm = 1
     end
 14: begin
     wm = 1
     gf = 1
     if doirs eq 0 then begin
       cwm = 1
       ifp = 0
     endif else begin
       cwm = 0
       ifp = 1
     endelse
     end
  else:
  endcase
end
   
pro radprof_hlp, Event
 tmp = idp3_findfile('idp3_radprof.hlp')
 xdisplayfile, tmp
end

pro radprof_xindx, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  wset, info.rprfdraw
  if strlen((*info.rprf).coordstr) gt 0 then $
   xyouts, 420, 10, /device, (*info.rprf).coordstr, color=!P.background 

  x = event.x > 61 < 579
  y = event.y > 41 < 254
  res = convert_coord(x, event.y, /device, /to_data)
  xval = res[0]
  yval = res[1]
  str = 'XCur:' + string(xval,'$(f9.4)') + '  YCur:' + $
       string(yval, '$(f10.4)')
  if (*info.rprf).log eq 1 then str = str + ' [' + $
      string(alog10(yval), '$(f8.4)') + ']'
  if info.color_bits eq 0 then lab_color=200 else lab_color=5
  xyouts, 420, 10, /device, str, color=lab_color
  (*info.rprf).coordstr = str
  if event.type eq 0 then idp3_updatetxt, info, str
  Widget_Control, info.idp3Window, Set_UValue=info
end

pro showinregion, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  roi = info.roi
  Widget_Control, info.rpwmhbtxt, Get_Value=temp
  hbox = float(temp[0])
  if hbox lt 1. then begin
    str = 'RadProf: No HalfBox specified'
    idp3_updatetxt, info, str
    return
  endif
  coords = fltarr(4)
  Widget_Control, info.rpxcentxt, Get_Value=temp
  xcen = float(temp[0])
  Widget_Control, info.rpycentxt, Get_Value=temp
  ycen = float(temp[0])
  x1 = (*info.roi).roixorig
  x2 = (*info.roi).roixend
  y1 = (*info.roi).roiyorig
  y2 = (*info.roi).roiyend
  coords[0] = xcen - hbox
  coords[1] = xcen + hbox
  coords[2] = ycen - hbox
  coords[3] = ycen + hbox
  if coords[0] ge x1 and coords[1] le x2 and coords[2] ge y1 and $
    coords[3] le y2 then begin
    wset, (*roi).drawid2
    value = info.color_xsect
    if value lt 1 then value = 200
    for i = 0,3 do begin
      xl = (coords[0] - x1) * (*roi).roizoom
      xr = (coords[1] - x1) * (*roi).roizoom
      yb = (coords[2] - y1) * (*roi).roizoom
      yt = (coords[3] - y1) * (*roi).roizoom
    endfor
    plots, xl, yb, color=value, /device
    plots, xr, yb, color=value, /device, /continue
    plots, xr, yt, color=value, /device, /continue
    plots, xl, yt, color=value, /device, /continue
    plots, xl, yb, color=value, /device, /continue
  endif else begin
    str = 'RadProf: Coordinates do not match ROI'
    idp3_updatetxt, info, str
  endelse
  end

pro showwmregion, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  roi = info.roi
  coords = (*roi).wmcoords
  if max(coords) lt 0 then begin
    str = 'RadProf: No Weighted Moment Region Defined'
    idp3_updatetxt, info, str
  endif else begin
    x1 = (*info.roi).roixorig
    x2 = (*info.roi).roixend
    y1 = (*info.roi).roiyorig
    y2 = (*info.roi).roiyend
    if coords[0] ge x1 and coords[1] le x2 and coords[2] ge y1 and $
       coords[3] le y2 then begin
       wset, (*roi).drawid2
       value = info.color_radpf
       if value lt 1 then value = 200
       for i = 0,3 do begin
	 xl = (coords[0] - x1) * (*roi).roizoom
	 xr = (coords[1] - x1) * (*roi).roizoom
	 yb = (coords[2] - y1) * (*roi).roizoom
	 yt = (coords[3] - y1) * (*roi).roizoom
       endfor
       plots, xl, yb, color=value, /device
       plots, xr, yb, color=value, /device, /continue
       plots, xr, yt, color=value, /device, /continue
       plots, xl, yt, color=value, /device, /continue
       plots, xl, yb, color=value, /device, /continue
    endif else begin
      str = 'RadProf: Coordinates do not match ROI'
      idp3_updatetxt, info, str
    endelse
  endelse
  end

pro radprof_setsmfact, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpsmxtxt, Get_Value = temp
  info.rpsmoothwid = fix(temp[0])
  widget_control, info.idp3Window, Set_UValue=info
  widget_control, event.top, Set_UValue=info
end

pro radprof_undosm, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  (*info.roi).rpsmooth = 0
  info.rpsmoothwid = 1
  widstr = strtrim(string(info.rpsmoothwid),2)
  Widget_Control, info.rpsmxtxt, Set_Value = widstr
  Widget_Control, info.idp3Window, Set_UValue=info
  idp3_radprof, info
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro radprof_smooth, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpsmxtxt, Get_Value = temp
  smwidth = fix(temp[0])
  if smwidth gt 1 then begin
    info.rpsmoothwid = smwidth
    (*info.roi).rpsmooth = 1
    idp3_rpsmooth, info
  endif else begin
    stat = Widget_Message('Smoothing Width must be greater than 1.')
  endelse
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function radprof_type, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  domedian = event.value
  (*info.roi).rpmm = domedian
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  idp3_radprof, info
end

function radprof_method, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpmethods, get_value=barray
  if info.doirs eq 1 then begin
    if (barray[0] eq 1 or barray[1] eq 1) and barray[2] eq 1 then begin
      barray[0] = 0
      barray[1] = 0
      barray[2] = 0
      stat = widget_message($
	'IRS Focal Plane is mutually exclusive from other methods')
      widget_Control, info.rpmethods, set_value=[0,0,0]
    endif
  endif
  cmethod = barray[0] * 2 + barray[1] * 4 + barray[2] * 8
  (*info.roi).cmethod = cmethod
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function radprof_errors, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  eplot = event.value
  (*info.roi).rpeplot = eplot
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  idp3_radprof, info
end

function radprof_scale, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpautobutton, Get_Value = barray
  if barray[0] eq 0 then info.rp_autoscl = 0 else info.rp_autoscl = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  idp3_radprof, info
end

function radprof_autocenter, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpautocenButton, Get_Value = barray
  if barray[0] eq 0 then info.cent.autocenter = 0 else info.cent.autocenter = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function radprof_fitcircle, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpfitcircleButton, Get_Value = barray
  if barray[0] eq 0 then info.cent.fitcircle = 0 else info.cent.fitcircle = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro rpdisp_done, Event
  Widget_Control, event.top, /Destroy
end

pro showgauss_ev, Event

@idp3_errors

  Widget_Control, event.top, Get_UValue=gsinfo
  Widget_Control, gsinfo.info.idp3Window, Get_UValue=info
  ncolors = info.d_colors - info.color_bits - 1
  pos_color = 3 ; green
  neg_color = 2 ; red
  no_color = 250 ; white

  case event.id of

    gsinfo.saverpButton: begin
      idp3_savegraw, event
    end

    gsinfo.savefitButton: begin
      idp3_savegfit, event
    end

    gsinfo.saveresidButton: begin
      idp3_savegresid, event
    end

    gsinfo.ovlyButton: begin
      Widget_control, gsinfo.ovlyButton, Get_Value = overlay
      if overlay eq 0 then info.rpgcntr_ovly = 0 else info.rpgcntr_ovly = 1
      im1 = *info.rpgaussim1
      im2 = *info.rpgaussim2
      im3 = im1 - im2
      imsz = size(im3)
      Widget_control, gsinfo.residz1txt, Get_Value=rz1str
      rz1 = float(rz1str[0])
      Widget_control, gsinfo.residz2txt, Get_Value=rz2str
      rz2 = float(rz2str[0])
      Widget_Control, gsinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, gsinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      wset, info.rprfgim4
      levs = fltarr(nlevs)
      delta = (rz2 - rz1) / float(nlevs-1)
      for i = 0, nlevs-1 do begin
        levs[i] = rz1 + float(i) * delta
      endfor
      px = [0.1, float(imsz[1])-0.1]
      py = [0.1, float(imsz[2])-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits ge 6 then begin
        col = intarr(nlevs)
	col[*] = pos_color 
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if overlay eq 1 then begin
        tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
        contour, im3,/noerase,levels=levs,min_value=rz1,max_value=rz2,$
          pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endif else begin
	erase
        contour, im3, levels=levs, min_value=rz1, max_value=rz2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col 
      endelse
    end

    gsinfo.fitz1txt: begin
      Widget_control, gsinfo.fitz1txt, Get_Value=fz1str
      Widget_control, gsinfo.fitz2txt, Get_Value=fz2str
      fz1 = float(fz1str[0])
      fz2 = float(fz2str[0])
      wset, info.rprfgim1
      im1 = *info.rpgaussim1
      im2 = *info.rpgaussim2
      tv, bytscl(im1, top=ncolors, min=fz1, max=fz2) + info.color_bits
      wset, info.rprfgim2
      tv, bytscl(im2, top=ncolors, min=fz1, max=fz2) + info.color_bits
    end

    gsinfo.fitz2txt: begin
      Widget_control, gsinfo.fitz1txt, Get_Value=fz1str
      Widget_control, gsinfo.fitz2txt, Get_Value=fz2str
      fz1 = float(fz1str[0])
      fz2 = float(fz2str[0])
      wset, info.rprfgim1
      im1 = *info.rpgaussim1
      im2 = *info.rpgaussim2
      tv, bytscl(im1, top=ncolors, min=fz1, max=fz2) + info.color_bits
      wset, info.rprfgim2
      tv, bytscl(im2, top=ncolors, min=fz1, max=fz2) + info.color_bits
    end

    gsinfo.residz1txt: begin
      Widget_Control, gsinfo.residz1txt, Get_Value=rz1str
      rz1 = float(rz1str[0])
      Widget_Control, gsinfo.residz2txt, Get_Value=rz2str
      rz2 = float(rz2str[0])
      Widget_Control, gsinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, gsinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      wset, info.rprfgim3
      im1 = *info.rpgaussim1
      imsz = size(im1)
      im2 = *info.rpgaussim2
      im3 = im1 - im2
      tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
      wset, info.rprfgim4
      levs = fltarr(nlevs)
      delta = (rz2 - rz1) / float(nlevs-1)
      for i = 0, nlevs-1 do begin
        levs[i] = rz1 + float(i) * delta
      endfor
      px = [0.1, float(imsz[1])-0.1]
      py = [0.1, float(imsz[2])-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits ge 6 then begin
        col = intarr(nlevs)
	col[*] = pos_color
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if info.rpgcntr_ovly eq 1 then begin
        tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
        contour, im3, /noerase,levels=levs,min_value=rz1,max_value=rz2, $
          pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endif else begin
	erase
        contour, im3, levels=levs, min_value=rz1, max_value=rz2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endelse
    end

    gsinfo.residz2txt: begin
      Widget_control, gsinfo.residz1txt, Get_Value=rz1str
      rz1 = float(rz1str[0])
      Widget_control, gsinfo.residz2txt, Get_Value=rz2str
      rz2 = float(rz2str[0])
      Widget_Control, gsinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, gsinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      wset, info.rprfgim3
      im1 = *info.rpgaussim1
      imsz = size(im1)
      im2 = *info.rpgaussim2
      im3 = im1 - im2
      tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
      wset, info.rprfgim4
      levs = fltarr(nlevs)
      delta = (rz2 - rz1) / float(nlevs-1)
      for i = 0, nlevs-1 do begin
        levs[i] = rz1 + float(i) * delta
      endfor
      px = [0.1, float(imsz[1])-0.1]
      py = [0.1, float(imsz[2])-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits ge 6 then begin
        col = intarr(nlevs)
	col[*] = pos_color
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if info.rpgcntr_ovly eq 1 then begin
        tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
        contour, im3, /noerase,levels=levs,min_value=rz1,max_value=rz2, $
          pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endif else begin
	erase
        contour, im3, levels=levs, min_value=rz1, max_value=rz2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endelse
    end
    
    gsinfo.nlevstxt: begin
      Widget_Control, gsinfo.residz1txt, Get_Value=rz1str
      rz1 = float(rz1str[0])
      Widget_Control, gsinfo.residz2txt, Get_Value=rz2str
      rz2 = float(rz2str[0])
      Widget_Control, gsinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, gsinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      im1 = *info.rpgaussim1
      imsz = size(im1)
      im2 = *info.rpgaussim2
      im3 = im1 - im2
      wset, info.rprfgim4
      levs = fltarr(nlevs)
      delta = (rz2 - rz1) / float(nlevs-1)
      for i = 0, nlevs-1 do begin
        levs[i] = rz1 + float(i) * delta
      endfor
      px = [0.1, float(imsz[1])-0.1]
      py = [0.1, float(imsz[2])-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits ge 6 then begin
        col = intarr(nlevs)
	col[*] = pos_color
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if info.rpgcntr_ovly eq 1 then begin
        tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
        contour, im3, /noerase,levels=levs,min_value=rz1,max_value=rz2, $
          pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endif else begin
	erase
        contour, im3, levels=levs, min_value=rz1, max_value=rz2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col
      endelse
    end

    endcase
    Widget_Control, gsinfo.info.idp3Window, Set_UValue=info
    Widget_Control, event.top, Set_UValue=gsinfo
end

pro radprof_showgauss, Event

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  Widget_Control, event.top, Set_UValue = info

  if (*info.roi).cmethod eq 4 or (*info.roi).cmethod eq 6 or $
    (*info.roi).cmethod eq 12 or (*info.roi).cmethod eq 14 then begin
    if XRegistered('idp3_radprofims') $
	 then Widget_Control, info.idp3rprfgim, /Destroy
    im1 = *info.rpgaussim1
    imsz = size(im1)
    im2 = *info.rpgaussim2
    im3 = im1 - im2
    pos_color = 3
    neg_color = 2
    no_color = 250
    c = imscale(im3, 10.0)
    rz1 = c[0]
    rz2 = c[1]
    rz1str = strtrim(string(rz1),2)
    rz2str = strtrim(string(rz2),2)
    zm2 = (*info.roi).roizoom ^ 2
    if info.zoomflux eq 1 then begin
      dz1 = info.z1 / zm2
      dz2 = info.z2 / zm2
    endif else begin
      dz1 = info.z1
      dz2 = info.z2
    endelse
    dz1str = strtrim(string(dz1),2)
    dz2str = strtrim(string(dz2),2)
    idp3rprfgim = widget_base (group_leader=info.idp3rprf, $
       xoffset=info.wpos.arwp[0], $
       yoffset=info.wpos.arwp[1], $
       /column,Title='IDP3-ROI 2-D Gaussfit Display')
    info.idp3rprfgim = idp3rprfgim
    buttonbase = Widget_Base(idp3rprfgim, /Row)
    saverpButton = Widget_Button(buttonbase, Value=' Save Raw ')
    savefitButton = Widget_Button(buttonbase, Value=' Save Fit ')
    saveresidButton = Widget_Button(buttonbase, Value=' Save Residuals ')
    labbut = Widget_Label(buttonbase, Value=' ')
    donebutton = widget_button (buttonbase, value=' Done ', $
       Event_Pro = 'rpdisp_done')
    colbase = Widget_Base(idp3rprfgim, Column=2)
    im1base = Widget_Base(colbase, /column)
    radprofim1 = Widget_Draw(im1base, xsize=imsz[1], ysize=imsz[2], $
		 retain=info.retn)
    lab1 = Widget_Label(im1base, Value='Raw Data',/align_center)
    radprofim2 = Widget_Draw(im1base, xsize=imsz[1], ysize=imsz[2], $
		 retain=info.retn)
    lab2 = Widget_Label(im1base, Value='Fitted Data',/align_center)
    zfbase = Widget_Base(im1base, /Row)
    zflab = Widget_Label(zfbase, Value='Data/Model - Z1:')
    fitz1txt = Widget_Text(zfbase, Value = dz1str, xsize=7, /Edit)
    zflab2 = Widget_Label(zfbase, Value='Z2:')
    fitz2txt = Widget_Text(zfbase, Value = dz2str, xsize=7, /Edit)
    im2base = Widget_Base(colbase, /column)
    radprofim3 = Widget_Draw(im2base, xsize=imsz[1], ysize=imsz[2], $
		 retain=info.retn)
    lab3 = Widget_Label(im2base, Value='Residuals',/align_center)
    radprofim4 = Widget_Draw(im2base, xsize=imsz[1], ysize=imsz[2], $
		 retain=info.retn)
    lab4 = Widget_Label(im2base, Value='Residual Contours')
    zrbase = Widget_Base(im2base, /Row)
    zrlab = Widget_Label(zrbase, Value='Residual - Z1:')
    residz1txt = Widget_Text(zrbase, Value = rz1str, xsize=7, /Edit)
    zlab2 = Widget_Label(zrbase, Value='Z2:')
    residz2txt = Widget_Text(zrbase, Value = rz2str, xsize=7, /Edit)
    zr2base = Widget_Base(im2base, /Row)
    nllab = Widget_Label(zr2base, Value='Levs:')
    nlevstxt = Widget_Text(zr2base, Value = '12', xsize=2, /Edit)
    ovlyButton = cw_bgroup(zr2base, ['Overlay Image'], row=1, /nonexclusive, $
		 set_value=[info.rpgcntr_ovly])

    gsinfo = { saverpButton   :  saverpButton,     $
	       savefitButton  :  savefitButton,    $
	       saveresidButton:  saveresidButton,  $
               fitz1txt       :  fitz1txt,         $
	       fitz2txt       :  fitz2txt,         $
	       residz1txt     :  residz1txt,       $
	       residz2txt     :  residz2txt,       $
	       nlevstxt       :  nlevstxt,         $
	       ovlyButton     :  ovlyButton,       $
	       info           :  info              $
						   }
					  
    Widget_Control, idp3rprfgim, Set_UValue = gsinfo

    ; Realize the widget onto the screen.
    Widget_Control, idp3rprfgim, /Realize
    Widget_Control, radprofim1, Get_Value=rprfim1
    Widget_Control, radprofim2, Get_Value=rprfim2
    Widget_Control, radprofim3, Get_Value=rprfim3
    Widget_Control, radprofim4, Get_Value=rprfim4
    info.rprfgim1 = rprfim1
    info.rprfgim2 = rprfim2
    info.rprfgim3 = rprfim3
    info.rprfgim4 = rprfim4
    Widget_Control,info.idp3Window,Set_UValue=info
    XManager, 'idp3_radprofims', idp3rprfgim, /no_Block, $
      Event_Handler='showgauss_ev'
    ncolors = info.d_colors - info.color_bits - 1
    wset, info.rprfgim1
    erase
    tv, bytscl(im1, top=ncolors, min=dz1, max=dz2) + info.color_bits 
    wset, info.rprfgim2
    erase
    tv, bytscl(im2, top=ncolors, min=dz1, max=dz2) + info.color_bits 
    wset, info.rprfgim3
    erase
    tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits 
    wset, info.rprfgim4
    erase
    nlevs = 12
    levs = fltarr(nlevs)
    delta = (rz2 - rz1) / float(nlevs-1)
    for i = 0, nlevs-1 do begin
      levs[i] = rz1 + float(i) * delta
    endfor
    px = [0.1, float(imsz[1])-0.1]
    py = [0.1, float(imsz[2])-0.1]
    linstyl = intarr(nlevs)
    linstyl[*] = 0
    neg = where(levs lt 0, count)
    if count gt 0 then linstyl[neg] = 2
    if info.color_bits ge 6 then begin
      col = intarr(nlevs)
      col[*] = pos_color
      if count gt 0 then col[neg] = neg_color
    endif else col = no_color
    if info.rpgcntr_ovly eq 1 then begin
      tv, bytscl(im3, top=ncolors, min=rz1, max=rz2) + info.color_bits
      contour, im3, /noerase,levels=levs,min_value=rz1,max_value=rz2, $
        pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $ 
	c_linestyle=linstyl, c_colors=col
    endif else begin
      contour, im3, levels=levs, min_value=rz1, max_value=rz2, $
        pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	c_linestyle=linstyl, c_colors=col
    endelse
  endif
end

function radprof_oplot, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  widget_control, info.rpoplotbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.rprf).oplot = 0 else (*info.rprf).oplot = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

function radprof_eeplot, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  widget_control, info.rpeebutton, Get_Value = barray
  if barray[0] eq 0 then (*info.rprf).ee = 0 else (*info.rprf).ee = 1
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
  idp3_display, info
end

function radprof_logscale, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  widget_control, info.rplogbutton, Get_Value = barray
  if barray[0] eq 0 then (*info.rprf).log = 0 else (*info.rprf).log = 1
;  (*info.rprf).oplot = 0
  idp3_display,info
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro radprof_ymin, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_control, info.rpymintxt, Get_Value=rpymin
  Widget_control, info.rpymaxtxt, Get_Value=rpymax
  info.rp_autoscl = 0
  Widget_Control, info.rpautobutton, Set_Value = info.rp_autoscl
  wset, info.rprfdraw
  yr = [rpymin,rpymax]
  xplot = *info.radpx
  stdplot = *info.radstd
  if (*info.rprf).ee eq 0 then begin
    yplot = *info.radpy
    yt = 'Intensity'
  endif else begin
    yplot = *info.radee
    yt = 'Enc Energy'
  endelse
  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
  xmax = max(xplot)
  xr = [0.,xmax]
  if (*info.rprf).log eq 0 then begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
        xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr 
    if (*info.rprf).ee eq 0 and (*info.roi).rpeplot gt 0 then begin
      if (*info.roi).rpeplot eq 1 then begin 
	idp3_errbars, xplot, yplot, yerr=stdplot, color=2
      endif else begin
        npts = *info.radnpt
	fix = where(npts lt 2, cnt)
	if cnt gt 0 then npts(fix) = 2
        seplot = stdplot / sqrt(npts-1)
	idp3_errbars, xplot, yplot, yerr=seplot, color=2
      endelse
    endif
  endif else begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
      xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr, /ylog
  endelse
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro radprof_ymax, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  Widget_control, info.rpymintxt, Get_Value=rpymin
  Widget_control, info.rpymaxtxt, Get_Value=rpymax
  info.rp_autoscl = 0
  Widget_Control, info.rpautobutton, Set_Value = info.rp_autoscl
  wset, info.rprfdraw
  yr = fltarr(2)
  yr[0] = float(rpymin)
  yr[1] = float(rpymax)
  xplot = *info.radpx
  stdplot = *info.radstd
  if (*info.rprf).ee eq 0 then begin
    yplot = *info.radpy 
    yt = 'Intensity'
  endif else begin
    yplot = *info.radee
    yt = 'Enc Energy'
  endelse
  if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
  if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
  xmax = max(xplot)
  xr = [0.,xmax]
  if (*info.rprf).log eq 0 then begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
        xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr 
    if (*info.rprf).ee eq 0 and (*info.roi).rpeplot gt 0 then begin
      if (*info.roi).rpeplot eq 1 then begin 
	idp3_errbars, xplot, yplot, yerr=stdplot, color=2
      endif else begin
        npts = *info.radnpt
	fix = where(npts lt 2, cnt)
	if cnt gt 0 then npts(fix) = 2
        seplot = stdplot / sqrt(npts-1)
	idp3_errbars, xplot, yplot, yerr=seplot, color=2
      endelse
    endif
  endif else begin
    plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
      xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr, /ylog
  endelse
  widget_control, event.top, Set_UValue=info
  widget_control, info.idp3Window, Set_UValue=info
end

pro radprof_xcen, Event
  ; update radial profile center X position
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpxcentxt, Get_Value=temp
  (*info.roi).radxcent = (float(temp[0]) - (*info.roi).roixorig) * $
      (*info.roi).roizoom
  (*info.rprf).sx = float(temp[0])
  Widget_Control, info.idp3Window, Set_UValue = info
  idp3_display, info
end

pro radprof_ycen, Event
  ; update radial profile center Y position
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpycentxt, Get_Value=temp
  (*info.roi).radycent = (float(temp[0]) - (*info.roi).roiyorig) * $
      (*info.roi).roizoom
  (*info.rprf).sy = float(temp[0])
  Widget_Control, info.idp3Window, Set_UValue = info
  idp3_display, info
end

pro radprof_radius, Event
  ; update radial profile radius
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  Widget_Control, info.rpradiustxt, Get_Value=temp
  (*info.roi).radradius = float(temp[0]) * (*info.roi).roizoom 
  (*info.rprf).r = float(temp[0])
  Widget_Control, info.idp3Window, Set_UValue = info
  idp3_display, info
end

pro radprof_fwhm, Event
  widget_control, event.top, Get_UValue=info
  widget_control, info.idp3Window, Get_UValue=info
  xplot = *info.radpx
  yplot = *info.radpy
  ymin = min(yplot)
  ymax = max(yplot)
  midpt = (ymax + ymin) * 0.5
  numpts = n_elements(yplot)
  for i = 0, numpts-2 do begin
    if midpt lt yplot[i] and midpt gt yplot[i+1] then begin
      pct = (yplot[i]-midpt) / abs(yplot[i]-yplot[i+1])
      xpt = xplot[i] + pct * abs(xplot[i] - xplot[i+1])
    endif
  endfor
  if xpt gt 0. then begin
    fwhm = 2.0 * xpt
    info.cent.fwhm = fwhm
    str = 'RadProf: Midpoint = ' + string(midpt) + '  FWHM = ' + $
	  string(fwhm) + ' pixels'
    idp3_updatetxt, info, str
    Widget_Control, info.rpfwhmtxt, Set_Value=string(fwhm,'$(f8.3)')
    Widget_Control, info.idp3Window, Set_UValue=info
  endif else begin
    str = 'RadProf: Bad FWHM, value not changed'
    idp3_updatetxt, info, str
  endelse
end

pro radprof_done, Event
  geo = Widget_Info(event.top, /geometry)
  widget_control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  info.wpos.rpwp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rpwp[1] = geo.yoffset - info.yoffcorr
  (*info.roi).centfit = 0
  Widget_Control, info.idp3Window, Set_UValue=info
  Widget_Control, event.top, /Destroy

  rprf = info.rprf
  roi = info.roi
  wset,(*roi).drawid2
  rcl = info.color_radpf
  (*roi).radradius = -1.0
  wset, info.drawid1
  info.roi = roi
  roi_display, info
end

pro idp3_radprof, info
@idp3_errors


  Widget_Control, info.idp3Window, Get_UValue=info

  domm = (*info.roi).rpmm
  setcflags, (*info.roi).cmethod, info.doirs, wm, gf, cwm, ifp
  er = (*info.roi).rpeplot
  swmhb = strtrim(string(info.cent.halfbox),2)
  blankstr = $
    '                                                                        '

  if not XRegistered('idp3_radprof') then begin
    idp3rprf = widget_base (group_leader=info.idp3Window, $
			  xoffset=info.wpos.rpwp[0], $
			  yoffset=info.wpos.rpwp[1], $
			  /column,Title='IDP3-ROI Radial Profile')
  
    info.idp3rprf = idp3rprf
    tbase = Widget_Base(idp3rprf, /row)
    showgaussbutton = Widget_Button(tbase, Value='GaussShow', /align_center, $
	     Event_Pro='radprof_showgauss')
    fill1 = Widget_Label(tbase, Value=' Smooth: Pix')
    strfact = strtrim(string(info.rpsmoothwid),2)
    sfacttxt = Widget_Text(tbase, Value=strfact, xsize=2, /Edit, $
	       Event_Pro = 'radprof_setsmfact')
    smoothButton = Widget_Button(tbase, Value = 'Smooth', /align_center, $
	   Event_Pro='radprof_smooth')
    undosmbutton = Widget_Button(tbase, Value='Undo', /align_center, $
	     Event_Pro = 'radprof_undosm')
    fill2 = Widget_Label(tbase, Value = ' ')
    profile2dbutton = Widget_Button(tbase, Value='RP2D', /align_center, $
	     Event_Pro = 'idp3_radprof2d')
    fill3 = Widget_Label(tbase, Value = ' Save:')
    centsavebutton = Widget_Button(tbase,Value='Centroid', /align_center, $
	     Event_Pro = 'idp3_savecentroid')
    savButton  = Widget_Button(tbase, Value='RadProf', /align_center, $
		 Event_Pro = 'idp3_SaveRadProf')
    fill4 = Widget_Label(tbase, Value=' ')
    prntButton  = Widget_Button(tbase, Value='Print', /align_center, $
		 Event_Pro = 'idp3_PrintRadProf')
    helpbutton = Widget_Button(tbase, Value='Help', /align_center, $
		Event_Pro='radprof_hlp')
    donebutton = Widget_Button (tbase,Value='Done', /align_center, $
		Event_Pro='radprof_done')
    rprfdraw = widget_draw(idp3rprf,xsize=600, ysize=325, /button_events, $
	  /motion_events, Event_Pro='radprof_xindx', retain=info.retn)
    buttonbase = Widget_Base(idp3rprf,/row)
    lab1 = Widget_Label(buttonbase, Value='Ymin:')
    rpymintxt = Widget_Text(buttonbase, Value='0.', xsize=7, /Edit, $
	       Event_Pro = 'radprof_ymin')
    lab2 = Widget_Label(buttonbase, Value='Ymax:')
    rpymaxtxt = Widget_Text(buttonbase, Value='0.', xsize=7, /Edit, $
	       Event_Pro = 'radprof_ymax')
    fills = Widget_Label(tbase, Value=' ')
    autoButton = cw_bgroup(buttonbase,['Auto Scale'],row = 1, /nonexclusive, $
	 set_value=[info.rp_autoscl], Event_Funct='radprof_scale')
    logButton = cw_bgroup(buttonbase,['Log Scale'],row = 1, /nonexclusive, $
	 set_value=[(*info.rprf).log], Event_Funct='radprof_logscale')
    eeButton = cw_bgroup(buttonbase,['Encircled Energy'],row=1, /nonexclusive, $
	 set_value=[(*info.rprf).ee], Event_Funct='radprof_eeplot')
    oplotButton = cw_bgroup(buttonbase,['OverPlot'],row = 1, /nonexclusive, $
	 set_value=[(*info.rprf).oplot], Event_Funct='radprof_oplot')
    buttonbase2 = Widget_Base(idp3rprf,/row)
    enames = ['None', 'SDErr','SErr']
    eButtons = cw_bgroup(buttonbase2, enames, row=1, label_left='Plot Err:', $
      uvalue='ebutton', set_value=er, exclusive=1, Event_Funct='radprof_errors')
    splab = Widget_Label(buttonbase2, Value='  ')
    snpbutton = Widget_Button(buttonbase2, Value='S/N Plot', /align_center, $
	       Event_Pro = 'idp3_rpsnplot')
    splab2 = Widget_Label(buttonbase2, Value='  ')
    showlabel = Widget_Label(buttonbase2, Value='ShowBox:')
    showinbutton = Widget_Button(buttonbase2, Value='HalfBox', /align_center, $
	       Event_Pro = 'showinregion')
    showwmbutton = Widget_Button(buttonbase2, Value='WgtMoment', $
	       /align_center, Event_Pro = 'showwmregion')
    labbase = Widget_Base(idp3rprf, /Row)
    mnames = ['Mean', 'Median']
    mButtons = cw_bgroup(labbase, mnames, row=1, label_left='Profile:', $
      uvalue='mbutton', set_value=domm, exclusive=1, Event_Funct='radprof_type')
    lab4 = Widget_Label(labbase, Value='XCenter')
    xcentxt = Widget_Text(labbase, Value=' ', xsize=10, /Edit, $
	       Event_Pro = 'radprof_xcen')
    lab5 = Widget_Label(labbase, Value='YCenter')
    ycentxt = Widget_Text(labbase, Value=' ', xsize=10, /Edit, $
	       Event_Pro = 'radprof_ycen')
    lab6 = Widget_Label(labbase, Value='Radius')
    radiustxt = Widget_Text(labbase, Value=' ', xsize=7, /Edit, $
	       Event_Pro = 'radprof_radius')
    parbase = Widget_Base(idp3rprf, /Row)
    par1lab = Widget_Label(parbase, Value = 'Fitting: FWHM')
    fwhmtxt = Widget_Text(parbase, Value=' ', xsize=8, /Edit, $
	       Event_Pro = 'Idp3_Nothing')
    setfwhmbutton=Widget_Button(parbase,Value='Calc FWHM',/align_center, $
	     Event_Pro='radprof_fwhm')
    fitcircleButton = cw_bgroup(parbase,['Fit Circle'],row = 1, /nonexclusive, $
	 set_value=[info.cent.fitcircle], Event_Funct='radprof_fitcircle')
    par2lab = Widget_Label(parbase, Value = ' WgtMoment: HalfBox')
    rpwmhbtxt = Widget_Text(parbase, Value=swmhb, xsize=5, /Edit, $
	       Event_Pro = 'Idp3_Nothing')
    autocButton = cw_bgroup(parbase,['CenterPeakUp'],row = 1, /nonexclusive, $
	 set_value=[info.cent.autocenter], Event_Funct='radprof_autocenter')
    valbase = Widget_Base(idp3rprf, /Row)
    resbase = Widget_Base(idp3rprf, /Row)
    res1base = Widget_Base(resbase, /Column,/Frame)
    if info.doirs eq 0 then begin
      cnames = ['WgtMoment(Original)', 'GaussFit      ','WgtMoment(HalfBox)']
      cButtons = cw_bgroup(res1base, cnames, column = 1, $
        uvalue='cbutton', set_value=[wm,gf,cwm], /nonexclusive,$
        Event_Funct='radprof_method')
    endif else begin
      cnames = ['WgtMoment(Original)', 'GaussFit      ','IRSFocalPlane']
      cButtons = cw_bgroup(res1base, cnames, column = 1, $
        uvalue='cbutton', set_value=[wm,gf,ifp], /nonexclusive,$
        Event_Funct='radprof_method')
    endelse
    centroidbutton = Widget_Button(res1base,Value='Centroid', $
	     Event_Pro = 'idp3_rpcentroid')
    res0base = Widget_Base(resbase, /Column, /Frame)
    centradLabel = Widget_Label(res0base, Value=blankstr)
    centrad2Label = Widget_Label(res0base, Value=blankstr)
    centrad3Label = Widget_Label(res0base, Value=blankstr)
    centrad4Label = Widget_Label(res0base, Value=blankstr)
    centrad5Label = Widget_Label(res0base, Value=blankstr)
  
    widget_control, idp3rprf, /realize

    WIDGET_CONTROL, rprfdraw, GET_VALUE=drawfield_id
    info.rprfdraw = drawfield_id
    info.rprfcrlab = centradLabel
    info.rprfcrlab2 = centrad2Label
    info.rprfcrlab3 = centrad3Label
    info.rprfcrlab4 = centrad4Label
    info.rprfcrlab5 = centrad5Label
    info.rpymintxt = rpymintxt
    info.rpymaxtxt = rpymaxtxt
    info.rpautobutton = autobutton
    info.rpoplotbutton = oplotbutton
    info.rplogbutton = logbutton
    info.rpeebutton = eebutton
    info.rpxcentxt = xcentxt
    info.rpycentxt = ycentxt
    info.rpradiustxt = radiustxt
    info.rpfwhmtxt = fwhmtxt
    info.rpmethods = cButtons
    info.rpsmxtxt = sfacttxt
    info.rpwmhbtxt = rpwmhbtxt
    info.rpautocenButton = autocButton
    info.rpfitcircleButton = fitcircleButton
    Widget_Control,info.idp3Window,Set_UValue=info
  endif

  wset, info.rprfdraw
  rprf = *info.rprf
  ls = info.rprfline
  ls = ls + 1
  if ls eq 6 then ls = 1
  if not XRegistered('idp3_radprof') then overplot=0 else overplot=rprf.oplot

  roi = info.roi
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend
  zoom = (*roi).roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = info.roiioz
  dataimage = ptr_new(idp3_congrid((*info.dispim)[x1:x2,y1:y2], $ 
         xsize, ysize, zoom, ztype, info.pixorg)) 
  if info.zoomflux eq 1 then *dataimage = *dataimage/(zoom ^ 2) 
  alph = (*info.alphaim)[x1:x2,y1:y2]
  alph[*,*] = 1.
  bad = where((*info.alphaim)[x1:x2,y1:y2] eq 0., bcnt)
  if bcnt gt 0 then alph[bad] = 0.
  alphaim = idp3_congrid(alph, xsize, ysize, zoom, ztype, info.pixorg) 
  alph = 0
  idp3_checktol, alphaim, info.masktol
  nbins = fix((*roi).radradius) + 100  ; patched on jan 16 2013
  if nbins gt 1 then begin
    theplot = fltarr(nbins)
    totalplot = fltarr(nbins)
    stdplot = fltarr(nbins)
    eeplot = fltarr(nbins)
    theplotcount = intarr(nbins)
    nrej = intarr(nbins)
    stdplot = fltarr(nbins)
    maxpt = fix(nbins*2*!pi) + 50
    tempdat = fltarr(nbins,maxpt)
    xcent = (*roi).radxcent
    xc = xcent/zoom + x1
    ycent = (*roi).radycent
    yc = ycent/zoom + y1
    trad = (*roi).radradius
    rad = trad/zoom
    xcstr = strmid(strtrim(string(xc,'$(f12.5)'),2),0,10)
    Widget_Control, info.rpxcentxt, Set_Value = xcstr
    ycstr = strmid(strtrim(string(yc,'$(f12.5)'),2),0,10)
    Widget_Control, info.rpycentxt, Set_Value = ycstr
    radstr = strmid(strtrim(string(rad,'$(f10.3)'),2),0,7)
    Widget_Control, info.rpradiustxt, Set_Value = radstr
    rsz = size(*dataimage)
    minx = xcent - trad > 0.
    maxx = xcent + trad < (rsz[1]-1)
    miny = ycent - trad > 0.
    maxy = ycent + trad < (rsz[2]-1)
    minx = float(round(minx))
    maxx = float(round(maxx))
    miny = float(round(miny))
    maxy = float(round(maxy))
    tmp = ptr_new(bytarr(xsize,ysize))
    (*tmp)[*,*] = 1
    if (*roi).rod eq 1 then begin
      ; generate the rod mask
      (*tmp)[*(*roi).roddmask] = 0
    endif
    if (*roi).msk eq 1 then begin
      tmpmask = (*(*roi).mask)
      xoff = (*roi).msk_xoff
      yoff = (*roi).msk_yoff
      goodval = (*roi).maskgood
      tmpmsk = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
      roimask = congrid(tmpmsk,xsize,ysize)
      bad = where(roimask ne (*roi).maskgood, cnt)
      if cnt gt 0 then (*tmp)[bad] = 0
    endif
    agood = where(alphaim gt 0, agcnt)
    if agcnt eq 0 then begin
      stat = Widget_Message('No data for profile')
      return
    endif
    abad = where(alphaim eq 0, abcnt)
    if abcnt gt 0 then (*tmp)[abad] = 0
    alphaim = 0
    for j = miny,maxy do begin
      for i = minx,maxx do begin
        rr = sqrt((i-xcent)^2+(j-ycent)^2)
        r = round(rr)
        if r le nbins-1 then begin
    	  if ((*tmp)[i,j] eq 1) then begin
	    totalplot[r] = totalplot[r] + (*dataimage)[i,j]
	    tempdat[r,theplotcount(r)] = (*dataimage)[i,j]
	    theplotcount[r] = theplotcount[r] + 1
	  endif else begin
	    nrej[r] = nrej[r] + 1
          endelse
        endif
      endfor
    endfor
    for i = 0, n_elements(totalplot)-1 do begin
      eeplot[i] = total(totalplot[0:i])
    endfor
    domedian = (*roi).rpmm
    if domedian eq 0 then begin
      for i = 0, nbins-1 do begin
        num = theplotcount[i]-1
        if num gt 0 then begin
          results = moment(tempdat[i,0:num])
          stdplot[i] = SQRT(results[1])
        endif else begin
          stdplot[i] = 0.
        endelse
      endfor
      indx = where(theplotcount gt 0,cnt1)
      temp = where(theplotcount le 0,cnt)
      if cnt gt 0 then begin
        if cnt1 gt 0 then begin
          theplot[indx] = totalplot[indx]/theplotcount[indx]
        endif
      endif else begin
        theplot = totalplot/theplotcount
      endelse
    endif else begin
      for i = 0, nbins-1 do begin
        num = theplotcount[i]-1
        if num gt 0 then begin
	  med = median(tempdat[i,0:num], /even)
	  std = sqrt(total((tempdat[i,0:num]-med)^2)/(num-1))
	  theplot[i] = med
	  stdplot[i] = std
        endif else begin
	  theplot[i] = totalplot[i]
	  stdplot[i] = 0.
        endelse
      endfor
    endelse
    if theplotcount[0] eq 0 then begin
      xplot = float(indgen(nbins-1))
      xplot = xplot + 1.0
      xplot = xplot/float(zoom) + 0.5 * (1.0/zoom)
      theplot = theplot[1:nbins-1]
      totalplot = totalplot[1:nbins-1]
      theplotcount = theplotcount[1:nbins-1]
      eeplot = eeplot[1:nbins-1]
      nrej = nrej[1:nbins-1]
      stdplot = stdplot[1:nbins-1]
    endif else begin
      xplot = float(indgen(nbins))
      xplot = xplot/float(zoom) + 0.5 * (1.0/zoom)
    endelse
    if ptr_valid(info.radpx) then ptr_free,info.radpx
    if ptr_valid(info.radpy) then ptr_free,info.radpy
    if ptr_valid(info.radee) then ptr_free,info.radee
    if ptr_valid(info.radnpt) then ptr_free,info.radnpt
    if ptr_valid(info.radrej) then ptr_free,info.radrej
    if ptr_valid(info.radstd) then ptr_free,info.radstd
    info.radpx = ptr_new(xplot)
    info.radpy = ptr_new(theplot)
    info.radee = ptr_new(eeplot)
    info.radnpt = ptr_new(theplotcount)
    info.radrej = ptr_new(nrej)
    info.radstd = ptr_new(stdplot)
    if rprf.ee eq 0 then begin
      yplot = theplot
      yt = 'Intensity'
    endif else begin
      yplot = eeplot
      yt = 'Enc Energy'
    endelse
    if overplot eq 1 then begin
      oplot,xplot,yplot,color=!d.n_colors-1,linestyle=ls
    endif else begin
      if info.plot_xscale eq 1 then xsc = 1 else xsc = 2
      if info.plot_yscale eq 1 then ysc = 1 else ysc = 2
      yr = fltarr(2)
      if info.rp_autoscl eq 1 then begin
        yr[0] = min(yplot)
        yr[1] = max(yplot)
        str1 = strtrim(string(yr[0]),2)
        str2 = strtrim(string(yr[1]),2)
        Widget_Control, info.rpymintxt, Set_Value=str1
        Widget_Control, info.rpymaxtxt, Set_Value=str2
      endif else begin
        Widget_Control, info.rpymintxt, Get_Value=str1
        Widget_Control, info.rpymaxtxt, Get_Value=str2
        yr[0] = float(str1[0])
        yr[1] = float(str2[0])
      endelse
      xmax = max(xplot)
      xr = [0., xmax]
      if rprf.log eq 1 then begin
        plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
          xtitle = 'Radius', ytitle = yt, /ynozero, /ylog, xrange=xr, yrange=yr
      endif else begin
        plot, xplot, yplot, color = !d.n_colors-1, ystyle=ysc, xstyle=xsc, $
            xtitle = 'Radius', ytitle = yt, /ynozero, yrange=yr, xrange=xr 
        if (*info.rprf).ee eq 0 and (*info.roi).rpeplot gt 0 then begin
          if (*info.roi).rpeplot eq 1 then begin 
	    idp3_errbars, xplot, yplot, yerr=stdplot, color=2
          endif else begin
            npts = *info.radnpt
	    fixx = where(npts lt 2, cnt)
	    if cnt gt 0 then npts[fixx] = 2
              seplot = stdplot / sqrt(npts-1)
	      idp3_errbars, xplot, yplot, yerr=seplot, color=2
            endelse
          endif
        endelse 

        if (*info.rprf).ee eq 1 then begin
          eenum = n_elements(eeplot)
          ee90 = eeplot[eenum-1] * 0.9
          eerad = -1
          xdelt = 1.0 / zoom
          for i = 0, eenum-2 do begin
            if eeplot[i] le ee90 and eeplot[i+1] ge ee90 then begin
	      rdelt = ((ee90 - eeplot[i]) / (eeplot[i+1] - eeplot[i]))
	      eerad = xplot[i] + rdelt * xdelt
            endif
          endfor
          if eerad gt 0 then begin
            str = 'RadProf: Radius enclosing 90% of encircled energy (' + $
	          string(ee90) +  '):' + string(eerad)
            idp3_updatetxt, info, str
          endif
        endif
      endelse
      info.rprfline = ls
      Widget_Control,info.idp3Window,Set_UValue=info

      cm = (*info.roi).cmethod
      setcflags, cm, info.doirs, wm, gf, cwm, ifp
      bstring = '                      '
      Widget_Control,info.rprfcrlab,Set_Value = bstring
      Widget_Control, info.rprfcrlab2, Set_Value = bstring
      Widget_Control, info.rprfcrlab3, Set_Value = bstring
      Widget_Control, info.rprfcrlab4, Set_Value = bstring
      Widget_Control, info.rprfcrlab5, Set_Value = bstring
      if (*info.roi).centfit eq 0 then begin
        xc = float(xcent)/zoom + x1
        yc = float(ycent)/zoom + y1
        cstring ='  Profile Center ' + string(format="(f9.3,' ',f9.3)", xc, yc)
        Widget_Control,info.rprfcrlab,Set_Value = cstring 
      endif else begin
        wmx = info.cent.wmx
        wmy = info.cent.wmy
        errwmx = info.cent.errwmx
        errwmy = info.cent.errwmy
        gfx = info.cent.gfx
        gfy = info.cent.gfy
        errgfx = info.cent.errgfx
        errgfy = info.cent.errgfy
        fwhmx = info.cent.fwhmx
        fwhmy = info.cent.fwhmy
        theta = info.cent.theta
        cwmx = info.cent.cwmx
        cwmy = info.cent.cwmy
        errcwmx = info.cent.errcwmx
        errcwmy = info.cent.errcwmy
        if wm eq 1 and gf eq 1 and cwm eq 1 then begin
          cstring =  'Moment Center ' + $
            string(format="(f8.3,' (',e9.3,')  ',f8.3,' (',e9.3,')')", $
	    wmx,errwmx, wmy,errwmy)
          Widget_Control, info.rprfcrlab, Set_Value = cstring 
          cstring =  'Gauss Center  ' + $
            string(format="(f8.3,' (',e9.3,')  ',f8.3,' (',e9.3,')')", $
	    gfx, errgfx, gfy, errgfy)
          Widget_Control, info.rprfcrlab2, Set_Value = cstring
	  errfwhmx = info.cent.errgfwhmx
	  errfwhmy = info.cent.errgfwhmy
	  errtheta = info.cent.errgtheta
	  dstring = 'GFWHM X=' + string(fwhmx, '$(f7.3)') + ' (' + $
		     string(errfwhmx, '$(e9.3)') + ') Y=' + $
		     string(fwhmy, '$(f7.3)') + ' (' + $
		     string(errfwhmy, '$(e9.3)') + ') ' + $
;                     '!7' + string("150b) + '!3' + '=' + $
		     'Theta=' + $
		     string(theta, '$(f8.2)') + ' (' + $
		     string(errtheta, '$(f6.2)') + ')'
;	  xyouts, 0.3, -0.5, dstring, /normal
          Widget_Control, info.rprfcrlab4, Set_Value = dstring
          diffx = wmx - gfx
          diffy = wnt - gfy
          sumdif = sqrt(diffx^2 + diffy^2)
          dstring = 'Difference  X= ' + $
            string(format="(f6.3,' Y= ',f6.3,'  RSX= ',f6.3)",$
            diffx,diffy,sumdif)
          Widget_Control,info.rprfcrlab3,Set_Value = dstring
          cstring =  'Constrain Center ' + $
            string(format="(f8.3,' (',e9.3,')  ',f8.3,' (',e9.3,')')", $
	    cwmx, errcwmx, cwmy, errcwmy)
          Widget_Control, info.rprfcrlab5, Set_Value = cstring 
        endif else begin
          if wm eq 1 then begin
            cstring =  'Moment Center ' + $
              string(format="(f8.3,' (',e9.3,')  ',f8.3,' (',e9.3,')')", $
  	      wmx, errwmx, wmy, errwmy)
            Widget_Control, info.rprfcrlab, Set_Value = cstring 
          endif 
          if gf eq 1 then begin
            cstring =  'Gauss Center  ' + $
              string(format="(f8.3,' (',e9.3,')  ',f8.3,' (',e9.3,')')", $
	      gfx, errgfx, gfy, errgfy)
            Widget_Control, info.rprfcrlab2, Set_Value = cstring
	    errfwhmx = info.cent.errgfwhmx
	    errfwhmy = info.cent.errgfwhmy
	    errtheta = info.cent.errgtheta
	    dstring = 'GFWHM: X=' + string(fwhmx, '$(f7.3)') + ' (' + $
		     string(errfwhmx, '$(e9.3)') + ') Y=' + $
		     string(fwhmy, '$(f7.3)') + ' (' + $
		     string(errfwhmy, '$(e9.3)') + ') ' + $
;                     '!7' + string("150b) + '!3' + ' =' + $
		     'Theta=' + $
		     string(theta, '$(f8.2)') + ' (' + $
		     string(errtheta, '$(f6.2)') + ')'
;	    xyouts, 0.3, -0.5, dstring, /normal
            Widget_Control, info.rprfcrlab4, Set_Value = dstring
	    if wm eq 1 then begin
              diffx = wmx - gfx
              diffy = wmy - gfy
              sumdif = sqrt(diffx^2 + diffy^2)
              dstring = 'Difference  X= ' + $
                string(format="(f6.3,' Y= ',f6.3,'  RSX= ',f6.3)",$
	        diffx,diffy,sumdif)
              Widget_Control,info.rprfcrlab3,Set_Value = dstring
	    endif 
          endif
          if cwm eq 1 then begin
            ; update constrained fit
            cstring =  'Constrain Center ' + $
              string(format="(f8.3,' (',e9.3,')  ',f8.3,' (',e9.3,')')", $
	      cwmx, errcwmx, cwmy, errcwmy)
            Widget_Control, info.rprfcrlab5, Set_Value = cstring 
          endif
        endelse
      endelse

      if (*info.roi).centfit ne 0 and wm eq 1 and gf eq 1 then begin 
        theplotp = fltarr(nbins)
        totalplotp = fltarr(nbins)
        eeplotp = fltarr(nbins)
        theplotcountp = intarr(nbins)
        maxpt = fix(nbins*2*!pi) + 50
        tempdat[*,*] = 0.
        xcentp = (info.cent.gfx - x1) * zoom
        ycentp = (info.cent.gfy - y1) * zoom
        minx = xcentp - trad > 0.
        maxx = xcentp + trad < (rsz[1]-1)
        miny = ycentp - trad > 0
        maxy = ycentp + trad < (rsz[2]-1)
        minx = float(round(minx))
        maxx = float(round(maxx))
        miny = float(round(miny))
        maxy = float(round(maxy))
        for j = miny,maxy do begin
          for i = minx,maxx do begin
            rr = sqrt((i-xcentp)^2+(j-ycentp)^2)
            r = round(rr)
            if r le nbins-1 then begin
              if ((*tmp)[i,j] eq 1) then begin
	        totalplotp[r] = totalplotp[r] + (*dataimage)[i,j]
	        tempdat[r,theplotcountp(r)] = (*dataimage)[i,j]
	        theplotcountp[r] = theplotcountp[r] + 1
	      endif 
            endif
          endfor
        endfor
        for i = 0, n_elements(totalplotp)-1 do begin
          eeplotp[i] = total(totalplotp[0:i])
        endfor
        domedian = (*roi).rpmm
        if domedian eq 0 then begin
          for i = 0, nbins-1 do begin
            num = theplotcountp[i]-1
            if num gt 0 then begin
              results = moment(tempdat[i,0:num])
            endif
          endfor
          indx = where(theplotcountp gt 0,cnt1)
          temp = where(theplotcountp le 0,cnt)
          if cnt gt 0 then begin
            if cnt1 gt 0 then begin
              theplotp[indx] = totalplotp[indx]/theplotcountp[indx]
            endif
          endif else begin
            theplotp = totalplotp/theplotcountp
          endelse
        endif else begin
          for i = 0, nbins-1 do begin
            num = theplotcountp[i]-1
            if num gt 0 then begin
              med = median(tempdat[i,0:num], /even)
	      theplotp[i] = med
            endif else begin
              theplotp[i] = totalplotp[i]
            endelse
          endfor
        endelse
        if theplotcountp[0] eq 0 then begin
          theplotp = theplotp[1:nbins-1]
          totalplotp = totalplotp[1:nbins-1]
          theplotcountp = theplotcountp[1:nbins-1]
          eeplotp = eeplotp[1:nbins-1]
        endif 
        if rprf.ee eq 0 then begin
          yplot = theplotp
        endif else begin
          yplot = eeplotp
        endelse
        if info.color_bits eq 0 then spcl = 200 else spcl = 5
        oplot, xplot, yplot, color = spcl, linestyle=2
      endif
    endif
    ptr_free,dataimage
    tempdat = 0
    alphaim = 0
    theplot = 0
    totalplot = 0
    stdplot = 0
    eeplot = 0
    theplotcount = 0
    nrej = 0
    tmpmask = 0
    roimask = 0
    tmp = 0
    wset, info.drawid1

    Widget_Control, info.idp3rprf, Set_UValue=info
    Widget_Control, info.idp3Window, Set_UValue=info

    if not XRegistered('idp3_radprof') then $
      XManager,'idp3_radprof',idp3rprf,/No_Block,Event_Handler='idp3rprf_event'

end

