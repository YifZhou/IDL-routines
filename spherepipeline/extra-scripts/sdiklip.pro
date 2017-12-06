function SDIKLIP, cube,  k_klip, target=target, checkpoint = checkpoint, anglemask=anglemask, $
distmask=distmask, posang=posang,scaling=scaling, diam=diam,pixelscale=pixelscale, wl=wl,angsep=angsep,hyper=hyper,annmode_inout=annmode_inout,$
obj=obj,nrings=nrings,wr =wr,n_ang =n_ang,spot_radius=spot_radius,rho=rho,phi=phi

;Function to create PSF subtracted image using KLIP algorithm
;The target image is currently the first image in the PSF cube
;STRUCTURE - Output from search_zones.pro
;IM_SIZE - Dimension of square subarray
;K_KLIP - Number of KL Basis Vectors to retain

; diam - telescope diameter in m 
; wl - wavelength of the observations
; pixelscale - in 1/arcsec


; hyper - if set, KLIP will only process four round patches centered
;         on the planets, but not the rest of the images
; =======================

 
if keyword_set(hyper) then begin
         print, '--[ NUKLIP    ]-- STARTING HYPERKLIP'

nimages = (size(cube))(3)

	nspots=n_elements(rho)
	;phi=fltarr(nspots)
	;rho=fltarr(nspots*4.)
	;rho[*]=0.79/pixelscale
	;for ii=0.,nspots-1. do phi[ii]=( 196.7+(360.* ii / nspots) )*!DTOR
	;phi=[phi,phi,phi,phi]	;magao
	
	;for ii=0.,nspots-1. do phi[ii]=( 193.+(360.* ii / nspots) )*!DTOR
	
	;rho=rho/pixelscale ;rho is input in arcsec
	;phi=phi*!DTOR
	
	wr=spot_radius
	

;phi = [117]*!DTOR  ; Position angle of the planets in radian  ;80 (95) for 72940_2

final_arr = reform(cube[*,*,0]) ; final array same size as sub array
final_arr[*] = !values.f_nan


;Build final image segment by segment:
for ii=0, nspots-1 do begin
 print, '--[ NUKLIP  ]-- Processing Spot #',ii
      ; What pos angle difference translates to 1.5 FWHM in this annulus/ring?

   arcdist = (asin( 1.0 *(1.22 * wl(10.^(-6.)) /diam/!DTOR *3600./pixelscale ) / (rho[ii])) )/!DTOR ; Gives the minimum posang difference
                                ; required to have a 1.5 FWHM arc
                                ; difference in H-band with a
                                ; diffraction limited 8m telescope at
                                ; the mid-point of the iith ring with
                                ; width wr
                                
 
                                ; AD March 3, 2015
                                
                                
;first, we get the data from our target segment (the one we will
;project onto KL basis

  ; Calculate the planets' position angle consider field rotation

 zones = getpatch(cube, rho[ii], phi[ii]- 1.*mean(posang)*!DTOR,wr)  ; Get patch corresponding to the planet ii

;        zones = getzone(cube, annulus, angles)  ; Returns a nz x npix 2D array with the pixels in the given zone across the cube

      target_seg = reform(zones.data[*,target]) 

      frames = findgen(nimages)

      ;nottarget  =  where( abs(posang(frames)-posang(target))  ge ANGSEP*abs(arcdist) ) ; AD
  FWHM=1.22 *wl*(10.^(-6.))/diam / !DTOR *3600./ pixelscale
 	 ; = rho[ii]*wavedist
      ;nottarget  =  where( abs(posang(frames)-posang(target))  ge ANGSEP*abs(arcdist) ) ; AD
      
      n_cols = (size(cube))(1)

  	  nottarget  =  where( abs(scaling(frames)-scaling(target)) ge ANGSEP*FWHM/(n_cols/2.) ); KW - SDI

  
      if N_elements(nottarget) lt 4 then begin
           nottarget =  where(findgen(nimages) ne target)
          print, ' -[ NUKLIP ]- Less than 4 frames avialable for PCA - Removing wavelength distance constraint'
        endif
     
      data_seg = transpose(zones.data[*,nottarget]  )
 
      dense_target = transpose(target_seg - mean(target_seg))
;      dense_target = target_seg[where(finite(target_seg) eq 1,/null)] ; Remove NaN   

;      dense_target = dense_target - total(dense_target)/n_elements(dense_target)  ; subtract mean
;      dense_target = transpose(dense_target)  ; 1XN

;      size_target = n_elements(dense_target)
;      size_mask = n_elements(zones.indices)

;      dense_data = reduce_matrix(data_seg)     ; Condense Matrix (rid NaN)

      dense_data = data_seg
      size_data = (size(dense_data))(2)


      kl_basis = get_klip_basis(dense_data, k_klip) ; CREATE BASIS!

;last, we will project our target image onto our KL basis

      synthetic_1d = dense_target # matrix_multiply(kl_basis,kl_basis,/atranspose)  ; create psf reconstruction
      
      synthetic_1d = dense_target - synthetic_1d ; subtract psf reconstruction     
                 
      final_arr[zones.indices] = synthetic_1d ; Build Final Image  -- AD: Replaced loop with single command


   
endfor

   


endif 


if keyword_set(annmode_inout) then begin


print, '--[ NUKLIP    ]-- STARTING ANNULAR KLIP'

;seperate structure elements
;ringseg = structure.ringseg
;mask_index = structure.mask_index
;structure = 0.0  ; free memory


;store number of images, rings, and angular segments in ringseg
;nimages = (size(ringseg))(1)
;nrings = (size(ringseg))(2)
;n_ang = (size(ringseg))(3)
;data = (size(ringseg))(4)

nimages = (size(cube))(3)

;Set dimensions of single frame
n_cols = (size(cube))(1)
n_rows = n_cols

final_arr = fltarr(n_cols,n_rows)  ; final array same size as sub array

final_arr[*] = !values.f_nan

;full_lib = fltarr(nimages-1,nrings,n_ang,data)  ; Define array for psf lib

;for aa = 0, nimages-2 do begin
;   full_lib[aa,*,*,*] = ringseg[aa+1,*,*,*]  ; Remove target image from psf lib
;endfor

;  full_lib[0:nimages-2,*,*,*] = ringseg[1:nimages-1,*,*,*]  ; Replaced the above loop with this single line

;store number of images in psf lib
;nimages = (size(full_lib))(1)

progress_counter = 0.0          ; initialize progress counter
total_elements = nrings*n_ang   ; also used for progress update

;Build final image segment by segment:
;for ii=0, nrings-1 do begin

      ; What pos angle difference translates to 1.5 FWHM in this annulus/ring?

 ;  arcdist = (asin( 1.0 *(1.22 * wl /diam/!DTOR *3600./pixelscale ) / ((ii+0.5)*wr )) )/!DTOR ; Gives the minimum posang difference
                                ; required to have a 1.5 FWHM arc
                                ; difference in H-band with a
                                ; diffraction limited 8m telescope at
                                ; the mid-point of the iith ring with
                                ; width wr
                                
 
                                ; AD March 3, 2015
;  print, 'Ring #',ii,' with min angular distance of :',arcdist
   for jj=0, n_ang-1 do begin

	;scaling=scaling/scaling[target]
;first, we get the data from our target segment (the one we will
;project onto KL basis

       ;annulus = [ ii*wr,(ii+1)*wr ]
              annulus = [ annmode_inout[0],annmode_inout[1] ]

       angles   = [ jj*(360./n_ang) , (jj+1)*(360./n_ang) ]
       if max(angles) gt 360 then stop

              ;  print, annulus
              ;  print, angles

        zones = getzone(cube, annulus, angles)  ; Returns a nz x npix 2D array with the pixels in the given zone across the cube

      target_seg = reform(zones.data[*,target]) 

;      nottarget =  where(findgen(nimages) ne target) ; AD
                                ; Changing this to exclude frames with
                                ; relative pos angles < 1.5 FWHM at
                                ; the given distance
      frames = findgen(nimages)
      
      
       FWHM=1.22 *wl*(10.^(-6.))/diam / !DTOR *3600./ pixelscale
 	 ; = rho[ii]*wavedist
 	 
      ;nottarget  =  where( abs(posang(frames)-posang(target))  ge ANGSEP*abs(arcdist) ) ; AD
  	   nottarget  =  where( abs(scaling(frames)-scaling(target)) ge ANGSEP*FWHM/(annmode_inout[0]+abs(annmode_inout[1]-annmode_inout[0])/2.) ); KW - SDI 2017
  	   
  	   if jj eq 0 then print, 'Required scaling = ',ANGSEP*FWHM/(annmode_inout[0]+abs(annmode_inout[1]-annmode_inout[0])/2.)

  if jj eq 0  then print, 'Frames meeting separation criteria:',(size(nottarget))(1)

     ; nottarget  =  where( abs(posang(frames)-posang(target))  ge ANGSEP*abs(arcdist) ) ; AD
  
      if N_elements(nottarget) lt 4 then begin
           nottarget =  where(findgen(nimages) ne target)
          print, ' -[ NUKLIP ]- Less than 4 frames avialable for PCA - Removing angular distance constraint'
        endif

      data_seg = transpose(zones.data[*,nottarget]  )
 
      dense_target = target_seg[where(finite(target_seg) eq 1,/null)] ; Remove NaN   

      if dense_target eq !NULL then begin
         
         print, 'ERROR: EMPTY SEARCH ZONE'
         print,'MAKE SURE ALL SEARCH ZONES CONTAIN >1 PIXELS'

      endif

      dense_target = dense_target - total(dense_target)/n_elements(dense_target)  ; subtract mean
      dense_target = transpose(dense_target)  ; 1XN
;      index = where(finite(mask_index[ii,jj,*]) eq 1,/null)  ; get segment index

      size_target = n_elements(dense_target)
      size_mask = n_elements(zones.indices)
      if size_target ne size_mask then print, 'MASK NOT SAME SIZE AS DATA'


;next, we will create our KL basis

     
      ;store the segments of interest
      ;data_seg = full_lib[*,ii,jj,*]   ; create psf lib for segment

      dense_data = reduce_matrix(data_seg)     ; Condense Matrix (rid NaN)

      size_data = (size(dense_data))(2)
      
      ;If the segment contains only a single pixel then dense_data is 1d matrix
      if size_target eq 1 then begin

         print, '(WARNING!) Some Search Zones Contain Only 1 Pixel...'
         
         size_data = 1

      endif

      if size_target ne size_data then print, 'TARGET SEG NOT SAME SIZE AS DATA SEG'

      kl_basis = get_klip_basis(dense_data, k_klip) ; CREATE BASIS!

;last, we will project our target image onto our KL basis


      synthetic_1d = dense_target # matrix_multiply(kl_basis,kl_basis,/atranspose)  ; create psf reconstruction
      
      synthetic_1d = dense_target - synthetic_1d ; subtract psf reconstruction     
      
      final_arr[zones.indices] = synthetic_1d ; Build Final Image  -- AD: Replaced loop with single command

      progress_counter = progress_counter + 1 ; update progress

   endfor
   
;endfor


endif

if not keyword_set(hyper) and not keyword_set(annmode_inout) then begin

print, '--[ NUKLIP    ]-- STARTING REGULAR KLIP'

;seperate structure elements
;ringseg = structure.ringseg
;mask_index = structure.mask_index
;structure = 0.0  ; free memory


;store number of images, rings, and angular segments in ringseg
;nimages = (size(ringseg))(1)
;nrings = (size(ringseg))(2)
;n_ang = (size(ringseg))(3)
;data = (size(ringseg))(4)

nimages = (size(cube))(3)

;Set dimensions of single frame
n_cols = (size(cube))(1)
n_rows = n_cols

final_arr = fltarr(n_cols,n_rows)  ; final array same size as sub array

final_arr[*] = !values.f_nan

;full_lib = fltarr(nimages-1,nrings,n_ang,data)  ; Define array for psf lib

;for aa = 0, nimages-2 do begin
;   full_lib[aa,*,*,*] = ringseg[aa+1,*,*,*]  ; Remove target image from psf lib
;endfor

;  full_lib[0:nimages-2,*,*,*] = ringseg[1:nimages-1,*,*,*]  ; Replaced the above loop with this single line

;store number of images in psf lib
;nimages = (size(full_lib))(1)

progress_counter = 0.0          ; initialize progress counter
total_elements = nrings*n_ang   ; also used for progress update

;Build final image segment by segment:
for ii=0, nrings-1 do begin

      ; What pos angle difference translates to 1.5 FWHM in this annulus/ring?

   arcdist = (asin( 1.0 *(1.22 * wl /diam/!DTOR *3600./pixelscale ) / ((ii+0.5)*wr )) )/!DTOR ; Gives the minimum posang difference
                                ; required to have a 1.5 FWHM arc
                                ; difference in H-band with a
                                ; diffraction limited 8m telescope at
                                ; the mid-point of the iith ring with
                                ; width wr
                                
 
                                ; AD March 3, 2015
;  print, 'Ring #',ii,' with min angular distance of :',arcdist
   for jj=0, n_ang-1 do begin


;first, we get the data from our target segment (the one we will
;project onto KL basis

       annulus = [ ii*wr,(ii+1)*wr ]
       angles   = [ jj*(360./n_ang) , (jj+1)*(360./n_ang) ]
       if max(angles) gt 360 then stop

              ;  print, annulus
              ;  print, angles

        zones = getzone(cube, annulus, angles)  ; Returns a nz x npix 2D array with the pixels in the given zone across the cube

      target_seg = reform(zones.data[*,target]) 

;      nottarget =  where(findgen(nimages) ne target) ; AD
                                ; Changing this to exclude frames with
                                ; relative pos angles < 1.5 FWHM at
                                ; the given distance
      frames = findgen(nimages)
      
      
       FWHM=1.22 *wl*(10.^(-6.))/diam / !DTOR *3600./ pixelscale
 	 ; = rho[ii]*wavedist
      ;nottarget  =  where( abs(posang(frames)-posang(target))  ge ANGSEP*abs(arcdist) ) ; AD
  	  nottarget  =  where( abs(scaling(frames)-scaling(target)) ge ANGSEP*FWHM/(N_Cols/2.) ); KW - SDI
  if jj eq 0 and ii eq 0 then print, 'Frames meeting separation criteria:',(size(nottarget))(1)

     ; nottarget  =  where( abs(posang(frames)-posang(target))  ge ANGSEP*abs(arcdist) ) ; AD
  
      if N_elements(nottarget) lt 4 then begin
           nottarget =  where(findgen(nimages) ne target)
          print, ' -[ NUKLIP ]- Less than 4 frames avialable for PCA - Removing angular distance constraint'
        endif

      data_seg = transpose(zones.data[*,nottarget]  )
 
      dense_target = target_seg[where(finite(target_seg) eq 1,/null)] ; Remove NaN   

      if dense_target eq !NULL then begin
         
         print, 'ERROR: EMPTY SEARCH ZONE'
         print,'MAKE SURE ALL SEARCH ZONES CONTAIN >1 PIXELS'

      endif

      dense_target = dense_target - total(dense_target)/n_elements(dense_target)  ; subtract mean
      dense_target = transpose(dense_target)  ; 1XN
;      index = where(finite(mask_index[ii,jj,*]) eq 1,/null)  ; get segment index

      size_target = n_elements(dense_target)
      size_mask = n_elements(zones.indices)
      if size_target ne size_mask then print, 'MASK NOT SAME SIZE AS DATA'


;next, we will create our KL basis

     
      ;store the segments of interest
      ;data_seg = full_lib[*,ii,jj,*]   ; create psf lib for segment

      dense_data = reduce_matrix(data_seg)     ; Condense Matrix (rid NaN)

      size_data = (size(dense_data))(2)
      
      ;If the segment contains only a single pixel then dense_data is 1d matrix
      if size_target eq 1 then begin

         print, '(WARNING!) Some Search Zones Contain Only 1 Pixel...'
         
         size_data = 1

      endif

      if size_target ne size_data then print, 'TARGET SEG NOT SAME SIZE AS DATA SEG'

      kl_basis = get_klip_basis(dense_data, k_klip) ; CREATE BASIS!

;last, we will project our target image onto our KL basis


      synthetic_1d = dense_target # matrix_multiply(kl_basis,kl_basis,/atranspose)  ; create psf reconstruction
      
      synthetic_1d = dense_target - synthetic_1d ; subtract psf reconstruction     
      
      final_arr[zones.indices] = synthetic_1d ; Build Final Image  -- AD: Replaced loop with single command

      progress_counter = progress_counter + 1 ; update progress

   endfor
   
endfor

endif
;===================

print, '--[ NUKLIP    ]-- COMPLETE'

return, final_arr
END
