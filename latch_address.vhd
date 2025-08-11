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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity latch_address is
Port (
    clk_i : in std_logic;
    start_addr_i : in std_logic;
    twp_i: in std_logic_vector(31 downto 0);
    tdh_i: in std_logic_vector(31 downto 0);
    tla_i: in std_logic_vector(31 downto 0);
    ale_o : out std_logic;
    addr_we_n_o : out std_logic;
    addr_in_i : in std_logic_vector(7 downto 0);
    addr_out_o : out std_logic_vector(7 downto 0);
    addr_busy_o : out std_logic
 );
end latch_address;
 
architecture Behavioral of latch_address is


type latch_states is (IDLE, SEND, DONE, FINISH);

signal state : latch_states := IDLE;
signal counter : integer := 0;
signal t_wp_s : integer := 0;
signal t_dh_s : integer := 0;
signal t_la_s : integer := 0;

begin


ale_o <= '1' when (state = SEND or state = DONE) else '0';
addr_we_n_o <= '0' when (state = SEND) else '1';
addr_out_o <= addr_in_i when (state = SEND or state = DONE) else "ZZZZZZZZ";
addr_busy_o <= '1' when (state /= IDLE) else '0';

ADDR_FSM : process(clk_i, start_addr_i)
begin
    if(rising_edge(clk_i)) then
        t_wp_s <= TO_INTEGER(unsigned(twp_i));
        t_dh_s <= TO_INTEGER(unsigned(tdh_i));
        t_la_s <= TO_INTEGER(unsigned(tla_i));
        case state is
            when IDLE =>
                if(start_addr_i = '1') then
                    state <= SEND;
                end if;
            when SEND =>
                if(counter = t_wp_s) then
                    counter <= 0;
                    state <= DONE;
                else
                    counter <= counter + 1;
                end if;
            when DONE =>
                if(counter = t_dh_s) then
                    counter <= 0;
                    state <= FINISH;
                else
                    counter <= counter + 1;
                end if;
            when FINISH =>
                if(counter = t_la_s) then
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