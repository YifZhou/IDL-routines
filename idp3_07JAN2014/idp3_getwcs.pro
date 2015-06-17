function idp3_getwcs, temphead, cv1, cv2, cpix1, cpix2, cd11, cd12, cd21, cd22
@idp3_structs

    cv1 = sxpar(temphead, 'CRVAL1', count=cr1_match)
    if cr1_match lt 1 then cv1 = 0.0d0
    cv2 = sxpar(temphead, 'CRVAL2', count=cr2_match)
    if cr2_match lt 1 then cv2 = 0.0d0
    cd11 = sxpar(temphead, 'CD1_1', count=cd11_match)
    cd12 = sxpar(temphead, 'CD1_2', count=cd12_match)
    cd21 = sxpar(temphead, 'CD2_1', count=cd21_match)
    cd22 = sxpar(temphead, 'CD2_2', count=cd22_match)
    cpix1 = sxpar(temphead, 'CRPIX1', count=crp1_match)
    if crp1_match lt 1 then cpix1 = 0
    cpix2 = sxpar(temphead, 'CRPIX2', count=crp2_match)
    if crp2_match lt 1 then cpix2 = 0
    if cd12_match eq 0 then cd12 = 0.0d0
    if cd21_match eq 0 then cd21 = 0.0d0
    cd_tot = min([cd11_match, cd22_match])
    if cd_tot lt 1 then begin
      cdelt1 = sxpar(temphead, 'CDELT1', count=cdelt1_match)
      cdelt2 = sxpar(temphead, 'CDELT2', count=cdelt2_match)
      crota = sxpar(temphead, 'CROTA2', count=crota_match)
      if cdelt1_match ge 1 and cdelt2_match ge 1 then begin
        if crota_match eq 0 then begin
  	  crota = 0.
  	  crota_match = 1
        endif
      endif
      if min([cdelt1_match, cdelt2_match, crota_match]) ge 1 then begin
	sinrota = double(sin(!dpi/180.0d0*crota))
	cosrota = double(cos(!dpi/180.0d0*crota))
	cd11 = cdelt1 * cosrota
	cd12 = abs(cdelt2) * sinrota
	if (cdelt1 lt 0.0) then cd12 = -(cd12)
	cd21 = -abs(cdelt1) * sinrota
	if (cdelt2 lt 0.0) then cd21 = -(cd21)
	cd22 = cdelt2 * cosrota
	cd_tot = 1
      endif
    endif
    if cd_tot lt 1 then begin
      cd11 = 0.0d0
      cd12 = 0.0d0
      cd21 = 0.0d0
      cd22 = 0.0d0
    endif
    if cr1_match ge 1 and cr2_match ge 1 and cd_tot ge 1 then wcs=1 else wcs=0
    return, wcs
end

