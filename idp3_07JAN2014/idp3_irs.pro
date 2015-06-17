pro idp3_irs, info=info, fpm=fpm, addtopm=addtopm

; Enable access to SMART objects 
    
@smart_proj

case 1 of
keyword_set(fpm):begin
                 obj = obj_new('idp3_irs_fpm',info)
                 obj_destroy,obj
end

keyword_set(addtopm):begin
    print,'Call to the project manager'

; Rebin input data to 128 x 128

    data = *addtopm[0]
    dims = size(data, /dimensions)

    if((dims[0] eq 128) and (dims[1] eq 128)) then begin
    endif else begin

        test1 = dims[0] mod 128.0
        test2 = dims[1] mod 128.0

        if((test1 eq 0) and (test2 eq 0)) then begin
            data = rebin(data, 128, 128)
        endif else begin
            data = congrid(data, 128, 128)
        endelse

    endelse

; Get file name

    fileid = a95_sxpar(*addtopm(1), 'FILENAME')

; Assemble header

    test3 = ptr_valid(addtopm(2))
    if(test3 eq 1) then begin 
        header = [*addtopm(1), *addtopm(2)] 
    endif else begin
        header = *addtopm(1)
    endelse

; Build the output data record

    rec = {smart_dr,                               $
           id:fileid,                              $
           files:ptr_new('none'),                  $
           noise:ptr_new(fltarr(128, 128)),        $
           data:ptr_new(data),                     $
           bmask:ptr_new(fltarr(128, 128)),        $
           header:ptr_new(header),                 $
           stacked:'no',                           $
           stackid:0,                              $
           datatype:'IMAGE',                       $
           idea:ptr_new('none')                    $
          }

; Add data to Dataset Manager display

    if xregistered('pmw') then begin
        sel=widget_info(smp_wList,/LIST_SELECT)
        if sel eq -1 then dump=dialog_message('Please select a dataset',/info) else begin
        if not XRegistered('smartproj_show') then $
            (*smp_list)[sel[0]] -> Show
            (*smp_list)[sel[0]] -> Add, data_record=ptr_new(rec),/skip_preset_bcd
        endelse
        endif

        end
        else:print, 'Problem in idp3_irs'

endcase

end
