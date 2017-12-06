pro autosphere, object_names, skip=skip, fresh=fresh, single=single, no_interupt=no_interupt,suffix=suffix,klip=klip,inject=inject,ifs_only=ifs_only,no_ifs=no_ifs

;keyword explanations:
;skip will skip to the post-processing steps (irdis and IFS)
;single will enable a HAK after each object that is reducted
;no_interupt will not interupt if calibration files have different dates than science
;suffix will add a suffix to the files 
;klip will run the klip algorith on IRDIS data
;inject will inject fake planets
;ifs_only will skip the IRDIS calibrations
;no_ifs will do only IRDIS



;AUTHOR: K. Wagner (UA)

;this script reads in a folder of of fits files downloaded from the ESO archive (including science and calibrations from IRDIS and or IFS)

;purpose is to sort the data and provide initial calibrations (dark subtraction, bad pixel correction, flat fielding, bad pixel correction)



;-----------------------------------------------------------------------------------------

for iii=0, n_elements(object_names)-1 do begin

cgcleanup

object_name=object_names[iii]

speaking=1

if not keyword_set(ifs_only) then ifs_only=0
if keyword_set(no_ifs) then process_ifs=0 else process_ifs=1

;following switches are for IRDIS data


;fresh=1	;will delete the processed folder when beginning...
		;made the above into a keyword 2017-11-14
if keyword_set(fresh) then fresh=1 else fresh=0

if keyword_set(single) then single=1 else single=0	
;runs HAK between runs (must hit any key to continue, or ESC to end reduction train). 

;object_name='S47'

;will go straight to the final post-processing
	if keyword_set(skip) then skip_start=1 else skip_start=0

	if skip_start then fresh=0 ;if skipping start then fresh makes no sense



reduction_path='/home/yzhou/Documents/test_wagner/'

input_directory=strcompress(reduction_path+object_name+'/',/rem)

;setting the path to the raw data (extracted .Z files)
download_subdir=strcompress(input_directory+'data_with_raw_calibs/',/rem)

dark_comb_imtype='median' ;'median' or 'mean'

sub_dark=1	;switch to turn dark subtraction on/off
	if ifs_only then sub_dark=0

remove_bads=1 ;very, very slow but worth it
	badmap_loc=reduction_path+'calib/SPHERE_badpix-map.fits'
	find_bads=0	;look for additional bad pixels?
	bad_thresh=5	;DN above which is to be considered a bad pixel in dark frame
	neg_bad_thresh=-5
	if ifs_only then remove_bads=0

reduce_irdis_sizes=1 	;re-zip raw data and delete intermediate products to save space?
	if ifs_only then reduce_irdis_sizes=0
	reduce_ifs_sizes=reduce_irdis_sizes
post_process_irdis=1	;run the reduce_irdis script?
	auto_cen=1	;automatically center IRDIS data
	if ifs_only then post_process_irdis=0


unzip=1	;will first uncompress the raw data, may or may not speed up overall script runtime. Fastest is to unzip in UNIX and delete the *.Z files. 

;following switches are for IFS data





starttime=systime(/JULIAN)


;-----------------------------------------------------------------------------------------

if not skip_start then begin

	if not ifs_only then begin
print, 'Looking for previously zipped data...'
	files=file_search(input_directory+'IRDIS/','raw.zip',count=cnt)
	if cnt gt 0 then file_unzip,files
	endif

;next steps incorporate ifs as well

print, 'Step 0: Cleaning downloaded files...'
	files=file_search(download_subdir,'M.SPHERE*',count=cnt)
	if cnt gt 0 then file_delete,files
	files=file_search(download_subdir,'*.txt',count=cnt)
	if cnt gt 0 then file_delete,files
	files=file_search(download_subdir,'*.xml',count=cnt)
	if cnt gt 0 then file_delete,files
	
	if unzip then begin
		files=file_search(download_subdir,'*.fits.Z',count=cnt)
		for ii=0, cnt-1 do begin 
			print, 'Unzipping file ',ii+1,'/',cnt
			a=readfits(files[ii],hd) 
			writefits, strcompress(files[ii]+'.fits',/rem),a,hd 
		endfor;file_gunzip, files[ii]
		if cnt gt 0 then file_delete, files, /recycle
	endif

print, 'Step 1: Making subdirectories... '
	if fresh then file_delete,input_directory+'IRDIS/calib',$
				input_directory+'IRDIS/products',$
				input_directory+'IFS/processed',$
				input_directory+'IRDIS/processed',$
				input_directory+'IRDIS/raw',$
				input_directory+'IFS/raw',$
				input_directory+'IFS/processed',$
				input_directory+'IFS/extra',$
				input_directory+'IRDIS/flux',$
				input_directory+'IRDIS/center',$
				/quiet,/recursive,/recycle

	file_mkdir, input_directory+'IRDIS/raw',$
				input_directory+'IRDIS/calib',$
				input_directory+'IRDIS/flux',$
				input_directory+'IRDIS/center',$
				input_directory+'IRDIS/products',$
				input_directory+'IRDIS/processed',$
				input_directory+'IFS/raw',$			
				input_directory+'IFS/extra',$
				input_directory+'IFS/products',$
				input_directory+'IFS/processed'
print, '	Done.'
	
;-----------------------------------------------------------------------------------------
	
	
print, 'Step 2: Searching for .fits files... Done.'
	files=file_search(download_subdir,'*.fits.Z',count=cnt)	;first search for compressed files
	if cnt le 0 then files=file_search(download_subdir,'*.fits',count=cnt)

	
print, '	Found ', cnt, ' fits files.'
if cnt gt 0 then begin

;-----------------------------------------------------------------------------------------


print, 'Step 3: Looping through fits headers and sorting files...'
for ii=0, cnt-1 do begin
	frame=readfits(files[ii],hdr,/silent)
	
	
	detector=''
	imtype=''
	date=''
	exptime=''
	ndit=''
	dbfilt=''
	ndfilt=''
	
	;extracting info...
	;want to know what detector, imtype, date, DIT, ND filter, DB filter
	detector=string(esopar(hdr,'HIERARCH ESO DET NAME '))
	imtype=string(esopar(hdr,'HIERARCH ESO DPR TYPE '))
	date=fxpar(hdr,'DATE')
	object=string(fxpar(hdr,'OBJECT'))
	date_full=date
	date=strmid(date,0,10)	;only keep YYYY-MM-DD
	exptime=fxpar(hdr,'EXPTIME')
	ndit=esopar(hdr,'HIERARCH ESO DET NDIT ')
	dbfilt=esopar(hdr,'ESO INS1 OPTI2 NAME ')
	ndfilt = esopar(hdr,'ESO INS4 COMB IND')
	if isa(ndfilt, /string) eq 0 then ndfilt = esopar(hdr,'ESO INS4 FILT2 NAME')  

	if ii eq 0 then begin
		detectors=detector
		dates=date
		full_dates=date_full
		imtypes=imtype
		exptimes=exptime
		ndfilts=ndfilt
		dbfilts=dbfilt
		ndits=ndit
		objects=object
	endif else begin
		detectors=[detectors,detector]
		dates=[dates,date]
		imtypes=[imtypes,imtype]
		exptimes=[exptimes,exptime]
		ndfilts=[ndfilts,ndfilt]
		dbfilts=[dbfilts,dbfilt]
		ndits=[ndits,ndit]
		full_dates=[full_dates,date_full]
		objects=[objects,object]
	endelse

	if speaking then begin
		print, strcompress('	Frame '+string(ii)+':')
		print, '	Date       = ',date
		print, '	Object     = ',object
		print, '	Detector   = ',detector
		print, '	Frame imtype = ',imtype
		print, '	Exptime    = ',exptime
		print, '	NDITs    = ',ndit
		print, '	ND filter  = ',ndfilt
		print, '	DB Filter  = ',dbfilt
	endif
endfor
print, '	Done.'

;separating dates into other forms
	yyyys=strmid(dates,0,4)
	mms=strmid(dates,5,2)
	dds=strmid(dates,9,2)
	
;-----------------------------------------------------------------------------------------


	
;separate IRDIS and IFS... IFS is done at this point, IRDIS reduction continues below.
print, 'Step 4: Separating IFS frames. Done with IFS step. Proceed to AVs scripts.'
	if total(where(strcompress(detectors,/rem) eq 'IFS')) gt 0 then file_move,$
		files(where(strcompress(detectors,/rem) eq 'IFS')),input_directory+'IFS/raw'

;-----------------------------------------------------------------------------------------


print, 'Step 5: Separating IRDIS frames.'
	if total(where(strcompress(detectors,/rem) eq 'IRDIS')) gt 0 then file_move,$
	files(where(strcompress(detectors,/rem) eq 'IRDIS')),input_directory+'IRDIS/raw'

endif else print, 'No files found in download directory... assuming they were already sorted, proceeding to step 6.'

;-----------------------------------------------------------------------------------------

if not ifs_only then begin

print, 'Step 6: Looping through IRDIS fits headers and sorting files...'
	files=file_search(input_directory+'IRDIS/raw','*.fits.Z',count=cnt)	;first find compressed files

	if cnt le 0 then files=file_search(input_directory+'IRDIS/raw','*.fits',count=cnt)

for ii=0, cnt-1 do begin
	frame=readfits(files[ii],hdr,/silent)
	
	;extracting info...
	;want to know what detector, imtype, date, DIT, ND filter, DB filter
	detector=esopar(hdr,'HIERARCH ESO DET NAME')
	imtype=String(esopar(hdr,'HIERARCH ESO DPR TYPE'))
	date=fxpar(hdr,'DATE')
	date_full=date
	date=strmid(date,0,10)	;only keep YYYY-MM-DD
	exptime=float(fxpar(hdr,'EXPTIME'))
	ndit=esopar(hdr,'HIERARCH ESO DET NDIT')
	dbfilt=esopar(hdr,'ESO INS1 OPTI2 NAME')
	object=fxpar(hdr,'OBJECT')
	ndfilt = esopar(hdr,'ESO INS4 COMB IND')
	if isa(ndfilt, /string) eq 0 then ndfilt = esopar(hdr,'ESO INS4 FILT2 NAME')  

	if ii eq 0 then begin
		detectors=detector
		dates=date
		imtypes=imtype
		exptimes=exptime
		ndfilts=ndfilt
		dbfilts=dbfilt
		ndits=ndit
		full_dates=date_full
		objects=object
	endif else begin
		detectors=[detectors,detector]
		dates=[dates,date]
		imtypes=[imtypes,imtype]
		exptimes=[exptimes,exptime]
		ndfilts=[ndfilts,ndfilt]
		dbfilts=[dbfilts,dbfilt]
		ndits=[ndits,ndit]
		full_dates=[full_dates,date_full]
		objects=[objects,object]
	endelse

	if speaking then begin
		print, strcompress('	Frame '+string(ii)+':')
		print, '	Date       = ',date
		print, '	Object     = ',object
		print, '	Detector   = ',detector
		print, '	Frame imtype = ',imtype
		print, '	Exptime    = ',exptime
		print, '	NDITs    = ',ndit
		print, '	ND filter  = ',ndfilt
		print, '	DB Filter  = ',dbfilt
	endif
endfor
print, '	Done.'	

dates_full=full_dates

;-----------------------------------------------------------------------------------------


print, 'Step 7: Collecting object files...'
	obj_inds=where(strcompress(imtypes,/rem) eq 'OBJECT' and strcompress(objects,/rem) ne 'OBJECT')
	
	if obj_inds[0] eq -1 then begin
		print, 'Warning! No object files found!'
		return
	endif
	print, '	Found ',n_elements(obj_inds),' object frames.'
	;check if the dates are the same
	obj_dates=dates[obj_inds]
		obj_dates_full=full_dates[obj_inds]

		date_check=total( where( obj_dates ne obj_dates[0] ) )

	print, '	Date of first exposure: ',obj_dates[0]
	print, '	Date of last exposure: ',obj_dates[n_elements(obj_inds)-1]

	if date_check gt 0 then begin
		print, '	Object dates differ!!!'
		;print, obj_dates
		print, '	If dates are only different because the observation went through midnight then proceed, otherwise manually separate the files and re-run this script.'
		;hak
	endif
	
		obj_files=files[obj_inds]

	
	obj_exptimes=exptimes[obj_inds]
		exp_check=total( where( obj_exptimes ne obj_exptimes[0] ) )
		
	if exp_check gt 0 then begin
		print, 'Object exposure times differ. Check input files'
		;print, obj_dates
		
		print, obj_exptimes
		
		print, 'Continuing with most prevalent exposure:'
	
		distfreq = Histogram(obj_exptimes, MIN=Min(obj_exptimes))
  		 maxfreq= Max(distfreq)
   		mode = (Where(distfreq EQ maxfreq) + Min(obj_exptimes))
   	
   		
   		obj_exptimes=obj_exptimes[where(obj_exptimes eq mode[0])]
   		obj_dates=obj_dates[where(obj_exptimes eq mode[0])]
   		obj_files=obj_files[where(obj_exptimes eq mode[0])]
		obj_dates_full=obj_dates_full[where(obj_exptimes eq mode[0])]
		;hak
		
		obj_exptime=mode[0]
		
	endif else obj_exptime=obj_exptimes[0]
	
	print, '	Object exposure times = ',obj_exptime
	
	
;-----------------------------------------------------------------------------------------


print, 'Step 8: Collecting star center files...'

	cen_inds=where(strcompress(imtypes,/rem) eq 'OBJECT,CENTER' )
	if cen_inds[0] eq -1 then begin
		print, 'Warning! No star center files found!'
		return
	endif
	print, '	Found ',n_elements(cen_inds),' center frames.'
	;check if the dates are the same
	cen_dates=dates[cen_inds]
		cen_dates_full=full_dates[cen_inds]

		date_check=total( where( cen_dates ne cen_dates[0] ) )

	print, '	Date of first exposure: ',cen_dates[0]
	print, '	Date of last exposure: ',cen_dates[n_elements(cen_inds)-1]

	if date_check gt 0 then begin
		print, '	Center dates differ!!!'
		;print, cen_dates
		print, '	If dates are only different because the observation went through midnight then proceed, otherwise manually separate the files and re-run this script.'
		if not keyword_set(no_interupt) then hak
	endif
	
	cen_exptimes=exptimes[cen_inds]
		exp_check=total( where( cen_exptimes ne cen_exptimes[0] ) )
		
	cen_files=files[cen_inds]

		
	if exp_check gt 0 then begin
		print, 'Star center exposure times differ. Check input files'
		;print, cen_dates
		
		
		print, cen_exptimes
		
		print, 'Continuing with most prevalent exposure:'
	
		distfreq = Histogram(cen_exptimes, MIN=Min(cen_exptimes))
  		 maxfreq= Max(distfreq)
   		mode =Where(distfreq EQ maxfreq) + Min(cen_exptimes)
   		Print, mode[0]
   		
   		cen_exptimes=cen_exptimes[where(cen_exptimes eq mode[0])]
   		cen_dates=cen_dates[where(cen_exptimes eq mode[0])]
   		cen_files=cen_files[where(cen_exptimes eq mode[0])]
		cen_dates_full=cen_dates_full[where(cen_exptimes eq mode[0])]
		;hak
		
		cen_exptime=mode[0]
		
		
		;hak
	endif else cen_exptime=cen_exptimes[0]
	
	print, '	Star center exposure times = ',cen_exptime
	
		
;-----------------------------------------------------------------------------------------

		
print, 'Step 9: Collecting flux calibration files...'


	flux_inds=where(strcompress(imtypes,/rem) eq 'OBJECT,FLUX' )
	if flux_inds[0] eq -1 then begin
		print, 'Warning! No flux files found!'
		return
	endif

print, '	Found ',n_elements(flux_inds),' flux calibration frames.'
	;check if the dates are the same
	flux_dates=dates[flux_inds]
	flux_dates_full=full_dates[flux_inds]
		date_check=total( where( flux_dates ne flux_dates[0] ) )

	print, '	Date of first exposure: ',flux_dates[0]
	print, '	Date of last exposure: ',flux_dates[n_elements(flux_inds)-1]

	if date_check gt 0 then begin
		print, '	Flux calibration dates differ!!!'
		;print, flux_dates
		print, '	If dates are only different because the observation went through midnight then proceed, otherwise manually separate the files and re-run this script.'
		;hak
	endif
	
	flux_exptimes=exptimes[flux_inds]
		exp_check=total( where( flux_exptimes ne flux_exptimes[0] ) )
		
		
	flux_files=files[flux_inds]
	
		
	if exp_check gt 0 then begin
		print, 'Flux calibration exposure times differ. Check input files'
		;print, flux_dates
		print, flux_exptimes
		
		print, 'Continuing with most prevalent exposure:'
	
		distfreq = Histogram(flux_exptimes, MIN=Min(flux_exptimes))
  		 maxfreq= Max(distfreq)
   		mode =Where(distfreq EQ maxfreq) + Min(flux_exptimes)
   		Print, mode[0]
   		
   		flux_exptimes=flux_exptimes[where(flux_exptimes eq mode[0])]
   		flux_dates=flux_dates[where(flux_exptimes eq mode[0])]
   		flux_files=flux_files[where(flux_exptimes eq mode[0])]
		flux_dates_full=flux_dates_full[where(flux_exptimes eq mode[0])]
		;hak
		
		flux_exptime=mode[0]
		
	endif else flux_exptime=flux_exptimes[0]
	
	print, '	Flux calibration exposure times = ',flux_exptime

	
;-----------------------------------------------------------------------------------------


print, 'Step 10: Collecting dark frames...'
	dark_inds=where(strcompress(imtypes,/rem) eq 'DARK' )


	if dark_inds[0] eq -1 then begin
		print, 'Warning! No dark files found!'
		return
	endif

	print, '	Found ',n_elements(dark_inds),' dark frames.'
	
	

	dark_dates=dates[dark_inds]
	dark_exptimes=exptimes[dark_inds]
	print, '	Darks are from dates: ',dark_dates
	print, '	With exposure times :', dark_exptimes
	
	dark_files=files[dark_inds]


	
	;bad pixels will be handled later in a very low, but very precise frame-by-frame step
	;need to find exposure times of star center frames, flux calibration frames, and object frames
	
	;print, obj_exptime
	;print, dark_exptimes
	;print, where(float(dark_exptimes) eq float(obj_exptime))
	obj_darks=dark_files[where(float(dark_exptimes) eq float(obj_exptime))]
	
	
	print, 'Found ',n_elements(obj_darks),' object darks.'
	print, obj_darks
	cen_darks=dark_files[where(dark_exptimes eq cen_exptime)]
	print, 'Found ',n_elements(cen_darks),' center darks.'
	print, cen_darks
	flux_darks=dark_files[where(dark_exptimes eq flux_exptime)]
	print, 'Found ',n_elements(flux_darks),' flux darks.'
	print, flux_darks
	
	
	obj_dark_date=dark_dates[where(dark_exptimes eq obj_exptime)]
	cen_dark_date=dark_dates[where(dark_exptimes eq cen_exptime)]
	flux_dark_date=dark_dates[where(dark_exptimes eq flux_exptime)]
	
	;limiting to dates that were actually observed
	
	if n_elements(where(dark_dates eq obj_dates and dark_exptimes eq obj_exptime)) gt 1 then begin 
		obj_darks=dark_files[where(dark_dates eq obj_dates and dark_exptimes eq obj_exptime)]
		print, 'Using object dark from date of observation only.'
		obj_dark_date=dark_dates[where(dark_dates eq obj_dates and dark_exptimes eq obj_exptime)]
		endif
		
		if n_elements(where(dark_dates eq flux_dates and dark_exptimes eq flux_exptime)) gt 1 then begin 
		flux_darks=dark_files[where(dark_dates eq flux_dates and dark_exptimes eq flux_exptime)]
		print, 'Using flux dark from date of observation only.'
		flux_dark_date=dark_dates[where(dark_dates eq flux_dates and dark_exptimes eq flux_exptime)]
		endif
		
if n_elements(where(dark_dates eq cen_dates and dark_exptimes eq cen_exptime)) gt 1 then begin 
		cen_darks=dark_files[where(dark_dates eq cen_dates and dark_exptimes eq cen_exptime)]
		
		cen_dark_date=dark_dates[where(dark_dates eq cen_dates and dark_exptimes eq cen_exptime)]
		print, 'Using center dark from date of observation only.'
		endif
		

	
	if n_elements(obj_darks) le 0 or  n_elements(cen_darks) le 0 or n_elements(flux_darks) le 0 then begin
		print, 'Dark files not found for object, flux, and center sequences! Halting sequence.'
		return
	endif

print, size(obj_dark_date)

if n_elements( size(obj_dark_date) ) ge 4 then obj_dark_date=obj_dark_date[0]
if n_elements( size(cen_dark_date) ) ge 4 then cen_dark_date=cen_dark_date[0]
if n_elements( size(flux_dark_date) ) ge 4 then flux_dark_date=flux_dark_date[0]	

print, obj_dates[0], obj_dark_date[0]

	if obj_dark_date ne obj_dates[0] or cen_dark_date ne obj_dates[0] or flux_dark_date ne obj_dates[0] then 	print, 'Warning - Science sequence date does not correspond to date of calibration files. Proceeding anyways, but consider using the calibration files from the correct date, if they exist.'
	
	
;-----------------------------------------------------------------------------------------


;begin copy space

	for ii=0, n_elements(obj_darks)-1 do begin
	print, obj_darks
		frame=readfits(obj_darks[ii],hdr,/silent)
		if ii eq 0 then obj_dark_cube=frame else obj_dark_cube=[ [[obj_dark_cube]], [[frame]] ]		
	endfor
	
if n_elements(size(obj_dark_cube)) gt 5 then begin
	print, 'More than one object dark frame found... combining.'

	if dark_comb_imtype eq 'median' then begin
		if (size(obj_dark_cube))(3) mod 2 eq 0 then obj_dark=median(obj_dark_cube,dim=3,/even) else obj_dark=median(obj_dark_cube,dim=3)
	
	endif
	
	if dark_comb_imtype eq 'mean' then obj_dark=mean(obj_dark_cube,dim=3)
endif else obj_dark=obj_dark_cube

print, 'Writing calibration file...'

writefits,input_directory+'IRDIS/calib/obj_dark.fits',obj_dark,hdr
writefits,input_directory+'IRDIS/calib/obj_dark-prebad.fits',obj_dark,hdr

;end copy space

for ii=0, n_elements(cen_darks)-1 do begin
		frame=readfits(cen_darks[ii],hdr,/silent)
		if ii eq 0 then cen_dark_cube=frame else cen_dark_cube=[ [[cen_dark_cube]], [[frame]] ]		
	endfor
	
	
if n_elements(size(cen_dark_cube)) gt 5 then begin
	print, 'More than one star center dark frame found... combining.'
	if dark_comb_imtype eq 'median' then begin
		if (size(cen_dark_cube))(3) mod 2 eq 0 then cen_dark=median(cen_dark_cube,dim=3,/even) else cen_dark=median(cen_dark_cube,dim=3)
	
	endif
	
	if dark_comb_imtype eq 'mean' then cen_dark=mean(cen_dark_cube,dim=3)
endif else cen_dark=cen_dark_cube

print, 'Writing calibration file...'

writefits,input_directory+'IRDIS/calib/cen_dark.fits',cen_dark,hdr
writefits,input_directory+'IRDIS/calib/cen_dark-prebad.fits',cen_dark,hdr

for ii=0, n_elements(flux_darks)-1 do begin
		frame=readfits(flux_darks[ii],hdr,/silent)
		if ii eq 0 then flux_dark_cube=frame else flux_dark_cube=[ [[flux_dark_cube]], [[frame]] ]		
	endfor
	
if n_elements(size(flux_dark_cube)) gt 5 then begin
	print, 'More than one flux calibration dark frame found... combining.'

	if dark_comb_imtype eq 'median' then begin
		if (size(flux_dark_cube))(3) mod 2 eq 0 then flux_dark=median(flux_dark_cube,dim=3,/even) else flux_dark=median(flux_dark_cube,dim=3)
	
	endif
	
	if dark_comb_imtype eq 'mean' then flux_dark=mean(flux_dark_cube,dim=3)
endif else flux_dark=flux_dark_cube

print, 'Writing calibration file...'

writefits,input_directory+'IRDIS/calib/flux_dark.fits',flux_dark,hdr
writefits,input_directory+'IRDIS/calib/flux_dark-prebad.fits',flux_dark,hdr


;-----------------------------------------------------------------------------------------



if remove_bads then begin

;print, 'Step 10a: Correcting bad pixels in dark frame...'



badmap=readfits(badmap_loc)



if find_bads then begin


;badmap[*]=1
badsig=3.
cs=3
smallcube=obj_dark;readfits(cen_files[0])

;filter cube
;if n_elements(size(smallcube)) gt 5 then for iii=0,(size(smallcube))(3)-1 do smallcube[*,*,iii]=smallcube[iii]-smooth(smallcube[*,*,iii],5.) else smallcube=smallcube-smooth(smallcube,5.) 

 print, 'Step 10a... Finding bad pixels... may take a while....'
  for ix=cs, (size(badmap))(1)-1-cs do begin
     for iy=cs, (size(badmap))(2)-1-cs do begin
           box = smallcube[ix-cs:ix+cs,iy-cs:iy+cs,*]
           this =  box[cs,cs,*]  ; this pixel

         ; if mean(this) gt 50 or mean(this) lt -10 then badmap[ix,iy]=0
                     if mean(this) gt bad_thresh or mean(this) lt neg_bad_thresh then badmap[ix,iy]=0

           box[cs,cs,*] = !values.f_nan
           box[cs-1,cs+1,*] = !values.f_nan
           box[cs-1,cs,*] = !values.f_nan
           box[cs-1,cs-1,*] = !values.f_nan
           
           box[cs+1,cs-1,*] = !values.f_nan
           box[cs+1,cs,*] = !values.f_nan
           box[cs+1,cs+1,*] = !values.f_nan
           
           box[cs,cs+1,*] = !values.f_nan
           box[cs,cs-1,*] = !values.f_nan



           if mean(this) gt (mean(box,/nan)+badsig*stddev(box,/nan)) or mean(this) lt (mean(box,/nan)-badsig*stddev(box,/nan)) then badmap[ix,iy] = 0 

        endfor
   ;  print, ' Left Column : ', ix
     endfor
     
     ;repeat for negative (dead) pixels on a frame with some actual light
     if 1 eq 1 then begin
     smallcube=readfits(obj_files[0])
    print, 'Step 10aa... Finding dead pixels... may take a minute....'
    for ix=cs, (size(badmap))(1)-1-cs do begin
     for iy=cs, (size(badmap))(2)-1-cs do begin
           box = smallcube[ix-cs:ix+cs,iy-cs:iy+cs,0]
           this =  box[cs,cs]  ; this pixel

         ; if mean(this) gt 50 or mean(this) lt -10 then badmap[ix,iy]=0
                     if  this lt 0 then badmap[ix,iy]=0

			
           box[cs,cs,*] = !values.f_nan
           box[cs-1,cs+1,*] = !values.f_nan
           box[cs-1,cs,*] = !values.f_nan
           box[cs-1,cs-1,*] = !values.f_nan
           
           box[cs+1,cs-1,*] = !values.f_nan
           box[cs+1,cs,*] = !values.f_nan
           box[cs+1,cs+1,*] = !values.f_nan
           
           box[cs,cs+1,*] = !values.f_nan
           box[cs,cs-1,*] = !values.f_nan

           if mean(this) lt (mean(box,/nan)-badsig*stddev(box,/nan)) then badmap[ix,iy] = 0 

        endfor
   ;  print, ' Left Column : ', ix
     endfor  
     endif
 
endif ;find_bads  

writefits,strcompress(input_directory+'IRDIS/calib/bad_pixel_mask.fits',/rem),badmap


	
;-----------------------------------------------------------------------------------------



print, 'Step 10b: Removing bad pixels from flux dark.'
remove_bad_pixels, badmap,input_directory+'IRDIS/calib/flux_dark.fits';flux_dark
print, 'Step 10b: Removing bad pixels from object dark.'
remove_bad_pixels, badmap,input_directory+'IRDIS/calib/obj_dark.fits';obj_dark
print, 'Step 10b: Removing bad pixels from center dark.'
remove_bad_pixels, badmap,input_directory+'IRDIS/calib/cen_dark.fits';cen_dark

flux_dark=readfits(input_directory+'IRDIS/calib/flux_dark.fits')
obj_dark=readfits(input_directory+'IRDIS/calib/obj_dark.fits')
cen_dark=readfits(input_directory+'IRDIS/calib/cen_dark.fits')


endif ;remove bads if

;ERROR: the above lines are broken, need to send it to the paths instead

;-----------------------------------------------------------------------------------------


if sub_dark then print, 'Step 11: Subtracting dark current from object files...'


	
	for ii=0, n_elements(obj_files)-1 do begin
		frame=readfits(obj_files[ii],hdr,/silent)
		if n_elements(size(frame)) gt 5 then begin $
			if sub_dark then for jj=0, (size(frame))(3)-1 do frame[*,*,jj]=frame[*,*,jj]-obj_dark & $
			endif else frame=frame-obj_dark
		writefits,strcompress(input_directory+'IRDIS/products/'+'IRDIS_OBJECT_'+string(obj_dates_full[ii])+'_.fits',/rem),frame,hdr
	endfor
	
;-----------------------------------------------------------------------------------------

	
if sub_dark then print, 'Step 12: Subtracting dark current from star center files...'
	
	
	for ii=0, n_elements(cen_files)-1 do begin
		frame=readfits(cen_files[ii],hdr,/silent)
		if n_elements(size(frame)) gt 5 then begin $
			if sub_dark then for jj=0, (size(frame))(3)-1 do frame[*,*,jj]=frame[*,*,jj]-cen_dark ; $
			endif else frame=frame-cen_dark
		writefits,strcompress(input_directory+'IRDIS/center/'+'IRDIS_CENTER_'+string(cen_dates_full[ii])+'_.fits',/rem),frame,hdr
	endfor
	
;-----------------------------------------------------------------------------------------


if sub_dark then print, 'Step 13: Subtracting dark current from flux calibration files...'
	

	
	for ii=0, n_elements(flux_files)-1 do begin
		frame=readfits(flux_files[ii],hdr,/silent)
		if n_elements(size(frame)) gt 5 then begin $
			if sub_dark then for jj=0, (size(frame))(3)-1 do frame[*,*,jj]=frame[*,*,jj]-flux_dark; & $
			endif else frame=frame-flux_dark
		writefits,strcompress(input_directory+'IRDIS/flux/'+'IRDIS_FLUX_'+string(flux_dates_full[ii])+'_.fits',/rem),frame,hdr
	endfor
	
;-----------------------------------------------------------------------------------------

	
print, 'Step 14: Collecting flat frames...'
	flat_inds=where(strcompress(imtypes,/rem) eq 'FLAT,LAMP' )
	print, '	Found ',n_elements(flat_inds),' flat frames.'
	flat_dates=dates[flat_inds]
	flat_exptimes=exptimes[flat_inds]
	print, '	Flats are from dates: ',flat_dates
	print, '	With exposure times :', flat_exptimes
	
	flat_files=files[flat_inds]
	
	;bad pixels will be handled later in a very low, but very precise frame-by-frame step
	;need to find exposure times of star center frames, flux calibration frames, and object frames
	
	;perform a fit to the response of each pixel to light:
	
	;skipping flat fielding for now...
	
	print, 'Skipping flat fielding... Account for flat field variations in final uncertainty.'
	

;-----------------------------------------------------------------------------------------

if remove_bads  then begin


print, 'Step 16: Removing bad pixels from flux calibration data.'
remove_bad_pixels, badmap,strcompress(input_directory+'IRDIS/flux/',/rem)

;-----------------------------------------------------------------------------------------


print, 'Step 17: Removing bad pixels from star center data.'
remove_bad_pixels, badmap,strcompress(input_directory+'IRDIS/center/',/rem)

;-----------------------------------------------------------------------------------------


print, 'Step 18: Removing bad pixels from object data.'
remove_bad_pixels, badmap,strcompress(input_directory+'IRDIS/products/',/rem)

endif else print, 'Skipping bad pixel correction.'	

;-----------------------------------------------------------------------------------------


print, 'Step 19: Splitting left and right.'

;leftmask=readfits('/media/kevin/Storage/Data/VLT/SPHERE/calib/irdis_left_mask.fits')
;rightmask=readfits('/media/kevin/Storage/Data/VLT/SPHERE/calib/irdis_right_mask.fits')

	files=file_search(input_directory+'IRDIS/flux/','*_.fits',count=cnt)
	for ii=0,cnt-1 do begin
		frame=readfits(files[ii],hdr,/silent)
		if n_elements(size(frame)) gt 5 then left = frame[0:1023,*,*] else left=frame[0:1023,*]
		if n_elements(size(frame)) gt 5 then right = frame[1024:2047,*,*] else right=frame[1024:2047,*]
		
		writefits,strcompress(input_directory+'IRDIS/flux/'+'IRDIS_FLUX_'+string(flux_dates_full[ii])+'_left.fits',/rem),left,hdr
							writefits,strcompress(input_directory+'IRDIS/flux/'+'IRDIS_FLUX_'+string(flux_dates_full[ii])+'_right.fits',/rem),right,hdr
							
							

	endfor
	
	file_delete,files
	
	files=file_search(input_directory+'IRDIS/center/','*_.fits',count=cnt)
	for ii=0,cnt-1 do begin
		frame=readfits(files[ii],hdr,/silent)
		if n_elements(size(frame)) gt 5 then left = frame[0:1023,*,*] else left=frame[0:1023,*]
		if n_elements(size(frame)) gt 5 then right = frame[1024:2047,*,*] else right=frame[1024:2047,*]
		writefits,strcompress(input_directory+'IRDIS/center/'+'IRDIS_CENTER_'+string(cen_dates_full[ii])+'_left.fits',/rem),left,hdr
							writefits,strcompress(input_directory+'IRDIS/center/'+'IRDIS_CENTER_'+string(cen_dates_full[ii])+'_right.fits',/rem),right,hdr

	endfor
	
		file_delete,files

	
	files=file_search(input_directory+'IRDIS/products/','*_.fits',count=cnt)
	for ii=0,cnt-1 do begin
		frame=readfits(files[ii],hdr,/silent)
		if n_elements(size(frame)) gt 5 then left = frame[0:1023,*,*] else left=frame[0:1023,*]
		if n_elements(size(frame)) gt 5 then right = frame[1024:2047,*,*] else right=frame[1024:2047,*]
		writefits,strcompress(input_directory+'IRDIS/products/'+'IRDIS_OBJECT_'+string(obj_dates_full[ii])+'_left.fits',/rem),left,hdr
							writefits,strcompress(input_directory+'IRDIS/products/'+'IRDIS_OBJECT_'+string(obj_dates_full[ii])+'_right.fits',/rem),right,hdr

	endfor
	
		file_delete,files

endif ;ifs_only if

endif ;skip initial steps if

;-----------------------------------------------------------------------------------------

cgcleanup



if  keyword_set(inject) then begin proc_orig = 0 & proc_inj=1 & endif else begin $
				   proc_orig = 1 & proc_inj=0 & endelse

;if neither keyword is set then process the original data only
if not keyword_set(proc_inj) and not keyword_set(proc_orig) then proc_orig=1

if post_process_irdis then begin

if keyword_set(klip) then begin

if keyword_set(suffix) then begin
	if skip_start then begin
	print, 'Running reduce_irdis.pro with injections'

	if proc_inj then begin	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,/skip_start,suffix=suffix,/klip else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,/skip_start,suffix=suffix,/klip 
	endif

	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen,/skip_start,suffix=suffix,/klip  else $
		reduce_irdis,object_name,reduction_path=reduction_path, /skip_start,suffix=suffix,/klip 
	endif	
	endif else begin


	if proc_inj then begin
	print, 'Running reduce_irdis.pro with injections'	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,suffix=suffix,/klip  else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,suffix=suffix,/klip 
	endif
	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen,suffix=suffix,/klip  else $
		reduce_irdis,object_name,reduction_path=reduction_path,suffix=suffix,/klip 
	endif
	endelse	

endif else begin

	if skip_start then begin
	if proc_inj then begin
	print, 'Running reduce_irdis.pro with injections'	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,/skip_start ,/klip else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,/skip_start,/klip 
	endif
	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen,/skip_start,/klip  else $
		reduce_irdis,object_name,reduction_path=reduction_path, /skip_start,/klip 
	endif
	endif else begin

	if proc_inj then begin
	print, 'Running reduce_irdis.pro with injections'	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,/klip  else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,/klip 
	endif
	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen, /klip  else $
		reduce_irdis,object_name,reduction_path=reduction_path,/klip 
	endif
	endelse	

endelse	

endif else begin

if keyword_set(suffix) then begin
	if skip_start then begin
	print, 'Running reduce_irdis.pro with injections'

	if proc_inj then begin	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,/skip_start,suffix=suffix else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,/skip_start,suffix=suffix
	endif

	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen,/skip_start,suffix=suffix else $
		reduce_irdis,object_name,reduction_path=reduction_path, /skip_start,suffix=suffix
	endif	
	endif else begin


	if proc_inj then begin
	print, 'Running reduce_irdis.pro with injections'	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,suffix=suffix else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,suffix=suffix
	endif
	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen, suffix=suffix else $
		reduce_irdis,object_name,reduction_path=reduction_path,suffix=suffix
	endif
	endelse	

endif else begin

	if skip_start then begin
	if proc_inj then begin
	print, 'Running reduce_irdis.pro with injections'	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen,/skip_start else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj,/skip_start
	endif
	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen,/skip_start else $
		reduce_irdis,object_name,reduction_path=reduction_path, /skip_start
	endif
	endif else begin

	if proc_inj then begin
	print, 'Running reduce_irdis.pro with injections'	
	if auto_cen then reduce_irdis,object_name,reduction_path=reduction_path, /inj,/autocen else $
		 reduce_irdis,object_name,reduction_path=reduction_path, /inj
	endif
	if proc_orig then begin
	print, 'Running reduce_irdis.pro '	
	if auto_cen then  reduce_irdis,object_name,reduction_path=reduction_path, /autocen else $
		reduce_irdis,object_name,reduction_path=reduction_path
	endif
	endelse	

endelse	

endelse
	
endif



;-----------------------------------------------------------------------------------------

if reduce_irdis_sizes and not skip_start then begin
	print, 'Zipping raw data and deleting old files - may take a minute...'
	file_zip, input_directory+'IRDIS/raw/', input_directory+'IRDIS/raw.zip'
	file_delete,input_directory+'IRDIS/raw/',/recursive
	print, 'Deleting intermediate data products...'
	file_delete,input_directory+'IRDIS/products/',/recursive
	print, 'Done.'	
endif else print, 'Skipping file size reduction...'
;-----------------------------------------------------------------------------------------



if process_ifs then begin

if not skip_start then begin

print, 'Starting IFS reduction...'
;-----------------------------------------------------------------------------------------
;  IFS data is currently just split on the basis of whether or not it has the IFS tag. There
;  are probably too many files for the data_reduction_ifs.sh script to know what to do with.
;  Thus, first step of this script is to sort the files further, keeping only the calibrations
;  with the correct dates, etc. similar to the IRDIS method above. 	
;-----------------------------------------------------------------------------------------



ROOT=strcompress('/media/kevin/Storage/Data/VLT/SPHERE/'+object_name+'/IFS/',/rem)
;MODE='YJH'



;first need to read in the raw IFS files and separate them into raw and raw-extra


print, 'Searching for .fits files... Done.'
	files=file_search(input_directory+'IFS/raw/','*.fits',count=cnt)	;first search for compressed files
	if cnt lt 1 then begin
	print, 'Searching for zip files... Done.'
	files=file_search(input_directory+'IFS/raw.zip',count=cnt)	;first search for compressed files
	if cnt ge 1 then print, 'Unzipping...'	
	if cnt ge 1 then file_unzip,files
	files=file_search(input_directory+'IFS/raw/','*.fits',count=cnt)	;first search for compressed files
	endif

	
print, '	Found ', cnt, ' fits files.'


;-----------------------------------------------------------------------------------------


print, 'Looping through fits headers and sorting files...'
for ii=0, cnt-1 do begin
	frame=readfits(files[ii],hdr,/silent)
	
	
	detector=''
	imtype=''
	date=''
	exptime=''
	ndit=''
	dbfilt=''
	ndfilt=''
	
	;extracting info...
	;want to know what detector, imtype, date, DIT, ND filter, DB filter
	detector=string(esopar(hdr,'HIERARCH ESO DET NAME '))
	imtype=esopar(hdr,'HIERARCH ESO DPR TYPE ')
	imcomb=string(esopar(hdr,'HIERARCH ESO INS2 COMB IFS '))
	date=fxpar(hdr,'DATE')
	object=string(fxpar(hdr,'OBJECT'))
	date_full=date
	date=strmid(date,0,10)	;only keep YYYY-MM-DD
	exptime=fxpar(hdr,'EXPTIME')
	ndit=esopar(hdr,'HIERARCH ESO DET NDIT ')
	dbfilt=esopar(hdr,'ESO INS1 OPTI2 NAME ')
	ndfilt = esopar(hdr,'ESO INS4 COMB IND')
	if isa(ndfilt, /string) eq 0 then ndfilt = esopar(hdr,'ESO INS4 FILT2 NAME')  

	if ii eq 0 then begin
		detectors=detector
		dates=date
		full_dates=date_full
		imtypes=imtype
		imcombs=imcomb
		exptimes=exptime
		ndfilts=ndfilt
		dbfilts=dbfilt
		ndits=ndit
		objects=object
	endif else begin
		detectors=[detectors,detector]
		dates=[dates,date]
		imtypes=[imtypes,imtype]
		imcombs=[imcombs,imcomb]
		exptimes=[exptimes,exptime]
		ndfilts=[ndfilts,ndfilt]
		dbfilts=[dbfilts,dbfilt]
		ndits=[ndits,ndit]
		full_dates=[full_dates,date_full]
		objects=[objects,object]
	endelse

	if speaking then begin
		print, strcompress('	Frame '+string(ii)+':')
		print, '	Date       = ',date
		print, '	Object     = ',object
		print, '	Detector   = ',detector
		print, '	Frame imtype = ',imtype
		print, '	Frame imcomb = ',imcomb
		print, '	Exptime    = ',exptime
		print, '	NDITs    = ',ndit
		print, '	ND filter  = ',ndfilt
		print, '	DB Filter  = ',dbfilt
	endif
endfor
print, '	Done.'


if n_elements(where( strcompress(imcombs,/rem) eq 'OBS_YJ' )) gt 1 then yj=1 else yj=0


if yj then mode='YJ' else mode='YJH'

;separating dates into other forms
	yyyys=strmid(dates,0,4)
	mms=strmid(dates,5,2)
	dds=strmid(dates,9,2)

;script will fail if it encounters more than two flats, so here we choose to keep only the first two and move the rest
;can make this more intelligent by selecting based on dates instead

white_flats=where(imcombs eq strcompress('CAL_BB_2_'+mode,/rem))
print, files[white_flats]
print, n_elements(white_flats)

if n_elements(white_flats) gt 2 then file_move, files[white_flats[2:n_elements(white_flats)-1]], input_directory+'IFS/extra/'


nb1_flats=where(imcombs eq strcompress('CAL_NB1_1_'+mode,/rem))
print, files[nb1_flats]
print, n_elements(nb1_flats)

if n_elements(nb1_flats) gt 2 then file_move, files[nb1_flats[2:n_elements(nb1_flats)-1]], input_directory+'IFS/extra/'

nb2_flats=where(imcombs eq strcompress('CAL_NB2_1_'+mode,/rem))
print, files[nb2_flats]
print, n_elements(nb2_flats)

if n_elements(nb2_flats) gt 2 then file_move, files[nb2_flats[2:n_elements(nb2_flats)-1]], input_directory+'IFS/extra/'

nb3_flats=where(imcombs eq strcompress('CAL_NB3_1_'+mode,/rem))
print, files[nb3_flats]
print, n_elements(nb3_flats)

if n_elements(nb3_flats) gt 2 then file_move, files[nb3_flats[2:n_elements(nb3_flats)-1]], input_directory+'IFS/extra/'


nb4_flats=where(imcombs eq strcompress('CAL_NB4_2_'+mode,/rem))
print, files[nb4_flats]
print, n_elements(nb4_flats)

if n_elements(nb4_flats) gt 2 then file_move, files[nb4_flats[2:n_elements(nb4_flats)-1]], input_directory+'IFS/extra/'

specpos=where(imtypes eq strcompress('SPECPOS,LAMP',/rem))
print, files[specpos]
print, n_elements(specpos)

if n_elements(specpos) ge 2 then file_move, files[specpos[1:n_elements(specpos)-1]], input_directory+'IFS/extra/'


wavcals=where(imtypes eq strcompress('WAVE,LAMP',/rem))
print, files[wavcals]
print, n_elements(wavcals)

if n_elements(wavcals) ge 2 then file_move, files[wavcals[1:n_elements(wavcals)-1]], input_directory+'IFS/extra/'

save,filename=input_directory+'IFS/products/mode.sav',mode, yj

print, 'Running command: ./idl/sphere-tools/SPHERE-legacy-master/ifs_reduction/data_reduction_ifs_new.sh '+ root+' '+mode
spawn,'./idl/sphere-tools/SPHERE-legacy-master/ifs_reduction/data_reduction_ifs_new.sh '+root+' '+ mode

;hak
;finishing pre-processing
data_reduction_ifs1, root

;clean display
cgcleanup

endif ;skip_start if

restore,filename=input_directory+'IFS/products/mode.sav'

;PSF subtraction and final processing with fake planet injections
if proc_inj and yj then reduce_ifs,object_name,/inj,/yj,reduction_path=reduction_path
if proc_inj and not yj then reduce_ifs,object_name,/inj,reduction_path=reduction_path

;PSF subtraction and final processing
if proc_orig and yj then reduce_ifs,object_name,/yj,reduction_path=reduction_path
if proc_orig and not yj then reduce_ifs,object_name,reduction_path=reduction_path


if reduce_ifs_sizes and not skip_start then begin
	print, 'Zipping raw data and deleting old files - may take a minute...'
	file_zip, input_directory+'IFS/raw/', input_directory+'IFS/raw.zip'
	file_delete,input_directory+'IFS/raw/',/recursive
	file_zip, input_directory+'IFS/extra/', input_directory+'IFS/extra.zip'
	file_delete,input_directory+'IFS/extra/',/recursive
	print, 'Deleting intermediate data products...'
	file_delete,input_directory+'IFS/interm/',$
		input_directory+'IFS/calib/',/recursive

	preproc_files=file_search(input_directory+'IFS/products/','*.fits',count=cnt)
	for ii=0,cnt-1 do if strpos(preproc_files[ii],'preproc') ne -1 then file_delete,preproc_files[ii]
	file_delete,input_directory+'IFS/spectra_positions_distortion.fits'
	file_delete,input_directory+'IFS/ifs_instrument_flat.fits'
	file_delete,input_directory+'IFS/ifs_science_dr.fits'	
	file_delete,input_directory+'IFS/input_image2.fits'
	file_delete,input_directory+'IFS/input_image_row.fits'
	file_delete,input_directory+'IFS/esorex.log'
print, 'Done.'	
endif else print, 'Skipping file size reduction...'



endif ;process_ifs if

print, 'Completed SPHERE reduction on ',object_name,' in ',(systime(/JULIAN)-starttime)*86400./60.,' minutes.'


if single then hak

cgcleanup

endfor


end
