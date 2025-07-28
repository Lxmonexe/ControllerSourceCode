----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/24/2025 04:31:09 PM
-- Design Name: 
-- Module Name: Controller_top - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Controller_top is
Port ( 
    clk : in std_logic;
    
    dbg_btn_i : in std_logic;
    
    cmd_register_i: in std_logic_vector(31 downto 0);
    ctrl_register_i: in std_logic_vector(31 downto 0);
    addr_register_i: in std_logic_vector(31 downto 0);
    addr_bis_register_i: in std_logic_vector(31 downto 0);
    status_register_o: out std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
    twp_register_i: in std_logic_vector(31 downto 0);
    tclh_register_i: in std_logic_vector(31 downto 0);
    tcls_register_i: in std_logic_vector(31 downto 0);
    tdh_register_i: in std_logic_vector(31 downto 0);
    trp_register_i: in std_logic_vector(31 downto 0);
    trhz_register_i: in std_logic_vector(31 downto 0);
    tlc_register_i: in std_logic_vector(31 downto 0);
    tla_register_i: in std_logic_vector(31 downto 0);
    
    clk_a_o      : out  std_logic;
    write_en_a_o : out  std_logic;
    addr_a_o     : out  std_logic_vector(15 downto 0) := "0000000000000000";
    data_a_o     : out  std_logic_vector(7 downto 0);
    data_a_i     : in std_logic_vector(7 downto 0);
    
    nand_ce_n : out std_logic;
    nand_cle : out std_logic;
    nand_ale : out std_logic;
    nand_we_n : out std_logic;
    nand_re_n : out std_logic;
    nand_wp_n : out std_logic;
    nand_data : inout std_logic_vector(7 downto 0);
    nand_rb_n : in std_logic
    
    );
end Controller_top;

architecture Behavioral of Controller_top is


component latch_command is
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
end component;

component latch_address is
Port (
    clk_i : in std_logic;
    start_addr_i : in std_logic;
    twp_register_i: in std_logic_vector(31 downto 0);
    tdh_register_i: in std_logic_vector(31 downto 0);
    tla_register_i: in std_logic_vector(31 downto 0);
    ale_o : out std_logic;
    addr_we_n_o : out std_logic;
    addr_in_i : in std_logic_vector(7 downto 0);
    addr_out_o : out std_logic_vector(7 downto 0);
    addr_busy_o : out std_logic
 );
end component;

component write_data is
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
end component;

component read_data is
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
end component;

component PHY is
Port (
    clk_i : in std_logic; 
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
end component;

attribute MARK_DEBUG : string;


----- Master FSM signal -----
signal Mstate : master_states := IDLE;
signal Sstate : substates := subIDLE;
signal PreviousMstate : master_states := IDLE;
signal NextSstate : substates := subIDLE;
signal delay_t : delay_type := CMDWAIT;
signal counter : integer := 0;
signal ready_counter : integer := 0;
signal address_cycle_count : integer := 0;
signal read_cycle_count : integer := 0; -- use to also count write cycle
signal wait_counter : integer := 0;
signal done : std_logic := '0';
signal wait_done : std_logic := '0';
signal controller_ready : std_logic := '0';


----- Command control signal -----
signal start_cmd_s : std_logic; 
signal cle_s : std_logic;
signal cmd_we_n_s :  std_logic;
signal cmd_in_s :  std_logic_vector(7 downto 0);
signal cmd_out_s :  std_logic_vector(7 downto 0);
signal cmd_busy_s:  std_logic;

----- Address control signal -----
signal start_addr_s :  std_logic;
signal ale_s :  std_logic;
signal addr_we_n_s :  std_logic;
signal addr_in_s :  std_logic_vector(7 downto 0);
signal addr_out_s :  std_logic_vector(7 downto 0);
signal addr_busy_s :  std_logic;

----- Write data control signal -----
signal start_write_s :  std_logic;
signal w_we_n_s :  std_logic; 
signal w_data_in_s :  std_logic_vector(7 downto 0);
signal w_data_out_s :  std_logic_vector(7 downto 0);
signal w_busy_s :  std_logic;

----- Read data control signal -----
signal start_read_s :  std_logic;
signal re_n_s :  std_logic;
signal r_data_out_s :  std_logic_vector (7 downto 0);
signal r_data_in_s :  std_logic_vector (7 downto 0);
signal r_busy_s :  std_logic;


----- Numeric NAND Flash signal -----
signal ready_busy_s : std_logic;

----- BRAM signal ------
signal BRAM_enable : std_logic;
signal addr_offset : integer := 0;
signal addr_index : integer := 0;
signal data_a_i_s : std_logic_vector(7 downto 0);
signal data_a_o_s : std_logic_vector(7 downto 0);


----- Register signal -----
signal twp_register_s:  std_logic_vector(31 downto 0);
signal tclh_register_s:  std_logic_vector(31 downto 0);
signal tcls_register_s:  std_logic_vector(31 downto 0);
signal tdh_register_s:  std_logic_vector(31 downto 0);
signal trp_register_s:  std_logic_vector(31 downto 0);
signal trhz_register_s:  std_logic_vector(31 downto 0);
signal tlc_register_s:  std_logic_vector(31 downto 0);
signal tla_register_s:  std_logic_vector(31 downto 0);


signal enable : std_logic := '0'; 
signal btn : std_logic;

begin

CMD_FSM : latch_command port map
(
    clk_i => clk,
    start_cmd_i => start_cmd_s,
    twp_register_i => twp_register_s,
    tclh_register_i => tclh_register_s,
    tcls_register_i => tcls_register_s,
    tlc_register_i => tlc_register_s,
    cle_o => cle_s,
    cmd_we_n_o => cmd_we_n_s,
    cmd_in_i => cmd_in_s,
    cmd_out_o => cmd_out_s,
    cmd_busy_o => cmd_busy_s
);

ADDR_FSM : latch_address port map
(
    clk_i => clk,
    start_addr_i => start_addr_s,
    twp_register_i => twp_register_s,
    tdh_register_i => tdh_register_s,
    tla_register_i => tla_register_s,
    ale_o => ale_s,
    addr_we_n_o => addr_we_n_s,
    addr_in_i => addr_in_s,
    addr_out_o => addr_out_s,
    addr_busy_o => addr_busy_s
);

WRITE_FSM : write_data port map
(
    clk_i => clk,
    start_write_i => start_write_s,
    twp_register_i => twp_register_s,
    tdh_register_i => tdh_register_s,
    w_we_n_o => w_we_n_s,
    w_data_in_i => w_data_in_s,
    w_data_out_o => w_data_out_s,
    w_busy_o => w_busy_s
);

READ_FSM : read_data port map
(
    clk_i => clk,
    start_read_i => start_read_s,
    trp_register_i => trp_register_s,
    trhz_register_i => trhz_register_s,
    re_n_o => re_n_s,
    r_data_out_i => r_data_out_s,
    r_data_in_o => r_data_in_s,
    r_busy_o => r_busy_s
);

PHY_interface : PHY port map 
( 
    clk_i => clk,
    nand_ce_n => nand_ce_n,
    nand_cle => nand_cle,
    nand_ale => nand_ale,
    nand_we_n => nand_we_n,   
    nand_re_n => nand_re_n,
    nand_wp_n => nand_wp_n,
    nand_data => nand_data,
    nand_rb_n => nand_rb_n,
    
    cle_i => cle_s,
    cmd_we_n_i => cmd_we_n_s,
    cmd_out_i => cmd_out_s,
    
    ale_i => ale_s,
    addr_we_n_i => addr_we_n_s,
    addr_out_i => addr_out_s,
    
    w_we_n_i => w_we_n_s,
    w_data_out_i => w_data_out_s,
    
    re_n_i => re_n_s,
    r_data_out_o => r_data_out_s,
    
    ready_busy_o => ready_busy_s,
    
    Mstate_i => Mstate,
    Sstate_i => Sstate
);




start_cmd_s <= '1' when (Sstate = LATCHCMD) else '0';
start_addr_s <= '1' when (Sstate = LATCHADDR) else '0';
start_write_s <= '1' when (Sstate = WRITEDATA) else '0';
start_read_s <= '1' when (Sstate = READDATA) else '0';


controller_ready <= '0' when (Mstate /= IDLE or ready_busy_s = '0') else '1';


status_register_o(0) <= controller_ready;
status_register_o(1) <= done;

BRAM_enable <= '1' when (wait_counter = 1 and (re_n_s = '0' xor w_we_n_s = '0')) else '0';

EN: process(clk, dbg_btn_i, done)
begin
    if rising_edge(clk) then
        btn <= dbg_btn_i;
        if(btn = '1') then
            enable <= '1';
        end if;
        if (done = '1' and enable = '1') then
            enable <= '0';
        end if;
        twp_register_s <= twp_register_i;
        tclh_register_s <= tclh_register_i;  
        tcls_register_s <= tcls_register_i;   
        tdh_register_s <= tdh_register_i;   
        trp_register_s <= trp_register_i;  
        trhz_register_s <= trhz_register_i;   
        tlc_register_s <= tlc_register_i;  
        tla_register_s <= tla_register_i;
    end if;
end process;

MASTER_FSM : process(all)
begin
   
    if rising_edge(clk) then
        if (ctrl_register_i(1) = '1') then
            Mstate <= RESET;
            Sstate <= LATCHCMD;
            delay_t <= CMDWAIT;
        
            counter <= 0;
            wait_counter <= 0;
            done <= '0';
            read_cycle_count <= 0;
            address_cycle_count <= 0;
            ready_counter <= 0;
            
        elsif((ctrl_register_i(0) = '0') and done = '1') then
            done <= '0';
        
        elsif(ctrl_register_i(0) = '1' and done = '0' and enable = '1') then
            case Mstate is 
        
            when IDLE =>
                if(wait_done = '1') then
                    done <= '1';
                    wait_done <= '0';
                elsif(cmd_register_i(0) = '1') then
                    Mstate <= RESET;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                elsif(cmd_register_i(1) = '1') then
                    Mstate <= READID;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                elsif(cmd_register_i(2) = '1') then
                    Mstate <= READPARAM;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                elsif(cmd_register_i(3) = '1') then
                    Mstate <= READSTATUS;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                elsif(cmd_register_i(4) = '1') then
                    Mstate <= READ;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                elsif(cmd_register_i(5) = '1') then
                    Mstate <= PAGEPROGRAM;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                elsif(cmd_register_i(6) = '1') then
                    Mstate <= ERASE;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0';
                elsif(cmd_register_i(7) = '1') then
                    Mstate <= SETFEATURES;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0';
                elsif(cmd_register_i(8) = '1') then
                    Mstate <= GETFEATURES;
                    Sstate <= LATCHCMD;
                    status_register_o(30) <= '0'; 
                else
                    status_register_o(30) <= '1'; 
                end if;
                
            when RESET =>
                cmd_in_s <= x"FF";
                Mstate <= SUBWAIT;
                delay_t <= CMDWAIT;
                PreviousMstate <= IDLE;
                NextSstate <= subIDLE;
                
            when READID =>
                cmd_in_s <= x"90";
                addr_in_s <= addr_register_i(7 downto 0);
                if(Sstate = LATCHCMD) then
                    delay_t <= CMDWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= LATCHADDR;
                    Mstate <= SUBWAIT;
                elsif(Sstate = LATCHADDR) then
                    delay_t <= ADDRWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= READDATA;
                    Mstate <= SUBWAIT;
                elsif(Sstate = READDATA) then
                    if(read_cycle_count = 5) then
                        read_cycle_count <= 0;
                        delay_t <= READWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    else
                        delay_t <= READWAIT;
                        PreviousMstate <= READID;
                        NextSstate <= Sstate;
                        Mstate <= SUBWAIT;
                        read_cycle_count <= read_cycle_count + 1;
                    end if;  
                end if;
                
            when READPARAM =>
                cmd_in_s <= x"EC";
                addr_in_s <= addr_register_i(7 downto 0);
                if(Sstate = LATCHCMD) then
                    delay_t <= CMDWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= LATCHADDR;
                    Mstate <= SUBWAIT;
                elsif(Sstate = LATCHADDR) then 
                    delay_t <= ADDRWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= READDATA;
                    Mstate <= SUBWAIT;
                elsif(Sstate = READDATA) then
                    if(ready_busy_s /= '0' and ready_counter = 1) then
                        if(read_cycle_count = 255) then
                            ready_counter <= 0;
                            read_cycle_count <= 0;
                            delay_t <= READWAIT;
                            PreviousMstate <= IDLE;
                            NextSstate <= subIDLE;
                            Mstate <= SUBWAIT;
                        else
                            delay_t <= READWAIT;
                            PreviousMstate <= Mstate;
                            NextSstate <= Sstate;
                            Mstate <= SUBWAIT;
                            read_cycle_count <= read_cycle_count + 1;
                        end if;
                    elsif(ready_busy_s = '0' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when READSTATUS => 
                cmd_in_s <= x"70";
                if(Sstate = LATCHCMD) then
                    delay_t <= CMDWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= READDATA;
                    Mstate <= SUBWAIT;
                elsif(Sstate = READDATA) then
                    if(ready_busy_s /= '0' and ready_counter = 1) then
                        ready_counter <= 0;
                        delay_t <= READWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    elsif(ready_busy_s = '0' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when PAGEPROGRAM =>
                cmd_in_s <= x"80";
                if(Sstate = LATCHCMD) then
                    if(counter = 1) then 
                        ready_counter <= 0;
                        counter <= 0;
                        cmd_in_s <= x"10";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= SUBWAIT;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    elsif(counter = 0) then
                        cmd_in_s <= x"80";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHADDR;
                        Mstate <= SUBWAIT;
                        counter <= 1;
                    end if;
                elsif(Sstate = LATCHADDR) then 
                    if(address_cycle_count = 0) then
                        addr_in_s <= addr_register_i(7 downto 0);
                    elsif(address_cycle_count = 1) then
                        addr_in_s <= addr_register_i(15 downto 8);
                    elsif(address_cycle_count = 2) then
                        addr_in_s <= addr_register_i(23 downto 16);
                    elsif(address_cycle_count = 3) then
                       addr_in_s <= addr_register_i(31 downto 24);
                    elsif(address_cycle_count = 4) then
                        addr_in_s <= addr_bis_register_i(7 downto 0);
                    end if;
                    if(address_cycle_count = 4) then
                            address_cycle_count <= 0;
                            delay_t <= ADDRWAIT;
                            PreviousMstate <= Mstate;
                            NextSstate <= WRITEDATA;
                            Mstate <= SUBWAIT;
                        else        
                            delay_t <= ADDRWAIT;
                            PreviousMstate <= Mstate;
                            NextSstate <= Sstate;
                            Mstate <= SUBWAIT;
                            address_cycle_count <= address_cycle_count + 1;
                        end if;
                elsif(Sstate = WRITEDATA) then                   
                    if(read_cycle_count = 2048 * TO_INTEGER(unsigned(cmd_register_i(18 downto 15)))) then
                        read_cycle_count <= 0;
                        delay_t <= WRITEWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHCMD;
                        Mstate <= SUBWAIT;
                    else
                        delay_t <= WRITEWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= Sstate;
                        Mstate <= SUBWAIT;
                        read_cycle_count <= read_cycle_count + 1;
                    end if;
                end if;
                
            when READ =>
                cmd_in_s <= x"00";
                if(Sstate = LATCHCMD) then
                    if(counter = 1) then
                        counter <= 0;
                        cmd_in_s <= x"30";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= READDATA; 
                        Mstate <= SUBWAIT;
                    elsif(counter = 0) then
                        cmd_in_s <= x"00";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHADDR;
                        Mstate <= SUBWAIT;
                        counter <= 1;
                    end if;
                elsif(Sstate = LATCHADDR) then
                    if(address_cycle_count = 0) then
                        addr_in_s <= addr_register_i(7 downto 0);
                    elsif(address_cycle_count = 1) then
                        addr_in_s <= addr_register_i(15 downto 8);
                    elsif(address_cycle_count = 2) then
                        addr_in_s <= addr_register_i(23 downto 16);
                    elsif(address_cycle_count = 3) then
                        addr_in_s <= addr_register_i(31 downto 24);
                    elsif(address_cycle_count = 4) then
                        addr_in_s <= addr_bis_register_i(7 downto 0);
                    end if; 
                    if(address_cycle_count = 4) then
                        address_cycle_count <= 0;
                        delay_t <= ADDRWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHCMD;
                        Mstate <= SUBWAIT;
                    else
                        delay_t <= ADDRWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= Sstate;
                        Mstate <= SUBWAIT;
                        address_cycle_count <= address_cycle_count + 1;
                    end if;
                elsif(Sstate = READDATA) then
                    if(ready_busy_s /= '0' and ready_counter = 1) then
                        if(read_cycle_count = 2048 * TO_INTEGER(unsigned(cmd_register_i(18 downto 15)))) then
                            ready_counter <= 0;
                            read_cycle_count <= 0;
                            delay_t <= READWAIT;
                            PreviousMstate <= IDLE;
                            NextSstate <= subIDLE;
                            Mstate <= SUBWAIT;
                        else
                            delay_t <= READWAIT;
                            PreviousMstate <= Mstate;
                            NextSstate <= Sstate;
                            Mstate <= SUBWAIT;
                            read_cycle_count <= read_cycle_count + 1;
                        end if;
                    elsif(ready_busy_s = '0' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when ERASE =>
                cmd_in_s <= x"60";
                addr_in_s <= addr_register_i(7 downto 0);
                if(Sstate = LATCHCMD) then
                    if(counter = 1) then
                        counter <= 0;
                        cmd_in_s <= x"D0";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE; 
                        Mstate <= SUBWAIT;
                    elsif(counter = 0) then
                        cmd_in_s <= x"60";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHADDR;
                        Mstate <= SUBWAIT;
                        counter <= 1;
                    end if;
                elsif(Sstate = LATCHADDR) then 
                    if(address_cycle_count = 2) then
                        address_cycle_count <= 0;
                        delay_t <= ADDRWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHCMD;
                        Mstate <= SUBWAIT;
                    else
                        delay_t <= ADDRWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= Sstate;
                        Mstate <= SUBWAIT;
                        address_cycle_count <= address_cycle_count + 1;
                    end if;
                end if;
                
            when SETFEATURES =>
                cmd_in_s <= x"EF";
                addr_in_s <= x"FA";
                if(Sstate = LATCHCMD) then
                    delay_t <= CMDWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= LATCHADDR;
                    Mstate <= SUBWAIT;
                elsif(Sstate = LATCHADDR) then
                    address_cycle_count <= 0;
                    delay_t <= ADDRWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= WRITEDATA;
                    Mstate <= SUBWAIT;
                elsif(Sstate = WRITEDATA) then                   
                    if(read_cycle_count = 3) then
                        read_cycle_count <= 0;
                        delay_t <= WRITEWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    else
                        delay_t <= WRITEWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= Sstate;
                        Mstate <= SUBWAIT;
                        read_cycle_count <= read_cycle_count + 1;
                    end if;
                end if;
                
            when GETFEATURES =>
                cmd_in_s <= x"EE";
                addr_in_s <= x"FA";
                if(Sstate = LATCHCMD) then
                    delay_t <= CMDWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= LATCHADDR;
                    Mstate <= SUBWAIT;
                elsif(Sstate = LATCHADDR) then
                    address_cycle_count <= 0;
                    delay_t <= ADDRWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= READDATA;
                    Mstate <= SUBWAIT;
                elsif(Sstate = READDATA) then                   
                    if(read_cycle_count = 3) then
                        read_cycle_count <= 0;
                        delay_t <= READWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    else
                        delay_t <= WRITEWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= Sstate;
                        Mstate <= SUBWAIT;
                        read_cycle_count <= read_cycle_count + 1;
                    end if;
                end if;
                
            when SUBWAIT =>
                if(delay_t = CMDWAIT) then
                    if(cmd_busy_s = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        if(PreviousMstate = SUBWAIT) then
                            Mstate <= PreviousMstate;
                            Sstate <= NextSstate;
                            delay_t <= WRITEDONE;
                            wait_done <= '0';
                      --  elsif(NextSstate = LATCHADDR) then
                      --      delay_t <= WAITRB;
                      --      Mstate <= SUBWAIT;
                      --      Sstate <= subIDLE;
                        else
                            Sstate <= NextSstate; 
                            Mstate <= PreviousMstate;
                            wait_done <= '1';
                        end if;
                    elsif(cmd_busy_s = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = ADDRWAIT) then
                    if(addr_busy_s = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(addr_busy_s = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = WRITEWAIT) then
                    if(w_busy_s = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(w_busy_s = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = READWAIT) then
                    if(r_busy_s = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(r_busy_s = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = WRITEDONE) then
                        if(ready_busy_s /= '0' and ready_counter = 1) then
                            ready_counter <= 0;
                            wait_counter <= 0;
                            wait_done <= '1';
                            Mstate <= IDLE;
                            Sstate <= subIDLE;
                        elsif(ready_busy_s = '0' and ready_counter = 0) then
                            ready_counter <= 1;
                        end if;
                elsif(delay_t = WAITRB) then 
                    if(ready_busy_s /= '0' and ready_counter = 1) then
                        ready_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(ready_busy_s = '0' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when others =>
                Mstate <= IDLE;
        end case;
        end if;
    end if;
end process;


status_register_o(2) <= '1' when Mstate = RESET else '0';
status_register_o(3) <= '1' when Mstate = READID else '0';
status_register_o(4) <= '1' when Mstate = READPARAM else '0';
status_register_o(5) <= '1' when Mstate = READSTATUS else '0';
status_register_o(6) <= '1' when Mstate = READ else '0';
status_register_o(7) <= '1' when Mstate = PAGEPROGRAM else '0';
status_register_o(8) <= '1' when Mstate = ERASE else '0';
status_register_o(9) <= '1' when (Mstate = SETFEATURES or Mstate = GETFEATURES) else '0';
status_register_o(10) <= '1' when Mstate = IDLE else '0';
status_register_o(11) <= '1' when Sstate = LATCHCMD else '0';
status_register_o(12) <= '1' when Sstate = LATCHADDR else '0';
status_register_o(13) <= '1' when Sstate = READDATA else '0';
status_register_o(14) <= '1' when Sstate = WRITEDATA else '0';


write_en_a_o <= '1' when (Sstate = READDATA and BRAM_enable = '1') else '0';
clk_a_o <= clk;
w_data_in_s <= data_a_i_s when BRAM_enable = '1' else "00000000";
data_a_o_s <= r_data_out_s when BRAM_enable = '1' else "00000000";
addr_index <= 0 when cmd_register_i(11 downto 10) = "00" else 
              16384 when cmd_register_i(11 downto 10) = "01" else
              32768 when cmd_register_i(11 downto 10) = "10" else
              49152 when cmd_register_i(11 downto 10) = "11" else 0;
              
BRAM_process: process(clk, BRAM_enable, Mstate)
begin
    
    if rising_edge(clk) then
        if(BRAM_enable = '1') then
            addr_a_o <= std_logic_vector(to_unsigned(addr_index + addr_offset, addr_a_o'length));
            addr_offset <= addr_offset + 1;
        elsif(Mstate = IDLE) then
            addr_offset <= 0;
        end if;
        data_a_o <= data_a_o_s;
        data_a_i_s <= data_a_i;
    end if;
   
end process;

end Behavioral;
