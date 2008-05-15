
library ieee;
use ieee.std_logic_1164.all;

entity crc_core is
  
  generic (
    C_SR_WIDTH : integer := 32);
  port (
    rst              : in  std_logic;
    opb_clk          : in  std_logic;
    crc_en           : in  std_logic;
    crc_clr          : in  std_logic;
    opb_m_last_block : in  std_logic;
    -- RX
    fifo_rx_en       : in  std_logic;
    fifo_rx_data     : in  std_logic_vector(C_SR_WIDTH-1 downto 0);
    opb_rx_crc_value : out std_logic_vector(C_SR_WIDTH-1 downto 0);
    -- TX
    fifo_tx_en       : in  std_logic;
    fifo_tx_data     : in  std_logic_vector(C_SR_WIDTH-1 downto 0);
    tx_crc_insert    : out std_logic;
    opb_tx_crc_value : out std_logic_vector(C_SR_WIDTH-1 downto 0));
end crc_core;


architecture behavior of crc_core is
  component crc_gen
    generic (
      C_SR_WIDTH      : integer;
      crc_start_value : std_logic_vector(31 downto 0));
    port (
      clk          : in  std_logic;
      crc_clear    : in  std_logic;
      crc_en       : in  std_logic;
      crc_data_in  : in  std_logic_vector(C_SR_WIDTH-1 downto 0);
      crc_data_out : out std_logic_vector(C_SR_WIDTH-1 downto 0));
  end component;

  signal rx_crc_en : std_logic;
  signal tx_crc_en : std_logic;


  signal cnt : integer range 0 to 15;
  
  
begin  -- behavior

  --* RX CRC_GEN
  crc_gen_rx : crc_gen
    generic map (
      C_SR_WIDTH      => C_SR_WIDTH,
      crc_start_value => (others => '1'))
    port map (
      clk          => OPB_Clk,
      crc_clear    => crc_clr,
      crc_en       => rx_crc_en,
      crc_data_in  => fifo_rx_data,
      crc_data_out => opb_rx_crc_value);    

  -- disable crc_generation for last data block
  rx_crc_en <= '1' when (crc_en = '1' and fifo_rx_en = '1' and opb_m_last_block = '0') else
               '0';

  -----------------------------------------------------------------------------
  --* TX CRC_GEN
  crc_gen_tx : crc_gen
    generic map (
      C_SR_WIDTH      => C_SR_WIDTH,
      crc_start_value => (others => '1'))
    port map (
      clk          => OPB_Clk,
      crc_clear    => crc_clr,
      crc_en       => tx_crc_en,
      crc_data_in  => fifo_tx_data,
      crc_data_out => opb_tx_crc_value);    

  -- disable crc_generation for last data block
  tx_crc_en <= '1' when (crc_en = '1' and fifo_tx_en = '1' and opb_m_last_block = '0') else
               '0';

  process(rst, OPB_Clk)
  begin
    if (rst = '1') then
      tx_crc_insert <= '0';
    elsif rising_edge(OPB_Clk) then
      if (opb_m_last_block = '0') then
        cnt <= 15;
        tx_crc_insert <= '0';
      elsif (fifo_tx_en = '1') then
        if (cnt = 1) then
          tx_crc_insert <= '1';
          cnt           <= cnt -1;
        elsif (cnt = 0) then
          tx_crc_insert <= '0';
        else
          cnt <= cnt -1;
        end if;
      end if;
    end if;
  end process;
end behavior;
