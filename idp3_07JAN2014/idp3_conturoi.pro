pro levs_stat, image, mask, goodpix, nlev, levs

;  Computes statistics for an image then contour levels 
;
; parameters : image  --- array with image
;              mask   --- image mask
;              nlev   --- number of levels
; outputs :    im_min --- min in entire array
;              im_max --- max in entire array         
;              im_sdev--- standard deviation within box
;              im_median- median within box
;              levs   --- levels for contour routine
;
 im_sdev = 0.e0 
 im_min = 0.e0 
 im_max = 0.e0 
 im_median = 0.e0
;
; crudely evaluate statistics by comparing a sub-image w/ a shifted
; version of the subimage (use lower left corner)
;
 box = intarr(4)
 imsz = size(image)
 box[0] = 0
 box[1] = imsz[1] - 2 
 box[2] = 0
 box[3] = imsz[2] - 2 

 sub_image = image(box[0]:box[1],box[2]:box[3])
 sub_image_shift=image(box[0]+1:box[1]+1,box[2]+1:box[3]+1)
 sub_mask = mask(box[0]:box[1],box[2]:box[3])
 sub_mask_shift = mask(box[0]+1:box[1]+1,box[2]+1:box[3]+1)
;
; select only non-zero/good pix and make sure there are the same number in
; each list
;
 jsi = where(sub_mask eq goodpix and sub_mask_shift eq goodpix, count)
 if count gt 0 then begin
   result = moment([sub_image[jsi]-sub_image_shift[jsi]],sdev=im_sdev)
   im_median = median([sub_image[jsi]-sub_image_shift[jsi]], /EVEN)
 endif else begin
   im_sdev = 1.
   im_median = 0.
 endelse

 js = where(mask eq goodpix, cnt)
 im_max = max(image[js]) 
 im_min = min(image[js])

; lev_low = im_median + 2.*im_sdev 
 if (im_max - im_min) le 2.1*im_sdev then im_sdev = 0.
 lev_low = im_min + im_sdev 
 lev_high = im_max - im_sdev
 levs = fltarr(nlev)
 if lev_low lt 0. and alog10(lev_high-lev_low) lt 0. then begin
   lev_low = abs(lev_low)
   lev_high = lev_high + 2.0 * lev_low
 endif
 if lev_low lt 0. then begin
   factor = 10.e0^(alog10(lev_high-lev_low)/(nlev-1))
   factors = factor ^ indgen(nlev)
   levs = lev_low + factors 
   print, 'Min < 0. ', lev_high, lev_low, factor
 endif else begin
   factor = 10.e0^(alog10(lev_high/lev_low)/(nlev-1))
   factors = factor ^ indgen(nlev)
   levs = lev_low * factors
   print, 'Min > 0. ', lev_low, factor
 endelse
end

pro contour_ev, Event

@idp3_errors

  Widget_Control, event.top, Get_UValue=crinfo
  Widget_Control, crinfo.info.idp3Window, Get_UValue=info
  ncolors = info.d_colors - info.color_bits - 1
  roi = *info.roi
  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend
  zoom = roi.roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  z1n = info.z1
  z2n = info.z2
  ztype = info.roiioz
  tiim = idp3_congrid((*info.dispim)[x1:x2,y1:y2], xsize, ysize, $
     zoom, ztype, info.pixorg)
  if info.zoomflux eq 1 then begin
    tiim = tiim / zoom ^ 2
    z1 = z1n / zoom ^ 2
    z2 = z2n / zoom ^ 2
  endif else begin
    z1 = z1n
    z2 = z2n
  endelse
  overlay = info.roicntr_ovly
  logspace = info.roicntr_logs
  pos_color = 3
  neg_color = 2
  no_color = 250

  case event.id of

    crinfo.ovlyButton: begin
      Widget_control, crinfo.ovlyButton, Get_Value = overlay
      if overlay eq 0 then info.roicntr_ovly = 0 else info.roicntr_ovly = 1
      Widget_Control, crinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, crinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      wset, info.roicntrim
      if logspace eq 0 then begin
        levs = fltarr(nlevs)
        delta = (z2 - z1) / float(nlevs-1)
        for i = 0, nlevs-1 do begin
          levs[i] = z1 + float(i) * delta
        endfor
      endif else begin
	iim = (*info.dispim)[x1:x2,y1:y2]
	goodpix = roi.maskgood
	mask = fltarr(x2-x1+1,y2-y1+1)
	mask[*,*] = goodpix - 1
	if roi.msk gt 0 then begin
	  tmask = *(roi.mask)
	  msz = size(tmask)
	  xb = x1 > 0
	  xe = x2 < (msz[1]-1)
	  yb = y1 > 0
	  ye = y2 < (msz[2]-1)
	  xs = xe - xb 
	  ys = ye - yb
	  mask[0:xs,0:ys] = tmask[xb:xe,yb:ye]
        endif else begin
	  mask[*,*] = goodpix
        endelse
	out = where(iim lt z1n or iim gt z2n, count)
	if count gt 0 then mask[out] = goodpix - 1
	levs_stat, iim, mask, goodpix, nlevs, levs
      endelse
      if info.zoomflux eq 1 then levs = levs / zoom^2
      print, levs
      if ptr_valid(info.roicntr_levs) then ptr_free, info.roicntr_levs
      info.roicntr_levs = ptr_new(levs)
      px = [0.1, float(xsize)-0.1]
      py = [0.1, float(ysize)-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits eq 6 then begin
	col = intarr(nlevs)
	col[*] = pos_color
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if overlay eq 1 then begin
        tv, bytscl(tiim, top=ncolors, min=z1, max=z2) + info.color_bits
        contour, tiim, /noerase, levels=levs, xstyle=5, ystyle=5, /device, $
          min_value=z1, max_value=z2, pos=[px[0],py[0],px[1],py[1]], $
          c_linestyle=linstyl, c_colors=col, c_charsize=0.8
      endif else begin
	erase
        contour, tiim, levels=levs, min_value=z1, max_value=z2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col, c_charsize=0.8
      endelse
    end

    crinfo.nlevstxt: begin
      Widget_Control, crinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, crinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      wset, info.roicntrim
      if logspace eq 0 then begin
        levs = fltarr(nlevs)
        delta = (z2 - z1) / float(nlevs-1)
        for i = 0, nlevs-1 do begin
          levs[i] = z1 + float(i) * delta
        endfor
      endif else begin
	iim = (*info.dispim)[x1:x2,y1:y2]
	goodpix = roi.maskgood
	mask = fltarr(x2-x1+1,y2-y1+1)
	mask[*,*] = goodpix - 1
	if roi.msk gt 0 then begin
	  tmask = *(roi.mask)
	  msz = size(tmask)
	  xb = x1 > 0
	  xe = x2 < (msz[1]-1)
	  yb = y1 > 0
	  ye = y2 < (msz[2]-1)
	  xs = xe - xb
	  ys = ye - yb
	  mask[0:xs,0:ys] = tmask[xb:xe,yb:ye]
        endif else begin
	  mask[*,*] = goodpix
        endelse
	out = where(iim lt z1n or iim gt z2n, count)
	if count gt 0 then mask[out] = goodpix - 1
	print, count, z1n, z2n
	levs_stat, iim, mask, goodpix, nlevs, levs
      endelse
      if info.zoomflux eq 1 then levs = levs / zoom^2
      print, levs
      if ptr_valid(info.roicntr_levs) then ptr_free, info.roicntr_levs
      info.roicntr_levs = ptr_new(levs)
      px = [0.1, float(xsize)-0.1]
      py = [0.1, float(ysize)-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits eq 6 then begin
	col = intarr(nlevs)
	col[*] = pos_color
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if overlay eq 1 then begin
        tv, bytscl(tiim, top=ncolors, min=z1, max=z2) + info.color_bits
        contour, tiim, /noerase, levels=levs, xstyle=5, ystyle=5, /device, $
          min_value=z1, max_value=z2, pos=[px[0],py[0],px[1],py[1]],  $
          c_linestyle=linstyl, c_colors=col, c_charsize=0.8
      endif else begin
	erase
        contour, tiim, levels=levs, min_value=z1, max_value=z2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col, c_charsize=0.8
      endelse
    end

    crinfo.loglevButton: begin
      Widget_Control, crinfo.loglevButton, Get_Value = logspace
      if logspace eq 0 then info.roicntr_logs = 0 else info.roicntr_logs = 1
      Widget_Control, crinfo.nlevstxt, Get_Value=nlevsstr
      nlevs = fix(nlevsstr[0]) > 1 < 60
      Widget_Control, crinfo.nlevstxt, Set_Value=strtrim(string(nlevs),2)
      wset, info.roicntrim
      if logspace eq 0 then begin
        levs = fltarr(nlevs)
        delta = (z2 - z1) / float(nlevs-1)
        for i = 0, nlevs-1 do begin
          levs[i] = z1 + float(i) * delta
        endfor
      endif else begin
	iim = (*info.dispim)[x1:x2,y1:y2]
	goodpix = roi.maskgood
	mask = fltarr(x2-x1+1,y2-y1+1)
	mask[*,*] = goodpix - 1
	if roi.msk gt 0 then begin
	  tmask = *(roi.mask)
	  msz = size(tmask)
	  xb = x1 > 0
	  xe = x2 < (msz[1]-1)
	  yb = y1 > 0
	  ye = y2 < (msz[2]-1)
	  xs = xe - xb
	  ys = ye - yb
	  mask[0:xs,0:ys] = tmask[xb:xe,yb:ye]
        endif else begin
	  mask[*,*] = goodpix
        endelse
	out = where(iim lt z1n or iim gt z2n, count)
	if count gt 0 then mask[out] = goodpix - 1
	print, count, z1n, z2n
	levs_stat, iim, mask, goodpix, nlevs, levs
      endelse
      if info.zoomflux eq 1 then levs = levs / zoom^2
      print, levs
      if ptr_valid(info.roicntr_levs) then ptr_free, info.roicntr_levs
      info.roicntr_levs = ptr_new(levs)
      px = [0.1, float(xsize)-0.1]
      py = [0.1, float(ysize)-0.1]
      linstyl = intarr(nlevs)
      linstyl[*] = 0
      neg = where(levs lt 0, count)
      if count gt 0 then linstyl[neg] = 2
      if info.color_bits eq 6 then begin
	col = intarr(nlevs)
	col[*] = pos_color
	if count gt 0 then col[neg] = neg_color
      endif else col = no_color
      if overlay eq 1 then begin
        tv, bytscl(tiim, top=ncolors, min=z1, max=z2) + info.color_bits
        contour, tiim, /noerase, levels=levs, xstyle=5, ystyle=5, /device, $
          min_value=z1, max_value=z2, pos=[px[0],py[0],px[1],py[1]],  $
          c_linestyle=linstyl, c_colors=col, c_charsize=0.8
      endif else begin
	erase
        contour, tiim, levels=levs, min_value=z1, max_value=z2, $
	  pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
	  c_linestyle=linstyl, c_colors=col, c_charsize=0.8
      endelse
    end

    crinfo.doneButton: begin
      Widget_Control, Event.top, /Destroy
      return
    end

    endcase
    Widget_Control, crinfo.info.idp3Window, Set_UValue=info
    Widget_Control, event.top, Set_UValue=crinfo
end

pro idp3_conturoi, Event
@idp3_structs
@idp3_errors

  if XRegistered('idp3_roicntr') then return
  
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  
  ncolors = info.d_colors - info.color_bits - 1
  roi = *info.roi
  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend
  zoom = roi.roizoom
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  z1n = info.z1
  z2n = info.z2
  ztype = info.roiioz
  tiim = idp3_congrid((*info.dispim)[x1:x2,y1:y2], xsize, ysize, $
     zoom, ztype, info.pixorg)
  if info.zoomflux eq 1 then begin
    tiim = tiim / zoom ^ 2
    z1 = z1n / zoom ^ 2
    z2 = z2n / zoom ^ 2
  endif else begin
    z1 = z1n
    z2 = z2n
  endelse
  pos_color = 3
  neg_color = 2
  no_color = 250
  nlevs = 12
  nlevstr = strtrim(string(nlevs),2)

;  if XRegistered('idp3_roicntr') $
;	 then Widget_Control, info.roicntrBase, /Destroy

    roicntr = Widget_Base(group_leader=info.idp3Window, $
       xoffset=info.wpos.rcwp[0], yoffset=info.wpos.rcwp[1], $
       /column,Title='IDP3-ROI Contour Map')
    info.roicntrBase = roicntr
    imbase = Widget_Base(roicntr, /Row)
    roicntrim = Widget_Draw(imbase, xsize=xsize, ysize=ysize,retain=info.retn)
    levbase = Widget_Base(roicntr, /Row)
    nllab = Widget_Label(levbase, Value='Levs:')
    nlevstxt = Widget_Text(levbase, Value = nlevstr, xsize=2, /Edit)
    loglevButton = cw_bgroup(levbase, ['Log Spacing'], row=1, /nonexclusive, $
		 set_value=[info.roicntr_logs])
    ovlyButton = cw_bgroup(levbase, ['Overlay Image'], row=1, /nonexclusive, $
		 set_value=[info.roicntr_ovly])
    prntButton = Widget_Button(levbase, Value='Print', $
		  Event_Pro='idp3_printcontur')
    donebutton = widget_button (levbase, value=' Done ')

    crinfo = {                                     $
	       nlevstxt       :  nlevstxt,         $
	       ovlyButton     :  ovlyButton,       $
	       loglevButton   :  loglevButton,     $
	       doneButton     :  doneButton,       $
	       info           :  info              $
						   }
					  
    Widget_Control, roicntr, Set_UValue = crinfo

    ; Realize the widget onto the screen.
    Widget_Control, roicntr, /Realize
    Widget_Control, roicntrim, Get_Value=roictim
    info.roicntrim = roictim
    Widget_Control,info.idp3Window,Set_UValue=info
    XManager, 'idp3_roicntr', roicntr, /no_Block, $
      Event_Handler='contour_ev'

    wset, info.roicntrim
    overlay = info.roicntr_ovly
    logspace = info.roicntr_logs
    if logspace eq 0 then begin
      levs = fltarr(nlevs)
      delta = (z2 - z1) / float(nlevs-1)
      for i = 0, nlevs-1 do begin
        levs[i] = z1 + float(i) * delta
      endfor
    endif else begin
      iim = (*info.dispim)[x1:x2,y1:y2]
      goodpix = roi.maskgood
      mask = fltarr(x2-x1+1,y2-y1+1)
      mask[*,*] = goodpix - 1
      if roi.msk gt 0 then begin
	tmask = *(roi.mask)
	msz = size(tmask)
	xb = x1 > 0
	xe = x2 < (msz[1]-1)
	yb = y1 > 0
	ye = y2 < (msz[2]-1)
	mask[0:xs,0:ys] = tmask[xb:xe,yb:ye]
      endif else begin
	mask[*,*] = goodpix
      endelse
      out = where(iim lt z1n or iim gt z2n, count)
      if count gt 0 then mask[out] = goodpix - 1
      levs_stat, iim, mask, goodpix, nlevs, levs
    endelse
    if info.zoomflux eq 1 then levs = levs / zoom^2
    print, levs
    if ptr_valid(info.roicntr_levs) then ptr_free, info.roicntr_levs
    info.roicntr_levs = ptr_new(levs)
    Widget_Control,info.idp3Window,Set_UValue=info
    px = [0.1, float(xsize)-0.1]
    py = [0.1, float(ysize)-0.1]
    linstyl = intarr(nlevs)
    linstyl[*] = 0
    neg = where(levs lt 0, count)
    if count gt 0 then linstyl[neg] = 2
    if info.color_bits eq 6 then begin
      col = intarr(nlevs)
      col[*] = pos_color
      if count gt 0 then col[neg] = neg_color
    endif else col = no_color
    if overlay eq 1 then begin
      tv, bytscl(tiim, top=ncolors, min=z1, max=z2) + info.color_bits
      contour, tiim, /noerase, levels=levs, xstyle=5, ystyle=5, /device, $
        pos=[px[0],py[0],px[1],py[1]], min_value=z1, max_value=z2, $ 
        c_linestyle=linstyl, c_colors=col, c_charsize=0.8
    endif else begin
      erase
      contour, tiim, levels=levs, min_value=z1, max_value=z2, $
        pos=[px[0],py[0],px[1],py[1]], /device, xstyle=5, ystyle=5, $
        c_linestyle=linstyl, c_colors=col, c_charsize=0.8
    endelse
end

