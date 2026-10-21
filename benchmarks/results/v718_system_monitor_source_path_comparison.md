# v718 comparison — System Monitor source paths

- **Before:** median 532.006 ms per 100 simulated launches; 600 external `dirname` processes.
- **After:** median 0.561 ms per 100 simulated launches; 0 external `dirname` processes.
- **Microbenchmark:** 948× faster for this path-resolution loop (99.89% lower measured time).
- **Method:** five trials; each trial resolves the six source paths 100 times using the old repeated `dirname` calls, then the new Bash parameter expansion. Raw results are in the adjacent CSV.
- **Scope:** this isolates path resolution. It does not represent a 948× speed-up for the full System Monitor process.
