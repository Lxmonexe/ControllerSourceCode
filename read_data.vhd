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
use work.onfi.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity read_data is
Port ( 
    clk : in std_logic;
    start_read : in std_logic;
    re_n : out std_logic;
    r_data_out : in std_logic_vector (7 downto 0);
    r_data_in : out std_logic_vector (7 downto 0);
    r_busy : out std_logic
);
end read_data;

architecture Behavioral of read_data is
 
type read_states is (IDLE, READ, DONE);

signal state : read_states := IDLE;
signal counter : integer := 0;

begin

re_n <= '0' when (state = READ) else '1';
r_data_in <= r_data_out when (state = READ or state = DONE) else "ZZZZZZZZ";
r_busy <= '1' when (state /= IDLE) else '0';

READ_FSM : process(clk, start_read)
begin
    if(rising_edge(clk)) then
        case state is
            when IDLE =>
                if(start_read = '1') then
                    state <= READ;
                end if;
            when READ =>
                if(counter = t_rp) then
                    counter <= 0;
                    state <= DONE;
                else
                    counter <= counter + 1;
                end if;
            when DONE =>
                if(counter = 10) then -- supposed to be t_rhz and cannot exceed 100ns
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
