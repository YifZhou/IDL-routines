pro idp3_prntfeps, info, iname, imnum, im_ext, dohdr, allon

@idp3_structs
@idp3_errors

  semi = ';' 
  phots = info.phot
  cent = info.cent
  numimages = n_elements(*info.images)
  zoom = (*info.roi).roizoom
  outname = info.phot.outname
  m = (*info.images)[imnum]
  hdr = [*(*m).phead, *(*m).ihead]
  ref = (*info.images)[info.moveimage]
  nullstr = "''"
  pound = '#'
  blankstr = '     '
  qt = "'"
  rdate = get_ut()
  ua_decompose, outname, disk, path, tname, extn, vers
  if dohdr eq 1 then begin
    ; write out table 1
    t1name = disk + path + tname + '.tbl'
    str = 'PrntFEPS: writing table 1: ' + t1name
    idp3_updatetxt, info, str
    temp = file_search (t1name, Count=fcount)
    if fcount gt 0 then openw, lun1, t1name, /Get_Lun, /Append $
      else openw, lun1, t1name, width=120, /Get_Lun
    printf, lun1, blankstr
    printf, lun1, pound
    printf, lun1, pound, '   Table 1:  General/Summary Information'
    printf, lun1, pound
    printf, lun1, pound, '   BCD Image Name: ', iname
    printf, lun1, pound, '   Image Extension: ', im_ext
    printf, lun1, pound, '   ', rdate
    printf, lun1, pound
    printf, lun1, 'FLUX_ID   = ', nullstr
    object = sxpar(hdr, 'OBJECT', count=cnt)
    if cnt le 0 then object = nullstr else object = qt + object + qt
    printf, lun1, 'OBJECT    = ', object
    instrume = sxpar(hdr, 'INSTRUME', count=cnt)
    if cnt le 0 then sinstrume = nullstr else sinstrume = qt + instrume + qt
    printf, lun1, 'INSTRUME  = ', sinstrume
    instrume = strtrim(instrume,2)
    chnlnum = sxpar(hdr, 'CHNLNUM', count=cnt)
    printf, lun1, 'CHNLNUM   = ', chnlnum
    printf, lun1, 'FLUX      = ', nullstr
    printf, lun1, 'SIG_INTL  = ', nullstr
    printf, lun1, 'SIG_CAL   = ', nullstr
    printf, lun1, 'SIG_TOT   = ', nullstr
    printf, lun1, 'SNR       = ', nullstr
    date_obs = sxpar(hdr, 'DATE_OBS', count=cnt)
    if cnt le 0 then date_obs = nullstr else date_obs = qt + date_obs + qt
    printf, lun1, 'DATE_OBS  = ', date_obs
    printf, lun1, 'ENTRY_DAT = ', nullstr
    printf, lun1, 'PHOT_ANYST= ', qt, info.feps_analyst, qt
    printf, lun1, 'N_SOURCES = ', nullstr
    printf, lun1, 'QUAL_FLAG = ', qt, phots.qualflag, qt
    printf, lun1, 'TABLE1_REF= ', qt, info.fepstb1ref, qt
    printf, lun1, 'COMMENTS  = ', nullstr

    ; write out table 2
    printf, lun1, blankstr
    printf, lun1, pound
    printf, lun1, pound, '   Table 2:  Observation Information'
    printf, lun1, pound
    printf, lun1, pound, '   BCD Image Name: ', iname
    printf, lun1, pound, '   Image Extension: ', im_ext
    printf, lun1, pound, '   ', rdate
    printf, lun1, pound
    printf, lun1, 'FLUX_ID   = ', nullstr
    printf, lun1, 'IMAGE_CNT = ', nullstr
    dithpatt = sxpar(hdr, 'DITHPATT', count=cnt)
    if cnt le 0 then dithpatt = nullstr else dithpatt = qt + dithpatt + qt
    printf, lun1, 'DITHPATT  = ', dithpatt
    dithscal = sxpar(hdr, 'DITHSCAL', count=cnt)
    if cnt le 0 then dithscal = nullstr else dithscal = qt + dithscal + qt
    printf, lun1, 'DITHSCAL  = ', dithscal
;    nmapcycl = sxpar(hdr, 'NMAPCYCL', count=cnt)
;    if cnt le 0 then nmapcycl = nullstr
;    printf, lun1, 'NMAPCYCL  = ', nmapcycl
    field24 = sxpar(hdr, 'LARGE24', count=l24)
    field70 = sxpar(hdr, 'LARGE70', count=l70)
    field160 = sxpar(hdr, 'LARGE160', count=l160)
    if l24 + l70 + l160 gt 0 then begin
      if l24 gt 0 then fieldsize = field24
      if l70 gt 0 then fieldsize = field70
      if l160 gt 0 then fieldsize = field160
    endif else fieldsize = nullstr
    printf, lun1, 'FIELDSIZE = ', fieldsize
    ncycles = sxpar(hdr, 'NCYCLES', count=nccnt)
    ncycl24 = sxpar(hdr, 'NCYCL24', count=cnt24)
    ncycl70 = sxpar(hdr, 'NCYCL70', count=cnt70)
    ncycl160 = sxpar(hdr, 'NCYCL160', count=cnt160)
    if nccnt + cnt24 + cnt70 + cnt160 gt 0 then begin
      if nccnt gt 0 then ncycl = ncycles
      if cnt24 gt 0 then ncycl = ncycl24
      if cnt70 gt 0 then ncycl = ncycl70
      if cnt160 gt 0 then ncycl = ncycl160
    endif else ncycl = nullstr 
    printf, lun1, 'NCYCL   = ', ncycl
;    if cnt le 0 then ncycles = nullstr
;    printf, lun1, 'NCYCLES   = ', ncycles
    aorkey = sxpar(hdr, 'AORKEY', count=cnt)
    if cnt le 0 then aorkey = nullstr
    printf, lun1, 'AORKEY    = ', aorkey
    samptime = sxpar(hdr, 'SAMPTIME', count=cnt)
    if cnt le 0 then samptime = nullstr
    printf, lun1, 'SAMPTIME  = ', samptime
    paonum = sxpar(hdr, 'PAONUM', count=cnt)
    if paonum le 0 then paonum = nullstr 
    printf, lun1, 'PAONUM    = ', paonum
    printf, lun1, 'EXP_RQST  = ', nullstr
    exptime = sxpar(hdr, 'EXPTIME', count=cnt)
    if cnt le 0 then exptime = nullstr
    printf, lun1, 'EXPTIME   = ', exptime
    framtime = sxpar(hdr, 'FRAMTIME', count=cnt)
    if cnt le 0 then framtime = nullstr
    printf, lun1, 'FRAMTIME  = ', framtime
    date = sxpar(hdr, 'DATE', count=cnt)
    if cnt le 0 then date = nullstr else date = qt + date + qt
    printf, lun1, 'BCD_DATE  = ', date
    printf, lun1, 'CFACT_ID  = ', nullstr
    pdate = qt + rdate + qt
    printf, lun1, 'PHOT_DATE = ', pdate
    printf, lun1, 'DATA_QUAL = ', nullstr
    printf, lun1, 'UPLD_FILE = ', nullstr
    printf, lun1, 'COMMENTS  = ', nullstr

    ; write out table 5
    printf, lun1, blankstr
    printf, lun1, pound
    printf, lun1, pound, '   Table 5  Pipeline and Calibration Version History'
    printf, lun1, pound
    printf, lun1, pound, '   BCD Image Name: ', iname
    printf, lun1, pound, '   Image Extension: ', im_ext
    printf, lun1, pound, '   ', rdate
    printf, lun1, pound
    printf, lun1, 'CFACT_ID  = ', nullstr
    printf, lun1, 'INSTRUME  = ', instrume
    printf, lun1, 'CHNLNUM   = ', chnlnum
    creator = sxpar(hdr, 'CREATOR', count=cnt)
    if cnt le 0 then screator = nullstr else screator = qt + creator + qt
    printf, lun1, 'CREATOR   = ', screator
    creator = strtrim(creator,2)
    sis_sver = sxpar(hdr, 'SIS_SVER', count=cnt)
    if cnt le 0 then begin
      sis_sver = sxpar(hdr, 'CREATOR0', count=cnt)
      if cnt le 0 then sis_sver = nullstr else sis_sver = qt + sis_sver + qt
    endif else sis_sver = qt + sis_sver + qt
    printf, lun1, 'SIS_SVER  = ', sis_sver
    sos_ver = sxpar(hdr, 'SOS_VER', count=cnt)
    if cnt le 0 then sos_ver = nullstr 
    printf, lun1, 'SOS_VER   = ', sos_ver
    sos_date = sxpar(hdr, 'SOS_DATE', count=cnt)
    if cnt le 0 then sos_date = nullstr else sos_date = qt + sos_date + qt
    printf, lun1, 'SOS_DATE  = ', sos_date
    plvid = sxpar(hdr, 'PLVID', count=cnt)
    if cnt le 0 then plvid = nullstr
    printf, lun1, 'PLVID     = ', plvid
    calid = sxpar(hdr, 'CALID', count=cnt)
    if cnt le 0 then calid = nullstr
    printf, lun1, 'CALID     = ', calid
    mc_ver = sxpar(hdr, 'MC_VER', count=cnt)
    if cnt le 0 then mc_ver = nullstr else mc_ver = qt + mc_ver + qt
    printf, lun1, 'MC_VER    = ', mc_ver
    ms_ver = sxpar(hdr, 'MS_VER', count=cnt)
    if cnt le 0 then ms_ver = nullstr else ms_ver = qt + ms_ver + qt
    printf, lun1, 'MS_VER    = ', ms_ver
    me_ver = sxpar(hdr, 'ME_VER', count=cnt)
    if cnt le 0 then me_ver = nullstr else me_ver = qt + me_ver + qt
    printf, lun1, 'ME_VER    = ', me_ver
    bunit = sxpar(hdr, 'BUNIT', count=cnt)
    if cnt le 0 then bunit = nullstr else bunit = qt + bunit + qt
    printf, lun1, 'BUNIT     = ', bunit
    fluxconv = sxpar(hdr, 'FLUXCONV', count=cnt)
    if cnt le 0 then begin
      if info.phot.fepsstat ge 0 then begin
	stat = idp3_getfeps(phots.fepsfile, instrume, creator, chnlnum, $
	       'FLUXCONV', value)
        if stat ge 0 then fluxconv = value else fluxconv = nullstr
      endif else fluxconv = nullstr
    endif 
    fluxcnv1 = sxpar(hdr, 'FLUXCNV1', count=cnt)
    if cnt le 0 then fluxcnv1 = nullstr
    fluxcnv2 = sxpar(hdr, 'FLUXCNV2', count=cnt)
    if cnt le 0 then fluxcnv2 = nullstr
    fluxcnv3 = sxpar(hdr, 'FLUXCNV3', count=cnt)
    if cnt le 0 then fluxcnv3 = nullstr
    fluxcnv4 = sxpar(hdr, 'FLUXCNV4', count=cnt)
    if cnt le 0 then fluxcnv4 = nullstr
    printf, lun1, 'FLUXCONV  = ', fluxconv
    printf, lun1, 'FLUXCNV1  = ', fluxcnv1
    printf, lun1, 'FLUXCNV2  = ', fluxcnv2
    printf, lun1, 'FLUXCNV3  = ', fluxcnv3
    printf, lun1, 'FLUXCNV4  = ', fluxcnv4
    if phots.fepsstat ge 0 then begin
      stat = idp3_getfeps(phots.fepsfile, instrume, creator, chnlnum, $
	    'SIGFCONV', value)
      if stat ge 0 then sigfconv = value else sigfconv = nullstr
    endif else sigfconv = nullstr
    printf, lun1, 'SIGFCONV  = ', sigfconv
    printf, lun1, 'TABLE5_REF= ', info.fepstb5ref
    printf, lun1, 'COMMENTS  = ', nullstr
  
    ; write out table 6 
    printf, lun1, blankstr
    printf, lun1, pound
    printf, lun1, pound, '   Table 6 IDP3 Version History'
    printf, lun1, pound
    printf, lun1, pound, '   BCD Image Name: ', iname
    printf, lun1, pound, '   Image Extension: ', im_ext
    printf, lun1, pound, '   ', rdate
    printf, lun1, pound
    printf, lun1, 'IDL_VER    = ', !version.release
    printf, lun1, 'IDP3_VER   = ', info.UAVersion
    idp3_date = get_ut()
    idp3_date = qt + idp3_date + qt
    printf, lun1, 'IDP3_DATE  = ', idp3_date
    printf, lun1, 'TABLE6_REF = ', info.fepstb6ref
    printf, lun1, 'COMMENTS   = ', nullstr
  
    ; write out table 7 
    printf, lun1, blankstr
    printf, lun1, pound
    printf, lun1, pound, '   Table 7:  Data Quality Flags'
    printf, lun1, pound
    printf, lun1, pound, '   BCD Image Name: ', iname
    printf, lun1, pound, '   Image Extension: ', im_ext
    printf, lun1, pound, '   ', rdate
    printf, lun1, pound
    printf, lun1, 'START COMMENT'
    printf, lun1, 'END COMMENT'
    close, lun1
    free_lun, lun1
  endif

  ; write out table 3
  t3name = disk + path + tname + '.tbl3'
  temp = file_search (t3name, Count = fcount)
  if fcount gt 0 then openw, lun3, t3name, /Get_Lun, /Append $
    else openw, lun3, t3name, width=120, /Get_Lun
  printf, lun3, pound
  printf, lun3, pound, $
    '   Table 3:  Image  *** list of individual images or whole image'
  printf, lun3, pound, $
    '             information on dither pattern, image statistics'
  printf, lun3, pound
  printf, lun3, pound, '   BCD Image Name: ', iname
  printf, lun3, pound, '   Image Extension: ', im_ext
  printf, lun3, pound, '   ', rdate
  printf, lun3, pound
  printf, lun3, 'IMAGE_CNT = ', nullstr
  ncoadd = sxpar(hdr, 'NCOADD', count=cnt)
  if cnt le 0 then ncoadd = sxpar(hdr, 'NCOMBINE', count=cnt)
  if cnt gt 0 then printf, lun3, 'NCOADD    = ', ncoadd $
    else printf, lun3, 'NCOADD    = ', 1
  cmethod = sxpar(hdr, 'CMETHOD', count=cnt)
  if cnt eq 0 then cmethod = nullstr else cmethod = qt + cmethod + qt
  printf, lun3, 'COADD_METH= ', cmethod
  naxis1 = sxpar(hdr, 'NAXIS1')
  printf, lun3, 'NAXIS1   = ', naxis1
  naxis2 = sxpar(hdr, 'NAXIS2')
  printf, lun3, 'NAXIS2   = ', naxis2
  cd11 = (*m).acd11
  cd12 = (*m).acd12
  cd21 = (*m).acd21
  cd22 = (*m).acd22
  idp3_cd2cdelt,(*m).acd11,(*m).acd12,(*m).acd21,(*m).acd22,cdelt1,cdelt2,crota
  printf, lun3, 'XPIXSIZE =', abs(cdelt1) * 3600.0d0
  printf, lun3, 'YPIXSIZE =', abs(cdelt2) * 3600.0d0
  gain = sxpar(hdr, 'GAIN', count=gcnt)
  gain1 = sxpar(hdr, 'GAIN1', count=gcnt1)
  gain2 = sxpar(hdr, 'GAIN2', count=gcnt2)
  gain3 = sxpar(hdr, 'GAIN3', count=gcnt3)
  gain4 = sxpar(hdr, 'GAIN4', count=gcnt4)
  if gcnt eq 0 then begin
    gain=0.
    gnum=0
    if gcnt1 gt 0 then begin
      gain = gain + gain1
      gnum = gnum + 1
    endif
    if gcnt2 gt 0 then begin
      gain = gain + gain2
      gnum = gnum + 1
    endif
    if gcnt3 gt 0 then begin
      gain = gain + gain3
      gnum = gnum + 1
    endif
    if gcnt4 gt 0 then begin
      gain = gain + gain4
      gnum = gnum + 1
    endif
    if gnum gt 0 then gain = gain/float(gnum) else gain = 0.
  endif
  printf, lun3, 'GAIN     = ', gain
  nsigl = sxpar(hdr, 'NSIGMAL', count=cnt)
  if cnt gt 0 then nsigl = nullstr
  printf, lun3, 'NSIGMA_LO = ', nsigl 
  nsigh = sxpar(hdr, 'NSIGMAH', count=cnt)
  if cnt gt 0 then nsigh = nullstr
  printf, lun3, 'NSIGMA_HI = ', nsigh 
  printf, lun3, 'IMG_NAME  = ', qt, iname, qt
  printf, lun3, 'IMG_EXTN  = ', im_ext
  printf, lun3, 'NTOT      = ', nullstr
  printf, lun3, 'NMAX      = ', nullstr
  dcenum = sxpar(hdr, 'DCENUM', count=cnt)
  if cnt gt 0 then sdcenum = string(dcenum) else sdcenum = nullstr
  if ncoadd gt 1 then sdcenum = nullstr
  printf, lun3, 'DCENUM    = ', sdcenum
  expid = sxpar(hdr, 'EXPID', count=cnt)
  if cnt le 0 then expid = nullstr
  printf, lun3, 'EXPID     = ', expid
  cyclenum = sxpar(hdr, 'CYCLENUM', count=cnt)
  if cnt gt 0 then scyclenum = string(cyclenum) else scyclenum = nullstr
  printf, lun3, 'CYCLENUM  = ', scyclenum
  dithpos = sxpar(hdr, 'DITHPOS', count=cnt)
  if cnt gt 0 then sdithpos = string(dithpos) else sdithpos = nullstr
  if ncoadd gt 1 then sdithpos = nullstr
  printf, lun3, 'DITHPOS   = ', sdithpos
  column = sxpar(hdr, 'COLUMN', count=cnt)
  if cnt gt 0 then scolumn = string(column) else scolumn = nullstr
  printf, lun3, 'COLUMN    = ', scolumn
  row = sxpar(hdr, 'ROW', count=cnt)
  if cnt gt 0 then srow = string(row) else srow = nullstr
  printf, lun3, 'ROW       = ', srow
  sclegnum = sxpar(hdr, 'SCLEGNUM', count=cnt)
  if cnt gt 0 then ssclegnum = string(sclegnum) else ssclegnum = nullstr
  printf, lun3, 'SCLEGNUM  = ', ssclegnum
  scandir = sxpar(hdr, 'SCANDIR', count=cnt)
  if cnt le 0 then scandir = nullstr else scandir = qt + scandir + qt
  printf, lun3, 'SCANDIR   = ', scandir
  utcs_obs = sxpar(hdr, 'UTCS_OBS', count=cnt)
  if cnt le 0 then utcs_obs = nullstr
  printf, lun3, 'UTCS_OBS  = ', utcs_obs
  clposnum = sxpar(hdr, 'CLPOSNUM', count=cnt)
  if cnt le 0 then clposnum = nullstr
  printf, lun3, 'CLPOSNUM  = ', clposnum
  depth = sxpar(hdr, 'DEPTH', count=cnt)
  if cnt le 0 then depth = nullstr
  printf, lun3, 'DEPTH     = ', depth
  aintbeg = sxpar(hdr, 'AINTBEG', count=cnt)
  if cnt le 0 then aintbeg = nullstr
  printf, lun3, 'AINTBEG   = ', aintbeg
  atimeend = sxpar(hdr, 'ATIMEEND', count=cnt)
  if cnt le 0 then atimeend = nullstr
  printf, lun3, 'ATIMEEND  = ', atimeend
  printf, lun3, 'RMS_TIMG  = ', phots.irms
  printf, lun3, 'MEAN_TIMG = ', phots.imean
  printf, lun3, 'MEDI_TIMG = ', phots.imedian
;  printf, lun3, 'RMS_BIMG  = ', phots.brrms
;  printf, lun3, 'MEAN_BIMG = ', phots.brmean
;  printf, lun3, 'MEDI_BIMG = ', phots.brmedian
  afpecte = sxpar(hdr, 'AFPECTE', count=cnt)
  if cnt le 0 then afpecte = nullstr
  printf, lun3, 'AFPECTE   = ', afpecte
  atctempe = sxpar(hdr, 'ATCTEMPE', count=cnt)
  if cnt le 0 then atctempe = nullstr
  printf, lun3, 'ATCTEMPE  = ', atctempe
  apdtempe = sxpar(hdr, 'APDTEMPE', count=cnt)
  if cnt le 0 then apdtempe = nullstr
  printf, lun3, 'APDTEMPE  = ', apdtempe
  acatmp2e = sxpar(hdr, 'ACATMP2E', count=cnt)
  if cnt le 0 then acatmp2e = nullstr
  printf, lun3, 'ACATMP2E  = ', acatmp2e
  acatmp3e = sxpar(hdr, 'ACATMP3E', count=cnt)
  if cnt le 0 then acatmp3e = nullstr
  printf, lun3, 'ACATMP3E  = ', acatmp3e
  acatmp5e = sxpar(hdr, 'ACATMP5E', count=cnt)
  if cnt le 0 then acatmp5e = nullstr
  printf, lun3, 'ACATMP5E  = ', acatmp5e
  ptgdiff = sxpar(hdr, 'PTGDIFF', count=cnt)
  if cnt le 0 then ptgdiff = nullstr
  printf, lun3, 'PTGDIFF   = ', ptgdiff
  cmd_t_24 = sxpar(hdr, 'CMD_T_24', count=cnt)
  if cnt le 0 then cmd_t_24 = nullstr
  printf, lun3, 'CMD_T_24  = ', cmd_t_24
  ad24tmpa = sxpar(hdr, 'AD24TMPA', count=cnt)
  if cnt le 0 then ad24tmpa = nullstr
  printf, lun3, 'AD24TMPA  = ', ad24tmpa
  acsmmtmp = sxpar(hdr, 'ACSMMTMP', count=cnt)
  if cnt le 0 then acsmmtmp = nullstr
  printf, lun3, 'ACSMMTMP  = ', acsmmtmp
  aceboxtm = sxpar(hdr, 'ACEBOXTM', count=cnt)
  if cnt le 0 then aceboxtm = nullstr
  printf, lun3, 'ACEBOXTM  = ', aceboxtm
  ad70tmpa = sxpar(hdr, 'AD70TMPA', count=cnt)
  if cnt le 0 then ad70tmpa = nullstr
  printf, lun3, 'AD70TMPA  = ', ad70tmpa
  ad70tmpb = sxpar(hdr, 'AD70TMPB', count=cnt)
  if cnt le 0 then ad70tmpb = nullstr
  printf, lun3, 'AD70TMPB  = ', ad70tmpb
  ad160tma = sxpar(hdr, 'AD160TMA', count=cnt)
  if cnt le 0 then ad160tma = nullstr
  printf, lun3, 'AD160TMA  = ', ad160tma
  ad160tmb = sxpar(hdr, 'AD160tmb', count=cnt)
  if cnt le 0 then ad160tmb = nullstr
  printf, lun3, 'AD160TMB  = ', ad160tmb
  printf, lun3, 'COMMENTS  = ', nullstr
  close, lun3
  free_lun, lun3

  ; output table 4A
  t4aname = disk + path + tname + '.tbl4a'
  temp = file_search (t4aname, Count = fcount)
  if fcount gt 0 then openw, lun4a, t4aname, /Get_Lun, /Append $
    else openw, lun4a, t4aname, width=120, /Get_Lun
  printf, lun4a, pound
  printf, lun4a, pound, '   Table 4A: Aperture Photometry'
  printf, lun4a, pound, $
    '       *** photometry off of a coadded image or individual frame'
  printf, lun4a, pound
  printf, lun4a, pound, '   BCD Image Name: ', iname
  printf, lun4a, pound, '   Image Extension: ', im_ext
  printf, lun4a, pound, '   ', rdate
  printf, lun4a, pound
  printf, lun4a, 'PHOT_CNT = ', nullstr
;  printf, lun4a, 'NCOADD   = ', sncoadd
  printf, lun4a, 'IMG_NAME  = ', qt, iname, qt
  printf, lun4a, 'IMG_EXTN  = ', im_ext
  printf, lun4a, 'DCENUM   = ', sdcenum
  printf, lun4a, 'XCEN_AP  = ', phots.xcenter
  printf, lun4a, 'YCEN_AP  = ', phots.ycenter
  if phots.all_cntrs eq 0 then begin
    lccx = (*ref).lccx
    lccy = (*ref).lccy
  endif else begin
    lccx = (*m).lccx
    lccy = (*m).lccy
  endelse
  pwcs = 0
  hdr = idp3_setcoords((*m), pwcs)
  xyad, hdr, lccx, lccy, xra, xdec
  if xra lt 0.0d0 then xra = xra + 360.d0
  idp3_conra, xra/15.0, prastr
  idp3_condec, xdec, pdecstr
  printf, lun4a, 'RA_AP    = ', qt, prastr, qt
  printf, lun4a, 'DEC_AP   = ', qt, pdecstr, qt
  printf, lun4a, 'CENTROID_X= ', lccx
  printf, lun4a, 'CENTROID_Y= ', lccy
  hdr = idp3_setcoords((*m), pwcs)
  xyad, hdr, lccx, lccy, xra, xdec
  if xra lt 0.0d0 then xra = xra + 360.d0
  idp3_conra, xra/15.0, rastr
  idp3_condec, xdec, decstr
  printf, lun4a, 'CNTRD_RA  = ', qt, rastr, qt
  printf, lun4a, 'CNTRD_DEC = ', qt, decstr, qt
  printf, lun4a, 'GAUSSXFWHM= ', cent.fwhmx
  printf, lun4a, 'GAUSSYFWHM= ', cent.fwhmy
  printf, lun4a, 'GAUSSPA   = ', cent.theta
  radesys = sxpar(hdr, 'RADESYS', count=cnt)
  if cnt le 0 then radesys = nullstr else radesys = qt + radesys + qt
  printf, lun4a, 'RADESYS   = ', radesys
  equinox = sxpar(hdr, 'EQUINOX', count=cnt)
  if cnt le 0 then equinox = nullstr
  printf, lun4a, 'EQUINOX   = ', equinox
  printf, lun4a, 'R_AP_TG  = ', phots.tradius
  printf, lun4a, 'R_BG_I   = ', phots.biradius
  printf, lun4a, 'R_BG_O   = ', phots.boradius
  printf, lun4a, 'NPIX_AP  = ', phots.tnpix
  printf, lun4a, 'N_BAD_AP = ', phots.tnbad
  printf, lun4a, 'N_BG     = ', phots.bnpix
  printf, lun4a, 'N_BAD_BG = ', phots.bnbad
  printf, lun4a, 'F_PEAK_AP= ', phots.tmax
  printf, lun4a, 'F_AP_ENC = ', phots.ttotal
  printf, lun4a, 'F_AP_NOBG= ', phots.t2total
  printf, lun4a, 'F_NOBG   = ', phots.corrflux
  printf, lun4a, 'SIG_FLUX1= ', nullstr
  printf, lun4a, 'SIG_FLUX2= ', nullstr
  printf, lun4a, 'SIG_FLUX3= ', nullstr
  printf, lun4a, 'RMS_BG   = ', phots.brms
  printf, lun4a, 'MD_BG_PIX= ', phots.bmedian
  printf, lun4a, 'MN_BG_PIX= ', phots.bmean
  printf, lun4a, 'APCORR_T = ', phots.ap_corr
  printf, lun4a, 'BG_FRACT = ', phots.bkg_fract
  printf, lun4a, 'SHARPNBKG= ', phots.sharpv2
  printf, lun4a, 'SHARP_ENC= ', phots.sharpv
  printf, lun4a, 'RMS_BIMG  = ', phots.brrms
  printf, lun4a, 'MEAN_BIMG = ', phots.brmean
  printf, lun4a, 'MEDI_BIMG = ', phots.brmedian
  printf, lun4a, 'QUAL_FLAG= ', qt, phots.qualflag, qt
  str = 'COMMENT  = ' + qt + phots.comment + qt
  printf, lun4a, str
  close, lun4a
  free_lun, lun4a
  ; write out table 8
    t8name = disk + path + tname + '.tbl8'
    temp = file_search (t8name, Count = fcount)
    if fcount gt 0 then openw, lun8, t8name, /Get_Lun, /Append $
      else openw, lun8, t8name, width=120, /Get_Lun
    printf, lun8, pound
    printf, lun8, pound, $
      '   Table 8:  Data Processing Information'
    printf, lun8, pound
    printf, lun8, pound, '   BCD Image Name: ', iname
    printf, lun8, pound, '   Image Extension: ', im_ext
    printf, lun8, pound, '   ', rdate
    printf, lun8, pound
    printf, lun8, pound, '      ROI and Centroid info'
    printf, lun8, pound
;    rname1 = (*ref).name
;    ua_decompose, rname1, rdisk1, rpath1, rname1, rextn1, rvers1
    rname2 = (*ref).orgname
    ua_decompose, rname2, rdisk2, rpath2, rname2, rextn2, rvers2
;    l1 = strlen(rname1)
;    l2 = strlen(rname2)
;    if l1 gt l2 then rim_ext = fix(strmid(rname1, l2+1)) + 1 else rim_ext=0
    str = 'R_IMGName= ' + qt + rname2 + rextn2 + qt
    printf, lun8, str
;    printf, lun8, 'R_IMGName= ', qt, rname2, rextn2, qt
    printf, lun8, 'R_IMGExt= ', (*ref).extver
    str = 'R_IMGPath= ' + qt + rdisk2 + rpath2 + qt
    printf, lun8, str
;    printf, lun8, 'R_IMGPath= ', qt, rdisk2, rpath2, qt
;    printf, lun8, 'CENTROID_X= ', lccx
;    printf, lun8, 'CENTROID_Y= ', lccy
;    hdr = idp3_setcoords((*m))
;    xyad, hdr, lccx+1., lccy+1., xra, xdec
;    if xra lt 0.0d0 then xra = xra + 360.d0
;    idp3_conra, xra/15.0, rastr
;    idp3_condec, xdec, decstr
;    printf, lun8, 'CNTRD_RA  = ', qt, rastr, qt
;    printf, lun8, 'CNTRD_DEC = ', qt, decstr, qt
;    printf, lun8, 'GAUSSXFWHM= ', cent.fwhmx
;    printf, lun8, 'GAUSSYFWHM= ', cent.fwhmy
;    printf, lun8, 'GAUSSPA   = ', cent.theta
    case (*info.roi).cmethod of
      2: cmstr = 'Weighted Moment'
      4: cmstr = 'Gaussian Fit'
      6: cmstr = 'Weighted Moment (CNTRD)'
      8: cmstr = 'Weighted Moment (HalfBox)'
      10: cmstr = 'Weighted Moment (CNTRD)'
      12: cmstr = 'Gaussian Fit'
      14: cmstr = 'Weighted Moment (CNTRD)'
      else: cmstr = 'None'
    endcase
    printf, lun8, 'CNTRD_TYPE= ', qt, cmstr, qt
    printf, lun8, 'ROI_ZOOM  =', zoom
    case info.roiioz of
      0: zstr = 'BiCubic Sinc'
      1: zstr = 'BiLinear'
      2: zstr = 'Pixel Replication'
      3: zstr = 'BiCubic Spline'
    else: zstr = 'Unknown'
    endcase
    printf, lun8, 'ZOOM_TYPE = ', qt, zstr, qt
    if info.zoomflux eq 0 then zcstr = 'Flux is not conserved' else $
      zcstr = 'Flux is conserved [scaled by 1./(zoom^2)]'
    printf, lun8, 'FLUX_TYPE = ', qt, zcstr, qt
    ims = info.images
    cnt = 0
    for kk = 0, numimages-1 do begin
      if (*(*ims)[kk]).vis eq 1 then begin
	cnt = cnt + 1
      endif else begin
	if kk eq info.moveimage then begin
	  str = 'PrntFEPS: Reference image not ON, must abort!'
	  idp3_updatetxt, info, str
	  close, lun8
	  free_lun, lun8
	  return
         endif
       endelse
    endfor
    printf, lun8, 'N_IMG_ON  = ', cnt
    if allon eq 1 then begin
      beg = 0
      last = numimages-1
    endif else begin
      beg = imnum
      last = imnum
    endelse
    counter = 0
    for mm = beg, last do begin
      if (*(*ims)[mm]).vis eq 1 then begin
        ct = string(format='(i2.2)', counter)
	printf, lun8, pound, '   Image ', ct
;        uname1 = (*(*ims)[mm]).name
	uname2 = (*(*ims)[mm]).orgname
;        ua_decompose, uname1, udisk1, upath1, uname1, uextn1, uvers1
        ua_decompose, uname2, udisk2, upath2, uname2, uextn2, uvers2
;        l1 = strlen(uname1)
;        l2 = strlen(uname2)
;        if l1 gt l2 then uim_ext = fix(strmid(uname1, l2+1)) + 1 else uim_ext=0
        uname = uname2 + uextn2
	printf, lun8, 'IMG_NAME' + ' = ', qt, uname, qt
	printf, lun8, 'IMG_EXTN' + ' = ', (*(*ims)[mm]).extver
	str = 'IMG_PATH' + ' = ' +  qt + upath2 + qt
	printf, lun8, str
;	printf, lun8, 'IMG_PATH' + ' = ', qt, upath2, qt
        printf, lun8, 'IMG_SCL' + '  = ', (*(*ims)[mm]).scl
        printf, lun8, 'IMG_BIAS' + ' = ', (*(*ims)[mm]).bias
        case (*(*ims)[mm]).dispf of
	  1: dstr = 'ADD, add image to stack'
	  2: dstr = 'SUB, subtract image from stack'
	  3: dstr = 'DIV, divide image into stack'
	  4: dstr = 'INV, logical OR image with stack'
	  5: dstr = 'AVE, average image with stack'
	  6: dstr = 'MUL, multiply image by stack'
	  7: dstr = 'MIN, compute minimum of image and stack'
	  8: dstr = 'POS, pix < 0 set to 0, add to stack'
	  9: dstr = 'NEG, pix > 0 set to 0, abs(pix < 0), add to stack'
	  10: dstr = 'ABS, abs(image), add to stack'
	  else: dstr = 'UNKNOWN'
        endcase
        printf, lun8, 'DISP_FNC' +  '= ', qt, dstr, qt
        printf, lun8, 'IMG_ZOOM' + ' =', (*(*ims)[mm]).zoom
        printf, lun8, 'IMG_ROT' + '  = ', (*(*ims)[mm]).rot
        printf, lun8, 'ROT_XCEN' + '= ', (*(*ims)[mm]).rotcx
        printf, lun8, 'ROT_YCEN' + '= ', (*(*ims)[mm]).rotcy
        xo = (*(*ims)[mm]).xoff + (*(*ims)[mm]).xpoff
        yo = (*(*ims)[mm]).yoff + (*(*ims)[mm]).ypoff
        printf, lun8, 'XOFFSET' + ' = ', xo
        printf, lun8, 'YOFFSET' + ' = ', yo
        printf, lun8, 'XPSCLFAC' + '= ', (*(*ims)[mm]).xpscl
        printf, lun8, 'YPSCLFAC' + '= ', (*(*ims)[mm]).ypscl
        printf, lun8, 'IMG_XPAD' + ' = ', (*(*ims)[mm]).rotxpad
        printf, lun8, 'IMG_YPAD' + ' = ', (*(*ims)[mm]).rotypad
        if (*(*ims)[mm]).flipy eq 1 $
	  then fstr = 'Image flipped about Y-AXIS' $ 
    	  else fstr = 'Image not flipped'
        printf, lun8, 'IMG_FLIP' + ' = ', qt, fstr, qt
	counter = counter + 1
      endif
    endfor
    close, lun8
    free_lun, lun8
end
