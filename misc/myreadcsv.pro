FUNCTION myReadCSV,fn, tags, nStart=nStart, missing_value=missing_value
  ;; function for reading csv files
  ;; change the names of tags
  ;; nStart : number of lines to start
  IF NOT keyword_set(nStart) THEN nStart = 0
  IF NOT keyword_set(missing_value) THEN missing_value = 0
  strct = read_csv(fn, record_start=nStart, missing_value = missing_value)
  IF n_tags(strct) NE N_ELEMENTS(tags) THEN BEGIN
     print, 'wrong number of tags'
     return, 1
  ENDIF 
  return, rename_tags(strct, tag_names(strct), tags)
END
