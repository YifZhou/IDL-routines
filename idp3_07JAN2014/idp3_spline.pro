function splie2, xxp1, yyp1, image1, sz

  y2a = fltarr(sz[1], sz[2])
  for j = 0, sz[2] - 1 do begin
    ytmp = image1[*,j]
    der = spl_init(xxp1,ytmp)
    y2a[*,j] = der
  endfor
  return, y2a
end

function splin2, xxp1, yyp1, image1, y2a, xxp2, yyp2, sz, xsz, ysz

  yytmp = fltarr(sz[2])
  image2 = fltarr(xsz, ysz)

  for i = 0, xsz-1 do begin
    for j = 0, sz[2] - 1 do begin
      ytmp = image1[*,j]
      y2tmp = y2a[*,j]
      yytmp[j] = spl_interp(xxp1, ytmp, y2tmp, xxp2[i])
    endfor
    der = spl_init(yyp1, yytmp)
    for j = 0, ysz-1 do begin
      image2[i,j] = spl_interp(yyp1, yytmp, der, yyp2[j])
    endfor
  endfor
  return, image2
end

function idp3_spline, array, xsize, ysize

  sz = size(array)
  xxp1 = findgen(sz[1])
  yyp1 = findgen(sz[2])
  xxp2 = float(sz[1]) / xsize * findgen(xsize)
  yyp2 = float(sz[2]) / ysize * findgen(ysize)
  y2a = splie2(xxp1, yyp1, array, sz)
  zarray = splin2(xxp1, yyp1, array, y2a, xxp2, yyp2, sz, xsize, ysize)
  return, zarray
end
