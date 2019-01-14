----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/14/2018 05:22:37 PM
-- Design Name: 
-- Module Name: forecast - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity forecast is
    Port ( 
           l,w : in std_logic_vector(7 downto 0);
				bluePlayer: in boolean;
				new_message_in: in std_logic;
				new_message_out: out std_logic;
           ready : in std_logic_vector(1 downto 0);
           message : in std_logic_vector(7 downto 0);
           edge : out std_logic_vector(7 downto 0);
           clk : in std_logic;
           rst : in std_logic;
		     state_out: out std_logic_vector(23 downto 0)
           );
end forecast;

architecture Behavioral of forecast is

component mem is port
	(
		aclr		: IN STD_LOGIC  := '0';
		address_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rden_a		: IN STD_LOGIC  := '1';
		rden_b		: IN STD_LOGIC  := '1';
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component mem_32bit is port
	(
		aclr		: IN STD_LOGIC  := '0';
		address_a		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rden_a		: IN STD_LOGIC  := '1';
		rden_b		: IN STD_LOGIC  := '1';
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;

component mem_1bit is port(
		aclr		: IN STD_LOGIC  := '0';
		address_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
		rden_a		: IN STD_LOGIC  := '1';
		rden_b		: IN STD_LOGIC  := '1';
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
end component;

component timer is
generic(ClockFrequencyHz : integer);
port(
    Clk     : in std_logic;
    nRst    : in std_logic; -- Negative reset
    Seconds : inout integer);
end component;

signal gameIsInitialized, positionIsInitialized: boolean := false;

signal curx : integer;
signal cury: integer;

constant ClockFrequencyHz: integer := 50000000;

constant start : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00000000001";
constant moves : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00000000010";
constant finish : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00000000100";
constant finish2 : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00000001000";
constant finish3 : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00000010000";
constant minimax : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00000100000";
constant initialize_ram : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00001000000";
constant wait_one_clk : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00010000000";
constant minimax_compliment : STD_LOGIC_VECTOR (10 DOWNTO 0) := "00100000000";
constant load_loopInfo : STD_LOGIC_VECTOR (10 DOWNTO 0) := "01000000000";
constant deepen_minimax : STD_LOGIC_VECTOR (10 DOWNTO 0) := "10000000000";
signal cur, return_state : STD_LOGIC_VECTOR (10 DOWNTO 0) :=start;

signal stackIsInitialized, write_phase, write_phase_test: boolean := false;

type loopInfo_rec is record
	maximizingPlayer, firstMoveBeing, all_neighbors_checked: boolean;
	maxValue: signed (31 downto 0);
	minValue: signed (31 downto 0);
	neighborIndex: integer;
	i, j: integer;
	depth: std_logic_vector(7 downto 0);
	returnValue: signed (31 downto 0);
	ram_content: std_logic_vector(7 downto 0);
end record;



signal all_neighbors_checked , do_once: boolean := false;
signal sequencePointer: integer;
signal stackPointer1, stackPointer2: integer := 0;
signal initial_depth: std_logic_vector(7 downto 0) := "00000001";
signal best_score_ever, best_score_ever_final: signed (31 downto 0);

signal neighbor_i, neighbor_j, temp_int: integer;
signal tempValue_sig: signed (31 downto 0);
signal i, j: integer := 0;

signal temp_message: std_logic_vector(7 downto 0) := "00000000";

type integer_sequence is array (0 to 333) of integer range 0 to 15;
signal best_moveSequence_final, best_moveSequence, temp_moveSequence: integer_sequence;

--playGround memory signals
signal pg_address_a, pg_address_b: std_logic_vector(15 downto 0);
signal pg_data_a, pg_data_b, pg_q_a, pg_q_b: std_logic_vector(7 downto 0);
signal pg_rden_a, pg_rden_b, pg_wren_a, pg_wren_b, pg_aclr: std_logic;
--maximizingPlayer memory signals
signal mp_address_a, mp_address_b: std_logic_vector(15 downto 0);
signal mp_data_a, mp_data_b, mp_q_a, mp_q_b: std_logic_vector(0 downto 0);
signal mp_rden_a, mp_rden_b, mp_wren_a, mp_wren_b, mp_aclr: std_logic;
--firstMoveBeing memory signals
signal fm_address_a, fm_address_b: std_logic_vector(15 downto 0);
signal fm_data_a, fm_data_b, fm_q_a, fm_q_b: std_logic_vector(0 downto 0);
signal fm_rden_a, fm_rden_b, fm_wren_a, fm_wren_b, fm_aclr: std_logic;
--all_neighbors_checked memory signals
signal an_address_a, an_address_b: std_logic_vector(15 downto 0);
signal an_data_a, an_data_b, an_q_a, an_q_b: std_logic_vector(0 downto 0);
signal an_rden_a, an_rden_b, an_wren_a, an_wren_b, an_aclr: std_logic;
--neighborIndex memory signals
signal ni_address_a, ni_address_b: std_logic_vector(15 downto 0);
signal ni_data_a, ni_data_b, ni_q_a, ni_q_b: std_logic_vector(7 downto 0);
signal ni_rden_a, ni_rden_b, ni_wren_a, ni_wren_b, ni_aclr: std_logic;
--depth_array memory signals
signal da_address_a, da_address_b: std_logic_vector(15 downto 0);
signal da_data_a, da_data_b, da_q_a, da_q_b: std_logic_vector(7 downto 0);
signal da_rden_a, da_rden_b, da_wren_a, da_wren_b, da_aclr: std_logic;
--maxValue memory signals
signal max_address_a, max_address_b: std_logic_vector(8 downto 0);
signal max_data_a, max_data_b, max_q_a, max_q_b: std_logic_vector(31 downto 0);
signal max_rden_a, max_rden_b, max_wren_a, max_wren_b, max_aclr: std_logic;
--minValue memory signals
signal min_address_a, min_address_b: std_logic_vector(8 downto 0);
signal min_data_a, min_data_b, min_q_a, min_q_b: std_logic_vector(31 downto 0);
signal min_rden_a, min_rden_b, min_wren_a, min_wren_b, min_aclr: std_logic;
--i_array memory signals
signal ia_address_a, ia_address_b: std_logic_vector(15 downto 0);
signal ia_data_a, ia_data_b, ia_q_a, ia_q_b: std_logic_vector(7 downto 0);
signal ia_rden_a, ia_rden_b, ia_wren_a, ia_wren_b, ia_aclr: std_logic;
--j_array memory signals
signal ja_address_a, ja_address_b: std_logic_vector(15 downto 0);
signal ja_data_a, ja_data_b, ja_q_a, ja_q_b: std_logic_vector(7 downto 0);
signal ja_rden_a, ja_rden_b, ja_wren_a, ja_wren_b, ja_aclr: std_logic;
--returnValue memory signals
signal rv_address_a, rv_address_b: std_logic_vector(8 downto 0);
signal rv_data_a, rv_data_b, rv_q_a, rv_q_b: std_logic_vector(31 downto 0);
signal rv_rden_a, rv_rden_b, rv_wren_a, rv_wren_b, rv_aclr: std_logic;

type queue_type is array (0 to 333) of std_logic_vector(7 downto 0);
signal queue: queue_type;
signal head, tail, index: integer;
signal timerReset, t1,t2,t3: std_logic := '0';
signal seconds: integer;
signal doOnce2, deepening_phase: boolean := false;

begin


memory_inst1 : mem PORT MAP (aclr => pg_aclr, address_a => pg_address_a, address_b	=> pg_address_b, clock => clk, data_a	=> pg_data_a, data_b => pg_data_b, 
								rden_a => pg_rden_a, rden_b => pg_rden_b, wren_a => pg_wren_a, wren_b => pg_wren_b, q_a => pg_q_a, q_b => pg_q_b);
memory_inst2 : mem_1bit PORT MAP (aclr => mp_aclr, address_a => mp_address_a, address_b	=> mp_address_b, clock => clk, data_a	=> mp_data_a, data_b => mp_data_b, 
								rden_a => mp_rden_a, rden_b => mp_rden_b, wren_a => mp_wren_a, wren_b => mp_wren_b, q_a => mp_q_a, q_b => mp_q_b);
memory_inst3 : mem_1bit PORT MAP (aclr => fm_aclr, address_a => fm_address_a, address_b	=> fm_address_b, clock => clk, data_a	=> fm_data_a, data_b => fm_data_b, 
								rden_a => fm_rden_a, rden_b => fm_rden_b, wren_a => fm_wren_a, wren_b => fm_wren_b, q_a => fm_q_a, q_b => fm_q_b);
memory_inst4 : mem_1bit PORT MAP (aclr => an_aclr, address_a => an_address_a, address_b	=> an_address_b, clock => clk, data_a	=> an_data_a, data_b => an_data_b, 
								rden_a => an_rden_a, rden_b => an_rden_b, wren_a => an_wren_a, wren_b => an_wren_b, q_a => an_q_a, q_b => an_q_b);
memory_inst5 : mem PORT MAP (aclr => ni_aclr, address_a => ni_address_a, address_b	=> ni_address_b, clock => clk, data_a	=> ni_data_a, data_b => ni_data_b, 
								rden_a => ni_rden_a, rden_b => ni_rden_b, wren_a => ni_wren_a, wren_b => ni_wren_b, q_a => ni_q_a, q_b => ni_q_b);
memory_inst6 : mem PORT MAP (aclr => da_aclr, address_a => da_address_a, address_b	=> da_address_b, clock => clk, data_a	=> da_data_a, data_b => da_data_b, 
								rden_a => da_rden_a, rden_b => da_rden_b, wren_a => da_wren_a, wren_b => da_wren_b, q_a => da_q_a, q_b => da_q_b);
memory_inst7 : mem_32bit PORT MAP (aclr => max_aclr, address_a => max_address_a, address_b	=> max_address_b, clock => clk, data_a	=> max_data_a, data_b => max_data_b, 
								rden_a => max_rden_a, rden_b => max_rden_b, wren_a => max_wren_a, wren_b => max_wren_b, q_a => max_q_a, q_b => max_q_b);
memory_inst8 : mem_32bit PORT MAP (aclr => min_aclr, address_a => min_address_a, address_b	=> min_address_b, clock => clk, data_a	=> min_data_a, data_b => min_data_b, 
								rden_a => min_rden_a, rden_b => min_rden_b, wren_a => min_wren_a, wren_b => min_wren_b, q_a => min_q_a, q_b => min_q_b);
memory_inst9 : mem PORT MAP (aclr => ia_aclr, address_a => ia_address_a, address_b	=> ia_address_b, clock => clk, data_a	=> ia_data_a, data_b => ia_data_b, 
								rden_a => ia_rden_a, rden_b => ia_rden_b, wren_a => ia_wren_a, wren_b => ia_wren_b, q_a => ia_q_a, q_b => ia_q_b);
memory_inst10 : mem PORT MAP (aclr => ja_aclr, address_a => ja_address_a, address_b	=> ja_address_b, clock => clk, data_a	=> ja_data_a, data_b => ja_data_b, 
								rden_a => ja_rden_a, rden_b => ja_rden_b, wren_a => ja_wren_a, wren_b => ja_wren_b, q_a => ja_q_a, q_b => ja_q_b);
memory_inst11 : mem_32bit PORT MAP (aclr => rv_aclr, address_a => rv_address_a, address_b	=> rv_address_b, clock => clk, data_a	=> rv_data_a, data_b => rv_data_b, 
								rden_a => rv_rden_a, rden_b => rv_rden_b, wren_a => rv_wren_a, wren_b => rv_wren_b, q_a => rv_q_a, q_b => rv_q_b);
								
i_Timer : timer generic map(ClockFrequencyHz => ClockFrequencyHz)
    port map (Clk => Clk, nRst => timerReset, Seconds => Seconds);
        
receiver2:process(clk)
variable vcurw , vcurl , vnextw , vnextl: integer;
variable dont_reload_loopInfo: boolean := false;
variable loopInfo: loopInfo_rec;
variable wasAjoint2: boolean := false;
variable tempValue_var: signed (31 downto 0);
variable quitProcess, thereWasANeighbor: boolean := false;
variable temp_ram_value, temp_ram_value2, tempstdlogic: std_logic_vector(7 downto 0) := "00000000";
variable test_var1: boolean := false;
begin
		if (rising_edge(clk)) then
		
			state_out(16 downto 6) <= cur;
			
			if ready ="11" and not do_once then 
				do_once <= true;
				state_out <=(others => '0');
				
			end if;
			if (rst = '1') then
				cur <= start;
				gameIsInitialized <= false;
				positionIsInitialized <= false;
				stackIsInitialized <= false;
				write_phase <= false;
				write_phase_test <= false;
				stackPointer1 <= 0;
				stackPointer2 <= 0;
				initial_depth <= "00000001";
				i <= 0;
				j <= 0;
				temp_message <= "00000000";
				index <= 0;
				timerReset <= '0';
			else
				
				case cur is
				
					when start =>
						--state_out(0) <= '1';
						initial_depth <= "00000001";
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						new_message_out <= '0';
						if (not positionIsInitialized  and ready = "11") then
							curx <= to_integer(unsigned(w))/2;
							cury <= to_integer(unsigned(l))/2;
							positionIsInitialized <= true;
						end if;
						if new_message_in = '1' then
							if message = "01111011" then --{
								timerReset <= '1';
								cur <= moves;
								-- making one clock delay before reading next character
								write_phase <= true;
								temp_message <= "00000000";
								head <= 0;
								tail <= 1;
								state_out <=(others => '0');
							else
								cur <= start;
							end if;
						end if;
						
						
					when moves =>
						timerReset <= '0';
						--state_out(1) <= '1';
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						
						if (new_message_in = '1') then
							queue(tail) <= message;
							tail <= tail + 1;
						end if;
						
						if write_phase then
							test_var1 := false;
							
							pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
							case temp_message is
								when "00110000" => ---up
									temp_ram_value := pg_q_a;
									temp_ram_value(0) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(4) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									pg_wren_b <= '1';
									
									cury <= cury-1;
									test_var1 := true;
								when "00110001" => ---up right
									temp_ram_value := pg_q_a;
									temp_ram_value(1) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(5) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									pg_wren_b <= '1';
									
								
									 
									curx <= curx+1;
									cury <= cury -1;
									test_var1 := true;
								when "00110010" => ---right
									temp_ram_value := pg_q_a;
									temp_ram_value(2) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(6) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury, 8));
									pg_wren_b <= '1';
									
									
									 curx <= curx+1;
									test_var1 := true;
								when "00110011" => ---right down
									temp_ram_value := pg_q_a;
									temp_ram_value(3) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(7) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									pg_wren_b <= '1';
									
									
									 curx <= curx+1;
									 cury <= cury +1;
									test_var1 := true;
								when "00110100" => ---down
									temp_ram_value := pg_q_a;
									temp_ram_value(4) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(0) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									pg_wren_b <= '1';
									
									
									 cury <= cury+1;
									test_var1 := true;
								when "00110101" => ---down left
									temp_ram_value := pg_q_a;
									temp_ram_value(5) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(1) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									pg_wren_b <= '1';
									
									
									curx <= curx-1;
									cury <= cury +1;
									test_var1 := true;
								when "00110110" => ---left
									temp_ram_value := pg_q_a;
									temp_ram_value(6) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(2) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury, 8));
									pg_wren_b <= '1';
									
									
									curx <= curx-1;
									test_var1 := true;
								when "00110111" => ---up left
									temp_ram_value := pg_q_a;
									temp_ram_value(7) := '1';
									pg_data_a <= temp_ram_value;
									pg_wren_a <= '1';
									
									temp_ram_value2 := pg_q_b;
									temp_ram_value2(3) := '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									pg_wren_b <= '1';
									
									
									curx <= curx-1;
									cury<=cury -1;
									test_var1 := true;
								when others =>
									cur <= moves;
							end case;  
							write_phase <= false;
							cur <= wait_one_clk;
							return_state <= moves;
							
						else
							if head = tail then
								cur <= moves;
							else
								tempstdlogic := queue(head);
								temp_message <= tempstdlogic;
								head <= head + 1;
								
								pg_rden_a <= '1';
								pg_wren_a <= '0';
								pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
								pg_wren_b <= '0';
								pg_rden_b <= '1';
								case tempstdlogic is
									when "00110000" => ---up
										pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									when "00110001" => ---up right
										pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									when "00110010" => ---right
										pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury, 8));
									when "00110011" => ---right down
										pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									when "00110100" => ---down
										pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									when "00110101" => ---down left
										pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									when "00110110" => ---left
										pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury, 8));
									when "00110111" => ---up left
										pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									when "01111101" => ---}7D
										cur <= initialize_ram;
										write_phase <= false;
									when others =>
										cur <= moves;
								end case;  
								
								
								if (tempstdlogic /= "01111101") then
								    write_phase <= true;
                                    cur <= wait_one_clk;
                                    return_state <= moves;
								end if;

							end if;
						end if;
						
					when initialize_ram =>
						--state_out(2) <= '1';
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
					
						if (gameIsInitialized) then
							cur <= minimax;
							write_phase <= false;
							sequencePointer <= 0;
							stackPointer1 <= 0;
							stackPointer2 <= 0;
							best_score_ever_final <= to_signed(-9999,32);
						else
							--TODO: fix it if it can not read and right the same index in the same clock
							--temp_ram_value := "00000000";
							if write_phase then
							 write_phase <= false;
								temp_ram_value := pg_q_a;
								if (((i = 0 or i = to_integer(unsigned(w))) and (j >= 0 and j <= to_integer(unsigned(l))))) then
									temp_ram_value(4) := '1';
									temp_ram_value(0) := '1';
								end if;
							
								if (((j = to_integer(unsigned(l))/2 or j = 0 or j = to_integer(unsigned(l))) and i >= 0 and i <= to_integer(unsigned(w)))) then
									temp_ram_value(2) := '1';
									temp_ram_value(6) := '1';
								end if;
								
								if ((j = 0 or j = to_integer(unsigned(l)) - 1) and ((i >= 0 and i <= to_integer(unsigned(w))/2 - 2) or (i >= to_integer(unsigned(w))/2 + 1 and i <= to_integer(unsigned(w)) - 1))) then
									temp_ram_value(3) := '1';
								end if;
								if ((j = 1 or j = to_integer(unsigned(l))) and ((i >= 1 and i <= to_integer(unsigned(w))/2 - 1) or (i >= to_integer(unsigned(w))/2 + 2 and i <= to_integer(unsigned(w))))) then
									temp_ram_value(7) := '1';
								end if;
								
								if ((j = 1 or j = to_integer(unsigned(l))) and ((i >= 0 and i <= to_integer(unsigned(w))/2 - 2) or (i >= to_integer(unsigned(w))/2 + 1 and i <= to_integer(unsigned(w)) - 1))) then
									temp_ram_value(1) := '1';
								end if;
								if ((j = 0 or j = to_integer(unsigned(l)) - 1) and ((i >= 1 and i <= to_integer(unsigned(w))/2 - 1) or (i >= to_integer(unsigned(w))/2 + 2 and i <= to_integer(unsigned(w))))) then
									temp_ram_value(5) := '1';
								end if;
								
								if ((j = 1 or j = to_integer(unsigned(l)) - 1) and ((i >= 0 and i <= to_integer(unsigned(w))/2 - 2) or (i >= to_integer(unsigned(w))/2 + 2 and i <= to_integer(unsigned(w))))) then
									temp_ram_value(2) := '1';
									temp_ram_value(6) := '1';
								end if;
								if (j = 1 or j = to_integer(unsigned(l)) - 1) then
									if (i = to_integer(unsigned(w))/2 - 1) then
										temp_ram_value(6) := '1';
									elsif (i = to_integer(unsigned(w))/2 + 1) then
										temp_ram_value(2) := '1';
									end if;
								end if;
								
								if ((j = 0 or j = to_integer(unsigned(l)) - 1) and ((i >= 1 and i <= to_integer(unsigned(w))/2 - 1) or (i >= to_integer(unsigned(w))/2 + 1 and i <= to_integer(unsigned(w)) - 1))) then
									temp_ram_value(4) := '1';
								end if;
								
								if ((j = 1 or j = to_integer(unsigned(l))) and ((i >= 1 and i <= to_integer(unsigned(w))/2 - 1) or (i >= to_integer(unsigned(w))/2 + 1 and i <= to_integer(unsigned(w)) - 1))) then
									temp_ram_value(0) := '1';
								end if;
								
								if (j = 0) then
									temp_ram_value(7) := '1';
									temp_ram_value(0) := '1';
									temp_ram_value(1) := '1';
								end if;
								
								if (j = to_integer(unsigned(l))) then
									temp_ram_value(3) := '1';
									temp_ram_value(4) := '1';
									temp_ram_value(5) := '1';
								end if;
								
								if (i = 0) then
									temp_ram_value(5) := '1';
									temp_ram_value(6) := '1';
									temp_ram_value(7) := '1';
								end if;
								
								if (i = to_integer(unsigned(w))) then
									temp_ram_value(1) := '1';
									temp_ram_value(2) := '1';
									temp_ram_value(3) := '1';
								end if;
								
								pg_rden_a <= '0';
								pg_wren_a <= '1';
								pg_address_a <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(j, 8));
								pg_data_a <= temp_ram_value;
								
								j <= j + 1;
								if (j = to_integer(unsigned(l))) then 
									j <= 0;
									i <= i + 1;
									if (i = to_integer(unsigned(w))) then 
										gameIsInitialized <= true;
									end if;
								end if;
								
								cur <= wait_one_clk;
								return_state <= initialize_ram;
							else
							   write_phase <= true;
								pg_rden_a <= '1';
								pg_wren_a <= '0';
								pg_address_a <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(j, 8));
								
								cur <= wait_one_clk;
								return_state <= initialize_ram;
							end if;
							
						end if;

					when load_loopInfo =>
						--state_out(3) <= '1';
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						mp_rden_a <= '0';
						mp_wren_a <= '0';
						fm_rden_a <= '0';
						fm_wren_a <= '0';
						an_rden_a <= '0';
						an_wren_a <= '0';
						ni_rden_a <= '0';
						ni_wren_a <= '0';
						da_rden_a <= '0';
						da_wren_a <= '0';
						max_rden_a <= '0';
						max_wren_a <= '0';
						min_rden_a <= '0';
						min_wren_a <= '0';
						ia_rden_a <= '0';
						ia_wren_a <= '0';
						ja_rden_a <= '0';
						ja_wren_a <= '0';
						rv_rden_a <= '0';
						rv_wren_a <= '0';
						rv_rden_b <= '0';
						rv_wren_b <= '0';
						
						if stackPointer1 >= 0 then
							mp_rden_a <= '1';
							mp_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							fm_rden_a <= '1';
							fm_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							an_rden_a <= '1';
							an_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							ni_rden_a <= '1';
							ni_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							da_rden_a <= '1';
							da_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							
							max_rden_a <= '1';
							max_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
							min_rden_a <= '1';
							min_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
							ia_rden_a <= '1';
							ia_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							ja_rden_a <= '1';
							ja_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
							rv_rden_a <= '1';
							rv_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
							
							rv_rden_b <= '1';
							rv_address_b <= std_logic_vector(to_unsigned(stackPointer1+1, 9));

							cur <= wait_one_clk;
							return_state <= minimax;

						else
							cur <= minimax;
						end if;
						dont_reload_loopInfo := false;
						
					when minimax =>
					--state_out(4) <= '1';
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						mp_rden_a <= '0';
						mp_wren_a <= '0';
						fm_rden_a <= '0';
						fm_wren_a <= '0';
						an_rden_a <= '0';
						an_wren_a <= '0';
						ni_rden_a <= '0';
						ni_wren_a <= '0';
						da_rden_a <= '0';
						da_wren_a <= '0';
						max_rden_a <= '0';
						max_wren_a <= '0';
						min_rden_a <= '0';
						min_wren_a <= '0';
						ia_rden_a <= '0';
						ia_wren_a <= '0';
						ja_rden_a <= '0';
						ja_wren_a <= '0';
						rv_rden_a <= '0';
						rv_wren_a <= '0';
						rv_rden_b <= '0';
						rv_wren_b <= '0';
					
						if (stackPointer1 >= 0) then
							quitProcess := false;
							thereWasANeighbor := false;
							dont_reload_loopInfo := false;
							
							if mp_q_a(0) = '0' then
								loopInfo.maximizingPlayer := false;
							else
								loopInfo.maximizingPlayer := true;
							end if;
							if fm_q_a(0) = '0' then
								loopInfo.firstMoveBeing := false;
							else
								loopInfo.firstMoveBeing := true;
							end if;
							if an_q_a(0) = '0' then
								loopInfo.all_neighbors_checked := false;
							else
								loopInfo.all_neighbors_checked := true;
							end if;
							
							loopInfo.neighborIndex := to_integer(unsigned(ni_q_a));
							loopInfo.depth := da_q_a;
							
							loopInfo.maxValue := signed(max_q_a);
							loopInfo.minValue := signed(min_q_a);
							loopInfo.i := to_integer(unsigned(ia_q_a));
							loopInfo.j := to_integer(unsigned(ja_q_a));
							loopInfo.returnValue := signed(rv_q_a);
							
							-- initialize stack
							if (not stackIsInitialized) then
								if initial_depth = "00000001" then
									state_out(0) <= '1';
								elsif initial_depth = "00000010" then
									state_out(1) <= '1';
								elsif initial_depth = "00000011" then
									state_out(2) <= '1';
								elsif initial_depth = "00000100" then
									state_out(3) <= '1';
								elsif initial_depth = "00000101" then
									state_out(4) <= '1';
								else
									state_out(5) <= '1';
								end if;
								quitProcess := true;
								stackIsInitialized <= true;
								
								mp_wren_a <= '1';
								mp_address_a <= "0000000000000000";
								mp_data_a(0) <= '1';
								
								fm_wren_a <= '1';
								fm_address_a <= "0000000000000000";
								fm_data_a(0) <= '1';
								
								an_wren_a <= '1';
								an_address_a <= "0000000000000000";
								an_data_a(0) <= '0';
								
								ni_wren_a <= '1';
								ni_address_a <= "0000000000000000";
								ni_data_a <= "00000000";
								
								da_wren_a <= '1';
								da_address_a <= "0000000000000000";
								da_data_a <= initial_depth;
								
								max_wren_a <= '1';
								max_address_a <= "000000000";
								max_data_a <= std_logic_vector(to_signed(-255, 32));
								
								min_wren_a <= '1';
								min_address_a <= "000000000";
								min_data_a <= std_logic_vector(to_signed(255, 32));
								
								ia_wren_a <= '1';
								ia_address_a <= "0000000000000000";
								ia_data_a <= std_logic_vector(to_unsigned(curx, 8));
								
								ja_wren_a <= '1';
								ja_address_a <= "0000000000000000";
								ja_data_a <= std_logic_vector(to_unsigned(cury, 8));
								
								rv_wren_a <= '1';
								rv_address_a <= "000000000";
								rv_data_a <= std_logic_vector(to_signed(cury, 32));
								
								best_score_ever <= to_signed(-9999,32);
								--temp_ram_value2 := ram(curx, cury);
								pg_rden_b <= '1';
								pg_wren_b <= '0';
								pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
								cur <= wait_one_clk;
								return_state <= load_loopInfo;
								dont_reload_loopInfo := true;
							end if;
							
							
								
							-- evaluation part
							if (loopInfo.depth = "00000000" and not quitProcess) then
								 
								if (loopInfo.j = 0 and ((loopInfo.i = to_integer(unsigned(w))/2 - 1) 
								or loopInfo.i = to_integer(unsigned(w))/2 or (loopInfo.i =to_integer(unsigned(w))/2 + 1))) then
									-- blue won
									if (bluePlayer) then
										tempValue_var := to_signed(9999, 32);
									else
										tempValue_var := to_signed(-9999,32);
									end if;
								elsif (loopInfo.j = to_integer(unsigned(l)) and ((loopInfo.i = to_integer(unsigned(w))/2 - 1) 
										 or loopInfo.i = to_integer(unsigned(w))/2 or (loopInfo.i =to_integer(unsigned(w))/2 + 1))) then
									-- red won
									if (bluePlayer) then
										tempValue_var := to_signed(-9999,32);
									else
										tempValue_var := to_signed(9999,32);
									end if;
								elsif (bluePlayer) then
									if (loopInfo.maximizingPlayer) then
										tempValue_var := to_signed((loopInfo.j - to_integer(unsigned(l)))*(loopInfo.j - to_integer(unsigned(l)))
										 + (loopInfo.i - to_integer(unsigned(w))/2)*(loopInfo.i - to_integer(unsigned(w))/2),32);
									else
										tempValue_var := to_signed(-((loopInfo.j - 0)*(loopInfo.j - 0) +
										 (loopInfo.i - to_integer(unsigned(w))/2)*(loopInfo.i - to_integer(unsigned(w))/2)),32);
									end if;
								elsif (not bluePlayer) then
									if (loopInfo.maximizingPlayer) then
										tempValue_var := to_signed((loopInfo.j - 0)*(loopInfo.j - 0) 
										+ (loopInfo.i - to_integer(unsigned(w))/2)*(loopInfo.i - to_integer(unsigned(w))/2),32);
									else
										tempValue_var := to_signed(-((loopInfo.j - to_integer(unsigned(l)))*(loopInfo.j - to_integer(unsigned(l))) 
										+ (loopInfo.i - to_integer(unsigned(w))/2)*(loopInfo.i - to_integer(unsigned(w))/2)),32);
									end if;
								end if;
								
								rv_wren_a <= '1';
								rv_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
								rv_data_a <= std_logic_vector(tempValue_var);
								
								stackPointer1 <= stackPointer1 - 1;
								quitProcess := true;
							end if;

							--TODO: if the opponent cant move its a win state as well
							-- cheking if game has ended befor getting to zero depth 
							if (loopInfo.j = 0 and ((loopInfo.i = to_integer(unsigned(w))/2 - 1) 
							   or loopInfo.i = to_integer(unsigned(w))/2 or (loopInfo.i =to_integer(unsigned(w))/2 + 1)) 
							   and not quitProcess) then
								-- blue won
								if (bluePlayer) then
									tempValue_var := to_signed(9999,32);
								else
									tempValue_var := to_signed(-9999,32);
								end if;
								
								rv_wren_a <= '1';
								rv_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
								rv_data_a <= std_logic_vector(tempValue_var);
								
								stackPointer1 <= stackPointer1 - 1;
								quitProcess := true;
							elsif (loopInfo.j = to_integer(unsigned(l)) and ((loopInfo.i = to_integer(unsigned(w))/2 - 1) 
							   or loopInfo.i = to_integer(unsigned(w))/2 or (loopInfo.i =to_integer(unsigned(w))/2 + 1)) 
							   and not quitProcess) then
								-- red won
								if (bluePlayer) then
									tempValue_var := to_signed(-9999,32);
								else
									tempValue_var := to_signed(9999,32);
								end if;
								
								rv_wren_a <= '1';
								rv_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
								rv_data_a <= std_logic_vector(tempValue_var);
								
								stackPointer1 <= stackPointer1 - 1;
								quitProcess := true;
							end if;

							-- traversing part
							if (not quitProcess) then
								-- specify a neighbor
								if (stackPointer1 = stackPointer2) then
									if write_phase then
										temp_ram_value := pg_q_a;
										temp_ram_value2 := pg_q_b;
										
										if( temp_ram_value2(0) = '1' or temp_ram_value2(1) = '1' or temp_ram_value2(2) = '1' or temp_ram_value2(3) = '1' or 
										temp_ram_value2(4) = '1' or temp_ram_value2(5) = '1' or temp_ram_value2(6) = '1' or temp_ram_value2(7) = '1') then 
											wasAjoint2 := true;
										else
											wasAjoint2 := false;
										end if;
										
										-- update the game state
										temp_ram_value(temp_int) := '1';
										pg_data_a <= temp_ram_value;
										pg_rden_a <= '0';
										pg_wren_a <= '1';
										pg_address_a <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
										
										pg_rden_b <= '0';
										pg_wren_b <= '1';
										case temp_int is
											when 0 =>
												temp_ram_value2(4) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
											when 1 =>
												temp_ram_value2(5) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
											when 2 =>
												temp_ram_value2(6) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
											when 3 =>
												temp_ram_value2(7) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
											when 4 =>
												temp_ram_value2(0) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
											when 5 =>
												temp_ram_value2(1) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
											when 6 =>
												temp_ram_value2(2) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
											when 7 =>
												temp_ram_value2(3) := '1';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
											when others =>
												temp_ram_value2(3) := '1';
										end case;
										
										fm_wren_a <= '1';
										fm_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										
										an_wren_a <= '1';
										an_data_a(0) <= '0';
										an_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										
										ni_wren_a <= '1';
										ni_data_a <= "00000000";
										ni_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										
										max_wren_a <= '1';
										max_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 9));
										max_data_a <= std_logic_vector(to_signed(-255, 32));
										min_wren_a <= '1';
										min_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 9));
										min_data_a <= std_logic_vector(to_signed(255, 32));
										ia_wren_a <= '1';
										ia_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										ia_data_a <= std_logic_vector(to_unsigned(neighbor_i, 8));
										ja_wren_a <= '1';
										ja_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										ja_data_a <= std_logic_vector(to_unsigned(neighbor_j, 8));
										rv_wren_a <= '1';
										rv_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 9));
										rv_data_a <= "00000000000000000000000000000000";
										
										if (loopInfo.firstMoveBeing and stackPointer1 + 1 < 33) then
											if (wasAjoint2) then
												fm_data_a(0) <= '1';
											else
												fm_data_a(0) <= '0';
											end if;
											temp_moveSequence(stackPointer1) <= temp_int;
											temp_moveSequence(stackPointer1 + 1) <= 8;
										else
											fm_data_a(0) <= '0';
										end if;
										
										mp_wren_a <= '1';
										mp_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										da_wren_a <= '1';
										da_address_a <= std_logic_vector(to_unsigned(stackPointer1+1, 16));
										if (wasAjoint2) then
											da_data_a <= loopInfo.depth;
											if loopInfo.maximizingPlayer then
											     mp_data_a(0) <= '1';
											else
											     mp_data_a(0) <= '0';
											end if;
										else
											da_data_a <=  std_logic_vector(unsigned(loopInfo.depth) - 1);
											if loopInfo.maximizingPlayer then
                                                 mp_data_a(0) <= '0';
                                            else
                                                 mp_data_a(0) <= '1';
                                            end if;
										end if;
										
										stackPointer1 <= stackPointer1 + 1;
										stackPointer2 <= stackPointer2 + 1;
										write_phase <= false;
										-- making sure next loop will access updated data
										if wasAjoint2 then
											-- this line updates the info of the incoming loop about the ram content of its related position after reversing the change
											cur <= wait_one_clk;
											return_state <= minimax_compliment;
											i <= neighbor_i;
											j <= neighbor_j;
											dont_reload_loopInfo := true;
										else
											cur <= wait_one_clk;
											return_state <= load_loopInfo;
											dont_reload_loopInfo := true;
										end if;
									else
										if (not loopInfo.all_neighbors_checked) then
											for i in 0 to 7 loop
												if (i >= loopInfo.neighborIndex and seconds < 1) then
													if (pg_q_b(i) = '0') then
														temp_int <= i;
														thereWasANeighbor := true;
														if (i = 7) then
															an_wren_a <= '1';
															an_data_a(0) <= '1';
															an_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
														end if;
														ni_wren_a <= '1';
														ni_data_a <= std_logic_vector(to_unsigned(i + 1, 8));
														ni_address_a <= std_logic_vector(to_unsigned(stackPointer1, 16));
														
														pg_rden_a <= '1';
														pg_wren_a <= '0';
														pg_address_a <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
														
														pg_rden_b <= '1';
														pg_wren_b <= '0';
														case i is
															when 0 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
																neighbor_i <= loopInfo.i;
																neighbor_j <= loopInfo.j - 1;
															when 1 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
																neighbor_i <= loopInfo.i + 1;
																neighbor_j <= loopInfo.j - 1;
															when 2 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
																neighbor_i <= loopInfo.i + 1;
																neighbor_j <= loopInfo.j;
															when 3 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
																neighbor_i <= loopInfo.i + 1;
																neighbor_j <= loopInfo.j + 1;
															when 4 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
																neighbor_i <= loopInfo.i;
																neighbor_j <= loopInfo.j + 1;
															when 5 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
																neighbor_i <= loopInfo.i - 1;
																neighbor_j <= loopInfo.j + 1;
															when 6 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
																neighbor_i <= loopInfo.i - 1;
																neighbor_j <= loopInfo.j;
															when 7 =>
																pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
																neighbor_i <= loopInfo.i - 1;
																neighbor_j <= loopInfo.j - 1;
															when others =>
																neighbor_i <= loopInfo.i;
																neighbor_j <= loopInfo.j;
														end case;
														
														cur <= wait_one_clk;
														return_state <= load_loopInfo;
														dont_reload_loopInfo := true;
														exit;
													
													end if;
												end if;
											end loop;
										end if;
										write_phase <= true;
										
										if (not thereWasANeighbor) then
											-- done with the current node
											if (loopInfo.maximizingPlayer) then
												rv_wren_a <= '1';
												rv_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
												rv_data_a <= std_logic_vector(loopInfo.maxValue);
											else
												rv_wren_a <= '1';
												rv_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
												rv_data_a <= std_logic_vector(loopInfo.minValue);
											end if;
											stackPointer1 <= stackPointer1 - 1;
											write_phase <= false;
											-- TODO: what if no neighbors are available (handle in evaluation)
										end if;
									end if;
									
								-- specified neighbor is checked
								else
									if write_phase then
										stackPointer2 <= stackPointer2 - 1;
										temp_ram_value := pg_q_a;
										temp_ram_value2 := pg_q_b;
										
										-- reverse the change ("neighborIndex - 1" because index is increased right after neighbor is selected)
										pg_rden_a <= '0';
										pg_wren_a <= '1';
										temp_ram_value(loopInfo.neighborIndex - 1) := '0';
										pg_data_a <= temp_ram_value;
										pg_address_a <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
										
										pg_rden_b <= '0';
										pg_wren_b <= '1';
										case (loopInfo.neighborIndex - 1) is
											when 0 =>
												temp_ram_value2(4) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
												t1 <= '0';
												t2 <= '0';
												t3 <= '0';
											when 1 =>
												temp_ram_value2(5) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
												t1 <= '0';
												t2 <= '0';
												t3 <= '1';
											when 2 =>
												temp_ram_value2(6) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
												t1 <= '0';
												t2 <= '1';
												t3 <= '0';
											when 3 =>
												temp_ram_value2(7) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
												t1 <= '0';
												t2 <= '1';
												t3 <= '1';
											when 4 =>
												temp_ram_value2(0) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
												t1 <= '1';
												t2 <= '0';
												t3 <= '0';
											when 5 =>
												temp_ram_value2(1) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
												t1 <= '1';
												t2 <= '0';
												t3 <= '1';
											when 6 =>
												temp_ram_value2(2) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
												t1 <= '1';
												t2 <= '1';
												t3 <= '0';
											when 7 =>
												temp_ram_value2(3) := '0';
												pg_data_b <= temp_ram_value2;
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
												t1 <= '1';
												t2 <= '1';
												t3 <= '1';
											when others =>
												temp_ram_value2(3) := '0';
										end case;
										
										-- update max or min value and best sequence of moves
										if (loopInfo.maximizingPlayer) then
											if (tempValue_sig > loopInfo.maxValue) then
												max_wren_a <= '1';
												max_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
												max_data_a <= std_logic_vector(tempValue_sig);
												
												-- check if childs move is in first move sequence
												if (loopInfo.firstMoveBeing  and tempValue_sig > best_score_ever and seconds < 1) then
													best_score_ever <= tempValue_sig;
													best_moveSequence <= temp_moveSequence;
												end if;
											end if;
										else
											if (tempValue_sig < loopInfo.minValue) then
												min_wren_a <= '1';
												min_address_a <= std_logic_vector(to_unsigned(stackPointer1, 9));
												min_data_a <= std_logic_vector(tempValue_sig);
											end if;
										end if;
										
										-- child data is no more needed
										stackPointer2 <= stackPointer2 - 1;
										write_phase <= false;
										-- this line updates the info of the incoming loop about the ram content of its related position after reversing the change
										cur <= wait_one_clk;
										return_state <= minimax_compliment;
										i <= loopInfo.i;
										j <= loopInfo.j;
										dont_reload_loopInfo := true;
										
										if (seconds >= 1 and loopInfo.depth = initial_depth) then
											deepening_phase <= false;
											stackIsInitialized <= false;
											stackPointer1 <= 0;
											stackPointer2 <= 0;
											cur <= wait_one_clk;
											return_state <= finish;
											write_phase <= false;
											edge <= "01111011"; --{
											new_message_out <= '1';
											state_out(23) <= '1';
											quitProcess := true;
											dont_reload_loopInfo := true;
											
											if best_score_ever > best_score_ever_final then
												best_moveSequence_final <= best_moveSequence;
												best_score_ever_final <= best_score_ever;
											end if;
										end if;
										
									else
										-- child loop's return value
										tempValue_sig <= signed(rv_q_b);
										
										pg_rden_a <= '1';
										pg_wren_a <= '0';
										pg_address_a <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
										
										pg_rden_b <= '1';
										pg_wren_b <= '0';
										case (loopInfo.neighborIndex - 1) is
											when 0 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
											when 1 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
											when 2 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
											when 3 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i+1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
											when 4 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
											when 5 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j+1, 8));
											when 6 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
											when 7 =>
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i-1, 8)) & std_logic_vector(to_unsigned(loopInfo.j-1, 8));
											when others =>
												pg_rden_b <= '1';
												pg_wren_b <= '0';
												pg_address_b <= std_logic_vector(to_unsigned(loopInfo.i, 8)) & std_logic_vector(to_unsigned(loopInfo.j, 8));
										end case;
										write_phase <= true;
										
										cur <= wait_one_clk;
										return_state <= load_loopInfo;
										dont_reload_loopInfo := true;
									end if;
									
								end if;
							end if;
							
							if not dont_reload_loopInfo then
								cur <= wait_one_clk;
								return_state <= load_loopInfo;
							end if;
						else
							cur <= deepen_minimax;
							deepening_phase <= true;
							if best_score_ever > best_score_ever_final then
								best_moveSequence_final <= best_moveSequence;
								best_score_ever_final <= best_score_ever;
							end if;
						end if;
					
					when deepen_minimax =>
						initial_depth <= std_logic_vector(unsigned(initial_depth) + 1);
						stackIsInitialized <= false;
						stackPointer1 <= 0;
						stackPointer2 <= 0;
						sequencePointer <= 0;
						cur <= minimax;
						
					
					when finish =>
						
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						
						if write_phase then
							-- if the next move goes to a non-joint its the end move
							temp_ram_value := pg_q_a;
							temp_ram_value2 := pg_q_b;
							if temp_ram_value2 = "00000000" then
								cur <= finish2;
							end if;
							
							new_message_out <= '1';
							
							
							
							pg_rden_a <= '0';
							pg_wren_a <= '1';
							pg_rden_b <= '0';
							pg_wren_b <= '1';
							case temp_int is
								when 0 =>
									edge <= "00110000";
									temp_ram_value(0):='1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(4):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									cury <= cury-1;
								when 1 =>
									edge <= "00110001";
									temp_ram_value(1):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(5):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									curx <= curx+1;
									cury <= cury -1;
								when 2 =>
									edge <= "00110010";
									temp_ram_value(2):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(6):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury, 8));
									curx <= curx+1;
								when 3 =>
									edge <= "00110011";
									temp_ram_value(3):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(7):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									curx <= curx+1;
									cury <= cury +1;
								when 4 =>
									edge <= "00110100";
									temp_ram_value(4):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(0):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									cury <= cury+1;
								when 5 =>
									edge <= "00110101";
									temp_ram_value(5):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(1):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
									curx <= curx-1;
									cury <= cury +1;
								when 6 =>
									edge <= "00110110";
									temp_ram_value(6):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(2):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury, 8));
									curx <= curx-1;
								when 7 =>
									edge <= "00110111";
									temp_ram_value(7):= '1';
									pg_data_a <= temp_ram_value;
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
									
									temp_ram_value2(3):= '1';
									pg_data_b <= temp_ram_value2;
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
									curx <= curx-1;
									cury<=cury -1;
								when others =>
									cur <= finish2;
							end case;
							sequencePointer <= sequencePointer + 1;
							write_phase <= false;
						else
							new_message_out <= '0';
							pg_rden_a <= '1';
							pg_wren_a <= '0';
							pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
							
							temp_int <= best_moveSequence_final(sequencePointer);
							
							pg_rden_b <= '1';
							pg_wren_b <= '0';
							case best_moveSequence_final(sequencePointer) is
								when 0 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
								when 1 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
								when 2 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury, 8));
								when 3 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx+1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
								when 4 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
								when 5 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury+1, 8));
								when 6 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury, 8));
								when 7 =>
									pg_address_b <= std_logic_vector(to_unsigned(curx-1, 8)) & std_logic_vector(to_unsigned(cury-1, 8));
								when others =>
									--state_out(5) <= '1';
									pg_address_a <= std_logic_vector(to_unsigned(curx, 8)) & std_logic_vector(to_unsigned(cury, 8));
							end case;
							write_phase <= true;
							cur <= wait_one_clk;
							return_state <= finish;
							
							-- cheking if game has ended
							if (cury = 0 and ((curx = to_integer(unsigned(w))/2 - 1) 
							   or curx = to_integer(unsigned(w))/2 or (curx =to_integer(unsigned(w))/2 + 1))) then
								-- blue won
								cur <= finish2;
								state_out(22) <= '1';
							elsif (cury = to_integer(unsigned(l)) and ((curx = to_integer(unsigned(w))/2 - 1) 
							   or curx = to_integer(unsigned(w))/2 or (curx =to_integer(unsigned(w))/2 + 1))) then
								-- red won
								cur <= finish2;
								state_out(21) <= '1';
							end if;
							
						end if;
						
					when finish2 =>
						--state_out(6) <= '1';
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						
						cur <= finish3;
						edge <= "01111101"; --}
						new_message_out <= '1';
						
					when finish3 =>
						--state_out(7) <= '1';
						pg_rden_a <= '0';
						pg_wren_a <= '0';
						pg_rden_b <= '0';
						pg_wren_b <= '0';
						
						cur <= start;
						new_message_out <= '1';
						edge <= "00001010"; --\n
					
					when minimax_compliment =>
						--state_out(8) <= '1';
						pg_rden_b <= '1';
						pg_wren_b <= '0';
						pg_address_b <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(j, 8));
						cur <= wait_one_clk;
						return_state <= load_loopInfo;
					
					when wait_one_clk =>
						--state_out(9) <= '1';
						if (return_state = moves and new_message_in = '1') then
							queue(tail) <= message;
							tail <= tail + 1;
						end if;
						new_message_out <= '0';
						cur <= return_state;
						
					when others =>
						cur <= start;
						
				end case;
				
			end if;
		end if;
end process;



end Behavioral;
