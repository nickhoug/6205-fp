`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"mem_test/X`"
`endif  /* ! SYNTHESIS */
