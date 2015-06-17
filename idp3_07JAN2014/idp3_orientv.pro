pro idp3_orientv, info, wdisplay    

    moveim = *(*info.images)[info.moveimage]
    if moveim.vis eq 1 then begin
      orient = idp3_getorient(moveim)
      if orient gt -990 then begin
	name = moveim.name
	if info.sip eq 0 then begin
	  ua_decompose, name, disk, path, nname, extn, version
	  name = nname + extn
        endif
        szn = 25.0 
        sze = 20.0 
	iscl = 1.
	if orient gt 360. then an = orient - 360. else an = orient
        if orient lt 0. then an  = orient + 360. else an = orient
        conv = !pi / 180.
        sinan = sin(an * conv)
        cosan = cos(an * conv)
        if moveim.flipy eq 0 then ae = an + 270. else ae = an - 270.
        if (ae LT 0.) then ae = ae + 360.
        if (ae GT 360.) then ae = ae - 360.
        sinae = sin(ae * conv)
        cosae = cos(ae * conv)
	xdn = szn * iscl * sinan
	ydn = szn * iscl * cosan
	xde = sze * iscl * sinae
	yde = sze * iscl * cosae
        if wdisplay eq 'main' then begin
	  xincpt = info.drawxsize
	  yincpt = info.drawysize
        endif else begin
          xincpt = (*info.roi).roixsize
          yincpt = (*info.roi).roiysize
        endelse
	if xde lt 0 then xincpt=xincpt-25 else xincpt=xincpt-40 
	if ydn lt 0 then yincpt=yincpt-25 else yincpt=yincpt-40 
        xan = xdn + xincpt
        yan = ydn + yincpt
        xae = xde + xincpt
        yae = yde + yincpt
	if info.color_orient le 0 then ocolor = 200 $
	   else ocolor = info.color_orient
        plots, xincpt, yincpt, color=ocolor, /device
        plots, xan, yan, color=ocolor, /device, /continue
        plots, xincpt, yincpt, color=ocolor, /device
        plots, xae, yae, color=ocolor, /device, /continue
  	xap = xan+2
	if (yan LT yincpt) then yap = yan-10 else yap=yan+3
	xyouts, xap, yap, 'N', /device
        if wdisplay eq 'main' then begin
	  str = name + '  orientation=' + string(an, '$(f9.4)')
	  Widget_Control, info.morientlab, Set_Value = str
        endif
      endif
      moveim = 0
      him = 0
    endif
end
