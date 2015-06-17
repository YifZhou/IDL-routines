pro idp3_cdelt2cd, cdelt1,cdelt2,crota,cd11,cd12,cd21,cd22

  cd11 = cdelt1 * double(cos(!pi/180.0*crota))
  cd12 = abs(cdelt2) * double(sin(!pi/180.0*crota))
  if (cdelt1 lt 0.0) then cd12 = -cd12
  cd21 = -abs(cdelt1) * double(sin(!pi/180.0*crota))
  if (cdelt2 lt 0.0) then cd21 = -cd21
  cd22 = cdelt2 * double(cos(!pi/180.0*crota))

end
