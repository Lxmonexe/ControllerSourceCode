----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/24/2025 02:24:14 PM
-- Design Name: 
-- Module Name: write_data - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity write_data is
Port ( 
    clk_i : in std_logic;
    start_write_i : in std_logic;
    twp_register_i: in std_logic_vector(31 downto 0);
    tdh_register_i: in std_logic_vector(31 downto 0);
    w_we_n_o : out std_logic; 
    w_data_in_i : in std_logic_vector(7 downto 0);
    w_data_out_o : out std_logic_vector(7 downto 0);
    w_busy_o : out std_logic
);
end write_data;

architecture Behavioral of write_data is
 
type write_states is (IDLE, WRITE, DONE);

signal state : write_states := IDLE;
signal counter : integer := 0;
signal t_wp_s : integer := 0;
signal t_dh_s : integer := 0;

begin

w_data_out_o <= w_data_in_i;
w_we_n_o <= '0' when (state = WRITE) else '1';
--w_data_out_o <= w_data_in_i when (state = WRITE or state = DONE) else "ZZZZZZZZ";
w_busy_o <= '1' when (state /= IDLE) else '0';

WRITE_FSM : process(clk_i, start_write_i)
begin
    if(rising_edge(clk_i)) then
        t_wp_s <= TO_INTEGER(unsigned(twp_register_i));
        t_dh_s <= TO_INTEGER(unsigned(tdh_register_i));
        case state is
            when IDLE =>
                if(start_write_i = '1') then
                    state <= WRITE;
                end if;
            when WRITE =>
                if(counter = t_wp_s)then
                    counter <= 0;
                    state <= DONE;
                else
                    counter <= counter + 1;
                end if;
            when DONE =>
                if(counter = t_dh_s) then
                    counter <= 0;
                    state <= IDLE;
                else
                    counter <= counter + 1;
                end if;
            when others =>
                state <= IDLE;
        end case;
    end if;
end process;

end Behavioral;
