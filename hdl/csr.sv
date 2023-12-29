// SPDX-License-Identifier: BSD-3-clause
/*
 * Copyright (C) Jörn Hoffmann, 2023
 *
 * Project  : SEC-V
 * Author   : J. Hoffmann <joern@bitaggregat.de>
 * Purpose  : Control and status register unit
 *
 * Opcodes
 *  - CSRRW,  CSRRS,  CSRRC
 *  - CSRRWI, CSRRSI, CSRRCI
 *
 * Todo
 *  [ ] Add functionality
 *
 * History
 *  v1.0    - Initial version
 */

`include "secv_pkg.svh"
import secv_pkg::*;

module csr #(
    parameter int XLEN = secv_pkg::XLEN
) (
    input  funit_in_t  fu_i,
    output funit_out_t fu_o
);


endmodule
