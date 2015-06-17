pro pstats_Done, event
  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info
  info.wpos.pswp[0] = geo.xoffset - info.xoffcorr
  info.wpos.pswp[1] = geo.yoffset - info.yoffcorr
  (*info.roi).polypts = 0
  (*info.roi).polydone = 0
  (*info.roi).spolypts = 0
  ptr_free, (*info.roi).polyx
  ptr_free, (*info.roi).polyy
  ptr_free, (*info.roi).savpolyx
  ptr_free, (*info.roi).savpolyy
  Widget_Control, event.top, /Destroy
  Widget_Control, info.idp3Window,Set_UValue=info
  roi_display, info
end

pro Idp3_polystatistics, info

@idp3_structs
@idp3_errors
 
  if XRegistered('idp3_polystatistics') then return

  Widget_Control, info.idp3Window, Get_UValue=info
  
  roi = *info.roi
  x1 = roi.roixorig
  y1 = roi.roiyorig
  x2 = roi.roixend
  y2 = roi.roiyend
  xplate = roi.pxscale
  yplate = roi.pyscale
  if xplate le 0.0 then xplate = 1.0
  if yplate le 0.0 then yplate = 1.0
  pts = roi.polypts-1
;  tim = ptr_new((*info.dispim)[x1+info.sxoff:x2+info.sxoff, $
;			       y1+info.syoff:y2+info.syoff])
  tim = ptr_new((*info.dispim)[x1:x2,y1:y2]) 
  xsz = ABS(x2 - x1) + 1
  ysz = ABS(y2 - y1) + 1
  xpts = intarr(pts+1)
  ypts = intarr(pts+1)
  for i = 0, pts do begin
;    xpts[i] = (*roi.polyx)[i] - (x1 + info.sxoff)
;    ypts[i] = (*roi.polyy)[i] - (y1 + info.syoff)
    xpts[i] = (*roi.polyx)[i] - x1
    ypts[i] = (*roi.polyy)[i] - y1 
  endfor
  mask = idp3_poly(xpts, ypts, xsz, ysz)
  good = where(mask GT 0, gcount)
  smask = mask
  smask[*,*] = roi.maskgood 
  smask[good] = roi.maskgood - 1
  if ptr_valid(roi.polymask) then ptr_free, roi.polymask
  (*info.roi).polymsk = 1
  (*info.roi).polymask = ptr_new(smask)
  count = n_elements((*tim)[good]) - 1
  area = xplate * yplate * float(gcount)
  c = moment((*tim)[good])
  (*info.roi).poly_mean = c[0]
  (*info.roi).poly_median = median((*tim)[good], /Even)
  (*info.roi).poly_mode = idp3_calcmode((*tim)[good])
  (*info.roi).poly_meanstd = sqrt(c[1])
  (*info.roi).poly_medianstd = sqrt(total(((*tim)[good] - $
     (*info.roi).poly_median)^2))/float(count)
  (*info.roi).poly_modestd = sqrt(total(((*tim)[good] - $
     (*info.roi).poly_mode)^2)/float(count))
  tot = total((*tim)[good])
  aveflux = tot/area
  polymin = min((*tim)[good])
  polymax = max((*tim)[good])
  str = 'polygon statistics: ' + string(c[0]) +  string(sqrt(c[1])) + $
	string(tot) + string(gcount)
  idp3_updatetxt, info, str
  str = '                    ' + string(area) + string( aveflux) + $
	string(polymin) + string(polymax)
  idp3_updatetxt, info, str
  str = '                    ' + string((*info.roi).poly_median) + $
				 string((*info.roi).poly_medianstd) + $
			         string((*info.roi).poly_mode) + $
				 string((*info.roi).poly_modestd) 
   idp3_updatetxt, info, str
  ptr_free,tim

  polystats = Widget_Base(Title = 'IDP3-ROI Polygon Stats', /Column, $
			       Group_Leader = info.idp3Window, $
			       XOffset = info.wpos.pswp[0], $
			       YOffset = info.wpos.pswp[1])
  
  info.polystats = polystats
  meanField = CW_Field(polystats, Title='           Mean:', XSize=13, $
    Value=c[0])
  sdmField  = CW_Field(polystats, Title='   SD ERR(Mean):', XSize=13, $
    Value=SQRT(c[1]))
  sdpField  = CW_Field(polystats, Title='  SD ERR(Pixel):', XSize=13, $
    Value=SQRT(c[1])/SQRT(gcount))
  totField  = CW_Field(polystats, Title='          Total:', XSize=13, $
    Value=tot)
  nptField  = CW_Field(polystats, Title='   Total Points:', XSize=13, $
    Value=gcount)
  areaField = CW_Field(polystats, Title='  Area (arcsec):', XSize=13, $
    Value=area)
  avfField  = CW_Field(polystats, Title='Ave Flux/arcsec:', XSize=13, $
    Value=aveflux)
  minField  = CW_Field(polystats, Title='            Min:', XSize=13, $
    Value=polymin)
  maxField  = CW_Field(polystats, Title='            Max:', XSize=13, $
    Value=polymax)
  doneButton=Widget_Button(polystats,Value='Done',Event_Pro='pstats_Done')

  Widget_Control, polystats, /Realize
  Widget_Control, polystats, Set_UValue = info
  Widget_Control, info.idp3Window, Set_UValue=info
  XManager, 'idp3_polystatistics', polystats, /No_Block

end
