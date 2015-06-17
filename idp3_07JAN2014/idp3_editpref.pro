pro EditPref_Done, event

  geo = Widget_Info(event.top, /geometry)
  Widget_Control, event.top, Get_UValue=epinfo
  Widget_Control, epinfo.info.idp3Window, Get_UValue=tempinfo
  tempinfo.wpos.epwp[0] = geo.xoffset - tempinfo.xoffcorr
  tempinfo.wpos.epwp[1] = geo.yoffset - tempinfo.yoffcorr
  Widget_Control, epinfo.info.idp3Window, Set_UValue=tempinfo
  Widget_Control, event.top, /Destroy

end

pro EditEONS_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=eonsinfo
  Widget_Control, eonsinfo.info.idp3Window, Get_UValue=tempinfo
  eonsinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=eonsinfo

  Case event.id of

    eonsinfo.mshiftField: begin
      ; Change the value of the master shifts for the EONS load list
      Widget_Control, eonsinfo.mshiftField, Get_Value = temp
      eonsinfo.info.master_shifts = temp[0]
    end

    eonsinfo.cmaskField: begin
      ; Change the value of the coronagraphic mask for the EONS load list
      Widget_Control, eonsinfo.cmaskField, Get_Value = temp
      eonsinfo.info.coron_mask = temp[0]
    end

    eonsinfo.cbadpixField: begin
      ; Change the value of the coron_badpix for the EONS load list
      Widget_Control, eonsinfo.cbadpixField, Get_Value = temp
      eonsinfo.info.coron_badpix = temp
    end

    eonsinfo.inradField: begin
      ; Change the value of the inner radius for the EONS load list
      Widget_Control, eonsinfo.inradField, Get_Value = temp
      eonsinfo.info.inner_radius = temp
    end

    eonsinfo.outradField: begin
      ; Change the value of the outer radius for the EONS load list
      Widget_Control, eonsinfo.outradField, Get_Value = temp
      eonsinfo.info.outer_radius = temp
    end

    eonsinfo.mxcenterField: begin
      ; Change the value of the mask x center for the EONS load list
      Widget_Control, eonsinfo.mxcenterField, Get_Value = temp
      eonsinfo.info.mask_xcenter = temp
    end

    eonsinfo.mycenterField: begin
      ; Change the value of the mask y center for the EONS load list
      Widget_Control, eonsinfo.mycenterField, Get_Value = temp
      eonsinfo.info.mask_ycenter = temp

    end

    eonsinfo.helpButton: begin
      tmp = idp3_findfile('idp3_eons.hlp')
      xdisplayfile, tmp
    end

    eonsinfo.doneButton: begin
      Widget_Control, eonsinfo.info.idp3Window, Set_UValue=eonsinfo.info
      Widget_Control, event.top, /Destroy
      return
    end

  endcase

  Widget_Control, event.top, Set_UValue=eonsinfo
  Widget_Control, eonsinfo.info.idp3Window, Set_UValue=eonsinfo.info
end

pro EditEONS, event

@idp3_structs
@idp3_errors
  
  ; Don't pop up if there is already an edit eons preferences widget up.
  if (XRegistered('EditEONS')) then return

  Widget_Control, event.top, Get_UValue=epinfo
  Widget_Control, epinfo.info.idp3Window, Get_UValue=info

  eonsWindow = Widget_Base(Title = 'Edit EONS Parameters', /Column, $
			   Group_Leader = event.top, /Grid_Layout, $
			   XOffset = info.wpos.eewp[0], $
			   YOffset = info.wpos.eewp[1])

  ir = info.inner_radius
  er = info.outer_radius
  ms = info.master_shifts
  cm = info.coron_mask
  mx = info.mask_xcenter
  my = info.mask_ycenter
  cb = info.coron_badpix

  mshiftField = cw_field(eonsWindow,value=ms, $
     title=' Master Shifts File:', $
     uvalue='mshift', xsize=60, /Return_Events,/string)
  cmaskField = cw_field(eonsWindow,value=cm, $
     title='          Mask File:', $
     uvalue='cmask', xsize=60, /Return_Events,/string)
  cbadpixField = cw_field(eonsWindow,value=cb, $
     title='Bad Pixel List File:', $
     uvalue='cbadpix', xsize=60, /Return_Events, /String)
  rowbase = widget_base(eonsWindow, /row)
  inradField = cw_field(rowbase,value=ir, $
     title='Inner Annulus Radius (pixels)', $
     uvalue='inrad', xsize=4, /Return_Events, /Integer)
  outradField = cw_field(rowbase,value=er, $
     title='    Outer Annulus Radius (pixels)', $
     uvalue='outrad', xsize=4, /Return_Events, /Integer)
  row2base = widget_base(eonsWindow, /row)
  mxcenterField = cw_field(row2base,value=mx, $
     title='mask XCenter', $
     uvalue='mxcenter', xsize=4, /Return_Events, /Integer)
  mycenterField = cw_field(row2base,value=my, $
     title='  mask YCenter', $
     uvalue='mycenter', xsize=4, /Return_Events, /Integer)
  padlabel = Widget_Label(row2base, Value='                 ')
  helpButton = Widget_Button(row2base, value='Help', /align_center)
  doneButton = Widget_Button(row2base, value='Close Window', /align_center)
 
  eonsinfo = {    helpButton  :     helpButton,  $
	          doneButton  :     doneButton,  $
	         mshiftField  :    mshiftField,  $
	          cmaskField  :     cmaskField,  $
		cbadpixField  :   cbadpixField,  $
	          inradField  :     inradField,  $
	         outradField  :    outradField,  $
	       mxcenterField  :  mxcenterField,  $
	       mycenterField  :  mycenterField,  $
		        info  :           info   }

  Widget_Control, eonsWindow, Set_UValue=eonsinfo
  Widget_Control, info.idp3Window, Set_UValue=info

  Widget_Control, eonsWindow, /Realize
  XManager, 'EditEONS', eonsWindow, /No_Block,  $
     Event_Handler='EditEONS_Ev'
end

pro EditSIRTF_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=mipsinfo
  Widget_Control, mipsinfo.info.idp3Window, Get_UValue=tempinfo
  mipsinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=mipsinfo

  Case event.id of

    mipsinfo.mzoomField: begin
      ; Change the value of the mips zoom factor to match resolution of PSF
      Widget_Control, mipsinfo.mzoomField, Get_Value = temp
      mipsinfo.info.m_zoom = temp[0]
    end

    mipsinfo.mtbiradField: begin
      ; Change the value of the background inner radius
      Widget_Control, mipsinfo.mtbiradField, Get_Value = temp
      mipsinfo.info.m_tbirad = temp[0]
    end

    mipsinfo.mtboradField: begin
      ; Change the value of the background outer radius
      Widget_Control, mipsinfo.mtboradField, Get_Value = temp
      mipsinfo.info.m_tborad = temp
    end

    mipsinfo.mtradField: begin
      ; Change the value of the target radius
      Widget_Control, mipsinfo.mtradField, Get_Value = temp
      mipsinfo.info.m_trad = temp
    end

    mipsinfo.mpbiradField: begin
      ; Change the value of the PSF background inner radius
      Widget_Control, mipsinfo.mpbiradField, Get_Value = temp
      mipsinfo.info.m_pbirad = temp[0]
    end

    mipsinfo.mpboradField: begin
      ; Change the value of the PSF background outer radius
      Widget_Control, mipsinfo.mpboradField, Get_Value = temp
      mipsinfo.info.m_pborad = temp
    end

    mipsinfo.mpradField: begin
      ; Change the value of the PSF radius
      Widget_Control, mipsinfo.mpradField, Get_Value = temp
      mipsinfo.info.m_prad = temp
    end

    mipsinfo.mpxcenField: begin
      ; Change the x value of the PSF center
      Widget_Control, mipsinfo.mpxcenField, Get_Value = temp
      mipsinfo.info.m_pxcen = temp
    end

    mipsinfo.mpycenField: begin
      ; Change the y value of the PSF center
      Widget_Control, mipsinfo.mpycenField, Get_Value = temp
      mipsinfo.info.m_pycen = temp
    end

    mipsinfo.doneButton: begin
      Widget_Control, mipsinfo.info.idp3Window, Set_UValue=mipsinfo.info
      Widget_Control, event.top, /Destroy
      return
    end

  endcase

  Widget_Control, event.top, Set_UValue=mipsinfo
  Widget_Control, mipsinfo.info.idp3Window, Set_UValue=mipsinfo.info
end

pro EditSIRTF, event

@idp3_structs
@idp3_errors
  
  ; Don't pop up if there is already an edit mips preferences widget up.
  if (XRegistered('EditSIRTF')) then return

  Widget_Control, event.top, Get_UValue=epinfo
  Widget_Control, epinfo.info.idp3Window, Get_UValue=info

  mipsWindow = Widget_Base(Title = 'Edit SIRTF Parameters', /Column, $
			   Group_Leader = event.top, /Grid_Layout, $
			   XOffset = info.wpos.eewp[0], $
			   YOffset = info.wpos.eewp[1])

  mz = info.m_zoom
  mbi = info.m_tbirad
  mbo = info.m_tborad
  mtr = info.m_trad
  mpbi = info.m_pbirad
  mpbo = info.m_pborad
  mpr = info.m_prad
  mpx = info.m_pxcen
  mpy = info.m_pycen

  mzoomField = cw_field(mipsWindow,value=mz, $
     title='Zoom Factor (Science Images):', $
     uvalue='mzoom', xsize=4, /Return_Events,/integer)
  mtradField = cw_field(mipsWindow,value=mtr, $
     title='Target Radius (pixels):', $
     uvalue='mtrad', xsize=8, /Return_Events,/float)
  mtbiradField = cw_field(mipsWindow,value=mbi, $
     title='Target Background Inner Radius (pixels):', $
     uvalue='mbirad', xsize=8, /Return_Events, /float)
  mtboradField = cw_field(mipsWindow,value=mbo, $
     title='Target Background Outer Radius (pixels):', $
     uvalue='mborad', xsize=8, /Return_Events, /float)
  mpradField = cw_field(mipsWindow,value=mpr, $
     title='PSF Radius (pixels):', $
     uvalue='mprad', xsize=8, /Return_Events, /float)
  mpbiradField = cw_field(mipsWindow,value=mpbi, $
     title='PSF Background Inner Radius (pixels):', $
     uvalue='mpbirad', xsize=8, /Return_Events, /float)
  mpboradField = cw_field(mipsWindow,value=mpbo, $
     title='PSF Background Outer Radius (pixels):', $
     uvalue='mpborad', xsize=8, /Return_Events, /float)
  xcenbase = Widget_Base(mipsWindow, /Row)
  mpxcenField = cw_field(xcenbase,value=mpx, $
     title='PSF XCenter:', $
     uvalue='mpxcen', xsize=8, /Return_Events, /float)
  mpycenField = cw_field(xcenbase,value=mpy, $
     title='PSF YCenter:', $
     uvalue='mpycen', xsize=8, /Return_Events, /float)
  doneButton = Widget_Button(mipsWindow, value='Close Window', /align_center)
 
  mipsinfo = {    doneButton  :     doneButton,  $
	          mzoomField  :     mzoomField,  $
	         mtbiradField :    mtbiradField, $
		 mtboradField :    mtboradField, $
	         mpbiradField :    mpbiradField, $
		 mpboradField :    mpboradField, $
	          mtradField  :     mtradField,  $
	          mpradField  :     mpradField,  $
	         mpxcenField  :    mpxcenField,  $
	         mpycenField  :    mpycenField,  $
		        info  :           info   }

  Widget_Control, mipsWindow, Set_UValue=mipsinfo
  Widget_Control, info.idp3Window, Set_UValue=info

  Widget_Control, mipsWindow, /Realize
  XManager, 'EditSIRTF', mipsWindow, /No_Block,  $
     Event_Handler='EditSIRTF_Ev'
end

pro EditPref_Event, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=epinfo
  Widget_Control, epinfo.info.idp3Window, Get_UValue=tempinfo
;  epinfo.info = tempinfo
;  Widget_Control, event.top, Set_UValue=epinfo
;  roi = *epinfo.info.roi

  case event.id of

    epinfo.pixButtons: begin
      ; Change the option for the pixel origin
      temp = event.value
      tempinfo.pixorg = temp
    end
    epinfo.mzoomButtons: begin
      ; Change the option for zooming main window
      temp = event.value
      tempinfo.mdioz = temp
      end
    epinfo.rzoomButtons: begin
      ; Change option for zooming region of interest window
      temp = event.value
      tempinfo.roiioz = temp 
      end
    epinfo.iosButtons: begin
      ; Change option for interpolation on shifting data
      temp = event.value
      tempinfo.ios = temp
      end
    epinfo.zoomfluxButtons: begin
      ; Change option for flux conservation 
      temp = event.value
      tempinfo.zoomflux = temp 
      end
    epinfo.dezoomButtons: begin
      ; Change the option for dezooming main window
      temp = event.value
      tempinfo.mddz = temp 
      end
    epinfo.wcsButtons: begin
      ; Change the option for displaying world coordinates
      temp = event.value
      tempinfo.show_wcs = temp
      end
    epinfo.barButtons: begin
      ; Change the option for displaying the color bar in ROI print
      temp = event.value
      tempinfo.scb = temp
      end
    epinfo.pathButtons: begin
      ; Change the option for displaying file path in show images widget
      temp = event.value
      tempinfo.sip = temp
      end
    epinfo.fitsButtons: begin
      ; Change the option to write simple fits files from multi-extension ones
      temp = event.value
      tempinfo.sfits = temp
      end
    epinfo.plotaxButtons: begin
      ; Change the option for plot axes
      temp = event.value
      tempinfo.plot_xscale = temp
      end
    epinfo.plotayButtons: begin
      ; Change the option for plot y axis
      temp = event.value
      tempinfo.plot_yscale = temp
      end
    epinfo.plotlwButtons: begin
      ; Change the line width for plots
      temp = event.value
      tempinfo.plot_linwid = float(temp+1)
      end
    epinfo.maskgoodField: begin
      ; Change value of good pixels in data mask 
      Widget_Control, epinfo.maskgoodField, Get_Value = temp
      (*tempinfo.roi).maskgood = temp 
      end
    epinfo.bmaskxField: begin
      ; Change x-size of build mask widget 
      Widget_Control, epinfo.bmaskxField, Get_Value = temp
      tempinfo.bmaskxsize = temp 
      end
    epinfo.bmaskyField: begin
      ; Change y-size of build mask widget 
      Widget_Control, epinfo.bmaskyField, Get_Value = temp
      tempinfo.bmaskysize = temp 
      end
    epinfo.exinvalidButtons: begin
      ; Change the option for ignoring zeroes when calculating mean or median
      temp = event.value
      tempinfo.exclude_invalid = temp
      end
    epinfo.invalidField: begin
      ; Set value of an invalid pixel
      Widget_Control, epinfo.invalidField, Get_Value = temp
      tempinfo.invalid = temp
      end
    epinfo.roiboxField: begin
      ; Set value of the ROI half box size 
      Widget_Control, epinfo.roiboxField, Get_Value = temp
      if temp MOD 2 eq 0 then begin
	temp = temp + 1
	str = 'ROI box size must be odd, resetting to ' + $
	  strtrim(string(temp),2)
	stat = Widget_Message(str)
	Widget_Control, epinfo.roiboxField, Set_Value = temp
      endif
      tempinfo.roibox = temp 
      end
    epinfo.histbinField: begin
      ; Set value of histogram bins
      Widget_Control, epinfo.histbinField, Get_Value = temp
      tempinfo.histbins = temp
      end
    epinfo.simxField: begin
      ; Set size of show images widget (X)
      Widget_Control, epinfo.simxField, Get_Value = temp
      tempinfo.showimxsize = temp
      tempinfo.showimscxsize = temp
      end
    epinfo.simyField: begin
      ; Set size of show images widget (Y)
      Widget_Control, epinfo.simyField, Get_Value = temp
      tempinfo.showimysize = temp-1
      tempinfo.showimscysize = temp-1
      end
    epinfo.dimxField: begin
      ; Set size of delete images widget (X)
      Widget_Control, epinfo.dimxField, Get_Value = temp
      tempinfo.delimxsize = temp
      end
    epinfo.dimyField: begin
      ; Set size of delete images widget (Y)
      Widget_Control, epinfo.dimyField, Get_Value = temp
      tempinfo.delimysize = temp
      end
    epinfo.masktolField: begin
      ; Set tolerance for definition of good pixel when shifting, rotating, etc
      Widget_Control, epinfo.masktolField, Get_Value = temp
      tempinfo.masktol = temp
      end
    epinfo.rpbkgxField: begin
      Widget_Control, epinfo.rpbkgxField, Get_Value = temp
      tempinfo.rpbkgxoff = temp
      end
    epinfo.rpbkgyField: begin
      Widget_Control, epinfo.rpbkgyField, Get_Value = temp
      tempinfo.rpbkgyoff = temp
      end
    epinfo.extnamField: begin
      ; set name of image extension to load
      Widget_Control, epinfo.extnamField, Get_Value = temp
      tempinfo.extnam = temp[0]
      end
    epinfo.planField: begin
      ; set plane of 3-D image to load
      Widget_Control, epinfo.planField, Get_Value = temp
      tempinfo.load_planes = temp[0]
      end
    epinfo.imfilterField: begin
      ; Set default value of filter for loading image files
      Widget_Control, epinfo.imfilterField, Get_Value = temp
      tempinfo.imfilter = temp[0]
      end
    epinfo.lsfilterField: begin
      ; Set default value of filter for loading list files
      Widget_Control, epinfo.lsfilterField, Get_Value = temp
      tempinfo.listfilter = temp[0]
      end
    epinfo.lpfilterField: begin
      ; Set default value of filter for loading parameter files
      Widget_Control, epinfo.lpfilterField, Get_Value = temp
      tempinfo.parfilter = temp[0]
      end
    epinfo.namdelimField: begin
      ; Set character for delimiting filename in saveinfo
      ; for systems (MAC) that allow imbedded blanks in name
      Widget_Control, epinfo.namdelimField, Get_Value = temp
      tempinfo.name_delim = temp[0]
      end
    epinfo.hdrcharField: begin
      ; Set character for denoting header lines in text output
      Widget_Control, epinfo.hdrcharField, Get_Value = temp
      tempinfo.header_char = temp[0]
      end
    epinfo.rpradField: begin
      ; Set fixed radius for radial profile
      Widget_Control, epinfo.rpradField, Get_Value = temp
      tempinfo.rpradius = temp
      end
    epinfo.helpButton: begin
    end
  else:
  endcase

  epinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=epinfo
  Widget_Control, epinfo.info.idp3Window, Set_UValue=tempinfo

  idp3_display, tempinfo
      
  ; Update the ShowIm display.
  ; If ShowIm is already running, kill it first.
  if (XRegistered('idp3_showim')) then begin
      geo = Widget_Info(tempinfo.ShowImBase, /geometry)
      tempinfo.wpos.siwp[0] = geo.xoffset - tempinfo.xoffcorr
      tempinfo.wpos.siwp[1] = geo.yoffset - tempinfo.yoffcorr
      Widget_Control, epinfo.info.idp3Window, Set_UValue= tempinfo
      Widget_Control, epinfo.info.ShowImBase, /Destroy
      idp3_showim, {WIDGET_BUTTON,ID:0L,TOP:epinfo.info.idp3Window,$
	  HANDLER:0L,SELECT:0}
      endif

  Widget_Control, epinfo.info.idp3Window, Get_UValue=tempinfo
  epinfo.info = tempinfo
  Widget_Control, event.top, Set_UValue=epinfo

end

pro Idp3_EditPref, event

@idp3_structs
@idp3_errors

  ; Don't pop up if there is already an edit user preferences widget up.
  if (XRegistered('idp3_editpref')) then return

  Widget_Control, event.top, Get_UValue=info
  eptitle = 'IDP3 Edit Preferences -- ' + $
    'MUST hit RETURN in INPUT BOXES to EFFECT change!'
  epWindow = Widget_base(Title = eptitle, /Column, $
			 Group_Leader = event.top, /Grid_Layout, $
			 XOffset = info.wpos.epwp[0], $
			 YOffset = info.wpos.epwp[1])
 
  roi = *info.roi
  mg = roi.maskgood
  rb = info.roibox
  hb = info.histbins
  inv = info.invalid
  simx = info.showimxsize
  simy = info.showimysize
  dimx = info.delimxsize
  dimy = info.delimysize
  bx = info.bmaskxsize
  by = info.bmaskysize
  imf = info.imfilter
  lsf = info.listfilter
  lpf = info.parfilter
  nd = info.name_delim
  hc = info.header_char
  rp = info.rpradius
  mtol = info.masktol
  extnam = info.extnam
  bkgxoff = info.rpbkgxoff
  bkgyoff = info.rpbkgyoff
  dospitzer = info.dospitzer
  doeons = info.doeons
  lp = info.load_planes

  pixbase = Widget_Base(epWindow, /Row, /Frame)
  pixstr = 'Definition of Pixel Origin: ' 
  pixlabel = Widget_Label(pixbase, Value=pixstr)
  pixnames = ['Pixel Center', 'Pixel Lower Left Corner']
  pixvalue = info.pixorg
  pixbuttons = CW_BGroup(pixbase, pixnames, exclusive=1, row=1, $
	       Set_Value=pixvalue, /No_Release)
  mzoombase = Widget_Base(epWindow, /Row, /frame)
  mzoomstr = 'Zoom Interpolation Main Display:       '
  mzoomlabel = Widget_Label(mzoombase, Value=mzoomstr)
  zoomnames = ['Bicubic Sinc', 'Bilinear', 'Pixel Replication', $
	       'Bicubic Spline']
  mzoomvalue = info.mdioz
  mzoomButtons = CW_BGroup(mzoombase, zoomnames, exclusive=1, row=1, $
		 Set_Value=mzoomvalue, /No_Release)
  rzoomstr = 'Zoom Interpolation Region of Interest: '
  rzoombase = Widget_Base(epWindow, /Row, /frame)
  rzoomlabel = Widget_Label(rzoombase, Value=rzoomstr)
  rzoomvalue = info.roiioz
  rzoomButtons = CW_BGroup(rzoombase, zoomnames, exclusive=1, row=1, $
		 Set_Value=rzoomvalue, /No_Release)
  zoomfluxstr = 'Zoom Flux: '
  zoomfluxbase = Widget_Base(epWindow, /Row, /Frame)
  zoomfluxlabel = Widget_Label(zoomfluxbase, Value=zoomfluxstr)
  zoomfluxvalue = info.zoomflux
  zoomfluxnames = ['Flux per detector pixel area', $
		   'Flux per resampled pixel area (Flux Conservation)']
  zoomfluxButtons = CW_BGroup(zoomfluxbase, zoomfluxnames, exclusive=1, row=1, $
		   Set_Value=zoomfluxvalue, /No_Release)
  iosbase = Widget_Base(epWindow, /Row, /frame)
  iosstr = 'Shift Interpolation: '
  ioslabel = Widget_Label(iosbase, Value=iosstr)
  iosnames = ['Bicubic Sinc', 'Bilinear', 'Bicubic Damped Sinc']
  ios = info.ios
  iosButtons = CW_BGroup(iosbase, iosnames, exclusive=1, row=1, $
	       Set_Value = ios, /No_Release)
  dezbase = Widget_Base(epWindow, /Row, /frame)
  dezoomstr = 'Dezoom in Main Display: '
  dezoomlabel = Widget_Label(dezbase, Value=dezoomstr)
  dezoomvalue = info.mddz
  dezoomnames = ['Mean', 'Median', 'Maximum', 'Minimum']
  dezoomButtons = CW_BGroup(dezbase, dezoomnames, exclusive=1, row=1, $
		  Set_Value=dezoomvalue, /No_Release)
  showbase = Widget_Base(epWindow, /Row, /Frame)
  wcsstr = 'Show World Coordinates:'
  wcslabel = Widget_Label(showbase, Value=wcsstr)
  wcsvalue = info.show_wcs
  wcsnames = ['None', 'Sexagesimal', 'Degrees']
  wcsButtons = CW_BGroup(showbase, wcsnames, exclusive=1, row=1, $
		  Set_Value=wcsvalue, /No_Release)
  barstr = '  Annotate ROI & Main Print:'
  barlabel = Widget_Label(showbase, Value=barstr)
  barvalue = info.scb
  prnames = ['None', 'Min', 'Color Bar']
  barButtons = CW_BGroup(showbase, prnames, exclusive=1, row=1, $
		  Set_Value=barvalue, /No_Release)
  imagebase = Widget_Base(epWindow, /Row, /Frame)
  pathstr = 'Display Path [Show/Delete Images]:'
  pathlabel = Widget_Label(imagebase, Value=pathstr)
  pathvalue = info.sip
  ynnames = ['No', 'Yes']
  pathButtons = CW_BGroup(imagebase, ynnames, exclusive=1, row=1, $
		Set_Value=pathvalue, /No_Release)
;  scrollstr = ' Scroll:'
;  scrolllabel = Widget_Label(imagebase, Value=scrollstr)
;  scrollvalue = info.sis
;  scrollButtons = CW_BGroup(imagebase, ynnames, exclusive=1, row=1, $
;		  Set_Value=scrollvalue, /No_Release)
  fitsstr = ' Simple FITS Output [Single HDU]:'
  fitslabel = Widget_Label(imagebase, Value=fitsstr)
  fitsvalue = info.sfits
  fitsButtons = CW_BGroup(imagebase, ynnames, exclusive=1, row=1, $
		Set_Value=fitsvalue, /No_Release)
  loadbase = Widget_Base(epWindow, /Row, /Frame)
  extnamField = cw_field(loadbase, value=extnam, $
	title='Loading Data: FITS Extension Name', $
	uvalue='extnam', xsize=4, /Return_Events, /String)
  planField = cw_field(loadbase, value=lp, $
	title=' Planes [3-D data]', uvalue='lp', xsize=4, $
	/Return_Events, /String)
  plotaxstr = 'Plot Axes Range  X: '
  plotaxbase = Widget_Base(epWindow, /Row, /Frame)
  plotaxlabel = Widget_Label(plotaxbase, Value=plotaxstr)
  plotaxvalue = info.plot_xscale
  plotaxnames = ['Extended', 'Exact']
  plotaxButtons = CW_BGroup(plotaxbase, plotaxnames, exclusive=1, row=1, $
		  Set_Value=plotaxvalue, /No_Release)
  plotaylabel = Widget_Label(plotaxbase, Value=' Y:')
  plotayvalue = info.plot_yscale
  plotayButtons = CW_BGroup(plotaxbase, plotaxnames, exclusive=1, row=1, $
		  Set_Value=plotayvalue, /No_Release)
  plotlwstr = '  Line Width:'
  plotlwlabel = Widget_Label(plotaxbase, Value=plotlwstr)
  plotlwvalue = fix(info.plot_linwid) - 1
  plotlwnames = ['1','2','3','4']
  plotlwButtons = CW_BGroup(plotaxbase, plotlwnames, exclusive=1, row=1, $
		  Set_Value=plotlwvalue, /No_Release)
  ebase1 = Widget_Base(epWindow, /row)
  maskgoodField = cw_field(ebase1,value=mg, $
	 title='ROI Mask Good Value:', $
	 uvalue='maskgood', xsize=2, /Return_Events, /Integer)
  exinvalidstr = ' Exclude Invalid:'
  exinvalidlabel = Widget_Label(ebase1, Value=exinvalidstr)
  exinvalidvalue = info.exclude_invalid
  exinvalidButtons = CW_BGroup(ebase1, ynnames, exclusive=1, row=1, $
		  Set_Value=exinvalidvalue, /No_Release)
  invalidField = cw_field(ebase1, value=inv, $
	title='Invalid Value:', $
	uvalue='inv', xsize=8, /Return_Events, /Floating)
  roiboxField = cw_field(ebase1, value=rb, $
	title='     ROI Box Size (Must be ODD):', $
	uvalue='roibox', xsize=3, /Return_Events, /Integer)
  ebase2 = Widget_Base(epWindow, /row)
  loadstr = 'Filters for Loading Files   Images:'
  imfilterField = cw_field(ebase2, value=imf, title=loadstr, $
		  uvalue='imf', xsize=6, /Return_Events, /String)
  lsfilterField = cw_field(ebase2, value=lsf, title='   Lists:', $
		  uvalue='lsf', xsize=6, /Return_Events, /String)
  lpfilterField = cw_field(ebase2, value=lpf, title='   Parameter Sets:',$
		  uvalue='lpf', xsize=6, /Return_Events, /String)
  histbinField = cw_field(ebase2, value=hb, $
	title='       # Histogram Bins', UValue='nobins', xsize=4, $
	/Return_Events, /Integer)
  ebase3 = Widget_Base(epWindow, /Row)
  namdelimField = cw_field(ebase3, value=nd, $
	 title='Filename delimiter (SavePar):',  $
	 uvalue='ndlim', xsize=2, /Return_Events, /String)
  hdrcharField = cw_field(ebase3, value=hc, $
	 title='Prepend char (Saving Profiles):', $
	 uvalue='hchar', xsize=2, /Return_Events, /String)
  rpradField = cw_field(ebase3, value=rp, title='  Radial Profile Radius:', $
	       uvalue='rprad', xsize=8, /Return_Events, /Floating)
  ebase4 = Widget_Base(epWindow, /Row)
  bmaskxField = cw_field(ebase4, value=bx, $
	  title = 'WIDGET SIZES  Build Mask X:', xsize=4, $
	  uvalue = 'bmx', /Return_Events, /Integer)
  bmaskyField = cw_field(ebase4, value=by, $
	  title = 'Y:', xsize=4, $
	  uvalue = 'bmy', /Return_Events, /Integer)
  simxField = cw_field(ebase4, value=simx, $
	 title=' Show Images X:', $
	 uvalue='simx', xsize=4, /Return_Events, /Integer)
  simyField = cw_field(ebase4, value=simy, title=' Y:', $
	 uvalue='simy', xsize=4, /Return_Events, /Integer)
  dimxField = cw_field(ebase4, value=dimx, $
	 title=' Delete Images X:', $
	 uvalue='dimx', xsize=4, /Return_Events, /Integer)
  dimyField = cw_field(ebase4, value=dimy, title=' Y:', $
	 uvalue='dimy', xsize=4, /Return_Events, /Integer)
  lastbase = Widget_Base(epWindow, /Row)
  masktolField = cw_field(lastbase, value=mtol, title='Mask Tolerance(+-):', $
	 uvalue='mtol', xsize=4, /Return_Events, /Float)
  rpbkgxField = cw_field(lastbase, value=bkgxoff, xsize=8, $
         title='RP Background XOffset',uvalue='bkgxoff', /Return_Events, /Float)
  rpbkgyField = cw_field(lastbase, value=bkgyoff, xsize=8, $
         title='YOffset', uvalue='bkgyoff', /Return_Events, /Float)
  if doeons eq 1 then eonsButton = Widget_Button(lastbase, $
           Value='EONS Parameters', Event_Pro='EditEONS')
  if dospitzer eq 1 then mipsButton = Widget_Button(lastbase, $
           Value='Spitzer Parameters', Event_Pro='EditSpitzer')
  if doeons eq 0 or dospitzer eq 0 then begin
    helpButton = Widget_Button(lastbase, Value='Help', /align_center)
    doneButton = Widget_Button(lastbase,Value='Close Window', $
      Event_Pro='EditPref_Done', /align_center)
  endif else begin
    helpButton = Widget_Button(epWindow, Value='Help', /align_center)
    doneButton = Widget_Button(epWindow,Value='Close Window', $
      Event_Pro='EditPref_Done', /align_center) 
  endelse

    epinfo = { $
		    pixButtons : pixbuttons,      $
		  mzoomButtons : mzoombuttons,    $
		  rzoomButtons : rzoomButtons,    $
	       zoomfluxButtons : zoomfluxButtons, $
		    iosButtons : iosButtons,      $
		 dezoomButtons : dezoomButtons,   $
		    wcsButtons : wcsButtons,      $
		    barButtons : barButtons,      $
		   pathButtons : pathButtons,     $
;		 scrollButtons : scrollButtons,   $
	      exinvalidButtons : exinvalidButtons,$
		   fitsButtons : fitsButtons,     $
		 plotaxButtons : plotaxButtons,   $
		 plotayButtons : plotayButtons,   $
	         plotlwButtons : plotlwButtons,   $
		    helpButton : helpButton,      $
                 maskgoodField : maskgoodField,   $
		  invalidField : invalidField,    $
		   roiboxField : roiboxField,     $
                  histbinField : histbinField,    $
		     simxField : simxField,       $
		     simyField : simyField,       $
		     dimxField : dimxField,       $
		     dimyField : dimyField,       $
		   bmaskxField : bmaskxField,     $
		   bmaskyField : bmaskyField,     $
                  masktolField : masktolField,    $
                   extnamField : extnamField,     $
		     planField : planField,       $
	         imfilterField : imfilterField,   $
                 lsfilterField : lsfilterField,   $
	         lpfilterField : lpfilterField,   $
                 namdelimField : namdelimField,   $
	  	  hdrcharField : hdrcharField,    $
		    rpradField : rpradField,      $
                   rpbkgxField : rpbkgxField,     $
                   rpbkgyField : rpbkgyField,     $ 
	                  info : info             }

  Widget_Control, epWindow, Set_UValue=epinfo

  info.epBase = epWindow
  Widget_Control, info.idp3Window, Set_UValue=info

  Widget_Control, epWindow, /Realize
  XManager, 'idp3_EditPref', epWindow, /No_Block,  $
	    Event_Handler='EditPref_Event'

;  Widget_Control, info.idp3Window, Set_UValue=info
end
