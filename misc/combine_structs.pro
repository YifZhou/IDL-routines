PRO combine_structs,str1,str2,strsum,structyp=structyp
  ;+
  ; NAME:
  ;    COMBINE_STRUCTS
  ;
  ; PURPOSE:
  ;  takes two arrays of structures str1,str2 which have the
  ;  same number of elements but possibly different tags
  ;  and makes another structure which has the same number of elements
  ;  but the tags of both str1,str2 and has their respective tags
  ;  values copied into it
  ;
  ; CALLING SEQUENCE
  ;    combine_structs, struct1, struct2, newstruct, structyp=structyp
  ;
  ; INPUTS:
                                ;    struct1,struc2: The two
                                ;    structures to be combined. If
                                ;    structure arrays,
  ;               Must contain the same number of structs.
  ;
  ; KEYWORD PARAMETERS:
  ;   structyp: a string with the name of the new structure.
  ;     if already defined the program will crash.
  ;
  ; Author Dave Johnston UofM
  ;-

  IF n_params() LT 2 THEN BEGIN
     print,'-syntax combine_structs,str1,str2,strsum,structyp=structyp'
     return
  ENDIF

  s1=size(str1)
  s2=size(str2)

  IF s1(1) NE s2(1) THEN BEGIN
     print,'structure sizes are different'
     return
  ENDIF

  str=create_struct(name=structyp,str1(0),str2(0))
  strsum=replicate(str,s1(1))
  copy_struct,str1,strsum
  copy_struct,str2,strsum

  return
  end
