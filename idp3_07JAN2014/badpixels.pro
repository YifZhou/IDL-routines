Function badpixels,data,mask,radius=radius,fwhm=fwhm
; Fix bad pixels (from a mask) using Gaussian weighted interpolation.
;
; Bad pixels are : 
;    - pixels with mask value of zero
; 
; Interpolation scheme :
;    using a Gaussian weight of "radius" sigma
;
; Badpixel mask :
;    0 = bad pixels
;    1 = good pixels
;
; Created by Inseok Song, Feb. 2005
; Modified by Glenn Schneider, Mar. 2005
; 
;===============================================================
; Get X and Y lengths of image data array
; 
;===============================================================
  nx = n_elements(data[*,0])
  ny = n_elements(data[0,*])
;
;===============================================================
; Set size of Gaussian interpolation kernel
; Radius: is in pixels an SHOULD be set to int(0.5 + (2.2*lamda/D) pixels
; For HST/NICMOS Camera 2 F160W optimal interpolation radius is 5 pixels.
; 
;===============================================================
  default_radius = 5.0D0
  default_fwhm   = 2.2D0
  if (n_elements(radius) EQ 0) then radius = default_radius
  if (n_elements(fwhm) EQ 0)   then fwhm   = default_fwhm
;
;===============================================================
; Sanity check on size of interpolation kernal
; The value of 13 is not necessarily generically appropriate.
; In general, a check and warning might be appropriate,
; But enforcing a limit, as here, might not be appropriate
; 
;===============================================================
  max_radius = 13.D0 
  if (radius GT max_radius) then begin
     print,'%% Gaussian kernel size is too large. Reduced to 13.0 pixels!'
     radius=13.D0
  endif
;
;===============================================================
; Calculte Gaussian Kernal for Interpolation Radius 
; 
;===============================================================
  x=dindgen(2*radius+1)
  y=exp(-0.5D*(x-radius)^2 / (fwhm/2.354D0)^2)
  kernel = y # y
;
;===============================================================
; Create padded image array to allow for edge effects.
; Preparing a bigger array with padding on all four sides of array.
; This is necessary to correct bad pixels that are "too close" to edges. 
; For the extreme case of the bad pixel sits on the edge of the image array
; padding must be of size "radius"
; 
;===============================================================
  BIG = dblarr(nx+2*radius, ny+2*radius)
  BIG = BIG * 0.D0  ; reset all array elements to 'zero'
  BIG[radius:radius+nx-1, radius:radius+ny-1] = data 
;
;===============================================================
; Search for bad pixels
; 
;===============================================================
  mask2 = (BIG+1.0)/(BIG+1.0) ;                    Array of 1's size of BIG
  mask2[radius:radius+nx-1, radius:radius+ny-1] *= mask
;
  mask2[0:radius-1,*] = -1    ;                 Pad value = -1 on all sides
  mask2[*,0:radius-1] = -1
  mask2[nx+radius:nx+2*radius-1,*] = -1
  mask2[*,ny+radius:ny+2*radius-1] = -1
;
;===============================================================
; ZERO-VALUE PIXELS ARE CONSIDERED *BAD* AND IN NEED OF REPAIR
; 
;===============================================================
  badpxls = where (mask2 EQ 0, nbads)
;
;===============================================================
; Perform a bad pixel interpolation using the Gaussian weight kernel
; 
;===============================================================
  badpos = array_indices(BIG,badpxls) ;  List by array indices of bad pixels
  for n=0L, nbads-1 do begin          ;  "Fix" one pixel at a time
      ; Get BIG array extract - size of kernel centered on bad pixel
      badpx = badpos[0,n]
      badpy = badpos[1,n]
      sub_section = BIG[badpx-radius:badpx+radius,badpy-radius:badpy+radius]
      sub_mask = mask2[badpx-radius:badpx+radius, badpy-radius:badpy+radius]
      goodpxls = where(sub_mask EQ 1, ngoods)
      badpxls  = where(sub_mask NE 1, nbads)
      sub_mask[badpxls] = 0.D0
      weight = kernel * sub_mask
      weight[radius,radius]=0.D0  ;        Dont use the bad pixel itself!
      weight /= total(weight)
      new_value = total(weight*sub_section)
      BIG[badpx,badpy] = new_value ;       Replace the bad pixel value
  endfor

  return,BIG[radius:nx+radius-1,radius:ny+radius-1]
end 

