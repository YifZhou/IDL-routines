pro reduce_ifs,obj,inj=inj,yj=yj, suffix=suffix,reduction_path=reduction_path

;Version: 2017/11/29

;This routine performs PSF subtraction on SPHERE/IFS data products that are 
;pre-processed using Arthur Vigan's pipeline available at http://astro.vigan.fr/

;Author: Kevin Wagner - University of Arizona - kwagner@as.arizona.edu
;Calling sequence: IDL> klipifs
;
;Inputs/Outputs: None/None - all work is done on files in the observation directory. 
;
;Modify the lines at the top of this routine to fit your reduction needs. 
;

;Establish paths:
;obj='HD131399-K12'
if keyword_set(reduction_path) then root=reduction_path+obj+'/IFS/' else root='/media/kevin/Storage/Data/VLT/SPHERE/'+obj+'/IFS'
klipfolder = '/processed/'	;will store processed files in root+klipfolder

if not keyword_set(yj) then yj=0 	;set to 1 for YJ mode on IFS, or to 0 for YJH mode

if not keyword_set(suffix) then suffix=''


comb_type ='nw-mean'	;'mean', 'median', 'nw-mean' (Bottom et al. 2017)

;What type of KLIP reduction?
adi=1		;run adi?
sdi=1		;run sdi? (will find old data cube if adi has already run)
rdi=0		;will prompt for a data_cube_coro.psf to be dragged into terminal (you will need to put in '' manually)


rdi_adi=0
rdi_sdi=0	;run sdi on an rdi cube

fresh_sdi=0 		;this uses the raw data_cube_coro in the SDI. Bypasses ADI.

classical_adi = 1 ;will output classical ADI results before running KLIP (useful for quick looks and some disks). 

hyp=0
	pxscale=0.00746 ;arcsec/pixel
	rho=[0.5]/pxscale;	spot location input in a radius in arcsec, then converted to pixels
	phi=[90.] & phi=(phi)*!DTOR;
	spot_radius=7.;	spot-width

annmode=0 & if hyp  then annmode=0
	annmode_inout=[90,130]	;will process only an annulus with these settings (and n_ang segments)
	
	
debug=0			;1 for on; 0 for off. Outputs extra files for development purposes.
				;Leaving this on can eat up a LOT of hard drive space.

destripe_ifs=1	;only really useful if doing a fresh_sdi reduction in which the field rotation is also minimal. 
	destripe_iter=3	;will process up to destripe_angle_<destripe_iter>
	destripe_angle=100.
	destripe_angle_2=101.
	destripe_angle_3=100.5
	destripe_angle_4=10.
	destripe_angle_5=99.5
	destripe_angle_6=9.5
	range_sz=140.		;range from center to destripe
	destripe_level=0.0	



;Include forward modelling of fake planets?
;addplanets=1
if keyword_set(inj) then addplanets=1 else addplanets=0
if addplanets then suffix=strcompress('_inj'+suffix,/rem)

theta=148.; -  0.1* runs 
rhop=0.2; + 0.001*runs	;right 0.825, left: 0.830	

planet_r=[rhop,rhop,rhop,rhop,rhop,rhop,rhop,rhop]
planet_theta=[theta,theta+180.,theta+90.,theta-90.,theta+45.,theta+180.+45.,theta+90.+45.,theta-90.+45.]

rplanet=[planet_r,planet_r+0.1,planet_r+0.2,planet_r+0.3,planet_r+0.4,planet_r+0.5,planet_r+0.6]
offang=65.
tplanet=[planet_theta,planet_theta-offang,planet_theta-2.*offang,planet_theta-3.*offang,planet_theta-4.*offang,planet_theta-5.*offang,planet_theta-6.*offang]

rplanet=rplanet/0.00746
tplanet=tplanet*!DTOR

nplanets=n_elements(rplanet)
contrast=fltarr(nplanets)
contrast[*]=5.0E-6
;General reduction parameters:
szz=140.			;half size of processed frame - do not change!!
k_adiklip=7;17.		;number of KL basis vectors to retain (7)
k_sdiklip=7;15.		;number of KL basis vectors to retain (7)
k_rdiklip=7;15.		;number of KL basis vectors to retain (7)

wr = 14. 		;Width of annuli in pixels (14) (12 recently)
wr_sdi = 14. 		;Width of annuli in pixels (14) (12 recently)
wr_rdi = 14. 		;Width of annuli in pixels (14) (12 recently)
nrings = fix(szz/wr) 	;Number of annuli (15)
nrings_rdi = fix(szz/wr_rdi) 	;Number of annuli (15)
nrings_sdi = fix(szz/wr_sdi) 	;Number of annuli (15)
n_ang = 6.		;Number of segments (6)
ANGSEP=0.5	;Exclude frames from ADI KLIP that are within ANGSEP x FWHM of the target frame
anglemax=360.
SDISEP=1.5		;Exclude frames from SDI KLIP that are within SDISEP x FWHM of the target frame
filter=15. 		;high pass filter width (set to 0 or 1 to disable) 
filter_low=0	;low pass filter width (set to 0 or 1 to disable)

bin=0		;if set to yes will temporally bin in the SDI step
binsize=2		;Currently only works for 2,3,4,5	
				;should be improved in the future to work for arbitrary numbers, and for the ADI step as well.
				

radmask=0		;masks the region exterior to maskrad and interior to innerrad
maskrad=0.88/0.00746	;pixels away from center
innerrad=0.08/0.00746

savesplit=0 	;Turn to 1 to also save first and second half of data separately.
				;Useful for determining artifacts / speckles.

;Reject bad frames: (NOTE: IDL notation is 0 = first frame) 
bads=[];[32]-1



;--------------------[ END User input, begin reduction script:      ]-----------------------------;


path=root+'/products/'

scicube=readfits(path+'data_cube_coro.fits', scihd)

if rdi_adi  then scicube=readfits(root+klipfolder+obj+'_ifs_rdiklip_xyln.fits', scihd)

if rdi_adi  then scicube[where(finite(scicube) eq 0)]=0

info=readfits(path+'data_info.fits', infohd)


if rdi  then begin
	refcube='empty'
	read, refcube, PROMPT='Enter reference cube path (data_cube_coro.fits): '
	refcube=readfits(strcompress(string(refcube),/remove_all),refhead)
endif

print,'Size of data cube:',size(scicube)
psfcube=readfits(path+'data_cube_psf.fits', psfhd)
xpsf=(size(psfcube))(1)
psfcubezero=psfcube

;mmm, scicube[xpsf/2.-100:xpsf/2.+100.-1.,xpsf/2.-100:xpsf/2.+100.-1.,0,0], sky
;Print, 'Sky:',sky

for x=0,xpsf-1 do begin
	for y=0,xpsf-1 do begin
		if (x-xpsf/2.)^2. + (y-xpsf/2.)^2. gt 10 then psfcubezero[x,y,*]=0
		;this step makes it so that noise in the PSF isn't added to the science region

		if radmask  then begin
		if Sqrt(  (x-(xpsf/2.) )^2. + (y-(xpsf/2.) )^2.  ) gt maskrad $
						then scicube[x,y,*,*]=sky
		;if Sqrt(  (x-(xpsf/2.) )^2. + (y-(xpsf/2.) )^2.  ) le innerrad $
		;				then scicube[x,y,*,*]=!values.f_nan;sky
		endif
	endfor
endfor
centers=readfits(path+'data_centers.fits', centershd)
scaling=readfits(path+'data_scaling.fits', scalinghd)

print, 'Scaling factors:', scaling

wavelength=readfits(path+'data_wavelength.fits', wavelengthhd)
wave=wavelength
print,wave
;extracting center of frames in each wavelength slice
xc=centers[*,1]
yc=centers[*,0]

xc[*]=139.5
yc[*]=139.5	;these are for Arthur Vigan's output, which is already centered. I'm not 
			;sure why his routine also outputs the "centers" which are simply 
			;misleading once the final cube has already been centered.

Print, 'X Centers:', xc
Print, 'Y Centers:', yc



;making a mask identical in size to a single frame and reading sizes
mask=fltarr(2*szz,2*szz)	;making a mask the same size as the science frame
sizes=size(mask)
width=sizes[1]
hwidth=float(width)/2.-1.
specn=sizes[3]
mask=fltarr(width,width) ;make the mask 2-dimensional
mask[*]=0.

;Setting up things for KLIP:

;BOXCAR IS BROKEN DO NOT USE!!!!!!!!
			;11 to 15 seems to be a good range, 9 starts to significantly self-subtract 
boxcar=0	;set boxcar to 1 to use FFT based filtering (will override smooth-
				;based filtering
boxsz=15		;set boxcar size

anglemask = jhrangmask(mask)
;Get the dimensions of a single frame
x = float((size(anglemask))(1))
y = float((size(anglemask))(2))
x = min([x,y])
distmask = mask  ; use the first image in cube to create mask
N = x  ; Define the size of N x N output array
dist_circle, distmask, N, [x/2., y/2.]  ; create distance mask
				;KLIP parameters (default values):


;===================This section de-rotates the klip images and stacks into Y, J, H, and YJH images. 

;reading angles
info = mrdfits(path+'data_info.fits',1)   ;; read data
;plot,info[*].time,info[*].pa         ;; plot pa values
pa = info[*].pa  
pupoff = info[*].pupoff  

print, pupoff 
;hak

;pupoff is 33.64 after AV routines, should be 33.76 to be consistent with Maire et al. 2016
;template_frame_ifs
;IRDIS offset: -135.99+/-0.1
;IRDIS -> IFS offset: 100.45+/-0.1
;TN=-1.75+/-0.08
;thus we add 0.12 to the offset
pupoff=pupoff+0.12

print, 'Angles:',pa
angles=pa

goods=fltarr((size(pa))(1))
goods[*]=1
goods[bads]=0

print,'offset:',pupoff

anles=angles[where(goods )]
pa=angles
pupoff=pupoff[where(goods )]
scicube=scicube[*,*,*,where(goods )]

cubesize=size(scicube)
cnt=cubesize[4]
print, cnt
fullcube=fltarr(2*szz,2*szz,39,cnt)
fullcubeps=fullcube	;pupil-stabilized cube to be used for SDI
fullcubeps[*]=0.


bigarr=fltarr(4.*szz,4.*szz,39,cnt)
bigpsfarr=fltarr(4.*szz,4.*szz,39)

print, size(bigpsfarr[szz:3.*szz-1,szz:3.*szz-1,*])
print, size(psfcubezero)

;use the first PSF, if there is more than one PSF cube in the file (i.e. a 4D cube)
if n_elements(psfcubezero) gt 6 then psfcubezero=reform(psfcubezero[*,*,*,0])
bigpsfarr[szz:3.*szz-1,szz:3.*szz-1,*]=reform(psfcubezero)

for k=0,38 do begin
	for ii=0, cnt-1 do begin	
		
		
	if addplanets  then begin



			;print, size(bigarr[szz:3.*szz-1,szz:3.*szz-1,k,ii])
			;print, size(scicube[*,*,k,ii])

			bigarr[szz:3.*szz-1,szz:3.*szz-1,k,ii]=scicube[*,*,k,ii]



 			
 			bigarr[*,*,k,ii]=rot(bigarr[*,*,k,ii],-pa[ii]-pupoff[ii],/INTERP)
 				
 				
 					xcc=140.
 					ycc=140.
 					if k eq 0 and ii eq 0 then print, $
 						'-------- Adding synthetic planets -------------'
 			
 				for jj=0,nplanets-1 do begin 

				print, 'Injecting planet # ', jj,k,ii, ' out of ', nplanets-1, 38, cnt-1				
 			 				
 				bigarr[*,*,k,ii]= bigarr[*,*,k,ii] + $
 					fshift(bigpsfarr[*,*,k], -rplanet[jj]*cos(tplanet[jj]),-rplanet[jj]*sin(tplanet[jj]))*contrast[jj]

				 print,'Injection coordinates: ',135.-rplanet[jj]*cos(tplanet[jj]),135.-rplanet[jj]*sin(tplanet[jj])
 				
 				endfor
				if ii eq 0 then print, 'Please wait...'
 			 	bigarr[*,*,k,ii]= rot(bigarr[*,*,k,ii],pa[ii]+pupoff[ii],/INTERP)
 			 	scicube[*,*,k,ii]=bigarr[szz:3.*szz-1,szz:3.*szz-1,k,ii]
				
 	endif ;addplanets if
		
		;spatial filtering:
		if filter_low gt 1 then scicube[*,*,k,ii]=smooth(scicube[*,*,k,ii],filter_low)
		if filter gt 1 then scicube[*,*,k,ii]=scicube[*,*,k,ii]-smooth(scicube[*,*,k,ii],filter)
		
	if destripe_ifs  then begin
	
		if k eq 0 and ii eq 0 then print, 'Destriping (may take some time...)'
		if k eq 0 and ii eq 0 then print, 'Cube sizes:', size(scicube)
		
		destripe_range=[xpsf/2.-range_sz:xpsf/2.+range_sz-1.]
		
 			if destripe_iter le 1 then $
 			scicube[destripe_range,destripe_range,k,ii]=destripe(scicube[destripe_range,destripe_range,k,ii],$
 			 destripe_angle, clip_level=destripe_level, /nodisp)
 			 
 			if destripe_iter le 2 then $
 			scicube[destripe_range,destripe_range,k,ii]=destripe(scicube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_2, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 3 then $
 			scicube[destripe_range,destripe_range,k,ii]=destripe(scicube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_3, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 4 then $
 			scicube[destripe_range,destripe_range,k,ii]=destripe(scicube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_4, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 5 then $
 			scicube[destripe_range,destripe_range,k,ii]=destripe(scicube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_5, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 6 then $
 			scicube[destripe_range,destripe_range,k,ii]=destripe(scicube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_6, clip_level=destripe_level, /nodisp)
 	endif
 					
 					
 	;repeating for reference cube
 if rdi  then begin
 	;spatial filtering:
		if filter_low gt 1 then begin
			if ii le (size(refcube))(4)-1 then refcube[*,*,k,ii]=smooth(refcube[*,*,k,ii],filter_low)
		endif
		
		if filter gt 1 then begin
			if ii le (size(refcube))(4)-1 then refcube[*,*,k,ii]=refcube[*,*,k,ii]-smooth(refcube[*,*,k,ii],filter)
		endif
		
		
if destripe_ifs  then begin
	if k eq 0 and ii eq 0 then print, 'Destriping reference cube (may take some time...)'
	if k eq 0 and ii eq 0 then print, 'Cube sizes:', size(refcube)

destripe_range=[xpsf/2.-range_sz:xpsf/2.+range_sz-1.]

	if ii lt ((size(refcube))(4)) then begin
 			if destripe_iter le 1 then	refcube[destripe_range,destripe_range,k,ii]= $
 			destripe(refcube[destripe_range,destripe_range,k,ii], destripe_angle, clip_level=destripe_level, /nodisp)
 			if destripe_iter le 2 then $
 			refcube[destripe_range,destripe_range,k,ii]=destripe(refcube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_2, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 3 then $
 			refcube[destripe_range,destripe_range,k,ii]=destripe(refcube[destripe_range,destripe_range,k,ii], $
 			destripe_angle_3, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 4 then refcube[destripe_range,destripe_range,k,ii]= $
 			destripe(refcube[destripe_range,destripe_range,k,ii], destripe_angle_4, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 5 then refcube[destripe_range,destripe_range,k,ii]= $
 			destripe(refcube[destripe_range,destripe_range,k,ii], destripe_angle_5, clip_level=destripe_level, /nodisp)
 			
 			if destripe_iter le 6 then refcube[destripe_range,destripe_range,k,ii]= $
 			destripe(refcube[destripe_range,destripe_range,k,ii], destripe_angle_6, clip_level=destripe_level, /nodisp)
 	endif
 endif
 	
endif ;rdi if

	endfor
		

endfor
		;derotates the frames and median combines for each band
		derotrawcube=scicube
		adicuberaw=scicube
		for k=0,38 do begin
			;make a median in wavelength k
			medarr,reform(adicuberaw[*,*,k,*]),pupilk
			for ii=0, cnt-1 do adicuberaw[*,*,k,ii]=adicuberaw[*,*,k,ii]-pupilk
			for ii=0, cnt-1 do adicuberaw[*,*,k,ii]=rot(adicuberaw[*,*,k,ii],-pa[ii]-pupoff[ii],/interp)
			for ii=0, cnt-1 do derotrawcube[*,*,k,ii]=rot(derotrawcube[*,*,k,ii],-pa[ii]-pupoff[ii],/interp)
			derotrawcubek=reform(derotrawcube[*,*,k,*])
			adicubek=reform(adicuberaw[*,*,k,*])

			if comb_type eq 'median' then medarr, derotrawcubek, kframemedraw
			if comb_type eq 'mean' then kframemedraw=mean(derotrawcubek,dim=3)
			if comb_type eq 'nw-mean' then kframemedraw=nw_ang_comb(derotrawcubek,pa+pupoff)
			if comb_type eq 'median' then medarr, adicubek, kadiframe
			if comb_type eq 'mean' then kadiframe=mean(adicubek,dim=3)
			if comb_type eq 'nw-mean' then kadiframe=nw_ang_comb(adicubek, pa+pupoff)			
			if k eq 0 then adisum=kadiframe else adisum=adisum+kadiframe
			if k eq 0 then adicube=kadiframe else adicube=[[[adicube]],[[kadiframe]]]
			

			if k eq 0 then sumraw=kframemedraw else sumraw=sumraw+kframemedraw
			if k eq 0 then sumrawcube=kframemedraw else sumrawcube=[[[sumrawcube]],[[kframemedraw]]]
		endfor
		sumraw=sumraw/39.
		
		writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_raw_xyl'+suffix+'.fits'), sumrawcube, scihd
		if yj then writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_raw_YJ'+suffix+'.fits'), sumraw, scihd else writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_raw_YJH'+suffix+'.fits'), sumraw, scihd 
		
		if classical_adi  then begin
		
		writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adi_xyl'+suffix+'.fits'), adicube, scihd
		if yj then writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adi_YJ'+suffix+'.fits'), adisum, scihd else writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adi_YJH'+suffix+'.fits'), adisum, scihd

		;add further YJH if statements here once figuring out the ranges in YJ mode
		
		
		if yj then yadicube = adicube[*,*,2:15] else yadicube=adicube[*,*,0:8]
		
		;medarr, yadicube, yadi
		yadi=mean(yadicube,dimension=3)
		writefits, root+''+klipfolder+''+obj+'_ifs_adi_Y'+suffix+'.fits', yadi, head

		if yj then jadicube = adicube[*,*,17:38] else jadicube=adicube[*,*,10:21]
		;medarr, jadicube, jadi
		jadi=mean(jadicube,dimension=3)

		writefits, root+''+klipfolder+''+obj+'_ifs_adi_J'+suffix+'.fits', jadi, head
	
		if not yj then hadicube=adicube[*,*,28:36]
		;medarr, hadicube, hadi
		if not yj then hadi=mean(hadicube,dimension=3)

		if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adi_H'+suffix+'.fits', hadi, head
		
		;make a convolved cube
		conv_xylcube=adicube
		for ccc=0,38 do begin
	
			sz=280.-1.
			width=(wavelength[ccc]*1E-6) / (8.2) * 206265. / 0.00746
			print, 'PSF Width: ',width
			PSF = psf_Gaussian(NPIX=sz, FWHM=[width,width])
			PSFN = PSF/MAX(PSF)
			conv_xylcube[where(finite(conv_xylcube) ne 1)]=0.
			conv_xylcube[*,*,ccc] = convolve(conv_xylcube[*,*,ccc], PSFN)

		endfor

		writefits, root+''+klipfolder+''+obj+'_ifs_adi_xyl_conv'+suffix+'.fits', conv_xylcube, head

		if yj then yadicube=conv_xylcube[*,*,2:15] else yadicube=conv_xylcube[*,*,0:8]
		;medarr, yadicube, yadi
		yadi=mean(yadicube,dimension=3)
		writefits, root+''+klipfolder+''+obj+'_ifs_adi_Y_conv'+suffix+'.fits', yadi, head

		if yj then jadicube=conv_xylcube[*,*,17:38] else jadicube=conv_xylcube[*,*,10:21]
		;medarr, jadicube, jadi
		jadi=mean(jadicube,dimension=3)

		writefits, root+''+klipfolder+''+obj+'_ifs_adi_J_conv'+suffix+'.fits', jadi, head
	
		if not yj then hadicube=conv_xylcube[*,*,28:36]
		;medarr, hadicube, hadi
		if not yj then hadi=mean(hadicube,dimension=3)

		if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adi_H_conv'+suffix+'.fits', hadi, head


		;medarr,conv_xylcube, yjhadi
		yjhadi=mean(conv_xylcube,dimension=3)

		if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adi_YJH_conv'+suffix+'.fits', yjhadi, head else writefits, root+''+klipfolder+''+obj+'_ifs_adi_YJ_conv'+suffix+'.fits', yjhadi, head

		endif ;classical_adi if


		if adi  then begin
for k=0,38 do begin ;loops through the spectral positions
	split=cnt/2-1	;determines how to split data after klip (if desired)


	;making a cube of dits in the wavelength channel (stored as kcube)
	for nc=0,cnt-1 do begin

	;first we shift the frame so that the center appears exactly in between the middle
	;two pixels, and then we will work with an even number of pixels

	indxck=fix(xc[k])
	indyck=fix(yc[k])
	
	remxck=xc[k]-float(indxck)
	remyck=yc[k]-float(indyck)
	
	print, 'Centering on pixel grid by ',-remxck+0.5,-remyck+0.5
	scicube(*,*,k,nc)=fshift(scicube(*,*,k,nc),-remxck+0.5,-remyck+0.5)
	;now the center lies exactly at indxck+0.5,indyck+0.5 
	
	
	frame=scicube[indxck-szz+1:indxck+szz,indyck-szz+1:indyck+szz,k,nc]

		;UPDATING HEADER 
		FXADDPAR, scihd, 'Filter Width', filter,'High-pass filter pixel width.'
		FXADDPAR, scihd, 'ADI K_adiklip', k_adiklip,'ADI K_adiklip'
		FXADDPAR, scihd, 'SDI K_adiklip', k_sdiklip,'SDI K_adiklip'
		FXADDPAR, scihd, 'ADI ANNULI WIDTH', wr,'ADI ANNULAR WIDTH'
		FXADDPAR, scihd, 'SDI ANNULI WIDTH', wr_sdi,'SDI ANNULI WIDTH'
		FXADDPAR, scihd, 'ADI N RINGS', NRINGS,'ADI N RINGS'
		FXADDPAR, scihd, 'SDI N RINGS', NRINGS_SDI,'SDI NRINGS'
		FXADDPAR, scihd, 'N ANG SEG', N_ANG,'N ANG SEG'
		FXADDPAR, scihd, 'ADI ANGSEP', angsep,'ADI ANGSEP'
		FXADDPAR, scihd, 'SDI WAVESEP', SDISEP,'SDI WAVESEP'
		FXADDPAR, scihd, 'Planets Injected?', addplanets,'Were artifical planets injected?'
		FXADDPAR, scihd, 'Injected Contrast:', contrast[0],'Injected artificial planet contrast with star (first planet).'
		FXADDPAR, scihd, 'NPlanets', nplanets,'Number of artificial planet injections.'
		head=scihd
		
		for ij =0, nplanets-1 do FXADDPAR, scihd, strcompress('InjP'+string(ij+1)+'-Con'), $
				contrast[ij], strcompress('Planet '+string(ij+1)+' contrast')
		
		for ij =0, nplanets-1 do FXADDPAR, scihd, strcompress('InjP'+string(ij+1)+'-R'), $
				rplanet[ij], strcompress('Planet '+string(ij+1)+' rho (px)')
		
		for ij =0, nplanets-1 do FXADDPAR, scihd, strcompress('InjP'+string(ij+1)+'-T'), $
				tplanet[ij]/!DTOR, strcompress('Planet '+string(ij+1)+' theta (deg E of N)')

		derotframe=rot(frame,-pa[nc]-pupoff[nc],1.0,/INTERP)	;returns to pupil-stabilized 
	
	print, 'Frame size:',size(frame)
	if nc eq 0 then kcube=frame else kcube=[[[kcube]],[[frame]]]
	if nc eq 0 then derotkcube=derotframe else derotkcube=[[[derotkcube]],[[derotframe]]]


endfor ;done making cube

;splitting cube
if savesplit  then begin
	derotkcube1=derotkcube[*,*,0:split]
	derotkcube2=derotkcube[*,*,split:cnt-1]

	medarr,derotkcube1,korigmed1
	writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_raw_median1_k'+String(k+1)+'prelim.fits',/rem), korigmed1, scihd

	medarr,derotkcube2,korigmed2
	writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_raw_median2_k'+String(k+1)+'prelim.fits',/rem), korigmed2, scihd

	if k eq 0 then medcube1=korigmed1 else medcube1 = [  [[medcube1]],[[korigmed1]]  ]
	if k eq 0 then medcube2=korigmed2 else medcube2 = [  [[medcube2]],[[korigmed2]]  ]
endif ;savesplit if

print, 'Size of k cube:',size(kcube)

medarr,derotkcube,korigmed
writefits, strcompress(root+''+klipfolder+''+obj+'_ifs_adiklip_input_k'+String(k+1)+'prelim.fits',/rem), kcube ;will be deleted later
if k eq 0 then medcube=korigmed else medcube = [  [[medcube]],[[korigmed]]  ]

	;this loops through the frames in each particular band and performs the KLIP routine
	for ii=0, cnt-1 do begin
		print, 'input size:', size(kcube)
		print, '--[ KLIPing Image ', ii, ' ]--'
		print, 'On wavelength:', wavelength[k]
			
  		if hyp  then  klip = nuklipsco(kcube, k_adiklip, target=ii, $
  		 anglemask=anglemask, distmask=distmask, posang=-angles,  $
 		 	wl=wave[k],diam=8.,pixelscale=0.00746,angsep=angsep,anglemax=anglemax,obj=obj,nrings=nrings,wr=wr,$
  		  n_ang =n_ang,spot_radius=spot_radius,rho=rho,phi=phi,/hyper) 
  		 
  		if annmode  then klip = nuklipsco(kcube, k_adiklip, target=ii, anglemask=anglemask, distmask=distmask,$
  		  posang=-angles,  wl=wave[k],diam=8.,pixelscale=0.00746,angsep=angsep,anglemax=anglemax,$
  		  obj=obj,nrings=nrings,wr =wr, n_ang =n_ang,annmode_inout=annmode_inout)
  		  
  		  if annmode eq 0 and hyp eq 0 then klip = nuklipsco(kcube, k_adiklip, target=ii, anglemask=anglemask, 	$
  		  distmask=distmask, posang=-angles,  wl=wave[k],diam=8.,pixelscale=0.00746,angsep=angsep,anglemax=anglemax,$
  		  obj=obj,nrings=nrings,wr =wr, n_ang =n_ang)
  		 	print, 'output size:', size(klip)

		if ii eq 0 then klipcube=klip else klipcube=[[[klipcube]],[[klip]]]
	endfor
			
		;derotates the frames and median combines for each band
		
		print, size(fullcubeps)
		print, size(klipcube)
		
		for ii=0, cnt-1 do begin
			fullcubeps[*,*,k,ii]=klipcube[*,*,ii]	
 			klipcube[*,*,ii]=rot(klipcube[*,*,ii],-pa[ii]-pupoff[ii],/INTERP)
 			fullcube[*,*,k,ii]=klipcube[*,*,ii]
	
		endfor
		

		if comb_type eq 'median' then medarr, klipcube, kframemed
		if comb_type eq 'mean' then kframemed=mean(klipcube,dim=3)
		if comb_type eq 'nw-mean' then kframemed=nw_ang_comb(klipcube,pa+pupoff)

		
		
		if debug  then medarr, reform(fullcubeps[*,*,k,*]), kframemedps

		if debug  then writefits, root+klipfolder+'/DEBUG_adiklipmedps'+String(k)+'_ouput.fits', kframemedps


		if debug  and k eq 38 then writefits, root+klipfolder+'/DEBUG_adiklip'+String(k)+'_ouput_full.fits', fullcubeps
		if debug  and k eq 38 then writefits, root+klipfolder+'/DEBUG_adiklip'+String(k)+'_ouput_full-derot.fits', fullcube

	for ii=0, cnt-1 do if ii eq 0 then sumk=klipcube[*,*,ii]$
			else sumk=sumk+klipcube[*,*,ii]

	
		for ii=0, split do if ii eq 0 then sumk1=klipcube[*,*,ii]$
			else sumk1=sumk1+klipcube[*,*,ii]
	
		for ii=split,cnt-1. do if ii eq split then sumk2=klipcube[*,*,ii]$
			else sumk2=sumk2+klipcube[*,*,ii]
	
	
	klipcube1=klipcube[*,*,0:split]
	medarr,klipcube1,kframemed1
	klipcube2=klipcube[*,*,split:cnt-1.]
	medarr,klipcube2,kframemed2

	kframemed[where(finite(kframemed) eq 0)]=0.0
		sumk[where(finite(sumk) eq 0)]=0.0
		
			kframemed1[where(finite(kframemed1) eq 0)]=0.0
		sumk1[where(finite(sumk1) eq 0)]=0.0
		
			kframemed2[where(finite(kframemed2) eq 0)]=0.0
		sumk2[where(finite(sumk2) eq 0)]=0.0
				
	sz=280.-1.
	width=(wavelength[k]*1E-6) / (8.2) * 206265. / 0.00746
	print, 'PSF Width: ',width
	PSF = psf_Gaussian(NPIX=sz, FWHM=[width,width])
	PSFN = PSF/MAX(PSF)
	kframemed_conv=kframemed
	kframemed_conv[where(finite(kframemed_conv) ne 1)]=0.
	kframemed_conv = convolve(kframemed_conv, PSFN)

	
	writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adiklip_median_k'+String(k+1)+'prelim.fits',/rem), kframemed, scihd
	
	
	writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adiklip_median_conv_k'+String(k+1)+'prelim.fits',/rem), kframemed_conv, scihd
	
if savesplit  then 	writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adiklip_median1_k'+String(k+1)+'prelim.fits',/rem), kframemed1, scihd
	
if savesplit  then 	writefits, STRCOMPRESS(root+''+klipfolder+''+obj+'_ifs_adiklip_median2_k'+String(k+1)+'prelim.fits',/rem), kframemed2, scihd
	

		if k eq 0 then newcube=fltarr(2*szz,2*szz,39)
	if k eq 0 then newcube[*]=0.
	if k eq 0 then sumcube=newcube
	
	if k eq 0 then newcube1=fltarr(2*szz,2*szz,39)
	if k eq 0 then newcube1[*]=0.
	if k eq 0 then sumcube1=newcube1
	
	if k eq 0 then newcube2=fltarr(2*szz,2*szz,39)
	if k eq 0 then newcube2[*]=0.
	if k eq 0 then sumcube2=newcube2
		
		
		aasz=2*szz
		kframemed=kframemed[0:aasz-1,0:aasz-1]
		sumk=sumk[0:aasz-1,0:aasz-1]
		kframemed1=kframemed1[0:aasz-1,0:aasz-1]
		sumk1=sumk1[0:aasz-1,0:aasz-1]
		kframemed2=kframemed2[0:aasz-1,0:aasz-1]
		sumk2=sumk2[0:aasz-1,0:aasz-1]
		

		print, size(newcube)
				print, size(kframemed)

	newcube[*,*,k]=kframemed
	sumcube[*,*,k]=sumk
	
	newcube1[*,*,k]=kframemed1
	sumcube1[*,*,k]=sumk1
	
	newcube2[*,*,k]=kframemed2
	sumcube2[*,*,k]=sumk2
	
	
	;generating Y image
	if k eq 8 then begin
	

	if yj then yklipcube=newcube[*,*,2:15] else yklipcube=newcube[*,*,0:8]
	sumy=mean(yklipcube,dim=3)
	writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_Y'+suffix+'.fits', sumy

	endif
	


	;generating J image
	if k eq 21 then begin


	if yj then jklipcube=newcube[*,*,17:38] else jklipcube=newcube[*,*,10:21]
	sumj=mean(jklipcube,dim=3)
	writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_J'+suffix+'.fits', sumj
	
	endif
endfor
;----------------ADIKLIP complete

;fullcube contains the raw ADI-processed cube, newcube contains the x,y,39 median-combined cube

;this is the cube of the 39 images, the individual frames may be deleted once this file is generated
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_xyln.fits', fullcube, scihd
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_xyln_pupst.fits', fullcubeps, scihd


writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_xyl'+suffix+'.fits', newcube, scihd
;writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_coadd_cube.fits', sumcube, scihd
;writefits, root+''+klipfolder+''+obj+'_ifs_original_cube.fits', medcube, scihd

if savesplit  then begin 
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_med_cube-1'+suffix+'.fits', newcube1, scihd
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_coadd_cube-1'+suffix+'.fits', sumcube1, scihd
writefits, root+''+klipfolder+''+obj+'_ifs_original_cube-1'+suffix+'.fits', medcube1, scihd
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_med_cube-2'+suffix+'.fits', newcube2, scihd
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_coadd_cube-2'+suffix+'.fits', sumcube2, scihd
writefits, root+''+klipfolder+''+obj+'_ifs_original_cube-2'+suffix+'.fits', medcube2, scihd
endif

;make a convolved cube
conv_xylcube=newcube
for ccc=0,38 do begin
	
	sz=280.-1.
	width=(wavelength[ccc]*1E-6) / (8.2) * 206265. / 0.00746
	print, 'PSF Width: ',width
	PSF = psf_Gaussian(NPIX=sz, FWHM=[width,width])
	PSFN = PSF/MAX(PSF)
	conv_xylcube[where(finite(conv_xylcube) ne 1)]=0.
	conv_xylcube[*,*,ccc] = convolve(conv_xylcube[*,*,ccc], PSFN)

endfor

writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_xyl_conv'+suffix+'.fits', conv_xylcube, head

if yj then yadicube=conv_xylcube[*,*,2:15] else yadicube=conv_xylcube[*,*,0:8]
;medarr, yadicube, yadi
yadi=mean(yadicube,dimension=3)
writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_Y_conv'+suffix+'.fits', yadi, head

if yj then jadicube=conv_xylcube[*,*,17:38] else jadicube=conv_xylcube[*,*,10:21]
;medarr, jadicube, jadi
jadi=mean(jadicube,dimension=3)

writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_J_conv'+suffix+'.fits', jadi, head
	
if not yj then hadicube=conv_xylcube[*,*,28:36]
;medarr, hadicube, hadi
if not yj then hadi=mean(hadicube,dimension=3)

if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_H_conv'+suffix+'.fits', hadi, head

;medarr,conv_xylcube, yjhadi
yjhadi=mean(conv_xylcube,dimension=3)

if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_YJH_conv'+suffix+'.fits', yjhadi, head else writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_YJ_conv'+suffix+'.fits', yjhadi, head

;stacking images H, YJH

start=28
for num=start,36 do begin
 if num eq start then sumh=newcube[*,*,num] else sumh=sumh+newcube[*,*,num]
endfor
sumh=sumh/9.
if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_H'+suffix+'.fits', sumh, head

;h first half
start=28
for num=start,36 do begin
 if num eq start then sumh1=newcube1[*,*,num] else sumh1=sumh1+newcube1[*,*,num]
endfor
sumh1=sumh1/9.
if savesplit and not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_H-1'+suffix+'.fits', sumh1, head

;second half
start=28
for num=start,36 do begin
 if num eq start then sumh2=newcube2[*,*,num] else sumh2=sumh2+newcube2[*,*,num]
endfor
sumh2=sumh2/9.
if savesplit and not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_H-2'+suffix+'.fits', sumh2, head
		
start=0
for num=start,38 do begin
 if num eq start then sumyjh=newcube[*,*,num] else sumyjh=sumyjh+newcube[*,*,num]
endfor
sumyjh=sumyjh/39.
if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_YJH'+suffix+'.fits', sumyjh, head  else writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_YJ'+suffix+'.fits', sumyjh, head

;writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_xyln.fits', fullcube, head

finalcube=fullcube
yjhcube=[]
for kz=0, (size(finalcube))(4)-1 do begin &	kzcube=reform(finalcube[*,*,*,kz]) & medarr,kzcube,kzmed & yjhcube=[[[yjhcube]],[[kzmed]]] & endfor	
	if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_YJH_cube'+suffix+'.fits', yjhcube, head else writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_YJ_cube'+suffix+'.fits', yjhcube, head 

start=0
for num=start,38 do begin
 if num eq start then sumyjh1=newcube1[*,*,num] else sumyjh1=sumyjh1+newcube1[*,*,num]
endfor
sumyjh1=sumyjh1/39.
if savesplit  then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_BB-1'+suffix+'.fits', sumyjh1, head

start=0
for num=start,38 do begin
 if num eq start then sumyjh2=newcube2[*,*,num] else sumyjh2=sumyjh2+newcube2[*,*,num]
endfor
sumyjh2=sumyjh2/39.
if savesplit  then writefits, root+''+klipfolder+''+obj+'_ifs_adiklip_BB-2'+suffix+'.fits', sumyjh2, head

path=root+''+klipfolder+''
;oldfiles=FILE_SEARCH(path,'*noklip.fits',COUNT=cc)
oldfiles=FILE_SEARCH(path,'*prelim.fits',COUNT=cc)
FILE_DELETE, oldfiles

endif ;adi if

;----------------Starting SDI

if sdi  then begin

if fresh_sdi  then adicube=scicube else $
	adicube=readfits(root+klipfolder+obj+'_ifs_adiklip_xyln.fits')
	


if rdi_sdi  then adicube=readfits(root+klipfolder+obj+'_ifs_rdiklip_xyln.fits')

if fresh_sdi  then begin
for k=0,38 do begin
		for ii=0, cnt-1 do begin
 		adicube[*,*,k,ii]=rot(adicube[*,*,k,ii],-pa[ii]-pupoff[ii],/INTERP)
		endfor
endfor
endif

	;binning temporally
if bin  then begin 

if binsize eq 2 then begin
binnedcube=fltarr((size(adicube))(1),(size(adicube))(2),(size(adicube))(3),fix((size(adicube))(4))/2.)
	for i=0,cnt-1 do begin
		if (i+1) mod 2 eq 0 then binnedcube[*,*,*,i/2]=(adicube[*,*,*,i]+adicube[*,*,*,i-1])/2.
	endfor
cnt=fix(cnt/2.)
endif

if binsize eq 3 then begin
binnedcube=fltarr((size(adicube))(1),(size(adicube))(2),(size(adicube))(3),fix((size(adicube))(4))/3)
	for i=0,cnt-1 do begin
		if (i+1) mod 3 eq 0 then binnedcube[*,*,*,i/3]=(adicube[*,*,*,i]+adicube[*,*,*,i-1]+adicube[*,*,*,i-2])/3.
	endfor
cnt=fix(cnt/3.)
endif

if binsize eq 4 then begin
binnedcube=fltarr((size(adicube))(1),(size(adicube))(2),(size(adicube))(3),fix((size(adicube))(4))/4.)
	for i=0,cnt-1 do begin
		if (i+1) mod 4 eq 0 then binnedcube[*,*,*,i/4]=(adicube[*,*,*,i]+adicube[*,*,*,i-1]+adicube[*,*,*,i-2]+adicube[*,*,*,i-3])/4.
	endfor
cnt=fix(cnt/4.)
endif

if binsize eq 5 then begin
binnedcube=fltarr((size(adicube))(1),(size(adicube))(2),(size(adicube))(3),fix((size(adicube))(4))/5)
	for i=0,cnt-1 do begin
		if (i+1) mod 5 eq 0 then binnedcube[*,*,*,i/5]=(adicube[*,*,*,i]+adicube[*,*,*,i-1]+adicube[*,*,*,i-2]+adicube[*,*,*,i-3]+adicube[*,*,*,i-4])/5.
	endfor
cnt=fix(cnt/5.)
endif

adicube=binnedcube
endif

finalcube=adicube ;to be used later
for i=0,cnt-1 do begin

	tempcube=reform(adicube[*,*,*,i]) ;this is a x,y,l cube from just a single IFS frame
	tempcubesc=tempcube	;this will be the scaled cube
	
	print, size(tempcubesc)
	
	if debug  then writefits, '~/Desktop/sdi_input_prescaling.fits',tempcube, head
	
	for k=0,38 do begin ;now for each lambda slice we scale the cube then perform SDI
		for kk=0,38 do begin ;scaling the cube
			tempcubesc[*,*,kk]=rot(tempcube[*,*,kk],0., (scaling[k]/scaling[kk]), /INTERP)
		endfor
		
		tempcubesc[where(finite(tempcubesc) eq 0)]=0.
		starttime=systime(/JULIAN)

		if debug  then writefits, '~/Desktop/sdi_input_debug.fits',tempcubesc, head
	
		print, '--[ SDI-KLIPing Image ', i, ' out of ',cnt-1,' ]--'
		print, 'On wavelength:', wavelength[k]
		;now use SDI klip
		if annmode  then tempcubesck = sdiklip(tempcubesc, k_sdiklip, target=k, anglemask=anglemask, distmask=distmask,posang=-angles, scaling=scaling,  wl=wavelength[k], diam=8., pixelscale=0.00746, angsep=sdisep, obj=obj, nrings=nrings_sdi,wr =wr_sdi, n_ang =n_ang,annmode_inout=annmode_inout)
		if hyp  then tempcubesck = sdiklip(tempcubesc, k_sdiklip, target=k, anglemask=anglemask, distmask=distmask,posang=-angles, scaling=scaling,  wl=wavelength[k], diam=8., pixelscale=0.00746, angsep=sdisep, obj=obj, nrings=nrings_sdi,wr =wr_sdi, n_ang =n_ang,spot_radius=spot_radius,rho=rho,phi=phi, /hyper)
		if annmode eq 0 and hyp eq 0 then tempcubesck = sdiklip(tempcubesc, k_sdiklip, target=k, anglemask=anglemask, distmask=distmask,posang=-angles, scaling=scaling,  wl=wavelength[k], diam=8., pixelscale=0.00746, angsep=sdisep, obj=obj, nrings=nrings_sdi,wr =wr_sdi, n_ang =n_ang)
		print, '------------------------[ Percent complete:', ((float(i)/float(cnt-1.))+float(k+1.)/(39.*float(cnt)))*100.
		endtime=systime(/JULIAN)
		print, '------------------------[ Time remaining (min):', (1.-((float(i)/float(cnt-1.))+float(k+1.)/(39.*float(cnt))))*(39.*float(cnt))*(endtime-starttime) *86400./60.
		
				if debug  then	writefits, '~/Desktop/sdi_output_debug.fits',tempcubesck, head

		finalcube[*,*,k,i]=tempcubesck
		finalcubederot=finalcube
		if k eq 38 then begin
			if rdi_sdi  then for ii=0, cnt-1 do begin
			for kk=0, 38 do begin
 			finalcubederot[*,*,kk,ii]=rot(finalcube[*,*,kk,ii],-pa[ii]-pupoff[ii],/INTERP)
 			endfor
			endfor
			medarr, reform(finalcubederot[*,*,*,i]), framei
			writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJH_'+String(i)+'_prelim.fits',framei, head
		endif
	endfor

	

endfor

	finalcubederot=finalcube
	
	if rdi_sdi  then begin
for k=0,38 do begin
		for ii=0, cnt-1 do begin
 		finalcubederot[*,*,k,ii]=rot(finalcube[*,*,k,ii],-pa[ii]-pupoff[ii],/INTERP)
		endfor
endfor
endif

		;derotates the frames and median combines for each band
	for k=0,38 do begin
		if comb_type eq 'median' then medarr, reform(finalcubederot[*,*,k,*]), kframemed
		if comb_type eq 'mean' then kframemed=mean(reform(finalcubederot[*,*,k,*]),dim=3)
		if comb_type eq 'nw-mean' then kframemed=nw_ang_comb(reform(finalcubederot[*,*,k,*]),pa+pupoff)
		if k eq 0 then xylcube=kframemed else xylcube=[ [[xylcube]] , [[kframemed]] ]
		if k eq 0 then sumyjh=kframemed else sumyjh=sumyjh+kframemed
	endfor
	
	simyjh=sumyjh/39.
	
	;medarr, xylcube, medyjh
	medyjh=mean(xylcube,dim=3)
	yjhcube=[]
for kz=0, (size(finalcube))(4)-1 do begin &	kzcube=reform(finalcube[*,*,*,kz]) & medarr,kzcube,kzmed & yjhcube=[[[yjhcube]],[[kzmed]]] & endfor	


;make a convolved cube
	conv_xylcube=xylcube

for ccc=0,38 do begin
	
	sz=280.-1.
	width=(wavelength[ccc]*1E-6) / (8.2) * 206265. / 0.00746
	print, 'PSF Width: ',width
	PSF = psf_Gaussian(NPIX=sz, FWHM=[width,width])
	PSFN = PSF/MAX(PSF)
	conv_xylcube[where(finite(conv_xylcube) ne 1)]=0.
	conv_xylcube[*,*,ccc] = convolve(conv_xylcube[*,*,ccc], PSFN)

endfor
	
if yj then writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJ'+suffix+'.fits', medyjh, head else writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJH'+suffix+'.fits', medyjh, head
if yj then writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJ_cube'+suffix+'.fits', yjhcube, head else writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJH_cube'+suffix+'.fits', yjhcube, head
;writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJH_sum.fits', sumyjh, head
writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_xyln.fits', finalcube, head
writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_xyl'+suffix+'.fits', xylcube, head

if yj then ysdicube=xylcube[*,*,2:15] else ysdicube=xylcube[*,*,0:8]
;medarr, ysdicube, ysdi
ysdi=mean(ysdicube,dim=3)
writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_Y'+suffix+'.fits', ysdi, head

if yj then jsdicube=xylcube[*,*,17:38] else jsdicube=xylcube[*,*,10:21]
;medarr, jsdicube, jsdi
jsdi=mean(jsdicube,dim=3)
writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_J'+suffix+'.fits', jsdi, head
	
if not yj then hsdicube=xylcube[*,*,28:36]
;medarr, hsdicube, hsdi
if not yj then hsdi=mean(hsdicube,dim=3)
if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_H'+suffix+'.fits', hsdi, head
writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_xyl_conv'+suffix+'.fits', conv_xylcube, head

if yj then ysdicube=conv_xylcube[*,*,2:15] else ysdicube=conv_xylcube[*,*,0:8]
ysdi=mean(ysdicube,dimension=3)
writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_Y_conv'+suffix+'.fits', ysdi, head

if yj then jsdicube=conv_xylcube[*,*,17:38] else jsdicube=conv_xylcube[*,*,10:21]
jsdi=mean(jsdicube,dimension=3)

writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_J_conv'+suffix+'.fits', jsdi, head
	
if not yj then hsdicube=conv_xylcube[*,*,28:36]
if not yj then hsdi=mean(hsdicube,dimension=3)

if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_H_conv'+suffix+'.fits', hsdi, head


yjhsdi=mean(conv_xylcube,dimension=3)

if not yj then  writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJH_conv'+suffix+'.fits', yjhsdi, head else writefits, root+''+klipfolder+''+obj+'_ifs_sdiklip_YJ_conv'+suffix+'.fits', yjhsdi, head


path=root+'/'+klipfolder+'/'
oldfiles=FILE_SEARCH(path,'*prelim.fits',COUNT=cc)
FILE_DELETE, oldfiles


endif

;----------------Starting RDI

if rdi  then begin

finalcube=scicube ;to be used later

;make cubes the same size
endsize=(size(scicube))(4)-1
if endsize lt (size(refcube))(4)-1 then refcube=refcube[*,*,*,0:endsize]

print, size(refcube)
print, size(scicube)


for k=0,38 do begin

	scikcube=reform(scicube[*,*,k,*]) ;this is a x,y,l cube from just a single IFS frame
	refkcube=reform(refcube[*,*,k,*])	;this will be the scaled cube
		
	if debug  then writefits, '~/Desktop/rdi_sci_input.fits',scikcube, head
	if debug  then writefits, '~/Desktop/rdi_ref_input.fits',refkcube, refhead
	
	for i=0,cnt-1 do begin ;loop through target frames and perform RDI
		refkcube[where(finite(refkcube) eq 0)]=0.
		starttime=systime(/JULIAN)

		print, '--[ SDI-KLIPing Image ', i, ' out of ',cnt-1,' ]--'
		print, 'On wavelength:', wavelength[k]
		;now use SDI klip
		if hyp eq 0 and annmode  then rdikcube = rdiklip(scikcube, refkcube, k_rdiklip, target=i, anglemask=anglemask, distmask=distmask,posang=-angles, scaling=scaling,  wl=wavelength[k], diam=8., pixelscale=0.00746, angsep=0., obj=obj, nrings=nrings_rdi,wr =wr_rdi, n_ang =n_ang,annmode_inout=annmode_inout)
		if hyp  then rdikcube = rdiklip(scikcube, refkcube, k_rdiklip, target=i, anglemask=anglemask, distmask=distmask,posang=-angles, scaling=scaling,  wl=wavelength[k], diam=8., pixelscale=0.00746, angsep=0., obj=obj, nrings=nrings_rdi,wr =wr_rdi, n_ang =n_ang,spot_radius=spot_radius,rho=rho,phi=phi, /hyper)
		if hyp eq 0 and annmode eq 0 then rdikcube = rdiklip(scikcube, refkcube, k_rdiklip, target=i, anglemask=anglemask, distmask=distmask,posang=-angles, scaling=scaling,  wl=wavelength[k], diam=8., pixelscale=0.00746, angsep=0., obj=obj, nrings=nrings_rdi,wr =wr_rdi, n_ang =n_ang)

		if debug  then	writefits, '~/Desktop/rdi_output_debug.fits',rdikcube, head

		print, size(rdikcube)	
		
		finalcube[*,*,k,i]=rdikcube
		
		if i eq cnt-1 then begin
		finalcubederot=finalcube
			for ii = 0 , cnt-1 do finalcubederot[*,*,k,ii]=rot(finalcube[*,*,k,ii],-pa[ii]-pupoff[ii],/INTERP)
			medarr, reform(finalcubederot[*,*,k,*]), framek
			writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_k'+String(k)+'_prelim.fits',framek, head
		endif
	endfor
endfor
	finalcubederot=finalcube
	

		;derotates the frames and median combines for each band
	for k=0,38 do begin
	
	for ii=0, cnt-1 do begin
 			finalcubederot[*,*,k,ii]=rot(finalcubederot[*,*,k,ii],-pa[ii]-pupoff[ii],/INTERP)
	endfor
	
		if comb_type eq 'median' then medarr, reform(finalcubederot[*,*,k,*]), kframemed
		if comb_type eq 'mean' then kramemed=mean(reform(finalcubederot[*,*,k,*]),dim=3)
		if comb_type eq 'nw-mean' then kramemed=nw_ang_comb(reform(finalcubederot[*,*,k,*]),pa+pupoff)

		if k eq 0 then xylcube=kframemed else xylcube=[ [[xylcube]] , [[kframemed]] ]
		
		if k eq 0 then sumyjh=kframemed else sumyjh=sumyjh+kframemed
	endfor
	
	simyjh=sumyjh/39.
	
	medarr, xylcube, medyjh
	yjhcube=[]
for kz=0, (size(finalcubederot))(4)-1 do begin &	kzcube=reform(finalcubederot[*,*,*,kz]) & medarr,kzcube,kzmed & yjhcube=[[[yjhcube]],[[kzmed]]] & endfor	
	
if yj then writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_YJ'+suffix+'.fits', medyjh, head else writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_YJH'+suffix+'.fits', medyjh, head
if yj then writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_YJ_cube'+suffix+'.fits', yjhcube, head else writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_YJH_cube'+suffix+'.fits', yjhcube, head
;writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_YJH_sum.fits', sumyjh, head

writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_xyln.fits', finalcube, head
writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_xyl'+suffix+'.fits', xylcube, head

if yj then sdicube=xylcube[*,*,2:15] else ysdicube=xylcube[*,*,0:8]
;medarr, ysdicube, ysdi
ysdi=mean(ysdicube,dim=3)
writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_Y'+suffix+'.fits', ysdi, head

if yj then jsdicube=xylcube[*,*,17:38] else jsdicube=xylcube[*,*,10:21]
;medarr, jsdicube, jsdi
jsdi=mean(jsdicube,dim=3)
writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_J'+suffix+'.fits', jsdi, head
	
if not yj then hsdicube=xylcube[*,*,28:36]
;medarr, hsdicube, hsdi
if not yj then hsdi=mean(hsdicube,dim=3)
if not yj then writefits, root+''+klipfolder+''+obj+'_ifs_rdiklip_H'+suffix+'.fits', hsdi, head


path=root+'/'+klipfolder+'/'
oldfiles=FILE_SEARCH(path,'*prelim.fits',COUNT=cc)
FILE_DELETE, oldfiles


endif

end
