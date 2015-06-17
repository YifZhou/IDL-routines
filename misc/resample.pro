FUNCTION resample, im, dim1, dim2
  imsize = (size(im))[1:2]
  im_rebinned = fltarr(dim1, dim2)
  n1 = imsize[0]/dim1
  n2 = imsize[1]/dim2
  FOR i=0, dim1-1 DO BEGIN
     FOR j=0, dim2-1 DO BEGIN
        im_rebinned[i, j] = total(im[i*n1:(i+1)*n1 -1, j*n2:(j+1)*n2 -1])
     ENDFOR
  ENDFOR
  return, im_rebinned
END
