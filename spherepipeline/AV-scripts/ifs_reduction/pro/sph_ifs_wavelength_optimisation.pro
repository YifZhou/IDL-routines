;+
; NAME:
;
;  SPH_IFS_WAVELENGTH_OPTIMISATION
;
; PURPOSE:
;
;  Wavlength optimisation routine for MPFIT() minimization.
;
; CALLING SEQUENCE:
;
;  Automatically called by MPFIT() during minimization
;
; DESCRIPTION:
; 
;  Interpolate the wavelength law at the position of the laser lines
;  and compares to the known wavelength of the lasers
;
; INPUTS:
;
;  PAR - fitted parameyers
;
;  LAM_LASER - wavelength of the lasers; in nm
;
;  POS_LASER - position of the laser peals in the wavelength vector;
;              in pixel
;
;  REF_IDX - index of the reference wavelength
;
;  NLAMBDA - number of wavelengths
;
;  SCALE_AVERAGE - scaling factor vector
;
; OUTPUTS:
;
;  Maximum of the difference between the know wavelength of the lasers
;  and the wavelength estimated from the wavelength calibration
;
; MODIFICATION HISTORY:
;
;  arthur.vigan - 07/2017
;                 Code transitionned to GitHub for improved support
;                 
;  arthur.vigan - 08/2015 - public version of personnal tool
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


function sph_ifs_wavelength_optimisation,par,lam_laser=lam_laser,pos_laser=pos_laser, $
                                         ref_idx=ref_idx,nlambda=nlambda, $
                                         scale_average=scale_average
  ref_lam = par[0]
  
  idx       = indgen(nlambda)
  lambda    = replicate(ref_lam,nlambda) * scale_average/scale_average[ref_idx]
  lam_peaks = interpol(lambda,idx,pos_laser)
  
  diff = lam_peaks-lam_laser
    
  return,max(abs(diff))
end
