function idp3_cursor, event
  Widget_control,event.top,Get_UValue=tinfo
  Widget_control,tinfo.idp3Window,Get_UValue=info
  
  Case Event.Value of
  0: begin
    (*tinfo.roi).mouse_mode = 0
    (*info.roi).mouse_mode = 0
  end

  1: begin
    (*tinfo.roi).mouse_mode = 1 
    (*info.roi).mouse_mode = 1
  end

  2: begin
    (*tinfo.roi).mouse_mode = 2
    (*info.roi).mouse_mode = 2
  end

  3: begin
    (*tinfo.roi).mouse_mode = 3
    (*info.roi).mouse_mode = 3
  end

  4: begin
    (*tinfo.roi).mouse_mode = 4
    (*info.roi).mouse_mode = 4
  end

  5: begin
    (*tinfo.roi).mouse_mode =5 
    (*info.roi).mouse_mode = 5
  end

  endcase

  Widget_control,tinfo.idp3Window,Set_UValue=info
  Widget_control,event.top,Set_UValue=tinfo
  ok = 1
  return, ok
end
