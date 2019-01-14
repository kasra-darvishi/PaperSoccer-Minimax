library ieee;
use ieee.std_logic_1164.all;

entity main is port (

	rxd : in std_logic := '1';
	txd : out std_logic := '1';
	clk : in std_logic;
	state_out: out std_logic_vector(23 downto 0)
);
end entity;

architecture RTL of main is

component agent is
    Port ( 
           message : in std_logic_vector(7 downto 0);
           new_message_in: in std_logic;
           new_message_out: out std_logic;
           edge : out std_logic_vector(7 downto 0);
           clk : in std_logic;
           rst : in std_logic;
			  state_out: out std_logic_vector(23 downto 0)
           );
end component;

component async_transmitter is port (
	clk : in std_logic;
	TxD_start : in std_logic;
	TxD_data : in std_logic_vector(7 downto 0);
	TxD : out std_logic;
	TxD_busy : out std_logic
);
end component;

COMPONENT async_receiver is port (
	clk : in std_logic;
	RxD :IN std_logic;
	RxD_data_ready :OUT std_logic := '0';
	RxD_data :OUT std_logic_vector(7 downto 0);

	RxD_idle :OUT std_logic ;  --// asserted when no data has been received for a while
	RxD_endofpacket :OUT std_logic :='0' --// asserted for one clock cycle when a packet has been detected (i.e. RxD_idle is going high)
);


end component;

component ClockPrescaler is
    port(
        clock   : in STD_LOGIC; -- 50 Mhz
        Led     : out STD_LOGIC
    );
end component;


-- sender ports
signal datain,dataout, dataout_agent : std_logic_vector (7 downto 0) := "00000000";
signal received,rst,transmit, transmit_agent : std_logic := '0';
signal snd_busy,IDLE ,ENDOFP, one_test_bit,slow_clk : std_logic;


type queue_type is array (0 to 666) of std_logic_vector(7 downto 0);
signal queue: queue_type;
signal head, tail, counter: integer := 0;

signal do_once, isREsetDone: boolean := false;
 
 
begin

buffer_proc : process( clk)
begin
    if(rising_edge(clk)) then
		if not isREsetDone then
			rst <= '1';
			isREsetDone <= true;
		else
			rst <= '0';
		end if;
		
		if (transmit_agent = '1') then
			queue(tail) <= dataout_agent;
			tail <= tail + 1;
			if (tail = 666) then
				tail <= 0;
			end if;
		end if;
		if snd_busy = '0' and head /= tail and counter > 500 then
			transmit <= '1';
			dataout <= queue(head);
			head <= head + 1;
			if (head = 666) then
				head <= 0;
			end if;
			counter <= 0;
		else
			transmit <= '0';
			counter <= counter + 1;
		end if;
	 end if;
end process;

snd: async_transmitter port map (clk, transmit, dataout, txd, snd_busy);
myagent : agent port map(datain , received ,transmit_agent ,dataout_agent ,clk ,rst,state_out);

m1 : async_receiver  port map(clk ,  rxd,received ,datain,idle ,endofp);

--m2: ClockPrescaler port map(clk, slow_clk);



end RTL;