function idp3_photstat, image, mask, thresh

  stats = fltarr(6)
  good = where(mask gt 0.0, cnt)
  medgood = where(mask ge thresh, medcnt)
  if cnt gt 1 then begin
    itotal = total(image[good] * mask[good])
    npix = total(mask)
    imax = max(image[good])
    if medcnt gt 0 then begin
      med  = median(image[medgood], /even)
      mc = moment(image[medgood])
      mmean = mc[0]
      mrms = sqrt(mc[1])
    endif
    stats[0] = itotal
    stats[1] = npix
    stats[2] = imax
    stats[3] = med
    stats[4] = mmean
    stats[5] = mrms
  endif
  return, stats
end
