library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_IFID_Register is
end entity;

architecture tb of tb_IFID_Register is
  -- Clock/reset control
  signal clk   : std_logic := '0';
  signal rst   : std_logic := '0';
  signal we    : std_logic := '1';
  signal flush : std_logic := '0';

  -- Inputs from IF stage
  signal i_PC       : std_logic_vector(31 downto 0) := (others => '0');
  signal i_PCplus4  : std_logic_vector(31 downto 0) := (others => '0');
  signal i_Instr    : std_logic_vector(31 downto 0) := (others => '0');

  -- Outputs to ID stage
  signal ifid_PC       : std_logic_vector(31 downto 0);
  signal ifid_PCplus4  : std_logic_vector(31 downto 0);
  signal ifid_Inst     : std_logic_vector(31 downto 0);

  constant Tclk : time := 10 ns;
begin
  -- Clock generation
  clk_proc : process
  begin
    clk <= '0'; wait for Tclk/2;
    clk <= '1'; wait for Tclk/2;
  end process;

  -- DUT instantiation
  dut : entity work.IFID_Register
    port map(
      i_CLK      => clk,
      i_RST      => rst,
      i_WE       => we,
      i_FLUSH    => flush,
      i_PC       => i_PC,
      i_PCplus4  => i_PCplus4,
      i_Instr    => i_Instr,
      ifid_PC       => ifid_PC,
      ifid_PCplus4  => ifid_PCplus4,
      ifid_Inst     => ifid_Inst
    );

  -- Start test
  stim : process
  begin
    ----------------------------------------------------------------
    -- Phase 0: async reset asserted, all outputs should clear
    ----------------------------------------------------------------
    rst <= '1'; we <= '1'; flush <= '0';
    i_PC      <= x"00000004";
    i_PCplus4 <= x"00000008";
    i_Instr   <= x"DEADBEEF";
    wait for 20 ns;

    ----------------------------------------------------------------
    -- Phase 1: release reset, normal operation
    ----------------------------------------------------------------
    rst <= '0';
    i_PC      <= x"00000010";
    i_PCplus4 <= x"00000014";
    i_Instr   <= x"11112222";
    wait until rising_edge(clk);  -- latch vector A
    wait for 20 ns;

    ----------------------------------------------------------------
    -- Phase 2: flush active (instruction should become NOP)
    ----------------------------------------------------------------
    flush <= '1';
    i_PC      <= x"00000020";
    i_PCplus4 <= x"00000024";
    i_Instr   <= x"33334444";
    wait until rising_edge(clk);
    flush <= '0';  -- disable flush
    wait for 20 ns;

    ----------------------------------------------------------------
    -- Phase 3: stall (WE=0, inputs change but outputs must hold)
    ----------------------------------------------------------------
    we <= '0';
    i_PC      <= x"00000030";
    i_PCplus4 <= x"00000034";
    i_Instr   <= x"55556666";
    wait for 30 ns;

    ----------------------------------------------------------------
    -- Phase 4: resume (WE=1), latch new inputs
    ----------------------------------------------------------------
    we <= '1';
    wait until rising_edge(clk);
    wait for 30 ns;

    wait;
  end process;
end architecture;
