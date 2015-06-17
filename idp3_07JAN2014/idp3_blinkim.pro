; IDP3_Blinkim -- Blink the images based on the data structures.

pro Idp3_Blinkim, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info

  ; Get current size of the draw field.
  dxs = info.drawxsize
  dys = info.drawysize

  numimages = n_elements(*info.images)
  numon = 0
  onim = -1
  for i = 0, numimages-1 do begin
    m = (*info.images)[i] 
    if (*m).vis eq 1 then begin
      numon = numon + 1
      if onim[0] lt 0 then onim = i else onim = [onim, i]
    endif
  endfor
  if numimages lt 2 or numon lt 2 then info.bcount = -1

  if info.bcount ge 0 and info.bcount le info.btimes-1 then begin
    wset, info.drawid1

    ; Figure out how big the display image must be.
    ; This depends on the sizes of the loaded images and their offsets.
    maxx = 0
    maxy = 0
    icount = 0
    for i = 0, numimages-1 do begin
      m = (*info.images)[i]    ; m is a pointer to this image structure
      if (*m).vis eq 1 and ((*m).dispf eq ADD or (*m).dispf eq SUB) then begin
        x2 = ((*m).xsiz + 2 * (*m).pad) * (*m).xpscl * (*m).zoom + (*m).xoff 
        y2 = ((*m).ysiz + 2 * (*m).pad) * (*m).ypscl * (*m).zoom + (*m).yoff
        if x2 gt maxx then maxx = x2
        if y2 gt maxy then maxy = y2
	icount = icount + 1
      endif
    endfor

    maxx = maxx + info.sxoff
    maxy = maxy + info.syoff
    info.maxxpoint = maxx
    info.maxypoint = maxy
    if maxx lt dxs then maxx = dxs
    if maxy lt dys then maxy = dys
    info.dispx = maxx
    info.dispy = maxy

    if info.bimcount ge 0 and info.bimcount le icount then begin
      ; Display this image
      inum = onim[info.bimcount]
      m = (*info.images)[inum]    ; m is a pointer to this image structure
      ; if the image is visible then...
      if (*m).vis eq 1 and ((*m).dispf eq ADD or (*m).dispf eq SUB) then begin
        ; Keep track of how many images are on.
        numon = numon + 1
        ; Start from scratch.
        ; Free the pointer to the current display image.
        ptr_free,info.dispim
        dispim = fltarr(maxx,maxy)   ; An empty display array
        mdst = idp3_setdata(info, inum)
	mds = mdst[*,*,0]
        ; Determine where this image should be in the display.
        ; check offsets, check boundaries, etc.
        xoff = (*m).xoff + info.sxoff
        yoff = (*m).yoff + info.syoff
        xsiz = ((*m).xsiz + 2 * (*m).pad) * (*m).zoom * (*m).xpscl 
        ysiz = ((*m).ysiz + 2 * (*m).pad) * (*m).zoom * (*m).ypscl
        idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax, $
      	    dymin,dymax,gxmin,gxmax,gymin,gymax,err
        ; blink the image in the display.
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
          dispim[gxmin:gxmax,gymin:gymax] = mds[dxmin:dxmax,dymin:dymax]
	  mds = 0
          info.dispim = ptr_new(dispim)
	  sdispim = idp3_scaldisplay(info)
	  bits = info.color_bits
	  temp = bytscl(sdispim, top=info.d_colors-bits-1, min=info.z1,$
		 max=info.z2) + bits
	  tv, temp
	  temp = 0
	  str = 'Image ' + string(inum,'$(i3)') + '   Iteration ' + $
	    string(info.bcount,'$(i3)')
          xyouts, 100, info.drawysize-25, str, /device
	  if (XRegistered('idp3_roi')) then begin
	    Widget_Control,info.idp3Window,Set_UValue=info
	    roi_Display, info, /roi_blink
          endif
        endif
        dispim = 0
        sdispim = 0
        info.bimcount = info.bimcount + 1
        wait, info.fdelay
        Widget_Control, info.gbase, TIMER = info.fdelay
      endif
      if info.bimcount eq icount then begin
        wait, info.sdelay
        info.bcount = info.bcount + 1
        info.bimcount = 0
      endif
    endif
  endif else begin
    if numon gt 0 then idp3_display, info
  endelse
  Widget_Control, info.idp3Window, Set_UValue = info
end

