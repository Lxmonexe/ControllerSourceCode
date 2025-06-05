library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_top is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
		-- Users to add ports here
		clk : in std_logic;
		rst : in std_logic;
        --nand_ce_n : out std_logic;
        --nand_cle : out std_logic;
        --nand_ale : out std_logic;
        --nand_we_n : out std_logic;
        --nand_re_n : out std_logic;
        --nand_wp_n : out std_logic;
        --nand_data : inout std_logic_vector(7 downto 0);
        --nand_rb_n : in std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axi_top;

architecture arch_imp of axi_top is

	-- component declaration
	component Axi_top_slave_lite_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		
		clk : in std_logic;
		
		nand_ce_n : out std_logic;
        nand_cle : out std_logic;
        nand_ale : out std_logic;
        nand_we_n : out std_logic;
        nand_re_n : out std_logic;
        nand_wp_n : out std_logic;
        nand_data : inout std_logic_vector(7 downto 0);
        nand_rb_n : in std_logic
		);
	end component Axi_top_slave_lite_v1_0_S00_AXI;

component nand_model 
port (
    Dq_Io : inout std_logic_vector(7 downto 0);
    Dqs : inout std_logic;
    Cle : in std_logic;
    Ale : in std_logic;
    Ce_n : in std_logic;
    Clk_We_n : in std_logic;
    Wr_Re_n : in std_logic;
    Wp_n : in std_logic;
    Rb_n : out std_logic      
);
end component;

signal nand_data : std_logic_vector(7 downto 0);
signal nand_dqs : std_logic := '1'; --interface synchrone
signal nand_cle, nand_ale : std_logic ;
signal nand_ce_n, nand_we_n, nand_re_n : std_logic;
signal nand_wp_n : std_logic;
signal nand_rb_n : std_logic;

begin

-- Instantiation of Axi Bus Interface S00_AXI
Axi_top_slave_lite_v1_0_S00_AXI_inst : Axi_top_slave_lite_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready,
		clk => clk,
		nand_ce_n => nand_ce_n,
        nand_cle => nand_cle,
        nand_ale => nand_ale,
        nand_we_n => nand_we_n,   
        nand_re_n => nand_re_n,
        nand_wp_n => nand_wp_n,
        nand_data => nand_data,
        nand_rb_n => nand_rb_n
	);

	-- Add user logic here
nandmodel: nand_model port map
(
    Dq_Io => nand_data,
    Dqs => nand_dqs,
    Cle => nand_cle,
    Ale => nand_ale,
    Ce_n => nand_ce_n,
    Clk_We_n => nand_we_n,
    Wr_Re_n => nand_re_n,
    Wp_n => nand_wp_n,
    Rb_n => nand_rb_n 
);
	-- User logic ends

end arch_imp;
