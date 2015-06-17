FUNCTION myReadCSV,fn, tags
  ;; function for reading csv files
  ;; change the names of tags  
  strct = read_csv(fn)
  IF n_tags(strct) NE N_ELEMENTS(tags) THEN BEGIN
     print, 'wrong number of tags'
     return, 1
  ENDIF 
  return, rename_tags(strct, tag_names(strct), tags)
END
