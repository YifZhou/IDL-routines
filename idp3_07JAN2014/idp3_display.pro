; IDP3_Display -- Display the images based on the data structures.

pro Idp3_Display, info

@idp3_structs
@idp3_errors
  ; Get current size of the draw field.
  dxs = info.drawxsize
  dys = info.drawysize

  c = size(*info.images)                       ; How many images?
  if (c[0] eq 0 and c[1] eq 2) then begin      ; Nothing to display
    ; Clear the display in case the user just deleted the last image.
    ptr_free, info.dispim
    ptr_free, info.alphaim
    dispim = ptr_new(fltarr(dxs,dys))   ; An empty display array
;    alphaim = ptr_new(fltarr(dxs,dys))   ; An empty display array
    info.sxoff = 0
    info.syoff = 0
    tv, *dispim
    return
  endif

  numimages = n_elements(*info.images)
  wset, info.drawid1

  ; Figure out how big the display image must be.
  ; This depends on the sizes of the loaded images and their offsets.
  maxx = 0
  maxy = 0
  numon = 0
  for i = 0, numimages-1 do begin
    m = (*info.images)[i]    ; m is a pointer to this image structure
    if (*m).vis eq 1 then begin
      x2 = ((*m).xsiz + 2 * (*m).pad) * (*m).xpscl * (*m).zoom + (*m).xoff 
      y2 = ((*m).ysiz + 2 * (*m).pad) * (*m).ypscl * (*m).zoom + (*m).yoff
      if x2 gt maxx then maxx = x2
      if y2 gt maxy then maxy = y2
      numon = numon + 1
    endif
  endfor
  if numon eq 0 then begin
    erase
    return
  endif


  maxx = maxx + info.sxoff
  maxy = maxy + info.syoff
  info.maxxpoint = maxx
  info.maxypoint = maxy
  if maxx lt dxs then maxx = dxs
  if maxy lt dys then maxy = dys
  info.dispx = maxx
  info.dispy = maxy

  ; Start from scratch.
  ; Free the pointer to the current display image.
  ptr_free, info.dispim
  dispim = ptr_new(fltarr(maxx,maxy))   ; An empty display array
  ptr_free, info.alphaim
  alphaim = ptr_new(fltarr(maxx,maxy))   ; An empty display array
  numon = 0
  for i = 0, numimages-1 do begin
    ; Display this image
    m = (*info.images)[i]    ; m is a pointer to this image structure
    
    if (*m).vis eq 1 then begin      ; if the image is visible then...

      ; Keep track of how many images are on.
      numon = numon + 1

      mdst = idp3_setdata(info, i)
      mds = mdst[*,*,0]
      alpha = mdst[*,*,1]

      ; zero masked pixels
      zz = where(alpha eq 0, zzcnt)
      if zzcnt gt 0 then begin
	mds[zz] = 0.
	zz = 0
      endif
      ;
      ; Determine where this image should be in the display.
      ; check offsets, check boundaries, etc.
      xoff = (*m).xoff + info.sxoff
      yoff = (*m).yoff + info.syoff
      xsiz = ((*m).xsiz + 2 * (*m).pad) * (*m).zoom * (*m).xpscl 
      ysiz = ((*m).ysiz + 2 * (*m).pad) * (*m).zoom * (*m).ypscl
      idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax,dymin,dymax, $
      		       gxmin,gxmax,gymin,gymax,err
      ; Include the image in the display.
      ; add, sub, div, inv, etc.
      z1 = (*m).z1
      z2 = (*m).z2
      mdsz = size(mds)
      outbound = 0
      if err eq -1 then begin
	test = widget_message(' X offset out of bounds')
	outbound = 1
      endif
      if err eq -2 then begin
	test = widget_message(' Y offset out of bounds')
	outbound = 1
      endif
      if outbound eq 0 then begin
        if dxmin lt 0 or dxmax gt mdsz[1] then begin
	  test = widget_message(' Image out of bounds in x')
	  outbound=1
        endif
        if dymin lt 0 or dymax gt mdsz[2] then begin
	  test = widget_message(' Image out of bounds in y')
          outbound=1
        endif
      endif
      if outbound eq 0 then begin
      case (*m).dispf of
	ADD: begin
	  (*dispim)[gxmin:gxmax,gymin:gymax] = $
		       (*dispim)[gxmin:gxmax,gymin:gymax] + $
		             mds[dxmin:dxmax,dymin:dymax]
          (*alphaim)[gxmin:gxmax,gymin:gymax] = $
		       (*alphaim)[gxmin:gxmax,gymin:gymax] + $
			     alpha[dxmin:dxmax,dymin:dymax]
	  end

	MUL: begin
	  if numon gt 1 then begin
	    (*dispim)[gxmin:gxmax,gymin:gymax] = $
		       (*dispim)[gxmin:gxmax,gymin:gymax] * $
		             mds[dxmin:dxmax,dymin:dymax]
            (*alphaim)[gxmin:gxmax,gymin:gymax] = $
		       (*alphaim)[gxmin:gxmax,gymin:gymax] * $
			     alpha[dxmin:dxmax,dymin:dymax]
          endif else begin
	    (*dispim)[gxmin:gxmax,gymin:gymax] = $
		       mds[dxmin:dxmax,dymin:dymax]
            (*alphaim)[gxmin:gxmax,gymin:gymax] = $
		       alpha[dxmin:dxmax,dymin:dymax]
          endelse
	  end

	SUB: begin
	  (*dispim)[gxmin:gxmax,gymin:gymax] = $
		       (*dispim)[gxmin:gxmax,gymin:gymax] - $
			     mds[dxmin:dxmax,dymin:dymax]
          (*alphaim)[gxmin:gxmax,gymin:gymax] = $
		       (*alphaim)[gxmin:gxmax,gymin:gymax] + $
			     alpha[dxmin:dxmax,dymin:dymax]
	  end

	AVE: begin
	  dim = (*dispim)[gxmin:gxmax,gymin:gymax]
	  dalpha = (*alphaim)[gxmin:gxmax,gymin:gymax]
	  dim = dim * dalpha + mds[dxmin:dxmax,dymin:dymax]
	  dalpha = dalpha + alpha[dxmin:dxmax,dymin:dymax]
	  good = where(dalpha gt 0., count)
	  if count gt 0. then dim[good] = dim[good]/dalpha[good]
	  (*dispim)[gxmin:gxmax,gymin:gymax] = dim
	  (*alphaim)[gxmin:gxmax,gymin:gymax] = dalpha
	  dim = 0
	  dalpha = 0
	  good = 0
	  end

	MIN: begin
	  if numon gt 1 then begin
	    tmp = (*dispim)[gxmin:gxmax,gymin:gymax] < $
	       mds[dxmin:dxmax,dymin:dymax]
            tmpa = (*alphaim)[gxmin:gxmax,gymin:gymax] > $
	       alpha[dxmin:dxmax,dymin:dymax]
	    (*dispim)[gxmin:gxmax,gymin:gymax] = tmp
	    (*alphaim)[gxmin:gxmax,gymin:gymax] = tmpa
	    tmp = 0
	    tmpa = 0
          endif else begin
	    (*dispim)[gxmin:gxmax,gymin:gymax] = mds[dxmin:dxmax,dymin:dymax]
	    (*alphaim)[gxmin:gxmax,gymin:gymax] = alpha[dxmin:dxmax,dymin:dymax]
          endelse
	  end

	POS: begin
	  tmp = mds[dxmin:dxmax,dymin:dymax] 
	  xtmp = where(tmp ge 0., count)
	  if count gt 0 then begin
	    tmpsz = size(tmp)
	    ytmp = fltarr(tmpsz[1],tmpsz[2])
	    ytmp[*,*] = 0.
	    ytmp[xtmp] = tmp[xtmp]
	    atmp = fltarr(tmpsz[1],tmpsz[2])
	    atmp[*,*] = 0.
	    atmp[xtmp] = 1.
	    str = 'Display: ' + string(count) + ' positive pixels found'
	    idp3_updatetxt, info, str
	    (*dispim)[gxmin:gxmax,gymin:gymax] = $
	       (*dispim)[gxmin:gxmax,gymin:gymax] + ytmp
            (*alphaim)[gxmin:gxmax,gymin:gymax] = $
	       (*alphaim)[gxmin:gxmax,gymin:gymax] + atmp
            tmp = 0
	    xtmp = 0
            ytmp = 0
	    atmp = 0
          endif else begin
	    str = 'Display: No positive pixels found'
	    idp3_updatetxt, info, str
          endelse
	  end

	NEG: begin
	  tmp = mds[dxmin:dxmax,dymin:dymax] 
	  xtmp = where(tmp lt 0., count)
	  if count gt 0 then begin
	    tmpsz = size(tmp)
	    ytmp = fltarr(tmpsz[1],tmpsz[2])
	    ytmp[*,*] = 0.
	    ytmp[xtmp] = abs(tmp[xtmp])
	    atmp = fltarr(tmpsz[1],tmpsz[2])
	    atmp[*,*] = 0.
	    atmp[xtmp] = 1.
	    str = 'Display: ' + string(count) + ' negative pixels found'
	    idp3_updatetxt, info, str
	    (*dispim)[gxmin:gxmax,gymin:gymax] = $
	       (*dispim)[gxmin:gxmax,gymin:gymax] + ytmp
            (*alphaim)[gxmin:gxmax,gymin:gymax] = $
	       (*alphaim)[gxmin:gxmax,gymin:gymax] + atmp
            tmp = 0
	    xtmp = 0
	    ytmp = 0
	    atmp = 0
          endif else begin
	    str = 'Display: No negative pixels found'
	    idp3_updatetxt, info, str
          endelse
	  end

	ABS: begin
	  tmp = mds[dxmin:dxmax,dymin:dymax] 
	  xtmp = where(tmp lt 0., count)
	  if count gt 0 then begin
	    ytmp = tmp
	    ytmp[xtmp] = abs(tmp[xtmp])
	    str = 'Display: ' + string(count) + ' negative pixels found'
	    idp3_updatetxt, info, str
          endif else begin
	    str = 'Display: No negative pixels found'
	    idp3_updatetxt, info, str
          endelse
	  (*dispim)[gxmin:gxmax,gymin:gymax] = $
	       (*dispim)[gxmin:gxmax,gymin:gymax] + ytmp
          (*alphaim)[gxmin:gxmax,gymin:gymax] = $
	       (*alphaim)[gxmin:gxmax,gymin:gymax] + $
			     alpha[dxmin:dxmax,dymin:dymax]
          tmp=0
	  xtmp = 0
	  ytmp = 0
	  end

	DIV: begin
	  ; Avoid divide by zero.
	  tmpmds = mds[dxmin:dxmax,dymin:dymax]
	  tmpdpm = (*dispim)[gxmin:gxmax,gymin:gymax]
	  tmpalp = alpha[dxmin:dxmax,dymin:dymax]
	  id = where(tmpmds ne 0.0 and tmpalp ne 0.0,tcnt)
	  if (tcnt gt 0) then begin
	    tmpdpm[id] = tmpdpm[id] / tmpmds[id]
	  endif else begin
	    tmpdpm[*,*] = 0.
	  endelse
	  (*dispim)[gxmin:gxmax,gymin:gymax] = tmpdpm
	  tmpmds = 0
	  tmpdpm = 0
	  tmpalp = 0
	  end
	
	INV: begin
	  ; Avoid divide by zero.
	  tmpmds = mds[dxmin:dxmax,dymin:dymax]
	  tmpalp = alpha[dxmin:dxmax,dymin:dymax]
	  tmpdat = tmpmds * 0.
	  id = where(tmpmds ne 0.0 and tmpalp ne 0.0,tcnt)
	  if (tcnt gt 0) then begin
	    tmpdat[id] = 1.0 / tmpmds[id]
	  endif else begin
	    tmpdat[*,*] = 0.
	  endelse
	  (*dispim)[gxmin:gxmax,gymin:gymax] = $
	    (*dispim)[gxmin:gxmax,gymin:gymax] + tmpdat
          (*alphaim)[gxmin:gxmax,gymin:gymax] = $
                       (*alphaim)[gxmin:gxmax,gymin:gymax] + $
                             alpha[dxmin:dxmax,dymin:dymax]
	  tmpmds = 0
	  tmpdat = 0
	  tmpalp = 0
	  end

	MAG: begin
	  ; Avoid logs of numbers le 0 
          ; constant alog10(2.5118865)
          magf = alog10(2.5118865)
	  tmpmds = mds[dxmin:dxmax,dymin:dymax]
	  tmpalp = alpha[dxmin:dxmax,dymin:dymax]
	  tmpdat = tmpmds * 0.
	  id = where(tmpmds gt 0.0 and tmpalp ne 0.0,tcnt)
	  if tcnt gt 0 then begin
	    tmpdat[id] = alog10(tmpmds[id]) / magf
            nid = where(tmpmds le 0.0 or tmpalp eq 0.0, bcnt)
            if bcnt gt 0 then tmpdat[nid] = info.invalid
	  endif else begin
	    tmpdat[*,*] = 0.
	  endelse
	  (*dispim)[gxmin:gxmax,gymin:gymax] = $
	    (*dispim)[gxmin:gxmax,gymin:gymax] + tmpdat
	  tmpmds = 0
	  tmpdat = 0
	  tmpalp = 0
	  end

      endcase
      endif
    endif
  endfor

  mdst = 0
  mds = 0
  alpha = 0

  ; Display the data.

  numdisp = numon 
  if numdisp gt 0 then begin
    info.dispim = dispim
    info.alphaim = alphaim
    sdispim = idp3_scaldisplay(info)
    if n_elements(sdispim) eq 1 then numdisp = 0
  endif
  bits = info.color_bits
  if numdisp eq 0 then begin
    erase
  endif else begin
    notnan = finite(sdispim)
    bad = where(notnan eq 0, count)
    if count gt 0 then sdispim[bad] = 0.
    tv, bytscl(sdispim,top=info.d_colors-bits-1,min=info.z1, max=info.z2)+bits
    notnan = 0
    bad = 0
    sdispim = 0
    idp3_orientv, info, 'main'

    info.alphaim = alphaim
    Widget_Control,info.idp3Window,Set_UValue=info

    ; if the Catalog window is up, redraw circles and check for id
    if XRegistered('idp3_catalog') then begin
      if info.catalog.entries gt 0 then begin
        xloc = round(*info.catalog.xpos)
        yloc = round(*info.catalog.ypos)
        minshift = info.catminred
        maxshift = info.catmaxred
        redshift = *info.catalog.zpf > minshift < maxshift
        catid = info.catid
        if catid gt 0 and info.catalog.entries ge catid then begin
	  id = round(*info.catalog.id)
	  loc = where(catid eq id, count)
	  if count gt 0 then begin
	    xx = xloc[loc]
	    yy = yloc[loc]
	    if xx lt info.drawxsize and yy lt info.drawysize then $
	      xyouts, xx, yy, '+', /device, color=yellow, alignment=0.5, $
	         charsize=3.0
          endif
        endif
        xp = info.catposx
        yp = info.catposy
        if xp gt 0 and xp lt info.drawxsize and yp gt 0 and $
	  yp lt info.drawysize then $
          xyouts, xp, yp, '+', /device,color=blue, alignment=0.5,charsize=3.0
        if info.catdisp eq 1 or info.catdisp eq 3 then begin
  	  ncolor=info.color_bits
	  th=fltarr(361)
	  for i=0,360 do th(i)=float(i)*(!pi/180.)
	  rad = info.catradius
	  shift_range = maxshift-minshift
	  fcolor = float(ncolor-1)
          for i = 0, info.catalog.entries-1 do begin
	    ctemp = fix(((redshift[i]-minshift) / shift_range) * fcolor + 0.5)
	    xx = xloc[i]
	    yy = yloc[i]
	    xx = xx < info.drawxsize
	    yy = yy < info.drawysize
	    if xx lt info.drawxsize and yy lt info.drawysize then $
	      plots, rad*cos(th) + xx, rad*sin(th) + yy, color=ctemp, /device
          endfor
        endif
        if info.catdisp eq 2 or info.catdisp eq 3 then begin
	  for i = 0, info.catalog.entries-1 do begin
	    id = *info.catalog.id
	    xx = xloc[i]
	    yy = yloc[i]
	    str = strtrim(string(round(id[i])),2)
	    if xx lt info.drawxsize and yy lt info.drawysize then $
	      xyouts, xx, yy, str, /device, color=green
          endfor
        endif
        xloc = 0
        yloc = 0
      endif
    endif
    
    ; If the ROI window is up, redraw the box and then update the ROI window.
    if (XRegistered('idp3_roi')) then begin
      ; Draw the roi box.
      roi = *info.roi
      if roi.tempxbox gt roi.boxx0 then begin
        x1 = roi.boxx0
        x2 = roi.tempxbox
      endif else begin
        x2 = roi.boxx0
        x1 = roi.tempxbox
      endelse
      if roi.tempybox gt roi.boxy0 then begin
        y1 = roi.boxy0
        y2 = roi.tempybox
      endif else begin
        y2 = roi.boxy0
        y1 = roi.tempybox
      endelse
      if x2 gt dxs or y2 gt dys then begin
	stat = Widget_Message('Cannot build ROI, larger than Main Display')
	return
      endif
      roi_color = info.color_roi
      if roi_color lt 0 then roi_color = 200
      roixsize = (abs(x1-x2)+1) * roi.roizoom
      roiysize = (abs(y1-y2)+1) * roi.roizoom
      (*info.roi).roixsize = roixsize
      (*info.roi).roiysize = roiysize
      (*info.roi).roixorig = x1 
      (*info.roi).roiyorig = y1
      (*info.roi).roixend = x2 
      (*info.roi).roiyend = y2
      plots, x1, y1, color=roi_color, /device
      plots, x1, y2, color=roi_color, /device, /continue 
      plots, x2, y2, color=roi_color, /device, /continue
      plots, x2, y1, color=roi_color, /device, /continue
      plots, x1, y1, color=roi_color, /device, /continue
      ; Update the contents
      roi_Display,info
    endif
  endelse
end

