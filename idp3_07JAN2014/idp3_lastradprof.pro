pro idp3_lastradprof, Event

  ; create new profile based on previous profile values
  ; assumption - radial profile widget is not currently active

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  (*info.roi).radradius = (*info.rprf).r * (*info.roi).roizoom
  (*info.roi).radxcent = ((*info.rprf).sx - (*info.roi).roixorig) * $
     (*info.roi).roizoom
  (*info.roi).radycent = ((*info.rprf).sy - (*info.roi).roiyorig) * $
     (*info.roi).roizoom
  if (*info.roi).radradius gt 1. and (*info.roi).radxcent gt 1. and $
    (*info.roi).radycent gt 1. then begin
    Widget_Control, info.idp3Window, Set_UValue = info
    wset, (*info.roi).drawid2
    rcl = info.color_radpf
    th=fltarr(361)
    for i=0,360 do th(i)=float(i)*(!pi/180.)
    plots,(*info.roi).radradius*cos(th)+(*info.roi).radxcent, $
      (*info.roi).radradius*sin(th)+(*info.roi).radycent,color=rcl,/device
    idp3_radprof, info
    Widget_Control, info.idp3Window, Set_UValue=info
    Widget_Control, event.top, Set_UValue=info
  endif else begin
    stat = Widget_Message('No Last Profile to use')
  endelse
end
