----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/28/2025 08:27:45 AM
-- Design Name: 
-- Module Name: PHY - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.onfi.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PHY is
Port ( 
    nand_ce_n : out std_logic;
    nand_cle : out std_logic;
    nand_ale : out std_logic;
    nand_we_n : out std_logic;
    nand_re_n : out std_logic;
    nand_wp_n : out std_logic;
    nand_data : inout std_logic_vector(7 downto 0);
    nand_rb_n : in std_logic;
     
    cle_i : in std_logic;
    cmd_we_n_i : in std_logic;
    cmd_out_i : in std_logic_vector (7 downto 0);
    
    ale_i : in std_logic;
    addr_we_n_i : in std_logic;
    addr_out_i : in std_logic_vector (7 downto 0);
    
    w_we_n_i : in std_logic;
    w_data_out_i : in std_logic_vector (7 downto 0);
    
    re_n_i : in std_logic;
    r_data_out_o : out std_logic_vector (7 downto 0);
    
    ready_busy_o : out std_logic;
    
    Mstate_i : in master_states;
    Sstate_i : in substates
);
end PHY;

architecture Behavioral of PHY is

begin

nand_ce_n <= '1' when (Mstate_i = IDLE) else '0';

nand_cle <= cle_i when (Sstate_i = LATCHCMD and Mstate_i /= IDLE) else '0';

nand_ale <= ale_i when (Sstate_i = LATCHADDR and Mstate_i /= IDLE) else '0';

nand_we_n <= cmd_we_n_i when (Sstate_i = LATCHCMD and Mstate_i /= IDLE) else
             addr_we_n_i when (Sstate_i = LATCHADDR and Mstate_i /= IDLE) else
             w_we_n_i when (Sstate_i = WRITEDATA and Mstate_i /= IDLE) else '1';
             
nand_re_n <= re_n_i when (Sstate_i = READDATA and Mstate_i /= IDLE) else '1';

nand_data <= cmd_out_i when (Sstate_i = LATCHCMD and Mstate_i /= IDLE) else
             addr_out_i when (Sstate_i = LATCHADDR and Mstate_i /= IDLE) else
             w_data_out_i when (Sstate_i = WRITEDATA and Mstate_i /= IDLE) else "ZZZZZZZZ";

nand_wp_n <= '1' when (Mstate_i /= IDLE) else '0'; -- à revoir 
            
r_data_out_o <= nand_data;
           
ready_busy_o <= nand_rb_n;

end Behavioral;
