pro Idp3_rpstack, event
  
@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=tinfo
  Widget_Control, tinfo.idp3Window, Get_UValue=info

  c = size(*info.images)
  if c[0] eq 0 and c[1] eq 2 then begin
    return
  endif
  
  roi = info.roi
  x1 = (*roi).roixorig
  y1 = (*roi).roiyorig
  x2 = (*roi).roixend
  y2 = (*roi).roiyend
  zoom = (*roi).roizoom
  dxs = info.drawxsize
  dys = info.drawysize
  xsize = (abs(x2-x1)+1) * zoom
  ysize = (abs(y2-y1)+1) * zoom
  ztype = info.roiioz
  xcent = (*roi).radxcent
  xc = xcent/zoom + x1
  ycent = (*roi).radycent
  yc = ycent/zoom + y1
  trad = (*roi).radradius
  rad = trad/zoom
  if abs(info.rpbkgxoff) gt 0. then begin
    bxcent = xcent + info.rpbkgxoff * zoom > 0 < (xsize-1)
    bxc = bxcent/zoom + x1
  endif else bxcent = -1
  if abs(info.rpbkgyoff) gt 0. then begin
    bycent = ycent + info.rpbkgyoff * zoom > 0 < (ysize-1)
    byc = bycent/zoom + y1
  endif else bycent = -1

  refname = (*(*info.images)[info.moveimage]).name
  ua_decompose, refname, disk, path, rname, extn, version
  title = ';  Radial profile and encircled energy calculations for list'
  title1 = '; Reference image: ' + refname + '   Zoom factor: ' + $
      strtrim(string(zoom),2)
  title11 =  '  profile center: ' + $
       strtrim(string(xc),2) + ', ' +  strtrim(string(yc),2) + $
       ' radius: ' + strtrim(string(rad),2)
  if bxcent gt 0. and bycent gt 0. then title3 = $
       'Background Center: ' + strtrim(string(bxc),2) + ', ' + $
       strtrim(string(byc),2)
  title2 = '  Name           XOffset      YOffset     Profile' + $
      '       Enc_Energy'
  if bxcent gt 0 and bycent gt 0 then title2 = title2 + $
      '   Bkg Enc_Energy'
  numimages = n_elements(*info.images)
  numon = 0
  for i = 0, numimages-1 do begin
    if (*(*info.images)[i]).vis eq 1 then numon = numon + 1
  endfor
  
  if numon le 1 then begin
    print, 'no profiles to stack'
    return
  endif

  rpstack = fltarr(numon)
  eestack = fltarr(numon)
  if bxcent gt 0. and bycent gt 0. then beestack = fltarr(numon)

  openw, slun, 'stack_profile.txt', /get_lun 
  printf, slun, title
  printf, slun, title1
  printf, slun, title11
  if bxcent gt 0 and bycent gt 0 then printf, slun, title3
  printf, slun, '  '
  printf, slun, title2
  print, title2
  pcnt = 0
  for im = 0, numimages-1 do begin
    if (*(*info.images)[im]).vis eq 1 then begin
      m = (*info.images)[im]
      name = (*m).name
      ua_decompose, name, disk, path, nam, extn, version
      iname = nam + extn
      maxx = ((*m).xsiz + 2 * (*m).pad) * (*m).xpscl * (*m).zoom + (*m).xoff
      maxy = ((*m).ysiz + 2 * (*m).pad) * (*m).ypscl * (*m).zoom + (*m).yoff
      maxx = maxx + info.sxoff
      maxy = maxy + info.syoff
      if maxx lt dxs then maxx = dxs
      if maxy lt dys then maxy = dys
      dispim = fltarr(maxx,maxy)   ; An empty display array
      mdst = idp3_setdata(info, im)
      mds = mdst[*,*,0]
      ; Determine where this image should be in the display.
      ; check offsets, check boundaries, etc.
      xoff = (*m).xoff + info.sxoff
      yoff = (*m).yoff + info.syoff
      xsiz = ((*m).xsiz + 2 * (*m).pad) * (*m).zoom * (*m).xpscl
      ysiz = ((*m).ysiz + 2 * (*m).pad) * (*m).zoom * (*m).ypscl
      idp3_checkbounds,maxx,maxy,xsiz,ysiz,xoff,yoff,dxmin,dxmax,dymin,dymax, $
			  gxmin,gxmax,gymin,gymax,err
      dispim[gxmin:gxmax,gymin:gymax] = $
	  dispim[gxmin:gxmax,gymin:gymax] + mds[dxmin:dxmax,dymin:dymax]
      dataimage = idp3_congrid(dispim[x1:x2,y1:y2], xsize, ysize, $
	  zoom,ztype,info.pixorg)
      if info.zoomflux eq 1 then dataimage[*,*] = $
	   dataimage[*,*]/(roi.roizoom ^ 2)
      xo = (*m).xoff + (*m).xpoff + info.sxoff
      yo = (*m).yoff + (*m).ypoff + info.syoff
      nbins = fix((*roi).radradius) + 1
      theplot = fltarr(nbins)
      totalplot = fltarr(nbins)
      stdplot = fltarr(nbins)
      eeplot = fltarr(nbins)
      theplotcount = intarr(nbins)
      nrej = intarr(nbins)
      maxpt = fix(nbins*2*!pi) + 50
      tempdat = fltarr(nbins,maxpt)
      rsz = size(dataimage)
      minx = xcent - trad > 0
      maxx = xcent + trad < (rsz[1]-1)
      miny = ycent - trad > 0
      maxy = ycent + trad < (rsz[2]-1)
      if bxcent gt 0. and bycent gt 0. then begin
        if XRegistered('idp3_radprof') then begin
          th = fltarr(361)
          wset, (*info.roi).drawid2
          for i = 0,360 do th[i] = float(i)*(!pi/180.)
          plots, trad*cos(th)+bxcent, trad*sin(th)+bycent,$
            color=3, /device
        endif
        btheplot = fltarr(nbins)
        btotalplot = fltarr(nbins)
        btheplotcount = intarr(nbins)
        bstdplot = fltarr(nbins)
        beeplot = fltarr(nbins)
        bnrej = intarr(nbins)
        bmaxpt = maxpt
        btempdat = fltarr(nbins, bmaxpt)
        bminx = bxcent - trad > 0
        bmaxx = bxcent + trad < (rsz[1]-1)
        bminy = bycent - trad > 0
        bmaxy = bycent + trad < (rsz[2]-1)
      endif
      tmp = ptr_new(bytarr(xsize,ysize))
      (*tmp)[*,*] = 1
      if (*roi).msk eq 1 then begin
        tmpmask = (*(*roi).mask)
        xoff = (*roi).msk_xoff
        yoff = (*roi).msk_yoff
        goodval = (*roi).maskgood
        tmpmsk = idp3_roimask(x1, x2, y1, y2, tmpmask, xoff, yoff, goodval)
        roimask = congrid(tmpmsk,xsize,ysize)
        bad = where(roimask ne (*roi).maskgood, cnt)
        if cnt gt 0 then (*tmp)[bad] = 0
      endif
      for j = miny,maxy do begin
        for i = minx,maxx do begin
          r = fix(sqrt((i-xcent)^2+(j-ycent)^2))
          if r le nbins-1 then begin
      	    if ((*tmp)[i,j] eq 1) then begin
	      totalplot[r] = totalplot[r] + (dataimage)[i,j]
	      tempdat[r,theplotcount(r)] = (dataimage)[i,j]
	      theplotcount[r] = theplotcount[r] + 1
	    endif else begin
	      nrej[r] = nrej[r] + 1
            endelse
          endif
        endfor
      endfor
      for i = 0, n_elements(totalplot)-1 do begin
        eeplot[i] = total(totalplot[0:i])
      endfor
      domedian = (*roi).rpmm
      if domedian eq 0 then begin
        for i = 0, nbins-1 do begin
          num = theplotcount[i]-1
          if num gt 0 then begin
            results = moment(tempdat[i,0:num])
            stdplot(i) = SQRT(results[1])
          endif else begin
            stdplot(i) = 0.
          endelse
        endfor
        indx = where(theplotcount gt 0,cnt1)
        temp = where(theplotcount le 0,cnt)
        if cnt gt 0 then begin
          if cnt1 gt 0 then begin
            theplot(indx) = totalplot(indx)/theplotcount(indx)
          endif
        endif else begin
          theplot = totalplot/theplotcount
        endelse
      endif else begin
        for i = 0, nbins-1 do begin
          num = theplotcount[i]-1
          if num gt 0 then begin
	    med = median(tempdat[i,0:num], /even)
	    std = sqrt(total((tempdat[i,0:num]-med)^2)/(num-1))
	    theplot[i] = med
  	    stdplot[i] = std
          endif else begin
	    theplot[i] = totalplot[i]
	    stdplot[i] = 0.
          endelse
        endfor
      endelse
      if theplotcount[0] eq 0 then begin
        theplot = theplot[1:nbins-1]
        totalplot = totalplot[1:nbins-1]
        theplotcount = theplotcount[1:nbins-1]
        eeplot = eeplot[1:nbins-1]
        nrej = nrej[1:nbins-1]
        stdplot = stdplot[1:nbins-1]
      endif
 
      if bxcent gt 0. and bycent gt 0. then begin 
        for j = bminy,bmaxy do begin
          for i = bminx,bmaxx do begin
            r = fix(sqrt((i-bxcent)^2+(j-bycent)^2))
            if r le nbins-1 then begin
      	      if ((*tmp)[i,j] eq 1) then begin
	        btotalplot[r] = btotalplot[r] + (dataimage)[i,j]
	        btempdat[r,btheplotcount(r)] = (dataimage)[i,j]
	        btheplotcount[r] = btheplotcount[r] + 1
	      endif else begin
	        bnrej[r] = bnrej[r] + 1
              endelse
            endif
          endfor
        endfor
        for i = 0, n_elements(btotalplot)-1 do begin
          beeplot[i] = total(btotalplot[0:i])
        endfor
        domedian = (*roi).rpmm
        if domedian eq 0 then begin
          for i = 0, nbins-1 do begin
            num = btheplotcount[i]-1
            if num gt 0 then begin
              results = moment(btempdat[i,0:num])
              bstdplot(i) = SQRT(results[1])
            endif else begin
              bstdplot(i) = 0.
            endelse
          endfor
          indx = where(btheplotcount gt 0,cnt1)
          temp = where(btheplotcount le 0,cnt)
          if cnt gt 0 then begin
            if cnt1 gt 0 then begin
              btheplot(indx) = btotalplot(indx)/btheplotcount(indx)
            endif
          endif else begin
            btheplot = btotalplot/btheplotcount
          endelse
        endif else begin
          for i = 0, nbins-1 do begin
            num = btheplotcount[i]-1
            if num gt 0 then begin
	      med = median(btempdat[i,0:num], /even)
	      std = sqrt(total((btempdat[i,0:num]-med)^2)/(num-1))
	      btheplot[i] = med
  	      bstdplot[i] = std
            endif else begin
	      btheplot[i] = btotalplot[i]
	      bstdplot[i] = 0.
            endelse
          endfor
        endelse
        if btheplotcount[0] eq 0 then begin
          btheplot = btheplot[1:nbins-1]
          btotalplot = btotalplot[1:nbins-1]
          btheplotcount = btheplotcount[1:nbins-1]
          beeplot = beeplot[1:nbins-1]
          bnrej = bnrej[1:nbins-1]
          bstdplot = bstdplot[1:nbins-1]
        endif
      endif
 
      nel = n_elements(theplot)
      rpstack[pcnt] = theplot[nel-1]
      eestack[pcnt] = eeplot[nel-1]
      if bxcent gt 0. and bycent gt 0. then begin
        bnel = n_elements(btheplot)
        beestack[pcnt] = beeplot[bnel-1]
      endif
      str = iname + string(xo) + string(yo) + string(theplot[nel-1]) + $
            string(eeplot[nel-1])
      if bxcent gt 0. and bycent gt 0. then str = str + $
            string(beeplot[bnel-1])
      printf, slun, str
      print, str
      pcnt = pcnt + 1
    endif
  endfor

  dataimage = 0
  dispim = 0
  tempdat = 0
  theplot = 0
  totalplot = 0
  theplotcount = 0
  eeplot = 0
  nreg = 0
  stdplot = 0
  btempdat = 0
  btheplot = 0
  btotalplot = 0
  btheplotcount = 0
  beeplot = 0
  bnreg = 0
  bstdplot = 0
  rres = moment(rpstack)
  eres = moment(eestack)
  printf, slun, 'Mean RP at radius: ', rres[0], '  RMS: ', sqrt(rres[1])
  printf, slun, 'Mean EE at radius: ', eres[0], '  RMS: ', sqrt(eres[1])
  print, 'Mean RP at radius: ', rres[0], '  RMS: ', sqrt(rres[1])
  print, 'Mean EE at radius: ', eres[0], '  RMS: ', sqrt(eres[1])
  if bxcent gt 0. and bycent gt 0. then begin
    beres = moment(beestack)
    printf, slun, 'Mean Background EE at radius: ', beres[0], '  RMS: ', sqrt(beres[1])
    print,  'Mean Background EE at radius: ', beres[0], '  RMS: ', sqrt(beres[1])
  endif
  close, slun
  free_lun, slun
end
