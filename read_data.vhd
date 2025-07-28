----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/24/2025 04:09:00 PM
-- Design Name: 
-- Module Name: read_data - Behavioral
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

entity read_data is
Port ( 
    clk_i : in std_logic;
    start_read_i : in std_logic;
    trp_register_i: in std_logic_vector(31 downto 0);
    trhz_register_i: in std_logic_vector(31 downto 0);
    re_n_o : out std_logic;
    r_data_out_i : in std_logic_vector (7 downto 0);
    r_data_in_o : out std_logic_vector (7 downto 0);
    r_busy_o : out std_logic
);
end read_data;

architecture Behavioral of read_data is
 
type read_states is (IDLE, READ, DONE);

signal state : read_states := IDLE;
signal counter : integer := 0;
signal t_rp_s : integer := 0;
signal t_rhz_s : integer := 0;

begin

re_n_o <= '0' when (state = READ) else '1';
r_data_in_o <= r_data_out_i when (state = READ or state = DONE) else "ZZZZZZZZ";
r_busy_o <= '1' when (state /= IDLE) else '0';

READ_FSM : process(clk_i, start_read_i)
begin
    if(rising_edge(clk_i)) then
        t_rp_s <= TO_INTEGER(unsigned(trp_register_i));
        t_rhz_s <= TO_INTEGER(unsigned(trhz_register_i));
        case state is
            when IDLE =>
                if(start_read_i = '1') then
                    state <= READ;
                end if;
            when READ =>
                if(counter = t_rp_s) then
                    counter <= 0;
                    state <= DONE;
                else
                    counter <= counter + 1;
                end if;
            when DONE =>
                if(counter = t_rhz_s) then -- supposed to be t_rhz and cannot exceed 100ns
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
