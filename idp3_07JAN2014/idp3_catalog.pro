pro idp3_catalog_ev, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=catinfo
  Widget_Control, catinfo.info.idp3Window, Get_UValue=info

  case event.id of

  catinfo.selectname: begin
    Widget_Control, catinfo.selectname, Get_Value = temp
    catname = strtrim(temp[0],2)
    info.catalog.name = catname
  end

  catinfo.browseButton: begin
    filevalue = Dialog_Pickfile(title='Please select Catalog to Load')
    catname = filevalue
    Widget_Control, catinfo.selectname, Set_Value = catname
    info.catalog.name = catname
  end

  catinfo.loadButton: begin
    Widget_Control, catinfo.selectname, Get_Value = temp
    catname = strtrim(temp[0],2)
    readintermini_udf, catname, data, catnumber, znum, ebvnum, tnum
    if round(catnumber) lt 1 then begin
      str = 'Catalog: Empty catalog'
      idp3_updatetxt, info, str
      return
    endif
    info.catalog.name = catname
    info.catalog.entries = catnumber
    id = data[*].id
    ra = data[*].ra
    dec = data[*].dec
    xpos = data[*].x
    ypos = data[*].y
    zpf = data[*].zpf
    ebvpf = data[*].ebvpf
    tempnum = data[*].tempnum
    apmag = data[*].apmag
    if ptr_valid(info.catalog.id) then ptr_free, info.catalog.id
    if ptr_valid(info.catalog.ra) then ptr_free, info.catalog.ra
    if ptr_valid(info.catalog.dec) then ptr_free, info.catalog.dec
    if ptr_valid(info.catalog.xpos) then ptr_free, info.catalog.xpos
    if ptr_valid(info.catalog.ypos) then ptr_free, info.catalog.ypos
    if ptr_valid(info.catalog.zpf) then ptr_free, info.catalog.zpf
    if ptr_valid(info.catalog.ebvpf) then ptr_free, info.catalog.ebvpf
    if ptr_valid(info.catalog.tempnum) then ptr_free, info.catalog.tempnum
    if ptr_valid(info.catalog.apmag) then ptr_free, info.catalog.apmag
    info.catalog.id = ptr_new(id)
    info.catalog.ra = ptr_new(ra)
    info.catalog.dec = ptr_new(dec)
    info.catalog.xpos = ptr_new(xpos)
    info.catalog.ypos = ptr_new(ypos)
    info.catalog.zpf = ptr_new(zpf)
    info.catalog.ebvpf = ptr_new(ebvpf)
    info.catalog.tempnum = ptr_new(tempnum)
    info.catalog.apmag = ptr_new(apmag)
    data = 0
    str = 'Catalog: ' + info.catalog.name + string(info.catalog.entries)
    idp3_updatetxt, info, str
  end

  catinfo.radField: begin
    Widget_Control, catinfo.radField, Get_Value=rad
    if rad lt 1.0 or rad gt 50. then begin
      str = 'Catalog: Invalid value for radius'
      idp3_updatetxt, info, str
      return
    endif
    info.catradius = rad
  end

  catinfo.minredField: begin
    Widget_Control, catinfo.minredField, Get_Value=red
    if red lt 0. then begin
      str = 'Catalog: Invalid value for Minimum Redshift'
      idp3_updatetxt, info, str
      return
    endif
    info.catminred = red
  end

  catinfo.maxredField: begin
    Widget_Control, catinfo.maxredField, Get_Value=red
    if red le 0. then begin
      str = 'Catalog: Invalid value for Maximum Redshift'
      idp3_updatetxt, info, str
      return
    endif
    info.catmaxred = red
  end

  catinfo.raField: begin
    Widget_Control, catinfo.raField, Get_Value=temp
    ra = strtrim(temp[0])
    str = ra + '  00:00:00.0'
    get_coords, pos, 2, instring=str
    if pos[0] lt 0. or pos[0] gt 24.0 then begin
      stat = Widget_Message('RA out of bounds')
      return
    endif
  end

  catinfo.decField: begin
    Widget_Control, catinfo.decField, Get_Value=temp
    dec = strtrim(temp[0])
    str = '00:00:00.0  ' + dec
    get_coords, pos, 2, instring=str
    if pos[1] lt -90. or pos[0] gt 90.0 then begin
      stat = Widget_Message('Dec out of bounds')
      return
    endif
  end

  catinfo.findrdButton: begin
    Widget_Control, catinfo.raField, Get_Value = temp
    sra = strtrim(temp[0])
    Widget_Control, catinfo.decField, Get_Value = temp
    sdec = strtrim(temp[0])
    str = sra + '  ' + sdec
    get_coords, pos, 2, instring=str
    if pos[0] lt 0. or pos[0] gt 24.0 then begin
      stat = Widget_Message('RA out of bounds')
      return
    endif
    if pos[1] lt -90. or pos[0] gt 90.0 then begin
      stat = Widget_Message('Dec out of bounds')
      return
    endif
    ra = pos[0] * 15.0
    dec = pos[1]
    ims = info.images
    imptr = (*ims)[info.moveimage]
    xz = (*imptr).xsiz
    yz = (*imptr).ysiz
    idp3_getcoords, 1, xcen, ycen, ra, dec, imstr = imptr
    if xcen gt 0 and xcen lt xz and ycen gt 0 and ycen lt yz then begin
      info.catposx = xcen
      info.catposy = ycen
      idp3_display, info
    endif else begin
      str = ' '
      if xcen lt 0 then str = 'RA outside data at left' 
      if xcen gt xz then str = 'RA outside field at right'
      if ycen lt 0 then str = str + '  Dec outside field at bottom'
      if ycen gt yz then str = str + '  Dec outside field at top'
      stat = Widget_Message(str)
    endelse
  end

  catinfo.displayButton: begin
    if info.catdisp eq 0 then begin
      str = 'Catalog: No display method selected'
      idp3_updatetxt, info, str
      return
    endif else begin
      ncolor = 10
      Widget_Control, catinfo.minredField, Get_Value=minshift
      Widget_Control, catinfo.maxredField, Get_Value=maxshift
      info.catminred = minshift
      info.catmaxred = maxshift
      delta = (maxshift-minshift)/float(ncolor)
      idp3_getcolor, ncolor, 13
      info.color_bits = ncolor
      xloc = round(*info.catalog.xpos)
      yloc = round(*info.catalog.ypos)
      if info.catdisp eq 1 or info.catdisp eq 3 then begin
	redshift = *info.catalog.zpf > minshift < maxshift
        n1 = where(redshift eq minshift, n1cnt)
        n2 = where(redshift eq maxshift, n2cnt)
        str = 'Catalog: min: ' + string(n1cnt) + '  max: ' + string(n2cnt)
	idp3_updatetxt, info, str
        th=fltarr(361)
        for i=0,360 do th(i)=float(i)*(!pi/180.)
        Widget_Control, catinfo.radField, Get_Value=rad
        info.catradius = rad
	ctemp = fix(((redshift-minshift) / (maxshift-minshift)) * $
                float(ncolor-1) + 0.5)
	wset, info.catdraw
	im = bytarr(550,50)
	im[*,*] = 255
	tv, im
	for jj = 0, ncolor-1 do begin
	  zz = where(ctemp eq jj, zcnt)
	  smin = minshift + delta * float(jj) 
	  smax = smin + delta
	  str = string(smin,'$(f3.1)') + '-' + string(smax,'$(f3.1)') + $
		': ' + strtrim(string(zcnt,'$(i4)'),2)
          if jj lt 5 then begin
	    yy = 27
	    xx = jj * 115 + 2
          endif else begin
	    yy = 7 
	    xx = (jj-5) * 115 + 2
          endelse
          xyouts, xx, yy, str, /device, color=jj, charsize=1.1
        endfor
        for i = 0, info.catalog.entries-1 do begin
	  wset, info.drawid1
          xx = xloc[i] 
          yy = yloc[i]
	  if xx lt info.drawxsize and yy lt info.drawysize then $
            plots, rad*cos(th) + xx, rad*sin(th) + yy, color=ctemp[i], /device
	  if XRegistered('idp3_roi') then begin
	    wset, (*info.roi).drawid2
	    x1 = (*info.roi).roixorig
	    x2 = (*info.roi).roixend
	    y1 = (*info.roi).roiyorig
	    y2 = (*info.roi).roiyend
	    zoom = (*info.roi).roizoom
	    zrad = rad * zoom
	    if xx ge x1 and xx le x2 and yy ge y1 and yy le y2 then begin
	      zxx = (xx - x1) * zoom
	      zyy = (yy - y1) * zoom
	      plots, zrad*cos(th)+zxx, zrad*sin(th)+zyy, color=ctemp[i], /device
            endif
          endif
        endfor
	ctemp = 0
      endif 
      if info.catdisp eq 2 or info.catdisp eq 3 then begin
        for i = 0, info.catalog.entries-1 do begin
	  wset, info.drawid1
	  id = *info.catalog.id
	  xx = xloc[i]
	  yy = yloc[i]
	  if xx lt info.drawxsize and yy lt info.drawysize then begin
	    str = strtrim(string(round(id[i])),2)
	    xyouts, xx, yy, str, /device, color=green
          endif
	  if XRegistered('idp3_roi') then begin
	    wset, (*info.roi).drawid2
	    x1 = (*info.roi).roixorig
	    x2 = (*info.roi).roixend
	    y1 = (*info.roi).roiyorig
	    y2 = (*info.roi).roiyend
	    zoom = (*info.roi).roizoom
	    if xx ge x1 and xx le x2 and yy ge y1 and yy le y2 then begin
	      zxx = (xx - x1) * zoom
	      zyy = (yy - y1) * zoom
	      xyouts, zxx, zyy, str, /device, color=green
            endif
          endif
        endfor
      endif
    endelse
  end

  catinfo.idField: begin
    Widget_Control, catinfo.idField, Get_Value = id
    info.catid = id
    idp3_display, info
  end

  catinfo.clearButton: begin
    info.catdisp = 0
    Widget_Control, catinfo.sButtons, Set_Value=[0,0]
    wset, info.catdraw
    loadct, 0
    color6
    im = bytarr(550,50)
    im[*,*] = 255
    tv, im
    idp3_display, info
  end

  catinfo.sButtons: begin
    Widget_Control, catinfo.sButtons, Get_Value=barray
    info.catdisp = barray[0] + barray[1]*2
  end

  catinfo.deleteButton: begin
    info.catalog.name = ' '
    info.catalog.entries = 0
    ptr_free, info.catalog.id
    ptr_free, info.catalog.ra
    ptr_free, info.catalog.dec
    ptr_free, info.catalog.xpos
    ptr_free, info.catalog.ypos
    ptr_free, info.catalog.apmag
  end

  catinfo.doneButton: begin
    info.catdisp = 0
    loadct, 0
    color6
    idp3_display, info
    Widget_Control, catinfo.info.idp3Window, Set_UValue=info
    Widget_Control, event.top, /Destroy
    return
  end
  endcase

  Widget_Control, catinfo.info.idp3Window, Set_UValue=info
  Widget_Control, event.top, Set_UValue=catinfo

end

pro idp3_catalog, event

@idp3_structs
@idp3_errors

  if(XRegistered("idp3_catalog")) then return

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  title = 'IDP3 Load/Show UDF Catalog'
  catbase = Widget_Base  (Title = title, /Column, Group_Leader=event.top, $
       XOffset=info.wpos.mpwp[0], YOffset = info.wpos.mpwp[1])
 
  rad = info.catradius
  disp = info.catdisp
  name = info.catalog.name
  case disp of
   0: dd = [0,0]
   1: dd = [1,0]
   2: dd = [0,1]
   3: dd = [1,1]
   else:
  endcase
  catbase1 = Widget_Base(catbase, /Row)
  label = Widget_Label(catbase1, Value='Filename:')
  selectname = Widget_Text(catbase1, Value = name, XSize = 60, /Edit)
  browseButton = Widget_Button(catbase1, Value='Browse', /align_center)
  loadButton = Widget_Button(catbase1, Value='Load', /align_center)
  doneButton = Widget_Button(catbase1, Value = 'Done', /align_center)
  catbase2 = Widget_Base(catbase, /Row)
  radField = cw_field(catbase2, value=rad, title='Radius:', $
	  xsize=5, /Return_Events, /Floating)
  idField = cw_field(catbase2, value=sid, title=' ID:', $
	  xsize=5, /Return_Events, /Integer)
  raField = cw_field(catbase2, value=' ', title=' RA:', $
	  xsize=12, /Return_Events, /String)
  decField = cw_field(catbase2, value=' ', title='Dec:', $
	  xsize=12, /Return_Events, /String)
  findrdButton = Widget_Button(catbase2, value='Find RA/Dec', /align_center)
  catbase3 = Widget_Base(catbase, /Row)
  minredField = cw_field(catbase3, value=info.catminred,title='Redshift: Min', $
	  xsize=5, /Return_Events, /Floating)
  maxredField = cw_field(catbase3, value=info.catmaxred, title='Max', $
	  xsize=5, /Return_Events, /Floating)
  snames = ['Objects', 'Obj IDs ']
  sButtons = cw_bgroup(catbase3, snames, row=1, uvalue='sbutton', $
      set_value=dd, /nonexclusive, $
      label_left=' Show:')
  displayButton = Widget_Button(catbase3, Value='Display', /align_center)
  clearButton = Widget_Button(catbase3, Value = 'Clear', /align_center)
  deleteButton = Widget_Button(catbase3, Value = 'Delete', /align_center)
  catlabel = Widget_Draw(catbase, xsize=550, ysize=50)


  catinfo = { sButtons       :   sButtons,       $
              selectname     :   selectname,     $
	      browseButton   :   browseButton,   $
	      loadButton     :   loadButton,     $
	      findrdButton   :   findrdButton,   $
	      radField       :   radField,       $
	      idField        :   idField,        $
	      raField        :   raField,       $
	      decField       :   decField,       $
	      minredField    :   minredField,    $
	      maxredField    :   maxredField,    $
	      displayButton  :   displayButton,  $
	      clearButton    :   clearButton,    $
	      deleteButton   :   deleteButton,   $
	      doneButton     :   doneButton,     $
	      info           :   info            }

  Widget_Control, catbase, set_uvalue = catinfo
  Widget_Control, catbase, /Realize
  Widget_Control, catlabel, Get_Value = catdraw
  info.catdraw = catdraw
  Widget_Control, info.idp3Window, Set_UValue=info

  XManager, "idp3_catalog", catbase, Event_Handler = "idp3_catalog_ev", $
       /No_Block
end
