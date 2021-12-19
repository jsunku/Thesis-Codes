library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity galvo_scanner is
	port (
		-- general ports
		clk        :  in std_logic;
		-- PMOD interface (external pins of galvoscaner ip)
		xy2_clk		: out	std_logic;						--  10mhz scanner clock
		sync		: out	std_logic;						-- scanner synchronisation
		x_channel	: out	std_logic;						-- scanner channel x
		y_channel	: out	std_logic;						-- scanner channel y
        dip_switch  : in std_logic;

		-- user interface
		--send		: in	std_logic;						-- start signal
		x_data		: in	std_logic_vector(15 downto 0);	-- x coordinates
		y_data		: in	std_logic_vector(15 downto 0));	-- y coordinates
end galvo_scanner;

architecture rtl of galvo_scanner is
	-- temporal signals
	signal x_word, y_word	: std_logic_vector(15 downto 0)	:= (others => '0');
	signal x_par, y_par		: std_logic := '1';

	-- counter
	signal counter		: unsigned(4 downto 0)	:= (others => '0');
	signal rst_counter	: std_logic;
	
	-----count 
	 signal count     :     integer range 0 to 30 :=1;
	 signal xy2_clk_i :     std_logic := '0';
	 
	 signal periodic_counter : integer range 0 to 30 := 0;
	 signal periodic_send : std_logic := '0';

	-- states
	type states is (IDLE, CONTROL, DATA, PAR);
	signal c_state, n_state	: states	:= IDLE;

    signal	sync_i		: std_logic;
	signal	x_channel_i	: std_logic;
	signal	y_channel_i	: std_logic;

attribute mark_debug : string;
attribute keep : string;
attribute mark_debug of x_data : signal is "true";
attribute mark_debug of y_data : signal is "true";
--attribute mark_debug of send   : signal is "true";
attribute mark_debug of periodic_send   : signal is "true";
attribute mark_debug of periodic_counter   : signal is "true";
attribute mark_debug of sync_i  : signal is "true";
attribute mark_debug of x_channel_i  : signal is "true";
attribute mark_debug of y_channel_i  : signal is "true";


begin

-------------------------------------------------------------
--generating 2 mhz clock  for scanner
-----------------------------------------------------

process(clk)
begin
if(rising_edge(clk)) then 
    count <= count +1;
    if(count = 25) then
       xy2_clk_i <= not xy2_clk_i;
       count <= 1;
    end if;
  end if;
end process;

---------------------------------------------------------
--process for generating peridic sending with 10microseconds
------------------------------------------------------------
process (xy2_clk_i)
begin
    if rising_edge(xy2_clk_i) then
      periodic_send <= '0'; 
      periodic_counter <=  periodic_counter + 1;
          if (periodic_counter = 19) then
              periodic_send <= '1';
              periodic_counter <= 0;
         end if; 
      end if;
end process;

	--------------------------------------------------------------------
	-- Title		:	calculations
	-- Description	:	this process increments/resets the counter and
	--					calculates the parities.
	---------------------------------------------------------------------
	process (xy2_clk_i)
	begin
		if rising_edge(xy2_clk_i) then
			if (rst_counter = '1') then
				counter	<= (others => '0');
			else
				counter	<= counter + 1;
			end if;
			if (counter = 19) then
				x_par	<= '1';
				y_par	<= '1';
				-- Alternatively: x_par <= (('1' xor x_word(15)) xor x_word(14)) xor ... xor x_word(0);	
			elsif (counter >= 3) then
				x_par	<= x_par xor x_word(18 - to_integer(counter));
				y_par	<= y_par xor y_word(18 - to_integer(counter));
			end if;
			
			if (counter = 2) then
				x_word	<= x_data xor X"8000"; -- Invert bit 15 of x_data
				-- Alternative: x_word(15)          <= not x_data(15);
				--              x_word(14 downto 0) <= x_data(14 downto 0);
				
				y_word	<= y_data xor X"8000";
			end if;
		end if;
	end process;

	--------------------------------------------------------------------
	-- Title		:	FSM
	-- Description	:	the next 3 processes represent the FSM with 4 states.
	--------------------------------------------------------------------
	--------------------------------------------------------------------
	-- Title		:	state FF
	-- Description	:	this process changes the state synchronously.
	--------------------------------------------------------------------
	process (xy2_clk_i)
	begin
		if rising_edge(xy2_clk_i) then
			c_state	<= n_state;
		end if;
	end process;

	---------------------------------------------------------------------
	-- Title		:	next state
	-- Description	:	this process generates the next state depending on
	--					the current state, counter and input signal send.
	---------------------------------------------------------------------
	process (c_state, counter, periodic_send)
	begin
		n_state	<= c_state;
		case c_state is
			when IDLE	=>
				if (periodic_send = '1') then
					n_state	<= CONTROL;
				end if;
			when CONTROL	=>
				if (counter = 2) then
					n_state	<= DATA;
				end if;
			when DATA	=>
				if (counter = 18) then
					n_state	<= PAR;
				end if;
			when PAR	=>
				if (periodic_send = '0') then
					n_state	<= IDLE;
				else
					n_state	<= CONTROL;
				end if;
		end case;
	end process;

	------------------------------------------------------------------
	-- Title		:	state outputs
	-- Description	:	this process generates the output signals based on
	--					state and counter.
	------------------------------------------------------------------
	process (c_state, counter, x_word, y_word, x_par, y_par)
	begin
		sync_i		<= '0';
		rst_counter	<= '0';
		x_channel_i	<= '0';
		y_channel_i	<= '0';
		case c_state is
			when IDLE	=>
			    sync_i	    <= dip_switch; 
				rst_counter	<= '1';
			when CONTROL	=>
				sync_i	<= '1';
				if (counter = 2) then
					x_channel_i	<= '1';
					y_channel_i	<= '1';
				end if;
		   when DATA	=>
				sync_i		<= '1';
				x_channel_i	<= x_word(18 - to_integer(counter));
				y_channel_i	<= y_word(18 - to_integer(counter));
		   when PAR	=>
				x_channel_i	<= x_par;
				y_channel_i	<= y_par;
				rst_counter	<= '1';
		end case;
	end process;
	
    		sync		<= sync_i;
			x_channel	<= x_channel_i;
			y_channel	<= y_channel_i;
	
	-- output serial clock
	 xy2_clk  <= xy2_clk_i;
	

end rtl;

