pro idp3_roiClose, info, closeroi

@idp3_errors

  if (*info.roi).rod eq 1 then begin
    (*info.roi).rod = 0
    ptr_free, (*info.roi).rodmask
    ptr_free, (*info.roi).roddmask
  endif

  if (*info.roi).msk eq 1 then begin
    (*info.roi).msk = 0
    ptr_free, (*info.roi).mask
    (*info.roi).maskname = ' '
    (*info.roi).msk_xoff = 0
    (*info.roi).msk_yoff = 0
  endif

  ptr_free, (*info.roi).roiimage

  if closeroi eq 1 then begin
    geo = Widget_Info(info.roiBase, /geometry)
    info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.roiBase, /Destroy
    Widget_Control, info.idp3Window, Set_UValue=info
  endif

  ; Close those widgets whose contents are meaningless without the ROI.

  if (XRegistered('idp3_roistatistics')) then begin
    geo = Widget_Info(info.roistats, /geometry)
    info.wpos.rswp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rswp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.roistats, /Destroy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if (XRegistered('idp3_polystatistics')) then begin
    geo = Widget_Info(info.polystats, /geometry)
    info.wpos.pswp[0] = geo.xoffset - info.xoffcorr
    info.wpos.pswp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.polystats, /Destroy
    (*info.roi).polypts = 0
    (*info.roi).polydone = 0
    (*info.roi).spolypts = 0
    ptr_free, (*info.roi).polyx
    ptr_free, (*info.roi).polyy
    ptr_free, (*info.roi).savpolyx
    ptr_free, (*info.roi).savpolyy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if (XRegistered('idp3_spreadsheet')) then begin
    geo = Widget_Info(info.spread, /geometry)
    info.wpos.sswp[0] = geo.xoffset - info.xoffcorr
    info.wpos.sswp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.spread, /Destroy
    info.sprd.sx = -2
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if (XRegistered('idp3_prof')) then begin
    geo = Widget_Info(info.idp3prof, /geometry)
    info.wpos.pwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.pwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.idp3prof, /Destroy
    (*info.prof).ex = -1
    (*info.prof).ey = -1
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if (XRegistered('idp3_radprof')) then begin
    geo = Widget_Info(info.idp3rprf, /geometry)
    info.wpos.rpwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rpwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.idp3rprf, /Destroy
    (*info.roi).radradius = -1.0
    (*info.roi).centfit = 0
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if (XRegistered('idp3_noiseprof')) then begin
    geo = Widget_Info(info.npBase, /geometry)
    info.wpos.npwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.npwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.npBase, /Destroy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if XRegistered('idp3_photometry') then begin
    geo = Widget_Info(info.apphotBase, /geometry)
    info.wpos.phwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.phwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.apphotBase, /Destroy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if XRegistered('idp3_galasym') then begin
    geo = Widget_Info(info.galasymBase, /geometry)
    info.wpos.gawp[0] = geo.xoffset - info.xoffcorr
    info.wpos.gawp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.galasymBase, /Destroy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if XRegistered('idp3_roicntr') then begin
    geo = Widget_Info(info.roicntrBase, /geometry)
    info.wpos.rcwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rcwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.roicntrBase, /Destroy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  if XRegistered('idp3_roihist') then begin
    geo = Widget_Info(info.histBase, /geometry)
    info.wpos.rhwp[0] = geo.xoffset - info.xoffcorr
    info.wpos.rhwp[1] = geo.yoffset - info.yoffcorr
    Widget_Control, info.histBase, /Destroy
    Widget_Control, info.idp3Window, Set_UValue = info
  endif

  ; Erase the box.
  idp3_display, info
end
