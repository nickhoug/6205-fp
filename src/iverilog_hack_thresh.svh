`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"mem_thresh/X`"
`endif  /* ! SYNTHESIS */
