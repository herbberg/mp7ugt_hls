-------------------------------------------------------------------------------
-- Synthesizer : ISE 14.6
-- Platform    : Linux Ubuntu 10.04
-- Targets     : Synthese
--------------------------------------------------------------------------------
-- This work is held in copyright as an unpublished work by HEPHY (Institute
-- of High Energy Physics) All rights reserved.  This work may not be used
-- except by authorized licensees of HEPHY. This work is the
-- confidential information of HEPHY.
--------------------------------------------------------------------------------
---Description:
-- $HeadURL: $
-- $Date:  $
-- $Author: HEPHY $
-- Modification : HEPHY,
--    1)for MP7
--    2) do not edit this part, it will be produced autmatically based  on python scirpt. The scirpt has a bug, and the bug should be fixed. I am not sure, if desing is woking correctly
-- $Revision: 0.1 $
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gt_mp7_core_pkg.all;
use work.math_pkg.all;

package output_logic_pkg is

   -- autogenerated items
	constant BX_IN_EVENT_ITEMS : integer := 4;
	constant OUTPUT_LOGIC_INSTR_ADDR_WIDTH : integer := 8;
	constant OL_INSTR_MUX_WIDTH : integer := 256;
	constant OL_MUX_STAGES : integer := 2;


   -- template
   constant OL_INSTR_BX_IE_WIDTH : integer := log2c(BX_IN_EVENT_ITEMS);

   constant OL_INSTR_ADDR_WIDTH  : integer := OUTPUT_LOGIC_INSTR_ADDR_WIDTH;
   constant OL_INSTR_CTRL_WIDTH  : integer := 4;

   constant OL_INSTR_MUX_FROM    : integer := 0;
   constant OL_INSTR_MUX_TO      : integer := OL_INSTR_MUX_FROM+OL_INSTR_MUX_WIDTH-1;

   constant OL_INSTR_ADDR_FROM   : integer := OL_INSTR_MUX_TO+1;
   constant OL_INSTR_ADDR_TO     : integer := OL_INSTR_ADDR_FROM+OL_INSTR_ADDR_WIDTH-1;


   constant OL_INSTR_BX_IE_FROM  : integer := OL_INSTR_ADDR_TO+1;
   constant OL_INSTR_BX_IE_TO    : integer := OL_INSTR_BX_IE_FROM+OL_INSTR_BX_IE_WIDTH-1;


   constant OL_INSTR_CTRL_FROM   : integer := OL_INSTR_BX_IE_TO+1;
   constant OL_INSTR_CTRL_TO     : integer := OL_INSTR_CTRL_FROM+OL_INSTR_CTRL_WIDTH-1;

   constant OL_INSTR_SOH : integer := 0;
   constant OL_INSTR_EOH : integer := 1;
   constant OL_INSTR_EOF : integer := 2;
   constant OL_INSTR_CRC  : integer := 3;

   constant OUTPUT_LOGIC_INSTR_WIDTH : integer :=  OL_INSTR_MUX_WIDTH+
                                                   OL_INSTR_BX_IE_WIDTH+
                                                   OL_INSTR_ADDR_WIDTH+
                                                   OL_INSTR_CTRL_WIDTH;

   type bx_in_event_array_t is array (0 to BX_IN_EVENT_ITEMS-1) of unsigned(log2c(MAX_BX_IN_EVENT)-1 downto 0);

end output_logic_pkg;

package body output_logic_pkg is

end output_logic_pkg;
