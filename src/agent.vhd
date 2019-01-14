----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/13/2018 10:05:09 PM
-- Design Name: 
-- Module Name: finder - Behavioral
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

entity agent is
    Port ( 
           message : in std_logic_vector(7 downto 0);
           new_message_in: in std_logic;
           new_message_out: out std_logic;
           edge : out std_logic_vector(7 downto 0);
           clk : in std_logic;
           rst : in std_logic;
		     state_out: out std_logic_vector(23 downto 0)
           );
end agent;

architecture Behavioral of agent is

constant start : STD_LOGIC_VECTOR (5 DOWNTO 0) := "000001";
constant widths : STD_LOGIC_VECTOR (5 DOWNTO 0) := "000010";
constant lengths : STD_LOGIC_VECTOR (5 DOWNTO 0) := "000100";
constant clplayer : STD_LOGIC_VECTOR (5 DOWNTO 0) := "001000";
constant moves : STD_LOGIC_VECTOR (5 DOWNTO 0) := "010000";
constant finish : STD_LOGIC_VECTOR (5 DOWNTO 0) := "100000";


signal cur: STD_LOGIC_VECTOR (5 DOWNTO 0) :=START;

signal x, y, color : std_logic_vector(7 downto 0); ---type definition
signal ready : std_logic_vector(1 downto 0):= "00";
signal strt : std_logic;
signal size: integer;
signal foreout : std_logic_vector(7 downto 0);
signal bluePlayer: boolean;
 
component forecast is
    Port ( 
           l,w : in std_logic_vector(7 downto 0);
		   bluePlayer: in boolean;
		   new_message_in: in std_logic;
           new_message_out: out std_logic;
           ready :in std_logic_vector(1 downto 0);
           message : in std_logic_vector(7 downto 0);
           edge : out std_logic_vector(7 downto 0);
           clk : in std_logic;
           rst : in std_logic;
		   state_out: out std_logic_vector(23 downto 0)
           );
end component;

begin

receiver: process( clk)
begin
    if(rising_edge(clk)) then
        if (rst= '1') then
            cur <= start;
				ready <= "00";
        else
         case cur is
			  when start =>
					if new_message_in = '1' then
						case message is
							when "01110111" => --w
								cur <= widths;
							when "01101100" => --l
								cur <= lengths;
							when "01100011" => --c
								cur <= clplayer;
							when "01111011" =>  --{
								cur <= moves;
							when others =>
								cur <= start;
						end case;   
					end if;
			  when widths =>
					if new_message_in = '1' then
						x <= message;
						ready(0) <= '1';
						cur <= finish;
					end if;
			  when lengths =>
					if new_message_in = '1' then
						y <= std_logic_vector(to_unsigned(to_integer(unsigned(message)) + 2, 8));
						ready(1) <='1';
						cur <= finish;
					end if;
			  when clplayer =>
					if new_message_in = '1' then
						color <= message;
						if (message = "01100010") then
							bluePlayer <= true;
						else
							bluePlayer <= false;
						end if;
						cur <= finish;
					end if;
			  when moves =>
					cur <= finish;
			  when finish =>
					if new_message_in = '1' then
						if (message = "00001010") then --\n
							cur <= start;
						else
							cur <= finish;
						end if;
					end if;
				when others =>
					cur <= start;
		 end case;

        end if;
    end if;
end process;
        


--size  <=  to_integer(unsigned(x) * unsigned(y)); 
m1: forecast port map(y , x, bluePlayer, new_message_in, new_message_out, ready, message, foreout, clk , rst, state_out);

edge <= foreout;



end Behavioral;
