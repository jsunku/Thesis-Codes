library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rotary_encoder is

  port( clk        :            in std_logic;
         reset     :            in std_logic;
          A        :            in std_logic;
          B        :            in std_logic;
          X        :            in std_logic;
         up_down   :            out std_logic;
         ce        :            out std_logic; -- evry flipflp in fpga has a synchronous controlinput (ce) this allows wheather flipflop sholsd store new data on next rising ede of clk or keep it old one
         error      :           out std_logic;
         counter    :           out std_logic_vector(15 downto 0)

  );
  
end rotary_encoder;
    
architecture Behavioral of rotary_encoder is

signal a_new, a_old, b_new, b_old : std_logic;
signal  x_old,x_new               : std_logic;
signal ce_i                       : std_logic := '0';
signal up_down_i                  : std_logic := '0'; 
signal counter_i                  : std_logic_vector(15 downto 0) :=  (others => '0');
signal error_i                    : std_logic := '0'; 

attribute mark_debug : string;
attribute keep : string;
attribute mark_debug of ce : signal is "true";
attribute mark_debug of up_down : signal is "true";
attribute mark_debug of A_old : signal is "true";
attribute mark_debug of B_old: signal is "true";
attribute mark_debug of X_old : signal is "true";
attribute mark_debug of error_i : signal is "true";
attribute mark_debug of counter_i : signal is "true";
  
 begin
 
up_down     <=   up_down_i;
ce          <=   ce_i;
counter     <=   counter_i;
error       <= error_i;
 

  -------------------------------------------
    ---sampling and delaying the signals
  -------------------------------------------
  process(clk)

  begin
  if rising_edge (clk) then

  a_old  <=  a_new;
  a_new  <=  A;
  b_old  <=  b_new;
  b_new  <=  B;
  x_old <=  x_new;
  x_new <=   X;
  
  end if;
end process;

------------------------------------------------
--decoding the encoder inputs
------------------------------------------------

process(a_new, a_old, b_new, b_old)

variable state : std_logic_vector(3 downto 0);

begin
state  := a_new & b_new & a_old & b_old;

case state is
 
  when "0000"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '0'; 
  when "0001"  => up_down_i    <= '1'; ce_i <= '0'; error_i <= '0'; 
  when "0010"  => up_down_i    <= '0'; ce_i <= '1'; error_i <= '0';
  when "0011"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '1';
  when "0100"  => up_down_i    <= '0'; ce_i <= '1'; error_i <= '0';
  when "0101"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '0';
  when "0110"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '1';
  when "0111"  => up_down_i    <= '1'; ce_i <= '1'; error_i <= '0';
  when "1000"  => up_down_i    <= '1'; ce_i <= '1'; error_i <= '0';
  when "1001"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '1';
  when "1010"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '0';
  when "1011"  => up_down_i    <= '0'; ce_i <= '1'; error_i <= '0';
  when "1100"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '1';
  when "1101"  => up_down_i    <= '0'; ce_i <= '1'; error_i <= '0';
  when "1110"  => up_down_i    <= '1'; ce_i <= '1'; error_i <= '0';
  when "1111"  => up_down_i    <= '0'; ce_i <= '0'; error_i <= '0';
when others => null;                      
  end case;
end process;

-------------------------------------------------------------
 
   -- Update counter--
------------------------------------------------------------
process(clk) 
	begin
	   if rising_edge(clk) then
	      --if(reset = '0') then
	     
	       if (x_old = '0') then
	           counter_i   <= (others => '0');
	       else
	           if ce_i  = '1' then
	               if up_down_i  = '0' then
	                   counter_i  <= std_logic_vector(unsigned(counter_i) + 1);
	               elsif up_down_i   = '1' then
	                   counter_i  <= std_logic_vector(unsigned(counter_i) - 1);
	               end if;
		      end if;	
	       end if;
        end if;	
 end process;
end  behavioral ;
