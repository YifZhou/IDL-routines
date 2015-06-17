pro galasym_Done, event
  Widget_Control, event.top, /Destroy
end

pro galasym_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=gainfo
  Widget_Control, gainfo.info.idp3Window, Get_UValue=tempinfo
  gainfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=gainfo

  case event.id of

    gainfo.gaxcenterField: begin
      ; Just read the value and save it.
      Widget_Control, gainfo.gaxcenterField, Get_Value = temp
      (*gainfo.info.roi).galxcntr = temp
      end
    gainfo.gaycenterField: begin
      Widget_Control, gainfo.gaycenterField, Get_Value = temp
      (*gainfo.info.roi).galycntr = temp
      end
    gainfo.centButton: begin
      xc = float((*gainfo.info.roi).radxcent)/(*gainfo.info.roi).roizoom + $
	(*gainfo.info.roi).roixorig 
      yc = float((*gainfo.info.roi).radycent)/(*gainfo.info.roi).roizoom + $
	(*gainfo.info.roi).roiyorig
      (*gainfo.info.roi).galxcntr = xc
      (*gainfo.info.roi).galycntr = yc
      Widget_Control, gainfo.gaxcenterField, Set_Value = xc
      Widget_Control, gainfo.gaycenterField, Set_Value = yc
      end
    gainfo.gradiusField: begin
      Widget_Control, gainfo.gradiusField, Get_Value = temp
      (*gainfo.info.roi).galradius = temp[0]
      end
    gainfo.radiusButton: begin
      radius = (*gainfo.info.roi).xslength * 0.5
      Widget_Control, gainfo.gradiusField, Set_Value = radius
      (*gainfo.info.roi).galradius = radius
      end
    gainfo.bkgField: begin
      ; constant background value, set region to -1
      Widget_Control, gainfo.bkgField, Get_Value = temp
      (*gainfo.info.roi).bkgval = temp[0]
      Widget_Control, gainfo.bkgxbegField, Set_Value = -1
      Widget_Control, gainfo.bkgxendField, Set_Value = -1
      Widget_Control, gainfo.bkgybegField, Set_Value = -1
      Widget_Control, gainfo.bkgyendField, Set_Value = -1
      end
    gainfo.stdField: begin
      Widget_Control, gainfo.stdField, Get_Value = temp
      (*gainfo.info.roi).bkg_dev = temp[0]
    end
    gainfo.getbkgButton: begin
      image = (*gainfo.info.dispim)
      case (*gainfo.info.roi).bkgmm of
      0: begin
	 ; set to value - do nothing
         end
      1: begin
	 ; set to mean - check field to use
	 case (*gainfo.info.roi).bkgfd of
	    0: begin
	       ;  error - no field defined
	       test = Widget_Message('No field description given!')
	       end
            1: begin
	       ; check region defined
               Widget_Control, gainfo.bkgxbegField, Get_Value=x1
	       Widget_Control, gainfo.bkgxendField, Get_Value=x2
	       Widget_Control, gainfo.bkgybegField, Get_Value=y1
	       Widget_Control, gainfo.bkgyendField, Get_Value=y2
	       if x1 ge 0 and x1 lt x2 and y1 ge 0 and y1 lt y2 then begin
		 result = moment(image[x1:x2,y1:y2])
		 (*gainfo.info.roi).bkgval = result[0]
		 Widget_Control, gainfo.bkgField, Set_Value=result[0]
		 (*gainfo.info.roi).bkg_dev = sqrt(result[1])
		 Widget_Control, gainfo.stdField, Set_Value=sqrt(result[1])
               endif else begin
		 test=Widget_Message('Invalid region specification')
               endelse
               end
            2: begin
	       ; use roi region
	       x1 = (*gainfo.info.roi).roixorig
	       x2 = (*gainfo.info.roi).roixend
	       y1 = (*gainfo.info.roi).roiyorig
	       y2 = (*gainfo.info.roi).roiyend
	       Widget_Control, gainfo.bkgxbegField, Set_Value=x1
	       Widget_Control, gainfo.bkgxendField, Set_Value=x2
	       Widget_Control, gainfo.bkgybegField, Set_Value=y1
	       Widget_Control, gainfo.bkgyendField, Set_Value=y2
               Widget_Control, gainfo.gaxcenterField, Get_Value = xcen
               Widget_Control, gainfo.gaycenterField, Get_Value = ycen
               Widget_Control, gainfo.gradiusField, Get_Value = radius
	       msksz = size(image)
	       roimsk = intarr(msksz[1],msksz[2])
	       roimsk[*,*] =0
	       roimsk[x1:x2,y1:y2] = 1
	       xx1 = fix(xcen - radius + 0.5)
	       xx2 = fix(xcen + radius + 0.5)
	       yy1 = fix(ycen - radius + 0.5)
	       yy2 = fix(ycen + radius + 0.5)
	       roimsk[xx1:xx2,yy1:yy2] = 0
	       good = where(roimsk eq 1, count)
	       rsz = n_elements(roimsk)
	       str = 'Galasym: ' + string(count) + $
		     ' pixels in roi (out of ' + string(rsz) +  $
		     ') used to compute mean'
               idp3_updatetxt, gainfo.info, str
	       result = moment(image(good))
	       (*gainfo.info.roi).bkgval = result[0]
	       Widget_Control, gainfo.bkgField, Set_Value=result[0]
	       (*gainfo.info.roi).bkg_dev = sqrt(result[1])
	       Widget_Control, gainfo.stdField, Set_Value=sqrt(result[1])
               end
            else:
          endcase
          end
      2: begin
         ; compute median
	 case (*gainfo.info.roi).bkgfd of
	    0: begin
	       ;  error - no field defined
	       test = Widget_Message('No field description given!')
	       end
            1: begin
	       ; check region defined
               Widget_Control, gainfo.bkgxbegField, Get_Value=x1
	       Widget_Control, gainfo.bkgxendField, Get_Value=x2
	       Widget_Control, gainfo.bkgybegField, Get_Value=y1
	       Widget_Control, gainfo.bkgyendField, Get_Value=y2
	       if x1 ge 0 and x1 lt x2 and y1 ge 0 and y1 lt y2 then begin
		 result = median(image[x1:x2,y1:y2], /even)
		 (*gainfo.info.roi).bkgval = result
		 Widget_Control, gainfo.bkgField, Set_Value=result
		 fcount = float(n_elements(image[x1:x2,y1:y2]))
		 std = sqrt(total((image[x1:x2,y1:y2] - result)^2)/(fcount-1))
		 (*gainfo.info.roi).bkg_dev = std
		 Widget_Control, gainfo.stdField, Set_Value=std
               endif else begin
		 test=Widget_Message('Invalid region specification')
               endelse
               end
            2: begin
	       ; use roi region
	       x1 = (*gainfo.info.roi).roixorig
	       x2 = (*gainfo.info.roi).roixend
	       y1 = (*gainfo.info.roi).roiyorig
	       y2 = (*gainfo.info.roi).roiyend
	       Widget_Control, gainfo.bkgxbegField, Set_Value=x1
	       Widget_Control, gainfo.bkgxendField, Set_Value=x2
	       Widget_Control, gainfo.bkgybegField, Set_Value=y1
	       Widget_Control, gainfo.bkgyendField, Set_Value=y2
               Widget_Control, gainfo.gaxcenterField, Get_Value = xcen
               Widget_Control, gainfo.gaycenterField, Get_Value = ycen
               Widget_Control, gainfo.gradiusField, Get_Value = radius
	       msksz = size(image)
	       roimsk = intarr(msksz[1],msksz[2])
	       roimsk[*,*] =0
	       roimsk[x1:x2,y1:y2] = 1
	       cnt = where(roimsk eq 1, gcnt)
	       xx1 = fix(xcen - radius + 0.5)
	       xx2 = fix(xcen + radius + 0.5)
	       yy1 = fix(ycen - radius + 0.5)
	       yy2 = fix(ycen + radius + 0.5)
	       roimsk[xx1:xx2,yy1:yy2] = 0
	       good = where(roimsk eq 1, count)
	       str = 'Galasym: ' + string(count) +  ' pixels in roi (out of ' $
		  + string(gcnt) + ') used to compute median'
               idp3_updatetxt, gainfo.info, str
	       result = median(image[good], /even)
	       (*gainfo.info.roi).bkgval = result
	       Widget_Control, gainfo.bkgField, Set_Value=result
	       fcount = float(n_elements(good))
	       std = sqrt(total((image[good] - result)^2)/(fcount-1))
	       (*gainfo.info.roi).bkg_dev = std
	       Widget_Control, gainfo.stdField, Set_Value=std
               end
            else:
          endcase
	 end

      3: begin
	 ; compute mode
	 case (*gainfo.info.roi).bkgfd of
	    0: begin
	       ;  error - no field defined
	       test = Widget_Message('No field description given!')
	       end
            1: begin
	       ; check region defined
               Widget_Control, gainfo.bkgxbegField, Get_Value=x1
	       Widget_Control, gainfo.bkgxendField, Get_Value=x2
	       Widget_Control, gainfo.bkgybegField, Get_Value=y1
	       Widget_Control, gainfo.bkgyendField, Get_Value=y2
	       if x1 ge 0 and x1 lt x2 and y1 ge 0 and y1 lt y2 then begin
		 result = idp3_calcmode(image[x1:x2,y1:y2])
		 (*gainfo.info.roi).bkgval = result
		 Widget_Control, gainfo.bkgField, Set_Value=result
	         fcount = float(n_elements(image[x1:x2,y1:y2]))
	         std = sqrt(total((image[x1:x2,y1:y2] - result)^2)/(fcount-1))
	         (*gainfo.info.roi).bkg_dev = std
	         Widget_Control, gainfo.stdField, Set_Value=std
               endif else begin
		 test=Widget_Message('Invalid region specification')
               endelse
               end
            2: begin
	       ; use roi region
	       x1 = (*gainfo.info.roi).roixorig
	       x2 = (*gainfo.info.roi).roixend
	       y1 = (*gainfo.info.roi).roiyorig
	       y2 = (*gainfo.info.roi).roiyend
	       Widget_Control, gainfo.bkgxbegField, Set_Value=x1
	       Widget_Control, gainfo.bkgxendField, Set_Value=x2
	       Widget_Control, gainfo.bkgybegField, Set_Value=y1
	       Widget_Control, gainfo.bkgyendField, Set_Value=y2
               Widget_Control, gainfo.gaxcenterField, Get_Value = xcen
               Widget_Control, gainfo.gaycenterField, Get_Value = ycen
               Widget_Control, gainfo.gradiusField, Get_Value = radius
	       msksz = size(image)
	       roimsk = intarr(msksz[1],msksz[2])
	       roimsk[*,*] =0
	       roimsk[x1:x2,y1:y2] = 1
	       cnt = where(roimsk eq 1, gcnt)
	       xx1 = fix(xcen - radius + 0.5)
	       xx2 = fix(xcen + radius + 0.5)
	       yy1 = fix(ycen - radius + 0.5)
	       yy2 = fix(ycen + radius + 0.5)
	       roimsk[xx1:xx2,yy1:yy2] = 0
	       good = where(roimsk eq 1, count)
	       str = 'Galasym: ' + string(count) + ' pixels in roi (out of ' $
		 + string(gcnt) + ') used to compute mode'
               idp3_updatetxt, gainfo.info, str
	       result = idp3_calcmode(image[good])
	       (*gainfo.info.roi).bkgval = result
	       Widget_Control, gainfo.bkgField, Set_Value=result
	       fcount = float(n_elements(good))
	       std = sqrt(total((image[good] - result)^2)/(fcount-1))
	       (*gainfo.info.roi).bkg_dev = std
	       Widget_Control, gainfo.stdField, Set_Value=std
               end
            else:
          endcase
         end
      else:
      endcase
      end
    gainfo.mButtons: begin
      bmethod = event.value
      (*gainfo.info.roi).bkgmm = bmethod
      end
    gainfo.fButtons: begin
      bfield = event.value
      (*gainfo.info.roi).bkgfd = bfield
      end
    gainfo.bkgxbegField: begin
      Widget_Control, gainfo.bkgxbegField, Get_Value = temp
      (*gainfo.info.roi).bkg_xbeg = temp[0]
      end
    gainfo.bkgxendField: begin
      Widget_Control, gainfo.bkgxendField, Get_Value = temp
      (*gainfo.info.roi).bkg_xend = temp[0]
      end
    gainfo.bkgybegField: begin
      Widget_Control, gainfo.bkgybegField, Get_Value = temp
      (*gainfo.info.roi).bkg_ybeg = temp[0]
      end
    gainfo.bkgyendField: begin
      Widget_Control, gainfo.bkgyendField, Get_Value = temp
      (*gainfo.info.roi).bkg_yend = temp[0]
      end
    gainfo.etavalField: begin
      Widget_Control, gainfo.etavalField, Get_Value = temp
      end
    gainfo.computeButton: begin
      Widget_Control, gainfo.bkgxbegField, Get_Value = x1
      Widget_Control, gainfo.bkgxendField, Get_Value = x2
      Widget_Control, gainfo.bkgybegField, Get_Value = y1
      Widget_Control, gainfo.bkgyendField, Get_Value = y2
      Widget_Control, gainfo.gaxcenterField, Get_Value = xcen
      Widget_Control, gainfo.gaycenterField, Get_Value = ycen
      Widget_Control, gainfo.gradiusField, Get_Value = radius
      Widget_Control, gainfo.bkgField, Get_Value = bkg
      Widget_Control, gainfo.stdField, Get_Value = bkg_dev
      image = (*gainfo.info.dispim)
      bkg_crd = fltarr(4)
      imsz = size(image)
      bkg_msk = intarr(imsz[1],imsz[2])
      bkg_msk[*,*] = 0
      bkg_crd[0] = x1
      bkg_crd[1] = x2
      bkg_crd[2] = y1
      bkg_crd[3] = y2
      if x1 gt 0 then bkg_msk[x1:x2,y1:y2] = 1
;      bkg_msk[x1:x2,y1:y2] = 1
      if xcen gt x1 and xcen lt x2 and ycen gt y1 and ycen lt y2 then begin
        xx1 = fix(xcen - radius + 0.5)
	xx2 = fix(xcen + radius + 0.5)
	yy1 = fix(ycen - radius + 0.5)
	yy2 = fix(ycen + radius + 0.5)
	bkg_msk[xx1:xx2,yy1:yy2] = 0
      endif 
      Widget_Control, gainfo.etavalField, Get_Value = temp
      etastr = temp[0]
      if strlen(etastr) eq 0 then begin
        eta_val = -1.0
      endif else begin
	eta_val = float(etastr)
      endelse
      res = idp3_asymmetry(image, xcen, ycen, radius, bkg, bkg_dev, bkg_crd,$
	    bkg_msk, eta_val)
      str = 'Asymmetry: ' + strtrim(string(res[0]),2) + $
	    '   Std Dev: ' + strtrim(string(res[1]),2) + $
	    '   S/N: ' + strtrim(string(res[2]),2)
      (*gainfo.info.roi).asym = res[0]
      (*gainfo.info.roi).asym_dev = res[1]
      (*gainfo.info.roi).asym_snr = res[2]
      (*gainfo.info.roi).asym_cc = res[3]
      (*gainfo.info.roi).asym_eta = res[4]
      Widget_Control, gainfo.reslabel, Set_Value = str
      end
    gainfo.saveButton: begin
      pos = 0
      filename = 'idp3_asym.log'
      title = $
        '    RA          Dec     Asymmetry    Error      Background' + $
        '       Noise        C    ETA'
      temp = file_search(filename, Count = fcount)
      if fcount gt 0 then begin
	pt = 1
	openw, lun, filename, /get_lun, /append
      endif else begin
	pt = 0
	openw, lun, filename, /get_lun
      endelse
      Widget_Control, gainfo.gaxcenterField, Get_Value = xcen
      Widget_Control, gainfo.gaycenterField, Get_Value = ycen
      case (*gainfo.info.roi).bkgmm of
	0: str1 = 'value'
	1: str1 = 'mean'
	2: str1 = 'median'
	3: str1 = 'mode'
	else: str1=''
      endcase
      case (*gainfo.info.roi).bkgfd of
	0: str2 = ''
	1: str2 = 'region'
	2: str2 = 'roi'
	else: str2=''
      endcase
      if ptr_valid((*gainfo.info.images)[gainfo.info.moveimage]) then begin 
        imptr = (*gainfo.info.images)[gainfo.info.moveimage]
        if (*imptr).vis eq 1 then begin
          hdr = [*(*imptr).phead, *(*imptr).ihead]
          if n_elements(hdr) gt 0 then begin
  	    a = sxpar(hdr, 'CRVAL1')
	    b = size(a)
	    if b[0] eq 0 and b[1] eq 5 then begin
              xyad, hdr, xcen, ycen, xra, xdec
              idp3_conra, xra/15.0, rastr
	      rlen = strlen(rastr)
	      rastr = strmid(rastr, 1, rlen-1)
              idp3_condec, xdec, decstr
	      if strmid(decstr, 0, 1) eq '+' then strput, decstr, ' ', 0
	      pos = 1
            endif
          endif
        endif
      endif
      if pos eq 1 then begin
	if pt eq 0 then printf, lun, title
	str = rastr + ' ' + decstr + '  ' + $
	      strtrim(string((*gainfo.info.roi).asym),2) + ' ' + $
	      strtrim(string((*gainfo.info.roi).asym_dev),2) + '  ' + $
	      strtrim(string((*gainfo.info.roi).bkgval),2) + '  ' + $
	      strtrim(string((*gainfo.info.roi).bkg_dev),2) + '  ' + $
	      strtrim(string((*gainfo.info.roi).asym_cc),2) + '  ' + $
	      strtrim(string((*gainfo.info.roi).asym_eta),2)
        printf, lun, str
      endif
      close, lun
      free_lun, lun
      end

    gainfo.helpButton: begin
      tmp = idp3_findfile('idp3_asymmetry.hlp')
      xdisplayfile, tmp
    end
  else:
  endcase

  Widget_Control, event.top, Set_UValue=gainfo
  Widget_Control, gainfo.info.idp3Window, Set_UValue=gainfo.info

end

pro Idp3_Galasym, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_galasym')) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  bkgmm = (*info.roi).bkgmm
  bkgfd = (*info.roi).bkgfd
  bkgval = (*info.roi).bkgval
  bkgstd = (*info.roi).bkg_dev
  eta = (*info.roi).asym_eta
  etastr = strtrim(string(eta),2)
  gaWindow = Widget_base(Title = 'IDP3-ROI Galactic Asymmetry', /Column, $
			 Group_Leader = info.idp3Window, /Grid_Layout, $
			 XOffset = info.wpos.gawp[0], $
			 YOffset = info.wpos.gawp[1])
  info.galasymBase = gaWindow
  Widget_Control, info.idp3Window, Set_UValue = info

  zBase = Widget_Base(gaWindow,/Row)
  gaxcenterField = cw_field(zBase,value=(*info.roi).galxcntr,$
  		   title='xcenter:', $
                   uvalue='xcenter', xsize=10, /Return_Events, /Floating)
  gaycenterField = cw_field(zBase,value=(*info.roi).galycntr,$
		   title='ycenter:', $
                   uvalue='ycenter', xsize=10, /Return_Events, /Floating)
  centbutton = Widget_Button(zBase, Value='Get Centroid')
  rBase = Widget_Base(gaWindow,/Row)
  gradiusField = cw_field(rBase,value=(*info.roi).galradius,$
		   title='Radius of Galaxy:', $
                   uvalue='gradius', xsize=10, /Return_Events, /Floating)
  radiusbutton = Widget_Button(rBase, Value='Get Cross Section Radius')
  bbase = Widget_Base(gaWindow, /Row)
  bkgField = cw_field(bbase,value=bkgval,$
	   title='Background:', uvalue=bkg, xsize=12, $
	   /Return_Events, /Floating)
  stdField = cw_field(bbase,value=bkgstd,uvalue=bkgstd, xsize=12, $
	   title='Std Dev:',/Return_Events, /Floating)
  bmbase = Widget_Base(gaWindow, /Row)
  bmnames = ['Value', 'Mean', 'Median', 'Mode']
  mButtons = cw_bgroup(bmbase, bmnames, row=1, label_left = '    Method:', $
      uvalue='mbutton', set_value=bkgmm, exclusive=1,/no_release)
  bfbase = Widget_Base(gaWindow, /Row)
  bfnames = ['None', 'Region', 'ROI']
  fButtons = cw_bgroup(bfbase, bfnames, row=1, label_left = '    Field: ', $
      uvalue='fbutton', set_value=bkgfd, exclusive=1,/no_release)
  oBase = Widget_Base(gaWindow,/Row)
  bkgxbegField = cw_field(oBase,value=(*info.roi).bkg_xbeg,title=$
	'Region:  xmin', $
        uvalue='bkgxbeg', xsize=10, /Return_Events, /Integer)
  bkgxendField = cw_field(oBase,value=(*info.roi).bkg_xend,title=' xmax', $
        uvalue='bkgxend', xsize=10, /Return_Events, /Integer)
  o2Base = Widget_Base(gaWindow, /Row)
  bkgybegField = cw_field(o2Base,value=(*info.roi).bkg_ybeg,title=$
	'         ymin', $
        uvalue='bkgybeg', xsize=10, /Return_Events, /Integer)
  bkgyendField = cw_field(o2Base,value=(*info.roi).bkg_yend,title=' ymax', $
        uvalue='bkgyend', xsize=10, /Return_Events, /Integer)
  o3Base = Widget_Base(gaWindow, /Row)
  etavalField = cw_field(o3Base,value=etastr, title=' Eta: ', $
	uvalue = 'etaval', xsize=20, /Return_Events, /String)
  bBase = Widget_Base(gaWindow,/Row)
  getbkgButton = Widget_Button(bbase, Value='Get Background')
  computeButton = Widget_Button(bBase, Value='Compute Asymmetry')
  saveButton = Widget_Button(bBase, Value='Save')
  helpButton = Widget_Button(bBase, Value='Help')
  doneButton = Widget_Button(bBase,Value='Done',Event_Pro='GalAsym_Done')
  lbase = Widget_Base(gaWindow, /Row)
  reslabel = Widget_Label(lbase, Value=$
    '                                                           ')

  gainfo = { gaxcenterField   : gaxcenterField, $
             gaycenterField   : gaycenterField, $
	     centButton       : centButton,     $
	     gradiusField     : gradiusField,   $
	     radiusButton     : radiusButton,   $
	     bkgField         : bkgField,       $
	     stdField         : stdField,       $
	     getbkgButton     : getbkgButton,   $
	     mButtons         : mButtons,       $
	     fButtons         : fButtons,       $
             bkgxbegField     : bkgxbegField,   $
             bkgybegField     : bkgybegField,   $
             bkgxendField     : bkgxendField,   $
	     bkgyendField     : bkgyendField,   $
	     etavalField      : etavalField,    $
             computeButton    : computeButton,  $
	     saveButton       : saveButton,     $
	     helpButton       : helpButton,     $
	     reslabel         : reslabel,       $
	     info             : info            }

  Widget_Control, gaWindow, Set_UValue=gainfo
  Widget_Control, gaWindow, /Realize
  Widget_Control, info.idp3Window, Set_UValue=info

  XManager, 'idp3_galasym', gaWindow, /No_Block,  $
	    Event_Handler='GalAsym_Event'
end

