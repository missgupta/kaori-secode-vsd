history
kaori-secode-calker:    optimizied for bow model, support cross-validation for gamma value of Chi-square kernel
kaori-secode-calker-v2: tbu
kaori-secode-calker-v3: optimized for fisher vector, with linear svm. there is
a bug when loading test data (contains NaN). And another bug is mu value
calculated when testing.
kaori-secode-calker-v4:  fix bug NaN
kaori-secode-calker-v5:  fix bug mu value calculated when testing
kaori-secode-calker-v6:  designed for MED 2013
kaori-secode-calker-v7:  designed for MED 2013, support different test sets
(to store kernels and scores for different test sets)
kaori-secode-calker-v7.1:  designed for MED 2013, load test data seperately
(not loading all), to support cal test kernel more efficiently
