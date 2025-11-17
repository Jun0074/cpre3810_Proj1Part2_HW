library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ID_EXE is
end tb_ID_EXE;

architecture sim of tb_ID_EXE is
  constant N : integer := 32;

  -- DUT inputs
  signal i_CLK       : std_logic := '0';
  signal i_RST       : std_logic := '0';
  signal i_WE        : std_logic := '0';
  signal i_FLUSH     : std_logic := '0';

  signal i_oRS1      : std_logic_vector(31 downto 0) := (others => '0');
  signal i_oRS2      : std_logic_vector(31 downto 0) := (others => '0');
  signal i_rd        : std_logic_vector(4 downto 0)  := (others => '0');
  signal i_rs1       : std_logic_vector(4 downto 0)  := (others => '0');
  signal i_rs2       : std_logic_vector(4 downto 0)  := (others => '0');
  signal i_PC        : std_logic_vector(N-1 downto 0) := (others => '0');
  signal i_PCplus4   : std_logic_vector(N-1 downto 0) := (others => '0');
  signal i_Imm       : std_logic_vector(31 downto 0) := (others => '0');
  signal i_funct3    : std_logic_vector(2 downto 0) := (others => '0');
  signal i_isJALR    : std_logic := '0';

  signal i_ALUSrcA   : std_logic := '0';
  signal i_ALUSrc    : std_logic := '0';
  signal i_ALUOp     : std_logic_vector(3 downto 0) := (others => '0');
  signal i_Branch    : std_logic := '0';
  signal i_Jump      : std_logic := '0';
  signal i_ResultSrc : std_logic_vector(1 downto 0) := (others => '0');
  signal i_MemWrite  : std_logic := '0';
  signal i_MemRead   : std_logic := '0';
  signal i_RegWrite  : std_logic := '0';
  signal i_LoadType  : std_logic_vector(2 downto 0) := (others => '0');
  signal i_Halt      : std_logic := '0';

  -- DUT outputs
  signal idex_oRS1      : std_logic_vector(31 downto 0);
  signal idex_oRS2      : std_logic_vector(31 downto 0);
  signal idex_rd        : std_logic_vector(4 downto 0);
  signal idex_rs1       : std_logic_vector(4 downto 0);
  signal idex_rs2       : std_logic_vector(4 downto 0);
  signal idex_PC        : std_logic_vector(N-1 downto 0);
  signal idex_PCplus4   : std_logic_vector(N-1 downto 0);
  signal idex_Imm       : std_logic_vector(31 downto 0);
  signal idex_funct3    : std_logic_vector(2 downto 0);
  signal idex_isJALR    : std_logic;

  signal idex_ALUSrcA   : std_logic;
  signal idex_ALUSrc    : std_logic;
  signal idex_ALUOp     : std_logic_vector(3 downto 0);
  signal idex_Branch    : std_logic;
  signal idex_Jump      : std_logic;
  signal idex_ResultSrc : std_logic_vector(1 downto 0);
  signal idex_MemWrite  : std_logic;
  signal idex_MemRead   : std_logic;
  signal idex_RegWrite  : std_logic;
  signal idex_LoadType  : std_logic_vector(2 downto 0);
  signal idex_Halt      : std_logic;

begin
  -- Clock: 10 ns period
  clk_gen : process
  begin
    i_CLK <= '0'; wait for 5 ns;
    i_CLK <= '1'; wait for 5 ns;
  end process;

  -- DUT
  uut: entity work.ID_EXE
    generic map ( N => N )
    port map (
      i_CLK => i_CLK,
      i_RST => i_RST,
      i_WE  => i_WE,
      i_FLUSH => i_FLUSH,

      i_oRS1 => i_oRS1,
      i_oRS2 => i_oRS2,
      i_rd   => i_rd,
      i_rs1  => i_rs1,
      i_rs2  => i_rs2,
      i_PC   => i_PC,
      i_PCplus4 => i_PCplus4,
      i_Imm  => i_Imm,
      i_funct3 => i_funct3,
      i_isJALR => i_isJALR,

      i_ALUSrcA => i_ALUSrcA,
      i_ALUSrc  => i_ALUSrc,
      i_ALUOp   => i_ALUOp,
      i_Branch  => i_Branch,
      i_Jump    => i_Jump,
      i_ResultSrc => i_ResultSrc,
      i_MemWrite  => i_MemWrite,
      i_MemRead   => i_MemRead,
      i_RegWrite  => i_RegWrite,
      i_LoadType  => i_LoadType,
      i_Halt      => i_Halt,

      idex_oRS1 => idex_oRS1,
      idex_oRS2 => idex_oRS2,
      idex_rd   => idex_rd,
      idex_rs1  => idex_rs1,
      idex_rs2  => idex_rs2,
      idex_PC   => idex_PC,
      idex_PCplus4 => idex_PCplus4,
      idex_Imm  => idex_Imm,
      idex_funct3 => idex_funct3,
      idex_isJALR => idex_isJALR,

      idex_ALUSrcA => idex_ALUSrcA,
      idex_ALUSrc  => idex_ALUSrc,
      idex_ALUOp   => idex_ALUOp,
      idex_Branch  => idex_Branch,
      idex_Jump    => idex_Jump,
      idex_ResultSrc => idex_ResultSrc,
      idex_MemWrite  => idex_MemWrite,
      idex_MemRead   => idex_MemRead,
      idex_RegWrite  => idex_RegWrite,
      idex_LoadType  => idex_LoadType,
      idex_Halt      => idex_Halt
    );

  -- Start stimulus
  stim : process
  begin
    -- Reset pulse
    i_RST <= '1'; i_WE <= '0'; i_FLUSH <= '0';
    wait for 12 ns;
    i_RST <= '0';
    wait for 8 ns; -- align to next rising edge

    -- Phase A: normal latch (WE=1, FLUSH=0)
    i_WE <= '1'; i_FLUSH <= '0';

    i_oRS1    <= x"AAAA0001";
    i_oRS2    <= x"BBBB0002";
    i_rd      <= "01010";      -- x10
    i_rs1     <= "00101";      -- x5
    i_rs2     <= "00110";      -- x6
    i_PC      <= x"00000040";
    i_PCplus4 <= x"00000044";
    i_Imm     <= x"00000010";
    i_funct3  <= "000";        -- beq for later EX usage
    i_isJALR  <= '0';

    i_ALUSrcA   <= '1';
    i_ALUSrc    <= '1';
    i_ALUOp     <= "0010";     -- ADD
    i_Branch    <= '1';
    i_Jump      <= '0';
    i_ResultSrc <= "00";       -- ALU
    i_MemWrite  <= '0';
    i_MemRead   <= '0';
    i_RegWrite  <= '1';
    i_LoadType  <= "000";
    i_Halt      <= '0';

    wait for 20 ns;  -- 2 cycles

    -- Phase B: stall (WE=0) - outputs should HOLD
    i_WE <= '0';
    -- change inputs; outputs should remain stable because WE=0
    i_oRS1    <= x"DEADBEEF";
    i_oRS2    <= x"FEEDC0DE";
    i_rd      <= "11111";
    i_rs1     <= "00001";
    i_rs2     <= "00010";
    i_PC      <= x"00000080";
    i_PCplus4 <= x"00000084";
    i_Imm     <= x"0000FF00";
    i_funct3  <= "001";        -- bne
    i_isJALR  <= '1';

    i_ALUSrcA   <= '0';
    i_ALUSrc    <= '0';
    i_ALUOp     <= "0011";     -- SUB
    i_Branch    <= '0';
    i_Jump      <= '1';
    i_ResultSrc <= "01";
    i_MemWrite  <= '1';
    i_MemRead   <= '1';
    i_RegWrite  <= '0';
    i_LoadType  <= "010";
    i_Halt      <= '1';

    wait for 20 ns;  -- observe hold

    -- Phase C: flush bubble (WE=1, FLUSH=1)
    -- Control outs should go to ZERO; data outs should LATCH new values
    i_WE    <= '1';
    i_FLUSH <= '1';

    i_oRS1    <= x"12345678";
    i_oRS2    <= x"9ABCDEF0";
    i_rd      <= "01001";
    i_rs1     <= "01010";
    i_rs2     <= "01011";
    i_PC      <= x"00000100";
    i_PCplus4 <= x"00000104";
    i_Imm     <= x"00000020";
    i_funct3  <= "100";        -- blt
    i_isJALR  <= '1';          -- should be forced to 0 at output due to flush 

    i_ALUSrcA   <= '1';
    i_ALUSrc    <= '0';
    i_ALUOp     <= "0100";
    i_Branch    <= '1';
    i_Jump      <= '1';
    i_ResultSrc <= "10";
    i_MemWrite  <= '1';
    i_MemRead   <= '0';
    i_RegWrite  <= '1';
    i_LoadType  <= "011";
    i_Halt      <= '1';

    wait for 20 ns;

    -- Phase D: back to normal (WE=1, FLUSH=0)
    i_FLUSH <= '0';

    i_oRS1    <= x"CAFEBABE";
    i_oRS2    <= x"0BADF00D";
    i_rd      <= "00011";
    i_rs1     <= "00001";
    i_rs2     <= "00010";
    i_PC      <= x"00000140";
    i_PCplus4 <= x"00000144";
    i_Imm     <= x"00000004";
    i_funct3  <= "111";        -- bgeu
    i_isJALR  <= '0';

    i_ALUSrcA   <= '0';
    i_ALUSrc    <= '1';
    i_ALUOp     <= "1001";     -- SLL
    i_Branch    <= '0';
    i_Jump      <= '0';
    i_ResultSrc <= "11";       -- LUI path
    i_MemWrite  <= '0';
    i_MemRead   <= '0';
    i_RegWrite  <= '1';
    i_LoadType  <= "000";
    i_Halt      <= '0';

    wait for 30 ns;

    -- finish
    wait;
  end process;

end architecture;
