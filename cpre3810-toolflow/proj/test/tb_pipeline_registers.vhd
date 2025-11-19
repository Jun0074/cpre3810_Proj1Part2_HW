library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pipeline_registers is
end tb_pipeline_registers;

architecture sim of tb_pipeline_registers is
  constant N     : integer := 32;
  constant T_CLK : time    := 10 ns;
  constant NOP32 : std_logic_vector(31 downto 0) := x"00000013"; -- addi x0, x0 ,0

  signal clk, rst : std_logic := '0';

  -- IF/ID
  signal if_we, if_flush : std_logic := '1';
  signal if_i_pc, if_i_pc4, if_i_instr : std_logic_vector(N-1 downto 0) := (others=>'0');
  signal if_o_pc, if_o_pc4, if_o_instr : std_logic_vector(N-1 downto 0);

  -- ID/EX
  signal id_we, id_flush : std_logic := '1';
  signal id_i_pc, id_i_pc4, id_o_pc, id_o_pc4 : std_logic_vector(N-1 downto 0);
  -- tie-off/observe ports
  signal id_i_rs1, id_i_rs2, id_i_imm : std_logic_vector(31 downto 0) := (others=>'0');
  signal id_i_rd, id_i_s1, id_i_s2    : std_logic_vector(4 downto 0)  := (others=>'0');
  signal id_i_funct3                  : std_logic_vector(2 downto 0)  := (others=>'0');
  signal id_i_isjalr                  : std_logic := '0';
  signal id_i_alusrca, id_i_alusrc,
         id_i_branch, id_i_jump,
         id_i_memwrite, id_i_memread,
         id_i_regwrite, id_i_halt     : std_logic := '0';
  signal id_i_aluop                   : std_logic_vector(3 downto 0)  := (others=>'0');
  signal id_i_resultsrc               : std_logic_vector(1 downto 0)  := (others=>'0');
  signal id_i_loadtype                : std_logic_vector(2 downto 0)  := (others=>'0');

  -- observe some ID/EX control outs (for flush)
  signal id_o_regwrite, id_o_memwrite, id_o_memread, id_o_branch, id_o_jump, id_o_halt : std_logic;
  signal id_o_aluop       : std_logic_vector(3 downto 0);
  signal id_o_resultsrc   : std_logic_vector(1 downto 0);
  signal id_o_loadtype    : std_logic_vector(2 downto 0);
  signal id_o_isjalr      : std_logic;

  -- EX/MEM
  signal ex_we : std_logic := '1';
  signal ex_i_pc4, ex_o_pc4 : std_logic_vector(N-1 downto 0);
  signal ex_i_alu, ex_i_rs2, ex_i_imm : std_logic_vector(31 downto 0) := (others=>'0');
  signal ex_i_rd                        : std_logic_vector(4 downto 0)  := (others=>'0');
  signal ex_i_resultsrc                 : std_logic_vector(1 downto 0)  := (others=>'0');
  signal ex_i_loadtype                  : std_logic_vector(2 downto 0)  := (others=>'0');
  signal ex_i_regwrite, ex_i_memwrite, ex_i_memread, ex_i_halt : std_logic := '0';
  signal ex_o_regwrite, ex_o_memwrite, ex_o_memread, ex_o_halt : std_logic;
  signal ex_o_resultsrc                 : std_logic_vector(1 downto 0);
  signal ex_o_loadtype                  : std_logic_vector(2 downto 0);
  signal ex_o_rd                        : std_logic_vector(4 downto 0);
  signal ex_o_alu, ex_o_rs2, ex_o_imm   : std_logic_vector(31 downto 0);

  -- MEM/WB
  signal mw_we : std_logic := '1';
  signal mw_i_pc4, mw_o_pc4 : std_logic_vector(N-1 downto 0);
  signal mw_i_rd           : std_logic_vector(4 downto 0)  := (others=>'0');
  signal mw_i_read, mw_i_loadext, mw_i_alu, mw_i_immu : std_logic_vector(31 downto 0) := (others=>'0');
  signal mw_i_resultsrc    : std_logic_vector(1 downto 0) := (others=>'0');
  signal mw_i_regwrite, mw_i_halt : std_logic := '0';
  signal mw_o_resultsrc    : std_logic_vector(1 downto 0);
  signal mw_o_regwrite, mw_o_halt : std_logic;
  signal mw_o_rd           : std_logic_vector(4 downto 0);
  signal mw_o_read, mw_o_loadext, mw_o_alu, mw_o_immu : std_logic_vector(31 downto 0);

  -- simple token generator
  signal token : std_logic_vector(31 downto 0) := (others=>'0');

  -- Components
  component IFID_Register is
    generic ( N : integer := 32 );
    port(
      i_CLK,i_RST,i_WE,i_FLUSH : in std_logic;
      i_PC,i_PCplus4           : in std_logic_vector(N-1 downto 0);
      i_Instr                  : in std_logic_vector(31 downto 0);
      ifid_PC, ifid_PCplus4    : out std_logic_vector(N-1 downto 0);
      ifid_Inst                : out std_logic_vector(31 downto 0)
    );
  end component;

  component ID_EXE is
    generic ( N : integer := 32 );
    port(
      i_CLK,i_RST,i_WE,i_FLUSH : in std_logic;
      i_oRS1,i_oRS2            : in  std_logic_vector(31 downto 0);
      i_rd,i_rs1,i_rs2         : in  std_logic_vector(4 downto 0);
      i_PC,i_PCplus4           : in  std_logic_vector(N-1 downto 0);
      i_Imm                    : in  std_logic_vector(31 downto 0);
      i_funct3                 : in  std_logic_vector(2 downto 0);
      i_isJALR                 : in  std_logic;
      i_ALUSrcA,i_ALUSrc,i_Branch,i_Jump,i_MemWrite,i_MemRead,i_RegWrite,i_Halt : in std_logic;
      i_ALUOp                  : in  std_logic_vector(3 downto 0);
      i_ResultSrc              : in  std_logic_vector(1 downto 0);
      i_LoadType               : in  std_logic_vector(2 downto 0);

      idex_oRS1,idex_oRS2      : out std_logic_vector(31 downto 0);
      idex_rd,idex_rs1,idex_rs2: out std_logic_vector(4 downto 0);
      idex_PC,idex_PCplus4     : out std_logic_vector(N-1 downto 0);
      idex_Imm                 : out std_logic_vector(31 downto 0);
      idex_funct3              : out std_logic_vector(2 downto 0);
      idex_isJALR              : out std_logic;

      idex_ALUSrcA,idex_ALUSrc,idex_Branch,idex_Jump,
      idex_MemWrite,idex_MemRead,idex_RegWrite,idex_Halt : out std_logic;
      idex_ALUOp               : out std_logic_vector(3 downto 0);
      idex_ResultSrc           : out std_logic_vector(1 downto 0);
      idex_LoadType            : out std_logic_vector(2 downto 0)
    );
  end component;

  component EX_MEM is
    generic ( N : integer := 32 );
    port(
      i_CLK,i_RST,i_WE : in std_logic;
      i_ALUResult,i_RS2,i_Imm  : in std_logic_vector(31 downto 0);
      i_rd                     : in std_logic_vector(4 downto 0);
      i_PCplus4                : in std_logic_vector(N-1 downto 0);
      i_MemWrite,i_MemRead,i_RegWrite : in std_logic;
      i_ResultSrc              : in std_logic_vector(1 downto 0);
      i_LoadType               : in std_logic_vector(2 downto 0);
      i_Halt                   : in std_logic;

      exmem_ALUResult, exmem_oRS2, exmem_Imm : out std_logic_vector(31 downto 0);
      exmem_rd                                : out std_logic_vector(4 downto 0);
      exmem_PCplus4                           : out std_logic_vector(N-1 downto 0);
      exmem_MemWrite,exmem_MemRead,exmem_RegWrite : out std_logic;
      exmem_ResultSrc                         : out std_logic_vector(1 downto 0);
      exmem_LoadType                          : out std_logic_vector(2 downto 0);
      exmem_Halt                              : out std_logic
    );
  end component;

  component MEM_WB is
    port(
      i_CLK,i_RST,i_WE : in std_logic;
      i_ReadData,i_LoadExt,i_ALUResult,i_PCplus4,i_ImmU : in std_logic_vector(31 downto 0);
      i_rd                     : in std_logic_vector(4 downto 0);
      i_ResultSrc              : in std_logic_vector(1 downto 0);
      i_RegWrite,i_Halt        : in std_logic;

      memwb_ReadData,memwb_LoadExt,memwb_ALUResult,memwb_PCplus4,memwb_ImmU : out std_logic_vector(31 downto 0);
      memwb_rd : out std_logic_vector(4 downto 0);
      memwb_ResultSrc : out std_logic_vector(1 downto 0);
      memwb_RegWrite  : out std_logic;
      memwb_Halt      : out std_logic
    );
  end component;

begin
  -- clock
  clk <= not clk after T_CLK/2;

  -- reset (2-3 cycles)
  process
  begin
    rst <= '1';
    wait for 3*T_CLK;
    rst <= '0';
    wait;
  end process;

  -- DUTs
  U_IFID: IFID_Register
    generic map(N=>N)
    port map(
      i_CLK=>clk, i_RST=>rst, i_WE=>if_we, i_FLUSH=>if_flush,
      i_PC=>if_i_pc, i_PCplus4=>if_i_pc4, i_Instr=>if_i_instr,
      ifid_PC=>if_o_pc, ifid_PCplus4=>if_o_pc4, ifid_Inst=>if_o_instr
    );

  U_IDEX: ID_EXE
    generic map(N=>N)
    port map(
      i_CLK=>clk, i_RST=>rst, i_WE=>id_we, i_FLUSH=>id_flush,
      i_oRS1=>id_i_rs1, i_oRS2=>id_i_rs2,
      i_rd=>id_i_rd, i_rs1=>id_i_s1, i_rs2=>id_i_s2,
      i_PC=>id_i_pc, i_PCplus4=>id_i_pc4, i_Imm=>id_i_imm,
      i_funct3=>id_i_funct3, i_isJALR=>id_i_isjalr,
      i_ALUSrcA=>id_i_alusrca, i_ALUSrc=>id_i_alusrc,
      i_Branch=>id_i_branch, i_Jump=>id_i_jump,
      i_MemWrite=>id_i_memwrite, i_MemRead=>id_i_memread,
      i_RegWrite=>id_i_regwrite, i_Halt=>id_i_halt,
      i_ALUOp=>id_i_aluop, i_ResultSrc=>id_i_resultsrc, i_LoadType=>id_i_loadtype,

      idex_oRS1=>open, idex_oRS2=>open,
      idex_rd=>open, idex_rs1=>open, idex_rs2=>open,
      idex_PC=>id_o_pc, idex_PCplus4=>id_o_pc4, idex_Imm=>open,
      idex_funct3=>open, idex_isJALR=>id_o_isjalr,

      idex_ALUSrcA=>open, idex_ALUSrc=>open, idex_Branch=>id_o_branch, idex_Jump=>id_o_jump,
      idex_MemWrite=>id_o_memwrite, idex_MemRead=>id_o_memread, idex_RegWrite=>id_o_regwrite, idex_Halt=>id_o_halt,
      idex_ALUOp=>id_o_aluop, idex_ResultSrc=>id_o_resultsrc, idex_LoadType=>id_o_loadtype
    );

  U_EXMEM: EX_MEM
    generic map(N=>N)
    port map(
      i_CLK=>clk, i_RST=>rst, i_WE=>ex_we,
      i_ALUResult=>ex_i_alu, i_RS2=>ex_i_rs2, i_Imm=>ex_i_imm, i_rd=>ex_i_rd,
      i_PCplus4=>ex_i_pc4,
      i_MemWrite=>ex_i_memwrite, i_MemRead=>ex_i_memread, i_RegWrite=>ex_i_regwrite,
      i_ResultSrc=>ex_i_resultsrc, i_LoadType=>ex_i_loadtype, i_Halt=>ex_i_halt,

      exmem_ALUResult=>ex_o_alu, exmem_oRS2=>ex_o_rs2, exmem_Imm=>ex_o_imm,
      exmem_rd=>ex_o_rd, exmem_PCplus4=>ex_o_pc4,
      exmem_MemWrite=>ex_o_memwrite, exmem_MemRead=>ex_o_memread, exmem_RegWrite=>ex_o_regwrite,
      exmem_ResultSrc=>ex_o_resultsrc, exmem_LoadType=>ex_o_loadtype, exmem_Halt=>ex_o_halt
    );

  U_MEMWB: MEM_WB
    port map(
      i_CLK=>clk, i_RST=>rst, i_WE=>mw_we,
      i_ReadData=>mw_i_read, i_LoadExt=>mw_i_loadext, i_ALUResult=>mw_i_alu,
      i_PCplus4=>mw_i_pc4, i_ImmU=>mw_i_immu, i_rd=>mw_i_rd,
      i_ResultSrc=>mw_i_resultsrc, i_RegWrite=>mw_i_regwrite, i_Halt=>mw_i_halt,

      memwb_ReadData=>mw_o_read, memwb_LoadExt=>mw_o_loadext,
      memwb_ALUResult=>mw_o_alu, memwb_PCplus4=>mw_o_pc4, memwb_ImmU=>mw_o_immu,
      memwb_rd=>mw_o_rd, memwb_ResultSrc=>mw_o_resultsrc, memwb_RegWrite=>mw_o_regwrite,
      memwb_Halt=>mw_o_halt
    );

  -- Chain PC+4 across the 4 regs
  id_i_pc    <= if_o_pc;
  id_i_pc4   <= if_o_pc4;
  ex_i_pc4   <= id_o_pc4;
  mw_i_pc4   <= ex_o_pc4;

  -- Simple token source: new value each cycle in baseline phases
  process(clk)
    variable cnt : unsigned(31 downto 0) := (others=>'0');
  begin
    if rising_edge(clk) then
      cnt   := cnt + 16;                     -- step by 16 for readability
      token <= std_logic_vector(cnt);        -- what we drive into IF/ID
    end if;
  end process;

  -- Start test here
  stim: process
  -- tick: helper method to advance the simulation by exactly one clock cycle.
    procedure tick is begin wait until rising_edge(clk); end procedure;
  begin
    -- defaults
    if_we <= '1'; if_flush <= '0';
    id_we <= '1'; id_flush <= '0';
    ex_we <= '1';
    mw_we <= '1';

    wait until rst='0'; tick;

    -- 1. Baseline: push a new token every cycle
    for i in 1 to 6 loop
      if_i_pc    <= std_logic_vector(unsigned(token) - 4);
      if_i_pc4   <= token;
      if_i_instr <= NOP32;
      tick;
    end loop;

    -- 2. Individual STALL tests
    -- i. Stall IF/ID (WE=0) for 1 cycle
    if_we <= '0';
    if_i_pc  <= x"AAAAAAAA"; -- change inputs; should NOT be latched
    if_i_pc4 <= x"BBBBBBBB";
    tick;
    if_we <= '1';  -- resume

    -- ii. Stall ID/EX for 1 cycle
    id_we <= '0';
    tick;
    id_we <= '1';

    -- iii. Stall EX/MEM for 1 cycle
    ex_we <= '0';
    tick;
    ex_we <= '1';

    -- iv. Stall MEM/WB for 1 cycle
    mw_we <= '0';
    tick;
    mw_we <= '1';

    -- 3. Individual FLUSH tests
    -- i. IF/ID flush (instruction becomes NOP on output that cycle)
    if_i_instr <= x"DEADBEEF";
    if_flush   <= '1';
    tick;
    if_flush   <= '0';
    if_i_instr <= NOP32;

    -- ii. ID/EX flush (zero control for one cycle)
    id_i_regwrite <= '1'; id_i_memwrite <= '1'; id_i_memread <= '1';
    id_i_branch   <= '1'; id_i_jump     <= '1'; id_i_halt    <= '1';
    id_i_aluop    <= "1010"; id_i_resultsrc <= "11"; id_i_loadtype <= "101";
    id_flush <= '1';
    tick;
    id_flush <= '0';
    -- return controls to zero
    id_i_regwrite <= '0'; id_i_memwrite <= '0'; id_i_memread <= '0';
    id_i_branch   <= '0'; id_i_jump     <= '0'; id_i_halt    <= '0';
    id_i_aluop    <= "0000"; id_i_resultsrc <= "00"; id_i_loadtype <= "000";

    -- A few more baseline cycles to see pipeline flowing again
    for i in 1 to 4 loop
      if_i_pc    <= std_logic_vector(unsigned(token) - 4);
      if_i_pc4   <= token;
      if_i_instr <= NOP32;
      tick;
    end loop;

    wait;
  end process;
end sim;