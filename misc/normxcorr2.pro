

FUNCTION xcorr2,TT, AA
  ;; outputsize is the size of the larger array
  T = TT
  A = AA
  ;; making sure that size(A) is bigger than size(T)
  IF n_elements(T) gt n_elements(A) THEN BEGIN
     tmp = T
     T = A
     A = tmp
  ENDIF
  
  T_size = (size(T))[1:2]
  A_size = (size(A))[1:2]
  outsize = A_size + T_size - 1
    ;; pad zeros
  T_pad_rot = dblarr(outsize[0], outsize[1])
  T_pad_rot[0:T_size[0] - 1, 0:T_size[1] - 1] = rot(T, 180)
  A_pad = dblarr(outsize[0], outsize[1])
  A_pad[0:A_size[0] - 1, 0:A_size[1] - 1] = A
  T_fft_conj = fft(T_pad_rot)
  A_fft = fft(A_pad)

  ;; ca=replicate(complex(0.,0.), outsize[0], outsize[1])
  ;; T_fft(0,*)=ca(0,*)
  ;; A_fft(0,*)=ca(0,*)
  ;; T_fft(*,0)=ca(*,0)
  ;; A_fft(*,0)=ca(*,0)

  ;; T_fft(outsize[0] - 1,*)=ca(0,*)
  ;; A_fft(outsize[0] - 1,*)=ca(0,*)
  ;; T_fft(*,outsize[1] - 1)=ca(*,0)
  ;; A_fft(*,outsize[1] - 1)=ca(*,0)
  xcorr = double(fft(T_fft_conj*A_fft, 1))
 ; xcorr=shift(xcorr,(size(xcorr))(1)/2,(size(xcorr))(2)/2)
  
  ;; return size same as image size
  TmpltRadius=floor(T_size/2)   ;
  return, xcorr[TmpltRadius(0):TmpltRadius(0)+A_size(0) - 1,TmpltRadius(1):TmpltRadius(1)+A_size(1)-1]
END

FUNCTION Gaussian2, x, y, p
  ;; 2 double gaussian peak, for mpfit2dfun
  zmod = p[0] + p[1] * exp(-(x - p[4])^2/p[2] - (y - p[5])^2/p[3]) + p[6]*exp(-(x - p[9])^2/p[7] - (y - p[10])^2/p[8])
  return, zmod
END


FUNCTION normxcorr2,image, template, weight = weight
  IF n_elements(weight) EQ 0 THEN weight = MAKE_ARRAY((size(template))[1], (size(template))[2], /double, value = 1.)
  IF n_elements(nSamp) EQ 0 THEN nSamp = 1
  weight = weight/total(weight)
  meanWeight = xcorr2(image, weight)
  meanTemplate = total(weight * template)
  meanTemplate = template - meanTemplate
  weightedTemplate = weight * meanTemplate
  weightedCovxy = xcorr2(image, weightedTemplate) - meanWeight * total(weightedTemplate)
  weightedCovxx = xcorr2(image^2, weight) - meanWeight^2
  weightedCovyy = total(meanTemplate^2 * weight)
  Denom = double(weightedCovxx*weightedCovyy)
  Denom[where(Denom) LE 0 ] = 0
  Denom = sqrt(Denom)
  xcorr = MAKE_ARRAY((size(Denom))[1], (size(Denom))[2], /double, value = 0)

  tol = 1e-8
  i_nonzero = where(Denom gt tol)
  xcorr[i_nonzero] = weightedCovxy[i_nonzero]/Denom[i_nonzero]
  pmax=fltarr(2)
  dxy = fltarr(2)
  m=max(xcorr,pos)
  xpos=pos mod (size(xcorr))(1)
  ypos=pos/(size(xcorr))(1)
  range = 3
  y=shift(xcorr,-(xpos-range),-(ypos-range))
  y=y(0:2*range,0:2*range)
                                ;pmax = polyfit2d(y,degree,/max)
  baseval = median(y)
  params = [baseval, m-baseval, 2.0, 2.0, range, range]
  meshgrid, (size(y))[1], (size(y))[2], xx, yy
  out2 = mpfit2dpeak(y, params, perror=perror, chisq=chisq)
  pmax[0]=params[4]+(xpos-range)
  pmax[1]=params[5]+(ypos-range)
  dxy[0] = pmax[0] - ((size(template))[1]-1)/2 
  dxy[1] = pmax[1] - ((size(template))[2]-1)/2 
  return, dxy
END 


