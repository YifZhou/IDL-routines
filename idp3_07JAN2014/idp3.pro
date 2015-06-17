pro Idp3_Nothing, event
  a=1
end

pro Idp3_Blink, event
@idp3_errors
  ; Just get the info structure and set the counter.
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  info.bcount = 0
  info.bimcount = 0
  Widget_Control, info.gbase, TIMER=info.fdelay
  Widget_Control, info.idp3Window, Set_UValue=info
end

pro Idp3_StopBlink, event
  ; Turn off blinking
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  info.bcount = -1
  info.bimcount = -1
  Widget_Control, info.idp3Window, Set_UValue=info
end

pro Idp3_Resize, event
@idp3_errors
  ; The user resized the main window so resize the draw window appropriately.
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info
  if info.scrollmain eq 0 then begin
    Widget_Control, info.idp3Draw, Draw_XSize = event.x - 5, $
  				   Draw_YSize = event.y - 40

    ; Save the new size in the info structure (tweeks for menu bar)
    info.drawxsize = event.x - 5
    info.drawysize = event.y - 40
    Widget_Control, info.idp3Window, Set_UValue=info
  endif else begin
    stat = Widget_Message('Cannot update image size for scrolled display')
  endelse
  ; Update graphics display
  idp3_display,info

  Widget_Control, info.idp3Window, Set_UValue=info
end


pro Idp3_Exit, event
  Widget_Control, event.top, /Destroy
end


pro Idp3_Helpoview, event
   Widget_Control, event.top, Get_UValue=tinfo
   Widget_Control,tinfo.idp3Window, Get_UValue = info
   if info.pdf_viewer eq '' then begin
     tmp = idp3_findfile('idp3_oview.hlp')
     xdisplayfile, tmp
   endif else begin
     tmp = idp3_findfile('idp3_overview.pdf')
     str = info.pdf_viewer + ' ' + tmp
     if !version.os eq 'darwin' then str = 'open -a ' + str
     spawn, str
   endelse
end

pro Idp3_Helpmain, event
   Widget_Control, event.top, Get_UValue=tinfo
   Widget_Control,tinfo.idp3Window, Get_UValue = info
   if info.pdf_viewer eq '' then begin
     tmp = idp3_findfile('idp3_maindisplay.hlp')
     xdisplayfile, tmp
   endif else begin
     tmp = idp3_findfile('idp3_maindisplay.pdf')
     str = info.pdf_viewer + ' ' + tmp
     if !version.os eq 'darwin' then str = 'open -a ' + str
     spawn, str
   endelse
end


; Idp3_Draw -- Handle events in the main draw window.
;
pro Idp3_Draw, event
@idp3_errors
  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control,tinfo.idp3Window, Get_UValue = info
  if not ptr_valid(info.images) then begin
    pstr = 'Bad images pointer'
    print, pstr
    if XRegistered('idp3_scrolltxt') then begin
      Widget_Control, info.scrolltxt, Set_Value=pstr, /Append
    endif
    return
  endif
  c = size(*info.images)
  if c[0] eq 0 and c[1] eq 2 then return
  numimages = n_elements(*info.images)
  wset,info.drawid1
  device, cursor_standard=30
  roi = *info.roi
  x = event.x
  y = event.y
  if x gt (info.drawxsize-1) then x = info.drawxsize-1
  if y gt (info.drawysize-1) then y = info.drawysize-1
  if x lt 0 then x = 0   ; This is just in case the user drags the cursor
  if y lt 0 then y = 0   ;   off the screen while pulling out an ROI box.
  str = 'X: ' + string(x, '$(i4)') + $
	' Y: ' + string(y, '$(i4)')
  if ptr_valid(info.dispim) then begin
    sdispim = idp3_scaldisplay(info)
    if n_elements(sdispim) gt 1 then begin
      if finite((sdispim)[x, y]) then begin
        val = (sdispim)[x, y]
        if info.imscl eq 0 then begin
          if abs(val) lt 1000. then vstr = string(val, '$(f10.5)') $
	    else vstr = string(val, '$(f10.2)')
          str = str + ' Value: ' + vstr
          if info.dispbias ne 0.0 then str = str + '  Display bias: ' + $
	    strtrim(string(info.dispbias,'$(f10.3)'),2) 
        endif else begin
          str = str + ' Value: [' + strtrim(string(val,'$(f10.4)'),2) + ']'
          if info.dispbias gt 0.0 then str = str + '  Display bias: [' + $
	    strtrim(string(alog10(info.dispbias),'$(f10.3)'),2) + ']'
        endelse
      endif else str = str + ' Value: NaN'
      if info.show_wcs gt 0 then begin
        if ptr_valid((*info.images)[info.moveimage]) then begin 
          imptr = (*info.images)[info.moveimage]
          if (*imptr).vis eq 1 then begin
	    idp3_getcoords, 0, float(x), float(y), xra, xdec, imstr=imptr
	    if xra ge 0. then begin
	      if info.show_wcs eq 1 then begin
                idp3_conra, xra/15.0, rastr
                idp3_condec, xdec, decstr
	        strp = 'ra:' + rastr + '   dec:' + decstr
              endif else begin
	        strp = 'ra:' + string(xra,'$(f12.7)') + '   dec:' + $
		        string(xdec,'$(f12.7)')
              endelse
            endif
          endif else strp = '                                     '
        endif else strp = '                                     '
      endif else strp = '                                     '
      Widget_Control, info.mwcslab, Set_Value=strp
    endif
    Widget_Control, info.mpixlab, Set_Value=str

    ; Handle 'region of interest' events (left mouse button)
    if event.press eq 1 then begin     ; Remember this corner.
      if XRegistered('idp3_roi') then begin
        ; Erase the old one.
        bits = info.color_bits
        tv, bytscl(sdispim,top=info.d_colors-bits-1,min=info.z1,max=info.z2)$
	  +bits
      endif

      ; Remember this corner.
      roi.boxx0 = x
      roi.boxy0 = y
      roi.tempxbox = x
      roi.tempybox = y
      roi.pressed = 1
      *info.roi = roi
      Widget_Control, event.top, Set_UValue=info
    endif
    if (roi.pressed eq 1) then begin
      ; User is dragging out an ROI box, erase and redraw until done.
      ; Erase the old one.
      if roi.tempxbox ne -1 then begin
        bits = info.color_bits
        tv, bytscl(sdispim,top=info.d_colors-bits-1,min=info.z1,max=info.z2)$
	  +bits
      endif
      ; Plot the new one.
      roi_color = info.color_roi
      if roi_color lt 0 then roi_color=200
      plots, roi.boxx0, roi.boxy0, color=roi_color, /device
      plots, roi.boxx0, y, color=roi_color, /device, /continue
      plots, x, y, /device, color=roi_color, /continue
      plots, x, roi.boxy0, color=roi_color, /device, /continue
      plots, roi.boxx0, roi.boxy0, color=roi_color, /device, /continue
      ; Now, remember where we are
      roi.tempxbox = x
      roi.tempybox = y
      if XRegistered('idp3_adjustroi') then begin
        Widget_Control, info.aroiBase, Get_UValue = temparoiinfo
        xb = roi.boxx0 < roi.tempxbox
        xe = roi.tempxbox > roi.boxx0
        yb = roi.boxy0 < roi.tempybox
        ye = roi.tempybox > roi.boxy0
        xc = (xb + xe) * 0.5
        xl = ABS(xe - xb) + 1
        yc = (yb + ye) * 0.5
        yl = ABS(ye - yb) + 1
        Widget_Control, temparoiinfo.xorigField, Set_Value=xb
        Widget_Control, temparoiinfo.xendField, Set_Value=xe
        Widget_Control, temparoiinfo.xcentField, Set_Value=xc
        Widget_Control, temparoiinfo.xlenField, Set_Value=xl
        Widget_Control, temparoiinfo.yorigField, Set_Value=yb
        Widget_Control, temparoiinfo.yendField, Set_Value=ye
        Widget_Control, temparoiinfo.ycentField, Set_Value=yc
        Widget_Control, temparoiinfo.ylenField, Set_Value=yl
      endif
      *info.roi = roi
      Widget_Control, event.top, Set_UValue=info
    endif
    if event.release eq 1 then begin
      ; Done drawing ROI, pop-up or update the widget.
      roi = *info.roi
      roi.pressed = 0
      if abs(roi.boxx0-roi.tempxbox) le 1 and abs(roi.boxy0-roi.tempybox) le 1 $
        and info.roibox gt 0 then begin
        odd = info.roibox MOD 2
        if odd eq 0 then info.roibox = info.roibox + 1
        bits = info.color_bits
        tv, bytscl(sdispim,top=info.d_colors-bits-1,min=info.z1,max=info.z2)$
	  +bits
        roi_xcen = roi.boxx0
        roi_ycen = roi.boxy0
        half = info.roibox/2
        roi.boxx0 = (roi_xcen - half) > 0
        roi.tempxbox = (roi_xcen + half) < (info.drawxsize-1)
        roi.boxy0 = (roi_ycen - half) > 0
        roi.tempybox = (roi_ycen + half) < (info.drawysize-1)
        ; Plot the new one.
        roi_color = info.color_roi
        if roi_color lt 0 then roi_color=200
        plots, roi.boxx0, roi.boxy0, color=roi_color, /device
        plots, roi.boxx0, roi.tempybox, color=roi_color, /device, /continue
        plots, roi.tempxbox, roi.tempybox, /device, color=roi_color, /continue
        plots, roi.tempxbox, roi.boxy0, color=roi_color, /device, /continue
        plots, roi.boxx0, roi.boxy0, color=roi_color, /device, /continue
        if XRegistered('idp3_adjustroi') then begin
          Widget_Control, info.aroiBase, Get_UValue = temparoiinfo
          xb = roi.boxx0
          xe = roi.tempxbox 
          yb = roi.boxy0 
          ye = roi.tempybox 
          xc = (xb + xe) * 0.5
          xl = ABS(xe - xb) + 1
          yc = (yb + ye) * 0.5
          yl = ABS(ye - yb) + 1
          Widget_Control, temparoiinfo.xorigField, Set_Value=xb
          Widget_Control, temparoiinfo.xendField, Set_Value=xe
          Widget_Control, temparoiinfo.xcentField, Set_Value=xc
          Widget_Control, temparoiinfo.xlenField, Set_Value=xl
          Widget_Control, temparoiinfo.yorigField, Set_Value=yb
          Widget_Control, temparoiinfo.yendField, Set_Value=ye
          Widget_Control, temparoiinfo.ycentField, Set_Value=yc
          Widget_Control, temparoiinfo.ylenField, Set_Value=yl
        endif
      endif
      sdispim = 0
      if (XRegistered('idp3_roi')) then begin
        geo = Widget_Info(info.roiBase, /geometry)
        info.wpos.rwp[0] = geo.xoffset - info.xoffcorr
        info.wpos.rwp[1] = geo.yoffset - info.yoffcorr
        Widget_Control, info.idp3Window, Set_UValue=info
        Widget_Control, info.roiBase, /Destroy
      endif
      *info.roi = roi
      Widget_Control,event.top,Set_UValue=info
      idp3_roi, info.idp3Window
    endif
  endif

  ; This is where we set the axis of rotation for the 'move' image.
  ; This code is really obsolete now that we have "set center" in
  ; the adjust position widget, but it may still have some use.
  if event.press eq 2 then begin     ; Remember this corner.
    tempx = event.x
    tempy = event.y
    moveim = (*info.images)[info.moveimage]    ; pointer to move image
    tempx = tempx - (*moveim).xoff
    tempy = tempy - (*moveim).yoff
    if tempx lt 0 then tempx = 0
    if tempy lt 0 then tempy = 0
    (*moveim).rotcx = tempx
    (*moveim).rotcy = tempy
    Widget_Control, event.top, Set_UValue=info
  endif

  ; This is where we allow the user to slide the image around under
  ; the viewport (if the image is larger than the viewport)
  if event.press eq 4 then begin     ; Remember this corner.
    info.movement = 1
    info.sxtemp = event.x
    info.sytemp = event.y
    Widget_Control, event.top, Set_UValue=info
  endif
  if info.movement eq 1 then begin
    ; Draw a line.
    device, get_graphics_function=g_fnc  ;save graphics function
    device, set_graphics_function=10     ;Use XOR writing mode
    if info.llinex ne 0 and info.lliney ne 0 then begin
      plots, [info.llinex,info.sxtemp], [info.lliney,info.sytemp], /device
    endif
    plots, [event.x,info.sxtemp], [event.y,info.sytemp], /device
    device, set_graphics_function=g_fnc
    info.llinex = event.x
    info.lliney = event.y
    Widget_Control, event.top, Set_UValue=info
  endif
  if event.release eq 4 then begin
    ; Update the display image offset and redisplay.
    info.movement = 0
    xmove = event.x - info.sxtemp
    ymove = event.y - info.sytemp
    xt = info.sxoff - xmove
    yt = info.syoff - ymove
    if xt lt 0 then xt = 0
    if yt lt 0 then yt = 0
    if xt gt (info.dispx - info.drawxsize) then  $
	     xt = (info.dispx - info.drawxsize)
    if yt gt (info.dispy - info.drawysize) then  $
	     yt = (info.dispy - info.drawysize)
    info.sxoff = xt
    info.syoff = yt
    if XRegistered('idp3_adjustdisplay') then begin
      Widget_Control, info.adBase, Get_UValue = tempadinfo
      Widget_Control, tempadinfo.sxoffField, Set_Value = xt
      Widget_Control, tempadinfo.syoffField, Set_Value = yt
    end
    idp3_display,info
    info.llinex = 0
    info.lliney = 0
    Widget_Control, event.top, Set_UValue=info
  endif
end


; IDP3 -- Image Display Paradigm #3

pro idp3, diagnostic=diagnostic

@idp3_structs
@VERSION.idp3

  images    = 0
  moveimage = 0
  if n_elements(diagnostic) eq 0 then diagnostic=0

  ; set 8 bit color according to operating system
  Case !version.os of
  'Win32': device, decomposed=0
  'linux': device, decomposed=0
  'darwin': device, decomposed=0
  'MacOS': device, pseudo=8
  'SUNOS': device, pseudo=8
  else:
  endcase

  ; set value of retain for graphics
  if !version.os eq "MacOS" then retn=1 else retn=2

  ; Load preferences.
  ; Here are the defaults in case the preference file could not be found.

; zoom / interpolation
  main_display_interpolation_on_zoom = 0
  region_of_interest_interpolation_on_zoom = 0
  main_display_dezoom = 0
  interpolation_on_shift = 0
  zoom_flux = 0
  pixel_origin = 0

; window sizes
  main_display_image_X_size = 400
  main_display_image_Y_size = 400
  main_display_scroll_X_size = 0
  main_display_scroll_Y_size = 0
  main_display_scroll = 0
  roi_max_xsize = 450
  roi_max_ysize = 450
  show_images_X_size = 400
  show_images_Y_size = 400
  del_images_X_size = 400
  del_images_Y_size = 400
  build_mask_display_X_size = 512
  build_mask_display_Y_size = 512
  text_win_size = 80
  show_images_path = 1

; window positions
  main_widget_pos                  = [150,50]
  adjust_display_widget_pos        = [300,100]
  adjust_position_widget_pos       = [600,100]
  adjust_radprof_widget_pos        = [300,200]
  adjust_roi_widget_pos            = [300,200]
  adjust_roi_display_widget_pos    = [350,150]
  adjust_polygon_widget_pos        = [350,250]
  adjust_cross_section_widget_pos  = [300,200]
  clip_minmax_widget_pos           = [300,300]
  delete_image_widget_pos          = [700,100]
  edit_preferences_widget_pos      = [100,100]
  set_color_widget_pos             = [150,150]
  edit_eons_widget_pos             = [200,200]
  movemask_widget_pos              = [500,350]
  median_parameters_widget_pos     = [500,350]
  noise_profile_widget_pos         = [250,250]
  noise_profile_plot_widget_pos    = [600,400]
  profile_widget_pos               = [600,400]
  polystatistics_widget_pos        = [600,600]
  roi_widget_pos                   = [500,500]
  radial_profile_widget_pos        = [550,400]
  roi_stats_widget_pos             = [850,300]
  roi_histogram_widget_pos         = [450,500]
  surf_widget_pos                  = [600,300]
  set_center_widget_pos            = [300,350]
  select_image_widget_pos          = [600,0]
  shadesurf_widget_pos             = [600,300]
  show_images_widget_pos           = [650,100]
  spread_sheet_widget_pos          = [300,550]
  save_widgets_pos                 = [100,600]
  print_widgets_pos                = [100,550]
  photometry_widget_pos            = [450,200]
  roi_contour_widget_pos           = [550,250]
  gal_asymmetry_widget_pos         = [450,500]

; window creep
  x_widgetcreep = -1
  y_widgetcreep = -1

; blink control
  blink_delay = 0.5
  iblink_delay = 0.5
  blink_times = 10

; paths and filters
  CD, current = current
  imagepath = current
  listpath = current
  savepath = current
  parpath = current
  imfilter = '*'
  listfilter='*'
  parfilter='*'

; load/save parameters
  extnam = 'SCI'
  load_planes = '*'
  basic_fits = 0
  header_char = ' '
  adjnegoff = 1
  name_delim = ''

; plot controls
  plot_xscale = 1
  plot_yscale = 1
  histbins = 500
  plot_linwid = 1
  show_color_bar = 0
  main_ps_size = 7.0
  roi_ps_size = 7.0

; colors
  color_radpf = 1
  color_poly = 1
  color_innernpf = 1
  color_outernpf = 1
  color_xsect = 1
  color_spsh = 1
  color_roi = 1
  color_orient = 2
  color_bits = 10

; combining data
  combim = 0
  negsig = -3
  possig = 3

; mask controls
  masktol = 0.02
  roimask_good_value = 0
  imask_good_value = 1
  imask_bad_value = 0
  exclude_invalid = 0
  invalid = 0.

; radial profile
  rpcenter_out_fov = 0
  rpsmoothwid = 1
  rpradius = -1
  rpbkgxoff = 0.
  rpbkgyoff = 0.

; miscellaneous
  show_wcs = 0
  wcs_str = '                                                              ' $
	  + '                                 '
  ra_name = 'RA_TARG'
  dec_name = 'DEC_TARG'
  ref_warn = 0
  roi_box = 0
  roi_default_zoom_factor = 4
  view_header_lines = 40
  pdf_viewer = ''
  doeons = 0
  inner_radius = 13
  outer_radius = 26
  master_shifts = 'master_shifts.idp3'
  coron_mask = 'c2_mask.fit'
  mask_xcenter = 70
  mask_ycenter = 211
  coron_badpix = 'c2_badpix.txt'
  dospitzer = 1
  m_pctnan = 75
  m_zoom = 4
  m_thresh = 0.9
  m_tbirad = 0.
  m_tborad = 0.
  m_trad = 3.
  m_refit = 0
  m_pborad = 0.
  m_pbirad = 0.
  m_prad = 12.
  m_pxcen = 256.
  m_pycen = 256.
  doirs = 0
  dofeps = 0
  feps_analyst = ' '
  feps_table1_ref = ' '
  feps_table5_ref = ' '
  feps_table6_ref = ' '
  feps_aux_table = ' '

  cbstdev = 0
  cbnsigma = 0
  cbnpixels = 0
  cbsav2idp3 = 0
  cbsav2file = 0
  smsav2idp3 = 0
  smsav2file = 0
  srsav2idp3 = 0
  srsav2file = 0

  txtarr = "Image Display Paradigm #3, Version " + UAVersion

  if doeons eq 1 then begin
    tmp = idp3_findfile('master_shifts.idp3')
    if tmp eq '' then begin
      estr = 'Error, no shifts file found'
      print, estr
      txtarr = [txtarr, estr]
      doeons = 0
    endif
  endif

  tmp = idp3_findfile('idp3_preferences')
  if tmp eq '' then begin
    tstr = 'idp3_preferences not found, Select below'
    tmp = Dialog_Pickfile(/Read, /Must_Exist,title=tstr)
    if tmp eq '' then begin
      prefstr = 'WARNING: Preferences file not found, using defaults.'
      print, prefstr
      txtarr = [txtarr, prefstr]
    endif
  endif else begin
    prefstr = 'Reading preferences from ' + tmp
    print, prefstr
    txtarr = [txtarr, prefstr]
    openr, ilun, tmp, /GET_LUN
    lineOfText = ''
    while not eof(ilun) do begin
      readf, ilun, lineOfText
      if strlen(lineOfText) gt 0 and strmid(lineOfText,0,1) ne ';' then begin
	 strs = strtrim(strsplit(lineOfText, '=', /extract), 2)
	 if n_elements(strs) eq 2 and strmid(strs[0],0,2) ne 'CD' then begin
	   if diagnostic eq 1 then print, strs[0], '  ', strs[1]
	   Case strs[0] of
	    'main_display_interpolation_on_zoom': $
		main_display_interpolation_on_zoom = fix(strs[1])
            'region_of_interest_interpolation_on_zoom': $
		region_of_interest_interpolation_on_zoom = fix(strs[1])
            'main_display_dezoom': main_display_dezoom = fix(strs[1])
	    'interpolation_on_shift': interpolation_on_shift = fix(strs[1])
	    'zoom_flux': zoom_flux = fix(strs[1])
	    'pixel_origin': pixel_origin = fix(strs[1])
	    'main_display_image_X_size': main_display_image_X_size=fix(strs[1])
            'main_display_image_Y_size': main_display_image_Y_size=fix(strs[1])
	    'main_display_scroll_X_size': $
		main_display_scroll_X_size = fix(strs[1])
            'main_display_scroll_Y_size': $
		main_display_scroll_Y_size = fix(strs[1])
            'main_display_scroll': main_display_scroll = fix(strs[1])
	    'roi_max_xsize': roi_max_xsize = fix(strs[1])
	    'roi_max_ysize': roi_max_ysize = fix(strs[1])
	    'show_images_X_size': show_images_X_size = fix(strs[1])
	    'show_images_Y_size': show_images_Y_size = fix(strs[1])
	    'del_images_X_size': del_images_X_size = fix(strs[1])
	    'del_images_Y_size': del_images_Y_size = fix(strs[1])
	    'build_mask_display_X_size': $
		build_mask_display_X_size = fix(strs[1])
            'build_mask_display_Y_size': $
		build_mask_display_Y_size = fix(strs[1])
            'text_win_size': text_win_size = fix(strs[1])
            'show_images_path': show_images_path = fix(strs[1])
	    'main_widget_pos': main_widget_pos = idp3_extpos(strs[1])
	    'adjust_display_widget_pos': $
		adjust_display_widget_pos = idp3_extpos(strs[1])
            'adjust_position_widget_pos': $
		adjust_position_widget_pos = idp3_extpos(strs[1])
            'adjust_radprof_widget_pos': $
		adjust_radprof_widget_pos = idp3_extpos(strs[1])
            'adjust_roi_widget_pos': $
		adjust_roi_widget_pos = idp3_extpos(strs[1])
            'adjust_roi_display_widget_pos': $
		adjust_roi_display_widget_pos = idp3_extpos(strs[1])
            'adjust_polygon_widget_pos': $
		adjust_polygon_widget_pos = idp3_extpos(strs[1])
            'adjust_cross_section_widget_pos': $
		adjust_cross_section_widget_pos = idp3_extpos(strs[1])
            'clip_minmax_widget_pos': $
		clip_minmax_widget_pos = idp3_extpos(strs[1])
            'delete_image_widget_pos': $
		delete_image_widget_pos = idp3_extpos(strs[1])
            'edit_preferences_widget_pos': $
		edit_preferences_widget_pos = idp3_extpos(strs[1])
            'set_color_widget_pos': $
		set_color_widget_pos = idp3_extpos(strs[1])
            'edit_eons_widget_pos': $
		edit_eons_widget_pos = idp3_extpos(strs[1])
            'movemask_widget_pos': $
		movemask_widget_pos = idp3_extpos(strs[1])
            'median_parameters_widget_pos': $
		median_parameters_widget_pos = idp3_extpos(strs[1])
            'noise_profile_widget_pos': $
		noise_profile_widget_pos = idp3_extpos(strs[1])
            'noise_profile_plot_widget_pos': $
		noise_profile_plot_widget_pos = idp3_extpos(strs[1])
            'profile_widget_pos': $
		profile_widget_pos = idp3_extpos(strs[1])
            'polystatistics_widget_pos': $
		polystatistics_widget_pos = idp3_extpos(strs[1])
            'roi_widget_pos': $
		roi_widget_pos = idp3_extpos(strs[1])
            'radial_profile_widget_pos': $
		radial_profile_widget_pos = idp3_extpos(strs[1])
            'roi_stats_widget_pos': $
		roi_stats_widget_pos = idp3_extpos(strs[1])
            'roi_histogram_widget_pos': $
		roi_histogram_widget_pos = idp3_extpos(strs[1])
            'surf_widget_pos': $
		surf_widget_pos = idp3_extpos(strs[1])
            'set_center_widget_pos': $
		set_center_widget_pos = idp3_extpos(strs[1])
            'select_image_widget_pos': $
		select_image_widget_pos = idp3_extpos(strs[1])
            'shadesurf_widget_pos': $
		shadesurf_widget_pos = idp3_extpos(strs[1])
            'show_images_widget_pos': $
		show_images_widget_pos = idp3_extpos(strs[1])
            'spread_sheet_widget_pos': $
		spread_sheet_widget_pos = idp3_extpos(strs[1])
            'save_widgets_pos': $
		save_widgets_pos = idp3_extpos(strs[1])
            'print_widgets_pos': $
		print_widgets_pos = idp3_extpos(strs[1])
            'photometry_widget_pos': $
		photometry_widget_pos = idp3_extpos(strs[1])
            'roi_contour_widget_pos': $
		roi_contour_widget_pos = idp3_extpos(strs[1])
            'gal_asymmetry_widget_pos': $
		gal_asymmetry_widget_pos = idp3_extpos(strs[1])
            'x_widgetcreep': x_widgetcreep = fix(strs[1])
            'y_widgetcreep': y_widgetcreep = fix(strs[1])
            'blink_delay': blink_delay = float(strs[1])
            'iblink_delay': iblink_delay = float(strs[1])
            'blink_times': blink_times = fix(strs[1])
            'imagepath': imagepath = idp3_extstr(strs[1])
            'listpath': listpath = idp3_extstr(strs[1])
            'savepath': savepath = idp3_extstr(strs[1])
            'parpath': parpath = idp3_extstr(strs[1])
            'imfilter': imfilter = idp3_extstr(strs[1])
            'listfilter': listfilter = idp3_extstr(strs[1])
            'parfilter': parfilter = idp3_extstr(strs[1])
            'extnam': extnam = idp3_extstr(strs[1])
            'load_planes': load_planes = idp3_extstr(strs[1])
            'basic_fits': basic_fits = fix(strs[1])
            'header_char': header_char = idp3_extstr(strs[1])
	    'adj_negoffset': adjnegoff = fix(strs[1])
            'name_delim': name_delim = idp3_extstr(strs[1])
            'plot_xscale': plot_xscale = fix(strs[1])
            'plot_yscale': plot_yscale = fix(strs[1])
            'histbins': histbins = fix(strs[1])
            'plot_linwid': plot_linwid = fix(strs[1])
            'show_color_bar': show_color_bar = fix(strs[1])
            'main_ps_size': main_ps_size = float(strs[1])
            'roi_ps_size': roi_ps_size = float(strs[1])
            'color_radpf': color_radpf = fix(strs[1])
            'color_poly': color_poly = fix(strs[1])
            'color_innernpf': color_innernpf = fix(strs[1])
            'color_outernpf': color_outernpf = fix(strs[1])
            'color_xsect': color_xsect = fix(strs[1])
            'color_spsh': color_spsh = fix(strs[1])
            'color_roi': color_roi = fix(strs[1])
            'color_orient': color_orient = fix(strs[1])
            'color_bits': color_bits = fix(strs[1])
            'combim': combim = fix(strs[1])
            'negsig': negsig = fix(strs[1])
            'possig': possig = fix(strs[1])
            'masktol': masktol = float(strs[1])
            'roimask_good_value': roimask_good_value = fix(strs[1])
            'imask_good_value': imask_good_value = fix(strs[1])
            'imask_bad_value': imask_bad_value = fix(strs[1])
            'exclude_invalid': exclude_invalid = fix(strs[1])
            'invalid': invalid = float(strs[1])
            'rpcenter_out_fov': rpcenter_out_fov = fix(strs[1])
            'rpsmoothwid': rpsmoothwid = fix(strs[1])
            'rpradius': rpradius = fix(strs[1])
            'rpbkgxoff': rpbkgxoff = float(strs[1])
            'rpbkgyoff': rpbkgyoff = float(strs[1])
            'show_wcs': show_wcs = fix(strs[1])
	    'wcs_str': wcs_str = idp3_extstr(strs[1])
	    'wcs_str1': wcs_str1 = idp3_extstr(strs[1])
            'ra_name': ra_name = idp3_extstr(strs[1])
            'dec_name': dec_name = idp3_extstr(strs[1])
            'ref_warn': ref_warn = fix(strs[1])
            'roi_box': roi_box = fix(strs[1])
            'roi_default_zoom_factor': $
		roi_default_zoom_factor = fix(strs[1])
            'view_header_lines': view_header_lines = fix(strs[1])
	    'pdf_viewer': pdf_viewer = idp3_extstr(strs[1])
            'doeons': doeons = fix(strs[1])
            'inner_radius': inner_radius = fix(strs[1])
            'outer_radius': outer_radius = fix(strs[1])
            'master_shifts': master_shifts = idp3_extstr(strs[1])
            'coron_mask': coron_mask = idp3_extstr(strs[1])
            'mask_xcenter': mask_xcenter = fix(strs[1])
            'mask_ycenter': mask_ycenter = fix(strs[1])
            'coron_badpix': coron_badpix = idp3_extstr(strs[1])
            'dospitzer': dospitzer = fix(strs[1])
            'm_pctnan': m_pctnan = fix(strs[1])
            'm_zoom': m_zoom = fix(strs[1])
            'm_thresh': m_thresh = float(strs[1])
            'm_tbirad': m_tbirad = float(strs[1])
            'm_tborad': m_tborad = float(strs[1])
            'm_trad': m_trad = float(strs[1])
            'm_refit': m_refit = fix(strs[1])
            'm_pborad': m_pborad = float(strs[1])
            'm_pbirad': m_pbirad = float(strs[1])
            'm_prad': m_prad = float(strs[1])
            'm_pxcen': m_pxcen = float(strs[1])
            'm_pycen': m_pycen = float(strs[1])
            'doirs': doirs = fix(strs[1])
            'dofeps': dofeps = fix(strs[1])
            'feps_analyst': feps_analyst = idp3_extstr(strs[1])
            'feps_table1_ref': feps_table1_ref = idp3_extstr(strs[1])
            'feps_table5_ref': feps_table5_ref = idp3_extstr(strs[1])
            'feps_table6_ref': feps_table6_ref = idp3_extstr(strs[1])
	    'feps_aux_table': feps_aux_table = idp3_extstr(strs[1])
            else: begin
	      vstr = 'Variable: ' + strs[0] + ' not found'
	      print, vstr
	      txtarr = [txtarr, vstr]
            end
           endcase
        endif
      endif
    endwhile
    close, ilun
    free_lun, ilun
  endelse

  if n_elements(wcs_str1) gt 0 then wcs_str = wcs_str + wcs_str1

; set up environmental variables for smart communication
  defsysv, '!sm_idp3', exists = ex_smart
  if ex_smart eq 0 then defsysv, '!sm_idp3', ptr_new()
  defsysv, '!sm_idp3_id', exists = e
  if e eq 0 then defsysv, '!sm_idp3_id', 0L

; set number of bits for display -> not greater than 255
  d_colors = min([!d.n_colors, 255])
; allocate first six color levels for plots, 0=black, 1=white, 2=red,
; 3=green, 4=blue, 5=yellow if color plots are specified
  if color_radpf ge 0 or color_poly ge 0 or color_innernpf ge 0 or $
     color_outernpf ge 0 or color_xsect ge 0 or color_spsh ge 0 or $
     color_roi ge 0 or color_orient ge 0 then begin
    color6
    color_bits = 10
  endif else color_bits = 0

  ; set path delimiter according to OS
  if !version.os EQ 'MacOS' then delim = ':' else delim = '/'
  a = strlen(imagepath)
  b = strmid(imagepath, a-1)
  if b ne delim then begin
      imagepath = imagepath + delim
      listpath = listpath + delim
      savepath = savepath + delim
      parpath = parpath + delim
  endif

  ; set values for x widget creep
  if x_widgetcreep eq -1  then begin
    Case !version.os of
      'Win32':  x_widgetcreep = 0
      'linux':  x_widgetcreep = 6
      'MacOS':  x_widgetcreep = 0
      'sunos':  x_widgetcreep = 6
      'darwin': x_widgetcreep = 0
      else: 
    endcase
  endif
   ; set values for y widget creep
  if y_widgetcreep eq -1  then begin
    Case !version.os of
      'Win32':  y_widgetcreep = 0
      'linux':  y_widgetcreep = 20
      'MacOS':  y_widgetcreep = 0
      'sunos':  y_widgetcreep = 29
      'darwin': y_widgetcreep = 22
      else: 
    endcase
  endif

  blink_count = blink_times

  ; Put widget position data into widget position structure.
  wpos = {idp3wposi} 
  wpos.mwp    = main_widget_pos
  wpos.adwp   = adjust_display_widget_pos
  wpos.apwp   = adjust_position_widget_pos
  wpos.arwp   = adjust_radprof_widget_pos
  wpos.aroiwp = adjust_roi_widget_pos
  wpos.rdwp = adjust_roi_display_widget_pos
  wpos.apolywp = adjust_polygon_widget_pos
  wpos.axwp   = adjust_cross_section_widget_pos
  wpos.cfwp   = clip_minmax_widget_pos
  wpos.diwp   = delete_image_widget_pos
  wpos.epwp   = edit_preferences_widget_pos
  wpos.tcwp   = set_color_widget_pos
  wpos.eewp   = edit_eons_widget_pos
  wpos.mmwp   = movemask_widget_pos
  wpos.mpwp   = median_parameters_widget_pos
  wpos.npwp   = noise_profile_widget_pos
  wpos.nplotwp= noise_profile_plot_widget_pos
  wpos.pwp    = profile_widget_pos
  wpos.pswp   = polystatistics_widget_pos
  wpos.rwp    = roi_widget_pos
  wpos.rpwp   = radial_profile_widget_pos
  wpos.rswp   = roi_stats_widget_pos
  wpos.rhwp   = roi_histogram_widget_pos
  wpos.swp    = surf_widget_pos
  wpos.scwp   = set_center_widget_pos
  wpos.seliwp = select_image_widget_pos
  wpos.shdswp = shadesurf_widget_pos
  wpos.siwp   = show_images_widget_pos
  wpos.sswp   = spread_sheet_widget_pos
  wpos.savwp  = save_widgets_pos
  wpos.printwp= print_widgets_pos
  wpos.phwp   = photometry_widget_pos
  wpos.rcwp   = roi_contour_widget_pos
  wpos.gawp   = gal_asymmetry_widget_pos

  idp3Window = Widget_Base( $
               Title = "Image Display Paradigm #3, Version " + UAVersion, $
               Mbar=menuBar, /Column, /TLB_Size_Events, TLB_Frame_Attr=8, $
               XOffset = wpos.mwp[0], YOffset = wpos.mwp[1])
  ; Build the menubar.
  fileMenu   = Widget_Button(menuBar, Value=" File             ", /Menu)
  imageMenu  = Widget_Button(menuBar, Value=" Images             ", /Menu)
  adjustMenu = Widget_Button(menuBar, Value=" Adjust             ", /Menu)
  editMenu   = Widget_Button(menuBar, Value=" Edit            ", /Menu)
  if doeons eq 1 then EONSMenu = Widget_Button(menuBar, Value=" EONS ", /Menu)
  if dospitzer eq 1 then $
    mipsMenu = Widget_Button(menuBar, Value=" SPITZER ", /Menu)
  if doirs eq 1 then $
    irsMenu = Widget_Button(menuBar, Value=" IRS ", /Menu)

  helpMenub  = Widget_Button(menuBar, Value= " Help ", /Help)

  ; Add to Help Menu
  helpButton = Widget_Button(helpMenub, Value='Help/Overview',$
     Event_Pro = 'Idp3_helpoview')
  help2Button = Widget_Button(helpMenub, Value='Help/Main Display', $
     Event_pro = 'idp3_helpmain')

  ; Add to Images Menu
  showimButton = Widget_Button(imageMenu, Value='Show Images', $
			       Event_Pro = 'Idp3_ShowIm')
  pickimButton = Widget_Button(imageMenu, Value='Select Image', $
			       Event_Pro = 'Idp3_SelectIm')
  alignButton  = Widget_Button(imageMenu, Value='Align by WCS', $
			       Event_Pro = 'Idp3_Alignwcs', /Separator)
  undoalignButton = Widget_Button(imageMenu, Value='Undo Alignment', $
			       Event_Pro = 'Idp3_UndoAlign')
  sourcedefButton = Widget_Button(imageMenu, Value='Source Location', $
			       Event_Pro = 'Idp3_Sourcedef')
  combineButton = Widget_Button(imageMenu, Value='Combine Images', $
			          Event_Pro = 'idp3_imcombine', /Separator)
  blinkMenu = Widget_Button(imageMenu, Value = 'Blink', /Menu, /Separator)

  ; Add to Blink Menu
  setupButton = Widget_Button(blinkMenu, Value='Setup', $
		 Event_Pro = 'Idp3_BlnkSetup')
  blinkButton = Widget_Button(blinkMenu, Value='Blink', $
		 Event_Pro = 'Idp3_Blink')
  stopblinkButton = Widget_Button(blinkMenu, Value='Stop Blink', $
		 Event_Pro = 'Idp3_StopBlink')

  ; Add to Adjust Menu
  positionButton = Widget_Button(adjustMenu, Value='Position', $
			       Event_Pro = 'Idp3_AdjustPosition')
  displayButton  = Widget_Button(adjustMenu, Value='Display', $
			       Event_Pro = 'Idp3_AdjustDisplay')
  resetButton = Widget_Button(adjustMenu, Value='Resize Display', $
			       Event_Pro = 'Idp3_Reset')

  ; Add to Edit Menu
  maskButton   = Widget_Button(editMenu, Value='Build Image Mask', $
			       Event_Pro = 'Idp3_BuildMask')
  editrefButton = Widget_BUtton(editMenu, Value = 'Edit Image', $
			       Event_Pro = 'Idp3_editim')
  repairBadButton = Widget_Button(editMenu, Value = 'Repair Bad Pixels', $
			       Event_Pro = 'Idp3_repairbad')

  ; Add to EONS Menu
  if doeons eq 1 then loadoffButton = Widget_Button(EONSMenu, $
    Value='Load/Offsets',  Event_Pro = 'Idp3_LoadShift')

  ; Add to Mips Menu
  if dospitzer eq 1 then begin 
     loadpsfButton = Widget_Button(mipsMenu, Value = 'Load PSFs', $
       Event_Pro = 'Idp3_loadmipsf')
     alignmipsButton = Widget_Button(mipsMenu, Value = 'Align Mips', $
       Event_Pro = 'idp3_alignmips')
     medpsfButton = Widget_Button(mipsMenu, Value=' PSF Subtract & Median ', $
       Event_pro = 'idp3_clipmipsmedpar')
     loadimerrButton = Widget_Button(mipsMenu, Value = 'Load Image with Errs', $
       Event_Pro = 'idp3_loadimerr')
     loadmipserrButton = Widget_Button(mipsMenu, Value ='Load MIPS with Errs', $
	Event_Pro = 'idp3_loadmipserr')
  endif

  ; Add to IRS Menu
  if doirs eq 1 then ExpPMButton = Widget_Button(IRSMenu, $
    Value='Export to PM',  Event_Pro = 'Idp3_ExpPM')

  ; Add to File Menu
  loaddataMenu = Widget_Button(fileMenu, Value= '  Load Images', /Menu)
  delimButton  = Widget_Button(fileMenu, Value='Delete Images', $
			       Event_Pro = 'Idp3_DeleteIm')
  savwidButton = Widget_Button(fileMenu, Value=' Save Display', $
			       Event_Pro = 'Idp3_savemain', /Separator)
  prntButton   = Widget_Button(fileMenu, Value='Print Display', $
			       Event_Pro = 'Idp3_print')

  edprfButton  = Widget_Button(fileMenu, Value='Edit Preferences', $
			       Event_Pro = 'Idp3_EditPref', /Separator)
  setcolButton = Widget_Button(fileMenu, Value='Set Colors', $
			       Event_Pro = 'Idp3_SetColor')
  creatxtButton = Widget_Button(fileMenu, Value = 'Create Text Window', $
			       Event_Pro = 'idp3_createtxt')
  savifButton  = Widget_Button(fileMenu, Value='   Save Parameters', $
			       Event_Pro = 'Idp3_SaveInfo', /Separator)
  loadpaButton = Widget_Button(fileMenu, Value='Restore Parameters', $
			       Event_Pro = 'Idp3_RestorInfo')
  convolButton = Widget_Button(fileMenu, Value='Convolve Display', $
			       Event_Pro = 'idp3_convolim', /Separator)
  catButton    = Widget_Button(fileMenu, Value='Catalogs', $
			       Event_Pro = 'Idp3_Catalog')
  exitButton   = Widget_Button(fileMenu, Value='Exit idp3', $
			       /Separator, Event_Pro = 'Idp3_Exit')

  ; Add to Load Data Menu
  loadimButton = Widget_Button(loaddataMenu, Value='Load Image', $
			       Event_Pr = 'Idp3_LoadIm')
  loadliButton = Widget_Button(loaddataMenu, Value='Load List', $
			       Event_Pro = 'Idp3_LoadList', /Separator)
  loadmaButton = Widget_Button(loaddataMenu, Value='Load Multiaccum', $
			       Event_Pro = 'Idp3_LoadMAccum', /Separator)
  loadmpsButton = Widget_Button(loaddataMenu, Value='Load MIPS', $
			       Event_Pro = 'Idp3_LoadMIPS', /Separator)
  loadwgtsButton = Widget_Button(loaddataMenu, Value='Load Image Weights', $
			       Event_Pro = 'idp3_loadwgts', /Separator)

  morientlab = Widget_Label(idp3Window, Value = wcs_str)
  mwcslab = Widget_Label(idp3Window, Value = wcs_str)

  ; Graphics window.
  drawxsize = main_display_image_X_size
  drawysize = main_display_image_Y_size
  scrollxsize = main_display_scroll_X_size
  scrollysize = main_display_scroll_Y_size
  scrollmain = main_display_scroll
  if scrollmain eq 1 then begin
    if scrollxsize le 0 or scrollxsize ge drawxsize or $
       scrollysize le 0 or scrollysize ge drawysize then begin
       scrollmain = 0
       scstr = $
	 'Cannot create scrolled display - scroll sizes must be < image sizes'
       print, scstr
       txtarr = [txtarr, scstr]
    endif
  endif
  showimxsize = show_images_X_size
  showimysize = show_images_Y_size
  showimscxsize = show_images_X_size - 1
  showimscysize = show_images_Y_size - 20
  delimxsize = del_images_X_size
  delimysize = del_images_Y_size
  bmaskxsize = build_mask_display_X_size
  bmaskysize = build_mask_display_Y_size
  viewhdrysize = view_header_lines
  gbase = Widget_Base(idp3Window, Event_Pro = 'Idp3_Blinkim')
  if scrollmain eq 0 then begin
    idp3Draw = Widget_Draw(gbase, XSize = drawxsize, YSize = drawysize, $
	        /Motion_Events, /Button_Events, Event_Pro = 'Idp3_Draw', $
		retain=retn)
  endif else begin
    idp3Draw = Widget_Draw(gbase, XSize = drawxsize, YSize = drawysize, $
		x_scroll_size = scrollxsize, y_scroll_size = scrollysize, $
		/scroll, /Motion_Events, /Button_Events, $
		Event_Pro='Idp3_Draw', retain=retn)
  endelse
  mpixlab = Widget_Label(idp3Window, Value = wcs_str)

  Widget_Control, idp3Window, /Realize           ; Show the GUI

  Widget_Control, idp3Draw, Get_Value = drawid1  ; Get the window index number

  ; Create and initialize the "Region Of Interest" structure.
  roi = ptr_new({idp3roii})
  (*roi).pxscale = 0.0
  (*roi).pyscale = 0.0
  (*roi).roiimage = ptr_new([0L,0L])
  (*roi).mouse_mode = 0
  (*roi).boxx0 = -1
  (*roi).boxy0 = -1
  (*roi).radxcent = 0.0
  (*roi).radycent = 0.0
  (*roi).radradius = 0.0
  (*roi).centfit = 0
  (*roi).rpmm = 0
  (*roi).rpeplot = 0
  (*roi).cmethod = 0
  (*roi).rpsmooth = 0
  (*roi).wmcoords = [-1.,-1.,-1.,-1.]
  (*roi).xsxstart = 0.0
  (*roi).xsystart = 0.0
  (*roi).xsxstop = 0.0
  (*roi).xsystop = 0.0
  (*roi).xsxcenter = 0.0
  (*roi).xsycenter = 0.0
  (*roi).xsangle = 0.0
  (*roi).xslength = 0.0
  (*roi).xsfwhm = 0.0
  (*roi).xspeak = 0.0
  (*roi).xsheight = 0.0
  (*roi).xs1overe = 0.0
  (*roi).xsbase0 = 0.0
  (*roi).xsbase1 = 0.0
  (*roi).xsmm = 0
  (*roi).xsbkg = 0
  (*roi).xsplotgb = 1
  (*roi).xsplotgauss = 0
  (*roi).xsplotres = 0
  (*roi).xsplotbase = 0
  (*roi).xsplotfwhm = 0
  (*roi).npxcenter = 0.0
  (*roi).npycenter = 0.0
  (*roi).facenter = 0.0
  (*roi).lacenter = 0.0
  (*roi).awidth = 0.0
  (*roi).aincr = 0.0
  (*roi).npmm = 0
  (*roi).polypts = -1
  (*roi).polyx = ptr_new(0L)
  (*roi).polyy = ptr_new(0L)
  (*roi).polydone = 0
  (*roi).polyxb = -1
  (*roi).polyyb = -1
  (*roi).spolypts = 0
  (*roi).savpolyx = ptr_new(0L)
  (*roi).savpolyy = ptr_new(0L)
  (*roi).polyxold = -1
  (*roi).polyyold = -1
  (*roi).edpt = -1
  (*roi).polymnd = 999.0
  (*roi).galxcntr = -1.
  (*roi).galycntr = -1.
  (*roi).galradius = -1.
  (*roi).bkgmm = 0
  (*roi).bkgfd = 0
  (*roi).bkgval = 0.0
  (*roi).bkg_dev = 0.0
  (*roi).asym = 0.0
  (*roi).asym_dev = 0.0
  (*roi).asym_snr = 0.0
  (*roi).asym_cc = 0.0
  (*roi).asym_eta = 0.0
  (*roi).bkg_xbeg = 0
  (*roi).bkg_xend = 0
  (*roi).bkg_ybeg = 0
  (*roi).bkg_yend = 0
  (*roi).tempxbox = -1
  (*roi).tempybox = -1
  (*roi).roizoom = roi_default_zoom_factor
  (*roi).fix0 = -1
  (*roi).fiy0 = -1
  (*roi).curs = 0
  (*roi).roixsize = 0
  (*roi).roiysize = 0
  (*roi).roixorig = 0
  (*roi).roiyorig = 0
  (*roi).roixend = 0
  (*roi).roiyend = 0
  (*roi).roiDraw = 0L
  (*roi).drawid2 = 0L
  (*roi).poly_mean = 0.0
  (*roi).poly_meanstd = 0.0
  (*roi).poly_median = 0.0
  (*roi).poly_medianstd = 0.0
  (*roi).poly_mode = 0.0
  (*roi).poly_modestd = 0.0
  (*roi).rodmask = ptr_new([0L,0L])
  (*roi).roddmask = ptr_new([0L,0L])
  (*roi).rod = 0
  (*roi).mask = ptr_new([0L,0L])
  (*roi).msk = 0
  (*roi).maskname = ' '
  (*roi).msk_xoff = 0
  (*roi).msk_yoff = 0
  (*roi).maskgood = roimask_good_value
  (*roi).orivec = 1
  (*roi).collapse_type = 0
  (*roi).collapse_dir = 0
  (*roi).polymask = ptr_new([0L,0L])
  (*roi).polymsk = 0
  (*roi).otype = 0
  (*roi).cotype = 0
  (*roi).pressed = 0

  ; Create and initialize the profile (cross-section) structure.
  prof = ptr_new({idp3profi})
  (*prof).sx = -1
  (*prof).sy = -1
  (*prof).ex = -1
  (*prof).ey = -1
  (*prof).width = 1
  (*prof).new = 0
  (*prof).oplot = 0
  (*prof).log = 0
  (*prof).ymin = 0.
  (*prof).ymax = 0.
  (*prof).xleft = -1.
  (*prof).xright = -1.
  (*prof).coordstr = ''
  (*prof).otype = 0
  (*prof).pressed = 0

  ; Create and initialize the radial profile structure.
  ; Not all of this structure is currently used, there are some entries
  ; in the main data structure (below) for the center and radius.
  rprf = ptr_new({idp3rprfi})
  (*rprf).sx = -1.0
  (*rprf).sy = -1.0
  (*rprf).r = -1.0
  (*rprf).new = 0
  (*rprf).oplot = 0
  (*rprf).log = 0
  (*rprf).ee = 0
  (*rprf).ymin = 0.0
  (*rprf).ymax = 0.0
  (*rprf).coordstr = ''
  (*rprf).otype = 0
  (*rprf).drag = 0
  (*rprf).pressed = 0

  ; Create and initialize the noise profile structrue.
  nprf = ptr_new({idp3nprfi})
  (*nprf).oplot = 0
  (*nprf).log = 0
  (*nprf).ymin = 0
  (*nprf).ymax = 0
  (*nprf).otype = 0

  ; Create and initialize the roi histogram structure
  rhist = ptr_new({idp3histi})
  (*rhist).xmin = 0.0
  (*rhist).xmax = 0.0
  (*rhist).ymin = 0.0
  (*rhist).ymax = 0.0
  (*rhist).log = 0
  (*rhist).otype = 0

  ; Create and initialize the spreadsheet structure.
  sprd = {idp3sprdi}
  sprd.sx = -2
  sprd.sy = -2
  sprd.ex = -2
  sprd.ey = -2
  sprd.view = [-1,-1]
  sprd.cells = [-1,-1,-1,-1]
  sprd.new = 0

  ; Create and initialize the centroid structure.
  cent = {idp3centi}
  cent.sx     = 0
  cent.sy     = 0
  cent.fwhm   = 0.0
  cent.mv     = 0
  cent.halfbox = 0.0
  cent.autocenter = 1
  cent.fitcircle = 0
  cent.wmx     = 0.0
  cent.wmy     = 0.0
  cent.errwmx  = 0.0
  cent.errwmy  = 0.0
  cent.gfx    = 0.0
  cent.gfy    = 0.0
  cent.errgfx = 0.0
  cent.errgfy = 0.0
  cent.cwmx = 0.0
  cent.cwmy = 0.0
  errcwmx = 0.0
  errcwmy = 0.0
  cent.fwhmx  = 0.0
  cent.fwhmy  = 0.0
  cent.theta  = 0.0
  cent.ccmain = 0L

  ; Create and initialize the aperture photometry structure
  phot = {idp3photi}
  phot.tradius = 0.0
  phot.biradius = 0.0
  phot.boradius = 0.0
  phot.shape = 0
  phot.sharp = 0
  phot.all_cntrs = 0
  phot.ap_corr = 0.
  phot.bkg_fract = 0.
  phot.med_thresh = 0.9
  phot.outname = ' '
  phot.comment = ' '
  phot.irms = 0.0
  phot.imean = 0.0
  phot.imedian = 0.0
  phot.brrms = 0.0
  phot.brmean = 0.0
  phot.brmedian = 0.0
  phot.qualflag = ' '
  feps_aux_table = strtrim(feps_aux_table)
  if dofeps eq 1 and strlen(feps_aux_table) gt 1 then begin
    inpath = imagepath
    get_new = 0
    stat = idp3_rdfeps(inpath, outpath, feps_aux_table, get_new)
    if stat eq 0 then begin
      phot.fepsstat = 0
      phot.fepsfile = feps_aux_table
      fstr = 'feps file: ' + feps_aux_table
      print, fstr
      txtarr = [txtarr, fstr]
    endif else begin
      phot.fepsstat = -1
      phot.fepsfile = ''
    endelse
  endif else begin
    phot.fepsstat = -1
    phot.fepsfile = ''
  endelse

  ; Create and initialize the edit structure.
  edit = {idp3editi}
  edit.eregion = ptr_new([0L,0L])
  edit.drawid  = 0L
  edit.z1 = -999.9
  edit.z2 = -999.9
  edit.zoomfact = 1.0
  edit.bx0 = -1
  edit.bx1 = -1
  edit.by0 = -1
  edit.by1 = -1

  ; create and initialize the mask builder structure.
  maskpix = {idp3maski}
  maskpix.last_region = ptr_new([0L,0L])
  maskpix.last_pixel = [-1,-1]
  maskpix.mask_good = imask_good_value
  maskpix.mask_bad = imask_bad_value
  maskpix.mask_veq = 0.0
  maskpix.mask_vgt = 0.0
  maskpix.mask_vlt = 0.0

  ; create and initialize the catalog structure
  catalog = {idp3cati}
  catalog.name = '  '
  catalog.entries = 0
  ptxtarr = ptr_new(txtarr)

  sourcezoom = 1

  ; Set up main display image.
  dispim = ptr_new(fltarr(drawxsize, drawysize))
  alphaim = ptr_new(fltarr(drawxsize, drawysize))
  dispx = drawxsize
  dispy = drawysize

  ; Save information that needs to be passed around in a structure.
  ; This is main, general information, structure.
  info = { UAVersion   :   UAVersion,         $ ; this version of idp3
	   drawid1     :   drawid1,           $ ; the window index number
	   drawxsize   :   drawxsize,         $ ; current X size of draw window
	   drawysize   :   drawysize,         $ ; current Y size of draw window
	   scrollxsize :   scrollxsize,       $ ; current X size of scroll win
	   scrollysize :   scrollysize,       $ ; current Y size of scroll win
	   scrollmain  :   scrollmain,        $ ; scroll main window
	   xoffcorr    :   x_widgetcreep,     $ ; error in x (info.geometry)
	   yoffcorr    :   y_widgetcreep,     $ ; error in y (info.geometry)
	   d_colors    :   d_colors,          $ ; number of display colors
	   retn        :   retn,              $ ; graphis retain
	   ptxtarr     :   ptxtarr  ,         $ ; pointer to scroll text
	   scrolltxt   :   0L,                $ ; scroll txt widget
	   delim       :   delim,             $ ; delimiting char for filepath
	   images      :   ptr_new(images),   $ ; pointer to images array
	   moveimage   :   moveimage,         $ ; current moveable image
	   idp3Window  :   idp3Window,        $ ; top widget identifier
	   roi_xmax    :   roi_max_xsize,     $ ; max visible ROI X size
	   roi_ymax    :   roi_max_ysize,     $ ; max visible ROI Y size
	   ShowImBase  :   0L,                $ ; top widget of show image
	   showimxsize :   showimxsize,       $ ; width of showim (scroll)
	   showimysize :   showimysize,       $ ; length of showim (scroll)
	   showimscxsize:  showimscxsize,     $ ; x scroll size of showim
	   showimscysize:  showimscysize,     $ ; y scroll size of showim
	   delimxsize  :   delimxsize,        $ ; width of deleteimages
	   delimysize  :   delimysize,        $ ; length of deleteimages
	   bmaskxsize  :   bmaskxsize,        $ ; buildmask max x size
	   bmaskysize  :   bmaskysize,        $ ; buildmask max y size
	   textwinsz   :   text_win_size,     $ ; x size of text window
	   showreflabel:   0L,                $ ; Show Images reference label
	   viewhdrysize:   viewhdrysize,      $ ; length of view hdr (scroll)
	   pdf_viewer  :   pdf_viewer,        $ ; task to view pdf help files 
	   lastresamp  :   -1,                $ ; last resample value
	   proshold    :   0,                 $ ; hold processing for display
	   maskWindow  :   0L,                $ ; base for Build Mask
	   maskDraw    :   0L,                $ ; base for mask draw widget
	   maskID      :   0L,                $ ; mask draw widget id
	   maskmode    :   0,                 $ ; mouse mode for build mask
	   maskzoom    :   1,                 $ ; zoom factor for build mask
	   roiBase     :   0L,                $ ; roi widget identifier
	   roicntrBase :   0L,                $ ; roi contour widget identifer
	   apphotBase  :   0L,                $ ; aperture photometry widget id
	   galasymBase :   0L,                $ ; gal asymmetry widget id
	   apWindow    :   0L,                $ ; top widget, adjust position
	   rtxcenField :   0L,                $ ; rotation xcenter (adjustpos)
	   rtycenField :   0L,                $ ; rotation ycenter (adjustpos)
	   imBiasField :   0L,                $ ; image bias field (adjustpos)
           imscaleField :  0L,                $ ; image flux scale (adjustpos)
	   scWindow    :   0L,                $ ; top widget, set rot center
	   adBase      :   0L,                $ ; top widget of adjust display
	   aroiBase    :   0L,                $ ; top widget of adjust roi
	   rdBase      :   0L,                $ ; top widget of adj roi display
	   arpBase     :   0L,                $ ; top widget of adjust radprof
           axsBase     :   0L,                $ ; top widget of adjust xsection
	   apolyBase   :   0L,                $ ; top widget of adjust polygon 
	   epBase      :   0L,                $ ; top widget of edit pref
	   histBase    :   0L,                $ ; top widget of histogram
	   editBase    :   0L,                $ ; top widget of edit
	   etBase      :   0L,                $ ; top widget of edit table
	   editlabel   :   0L,                $ ; edit name label
	   etable      :   0L,                $ ; edit table id
	   cent        :   cent,              $ ; centroid structure
	   roistats    :   0L,                $ ; top widget of roi stats
	   polystats   :   0L,                $ ; top widget of polygon stats
	   spread      :   0L,                $ ; top widget of spreadsheet
	   sstable     :   0L,                $ ; spreadsheet table
	   gbase       :   gbase,             $ ; graphics base, used for timer
	   Z1          :   0.0,               $ ; lower colormap cutoff
	   Z2          :   0.0,               $ ; upper colormap cutoff
	   imscl       :   0,                 $ ; flag for image scaling
	   AutoScale   :   1,                 $ ; switch for auto scale
	   Dispbias    :   0.0,               $ ; display bias
	   otype       :   0,                 $ ; print type
	   apad        :   0,                 $ ; pad value for All Pad
	   catradius   :   3.0,               $ ; catalog display radius
	   catdisp     :   0,                 $ ; catalog display flag
	   catid       :   -1,                $ ; catalog id to mark
	   catposx     :   -1,                $ ; catalog ra/dec x position
	   catposy     :   -1,                $ ; catalog ra/dec y position
	   catminred   :   0.0,               $ ; catalog min redshift
	   catmaxred   :   6.5,               $ ; catalog max redshift
	   catdraw     :   0L,                $ ; catalog draw id
           roi         :   roi,               $ ; region of interest structure
           prof        :   prof,              $ ; region of interest profile
           rprf        :   rprf,              $ ; radial profile struct
	   nprf        :   nprf,              $ ; noise profile struct
	   rhist       :   rhist,             $ ; histogram structure
	   edit        :   edit,              $ ; edit struct
	   maskpix     :   maskpix,           $ ; build mask structure
	   catalog     :   catalog,           $ ; catalog structure
	   phot        :   phot,              $ ; photometry structure
           idp3prof    :   0L,                $ ; ROI profile plot widget ID
	   profdraw    :   0L,                $ ; profile drawid
	   profline    :   0,                 $ ; profile line type
	   profymintxt :   0L,                $ ; profile ymin text field
	   profymaxtxt :   0L,                $ ; profile ymax text field
	   profwidth   :   0L,                $ ; profile width text field
	   proffwhmtxt :   0L,                $ ; profile fwhm text field
	   profpeaktxt :   0L,                $ ; profile peak pixel text field
	   profbasetxt :   0L,                $ ; profile baseline text field
	   proflefttxt :   0L,                $ ; profile fitregion(left) text
	   profrighttxt:   0L,                $ ; profile fitregion(right) text
	   xs_autoscl  :   1,                 $ ; autoscale y axis of cross sec
	   xs_negpeak  :   0,                 $ ; fit negative peak for x sect
	   xsautobutton:   0L,                $ ; xsection autoscale button
	   xsgaussbutton:  0L,                $ ; xsection plot gauss only
	   xsgbbutton:     0L,                $ ; xsection plot gauss+baseline
	   xsresidbutton:  0L,                $ ; xsection residual plot button
	   xsbasebutton:   0L,                $ ; xsection baseline plot button
	   xsfwhmbutton:   0L,                $ ; xsection fwhm plot button
	   xslogbutton :   0L,                $ ; xsection log button
	   xsoplotbutton:  0L,                $ ; xsection overplot button
	   xsnegpeakbutton:0L,                $ ; xsection neg peak button
	   proffitlab1 :   0L,                $ ; xsection fit label #1 
	   proffitlab2 :   0L,                $ ; xsection fit label #2
	   proffitlab3 :   0L,                $ ; xsection fit label #3
	   proffitlab4 :   0L,                $ ; xsection fit label #4
	   proffitlab5 :   0L,                $ ; xsection fit label #5
	   proflab1    :   0L,                $ ; xsection label
	   proflab2    :   0L,                $ ; xsection label 2
	   proflab3    :   0L,                $ ; xsection label 3
	   idp3prfim   :   0L,                $ ; profile image widget id
	   profim      :   0L,                $ ; profile image id
           idp3rprf    :   0L,                $ ; ROI radial profile widget ID
	   idp3rprfgim :   0L,                $ ; rad prof gaussian widget ID
	   rprfdraw    :   0L,                $ ; radial profile drawid
	   rprfgim1    :   0L,                $ ; rad prof raw data drawid
	   rprfgim2    :   0L,                $ ; rad prof gaussian drawid
	   rprfgim3    :   0L,                $ ; rad prof gauss residual drawid
	   rprfgim4    :   0L,                $ ; rad prof gauss contour drawid
	   rprfcrlab   :   0L,                $ ; rad prof cent/rad label id
	   rprfcrlab2  :   0L,                $ ; rad prof centroid label 2 id
	   rprfcrlab3  :   0L,                $ ; rad prof centroid label 3 id
	   rprfcrlab4  :   0L,                $ ; rad prof centroid label 4 id
	   rprfcrlab5  :   0L,                $ ; rad prof centroid label 5 id
	   rpymintxt   :   0L,                $ ; rad prof ymin text field
	   rpymaxtxt   :   0L,                $ ; rad prof ymax text field
	   rpautobutton:   0L,                $ ; rad prof autoscale button
	   rplogbutton :   0L,                $ ; rad prof log scale button
	   rpoplotbutton:  0L,                $ ; rad prof overplot button
	   rpeebutton  :   0L,                $ ; rad prof enc energy button
	   rpautocenButton: 0L,               $ ; rad prof auto center (wm mom)
	   rpfitcircleButton: 0L,             $ ; rad prof fit circle/square 
	   rp_autoscl  :   1,                 $ ; autoscale y axis of rad prof
	   rpxcentxt   :   0L,                $ ; rad prof/centroid x center
	   rpycentxt   :   0L,                $ ; rad prof/centroid y center
	   rpradiustxt :   0L,                $ ; rad prof radius
	   rpfwhmtxt   :   0L,                $ ; rad prof centroid fwhm
	   rpsmxtxt    :   0L,                $ ; rad prof smooth width
	   rpmethods   :   0L,                $ ; rad prof methods
	   rpwmhbtxt   :   0L,                $ ; rad prof wgt moment halfbox
	   rprfline    :   0,                 $ ; radial profile line type
	   rpgcntr_ovly:   0,                 $ ; overlay contours on image
	   radpfim     :   ptr_new(),         $ ; pointer to 2D radial profile
	   rcollapsim  :   ptr_new(),         $ ; pointer to roi collapsed image
	   idp3rpsnp   :   0L,                $ ; Radial Profile SNR ID
	   snplot      :   0L,                $ ; SNR drawid
	   snlab       :   0L,                $ ; SNR label id
	   npBase      :   0L,                $ ; top widget of noise profile
	   idp3npf     :   0L,                $ ; noise profile plot widget
	   npfdraw     :   0L,                $ ; noise profile plot draw id
	   npfymintxt  :   0L,                $ ; noise profile ymin field
	   npfymaxtxt  :   0L,                $ ; noise profile ymax field
	   npautobutton:   0L,                $ ; noise prof autoscale button
	   nplogbutton :   0L,                $ ; noise prof log scale button
	   npoplotbutton:  0L,                $ ; noise prof overplot button
	   np_autoscl  :   1,                 $ ; autoscale y axis of noise prof
	   nprfline    :   0,                 $ ; noise profile line type
	   histdraw    :   0L,                $ ; histogram drawid
	   histmin     :   0.,                $ ; min histogram value
	   histmax     :   0.,                $ ; max histogram value
	   rh_autoscl  :   1,                 $ ; autoscale histogram?
	   rhautobutton:   0L,                $ ; histogram auto scale button
	   rhlogbutton :   0L,                $ ; histogram log scale button
	   roicntrim   :   0L,                $ ; contour drawid
	   roicntr_logs:   0,                 $ ; log spaced levels
	   roicntr_ovly:   0,                 $ ; contour overlay
	   roicntr_levs:   ptr_new(),         $ ; contour levels
	   roifillarr  :   0,                 $ ; fill roi 1-D array
	   roifillval  :   0.,                $ ; fill value for roi 1-D array
	   sprd        :   sprd,              $ ; spreadsheet selection struct
	   statofile   :   ' ',               $ ; statistics output file
	   xsecx       :   ptr_new(),         $ ; cross section X values
	   xsecy       :   ptr_new(),         $ ; cross section Y values
	   xsgfit      :   ptr_new(),         $ ; cross section gaussian fit
	   xsbasefit   :   ptr_new(),         $ ; cross section baseline fit
	   radpx       :   ptr_new(),         $ ; radial profile X values
	   radpy       :   ptr_new(),         $ ; radial profile Y values
	   radstd      :   ptr_new(),         $ ; radial profile std dev
	   radee       :   ptr_new(),         $ ; rad profile enc energy vals
	   radnpt      :   ptr_new(),         $ ; number points for profile
	   radrej      :   ptr_new(),         $ ; radial profile rejected pix
	   rpgaussim1  :   ptr_new(),         $ ; rad prof raw data
	   rpgaussim2  :   ptr_new(),         $ ; rad prof gauss fit data
	   rp2d        :   ptr_new(),         $ ; 2D rad prof image
	   noispx      :   ptr_new(),         $ ; noise profile X values
	   noispy      :   ptr_new(),         $ ; noise profile Y values
	   noispa      :   ptr_new(),         $ ; noise profile area values
	   noispm      :   ptr_new(),         $ ; noise profile mean values
	   noispr      :   ptr_new(),         $ ; noise profile rej pts values
	   noispp      :   ptr_new(),         $ ; noise profile no of pts vals
	   rhisto      :   ptr_new(),         $ ; roi histogram array
	   rh_xax      :   ptr_new(),         $ ; roi histogram x axis
           dispim      :   dispim,            $ ; current display image
	   alphaim     :   alphaim,           $ ; current display alpha channel
           dispx       :   dispx,             $ ; current display image x size
           dispy       :   dispy,             $ ; current display image y size
           maxxpoint   :   0,                 $ ; current disp image max x data
           maxypoint   :   0,                 $ ; current disp image max y data
	   sxoff       :   0,                 $ ; screen x offset
	   syoff       :   0,                 $ ; screen y offset
	   sxtemp      :   0,                 $ ; screen x offset temp
	   sytemp      :   0,                 $ ; screen y offset temp
	   llinex      :   0,                 $ ; line draw x last
	   lliney      :   0,                 $ ; line draw y last
	   movement    :   0,                 $ ; movement flag
	   imagepath   :   imagepath,         $ ; image file path
	   listpath    :   listpath,          $ ; path for lists
	   savepath    :   savepath,          $ ; directory path to save data 
	   parpath     :   parpath,           $ ; directory path for par files 
	   imfilter    :   imfilter,          $ ; file filter for loading images
	   listfilter  :   listfilter,        $ ; file filter for loading lists
	   parfilter   :   parfilter,         $ ; file filter for loading pars
	   extnam      :   extnam,            $ ; name of image extension
	   mpixlab     :   mpixlab,           $ ; mainpixLabel widget ID
	   morientlab  :   morientlab,        $ ; mainorientation label ID
	   mwcslab     :   mwcslab,           $ ; mainwcsLabel widget ID
	   rwcslab     :   0L,                $ ; roiwcsLabel widget ID
	   pixval      :   0L,                $ ; pixvalLabel widget ID
	   pixval2     :   0L,                $ ; pixval2Label widget ID
	   roimskonof  :   0L,                $ ; roi mask on/off button ID
	   mdioz       :   main_display_interpolation_on_zoom,        $
	   roiioz      :   region_of_interest_interpolation_on_zoom,  $
	   ios         :   interpolation_on_shift,                    $
	   mddz        :   main_display_dezoom,                       $
	   sip         :   show_images_path,                          $
	   mpsz        :   main_ps_size,                              $
	   rpsz        :   roi_ps_size,                               $
	   scb         :   show_color_bar,                            $
	   sfits       :   basic_fits,                                $
	   roibox      :   roi_box,                                   $
	   zoomflux    :   zoom_flux,                                 $
	   plot_xscale :   plot_xscale,       $ ; plot x scaling
	   plot_yscale :   plot_yscale,       $ ; plot y scaling
	   plot_linwid :   plot_linwid,       $ ; line thickness plot print 
	   header_char :   header_char,       $ ; character preceding hdr lines
	   adjnegoff   :   adjnegoff,         $ ; adjust for offsets < 0 -align
	   name_delim  :   name_delim,        $ ; filename delimiter
	   show_wcs    :   show_wcs,          $ ; show world coordinates flag
	   wcs_str     :   wcs_str,           $ ; string for wcs
	   ref_warn    :   ref_warn,          $ ; warn when ref image turned off
	   load_planes :   load_planes,       $ ; planes of 3-D image to load
	   invalid     :   invalid,           $ ; value of invalid pixel
	   exclude_invalid : exclude_invalid, $ ; invalid pix val when combining
	   rpcofov     :   rpcenter_out_fov,  $ ; allow rp center outside fov
           rpsmoothwid :   rpsmoothwid,       $ ; boxcar smoothing width for rp
	   rpradius    :   rpradius,          $ ; fixed radial profile radius
           rpbkgxoff   :   rpbkgxoff,         $ ; x offset from center for bkg
           rpbkgyoff   :   rpbkgyoff,         $ ; y offset from center for bkg
	   color_radpf :   color_radpf,       $ ; color to mark radial profile
	   color_poly  :   color_poly,        $ ; color to mark polygons
	   color_innernpf: color_innernpf,    $ ; color to mark inner noise prf
	   color_outernpf: color_outernpf,    $ ; color to mark outer noise prf
	   color_xsect :   color_xsect,       $ ; color to mark cross section
	   color_spsh  :   color_spsh,        $ ; color to mark spreadsheet
	   color_roi   :   color_roi,         $ ; color to mark roi region
	   color_orient:   color_orient,      $ ; color of orientation vector
	   color_bits  :   color_bits,        $ ; no preallocated color bits
	   sdelay      :   blink_delay,       $ ; blink delay between series
	   fdelay      :   iblink_delay,      $ ; blink delay between frames
	   btimes      :   blink_times,       $ ; blink times
	   bcount      :   blink_count,       $ ; blink counter
	   bimcount    :   0,                 $ ; blink image counter
	   histbins    :   histbins,          $ ; number of bins in histogram
	   pixorg      :   pixel_origin,      $ ; pixel origin (0=cntr,1=lledge)
	   negsig      :   negsig,            $ ; neg sigma limit for mean
	   possig      :   possig,            $ ; pos sigma limit for mean
	   combim      :   combim,            $ ; method from combining data
	   cbstdev     :   cbstdev,           $ ; compute stdev image
	   cbnsigma    :   cbnsigma,          $ ; compute n sigma image
	   cbnpixels   :   cbnpixels,         $ ; compute no pixels image
	   cbsav2idp3  :   cbsav2idp3,        $ ; save combine results to idp3
	   cbsav2file  :   cbsav2file,        $ ; save combine results to file
	   smsav2idp3  :   smsav2idp3,        $ ; save main display to idp3
	   smsav2file  :   smsav2file,        $ ; save main display to file 
	   srsav2idp3  :   srsav2idp3,        $ ; save roi display to idp3
	   srsav2file  :   srsav2file,        $ ; save roi display to file 
	   masktol     :   masktol,           $ ; mask good tolerance
	   sourcezoom  :   sourcezoom,        $ ; zoom factor for Source Def
	   doeons      :   doeons,            $ ; build eons menu
	   inner_radius :  inner_radius,      $ ; flux normalization inner rad
	   outer_radius :  outer_radius,      $ ; flux normalization outer rad
           master_shifts:  master_shifts,     $ ; master_shifts file
	   coron_mask  :   coron_mask,        $ ; coronagraphic mask
	   mask_xcenter:   mask_xcenter,      $ ; mask x center
	   mask_ycenter:   mask_ycenter,      $ ; mask y center
	   coron_badpix:   coron_badpix,      $ ; coronagraphic bad pixel list
	   dospitzer   :   dospitzer,         $ ; load mips menu
	   m_pctnan    :   m_pctnan,          $ ; mips % nans allowed
	   m_zoom      :   m_zoom,            $ ; mips zoom factor
	   m_thresh    :   m_thresh,          $ ; mips median threshold
	   m_tbirad    :   m_tbirad,          $ ; mips object bkg inner radius
	   m_tborad    :   m_tborad,          $ ; mips object bkg outer radius
	   m_trad      :   m_trad,            $ ; mips target radius
	   m_refit     :   m_refit,           $ ; mips refit object center
	   m_pbirad    :   m_pbirad,          $ ; mips psf bkg inner radius
	   m_pborad    :   m_pborad,          $ ; mips psf bkg outer radius
	   m_prad      :   m_prad,            $ ; mips psf radius
	   m_pxcen     :   m_pxcen,           $ ; mips psf x center
	   m_pycen     :   m_pycen,           $ ; mips psf y center
	   doirs       :   doirs,             $ ; do irs special functions
	   loadsmButton:   0L,                $ ; smart load procedure
	   dofeps      :   dofeps,            $ ; do feps special functions
	   feps_analyst:   feps_analyst,      $ ; feps photometry analyst
           fepstb1ref  :   feps_table1_ref,   $ ; feps table 1 reference
	   fepstb5ref  :   feps_table5_ref,   $ ; feps table 5 reference
	   fepstb6ref  :   feps_table6_ref,   $ ; feps table 6 reference
	   wpos        :   wpos,              $ ; widget position structure
	   idp3Draw    :   idp3Draw           } ; the draw widget identifier

  ; Save the info structure in the main widget base uvalue.
  Widget_Control, idp3Window, Set_UValue = info

  if ex_smart eq 1 then !sm_idp3_id = idp3Window

  XManager, 'idp3', idp3Window, /No_Block, Event_Handler='Idp3_Resize'
end
