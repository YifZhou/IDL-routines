pro idp3_prntphot, info, name, extn, dohdr

@idp3_structs
@idp3_errors

  semi = ';' 
  phots = info.phot
  outname = info.phot.outname
  temp = file_search (outname, Count = fcount)
  if fcount gt 0 then openw, lun, outname, /Get_Lun, /Append $
    else openw, lun, outname, width=240, /Get_Lun
  if dohdr eq 1 then begin
    zoom = (*info.roi).roizoom
    ztype = info.roiioz
    zm = ['BC', 'BL', 'PR', 'CS']
    zf = ['FNC', 'FC ']
    zoomstr = string(zoom,'$(i2)') + '/' + zm[ztype] + '/' + $
	  zf[info.zoomflux]
    vers = ';   ' + info.UAVersion + '    '
    dat = systime()
    datstr = strmid(dat,11,9) + strmid(dat,4,7) + strmid(dat,20,4)
    if phots.shape eq 0 then method = phots.method + '/Circle' $
       else method = phots.method + '/Square'
    h1 = ';Version IDP3          Date               Method     '
    h2 = 'Target Radius  Inner Sky Radius  Outer Sky Radius        '
    h3 = 'Median Threshold  Aperture Correction  PSF Bkg Fract Flux per pix'
    h4 = '  Comment'
    hstr = h1 + h2 + h3 + h4
    printf, lun, semi
    printf, lun, hstr
    hform1 = '(a11, 3x, a20, 2x, a15, 4x, f9.4, 7x, f10.4, 8x, f10.4, 8x,'
    hform2 = '9x, f8.4, 11x, f9.5, 15x, f12.6, 10x, a20)'
    hformstr = hform1 + hform2
    printf, lun, vers, datstr, method, phots.tradius, phots.biradius, $
		 phots.boradius, phots.med_thresh, phots.ap_corr, $
		 phots.bkg_fract, phots.comment, FORMAT = hformstr
    printf, lun, semi
    ref = (*info.images)[info.moveimage]
;    rname1 = (*ref).name
;    ua_decompose, rname1, rdisk1, rpath1, rname11, rextn1, rvers1
    rname2 = (*ref).orgname
    ua_decompose, rname2, rdisk2, rpath2, rname22, rextn2, rvers2
;    l1 = strlen(rname11)
;    l2 = strlen(rname22)
;    if l1 gt l2 then ext = fix(strmid(rname1, l2+1)) + 1 else ext=0
    ext = (*ref).extver
    str = ';Reference Image: ' + rname2 
    if ext gt 0 then str = str + '   Extension: ' + strtrim(string(ext),2)
    printf, lun, str
    printf, lun, semi
    if strlen(name) le 22 $
      then d1 = ';     Filename        Ext  XCenter    YCenter    TNPix' + $
           '   TNBad' $
      else d1 = ';          Filename                     Ext   XCenter' + $ 
	   '   YCenter     TNPix   TNBad'
    d2 = '     BNPix   BNBad      TMax        TTotal       TMedian'
    d3 = '       TRMS        T2Total      T2Median     CorrFlux'
    d4 = '      BMedian       BMean       BRMS     Sharpv      Sharpv2'
    dstr = d1 + d2 + d3 + d4
    printf, lun, dstr
    printf, lun, semi
  endif
  if strlen(name) le 22 $
    then dform1 = '(a22,2x,i3,2x,f8.3,2x,f8.3,2x,f9.2,2x,i5,2x,f9.2,2x,i5,' $
    else dform1 = '(a38,2x,i3,2x,f8.3,2x,f8.3,2x,f9.2,2x,i5,2x,f9.2,2x,i5,'
  dform2 = '1x,e12.5,1x,e12.5,1x,e12.5,1x,e12.5,1x,e12.5,1x,e12.5,'
  dform3 = '1x,e12.5,1x,e12.5,1x,e12.5,1x,e12.5,1x,e12.5,1x,e12.5)'
  dformstr = dform1 + dform2 + dform3
  printf, lun, name, extn, phots.xcenter, phots.ycenter, phots.tnpix, phots.tnbad, $
	       phots.bnpix, phots.bnbad, phots.tmax, phots.ttotal, $
	       phots.tmedian, phots.trms, phots.t2total, phots.t2median, $
	       phots.corrflux, phots.bmedian, phots.bmean, phots.brms, $
	       phots.sharpv, phots.sharpv2, FORMAT = dformstr
  close, lun
  free_lun, lun
end
