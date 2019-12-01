-- ===================================================================
-- TITLE : Melody Chime / Score Sequencer
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM Works)
--     DATE   : 2012/08/28 -> 2012/08/28
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

entity melodychime_seq is
	generic(
		TEMPO_TC		: integer := 357		-- テンポカウンタ(357ms/Tempo=84) 
	);
	port(
		reset			: in  std_logic;		-- async reset
		clk				: in  std_logic;		-- system clock
		timing_1ms		: in  std_logic;		-- clock enable (1msタイミング,1パルス幅,1アクティブ) 
		tempo_out		: out std_logic;		-- テンポ信号出力 (1パルス幅,1アクティブ)

		test_score_addr	: out std_logic_vector(3 downto 0);

		start			: in  std_logic;		-- '1'パルスで再生開始 

		slot_div		: out std_logic_vector(7 downto 0);		-- スロットの音程データ 
		slot_note		: out std_logic;						-- スロットの発音 
		slot0_wrreq		: out std_logic;		-- スロット０への書き込み要求 
		slot1_wrreq		: out std_logic			-- スロット１への書き込み要求 
	);
end melodychime_seq;

architecture RTL of melodychime_seq is
	constant R		: std_logic_vector(4 downto 0) := "XXXXX";	--	O4G+
	constant O4Gp	: std_logic_vector(4 downto 0) := "00000";	--	O4G+
	constant O4A	: std_logic_vector(4 downto 0) := "00001";	--	O4A
	constant O4Ap	: std_logic_vector(4 downto 0) := "00010";	--	O4A+
	constant O4B	: std_logic_vector(4 downto 0) := "00011";	--	O4B
	constant O5C	: std_logic_vector(4 downto 0) := "00100";	--	O5C
	constant O5Cp	: std_logic_vector(4 downto 0) := "00101";	--	O5C+
	constant O5D	: std_logic_vector(4 downto 0) := "00110";	--	O5D
	constant O5Dp	: std_logic_vector(4 downto 0) := "00111";	--	O5D+
	constant O5E	: std_logic_vector(4 downto 0) := "01000";	--	O5E
	constant O5F	: std_logic_vector(4 downto 0) := "01001";	--	O5F
	constant O5Fp	: std_logic_vector(4 downto 0) := "01010";	--	O5F+
	constant O5G	: std_logic_vector(4 downto 0) := "01011";	--	O5G
	constant O5Gp	: std_logic_vector(4 downto 0) := "01100";	--	O5G+
	constant O5A	: std_logic_vector(4 downto 0) := "01101";	--	O5A
	constant O5Ap	: std_logic_vector(4 downto 0) := "01110";	--	O5A+
	constant O5B	: std_logic_vector(4 downto 0) := "01111";	--	O5B
	constant O6C	: std_logic_vector(4 downto 0) := "10000";	--	O6C
	constant O6Cp	: std_logic_vector(4 downto 0) := "10001";	--	O6C+
	constant O6D	: std_logic_vector(4 downto 0) := "10010";	--	O6D
	constant O6Dp	: std_logic_vector(4 downto 0) := "10011";	--	O6D+
	constant O6E	: std_logic_vector(4 downto 0) := "10100";	--	O6E
	constant O6F	: std_logic_vector(4 downto 0) := "10101";	--	O6F
	constant O6Fp	: std_logic_vector(4 downto 0) := "10110";	--	O6F+
	constant O6G	: std_logic_vector(4 downto 0) := "10111";	--	O6G
	constant O6Gp	: std_logic_vector(4 downto 0) := "11000";	--	O6G+
	constant O6A	: std_logic_vector(4 downto 0) := "11001";	--	O6A
	constant O6Ap	: std_logic_vector(4 downto 0) := "11010";	--	O6A+
	constant O6B	: std_logic_vector(4 downto 0) := "11011";	--	O6B
	constant O7C	: std_logic_vector(4 downto 0) := "11100";	--	O7C
	constant O7Cp	: std_logic_vector(4 downto 0) := "11101";	--	O7C+
	constant O7D	: std_logic_vector(4 downto 0) := "11110";	--	O7D
	constant O7Dp	: std_logic_vector(4 downto 0) := "11111";	--	O7D+

	constant SCORE_WIDTH	: integer := 4;
	constant SCORE_LENGTH	: integer := 2**SCORE_WIDTH;
	constant SLOT_WIDTH		: integer := 1;
	constant SLOT_LENGTH	: integer := 2**SLOT_WIDTH;

	type DEF_SCORE is array(0 to SCORE_LENGTH*SLOT_LENGTH-1) of std_logic_vector(5 downto 0);
	signal score_mem : DEF_SCORE;

	signal tempocount		: integer range 0 to TEMPO_TC-1;
	signal tempo_sig		: std_logic;
	signal start_reg		: std_logic;

	signal scorecount		: integer range 0 to SCORE_LENGTH-1;
	signal play_reg			: std_logic;
	signal tdelay_reg		: std_logic;
	signal slotcount		: integer range 0 to SLOT_LENGTH-1;
	signal slot_reg			: std_logic;

	signal score_reg		: std_logic_vector(5 downto 0);
	signal sqdivref_sig		: integer range 0 to 255;
	signal wrreq_reg		: std_logic_vector(SLOT_LENGTH-1 downto 0);

begin

	test_score_addr <= CONV_std_logic_vector(scorecount, 4);


	-- 楽譜データ 

	score_mem(SCORE_LENGTH*0 + 0)  <= '1' & O6G;
	score_mem(SCORE_LENGTH*0 + 1)  <= '1' & O6Dp;
	score_mem(SCORE_LENGTH*0 + 2)  <= '1' & O5Ap;
	score_mem(SCORE_LENGTH*0 + 3)  <= '1' & O6Dp;
	score_mem(SCORE_LENGTH*0 + 4)  <= '1' & O6F;
	score_mem(SCORE_LENGTH*0 + 5)  <= '1' & O6Ap;
	score_mem(SCORE_LENGTH*0 + 6)  <= '0' & O6Ap;
	score_mem(SCORE_LENGTH*0 + 7)  <= '1' & O5F;
	score_mem(SCORE_LENGTH*0 + 8)  <= '1' & O6F;
	score_mem(SCORE_LENGTH*0 + 9)  <= '1' & O6G;
	score_mem(SCORE_LENGTH*0 + 10) <= '1' & O6F;
	score_mem(SCORE_LENGTH*0 + 11) <= '1' & O5Ap;
	score_mem(SCORE_LENGTH*0 + 12) <= '1' & O6Dp;
	score_mem(SCORE_LENGTH*0 + 13) <= '0' & O6Dp;
	score_mem(SCORE_LENGTH*0 + 14) <= '0' & O6Dp;
	score_mem(SCORE_LENGTH*0 + 15) <= '0' & O6Dp;

	score_mem(SCORE_LENGTH*1 + 0)  <= '0' & R;
	score_mem(SCORE_LENGTH*1 + 1)  <= '0' & R;
	score_mem(SCORE_LENGTH*1 + 2)  <= '1' & O5G;
	score_mem(SCORE_LENGTH*1 + 3)  <= '0' & O5G;
	score_mem(SCORE_LENGTH*1 + 4)  <= '1' & O6D;
	score_mem(SCORE_LENGTH*1 + 5)  <= '0' & O6D;
	score_mem(SCORE_LENGTH*1 + 6)  <= '0' & R;
	score_mem(SCORE_LENGTH*1 + 7)  <= '0' & R;
	score_mem(SCORE_LENGTH*1 + 8)  <= '1' & O5Ap;
	score_mem(SCORE_LENGTH*1 + 9)  <= '0' & O5Ap;
	score_mem(SCORE_LENGTH*1 + 10) <= '1' & O5Ap;
	score_mem(SCORE_LENGTH*1 + 11) <= '0' & O5Ap;
	score_mem(SCORE_LENGTH*1 + 12) <= '1' & O5G;
	score_mem(SCORE_LENGTH*1 + 13) <= '0' & O5G;
	score_mem(SCORE_LENGTH*1 + 14) <= '0' & O5G;
	score_mem(SCORE_LENGTH*1 + 15) <= '0' & O5G;


	-- テンポタイミングおよびスタート信号発生 

	process (clk, reset) begin
		if (reset = '1') then
			tempocount  <= 0;
			start_reg <= '0';

		elsif rising_edge(clk) then
			if (timing_1ms = '1') then
				if (tempocount = 0) then
					tempocount <= TEMPO_TC-1;
				else
					tempocount <= tempocount - 1;
				end if;
			end if;

			if (start = '1') then
				start_reg <= '1';
			elsif (tempo_sig = '1') then
				start_reg <= '0';
			end if;

		end if;
	end process;

	tempo_sig <= '1' when(timing_1ms = '1' and tempocount = 0) else '0';
	tempo_out <= tempo_sig;


	-- スコアシーケンサ 

	process (clk, reset) begin
		if (reset = '1') then
			play_reg   <= '0';
			scorecount <= 0;
			tdelay_reg <= '0';
			slot_reg   <= '0';
			slotcount  <= 0;

		elsif rising_edge(clk) then
			if (tempo_sig = '1') then
				if (start_reg = '1') then
					play_reg <= '1';
					scorecount <= 0;
				elsif (scorecount = SCORE_LENGTH-1) then
					play_reg <= '0';
				elsif (play_reg = '1') then
					scorecount <= scorecount + 1;
				end if;
			end if;

			tdelay_reg <= tempo_sig;

			if (tdelay_reg = '1') then
				slot_reg <= play_reg;
				slotcount <= 0;
			elsif (slotcount = SLOT_LENGTH-1) then
				slot_reg  <= '0';
			else
				slotcount <= slotcount + 1;
			end if;

		end if;
	end process;


	-- 楽譜読み出し 

	process (clk) begin
		if rising_edge(clk) then
			score_reg <= score_mem( slotcount*SCORE_LENGTH + scorecount );
		end if;
	end process;

	process (clk, reset) begin
		if (reset = '1') then
			wrreq_reg <= (others=>'0');

		elsif rising_edge(clk) then
			for i in 0 to SLOT_LENGTH-1 loop
				if (i = slotcount) then
					wrreq_reg(i) <= slot_reg;
				else
					wrreq_reg(i) <= '0';
				end if;
			end loop;

		end if;
	end process;


	-- 音階データ→分周値変換 

	with score_reg(4 downto 0) select sqdivref_sig <=
		241-1	when O4Gp,	--	O4G+	207.652Hz
		227-1	when O4A,	--	O4A		220.000Hz
		215-1	when O4Ap,	--	O4A+	233.082Hz
		202-1	when O4B,	--	O4B		246.942Hz
		191-1	when O5C,	--	O5C		261.626Hz
		180-1	when O5Cp,	--	O5C+	277.183Hz
		170-1	when O5D,	--	O5D		293.665Hz
		161-1	when O5Dp,	--	O5D+	311.127Hz
		152-1	when O5E,	--	O5E		329.628Hz
		143-1	when O5F,	--	O5F		349.228Hz
		135-1	when O5Fp,	--	O5F+	369.994Hz
		128-1	when O5G,	--	O5G		391.995Hz
		120-1	when O5Gp,	--	O5G+	415.305Hz
		114-1	when O5A,	--	O5A		440.000Hz
		107-1	when O5Ap,	--	O5A+	466.164Hz
		101-1	when O5B,	--	O5B		493.883Hz
		96-1	when O6C,	--	O6C		523.251Hz
		90-1	when O6Cp,	--	O6C+	554.365Hz
		85-1	when O6D,	--	O6D		587.330Hz
		80-1	when O6Dp,	--	O6D+	622.254Hz
		76-1	when O6E,	--	O6E		659.255Hz
		72-1	when O6F,	--	O6F		698.456Hz
		68-1	when O6Fp,	--	O6F+	739.989Hz
		64-1	when O6G,	--	O6G		783.991Hz
		60-1	when O6Gp,	--	O6G+	830.609Hz
		57-1	when O6A,	--	O6A		880.000Hz
		54-1	when O6Ap,	--	O6A+	932.328Hz
		51-1	when O6B,	--	O6B		987.767Hz
		48-1	when O7C,	--	O7C		1046.502Hz
		45-1	when O7Cp,	--	O7C+	1108.731Hz
		43-1	when O7D,	--	O7D		1174.659Hz
		40-1	when O7Dp;	--	O7D+	1244.508Hz


	-- スロット制御信号出力 

	slot_div  <= CONV_std_logic_vector(sqdivref_sig, 8);
	slot_note <= score_reg(5);

	slot0_wrreq <= wrreq_reg(0);
	slot1_wrreq <= wrreq_reg(1);


end RTL;
