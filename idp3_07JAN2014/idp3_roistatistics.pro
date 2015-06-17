pro stats_Done, event
  geo = Widget_Info(event.top, /geometry)
  widget_control, event.top, Get_UValue=statsinfo
  Widget_Control, statsinfo.info.idp3Window, Get_UValue=info
  info.wpos.rswp[0] = geo.xoffset - info.xoffcorr
  info.wpos.rswp[1] = geo.yoffset - info.yoffcorr
  Widget_Control, statsinfo.info.idp3Window, Set_UValue=info
  Widget_Control, event.top, /Destroy
end

pro stats_setbias, event
  Widget_Control, event.top, Get_UValue=statsinfo
  Widget_Control, statsinfo.info.idp3Window, Get_UValue=info
  print, 'Bias: ', statsinfo.roimed
  imbias = -(statsinfo.roimed)
  ref = info.moveimage
  imptr = (*info.images)[ref]
  if (*imptr).vis ne 1 then begin
    str = 'ROIStatistics: Reference image not ON'
    idp3_updatetxt, info, str
    return
  endif
  if XRegistered('idp3_adjustposition') then begin
    Widget_Control, info.imbiasField, Set_Value=imbias
    (*(*info.images)[ref]).bias = imbias
    Widget_Control, statsinfo.info.idp3Window, Set_UValue=info
    idp3_display, info
  endif else begin
    str = 'ROIStatistics: Adjust Position Widget not active'
    idp3_updatetxt, info, str
    return
  endelse
end

pro stats_setflux, event
  Widget_Control, event.top, Get_UValue=statsinfo
  Widget_Control, statsinfo.info.idp3Window, Get_UValue=info
  print, 'Flux:  ', statsinfo.roimed
  imflux = statsinfo.roimed
  ref = info.moveimage
  imptr = (*info.images)[ref]
  if (*imptr).vis ne 1 then begin
    str = 'ROIStatistics: Reference image not ON'
    idp3_updatetxt, info, str
    return
  endif
  if XRegistered('idp3_adjustposition') then begin
    Widget_Control, info.imscaleField, Set_Value=imflux
    (*(*info.images)[ref]).scl = imflux
    Widget_Control, statsinfo.info.idp3Window, Set_UValue=info
    idp3_display, info
  endif else begin
    str = 'ROIStatistics: Adjust Position Widget not active'
    idp3_updatetxt, info, str
    return
  endelse
end

pro stats_browse, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=statsinfo
  Widget_Control, statsinfo.info.idp3Window, Get_UValue=info

  filename  = dialog_pickfile(title='Pick output path/filename')
  Widget_Control, statsinfo.fileField, Set_Value = filename

end

pro stats_save, event
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=statsinfo
  Widget_Control, statsinfo.info.idp3Window, Get_UValue=info

  Widget_Control, statsinfo.fileField, Get_Value = filename
  filename = strtrim(filename[0],2)
  ua_decompose, filename, disk, path, name, extn, vers
  sextn = strlowcase(extn)
  if strlen(sextn) gt 4 then sextn = strmid(sextn, 0, 4)
  if sextn eq '.fit' or sextn eq '.hdf' then begin
    str = 'Improper extension for statistics file!'
    stat = Widget_Message(str)
    return
  endif
  if strlen(extn) eq 0 then begin
    filename = filename + '.txt'
    Widget_Control, statsinfo.fileField, Set_Value = filename
  endif
  info.statofile = filename
  refnam = (*(*info.images)[info.moveimage]).name
  ua_decompose, refnam, rdisk, rpath, rname, rextn, rvers
  x1 = (*info.roi).roixorig
  x2 = (*info.roi).roixend
  y1 = (*info.roi).roiyorig
  y2 = (*info.roi).roiyend

  labstr = '      Mean          Variance    SD ERR (Pixel)   ' + $
     'SD ERR (Mean)        Total            Min            Max           ' + $
     'Median      No. Pixels  File/Region'
  labstr = info.header_char + labstr
  temp = file_search(filename, Count = fcount)
  if fcount eq 0 then begin
    openw, lun, filename, /get_lun, width = 170
    printf, lun, labstr
  endif else openw, lun, filename, /get_lun, /append
  meanstr = string(statsinfo.c[0], '$(g14.6)')
  varstr = string(statsinfo.c[1], '$(g14.6)')
  sdmstr = string(sqrt(statsinfo.c[1]), '$(g14.6)')
  sdpstr = string(SQRT(statsinfo.c[1])/SQRT(statsinfo.cnt), '$(g14.6)')
  totstr = string(statsinfo.tot, '$(g16.8)')
  minstr = string(statsinfo.roimin, '$(g14.6)')
  maxstr = string(statsinfo.roimax, '$(g14.6)')
  medstr = string(statsinfo.roimed, '$(g14.6)')
  cntstr = string(statsinfo.cnt, '$(i8)')
  namstr = rname + '[' + strtrim(string(x1),2) + ':' + strtrim(string(x2),2) $
	   + ',' + strtrim(string(y1),2) + ':' + strtrim(string(y2),2) + ']'
  b2 = '  '
  bigstr = meanstr + b2 + varstr + b2 + sdmstr + b2 + sdpstr + b2 + $
	   totstr + b2 + minstr + b2 + maxstr + b2 + medstr + b2 + cntstr $
	   + '   ' + namstr
  printf, lun, bigstr
  close, lun
  free_lun, lun

  Widget_Control, statsinfo.info.idp3Window, Set_UValue = info
  Widget_Control, event.top, Set_UValue = statsinfo
end

pro roiStats_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=statsinfo
  Widget_Control, statsinfo.info.idp3Window, Get_UValue=tempinfo
  statsinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=statsinfo

end

pro Idp3_roiStatistics, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_roistatistics')) then return
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  ; Pop up a little widget, calculate statistics on the ROI data and display.
  roistatsWindow = Widget_base(Title = 'IDP3-ROI Stats', /Column, $
			       Group_Leader = info.idp3Window, $
			       XOffset = info.wpos.rswp[0], $
			       YOffset = info.wpos.rswp[1])

  info.roistats = roistatsWindow
  Widget_Control,tinfo.idp3Window,Set_UValue=info

  ofile = info.statofile
  roi = *info.roi

  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend
  tim = ptr_new((*info.dispim)[x1:x2,y1:y2])
  alphaim = (*info.alphaim)[x1:x2,y1:y2]
  tmp = bytarr(x2-x1+1, y2-y1+1)
  tmp[*,*] = 1
  cnt = 0

  if roi.rod eq 1 then begin
    c = moment((*tim)[*(*info.roi).rodmask])
    tot = total((*tim)[*(*info.roi).rodmask])
    roimin = min((*tim)[*(*info.roi).rodmask])
    roimax = max((*tim)[*(*info.roi).rodmask])
    cnt = total((*info.roi).rodmask)
    ptr_free,tim
  endif else begin
    if roi.msk eq 1 then begin
      tmpmask = (*roi.mask)
      xoff = roi.msk_xoff
      yoff = roi.msk_yoff
      goodval = roi.maskgood
      roimask = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
      bad = where(roimask ne roi.maskgood, bcnt)
      if bcnt gt 0 then tmp[bad] = 0
    endif
    abad = where(alphaim eq 0, acnt)
    if acnt gt 0 then tmp[abad] = 0
    alphaim = 0
    if info.exclude_invalid eq 1 then begin
      ebad = where((*tim) eq info.invalid, ecnt)
      if ecnt gt 0 then begin
	tmp[ebad] = 0
      endif
    endif
    good = where(tmp ne 0, cnt)
    if cnt gt 0 then begin
      c = moment((*tim)[good])
      tot = total((*tim)[good])
      roimin = min((*tim)[good])
      roimax = max((*tim)[good])
      roimed = median((*tim)[good], /even)
      ua_decompose, (*info.roi).maskname, disk, path, name, extn, version
      roimsk = name + extn
    endif else begin
      str = 'ROIStatistics: No good data'
      idp3_updatetxt, info, str
      c = fltarr(2)
      c[*] = 0.
      tot = 0.
      roimin = 0.
      roimax = 0.
      roimed = 0.
    endelse
  endelse

  resbase = Widget_Base(roistatsWindow, /Column, /Frame)
  meanstr = '            Mean:' + string(c[0], '$(g14.6)')
  varstr = '        Variance:' + string(c[1], '$(g14.6)')
  sdmstr = '  SD ERR (Pixel):' + string(sqrt(c[1]), '$(g14.6)')
  sdpstr = '   SD ERR (Mean):' + string(SQRT(c[1])/SQRT(cnt), '$(g14.6)')
  totstr = '           Total:' + string(tot, '$(g16.8)')
  minstr = '             Min:' + string(roimin, '$(g14.6)')
  maxstr = '             Max:' + string(roimax, '$(g14.6)')
  medstr = '          Median:' + string(roimed, '$(g14.6)')
  cntstr = 'Number of Pixels:' + string(cnt, '$(i8)')
  if roi.msk gt 0 then begin
    namstr = '     Mask Name: ' + roimsk
  endif
  meanlab = Widget_Label(resbase, Value = meanstr)
  varlab = Widget_Label(resbase, Value = varstr)
  sdmlab = Widget_Label(resbase, Value = sdmstr)
  sdplab = Widget_Label(resbase, Value = sdpstr)
  totlab = Widget_Label(resbase, Value = totstr)
  minlab = Widget_Label(resbase, Value = minstr)
  maxlab = Widget_Label(resbase, Value = maxstr)
  medlab = Widget_Label(resbase, Value = medstr)
  cntlab = Widget_Label(resbase, Value = cntstr)
  if n_elements(namstr) gt 0 then msklab = Widget_Label(resbase, Value=namstr)
  fileField = CW_Field(roistatsWindow, Title='File:', xsize=32, $
		       value=ofile, /return_events, /string)
  buttonbase = Widget_Base(roistatsWindow, /Row)
  biasbutton = Widget_Button(buttonbase, Value='Set Image Bias', $
		 Event_Pro='stats_setbias', /align_center)
  fluxbutton = Widget_Button(buttonbase, Value='Set Image Flux', $
                 Event_Pro = 'stats_setflux', /align_center)
  button1base =Widget_Base(roistatsWindow, /Row)
  browsebutton = Widget_Button(button1base, Value='Browse', Event_Pro = $
		 'stats_browse')
  savebutton = Widget_Button(button1base, Value = 'Save', Event_Pro = $
		 'stats_save')
  doneButton= Widget_Button(button1base,Value='Done',Event_Pro='stats_Done')

  statsinfo = {doneButton   : doneButton,     $
	       fileField    : fileField,      $
	       c            : c,              $
	       tot          : tot,            $
	       roimin       : roimin,         $
	       roimax       : roimax,         $
	       roimed       : roimed,         $
	       cnt          : cnt,            $
	       info         : info            } 

  Widget_Control, roistatsWindow, Set_UValue=statsinfo

  Widget_Control, roistatsWindow, /Realize
  XManager, 'idp3_roistatistics', roistatsWindow, /No_Block, $
            Event_Handler='roiStats_Event'
end

