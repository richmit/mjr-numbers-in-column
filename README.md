<!-- :shell>>> ~/core/codeBits/bin/emacs_package_com_to_md.rb mjr-numbers-in-column.el -->
# `mjr-stats-numbers-in-column`: Emacs Tools For Columnar Data

See the README: https://github.com/richmit/mjr-numbers-in-column/

This package provides an easy way to extract data arranged in a column and compute various statistics.

Two functions are provided:
 - `mjr-numbers-in-column-extract` to extract data from a column.
 - `mjr-numbers-in-column-stats` to compute statstics for data in a column

For example, we might be looking at the following "vmstat" output and want to know the average value for the "in" column.

      $ vmstat 1 10

      procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
       r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
       0  0  89032 21592880    0      0    0    0     0     0 2413 3604  0  2 98  0  0  0
       0  0  89032 21593640    0      0    0    0     0     0 1994 3036  1  2 97  0  0  0
       0  0  89032 21593620    0      0    0    0     0     0 1989 3043  1  3 96  0  0  0
       0  0  89032 21595388    0      0    0    0     0     0 2084 3299  0  0 100 0  0  0
       0  0  89032 21593396    0      0    0    0     0     0 2311 3710  0  1 99  0  0  0
       0  0  89032 21592160    0      0    0    0     0     0 1861 3030  0  1 99  0  0  0
       0  0  89032 21592184    0      0    0    0     0     0 1996 3034  1  3 96  0  0  0
       0  0  89032 21592664    0      0    0    0     0     0 2190 3283  1  3 96  0  0  0
       0  0  89032 21592284    0      0    0    0     0     0 2121 3174  1  4 95  0  0  0

All we have to do is put our cursor on any digit of 2413 in the first row and run `mjr-numbers-in-column-stats` to get the following:

      sum: 18959 mean: 2106.55556 median: 2084 min: 1861 max: 2413 sd: 164.11183
      psd: 174.06688 range: 552 n: 9 var: 26932.69136 pvar: 30299.27778 sumsq: 40180581

So the average is 2106 with a standard deviation of 164.11183.

# Installing

The easiest way to install mjr-stats-numbers-in-column is to pull it directly from github:

     (package-vc-install (list 'mjr-stats-numbers-in-column
                          :url "https://github.com/richmit/mjr-stats-numbers-in-column"
                          :rev 'newest))
