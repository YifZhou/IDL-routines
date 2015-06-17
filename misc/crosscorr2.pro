FUNCTION crosscorr2, im1, im2, dxy, range = range, degree = degree
  out = convolve(im1, im2, /correl)
  pmax=fltarr(2)
  dxy = fltarr(2)
  m=max(out,pos)
  xpos=pos mod (size(out))(1)
  ypos=pos/(size(out))(1)
  if n_elements(range) eq 0 then range=2
  if n_elements(degree) eq 0 then degree=4
  y=shift(out,-(xpos-range),-(ypos-range))
  y=y(0:2*range,0:2*range)
;  pmax = polyfit2d(y,degree,/max)
  baseval = median(y)
  params = [baseval, m-baseval, 2.0, 2.0, range, range]
  out2 = mpfit2dpeak(y, params, perror=perror, chisq=chisq)
  pmax(0)=params(4)+(xpos-range)
  pmax(1)=params(5)+(ypos-range)
  if pmax(1) gt (size(out))(2)/2 then pmax(1)=pmax(1)-(size(out))(2)
  if pmax(0) gt (size(out))(1)/2 then pmax(0)=pmax(0)-(size(out))(1)
  IF pmax(0) GE 0. THEN dxy[0] =  (size(out))(1)/2. - pmax(0) ELSE dxy[0] =  -(size(out))(1)/2. + abs(pmax(0))
  IF pmax(1) GE 0. THEN dxy[1] =  (size(out))(2)/2. - pmax(1) ELSE dxy[1] =  -(size(out))(2)/2. + abs(pmax(1))
  return, out
END

