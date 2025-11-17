library IEEE;
use IEEE.std_logic_1164.all;

entity ID_EXE is
  generic ( N : integer := 32 );  -- width for PC/data paths
  port(
    -- Clock / Reset / Write-enable / Flush
    i_CLK    : in  std_logic;
    i_RST    : in  std_logic;                 -- active-high async (dffg)
    i_WE     : in  std_logic;                 -- '1' latch; '0' hold (stall)
    i_FLUSH  : in  std_logic;                 -- '1' => bubble (zero control)

    -- Inputs from ID stage
    -- Data
    i_oRS1       : in  std_logic_vector(31 downto 0);
    i_oRS2       : in  std_logic_vector(31 downto 0);
    i_rd         : in  std_logic_vector(4 downto 0);
    i_rs1        : in  std_logic_vector(4 downto 0);
    i_rs2        : in  std_logic_vector(4 downto 0);
    i_PC         : in  std_logic_vector(N-1 downto 0);
    i_PCplus4    : in  std_logic_vector(N-1 downto 0);
    i_Imm        : in  std_logic_vector(31 downto 0);
    i_funct3      : in  std_logic_vector(2 downto 0); -- added for ALU control
    i_isJALR    : in  std_logic;

    -- Control (from decode)
    i_ALUSrcA    : in  std_logic;
    i_ALUSrc     : in  std_logic;
    i_ALUOp      : in  std_logic_vector(3 downto 0);
    i_Branch     : in  std_logic;
    i_Jump       : in  std_logic;
    i_ResultSrc  : in  std_logic_vector(1 downto 0);
    i_MemWrite   : in  std_logic;
    i_MemRead    : in  std_logic;
    i_RegWrite   : in  std_logic;
    i_LoadType   : in  std_logic_vector(2 downto 0);
    i_Halt       : in  std_logic;

    -- Latched outputs to EXE stage
    -- Data
    idex_oRS1    : out std_logic_vector(31 downto 0);
    idex_oRS2    : out std_logic_vector(31 downto 0);
    idex_rd      : out std_logic_vector(4 downto 0);
    idex_rs1     : out std_logic_vector(4 downto 0);
    idex_rs2     : out std_logic_vector(4 downto 0);
    idex_PC      : out std_logic_vector(N-1 downto 0);
    idex_PCplus4 : out std_logic_vector(N-1 downto 0);
    idex_Imm     : out std_logic_vector(31 downto 0);
    idex_funct3   : out std_logic_vector(2 downto 0); -- added for ALU control  
    idex_isJALR  : out std_logic;

    -- Control
    idex_ALUSrcA   : out std_logic;
    idex_ALUSrc    : out std_logic;
    idex_ALUOp     : out std_logic_vector(3 downto 0);
    idex_Branch    : out std_logic;
    idex_Jump      : out std_logic;
    idex_ResultSrc : out std_logic_vector(1 downto 0);
    idex_MemWrite  : out std_logic;
    idex_MemRead   : out std_logic;
    idex_RegWrite  : out std_logic;
    idex_LoadType  : out std_logic_vector(2 downto 0);
    idex_Halt      : out std_logic
  );
end ID_EXE;

architecture structural of ID_EXE is
  -- Components
  component RegN is
    generic(N : integer := 32);
    port(
      i_CLK : in std_logic;
      i_RST : in std_logic;
      i_WE  : in std_logic;
      i_D   : in std_logic_vector(N-1 downto 0);
      o_Q   : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component dffg is
    port(
      i_CLK : in std_logic;
      i_RST : in std_logic;
      i_WE  : in std_logic;
      i_D   : in std_logic;
      o_Q   : out std_logic
    );
  end component;

  -- Flush-gated control inputs (zero when i_FLUSH='1')
  signal s_ALUOp_D     : std_logic_vector(3 downto 0);
  signal s_ResultSrc_D : std_logic_vector(1 downto 0);
  signal s_LoadType_D  : std_logic_vector(2 downto 0);
  signal s_ALUSrcA_D, s_ALUSrc_D, s_Branch_D, s_Jump_D,
         s_MemWrite_D, s_MemRead_D, s_RegWrite_D, s_Halt_D, s_isJALR_D: std_logic;
begin
  -- Flush = bubble: zero ONLY control signals; data still latches.
  s_ALUSrcA_D  <= '0'                       when i_FLUSH='1' else i_ALUSrcA;
  s_ALUSrc_D   <= '0'                       when i_FLUSH='1' else i_ALUSrc;
  s_ALUOp_D    <= (others => '0')           when i_FLUSH='1' else i_ALUOp;
  s_Branch_D   <= '0'                       when i_FLUSH='1' else i_Branch;
  s_Jump_D     <= '0'                       when i_FLUSH='1' else i_Jump;
  s_ResultSrc_D<= (others => '0')           when i_FLUSH='1' else i_ResultSrc;
  s_MemWrite_D <= '0'                       when i_FLUSH='1' else i_MemWrite;
  s_MemRead_D  <= '0'                       when i_FLUSH='1' else i_MemRead;
  s_RegWrite_D <= '0'                       when i_FLUSH='1' else i_RegWrite;
  s_LoadType_D <= (others => '0')           when i_FLUSH='1' else i_LoadType;
  s_Halt_D     <= '0'                       when i_FLUSH='1' else i_Halt;
  s_isJALR_D    <= '0'             when i_FLUSH='1' else i_isJALR;

  -- Data registers
  r_oRS1 : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_oRS1, o_Q => idex_oRS1);

  r_oRS2 : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_oRS2, o_Q => idex_oRS2);

  r_rd : RegN
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_rd, o_Q => idex_rd);

  r_rs1 : RegN
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_rs1, o_Q => idex_rs1);

  r_rs2 : RegN
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_rs2, o_Q => idex_rs2);

  r_PC : RegN
    generic map(N => N)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_PC, o_Q => idex_PC);

  r_PCplus4 : RegN
    generic map(N => N)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_PCplus4, o_Q => idex_PCplus4);

  r_Imm : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_Imm, o_Q => idex_Imm);

  r_funct3 : RegN
    generic map(N => 3)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
            i_D => i_funct3, o_Q => idex_funct3);

  -- Control registers (flush-gated)
  r_ALUSrcA : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_ALUSrcA_D, o_Q => idex_ALUSrcA);

  r_ALUSrc : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_ALUSrc_D, o_Q => idex_ALUSrc);

  r_ALUOp : RegN
    generic map(N => 4)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_ALUOp_D, o_Q => idex_ALUOp);

  r_Branch : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_Branch_D, o_Q => idex_Branch);

  r_Jump : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_Jump_D, o_Q => idex_Jump);

  r_isJALR : dffg
  port map(i_CLK=>i_CLK, i_RST=>i_RST, i_WE=>i_WE,
           i_D=>s_isJALR_D, o_Q=>idex_isJALR);

  r_ResultSrc : RegN
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_ResultSrc_D, o_Q => idex_ResultSrc);

  r_MemWrite : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_MemWrite_D, o_Q => idex_MemWrite);

  r_MemRead : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_MemRead_D, o_Q => idex_MemRead);

  r_RegWrite : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_RegWrite_D, o_Q => idex_RegWrite);

  r_LoadType : RegN
    generic map(N => 3)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_LoadType_D, o_Q => idex_LoadType);

  r_Halt : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_Halt_D, o_Q => idex_Halt);

end structural;
