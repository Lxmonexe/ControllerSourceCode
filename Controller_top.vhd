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
    cmd_register: in std_logic_vector(31 downto 0);
    ctrl_register: in std_logic_vector(31 downto 0);
    addr_register: in std_logic_vector(31 downto 0);
    addr_bis_register: in std_logic_vector(31 downto 0);
    status_register: out std_logic_vector(31 downto 0) := "00000000000000000000000000000000" ;
    
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
    clk : in std_logic;
    start_cmd : in std_logic; 
    cle : out std_logic;
    cmd_we_n : out std_logic;
    cmd_in : in std_logic_vector(7 downto 0);
    cmd_out : out std_logic_vector(7 downto 0);
    cmd_busy: out std_logic
);
end component;

component latch_address is
Port (
    clk : in std_logic;
    start_addr : in std_logic;
    ale : out std_logic;
    addr_we_n : out std_logic;
    addr_in : in std_logic_vector(7 downto 0);
    addr_out : out std_logic_vector(7 downto 0);
    addr_busy : out std_logic
 );
end component;

component write_data is
Port ( 
    clk : in std_logic;
    start_write : in std_logic;
    w_we_n : out std_logic; 
    w_data_in : in std_logic_vector(7 downto 0);
    w_data_out : out std_logic_vector(7 downto 0);
    w_busy : out std_logic
);
end component;

component read_data is
Port ( 
    clk : in std_logic;
    start_read : in std_logic;
    re_n : out std_logic;
    r_data_out : in std_logic_vector (7 downto 0);
    r_data_in : out std_logic_vector (7 downto 0);
    r_busy : out std_logic
);
end component;

component PHY is
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
end component;


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
signal start_cmd : std_logic; 
signal cle : std_logic;
signal cmd_we_n :  std_logic;
signal cmd_in :  std_logic_vector(7 downto 0);
signal cmd_out :  std_logic_vector(7 downto 0);
signal cmd_busy:  std_logic;

----- Address control signal -----
signal start_addr :  std_logic;
signal ale :  std_logic;
signal addr_we_n :  std_logic;
signal addr_in :  std_logic_vector(7 downto 0);
signal addr_out :  std_logic_vector(7 downto 0);
signal addr_busy :  std_logic;

----- Write data control signal -----
signal start_write :  std_logic;
signal w_we_n :  std_logic; 
signal w_data_in :  std_logic_vector(7 downto 0);
signal w_data_out :  std_logic_vector(7 downto 0);
signal w_busy :  std_logic;

----- Read data control signal -----
signal start_read :  std_logic;
signal re_n :  std_logic;
signal r_data_out :  std_logic_vector (7 downto 0);
signal r_data_in :  std_logic_vector (7 downto 0);
signal r_busy :  std_logic;


----- Numeric NAND Flash signal -----
signal ready_busy : std_logic;

----- BRAM control signal ------
signal BRAM_enable : std_logic;
signal addr_offset : integer := 0;
signal addr_index : integer := 0;

begin



CMD_FSM : latch_command port map
(
    clk => clk,
    start_cmd => start_cmd,
    cle => cle,
    cmd_we_n => cmd_we_n,
    cmd_in => cmd_in,
    cmd_out => cmd_out,
    cmd_busy => cmd_busy
);

ADDR_FSM : latch_address port map
(
    clk => clk,
    start_addr => start_addr,
    ale => ale,
    addr_we_n => addr_we_n,
    addr_in => addr_in,
    addr_out => addr_out,
    addr_busy => addr_busy
);

WRITE_FSM : write_data port map
(
    clk => clk,
    start_write => start_write,
    w_we_n => w_we_n,
    w_data_in => w_data_in,
    w_data_out => w_data_out,
    w_busy => w_busy
);

READ_FSM : read_data port map
(
    clk => clk,
    start_read => start_read,
    re_n => re_n,
    r_data_out => r_data_out,
    r_data_in => r_data_in,
    r_busy => r_busy
);

PHY_interface : PHY port map 
( 
    nand_ce_n => nand_ce_n,
    nand_cle => nand_cle,
    nand_ale => nand_ale,
    nand_we_n => nand_we_n,   
    nand_re_n => nand_re_n,
    nand_wp_n => nand_wp_n,
    nand_data => nand_data,
    nand_rb_n => nand_rb_n,
    
    cle => cle,
    cmd_we_n => cmd_we_n,
    cmd_out => cmd_out,
    
    ale => ale,
    addr_we_n => addr_we_n,
    addr_out => addr_out,
    
    w_we_n => w_we_n,
    w_data_out => w_data_out,
    
    re_n => re_n,
    r_data_out => r_data_out,
    
    ready_busy => ready_busy,
    
    Mstate => Mstate,
    Sstate => Sstate
);


start_cmd <= '1' when (Sstate = LATCHCMD) else '0';
start_addr <= '1' when (Sstate = LATCHADDR) else '0';
start_write <= '1' when (Sstate = WRITEDATA) else '0';
start_read <= '1' when (Sstate = READDATA) else '0';


controller_ready <= '0' when (Mstate /= IDLE) else '1';


status_register(0) <= controller_ready;
status_register(1) <= done;

BRAM_enable <= '1' when (wait_counter = 1 and (re_n = '0' xor w_we_n = '0')) else '0';

MASTER_FSM : process(clk, ctrl_register)
begin
    if(ctrl_register(0) = '0' and done = '1') then
        done <= '0';
    elsif(rising_edge(clk) and ctrl_register(0) = '1' and done = '0') then
        case Mstate is 
        
            when IDLE =>
                if(wait_done = '1') then
                    done <= '1';
                    wait_done <= '0';
                elsif(cmd_register(0) = '1') then
                    Mstate <= RESET;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                elsif(cmd_register(1) = '1') then
                    Mstate <= READID;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                elsif(cmd_register(2) = '1') then
                    Mstate <= READPARAM;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                elsif(cmd_register(3) = '1') then
                    Mstate <= READSTATUS;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                elsif(cmd_register(4) = '1') then
                    Mstate <= READ;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                elsif(cmd_register(5) = '1') then
                    Mstate <= PAGEPROGRAM;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                elsif(cmd_register(6) = '1') then
                    Mstate <= ERASE;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0';
                elsif(cmd_register(7) = '1') then
                    Mstate <= SETFEATURES;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0';
                elsif(cmd_register(8) = '1') then
                    Mstate <= GETFEATURES;
                    Sstate <= LATCHCMD;
                    status_register(30) <= '0'; 
                else
                    status_register(30) <= '1'; 
                end if;
                
            when RESET =>
                cmd_in <= x"FF";
                if(counter = 0) then
                    counter <= 1;       -- wait one clk cycle to load cmd in data
                else
                    counter <= 0;
                    Mstate <= SUBWAIT;
                    delay_t <= CMDWAIT;
                    PreviousMstate <= IDLE;
                    NextSstate <= subIDLE;
                end if; 
                
            when READID =>
                cmd_in <= x"90";
                addr_in <= x"20";
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
                cmd_in <= x"EC";
                addr_in <= x"00";
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
                    if(ready_busy = '1' and ready_counter = 1) then
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
                    elsif(ready_busy /= '1' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when READSTATUS => 
                cmd_in <= x"70";
                if(Sstate = LATCHCMD) then
                    delay_t <= CMDWAIT;
                    PreviousMstate <= Mstate;
                    NextSstate <= READDATA;
                    Mstate <= SUBWAIT;
                elsif(Sstate = READDATA) then
                    if(ready_busy = '1' and ready_counter = 1) then
                        ready_counter <= 0;
                        delay_t <= READWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    elsif(ready_busy /= '1' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when PAGEPROGRAM =>
                cmd_in <= x"80";
                if(Sstate = LATCHCMD) then
                    if(counter = 1) then
                        counter <= 0;
                        cmd_in <= x"10";
                        delay_t <= WRITEDONE;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE;
                        Mstate <= SUBWAIT;
                    elsif(counter = 0) then
                        cmd_in <= x"80";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHADDR;
                        Mstate <= SUBWAIT;
                        counter <= 1;
                    end if;
                elsif(Sstate = LATCHADDR) then 
                    if(address_cycle_count = 0) then
                        addr_in <= addr_register(7 downto 0);
                    elsif(address_cycle_count = 1) then
                        addr_in <= addr_register(15 downto 8);
                    elsif(address_cycle_count = 2) then
                        addr_in <= addr_register (23 downto 16);
                    elsif(address_cycle_count = 3) then
                       addr_in <= addr_register(31 downto 24);
                    elsif(address_cycle_count = 4) then
                        addr_in <= addr_bis_register(7 downto 0);
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
                    if(read_cycle_count = 2048 * TO_INTEGER(unsigned(cmd_register(18 downto 15)))) then
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
                cmd_in <= x"00";
                if(Sstate = LATCHCMD) then
                    if(counter = 1) then
                        counter <= 0;
                        cmd_in <= x"30";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= READDATA; 
                        Mstate <= SUBWAIT;
                    elsif(counter = 0) then
                        cmd_in <= x"00";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= Mstate;
                        NextSstate <= LATCHADDR;
                        Mstate <= SUBWAIT;
                        counter <= 1;
                    end if;
                elsif(Sstate = LATCHADDR) then
                    if(address_cycle_count = 0) then
                        addr_in <= addr_register(7 downto 0);
                    elsif(address_cycle_count = 1) then
                        addr_in <= addr_register(15 downto 8);
                    elsif(address_cycle_count = 2) then
                        addr_in <= addr_register (23 downto 16);
                    elsif(address_cycle_count = 3) then
                       addr_in <= addr_register(31 downto 24);
                    elsif(address_cycle_count = 4) then
                        addr_in <= addr_bis_register(7 downto 0);
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
                    if(ready_busy /= '0' and ready_counter = 1) then
                        if(read_cycle_count = 2048 * TO_INTEGER(unsigned(cmd_register(18 downto 15)))) then
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
                    elsif(ready_busy = '0' and ready_counter = 0) then
                        ready_counter <= 1;
                    end if;
                end if;
                
            when ERASE =>
                cmd_in <= x"60";
                addr_in <= addr_register(7 downto 0);
                if(Sstate = LATCHCMD) then
                    if(counter = 1) then
                        counter <= 0;
                        cmd_in <= x"D0";
                        delay_t <= CMDWAIT;
                        PreviousMstate <= IDLE;
                        NextSstate <= subIDLE; 
                        Mstate <= SUBWAIT;
                    elsif(counter = 0) then
                        cmd_in <= x"60";
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
                cmd_in <= x"EF";
                addr_in <= x"FA";
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
                cmd_in <= x"EE";
                addr_in <= x"FA";
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
                    if(cmd_busy = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(cmd_busy = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = ADDRWAIT) then
                    if(addr_busy = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(addr_busy = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = WRITEWAIT) then
                    if(w_busy = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(w_busy = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = READWAIT) then
                    if(r_busy = '0' and wait_counter = 1) then
                        wait_counter <= 0;
                        wait_done <= '1';
                        Mstate <= PreviousMstate;
                        Sstate <= NextSstate;
                    elsif(r_busy = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                elsif(delay_t = WRITEDONE) then
                    if(cmd_busy = '0' and wait_counter = 1) then   
                        Sstate <= subIDLE;
                        if(counter = t_prog) then
                            counter <= 0;
                            wait_counter <= 0;
                            wait_done <= '1';
                            Mstate <= PreviousMstate;
                            Sstate <= NextSstate;
                        else
                            counter <= counter + 1;
                        end if;
                    elsif(cmd_busy = '1' and wait_counter = 0) then
                        wait_counter <= 1;
                    end if;
                end if;
                
            when others =>
                Mstate <= IDLE;
        end case;
    end if;
end process;

Status_process : process(Mstate, Sstate)
begin
    case Mstate is 
        when IDLE =>
            status_register(28 downto 2) <= (others => '0');
        when RESET =>
            status_register(2) <= '1';          
        when READID =>
            status_register(3) <= '1'; 
        when READPARAM =>
            status_register(4) <= '1';  
        when READSTATUS => 
            status_register(5) <= '1';    
        when PAGEPROGRAM =>
            status_register(6) <= '1';    
        when READ =>
            status_register(7) <= '1';    
        when ERASE =>
            status_register(8) <= '1';
        when SETFEATURES =>
            status_register(9) <= '1';
        when GETFEATURES =>
            status_register(9) <= '1';
        when SUBWAIT =>
            
        when others =>
            status_register(31) <= '1';
    end case;
    case Sstate is
        when SUBIDLE =>
            status_register(13 downto 10) <= (others => '0');
        when LATCHCMD =>
            status_register(13 downto 10) <= "0001";
        when LATCHADDR =>
            status_register(13 downto 10) <= "0010";
        when READDATA =>
            status_register(13 downto 10) <= "0100";
        when WRITEDATA => 
            status_register(13 downto 10) <= "1000";
        when others =>
            status_register(31) <= '1';
    end case;
    if(addr_register(15) /= '0' or addr_bis_register(7) /= '0') then
        status_register(29) <= '1';
    else
        status_register(29) <= '0';
    end if;
end process;

BRAM_process: process(clk, BRAM_enable,Mstate, Sstate, data_a_i)
begin
    if(BRAM_enable = '1') then
        
        if(Sstate = READDATA) then
            write_en_a_o  <= '1';
        else 
            write_en_a_o  <= '0';
        end if;
        clk_a_o <= clk;
        data_a_o <= r_data_out;
        w_data_in <= data_a_i;
        
    elsif( Mstate = IDLE) then
        addr_offset <= 0;
        clk_a_o <= '0';
        write_en_a_o  <= '0';
    end if;
    if rising_edge(BRAM_enable) then
        addr_a_o <= std_logic_vector(to_unsigned(addr_index + addr_offset, addr_a_o'length));
        addr_offset <= addr_offset + 1; 
    end if;
    case cmd_register(11 downto 10) is 
        when "00" =>
            addr_index <= 0;
        when "01" => 
            addr_index <= 16384;
        when "10" =>
            addr_index <= 32768;
        when "11" =>
            addr_index <= 49152;
        when others =>
            addr_index <= 0;
    end case;
end process;

end Behavioral;
