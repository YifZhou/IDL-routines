SPHERE/IFS reduction pipeline
=============================

Description
-----------

This repository contains a simple, custom SPHERE/IFS reduction pipeline.

The starting point is the script *data_reduction_IFS.sh*, which contains most of the documentation and a step by step procedure to reduce an IFS data set. Then the IDL script *data_reduction_IFS.pro* can be used for the final steps. The pro/ subdirectory contains other IDL routines that are used in the data reduction.

No example data is included, but the `ESO archive <http://archive.eso.org/wdb/wdb/eso/sphere/form>`_ now contains a lot of public data, which can be used to test the pipeline.

Do not hesitate to contact me if you have any problem using the reduction pipeline.

Credits
-------

If you use this pipeline, please cite the following reference:

* `Vigan et al. 2015, MNRAS, 454, 129 <https://ui.adsabs.harvard.edu/#abs/2015MNRAS.454..129V/abstract>`_

The development of the SPHERE instrument has demanded a tremendous effort from many scientists, who have devoted several years of their life to design, build, test and commission the instrument. To recognize this work, we kindly ask you to cite the relevant instrumental papers in your scientific work. The reference papers for SPHERE and the SPHERE/IFS mode are:

* SPHERE general description: `Beuzit et al., 2008, SPIE, <https://ui.adsabs.harvard.edu/#abs/2008SPIE.7014E..18B/abstract>`_
* IFS general description: `Claudi et al., 2008, SPIE, 7014 <https://ui.adsabs.harvard.edu/#abs/2008SPIE.7014E..3EC/abstract>`_
* IFS performance: `Mesa et al., 2015, A&A, 576, 121 <https://ui.adsabs.harvard.edu/#abs/2015A&A...576A.121M/abstract>`_

We are grateful for your effort, and hope that these tools will contribute to your scientific work and discoveries. Please feel free to report any bug or possible improvement to the author(s).
 
Author
------

Arthur Vigan, `arthur.vigan@lam.fr <mailto:arthur.vigan@lam.fr>`_
