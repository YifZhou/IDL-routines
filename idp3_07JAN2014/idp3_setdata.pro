function idp3_setdata, info, indx

@idp3_structs
@idp3_errors

    m = (*info.images)[indx]
    ref = info.moveimage
    temp = *(*m).data
    tsz = size(temp)
    atemp = fltarr(tsz[1],tsz[2])
    atemp[*,*] = 1.
    if ptr_valid((*m).xnan) and ptr_valid((*m).ynan) then begin
      nx = *(*m).xnan
      ny = *(*m).ynan
      for i = 0l, n_elements(nx)-1l do begin
	atemp[nx[i], ny[i]] = 0.
      endfor
    endif
    rotx = (*m).rotcx
    roty = (*m).rotcy
    lccx = (*m).olccx
    lccy = (*m).olccy
    if lccx gt 0. and lccy gt 0. then up_cntrd = 1 else up_cntrd = 0
    acrpix1 = (*m).crpix1
    acrpix2 = (*m).crpix2
    acd11 = (*m).cd11
    acd12 = (*m).cd12
    acd21 = (*m).cd21
    acd22 = (*m).cd22

    if ptr_valid((*m).mask) and (*m).maskvis eq 1 then begin
      ; add masked pixels to alpha image
      mtemp = *(*m).mask
      mbad = where(mtemp eq 0, mcnt)
      if mcnt gt 0 then begin
	atemp[mbad] = 0.    ; set pixels in alpha channel to 0
      endif
      mtemp = 0
    endif

    ; should invalid pixels be masked
    if info.exclude_invalid eq 1 then begin
      ebad = where(temp eq info.invalid, ecnt)
      if ecnt gt 0 then begin
	atemp[ebad] = 0.
      endif
    endif
 
    ; Should pixels be edited
    if ptr_valid((*m).xedit) then begin
      xedit = *(*m).xedit
      yedit = *(*m).yedit
      zedit = *(*m).zedit
      num = n_elements(xedit)
      if num gt 0 then begin
	for i = 0, num-1 do begin
	  temp[xedit[i],yedit[i]] = zedit[i]
        endfor
      endif
    endif

    ; Should image be clipped?
    if (*m).clipbottom eq 1 then begin
      d = where(temp le (*m).clipmin, bcount)
      if bcount gt 0 then begin
	print, bcount, ' minimum pixels reset to ', (*m).cminval
	temp(d) = (*m).cminval
      endif
    endif 
    if (*m).cliptop eq 1 then begin
      d = where(temp ge (*m).clipmax, tcount)
      if tcount gt 0 then begin
	print, tcount, ' maximum pixels reset to ', (*m).cmaxval
	temp(d) = (*m).cmaxval
      endif
    endif

    ; Should the Y axis be flipped?
    mdata = temp
    alpha = atemp
    if (*m).flipy eq 1 then begin
      tempsz = size(temp)
      yflip = fix(tempsz[2]/2)-1
      for ii = 0, yflip do begin
        oi = tempsz[2] - 1 - ii
        mdata[*,ii] = temp[*,oi]
        mdata[*,oi] = temp[*,ii]
        alpha[*,ii] = atemp[*,oi]
        alpha[*,oi] = atemp[*,ii]
      endfor
      roty = tempsz[2] - roty - 1
      acrpix1 = tempsz[1] - acrpix1 - 1
      acrpix2 = tempsz[2] - acrpix2 - 1
      if up_cntrd eq 1 then lccy = tempsz[2] - lccy - 1
    endif 
    temp = 0
    atemp = 0

    ; Should image be padded 
    if (*m).topad eq 1 and (*m).pad gt 0 then begin
      tempdata = fltarr((*m).xsiz + 2 * (*m).pad, (*m).ysiz + 2 * (*m).pad)
      tempdata[*,*] = 0.
      tempalpha = fltarr((*m).xsiz + 2 * (*m).pad, (*m).ysiz + 2 * (*m).pad)
      tempalpha[*,*] = 0.
      xbeg = (*m).pad
      ybeg = (*m).pad
      xend = xbeg + (*m).xsiz - 1
      yend = ybeg + (*m).ysiz - 1
      tempdata[xbeg:xend,ybeg:yend] = mdata
      tempalpha[xbeg:xend,ybeg:yend] = alpha
      mdata = tempdata
      tempdata = 0
      alpha = tempalpha
      tempalpha = 0
      rotx = rotx + (*m).pad
      roty = roty + (*m).pad
      acrpix1 = acrpix1 + (*m).pad
      acrpix2 = acrpix2 + (*m).pad
      if up_cntrd eq 1 then begin
	lccx = lccx + (*m).pad
	lccy = lccy + (*m).pad
      endif
    endif
    
    ; is a pixel scale correction to be applied:
    if (*m).xpscl ne 1.0 or (*m).ypscl ne 1.0 then begin
      fxsiz = float((*m).xsiz)
      fpad = float((*m).pad)
      fysiz = float((*m).ysiz)
      newxsz = (fxsiz + 2.0 * fpad) * (*m).xpscl
      newysz = (fysiz + 2.0 * fpad) * (*m).ypscl
      mdata = congrid(mdata, newxsz, newysz, cubic=-0.5)
      alpha = congrid(alpha, newxsz, newysz, cubic=-0.5)
      newsz = size(mdata)
      xszstr = string(newxsz, '$(f12.5)')
      fxsizstr = string(fxsiz, '$(f12.5)')
      fpadstr = string(fpad, '$(f10.5)')
      yszstr = string(newysz, '$(f12.5)')
      fysizstr = string(fysiz, '$(f12.5)')
      if info.zoomflux eq 1 then mdata = mdata/((*m).xpscl*(*m).ypscl)
      rotx = rotx * (*m).xpscl
      roty = roty * (*m).ypscl
      acrpix1 = acrpix1 * (*m).xpscl
      acrpix2 = acrpix2 * (*m).ypscl
      acd11 = acd11 / (*m).xpscl
      acd21 = acd21 / (*m).xpscl
      acd12 = acd12 / (*m).ypscl
      acd22 = acd22 / (*m).ypscl
      if up_cntrd eq 1 then begin
	lccx = lccx * (*m).xpscl
	lccy = lccy * (*m).ypscl
      endif
    endif

    ; Zoom it.  Don't worry about zooming if the zoom is close to one.
    zms = [0.50, 0.333, 0.25, 0.20, 0.125, 0.10]
    facts = [2, 3, 4, 5, 8, 10]
    if (abs((*m).zoom - 1.0) gt .00001) then begin
      match = -1
      for i = 0, n_elements(zms)-1 do begin
        if abs((*m).zoom - zms[i]) le 0.001 then begin
	  match = i
        endif
      endfor
      ;if match gt -1 then image is being dezoomed an integral amount
      if match gt -1 then begin
        xsz = fix(((*m).xsiz + 2.0 * (*m).pad) * (*m).xpscl * (*m).zoom)
        ysz = fix(((*m).ysiz + 2.0 * (*m).pad) * (*m).ypscl * (*m).zoom)
        scl = 1.0 / (facts[match]^2)
        mds = fltarr(xsz,ysz)
	alph = fltarr(xsz,ysz)
        CASE info.mddz of

	  0: begin
	    for j = 0, ysz-1 do begin
	      for i = 0, xsz-1 do begin
		pz = facts[match]
		mds[i,j]=total(mdata[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1]) * scl
		alph[i,j]=total(alpha[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1]) * scl
              endfor
            endfor
	    end

	  1: begin
	    for j = 0, ysz-1 do begin
	      for i = 0, xsz-1 do begin
		pz = facts[match]
		mds[i,j]=median(mdata[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1],/even)
		alph[i,j]=median(alpha[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1],/even)
              endfor
            endfor
	    end
          
	  2: begin
	    for j = 0, ysz-1 do begin
	      for i = 0, xsz-1 do begin
		pz = facts[match]
		mds[i,j]=max(mdata[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1])
		alph[i,j]=max(alpha[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1])
              endfor
            endfor
	    end
	  
	  3: begin
	    for j = 0, ysz-1 do begin
	      for i = 0, xsz-1 do begin
		pz = facts[match]
		mds[i,j]=min(mdata[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1])
		alph[i,j]=min(alpha[i*pz:(i+1)*pz-1,j*pz:(j+1)*pz-1])
              endfor
            endfor
	    end

          else:
	  endcase
      endif else begin
        ; Check the interpolation type and zoom accordingly, defaut to bicubic.
	newxsiz = ((*m).xsiz + 2.0 * (*m).pad) * (*m).xpscl * (*m).zoom
	newysiz = ((*m).ysiz + 2.0 * (*m).pad) * (*m).ypscl * (*m).zoom
        mds = idp3_congrid(mdata, newxsiz, newysiz, (*m).zoom, info.mdioz,  $
	      info.pixorg)
        alph = idp3_congrid(alpha, newxsiz, newysiz, (*m).zoom, info.mdioz, $
	      info.pixorg)
	      
      endelse
      rotx = rotx * (*m).zoom
      roty = roty * (*m).zoom
      acrpix1 = acrpix1 * (*m).zoom
      acrpix2 = acrpix2 * (*m).zoom
      acd11 = acd11 / (*m).zoom
      acd12 = acd12 / (*m).zoom
      acd21 = acd21 / (*m).zoom
      acd22 = acd22 / (*m).zoom 
      if up_cntrd eq 1 then begin
	lccx = lccx * (*m).zoom
	lccy = lccy * (*m).zoom
      endif
    endif else begin
      mds = mdata   ; Zoom is one, just copy the data.
      alph = alpha
    endelse
    mdata = 0
    alpha = 0

    ; The user wants to conserve total flux, divide by square of zoom.
    if info.zoomflux eq 1 then mds = mds/((*m).zoom * (*m).zoom) 

    ; Do rotations, if necessary.
    if abs((*m).rot) gt .0001 then begin
      mds = idp3_rot(mds, (*m).rot, 1.0, rotx, roty, /pivot, cubic=-0.5, $
	missing=0.0, pixdef=info.pixorg)
      alph = idp3_rot(alph, (*m).rot, 1.0, rotx, roty, /pivot, cubic=-0.5, $
	missing=0.0, pixdef=info.pixorg)
      cdr = !DPI/180.0D
      theta = (*m).rot * cdr
      rot_mat = [ [ cos(theta), sin(theta)], $   ;Rotation matrix
		  [-sin(theta), cos(theta)] ]
      crpix = [acrpix1, acrpix2]
      cd = [ [acd11, acd21], [acd12, acd22] ]
      rotc = [rotx,roty]
;      ncrpix = rotc + transpose(rot_mat)#(crpix-1.-rotc) + 1.
      ncrpix = rotc + transpose(rot_mat)#(crpix-rotc)
      newcd = cd # rot_mat
      acrpix1 = ncrpix[0]
      acrpix2 = ncrpix[1]
      acd11 = newcd[0,0]
      acd12 = newcd[0,1]
      acd21 = newcd[1,0]
      acd22 = newcd[1,1]
      if up_cntrd eq 1 then begin
	lcc = [lccx, lccy]
	nlcc = rotc + transpose(rot_mat)#(lcc-rotc)
	lccx = nlcc[0]
	lccy = nlcc[1]
      endif
    endif

    ; Do fractional pixel shifts.  Don't do it if the fraction is too small.
    if abs((*m).xpoff) gt .0001 or abs((*m).ypoff) gt .0001 then begin
      sz = size(mds)
      ios = info.ios
      x = findgen(sz(1))-(*m).xpoff
      y = findgen(sz(2))-(*m).ypoff
      case info.ios of
      0: begin
        mds = interpolate(mds,x,y,cubic=-.5,/grid)      ; bicubic
        alph = interpolate(alph,x,y,cubic=-.5,/grid)    ; bicubic
        end
      1: begin
	mds = interpolate(mds,x,y,/grid)      ; bilinear
	alph = interpolate(alph,x,y,/grid)    ; bilinear
        end
      2: begin
	mds = sshift2d(mds, [(*m).xpoff, (*m).ypoff])
	alph = sshift2d(alph, [(*m).xpoff, (*m).ypoff])
	end
      endcase
      acrpix1 = acrpix1 + (*m).xpoff
      acrpix2 = acrpix2 + (*m).ypoff
      rotx = rotx + (*m).xpoff
      roty = roty + (*m).ypoff
      if up_cntrd eq 1 then begin
	lccx = lccx + (*m).xpoff
	lccy = lccy + (*m).ypoff
      endif
    endif

    if abs((*m).xoff) gt 0.0001 or abs((*m).yoff) gt 0.0001 then begin
      acrpix1 = acrpix1 + (*m).xoff
      acrpix2 = acrpix2 + (*m).yoff
      rotx = rotx + (*m).xoff
      roty = roty + (*m).yoff
      if up_cntrd eq 1 then begin
	lccx = lccx + (*m).xoff
	lccy = lccy + (*m).yoff
      endif
    endif

    ; add 0.5 pixel to reference if pixel origin is lower left
    if info.pixorg eq 1 then begin
      acrpix1 = acrpix1 + 0.5
      acrpix2 = acrpix2 + 0.5
    endif

    ; Scale it.
    if (abs((*m).scl - 1.0) gt .0001) then mds = mds * (*m).scl

    ; Apply bias.
    if ((*m).bias NE 0.0) then mds = mds + (*m).bias

    ; update WCS
    (*m).acrpix1 = acrpix1
    (*m).acrpix2 = acrpix2
    (*m).acd11 = acd11
    (*m).acd12 = acd12
    (*m).acd21 = acd21
    (*m).acd22 = acd22
    (*m).lccx = lccx
    (*m).lccy = lccy
    Widget_Control, info.idp3Window, Set_UValue=info

    ; if adjust position active and this is ref image then update rot center
    if XRegistered('idp3_adjustposition') and ref eq indx then begin
      Widget_Control, info.rtxcenField, Set_Value=rotx
      Widget_Control, info.rtycenField, Set_Value=roty
    endif

    ; if show centroid widget active for this image, update data
    cname = 'idp3_showcntrd' + strtrim(string(indx),2)
    if XRegistered(cname) then begin
      newtext = strarr(2)
      Widget_Control, (*m).cntrdtext, Get_Value = ctext
      newtext[0] = ' (X,Y) =' + string(lccx,'$(f10.4)') + $
		 string(lccy,'$(f10.4)')
      newtext[1] = ctext[1]
      Widget_Control, (*m).cntrdtext, Set_Value = newtext
    endif

    ; reset mask according to tolerance
    sz = size(mds)
    if n_elements(alph) gt 0 then begin
      idp3_checktol, alph, info.masktol
    endif else begin
      alph = fltarr(sz[1],sz[2])
      alph[*,*] = 1.
    endelse
    
    ; return final images
    outim = fltarr(sz[1],sz[2],2)
    outim[*,*,0] = mds
    outim[*,*,1] = alph
    mds=0
    alph=0
    m = 0
    return, outim
end
