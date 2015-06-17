pro idp3_photsquare, tmp, zxcen, zycen, ztr, zbir, zbor, flg, fmask, nbad

  nbad = 0
  if flg eq 0 then begin
    ; square aperture for background
    zboledge = zxcen - zbor
    zboredge = zxcen + zbor
    zbotop = zycen + zbor
    zbobottom = zycen - zbor
    zbiledge = zxcen - zbir
    zbiredge = zxcen + zbir
    zbibottom = zycen - zbir
    zbitop = zycen + zbir
    zbilf = floor(zbiledge)
    zbilc = ceil(zbiledge)
    zbolf = floor(zboledge)
    zbolc = ceil(zboledge)
    zbirf = floor(zbiredge)
    zbirc = ceil(zbiredge)
    zborf = floor(zboredge)
    zborc = ceil(zboredge)
    zbobf = floor(zbobottom)
    zbobc = ceil(zbobottom)
    zbibf = floor(zbibottom)
    zbibc = ceil(zbibottom)
    zbotf = floor(zbotop)
    zbotc = ceil(zbotop)
    zbitf = floor(zbitop)
    zbitc = ceil(zbitop)
    if zbibf lt zbibc then zbibd = zbibottom-float(zbibf) else zbibd=0.
    if zbitf lt zbitc then zbitd = float(zbitc)-zbitop else zbitd=1.
    if zbilf lt zbilc then zbild = zbiledge - float(zbilf) else zbild=0.
    if zbirf lt zbirc then zbird = float(zbirc) - zbiredge else zbird = 1.
    if zbobf lt zbobc then zbobd = float(zbobc) - zbobottom else zbobd=1.
    if zbotf lt zbotc then zbotd = zbotop - float(zbotf) else zbotd=0.
    if zbolf lt zbolc then zbold = float(zbolc) - zboledge else zbold=1.
    if zborf lt zborc then zbord = zboredge - float(zborf) else zbord=0.
    ; set entire box to 1 if pixel not masked
    for j = zbobc, zbotf-1 do begin
      for i = zbolc, zborf-1 do begin
	if tmp[i,j] eq 1 then fmask[i,j] = 1.0 else nbad = nbad + 1
      endfor
      if tmp[zbolf, j] eq 1 then fmask[zbolf,j] = zbold else nbad = nbad + 1
      if tmp[zborf, j] eq 1 then fmask[zborf,j] = zbord else nbad = nbad + 1
    endfor
    for i = zbolc, zborf-1 do begin
      if tmp[i,zbobf] eq 1 then fmask[i,zbobf] = zbobd else nbad = nbad + 1
      if tmp[i,zbotf] eq 1 then fmask[i,zbotf] = zbotd else nbad = nbad + 1
    endfor
    ; turn off inner region
    fmask[zbilf:zbirf,zbibf:zbitf] = 0.0
    for i = zbilc, zbirf-1 do begin
      if tmp[i,zbibf] eq 1 then fmask[i,zbibf] = zbibd else nbad = nbad + 1
      if tmp[i,zbitf] eq 1 then fmask[i,zbitf] = zbitd else nbad = nbad + 1
    endfor
    for i = zbibc, zbitf-1 do begin
      if tmp[zbilf, i] eq 1 then fmask[zbilf,i] = zbild else nbad = nbad + 1
      if tmp[zbirf, i] eq 1 then fmask[zbirf,i] = zbird else nbad = nbad + 1
    endfor
    ; four outer corners
    if tmp[zbolf,zbobf] eq 1 then fmask[zbolf,zbobf] = zbold*zbobd $
       else nbad = nbad + 1
    if tmp[zborf,zbobf] eq 1 then fmask[zborf,zbobf] = zbord*zbobd $
       else nbad = nbad + 1
    if tmp[zbolf,zbotf] eq 1 then fmask[zbolf,zbotf] = zbold*zbotd $
       else nbad = nbad + 1
    if tmp[zborf,zbotf] eq 1 then fmask[zborf,zbotf] = zbord*zbotd $
       else nbad = nbad + 1
    ; four inner corners
    if tmp[zbilf,zbibf] eq 1 then begin
      if zbilf lt zbilc then fmask[zbilf,zbibf] = zbild + zbibd * $
	          (1. - zbild)  else fmask[zbilf,zbibf] = zbibd
    endif else begin
      fmask[zbilf,zbibf] = 0.0
      nbad = nbad + 1
    endelse
    if tmp[zbirf,zbibf] eq 1 then begin
      if zbirf lt zbirc then fmask[zbirf,zbibf] = zbird + zbibd * $
	            (1. - zbird)  else fmask[zbirf,zbibf] = 1.0
    endif else begin
      fmask[zbirf,zbibf] = 0.0
      nbad = nbad + 1
    endelse
    if tmp[zbilf,zbitf] eq 1 then begin
      if zbilf lt zbilc then fmask[zbilf,zbitf] = zbild + zbitd * $
	            (1. - zbild)  else fmask[zbilf,zbitf] = zbitd
    endif else begin
      fmask[zbilf,zbitf] = 0.0
      nbad = nbad + 1
    endelse
    if tmp[zbirf,zbitf] eq 1 then begin
       if zbirf lt zbirc then fmask[zbirf,zbitf] = zbird + zbitd * $
	            (1. - zbird) else fmask[zbirf,zbitf] = 1.0
    endif else begin
      fmask[zbirf,zbitf] = 0.0
      nbad = nbad + 1
    endelse
  endif else begin
    ; square aperture for target
    ztledge = zxcen - ztr
    ztredge = zxcen + ztr
    ztbottom = zycen - ztr
    zttop = zycen + ztr
    ztlf = floor(ztledge)
    ztlc = ceil(ztledge)
    ztrf = floor(ztredge)
    ztrc = ceil(ztredge)
    ztbf = floor(ztbottom)
    ztbc = ceil(ztbottom)
    zttf = floor(zttop)
    zttc = ceil(zttop)
    if ztlf ne ztlc then ztld = float(ztlc)-ztledge else ztld=1.0
    if ztrf ne ztrc then ztrd = ztredge-float(ztrf) else ztrd=0.0
    if ztbf ne ztbc then ztbd = float(ztbc)-ztbottom else ztbd=1.0
    if zttf ne zttc then zttd = zttop - float(zttf) else zttd=0.0
    for j = ztbc, zttf do begin
      for i = ztlc, ztrf do begin
        if tmp[i,j] eq 1 then fmask[i,j] = 1. else nbad = nbad + 1
      endfor
      if tmp[ztlf,j] eq 1 then fmask[ztlf,j] = ztld else nbad = nbad + 1
      if tmp[ztrf,j] eq 1 then fmask[ztrf,j] = ztrd else nbad = nbad + 1
    endfor
    for i = ztlc, ztrf do begin
      if tmp[i,ztbf] eq 1 then fmask[i,ztbf] = ztbd else nbad = nbad + 1
      if tmp[i,zttf] eq 1 then fmask[i,zttf] = zttd else nbad = nbad + 1
    endfor
    ; four corners
    if tmp[ztlf,ztbf] eq 1 then fmask[ztlf,ztbf]=ztld*ztbd else nbad = nbad + 1
    if tmp[ztrf,ztbf] eq 1 then fmask[ztrf,ztbf]=ztrd*ztbd else nbad = nbad + 1
    if tmp[ztlf,zttf] eq 1 then fmask[ztlf,zttf]=ztld*zttd else nbad = nbad + 1
    if tmp[ztrf,zttf] eq 1 then fmask[ztrf,zttf]=ztrd*zttd else nbad = nbad + 1
  endelse
end
