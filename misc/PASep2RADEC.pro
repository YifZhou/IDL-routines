PRO PASep2RADEC, ra1, dec1, p, s, ra2, dec2
  ;;; using position angle and separation to calulate the ra and dec
  ;;; of companion
  ;;; ra/dec in decimal degrees,
  ;;; pa in decimal degrees
  ;;; sep in arcsec
  rad = !const.pi/180.
  pa = p MOD 360  
  sep = s/3600. * rad  ;; separation from arcsec to rad
  dDEC = (cos(pa*rad) * sep) 
  dRA = abs(sqrt(sep^2 - dDEC^2)/cos(dec1*rad))
  IF NOT ((pa GE 0) AND (pa LE 180)) THEN dRA = -dRA
  ra2 = ra1 + dRA/rad
  dec2 = dec1 + dDEC/rad
END
