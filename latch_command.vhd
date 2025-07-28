----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/24/2025 08:32:27 AM
-- Design Name: 
-- Module Name: latch_command - Behavioral
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


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity latch_command is
Port (
    clk_i : in std_logic;
    start_cmd_i : in std_logic;
    twp_register_i: in std_logic_vector(31 downto 0);
    tclh_register_i: in std_logic_vector(31 downto 0);
    tcls_register_i: in std_logic_vector(31 downto 0);
    tlc_register_i: in std_logic_vector(31 downto 0);  
    cle_o : out std_logic;
    cmd_we_n_o : out std_logic;
    cmd_in_i : in std_logic_vector(7 downto 0);
    cmd_out_o : out std_logic_vector(7 downto 0);
    cmd_busy_o: out std_logic
);
end latch_command;
 
architecture Behavioral of latch_command is

type latch_states is (IDLE, SET, SEND, DONE, FINISH);

signal state : latch_states := IDLE;
signal counter : integer := 0;
signal t_wp_s : integer := 0;
signal t_clh_s : integer := 0;
signal t_cls_s : integer := 0;
signal t_lc_s : integer := 0;

begin



cle_o <= '1' when (state = SET or state = SEND or state = DONE) else '0';
cmd_we_n_o <= '0' when (state = SEND) else '1';
cmd_out_o <= cmd_in_i when (state = SEND or state = DONE) else "ZZZZZZZZ"; -- test pattern, should not appear outside due to high Z
cmd_busy_o <= '1' when (state /= IDLE) else '0';

CMD_FSM : process(clk_i, start_cmd_i)
begin
    if(rising_edge(clk_i)) then
        t_wp_s <= TO_INTEGER(unsigned(twp_register_i)); 
        t_clh_s <= TO_INTEGER(unsigned(tclh_register_i));
        t_cls_s <= TO_INTEGER(unsigned(tcls_register_i));
        t_lc_s <= TO_INTEGER(unsigned(tlc_register_i));
        case state is 
            when IDLE => 
                if(start_cmd_i = '1') then
                    state <= SET;
                end if;
            when SET =>
                if(counter = (t_lc_s)) then
                    counter <= 0;
                    state <= SEND;
                else 
                    counter <= counter + 1;
                end if;
            when SEND =>
                if(counter = t_wp_s) then
                    counter <= 0;
                    state <= DONE;
                else 
                    counter <= counter + 1;
                end if;
            when DONE => 
                if(counter = t_clh_s) then
                    counter <= 0;
                    state <= FINISH;
                else
                    counter <= counter + 1;
                end if;     
            when FINISH =>                      -- wait t_cls for the address after
                if(counter = t_cls_s) then
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
