
pro Idp3_ReadRod, event

@idp3_structs
@idp3_errors

  Widget_Control, event.top, Get_UValue=info
  Widget_Control, info.idp3Window, Get_UValue=info

  filename = Dialog_Pickfile(/Read, /Must_Exist)
;  filename = strcompress(filename(0), /remove_all)
  filename = strtrim(filename(0), 2)

  ; Check to see if this image exists.
  temp = file_search (filename, Count = fcount)
  if (strlen(filename) gt 0 and fcount ne 0) then begin

    ; Read the image.
    ua_fits_read, filename, tempmask, temphead, /no_abort

    ; If there is already a pointed to mask, free it.
    if ptr_valid((*info.roi).rodmask) then ptr_free,(*info.roi).rodmask
    if ptr_valid((*info.roi).roddmask) then ptr_free,(*info.roi).roddmask

    ; Get the ROI information.
    x1 = (*info.roi).roixorig
    y1 = (*info.roi).roiyorig
    x2 = (*info.roi).roixend
    y2 = (*info.roi).roiyend
    zoom = (*info.roi).roizoom
    roixsize = (*info.roi).roixsize
    roiysize = (*info.roi).roiysize
    s = size(tempmask)
    maskxsize = s[1]
    maskysize = s[2]

    ; If the ROI and the mask we just read are different sizes,
    ; trim the mask or congrid it up to the size of the ROI.
    temp = ptr_new(intarr(max([roixsize,maskxsize]),max([roiysize,maskysize])))
    (*temp)[*,*] = 1
    temp2 = ptr_new(intarr(roixsize,roiysize))
    (*temp)[0:maskxsize-1,0:maskysize-1] = tempmask
    (*temp2) = (*temp)[0:roixsize-1,0:roiysize-1]
   
    (*info.roi).rodmask = ptr_new( $
	where(congrid((*temp2),abs(x2-x1)+1,abs(y2-y1)+1) eq 1))
    (*info.roi).roddmask = ptr_new(where((*temp2) eq 0))
    (*info.roi).rod = 1

    ptr_free,temp
    ptr_free,temp2

  endif else begin
    test = Dialog_Message("Sorry, couldn't find file "+filename)
  endelse

  ; Update graphics display.
  roi_display,info

  Widget_Control, event.top, Set_UValue=info
  Widget_Control, info.idp3Window, Set_UValue=info

end

