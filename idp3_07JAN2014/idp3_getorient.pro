function idp3_getorient, moveim    

      him = [*moveim.phead, *moveim.ihead]
      orient = sxpar(him, 'ORIENTAT', count=omatch) + moveim.rot
      pa = sxpar(him, 'PA', count=pmatch) + moveim.rot
      reorient = sxpar(him, 'REORIENT', count=rmatch) + moveim.rot
      if moveim.valid_wcs gt 0 then begin
         sxaddpar, him, 'CD1_1', moveim.acd11
         sxaddpar, him, 'CD1_2', moveim.acd12
         sxaddpar, him, 'CD2_1', moveim.acd21
         sxaddpar, him, 'CD2_2', moveim.acd22
	 getrot, him, rot, cdelt
         rot = rot * (-1.0)
	 cmatch = 1
      endif else cmatch = 0
      if omatch + rmatch + pmatch + cmatch ne 0 then begin
        if cmatch eq 1 then begin
           orient = rot 
         endif else begin
           if pmatch eq 1 then orient = pa
           if rmatch eq 1 then orient = reorient
         endelse
      if moveim.flipy eq 1 then orient = 360. - (180. + orient)
      him = 0
    endif else orient = -999
return, orient
end
