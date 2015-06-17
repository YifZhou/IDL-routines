function idp3_scaldisplay, info

  sdispim = *(info.dispim) + info.Dispbias
  if ptr_valid(info.alphaim) then begin
    alpha = *(info.alphaim)
    bad = where(alpha lt 0.5, acount)
    if acount gt 0 then sdispim[bad] = 0.
    alpha = 0
  endif else print, 'invalid pointer'
  dispim = 0

  ; Fiddle the scaling, if scaling hasn't been set or autoscale is on, then
  ; autoscale.  Otherwise, just use the Z1 Z2 values.
  auto = info.autoscale
  if abs(info.Z1) lt 1.0e-9 and abs(info.Z2) lt 1.0e-9 or auto eq 1 then begin
    CASE info.imscl of
      0: Begin  ; linear scaling
        c = imscale(sdispim,10.0)
        z1 = c[0]
        z2 = c[1]
	goodscale = 1
       end
       1: Begin  ; log scaling
	  a = where(sdispim gt 0.0, gcount)
	  b = where(sdispim le 0.0, bcount)
	  if bcount gt 0 then sdispim[b] = 0.01
	  if gcount gt 0 then begin
            sdispim = alog10(sdispim)
	    c = imscale(sdispim[a],10.0)
	    z1 = c[0]
	    z2 = c[1]
	    if bcount gt 0 then sdispim[b] = z1
	    a = 0
	    b = 0
	    goodscale = 1
          endif else begin
	    test = Widget_Message('Data invalid for Log scaling')
	    goodscale = 0
          endelse
        end
	2: Begin    ; square root scaling
	  a = where(sdispim ge 0.0, gcount)
	  b = where(sdispim lt 0.0, bcount)
	  if bcount gt 0 then sdispim[b] = 0.0
	  if gcount gt 0 then begin
            sdispim = sqrt(sdispim)
	    c = imscale(sdispim[a],10.0)
	    z1 = c[0]
	    z2 = c[1]
	    if bcount gt 0 then sdispim[b] = z1
	    a = 0
	    b = 0
	    goodscale = 1
          endif else begin
	    test = Widget_Message('Data invalid for Square Root scaling')
	    goodscale = 0
          endelse
	end
    endcase
    if goodscale eq 1 then begin
      info.Z1 = z1
      info.Z2 = z2
      Widget_Control, info.idp3Window, Set_UValue=info
      if (XRegistered('idp3_adjustdisplay')) then begin
	Widget_Control, info.adBase, Get_UValue = tempadinfo
	Widget_Control, tempadinfo.plotminField, Set_Value = z1
	Widget_Control, tempadinfo.plotmaxField, Set_Value = z2
      endif 
      if (XRegistered('idp3_roidisplay')) then begin
	Widget_Control, info.rdBase, Get_UValue = temprdinfo
	Widget_Control, temprdinfo.plotminField, Set_Value = z1
	Widget_Control, temprdinfo.plotmaxField, Set_Value = z2
	if info.zoomflux eq 0 then begin
	  rz1 = z1
	  rz2 = z2
        endif else begin
          rz1 = z1 / (*info.roi).roizoom
	  rz2 = z2 / (*info.roi).roizoom
        endelse
	Widget_Control, temprdinfo.rplotminField, Set_Value = rz1
	Widget_Control, temprdinfo.rplotmaxField, Set_Value = rz2
      endif
    endif
  endif else begin
    z1 = info.Z1
    z2 = info.Z2
    goodscale = 1
    Case info.imscl of
     0: Begin
	end
     1: Begin
        a = where(sdispim gt 0.0, gcount)
        b = where(sdispim le 0.0, bcount)
        if bcount gt 0 then sdispim[b] = 0.01
        if gcount gt 0 then begin
          sdispim = alog10(sdispim)
          if bcount gt 0 then sdispim[b] = z1
        endif 
	a = 0
	b = 0
        end
     2: Begin
        a = where(sdispim ge 0.0, gcount)
        b = where(sdispim lt 0.0, bcount)
        if bcount gt 0 then sdispim[b] = 0.0
        if gcount gt 0 then begin
	  sdispim = sqrt(sdispim)
	  if bcount gt 0 then sdispim[b] = z1
        endif
	a = 0
	b = 0
        end
     else: 
    endcase
  endelse
  if goodscale eq 0 then sdispim = -1
  return, sdispim
end
