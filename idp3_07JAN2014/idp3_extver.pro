function idp3_extver, nextend, extnames, extnam, val_extnam

  ; checking for number of extensions that match the desired extension
  ; name.  If there are no extension names (string length = 0) set
  ; next to number of extensions in file

  next = 0
  val_extnam = 0
  for i = 1, nextend do begin
    if strlen(extnames[i]) gt 0 then begin
      if extnames[i] eq extnam then next = next + 1
      val_extnam = val_extnam + 1
    endif 
  endfor

  if val_extnam eq 0 and next eq 0 then next = nextend
  return, next
end
