-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 Rick Wertenbroek <rick.wertenbroek@gmail.com>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright notice,
-- this list of conditions and the following disclaimer in the documentation
-- and/or other materials provided with the distribution.
--
-- 3. Neither the name of the copyright holder nor the names of its
-- contributors may be used to endorse or promote products derived from this
-- software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-------------------------------------------------------------------------------
-- File         : true_dual_port_bram.vhd
-- Description  : This is a true dual port bram described in VHDL (can have
--                asymmetric ports).
--
-- Author       : Rick Wertenbroek
-- Version      : 0.1
--
-- VHDL std     : 2008
-- Dependencies : log_pkg.vhd
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.log_pkg.all;

entity true_dual_port_bram is
    generic (
        WIDTH_PORT_A : natural := 8;
        DEPTH_PORT_A : natural := 1024;
        ADDR_WIDTH_A : natural := ilogup(DEPTH_PORT_A);
        WIDTH_PORT_B : natural := 16;
        DEPTH_PORT_B : natural := DEPTH_PORT_A * WIDTH_PORT_A / WIDTH_PORT_B;
        ADDR_WIDTH_B : natural := ilogup(DEPTH_PORT_B)
        );
    port (
        clk_a_i      : in  std_logic;
        write_en_a_i : in  std_logic;
        addr_a_i     : in  std_logic_vector(ADDR_WIDTH_A-1 downto 0);
        data_a_i     : in  std_logic_vector(WIDTH_PORT_A-1 downto 0);
        data_a_o     : out std_logic_vector(WIDTH_PORT_A-1 downto 0);
        clk_b_i      : in  std_logic;
        write_en_b_i : in  std_logic;
        addr_b_i     : in  std_logic_vector(ADDR_WIDTH_B-1 downto 0);
        data_b_i     : in  std_logic_vector(WIDTH_PORT_B-1 downto 0);
        data_b_o     : out std_logic_vector(WIDTH_PORT_B-1 downto 0)
        );
end entity true_dual_port_bram;

architecture rtl of true_dual_port_bram is

    ---------------
    -- Constants --
    ---------------
    constant MIN_WIDTH : natural := minimum(WIDTH_PORT_A, WIDTH_PORT_B);
    constant MAX_WIDTH : natural := maximum(WIDTH_PORT_A, WIDTH_PORT_B);
    constant MAX_DEPTH : natural := maximum(DEPTH_PORT_A, DEPTH_PORT_B);
    constant RATIO     : natural := MAX_WIDTH / MIN_WIDTH;

    -----------
    -- Types --
    -----------
    type bram_t is array (0 to MAX_DEPTH-1) of std_logic_vector(MIN_WIDTH-1 downto 0);

    -------------
    -- Signals --
    -------------
    signal bram_s : bram_t;

begin

    -- GENERATE WIDTH A < WIDTH B
    asymmetry_gen :
    if WIDTH_PORT_A < WIDTH_PORT_B generate

        process(clk_a_i) is
        begin
            if rising_edge(clk_a_i) then
                if write_en_a_i = '1' then
                    bram_s(to_integer(unsigned(addr_a_i))) <= data_a_i;
                end if;
                data_a_o <= bram_s(to_integer(unsigned(addr_a_i)));
            end if;
        end process;

        process(clk_b_i) is
        begin
            if rising_edge(clk_b_i) then
                for i in 0 to RATIO-1 loop
                    if write_en_b_i = '1' then
                        bram_s(to_integer(unsigned(addr_b_i) & to_unsigned(i, ilogup(RATIO)))) <= data_b_i((i+1)*MIN_WIDTH-1 downto i*MIN_WIDTH);
                    end if;
                    data_b_o((i+1)*MIN_WIDTH-1 downto i*MIN_WIDTH) <= bram_s(to_integer(unsigned(addr_b_i) & to_unsigned(i, ilogup(RATIO))));
                end loop;
            end if;
        end process;

    -- GENERATE SYMMETRICAL BRAM
    elsif WIDTH_PORT_A = WIDTH_PORT_B generate

        process(clk_a_i) is
        begin
            if rising_edge(clk_a_i) then
                if write_en_a_i = '1' then
                    bram_s(to_integer(unsigned(addr_a_i))) <= data_a_i;
                end if;
                data_a_o <= bram_s(to_integer(unsigned(addr_a_i)));
            end if;
        end process;

        process(clk_b_i) is
        begin
            if rising_edge(clk_b_i) then
                if write_en_b_i = '1' then
                    bram_s(to_integer(unsigned(addr_b_i))) <= data_b_i;
                end if;
                data_b_o <= bram_s(to_integer(unsigned(addr_b_i)));
            end if;
        end process;

    -- GENERATE WIDTH B < WIDTH A
    else generate

        process(clk_b_i) is
        begin
            if rising_edge(clk_b_i) then
                if write_en_b_i = '1' then
                    bram_s(to_integer(unsigned(addr_b_i))) <= data_b_i;
                end if;
                data_b_o <= bram_s(to_integer(unsigned(addr_b_i)));
            end if;
        end process;

        process(clk_a_i) is
        begin
            if rising_edge(clk_a_i) then
                for i in 0 to RATIO-1 loop
                    if write_en_a_i = '1' then
                        bram_s(to_integer(unsigned(addr_a_i) & to_unsigned(i, ilogup(RATIO)))) <= data_a_i((i+1)*MIN_WIDTH-1 downto i*MIN_WIDTH);
                    end if;
                    data_a_o((i+1)*MIN_WIDTH-1 downto i*MIN_WIDTH) <= bram_s(to_integer(unsigned(addr_a_i) & to_unsigned(i, ilogup(RATIO))));
                end loop;
            end if;
        end process;

    end generate;

end rtl;
