-- altera vhdl_input_version vhdl_2008
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-- Title   : ONFI compliant NAND interface
-- File    : onfi_package.vhd
-- Author  : Alexey Lyashko <pradd@opencores.org>
-- License : LGPL
-------------------------------------------------------------------------------------------------
-- Description:
-- This file contains clock cycle duration definition, delay timing constants as well as
-- definition of FSM states and types used in the module.
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package onfi is
    -- Clock cycle length in ns
    -- IMPORTANT!!! The 'clock_cycle' is configured for 400MHz, change it appropriately!
    -- Changed to 10 ns. Author: Nicholas Strong
    -- constant clock_cycle    : real := 2.5;
    constant clock_cycle    : real := 10.0;

    -- NAND interface delays.
    -- These are all based on the DC characteristics at the back of the datasheet
    -- Delays of 7.5ns may need to be fixed to 7.0.
    -- Nicholas Strong : editing these for the micron part          -- MT29F256G08CBCBB -- MT29F8G08ABACA
    constant t_cls  : integer := integer(50.0       / clock_cycle); -- > 50.0           -- > 10.0          -- CLE Setup Time              --
    constant t_clh  : integer := integer(20.0       / clock_cycle); -- > 20.0           -- > 5.0           -- CLE Hold Time               --
    constant t_wp   : integer := integer(50.0       / clock_cycle); -- > 50.0           -- > 10.0          -- WE# Pulse Width             --
    constant t_wh   : integer := integer(30.0       / clock_cycle); -- > 30.0           -- > 7.0           -- WE# High Hold Time          --
    constant t_wc   : integer := integer(100.0      / clock_cycle); -- > 100.0          -- > 20.0          -- WE# Cycle Time              --
    constant t_ds   : integer := integer(40.0       / clock_cycle); -- > 40.0           -- > 7.0           -- Data Setup Time             --
    constant t_dh   : integer := integer(20.0       / clock_cycle); -- > 20.0           -- > 5.0           -- Data Hold Time              --
    constant t_als  : integer := integer(50.0       / clock_cycle); -- > 50.0           -- > 10.0          -- ALE Setup Time              --
    constant t_alh  : integer := integer(20.0       / clock_cycle); -- > 20.0           -- > 5.0           -- ALE Hold Time               --
    constant t_rr   : integer := integer(40.0       / clock_cycle); -- > 40.0           -- > 20.0          -- Ready to RE# Low            --
    constant t_rea  : integer := integer(40.0       / clock_cycle); -- < 40.0           -- < 16.0          -- RE# Access Time             --
    constant t_rp   : integer := integer(70.0       / clock_cycle); -- > 50.0           -- > 10.0          -- RE# Pulse Width             -- * Inrease rp so that rp+reh=rc
    constant t_reh  : integer := integer(30.0       / clock_cycle); -- > 30.0           -- > 7.0           -- RE# High Hold Time          --
    constant t_rhw  : integer := integer(200.0      / clock_cycle); -- > 200.0                             -- RE# High to WE# Low
    constant t_wb   : integer := integer(200.0      / clock_cycle); -- < 200.0          -- < 100.0         -- WE# High to R/B# Low        --
    constant t_rst  : integer := integer(500000.0   / clock_cycle); -- < 500000.0       -- < 5000.0        -- Device Reset Time           --
    constant t_bers : integer := integer(30000000.0 / clock_cycle); -- < 30000000.0     -- < 10000000.0    -- ERASE BLOCK Operation Time  --
    constant t_whr  : integer := integer(120.0      / clock_cycle); -- > 120.0          -- > 60.0          -- WE# High to RE# Low         --
    constant t_prog : integer := integer(950000.0   / clock_cycle); -- < 950000.0       -- < 600000.0      -- PROGRAM PAGE Operation Time --
    constant t_adl  : integer := integer(150.0      / clock_cycle); -- > 150.0          -- > 70.0          -- ALE to Data Start           --
    constant t_r    : integer := integer(78000.0    / clock_cycle); -- < 78000.0        -- < 25000.0       -- READ PAGE Operation Time    -- * For read parameter, at least
    constant t_ww   : integer := integer(100.0      / clock_cycle); -- > 100.0          -- Look this up    -- Explain this

    type master_states is (IDLE, RESET, READID, READPARAM, PAGEPROGRAM, READSTATUS, READ, ERASE, SETFEATURES, GETFEATURES ,SUBWAIT);
	type substates is ( subIDLE, LATCHCMD, LATCHADDR, WRITEDATA, READDATA);
	type delay_type is (CMDWAIT, ADDRWAIT, WRITEWAIT, READWAIT, WRITEDONE);
	
end onfi;
