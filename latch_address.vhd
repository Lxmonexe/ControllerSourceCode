----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/24/2025 10:57:17 AM
-- Design Name: 
-- Module Name: latch_address - Behavioral
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

entity latch_address is
Port (
    clk : in std_logic;
    start_addr : in std_logic;
    ale : out std_logic;
    addr_we_n : out std_logic;
    addr_in : in std_logic_vector(7 downto 0);
    addr_out : out std_logic_vector(7 downto 0);
    addr_busy : out std_logic
 );
end latch_address;
 
architecture Behavioral of latch_address is


type latch_states is (IDLE, LOAD, SEND, DONE);

signal state : latch_states := IDLE;
signal counter : integer := 0;

begin

ale <= '1' when (state = LOAD or state = SEND or state = DONE) else '0';
addr_we_n <= '0' when (state = SEND) else '1';
addr_out <= addr_in when (state = LOAD or state = SEND or state = DONE) else "ZZZZZZZZ";
addr_busy <= '1' when (state /= IDLE) else '0';

ADDR_FSM : process(clk, start_addr)
begin
    if(rising_edge(clk)) then
        case state is
            when IDLE =>
                if(start_addr = '1') then
                    state <= SEND;
                end if;
            --when LOAD =>
                --state <= SEND;
            when SEND =>
                if(counter = t_wp) then
                    counter <= 0;
                    state <= DONE;
                else
                    counter <= counter + 1;
                end if;
            when DONE =>
                if(counter = t_dh) then
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