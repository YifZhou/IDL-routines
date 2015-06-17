; Using the CD matrix to calculate pixel offsets given RA and DEC offsets.
; ra_off and dec_off in decimal degrees.

pro idp3_pixoffset,cd11,cd12,cd21,cd22,crval1,crval2,cra1,cdec1,deltax,deltay

;      crval1, crval2 from REF image
;      CD matrix from REF image
;      cra1, cdec1 from list image
;      (Full tangent plane projection code)

      d2r = !dpi/180.0d0
      r2d = 180.0d0/!dpi

      bottom = sin(d2r*cdec1)*sin(d2r*crval2) + $
               cos(d2r*cdec1)*cos(d2r*crval2) * cos(d2r*(cra1-crval1))
      xi  = cos(d2r*cdec1) * sin(d2r*(cra1-crval1)) / bottom
      eta = (sin(d2r*cdec1)*cos(d2r*crval2) - $
             cos(d2r*cdec1)*sin(d2r*crval2) * cos(d2r*(cra1-crval1)))/bottom

      determinent = double(cd11*cd22-cd12*cd21)
      xi = xi*r2d
      eta = eta*r2d
      deltax =  (double(cd22) * xi - double(cd12) * eta) / determinent
      deltay = (-double(cd21) * xi + double(cd11) * eta) / determinent
end
