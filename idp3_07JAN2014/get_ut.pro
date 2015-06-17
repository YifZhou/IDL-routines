function get_ut

 dstr = ' '
 months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', $
	   'Oct', 'Nov', 'Dec']
 str = 'date -u > date.txt'
 spawn, str
 openr, dlun, 'date.txt', /get_lun
 readf, dlun, dstr
 close, dlun
 free_lun, dlun

 dates = strsplit(dstr, /extract)

 year = dates[5]
 day = dates[2]
 timestr = dates[3]
 mo = -1
 for i = 0, 11 do begin
   if dates[1] eq months[i] then mo = i+1
 endfor
 if mo lt 0 then print, 'Error in month'
 month = strtrim(string(mo),2)
 if month lt 10 then month = '0' + month

 output = year + '-' + month + '-' + day + 'T' + timestr
 return, output
 end

