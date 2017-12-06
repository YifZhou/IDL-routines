function getpatch, cube, rho, phi, wr

; AD
; Dec 2014 - Undisclosed Location
;
;
; Modified version of getzone.pro This version extracts a circular
; patch centered on the [rho,pos] information provided (ideally, on a planet)
;
;
; The .indices returns an array of the (linear) indices of the pixels
; that are extracted in the patch. This can be used to copy these back,
; after processing, to the final image.
; =======================

 sc = size(cube)

 mask  = fltarr(sc[1],sc[2])

 px = sc[1]/2. - rho*sin(phi)  ; planet's x position
 py = sc[2]/2. + rho*cos(phi)  ; planet's y position

 print

 dist_circle,  mask, [ sc[1],sc[2]], px, py     ; Create mask with distance from the center of the planet
 
 good = where(mask le wr+rho/10.)

 indices=good
 data = fltarr(n_elements(good), sc[3])

                                ; Go through the images, layer by
                                ; layer, and extract the data points
                                ; required here
; ii=findgen(sc[3]-1)
; data[*,*] = (cube[*,*,*)[good]

 for ii=0, sc[3]-1 do begin
    img= cube[*,*,ii]
    data[*,ii] = img[good]
 endfor

return, {data:data, good:good, num:n_elements(good), indices:indices}
end

