pro selinst_event, sel_event
COMMON selinput, instr, names
  maxnames = n_elements(names) - 1
  Widget_Control, sel_event.id, Get_UValue = str
  if str eq 'cancel' then begin
    Widget_Control, sel_event.top, /Destroy
    return
  endif
  indx = sel_event.index
  if indx ge 0 and indx le maxnames then instr=names[indx] else instr='     '
  Widget_Control, sel_event.top, /Destroy
end

pro selinst, event

COMMON selinput, instr, names

  if XRegistered('selinst') then return
  select_base = Widget_Base(/Column,title='Instrument/Detector', $
		Group_Leader=event.top, /Modal)
  names = ['NICMOS-1', 'NICMOS-2', 'NICMOS-3', 'STIS-CCD', $
	   'WFPC2-1',  'WFPC2-2',  'WFPC2-3',  'WFPC2-4', 'MIPS-1', $
	   'MIPS-2', 'MIPS-3', 'MIPS-4', 'MIPS-5', 'IRAC-1', 'IRAC-2', $
	   'IRAC-3', 'IRAC-4', 'OTHER']
  num = n_elements(names)
  list = Widget_List(select_base, Value = names, UValue = 'list', $
	 YSize = num, XSize = 25)
  cancel = Widget_Button(select_base, Value='Cancel',UValue='cancel')
  Widget_Control, select_base, /Realize
  XManager, 'selinst', select_base, Event_Handler = 'selinst_event' 
end

pro SetPixscl_Event, event

COMMON selinput, instr, names
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=spinfo
  Widget_Control, spinfo.info.idp3Window, Get_UValue=tempinfo
  spinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=spinfo

  imptr = (*spinfo.info.images)[spinfo.info.moveimage]
  temphead = [*(*imptr).phead, *(*imptr).ihead]
  od = sxpar(temphead, 'DATE-OBS')
  ot = sxpar(temphead, 'TIME-OBS')
  odsz = size(od)
  otsz = size(ot)

  case event.id of

    spinfo.ixField: begin
      ; Update X pixel scale for input 
      Widget_Control, spinfo.ixField, Get_Value = tempstr
      temp = double(tempstr[0])
      if temp le 0.0 then $
	stat = Widget_Message('Invalid input X scale')
      xpix = temp
      end

    spinfo.iyField: begin
      ; Update Y pixel scale for input 
      Widget_Control, spinfo.iyField, Get_Value = tempstr
      temp = double(tempstr[0])
      if temp le 0.0 then $
	stat = Widget_Message('Invalid input Y scale')
      ypix = temp
      end

    spinfo.oxField: begin
      ; Update X pixel scale for output 
      Widget_Control, spinfo.oxField, Get_Value = tempstr
      temp = double(tempstr[0])
      if temp le 0.0 then $
	stat = Widget_Message('Invalid output X scale')
      nxpix = temp
      end

    spinfo.oyField: begin
      ; Update Y pixel scale for output 
      Widget_Control, spinfo.oyField, Get_Value = tempstr
      temp = double(tempstr[0])
      if temp le 0.0 then $
	stat = Widget_Message('Invalid output Y scale')
      nypix = temp
      end

    spinfo.inField: begin
      ; Get input instrument/detector name
      Widget_Control, spinfo.inField, Get_Value = temp
      oistr = strtrim(temp[0],2)
      oin = strsplit(oistr, '-', /extract)
      if n_elements(oin) ne 2 then oin = strsplit(oistr, ' ', /extract)
      if n_elements(oin) ne 2 then begin
        if strlowcase(oin[0]) ne 'other' then begin 
	  stat = Widget_Message('Improper input string')
	  xpix = 1.0d0
	  ypix = 1.0d0
	  xpixstr = string(xpix, '$(f12.9)')
	  ypixstr = string(ypix, '$(f12.9)')
          Widget_Control, spinfo.oxField, Set_Value = xpixstr
          Widget_Control, spinfo.oyField, Set_Value = ypixstr
        endif
      endif else begin
        instr = strupcase(oin[0])
        idet = fix(oin[1])
        if odsz[1] eq 7 and otsz[1] eq 7 $
	   then idp3_getplate, instr, idet, xpix, ypix,odate=od,otime=ot $
	   else idp3_getplate, instr, idet, xpix, ypix
        xpixstr = string(xpix, '$(f12.9)')
	ypixstr = string(ypix, '$(f12.9)')
        Widget_Control, spinfo.oxField, Set_Value = xpixstr
        Widget_Control, spinfo.oyField, Set_Value = ypixstr
      endelse 
      end

    spinfo.outField: begin
      ; Get output instrument/detector name
      Widget_Control, spinfo.inField, Get_Value = temp
      oistr = strtrim(temp[0],2)
      Widget_Control, spinfo.outField, Get_Value = temp
      oostr = strtrim(temp[0],2)
      oon = strsplit(oostr, '-', /extract)
      if n_elements(oon) ne 2 then oon = strsplit(oostr, ' ', /extract)
      if n_elements(oon) ne 2 then begin
	if strlowcase(oon[0]) ne 'other' then begin
	  stat = Widget_Message('Improper output string')
	  xpix = 1.0d0
	  ypix = 1.0d0
	  xpixstr = string(xpix, '$(f12.9)')
	  ypixstr = string(ypix, '$(f12.9)')
          Widget_Control, spinfo.oxField, Set_Value = xpixstr
          Widget_Control, spinfo.oyField, Set_Value = ypixstr
        endif
      endif else begin
	onstr = strupcase(oon[0])
        odet = fix(oon[1])
	if strlowcase(oostr) eq strlowcase(oistr) then begin
	  Widget_Control, spinfo.ixField, Get_Value = xpixstr
	  Widget_Control, spinfo.iyField, Get_Value = ypixstr
          xpix = double(xpixstr[0])
	  ypix = double(ypixstr[0])
	  if xpix le 0. or ypix le 0. then begin
	    if odsz[1] eq 7 and otsz[1] eq 7 $
	       then idp3_getplate, onstr, odet, xpix, ypix,odate=od,otime=ot $
	       else idp3_getplate, onstr, odet, xpix, ypix
            xpixstr = string(xpix, '$(f12.9)')
	    ypixstr = string(ypix, '$(f12.9)')
	    Widget_Control, spinfo.ixField, Set_Value = xpixstr
	    Widget_Control, spinfo.iyField, Set_Value = ypixstr
            Widget_Control, spinfo.oxField, Set_Value = xpixstr
            Widget_Control, spinfo.oyField, Set_Value = xpixstr
          endif
        endif else begin
          if odsz[1] eq 7 and otsz[1] eq 7 $
	    then idp3_getplate, onstr, odet, xpix, ypix, odate=od, otime=ot $
	    else idp3_getplate, onstr, odet, xpix, ypix
          xpixstr = string(xpix, '$(f12.9)')
	  ypixstr = string(ypix, '$(f12.9)')
          Widget_Control, spinfo.oxField, Set_Value = xpixstr
          Widget_Control, spinfo.oyField, Set_Value = ypixstr
        endelse
      endelse
      end

    spinfo.selinButton: begin
      selinst, event
      Widget_Control, spinfo.inField, Set_Value = instr
      oistr = strtrim(instr,2)
      oin = strsplit(oistr, '-', /extract)
      if n_elements(oin) ne 2 then begin
        if strlowcase(oin[0]) ne 'other' then begin
	  stat = Widget_Message('Improper input string')
	  xpix = 1.0d0
	  ypix = 1.0d0
	  xpixstr = string(xpix, '$(f12.9)')
	  ypixstr = string(ypix, '$(f12.9)')
          Widget_Control, spinfo.ixField, Set_Value = xpixstr
          Widget_Control, spinfo.iyField, Set_Value = ypixstr
        endif
      endif else begin
        instr = strupcase(oin[0])
        sdet = oin[1]
        if odsz[1] eq 7 and otsz[1] eq 7 $
	   then idp3_getplate, instr, sdet, xpix, ypix,odate=od,otime=ot $
	   else idp3_getplate, instr, sdet, xpix, ypix
        xpixstr = string(xpix, '$(f12.9)')
	ypixstr = string(ypix, '$(f12.9)')
        Widget_Control, spinfo.ixField, Set_Value = xpixstr
        Widget_Control, spinfo.iyField, Set_Value = ypixstr
      endelse 
    end

    spinfo.calcButton: begin
      hdr = [*(*imptr).phead, *(*imptr).ihead]
      if (*imptr).valid_wcs gt 0 then begin
        sxaddpar, hdr, 'CD1-1', (*imptr).acd11
        sxaddpar, hdr, 'CD1-2', (*imptr).acd12
        sxaddpar, hdr, 'CD2-1', (*imptr).acd21
        sxaddpar, hdr, 'CD2_2', (*imptr).acd22
        getrot, hdr, rot, cdelt
        xpixstr = string(abs(cdelt[0]) * 3600.0d0, '$(f12.9)')
        ypixstr = string(abs(cdelt[1]) * 3600.0d0, '$(f12.9)')
        Widget_Control, spinfo.ixField, Set_Value=xpixstr
        Widget_Control, spinfo.iyField, Set_Value=ypixstr
        str = 'SetPixScl: ' + xpixstr + '  ' + ypixstr + string(rot*(-1.))
      endif else str = 'No valid WCS - Cannot compute pixel scale!'
      idp3_updatetxt, spinfo.info, str
    end

    spinfo.seloutButton: begin
      selinst, event
      Widget_Control, spinfo.inField, Get_Value = temp
      oistr = strtrim(temp[0],2)
      Widget_Control, spinfo.outField, Set_Value = instr
      oostr = strtrim(instr,2)
      oon = strsplit(oostr, '-', /extract)
      if n_elements(oon) ne 2 then begin
	if strlowcase(oon[0]) ne 'other' then begin
	  xpix = 1.0d0
	  ypix = 1.0d0
	  xpixstr = string(xpix, '$(f12.9)')
	  ypixstr = string(ypix, '$(f12.9)')
          Widget_Control, spinfo.oxField, Set_Value = xpixstr
          Widget_Control, spinfo.oyField, Set_Value = ypixstr
	  stat = Widget_Message('Improper output string')
        endif
      endif else begin
	onstr = strupcase(oon[0])
        odet = oon[1]
	if strlowcase(oostr) eq strlowcase(oistr) then begin
	  Widget_Control, spinfo.ixField, Get_Value = xpixstr
	  Widget_Control, spinfo.iyField, Get_Value = ypixstr
	  xpix = double(xpixstr[0])
	  ypix = double(ypixstr[0])
	  str = 'SetPixScl: ' + xpixstr + string(xpix) + '  ' +  ypixstr + $
		string(ypix)
          idp3_updatetxt, spinfo.info, str
	  if xpix le 0.0d0 or ypix le 0.0d0 then begin
	    if odsz[1] eq 7 and otsz[1] eq 7 $
	       then idp3_getplate, onstr, odet, xpix, ypix,odate=od,otime=ot $
	       else idp3_getplate, onstr, odet, xpix, ypix
            xpixstr = string(xpix, '$(f12.9)')
	    ypixstr = string(ypix, '$(f12.9)')
	    Widget_Control, spinfo.ixField, Set_Value = xpixstr
	    Widget_Control, spinfo.iyField, Set_Value = ypixstr
          endif
	  Widget_Control, spinfo.oxField, Set_Value = xpixstr
	  Widget_Control, spinfo.oyField, Set_Value = xpixstr
        endif else begin
          if odsz[1] eq 7 and otsz[1] eq 7 $
	    then idp3_getplate, onstr, odet, xpix, ypix, odate=od, otime=ot $
	    else idp3_getplate, onstr, odet, xpix, ypix
          xpixstr = string(xpix, '$(f12.9)')
	  ypixstr = string(ypix, '$(f12.9)')
          Widget_Control, spinfo.oxField, Set_Value = xpixstr
          Widget_Control, spinfo.oyField, Set_Value = ypixstr
        endelse
      endelse
    end

    spinfo.xsField: begin
      ; set x scale factor
      Widget_Control, spinfo.xsField, Get_Value=temp
      if temp le 0.0 then begin
	stat = Widget_Message('Invalid X scale factor')
      endif
    end

    spinfo.ysField: begin
      ; set y scale factor
      Widget_Control, spinfo.ysField, Get_Value=temp
      if temp le 0.0 then begin
	stat = Widget_Message('Invalid Y scale factor')
      endif
    end

    spinfo.multButton: begin
      Widget_Control, spinfo.xsField, Get_Value=xtemp
      Widget_Control, spinfo.ysField, Get_Value=ytemp
      Widget_Control, spinfo.ixField, Get_Value=xpixstr
      Widget_Control, spinfo.iyField, Get_Value=ypixstr
      xpix = double(xpixstr[0])
      ypix = double(ypixstr[0])
      if xtemp le 0.0 or ytemp le 0.0 then begin
	stat = Widget_Message('Invalid scale factor')
      endif else begin
        if xpix le 0.0 or ypix le 0.0 then begin
	  stat = Widget_Message('Invalid input scale')
        endif else begin
	  nxpix = xtemp * xpix
	  nypix = ytemp * ypix
	  nxpixstr = string(nxpix, '$(f12.9)')
	  nypixstr = string(nypix, '$(f12.9)')
	  Widget_Control, spinfo.oxField, Set_Value=nxpixstr
	  Widget_Control, spinfo.oyField, Set_Value=nypixstr
        endelse
      endelse
    end

    spinfo.doneButton: begin  
      Widget_Control, spinfo.ixField, Get_Value = xpixstr
      Widget_Control, spinfo.iyField, Get_Value = ypixstr
      Widget_Control, spinfo.oxField, Get_Value = nxpixstr
      Widget_Control, spinfo.oyField, Get_Value = nypixstr
      Widget_Control, spinfo.inField, Get_Value = temp
      xpix = double(xpixstr[0])
      ypix = double(ypixstr[0])
      nxpix = double(nxpixstr[0])
      nypix = double(nypixstr[0])
      instr = strtrim(temp[0],2)
      print, xpixstr, xpix
      print, ypixstr, ypix
      print, nxpixstr, nxpix
      print, nypixstr, nypix
      imptr = (*spinfo.info.images)[spinfo.info.moveimage]
      if xpix le 0. or ypix le 0. then begin
        stat = Widget_Message('Input pixel scales not defined')
        (*imptr).xplate = 0.d0
        (*imptr).yplate = 0.d0
	(*imptr).xpscl = 1.0d0
      endif else begin
        str = 'SetPixScl: Image Pixel Scale (Input ): ' + $
	      string(xpix) + string(ypix)
        idp3_updatetxt, spinfo.info, str
        (*imptr).xplate = xpix
        (*imptr).yplate = ypix
      endelse
      if nxpix le 0. or nypix le 0. then begin
        stat = Widget_Message('Output pixel scales not defined')
        (*imptr).nxplate = 0.d0
        (*imptr).nyplate = 0.d0
	(*imptr).ypscl = 1.0d0
      endif else begin
        str = '                  (Output): ' + string(nxpix) + string(nypix)
	idp3_updatetxt, spinfo.info, str
        (*imptr).nxplate = nxpix
        (*imptr).nyplate = nypix
      endelse
      if xpix gt 0. and ypix gt 0. and nxpix gt 0. and nypix gt 0. then begin
        if (*imptr).valid_wcs gt 0 then begin
          hdr = [*(*imptr).phead, *(*imptr).ihead]
          sxaddpar, hdr, 'CD1-1', (*imptr).acd11
          sxaddpar, hdr, 'CD1-2', (*imptr).acd12
          sxaddpar, hdr, 'CD2-1', (*imptr).acd21
          sxaddpar, hdr, 'CD2_2', (*imptr).acd22
          getrot, hdr, rot, cdelt
          cxpix = abs(cdelt[0]) * 3600.0d0
          cypix = abs(cdelt[1]) * 3600.0d0
          xpct = (abs(cxpix - xpix) / cxpix) * 100.0d0
          ypct = (abs(cypix - ypix) / cypix) * 100.0d0
          if xpct le 1.0 and ypct le 1.0 then begin
	    (*imptr).xpscl = xpix/nxpix
	    (*imptr).xplate = nxpix
	    str = 'SetPixScl: Changing x pixel scale: ' + $
		string(xpix) + string(nxpix) + string((*imptr).xpscl)
            idp3_updatetxt, spinfo.info, str
	    (*imptr).ypscl = ypix/nypix
	    (*imptr).yplate = nypix
	    str = 'SetPixScl: Changing y pixel scale: ' + $
		string(ypix) + string(nypix) + string((*imptr).ypscl)
            idp3_updatetxt, spinfo.info, str
          endif else begin
            str = 'Input pixel scale varies by more than 1% from WCS, aborting!'
            stat = Widget_Message(str)
          endelse
        endif else begin
	  if strlowcase(instr) eq 'other' or (*imptr).oxplate le 0. then begin
	    (*imptr).xpscl = xpix/nxpix
	    (*imptr).xplate = nxpix
	    str = 'SetPixScl: Changing x pixel scale: ' + $
		string(xpix) + string(nxpix) + string((*imptr).xpscl)
            idp3_updatetxt, spinfo.info, str
	    (*imptr).ypscl = ypix/nypix
	    (*imptr).yplate = nypix
	    str = 'SetPixScl: Changing y pixel scale: ' + $
		string(ypix) + string(nypix) + string((*imptr).ypscl)
            idp3_updatetxt, spinfo.info, str
          endif else begin
	    (*imptr).xpscl = (*imptr).oxplate/nxpix
	    (*imptr).xplate = nxpix
	    str = 'SetPixScl: Changing x pixel scale: ' + $
		string((*imptr).oxplate) + string(nxpix) + $
	        string((*imptr).xpscl)
            idp3_updatetxt, spinfo.info, str
            (*imptr).ypscl = (*imptr).oyplate/nypix
	    (*imptr).yplate = nypix
	    str ='SetPixScl: Changing y pixel scale: ' + $
	       string((*imptr).oyplate) + string(nypix) + $
	       string((*imptr).ypscl)
            idp3_updatetxt, spinfo.info, str
          endelse
        endelse
        Widget_Control, event.top, Set_UValue=spinfo
        Widget_Control, spinfo.info.idp3Window, Set_UValue=spinfo.info
	Widget_Control, event.top, /Destroy
      endif else begin
	  stat = Widget_Message('Scales not defined, use cancel to quit')
      endelse
    end

    spinfo.cancelButton: begin
      cxpix = (*imptr).xplate
      cypix = (*imptr).yplate
      if cxpix gt 0.0 and abs(cxpix - spinfo.xplate) gt 0.001 or $
	 cypix gt 0.0 and abs(cypix - spinfo.yplate) gt 0.001 then begin
         str = 'SetPixScl: Original Pixel Scale: ' + $
	       string(spinfo.xplate) + string(spinfo.yplate)
         idp3_updatetxt, spinfo.info, str
         str = 'SetPixScl:  Current Pixel Scale: ' + $
	       string(cxpix) + string(cypix)
         idp3_updatetxt, spinfo.info, str
      endif else begin
	 str = 'SetPixScl: Original Pixel Scale: ' + $
	       string(spinfo.xplate) + string(spinfo.yplate)
         idp3_updatetxt, spinfo.info, str
      endelse
      Widget_Control, event.top, /Destroy
    end

    spinfo.helpButton: begin
      if tempinfo.pdf_viewer eq '' then begin
	tmp = idp3_findfile('idp3_setpixscl.hlp')
	xdisplayfile, tmp
      endif else begin
	tmp = idp3_findfile('idp3_pixelscale.pdf')
	str = tempinfo.pdf_viewer + ' ' + tmp
	if !version.os eq 'darwin' then str = 'open -a ' + str
	spawn, str
      endelse
    end
  else:
  endcase

end

pro Idp3_SetPixscl, event

@idp3_structs
@idp3_errors

  if (XRegistered('idp3_setpixscl')) then return

  Widget_Control, event.top, Get_UValue=spinfo

  imptr = (*spinfo.info.images)[spinfo.info.moveimage]
  str = (*imptr).instrume + '-' + (*imptr).detector
  xplate = (*imptr).oxplate
  yplate = (*imptr).oyplate
  if (*imptr).nxplate gt 0.0d0 $
    then nxplate = (*imptr).nxplate else nxplate = 0.0d0
  if (*imptr).nyplate gt 0.0d0 $
    then nyplate = (*imptr).nyplate else nyplate = 0.0d0
  xplatestr = string(xplate, '$(f12.9)')
  yplatestr = string(yplate, '$(f12.9)')
  nxplatestr = string(nxplate, '$(f12.9)')
  nyplatestr = string(nyplate, '$(f12.9)')

  spWindow = Widget_base(Title = 'IDP3 Set Pixel Scales', /Row, $
			 Group_Leader = event.top, /Modal, /Grid_Layout, $
			 XOffset = spinfo.info.wpos.scwp[0], $
			 YOffset = spinfo.info.wpos.scwp[1])
  col1base = Widget_Base(spWindow, /Column)
  label1 = Widget_Label(col1base, Value=' Input Instrument/Detector   ')
  r2base = Widget_Base(col1base, /Row)
  inField = cw_field(r2base, value=str, title='Name:', $
	    UValue = 'inf', xsize=10, /Return_Events, /String)
  selinButton = Widget_Button(r2base, Value='Select', /align_center)
  calcButton = Widget_Button(col1base, Value='Set Pixel Scale from WCS', $
      /align_center)
  label3 = Widget_Label(col1base, Value = 'Pixel Scale')
  r3base = Widget_Base(col1base, /Row)
  xlab0  = Widget_Label(r3base, Value='X:')
  ixField = Widget_Text(r3base,Value=xplatestr, $
                    uvalue='ixf', xsize=12, /Edit)
  ylab0  = Widget_Label(r3base, Value='Y:')
  iyField = Widget_Text(r3base,Value=yplatestr, $
                    uvalue='iyf', xsize=12, /Edit)
  label4 = Widget_Label(col1base, Value='Pixel Scale Factors')
  r4base = Widget_Base(col1base, /Row)
  xsField = cw_field(r4base, value=1.0, title='X', $
	       uvalue = 'xsf', xsize=7, /Return_Events, /Floating)
  ysField = cw_field(r4base, value=1.0, title='Y', $
	       uvalue = 'ysf', xsize=7, /Return_Events, /Floating)
  multButton = Widget_Button(r4base, Value='Multiply', /align_center)
  col2base = Widget_Base(spWindow, /Column)
  label5 = Widget_Label(col2base, Value=' Output Instrument/Detector')
  r6base = Widget_base(col2base, /Row)
  outField = cw_field(r6base, value='       ', title='Name:', $
	    UValue = 'onf', xsize=10, /Return_Events, /String)
  seloutButton = Widget_Button(r6base, Value='Select', /align_center)
  label66 = Widget_Label(col2base, Value='  ')
  label6 = Widget_Label(col2base, Value = 'Pixel Scale')
  r7base = Widget_Base(col2base, /Row)
  xlab1  = Widget_Label(r7base, Value='X:')
  oxField = Widget_Text(r7base,Value=nxplatestr, $
                    uvalue='oxf', xsize=12, /Edit)
  ylab1  = Widget_Label(r7base, Value='Y:')
  oyField = Widget_Text(r7base,Value=nyplatestr, $
                    uvalue='oyf', xsize=12, /Edit)
  r8base = Widget_Base(col2base, /Row)
  label0 = Widget_Label(r8base, Value='              ')
  r9base = Widget_Base(col2base, /Row)
  label11 = Widget_Label(r9base, Value='        ')
  doneButton = Widget_Button(r9base,Value='Apply')
  cancelButton = Widget_Button(r9base,Value='Cancel')
  helpButton = Widget_Button(r9base,Value='Help')

  

  scinfo = { ixField     : ixField,      $
             iyField     : iyField,      $
	     inField     : inField,      $
	     selinButton : selinButton,  $
	     calcButton  : calcButton,   $
	     oxField     : oxField,      $
	     oyField     : oyField,      $
	     outField    : outField,     $
	     seloutButton: seloutButton, $
	     xsField     : xsField,      $
	     ysField     : ysField,      $
	     multButton  : multButton,   $
	     doneButton  : doneButton,   $
	     helpButton  : helpButton,   $
	     cancelButton: cancelButton, $
	     xplate      : xplate,       $
	     yplate      : yplate,       $
	     info        : spinfo.info  }

  Widget_Control, spWindow, Set_UValue=scinfo

  Widget_Control, spWindow, /Realize
  XManager, 'idp3_setpixscl', spWindow, /No_Block,  $
	    Event_Handler='Setpixscl_Event'
end

