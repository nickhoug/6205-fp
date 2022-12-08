`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"mem_kernel/X`"
`endif  /* ! SYNTHESIS */
