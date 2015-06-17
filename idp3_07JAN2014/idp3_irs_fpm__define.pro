pro idp3_irs_fpm::CLEANUP

   print,'Cleaning up!'
   ptr_free,self.idp3_info

end

function idp3_irs_fpm::INIT,info
   print,'IRS_fpm object is alive!'
   if ptr_valid(self.idp3_info) then self.idp3_info = info else $
     self.idp3_info = ptr_new(info)
   help,*self.idp3_info
   return,1
end

pro idp3_irs_fpm__define

   struct = {idp3_irs_fpm, $
             idp3_info:ptr_new() $
            }
   return

end
