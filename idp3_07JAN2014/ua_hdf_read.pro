
FUNCTION HDFan2FITShdr,filename,found_header
;
; Reads a Transform Notebook annotation from a Transform HDF file
; and, if successful, returns a string array containing a UA FITS style header.
;
; If unsuccessful, returns an empty string array value of ['',''].
;
; Note: If the HDF file contains more than one annotation containing
; what appears to be a FITS header, only the first FITS header is returned.

found_header = 0

;
; Verify that the version of IDL is at least 5.2 (i.e. has annotation support).
IF !VERSION.RELEASE LT 5.2 THEN BEGIN
  Print,"IDL Version 5.2 or higher is required for HDF annotation support."
  old_version_of_IDL = ['','']
  RETURN, old_version_of_IDL
ENDIF
;

;
; Verify that caller supplied a filename and an output variable name.
IF n_params() LT 2 THEN BEGIN
  Print,"usage:  result = HDFan2FITShdr(filename,found_header)"
  Print,"   ARGUMENTS : filename : string name of a Transform HDF file"
  Print,"               found_header : equals 1 if a header was found"
  Print,"EXAMPLE:  FITS_header = HDFan2FITShdr('transform_output.hdf',found_h)"
  bad_call_syntax = ['','']
  RETURN, bad_call_syntax
ENDIF
;

; Verify that it is an HDF file.
IF HDF_ISHDF(filename) NE 1 THEN BEGIN
  Print,"File "+filename+" is not an HDF file."
  not_an_HDF_file = ['','']
  RETURN, not_an_HDF_file 
ENDIF

; Open the HDF file readonly.
  fileid=HDF_OPEN(filename,/READ)
;
; Search the file for AN annotations
;
  an_id=HDF_AN_START(fileid)
  result=HDF_AN_FILEINFO(an_id,n_file_labels,n_file_descs, $       
                               n_data_labels,n_data_descs)        
  max_str = 500
  notebook = StrArr(500)
  num_str = 0

  cards = -1
  FOR i=0,n_data_descs-1 DO BEGIN
    IF found_header EQ 0 THEN BEGIN
      ann_id=HDF_AN_SELECT(an_id,i,1)
      result=HDF_AN_READANN(ann_id,annotation)
      HDF_AN_ENDACCESS,ann_id
      oldpos = 0
      startpos = StrPos(annotation,'SIMPLE  =',oldpos)
      endpos = StrPos(annotation,'END               ',oldpos)
      IF ((startpos GE 0) AND (endpos GT 0)) THEN BEGIN
        len80 = 80
        len82 = 82
        maxcards = ((endpos - startpos) / len82) + 1
        oldpos = startpos
        not_finished = 1
        cards = 0
        WHILE not_finished EQ 1 DO BEGIN
          cardpos = oldpos
          new_card = StrMid(annotation,cardpos,len80)
          notebook[cards:cards] = new_card
          oldpos = cardpos + len82 
          cards = cards + 1
          IF cards GT maxcards THEN BEGIN
            new_card = StrMid(annotation,endpos,len80)
            notebook[cards:cards] = new_card
            cards = cards + 1
            found_header = 1
            not_finished = 0
          ENDIF
          IF oldpos GT (endpos - 80) THEN BEGIN
            new_card = StrMid(annotation,endpos,len80)
            notebook[cards:cards] = new_card
            cards = cards + 1
	    found_header = 1
            not_finished = 0
          ENDIF
        ENDWHILE
      ENDIF ELSE BEGIN
      ENDELSE
    ENDIF
  ENDFOR

  HDF_AN_END,an_id

  HDF_CLOSE,fileid

  IF found_header EQ 1 THEN BEGIN
    cardsm = cards - 1
    hdf_fits = notebook[0:cardsm]
    notebook = 0
    RETURN, hdf_fits
  ENDIF ELSE BEGIN
    no_FITS_header = ['','']
    notebook = 0
    RETURN, no_FITS_header
  ENDELSE

END
FUNCTION HDFsd2IDLimage,filename,found_image
;
; Reads a Transform two-dimensional image from a Transform HDF file
; and, if successful, returns a two-dimensional array containing that image.
;
; If, unsuccessful, returns an 2x2 array containing pixel values set to zero.
;
; Note: If the HDF file contains more than one two-dimensional SD image,
; only the first two-dimensional image is returned.
;

failure = IntArr(2,2)
failure[0,0] = 0
failure[1,0] = 0
failure[0,1] = 0
failure[1,1] = 0

found_image = 0

; Verify that the caller supplied a filename and an output variable name.
IF n_params() LT 2  THEN BEGIN
  Print,'usage:  result = HDFsd2IDLimage(filename,found_image)'
  Print,"   ARGUMENTS : filename : string name of HDF file"
  Print,"               found_image : equals 1 if an image was found"
  Print,"EXAMPLE:  image = HDFsd2IDLimage('hdf_data_only.hdf',found_image)"
  bad_call_syntax = failure
  RETURN, bad_call_syntax
ENDIF

; Verify that it is an HDF file.
IF HDF_ishdf(filename) NE 1 THEN BEGIN
  Print,"File "+filename+" is not an HDF file."
  not_an_HDF_file = failure
  RETURN, not_an_HDF_file
ENDIF

; Get the number of SDSs in the file

found = 0
sd_id=HDF_SD_START(filename,/read)
  HDF_SD_FILEINFO,sd_id,nmfsds,nglobatts

  IF nmfsds GT 0 THEN BEGIN 
    FOR i=0,nmfsds-1 DO BEGIN
      sds_id=HDF_SD_SELECT(sd_id,i)
        HDF_SD_GETINFO,sds_id,name=n,ndims=r,type=t,natts=nats,$
                       hdf_type=h,unit=u

        IF ((r EQ 2) AND (found EQ 0)) THEN BEGIN
          HDF_SD_GETDATA,sds_id,tempdata
          found = 1
        ENDIF

      HDF_SD_ENDACCESS,sds_id
    ENDFOR
  ENDIF
HDF_SD_END,sd_id

IF found EQ 1 THEN BEGIN
  found_image = 1
  RETURN, tempdata
ENDIF ELSE BEGIN
  found_image = 0
  no_image_found = failure
  RETURN, no_image_found
ENDELSE

END

PRO ua_HDF_read,filename,hdf_fits,hdf_image,found_header,found_image
;
; Attempts to read a Transform FITS header annotation 
; and an HDF SD two-dimensional image from an HDF file

;
;	Check for required number of input parameters
IF n_params() LT 5 THEN BEGIN
  Print,"usage:  HDF_read,filename,header,image,found_header,found_image "
  Print,"   ARGUMENTS : IN  : filename : string name of HDF file"
  Print,"               OUT : header : array of strings containing header"
  Print,"               OUT : image : two-dimensional array containing image"
  Print,"               OUT : found_header : equals 1 if header was found"
  Print,"               OUT : found_image : equals 1 if image was found"
  Print,"EXAMPLE:  HDF_read,'hdf_data_only.hdf',hdr,img,found_hdr,found_img "
  RETURN
ENDIF
;

Forward_Function hdfan2fitshdr
Forward_Function hdfsd2idlimage

hdf_fits = hdfan2fitshdr(filename,found_header)
hdf_image = hdfsd2idlimage(filename,found_image)

END
