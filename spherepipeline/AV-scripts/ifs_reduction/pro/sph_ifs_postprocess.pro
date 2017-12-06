;+
; NAME:
;
;  SPH_IFS_POSTPROCESS
;
; PURPOSE:
;
;  Performs the post-processing of SPHERE/IFS data.
;
; CALLING SEQUENCE:
;
;  Intended to be called from command line:
;
;    idl -e sph_ifs_postprocess -args ${SOF} 
;
; DESCRIPTION:
;
;  The main goal of this routine is to strip the (x,y,lambda) data
;  cubes produced by the DRH from the unused extensions. It does so by
;  reading the data using READFITS() and writing it back using
;  WRITEFITS.
;  
; INPUTS:
;
;  SOF - path to the SOF file
;
; OUTPUTS:
;
;  Original files stripped from unused extensions
;
; EXAMPLE:
;
;  If the original science SOF file for the DRH looks like this:
;  
;    /path/to/raw/data/SPHER.2015-01-01T00:00:00.000.fits       IFS_SCIENCE_DR_RAW
;    /path/to/raw/data/SPHER.2015-01-01T00:01:00.000.fits       IFS_SCIENCE_DR_RAW
;    /path/to/raw/data/SPHER.2015-01-01T00:02:00.000.fits       IFS_SCIENCE_DR_RAW
;    
;    /path/to/cal/data/master_detector_flat.fits             IFS_MASTER_DFF_LONGBB
;    /path/to/cal/data/some_badpixel_map.fits               IFS_STATIC_BADPIXELMAP
;    /path/to/cal/data/wave_cal.fits                                 IFS_WAVECALIB
;
;  Then the call sequence would be:
;
;   idl -e sph_ifs_postprocess -args science.sof
;
; MODIFICATION HISTORY:
;
;  arthur.vigan - 07/2017
;                 Code transitionned to GitHub for improved support
;                 
;  arthur.vigan - 08/2015 - commented for distribution
;
;  arthur.vigan - ??/2014 - original version
;
; AUTHOR:
; 
;   Arthur Vigan
;   Laboratoire d'Astrophysique de Marseille
;   arthur.vigan@lam.fr
;
; LICENSE:
;
;   This code is released under the MIT license.
;
;-

pro sph_ifs_postprocess
  cl_args = command_line_args(count=count)
  
  if (count ne 1) then begin
     message,string(count,format='("Unexpected number of arguments: ' + $
                    '",I0," instead of 1")'),/inform
     exit,status=1
  endif

  ;args = strsplit(cl_args,' ',/extract)
  args   = cl_args
  sof    = args[0]

  print,'Postprocessing of IFS data cubes:'
  print,' SOF FILE  = '+sof
  print
  
  ;; read SOF file
  readcol,sof,file,type,format='A,A',count=nfiles
  if (count eq 0) then begin
     message,'SOF file empty or not formated correctly',/inform
     exit,status=1
  endif

  ff = where(type eq 'IFS_SCIENCE_DR_RAW',nff)

  print,'SOF file content:'
  print,' * ',nff,' raw file(s)',format='(A0,I3,A0)'
  print
  
  ;; raw files
  if (nff ne 0) then begin
     raw_file = file[ff]
  endif else begin
     message,'No raw files in SOF file',/inform
     exit,status=1
  endelse

  print,'Postprocessing...'
  for f=0,nff-1 do begin
     print,' ==> '+raw_file[f]

     dname = file_dirname(raw_file[f])
     fname = file_basename(raw_file[f])
     
     fname = strmid(fname,0,strlen(fname)-5)
     files = file_search(dname+'/../'+fname+'*.fits',count=nfiles)

     for g=0,nfiles-1 do begin
        print,'   * associated product '+files[g]
        
        print,'   * stripping extensions'
        data = readfits(files[g],hdr)
        
        print,'   * resaving into '+files[g]
        writefits,files[g],data,hdr
     endfor
        
     print
  endfor
end
