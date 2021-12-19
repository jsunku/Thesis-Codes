library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity synchro_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
	
	-------------signals from Pl (Fpga side)---------------
	      clk          : in std_logic;
          counter      : in std_logic_vector (15 downto 0); -- Current angle (from 0 to 360 degrees) scaled to the range 0 to 65534.
          gate         : buffer std_logic;
          led          : out std_logic_vector(2 downto 0);
          push_button  : in std_logic;
          difference_dbg : out std_logic_vector(15 downto 0);
          
		-- Users to add ports here

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
end synchro_v1_0;

architecture arch_imp of synchro_v1_0 is
constant c_degree_2   :   std_logic_vector(15 downto 0):= X"016C";
constant c_degree_3   :   std_logic_vector(15 downto 0):= X"0222";
constant c_degree_4   :   std_logic_vector(15 downto 0):= X"02D8";
constant c_degree_6   :   std_logic_vector(15 downto 0):= X"0444";
constant c_degree_8   :   std_logic_vector(15 downto 0):= X"05B0";

constant c_degree_10  :   std_logic_vector(15 downto 0):= X"071C";
constant c_degree_20  :   std_logic_vector(15 downto 0):= X"0E38";
constant c_degree_30  :   std_logic_vector(15 downto 0):= X"1554";
constant c_degree_40  :   std_logic_vector(15 downto 0):= X"1C70";
constant c_degree_50  :   std_logic_vector(15 downto 0):= X"283C";


 signal difference          :   std_logic_vector(15 downto 0);
 signal difference_positive :   std_logic;
 
 signal ctr_fa2              :   std_logic;
 signal ctr_fa3              :   std_logic;
 signal ctr_fa4              :   std_logic;
 signal ctr_fa6              :   std_logic;
 signal ctr_fa8              :   std_logic;
 signal ctr_fa10             :   std_logic;
 signal ctr_fa20             :   std_logic;
 signal ctr_fa30             :   std_logic;
 signal ctr_fa40             :   std_logic;
 signal ctr_fa50             :   std_logic;
 
 signal ctr_sl2              :   std_logic;
 signal ctr_sl3              :   std_logic;
 signal ctr_sl4              :   std_logic;
 signal ctr_sl6              :   std_logic;
 signal ctr_sl8              :   std_logic;
 signal ctr_sl10             :   std_logic;
 signal ctr_sl20             :   std_logic;
 signal ctr_sl30             :   std_logic;
 signal ctr_sl40             :   std_logic;
 signal ctr_sl50             :   std_logic;
 
 signal angle               :   std_logic_vector(15 downto 0);
 
attribute mark_debug : string;
attribute keep : string;
attribute mark_debug of counter : signal is "true";
attribute mark_debug of gate : signal is "true";
attribute mark_debug of difference : signal is "true";

attribute mark_debug of difference_positive : signal is "true";

attribute mark_debug of ctr_sl2 : signal is "true";

attribute mark_debug of ctr_sl3 : signal is "true";
attribute mark_debug of ctr_sl4 : signal is "true";
attribute mark_debug of ctr_sl6 : signal is "true";
attribute mark_debug of ctr_sl8 : signal is "true";
attribute mark_debug of ctr_sl10 : signal is "true";
attribute mark_debug of ctr_sl20 : signal is "true";
attribute mark_debug of ctr_sl30 : signal is "true";
attribute mark_debug of ctr_sl40: signal is "true";
attribute mark_debug of ctr_sl50 : signal is "true";
attribute mark_debug of ctr_fa2 : signal is "true";
attribute mark_debug of ctr_fa3 : signal is "true";
attribute mark_debug of ctr_fa4 : signal is "true";
attribute mark_debug of ctr_fa6 : signal is "true";
attribute mark_debug of ctr_fa8 : signal is "true";
attribute mark_debug of ctr_fa10 : signal is "true";
attribute mark_debug of ctr_fa20 : signal is "true";
attribute mark_debug of ctr_fa30 : signal is "true";
attribute mark_debug of ctr_fa40 : signal is "true";
attribute mark_debug of ctr_fa50 : signal is "true";

attribute mark_debug of angle : signal is "true";


	-- component declaration
	component synchro_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		
     
  ctr_fa2              :  in std_logic;
  ctr_fa3              :  in  std_logic;
  ctr_fa4              :  in std_logic;
  ctr_fa6              :  in std_logic;
  ctr_fa8              :  in std_logic;
  ctr_fa10             :  in std_logic;
  ctr_fa20             :  in std_logic;
  ctr_fa30             :  in std_logic;
  ctr_fa40             :  in std_logic;
  ctr_fa50             :  in std_logic;
 
 
 ctr_sl2               :  in std_logic;
 ctr_sl3               :  in std_logic;
 ctr_sl4               :  in std_logic;
 ctr_sl6               :  in std_logic;
 ctr_sl8               :  in std_logic;
 ctr_sl10              :  in std_logic;
 ctr_sl20              :  in std_logic;
 ctr_sl30              :  in std_logic;
 ctr_sl40              :  in std_logic;
 ctr_sl50              :   in std_logic;
 angle                 :   out  std_logic_vector(15 downto 0);
 
 push_button           :   in std_logic;
        
        
		S_AXI_ACLK      : in std_logic;
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
		S_AXI_RREADY	: in std_logic
		);
	end component synchro_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
synchro_v1_0_S00_AXI_inst : synchro_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	
	    ctr_fa2 =>ctr_fa2,  
	    ctr_fa3 =>ctr_fa3,
	    ctr_fa4 =>ctr_fa4,
	    ctr_fa6 =>ctr_fa6,
	    ctr_fa8 =>ctr_fa8,
	    ctr_fa10 =>ctr_fa10,
	    ctr_fa20=>ctr_fa20,
	    ctr_fa30 =>ctr_fa30,
	    ctr_fa40 =>ctr_fa40,
	    ctr_fa50 =>ctr_fa50,
	  
	    
	    ctr_sl2 => ctr_sl2,
	    ctr_sl3 => ctr_sl3,
	    ctr_sl4 => ctr_sl4,
	    ctr_sl6 => ctr_sl6,
	    ctr_sl8 => ctr_sl8,
	    ctr_sl10 => ctr_sl10,
	    ctr_sl20 => ctr_sl20,
	    ctr_sl30 => ctr_sl30,
	    ctr_sl40 => ctr_sl40,
	    ctr_sl50 => ctr_sl50,
	  
	    
	    angle => angle,
	    
	    push_button =>  push_button,
	
	        
	    
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
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
  difference <= std_logic_vector(unsigned(counter) - unsigned(angle));
  difference_dbg <= difference;
    
    -- If we interpret the signal 'difference' as a SIGNED number, then the magnitude should be very small.
    -- We are interested in the sign of the signal 'difference':
    difference_positive <= '1' when signed(difference) >= 0    -- Positive
                      else '0';                                -- Negative
    
 ctr_fa2 <= '1' when signed(difference) >= signed(C_DEGREE_2) and signed(difference) < signed(C_DEGREE_3 )else '0';  
ctr_fa3 <= '1' when signed(difference) >= signed(C_DEGREE_3) and signed(difference) < signed(C_DEGREE_4 )else '0';
ctr_fa4 <= '1' when signed(difference) >= signed(C_DEGREE_4) and signed(difference) < signed(C_DEGREE_6) else '0';
ctr_fa6 <= '1' when signed(difference) >= signed(C_DEGREE_6) and signed(difference) < signed(C_DEGREE_8)else '0';
ctr_fa8 <= '1' when signed(difference) >= signed(C_DEGREE_8) and signed(difference) < signed(C_DEGREE_10 )else '0';
ctr_fa10 <= '1' when signed(difference) >= signed(C_DEGREE_10) and signed(difference) < signed(C_DEGREE_20 ) else '0';
ctr_fa20 <= '1' when signed(difference) >= signed(C_DEGREE_20) and signed(difference) < signed(C_DEGREE_30 )else '0';
ctr_fa30 <= '1' when signed(difference) >= signed(C_DEGREE_30) and signed(difference) < signed(C_DEGREE_40 )else '0';
ctr_fa40 <= '1' when signed(difference) >= signed(C_DEGREE_40) and signed(difference) < signed(C_DEGREE_50 )else '0';
ctr_fa50 <= '1' when signed(difference) >= signed(C_DEGREE_50)  else '0';



ctr_sl2 <= '1' when signed(difference) <= - signed (C_DEGREE_2) and signed(difference) > - signed(C_DEGREE_3 )else '0';
ctr_sl3 <= '1' when signed(difference) <= - signed (C_DEGREE_3) and signed(difference) > - signed(C_DEGREE_4 )else '0';
ctr_sl4<=  '1' when signed(difference) <= - signed (C_DEGREE_4) and signed(difference) > - signed(C_DEGREE_6)else '0';
ctr_sl6 <= '1' when signed(difference) <= - signed (C_DEGREE_6) and signed(difference) > - signed(C_DEGREE_8)else '0';
ctr_sl8 <= '1' when signed(difference) <= - signed (C_DEGREE_8) and signed(difference) > - signed(C_DEGREE_10 )else '0';

ctr_sl10 <= '1' when signed(difference) <= - signed (C_DEGREE_10) and signed(difference) > - signed(C_DEGREE_20 )else '0';
ctr_sl20<=  '1' when signed(difference) <= - signed (C_DEGREE_20) and signed(difference) > - signed(C_DEGREE_30 )else '0';
ctr_sl30 <= '1' when signed(difference) <= - signed (C_DEGREE_30) and signed(difference) > - signed(C_DEGREE_40 )else '0';
ctr_sl40<=  '1' when signed(difference) <= - signed (C_DEGREE_40) and signed(difference) > - signed(C_DEGREE_50)else '0';
ctr_sl50<=  '1' when signed(difference) <= - signed (C_DEGREE_50) else '0';

gate   <= '1' when signed(difference) < signed (C_DEGREE_2) and signed(difference) > - signed (C_DEGREE_2) else '0';
    
  led(0)<= ctr_sl2;
  led(1)<= ctr_fa2;
  led(2)<= gate;
   
	-- User logic ends

end arch_imp;
