# FilterEvaluationFramework
This framework can be used to implement filters that are implemented in libDirectional. Features:
* Ensures all filters have to deal with the same scenario.
* Evaluation is performed at the last time step to facilitate that we are not too heavily influenced by the prior. Further, one does not consider massively correlated states when calculating the error.
* Measures only the real online run time of the filters.
* When possible, does expensive precomputations once for all runs to save computation time.
* Plot error over the number of parameters, time over the number of parameters, and error over run time.
* Much more... 

Author: Florian Pfaff, pfaff@kit.edu<br>
Includes sphMeanShift by Kailai Li, kailai.li@kit.edu
