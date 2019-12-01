-- ===================================================================
-- TITLE : Melody Chime
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM Works)
--     DATE   : 2012/08/17 -> 2012/08/28
--            : 2012/08/28 (FIXED)
--
--     UPDATE : 2018/11/26
-- ===================================================================

-- The MIT License (MIT)
-- Copyright (c) 2012,2018 J-7SYSTEM WORKS LIMITED.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity melodychime is
	generic(
--		CLOCK_FREQ_HZ	: integer := 50000000
		CLOCK_FREQ_HZ	: integer := 24000000
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		start		: in  std_logic;		-- play start(0→1 : start)

		timing_1ms	: out std_logic;
		tempo_led	: out std_logic;
		aud_out		: out std_logic
	);
end melodychime;

architecture RTL of melodychime is
	constant VALUE_TEMPO_TC		: integer := 357;		-- テンポカウンタ(357ms/Tempo=84) 
	constant VALUE_ENVELOPE_TC	: integer := 28000;		-- エンベロープ時定数(一次遅れ系,t=0.5秒)

	constant CLOCKDIV_NUM		: integer := CLOCK_FREQ_HZ/100000;
	signal count10us		: integer range 0 to CLOCKDIV_NUM-1;
	signal count1ms			: integer range 0 to 99;
	signal timing_10us_reg	: std_logic;
	signal timing_1ms_reg	: std_logic;
	signal tempo_led_reg	: std_logic;

	signal start_in_reg		: std_logic_vector(1 downto 0);
	signal start_sig		: std_logic;


	component melodychime_seq
	generic(
		TEMPO_TC		: integer
	);
	port(
		reset			: in  std_logic;
		clk				: in  std_logic;
		timing_1ms		: in  std_logic;
		tempo_out		: out std_logic;

		test_score_addr	: out std_logic_vector(3 downto 0);

		start			: in  std_logic;

		slot_div		: out std_logic_vector(7 downto 0);
		slot_note		: out std_logic;
		slot0_wrreq		: out std_logic;
		slot1_wrreq		: out std_logic	
	);
	end component;
	signal tempo_sig		: std_logic;
	signal slot_div_sig		: std_logic_vector(7 downto 0);
	signal slot_note_sig	: std_logic;
	signal slot0_wrreq_sig	: std_logic;
	signal slot1_wrreq_sig	: std_logic;


	component melodychime_sg
	generic(
		ENVELOPE_TC		: integer
	);
	port(
		reset			: in  std_logic;
		clk				: in  std_logic;
		reg_div			: in  std_logic_vector(7 downto 0);
		reg_note		: in  std_logic;
		reg_write		: in  std_logic;

		timing_10us		: in  std_logic;
		timing_1ms		: in  std_logic;

		wave_out		: out std_logic_vector(15 downto 0)
	);
	end component;
	signal slot0_wav_sig	: std_logic_vector(15 downto 0);
	signal slot1_wav_sig	: std_logic_vector(15 downto 0);


	signal wav_add_sig		: std_logic_vector(9 downto 0);
	signal pcm_sig			: std_logic_vector(9 downto 0);
	signal add_sig			: std_logic_vector(pcm_sig'left+1 downto 0);
	signal dse_reg			: std_logic_vector(add_sig'left-1 downto 0);
	signal dacout_reg		: std_logic;

begin

	-- タイミングパルス生成 

	process (clk, reset) begin
		if (reset = '1') then
			count10us <= 0;
			count1ms  <= 0;
			timing_10us_reg <= '0';
			timing_1ms_reg  <= '0';
			tempo_led_reg   <= '0';

		elsif rising_edge(clk) then
			if (count10us = 0) then
				count10us <= CLOCKDIV_NUM-1;
				if (count1ms = 0) then
					count1ms <= 99;
				else 
					count1ms <= count1ms - 1;
				end if;
			else
				count10us <= count10us - 1;
			end if;

			if (count10us = 0) then
				timing_10us_reg <= '1';
			else 
				timing_10us_reg <= '0';
			end if;

			if (count10us = 0 and count1ms = 0) then
				timing_1ms_reg <= '1';
			else 
				timing_1ms_reg <= '0';
			end if;

			if (tempo_sig = '1') then
				tempo_led_reg <= not tempo_led_reg;
			end if;

		end if;
	end process;

	timing_1ms <= timing_1ms_reg;
	tempo_led <= tempo_led_reg;


	-- スタート信号入力 

	process (clk, reset) begin
		if (reset = '1') then
			start_in_reg <= "00";

		elsif rising_edge(clk) then
			start_in_reg <= start_in_reg(0) & start;

		end if;
	end process;

	start_sig <= '1' when(start_in_reg(1 downto 0) = "01") else '0';


	-- シーケンサインスタンス 

	U_SEQ : melodychime_seq
	generic map (
		TEMPO_TC		=> VALUE_TEMPO_TC
	)
	port map (
		reset			=> reset,
		clk				=> clk,
		timing_1ms		=> timing_1ms_reg,
		tempo_out		=> tempo_sig,
		start			=> start_sig,

		slot_div		=> slot_div_sig,
		slot_note		=> slot_note_sig,
		slot0_wrreq		=> slot0_wrreq_sig,
		slot1_wrreq		=> slot1_wrreq_sig
	);


	-- 音源スロットインスタンス 

	U_SG0 : melodychime_sg
	generic map (
		ENVELOPE_TC		=> VALUE_ENVELOPE_TC
	)
	port map (
		reset			=> reset,
		clk				=> clk,
		reg_div			=> slot_div_sig,
		reg_note		=> slot_note_sig,
		reg_write		=> slot0_wrreq_sig,

		timing_10us		=> timing_10us_reg,
		timing_1ms		=> timing_1ms_reg,

		wave_out		=> slot0_wav_sig
	);

	U_SG1 : melodychime_sg
	generic map (
		ENVELOPE_TC		=> VALUE_ENVELOPE_TC
	)
	port map (
		reset			=> reset,
		clk				=> clk,
		reg_div			=> slot_div_sig,
		reg_note		=> slot_note_sig,
		reg_write		=> slot1_wrreq_sig,

		timing_10us		=> timing_10us_reg,
		timing_1ms		=> timing_1ms_reg,

		wave_out		=> slot1_wav_sig
	);


	-- 波形加算と1bitDSM-DAC

	wav_add_sig <= (slot0_wav_sig(15) & slot0_wav_sig(15 downto 7)) + (slot1_wav_sig(15) & slot1_wav_sig(15 downto 7));

	pcm_sig(9) <= not wav_add_sig(9);
	pcm_sig(8 downto 0) <= wav_add_sig(8 downto 0);

	add_sig <= ('0' & pcm_sig) + ('0' & dse_reg);

	process (clk, reset) begin
		if (reset = '1') then
			dse_reg    <= (others=>'0');
			dacout_reg <= '0';

		elsif rising_edge(clk) then
			dse_reg    <= add_sig(add_sig'left-1 downto 0);
			dacout_reg <= add_sig(add_sig'left);

		end if;
	end process;

	aud_out <= dacout_reg;



end RTL;
