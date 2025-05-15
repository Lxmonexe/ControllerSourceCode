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
     
    cle : in std_logic;
    cmd_we_n : in std_logic;
    cmd_out : in std_logic_vector (7 downto 0);
    
    ale : in std_logic;
    addr_we_n : in std_logic;
    addr_out : in std_logic_vector (7 downto 0);
    
    w_we_n : in std_logic;
    w_data_out : in std_logic_vector (7 downto 0);
    
    re_n : in std_logic;
    r_data_out : out std_logic_vector (7 downto 0);
    
    ready_busy : out std_logic;
    
    Mstate : in master_states;
    Sstate : in substates
);
end PHY;

architecture Behavioral of PHY is

begin

nand_ce_n <= '1' when (Mstate = IDLE) else '0';

nand_cle <= cle when (Sstate = LATCHCMD and Mstate /= IDLE) else '0';

nand_ale <= ale when (Sstate = LATCHADDR and Mstate /= IDLE) else '0';

nand_we_n <= cmd_we_n when (Sstate = LATCHCMD and Mstate /= IDLE) else
             addr_we_n when (Sstate = LATCHADDR and Mstate /= IDLE) else
             w_we_n when (Sstate = WRITEDATA and Mstate /= IDLE) else '1';
             
nand_re_n <= re_n when (Sstate = READDATA and Mstate /= IDLE) else '1';

nand_data <= cmd_out when (Sstate = LATCHCMD and Mstate /= IDLE) else
             addr_out when (Sstate = LATCHADDR and Mstate /= IDLE) else
             w_data_out when (Sstate = WRITEDATA and Mstate /= IDLE) else "ZZZZZZZZ";

nand_wp_n <= '1' when (Mstate /= IDLE) else '0'; -- à revoir 
            
r_data_out <= nand_data;
           
ready_busy <= nand_rb_n;

end Behavioral;
