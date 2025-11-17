-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- Author: Tian Jun Teoh, Austin Nguyen
-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor  
-- implementation.

-- 01/29/2019 by H3::Design created.
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0); -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.
       oHalt           : out std_logic); -- added output for halt
end  RISCV_Processor;


architecture structure of RISCV_Processor is
	
  -- Required data memory signals
  signal s_DMemWr       : std_logic; -- TODO: use this signal as the final active high data memory write enable signal
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
  signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
  signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
  -- Required register file signals 
  signal s_RegWr        : std_logic; -- TODO: use this signal as the final active high write enable input to the register file
  signal s_RegWrAddr    : std_logic_vector(4 downto 0); -- TODO: use this signal as the final destination register address input
  signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_NextInstAddr instead
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
  signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal 

  -- Required halt signal -- for simulation
  signal s_Halt_Pipeline : std_logic;  -- internal halt signal from control unit to be passed through pipeline
  signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Opcode: 01 0100)

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;  -- TODO: this signal indicates an overflow exception would have been initiated

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
        clk          : in std_logic;
        addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
        data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
        we           : in std_logic := '1';
        q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
    end component;

-- TODO: You may add any additional signals or components your implementation 
--       requires below this comment

  -- Register file read buses
  signal s_RS1Data  : std_logic_vector(N-1 downto 0);
  signal s_RS2Data  : std_logic_vector(N-1 downto 0);

  -- ALU inputs/flags
  signal s_ALUResult : std_logic_vector(N-1 downto 0);  -- ALU result (tie to oALUOut later)
  signal s_ALU_A    : std_logic_vector(N-1 downto 0);
  signal s_ALU_B    : std_logic_vector(N-1 downto 0);
  signal s_Zero     : std_logic;
  signal s_LT       : std_logic;
  signal s_LTU      : std_logic;

  -- PC select (branch/jump)
  signal s_PCsrc    : std_logic;
  signal s_NewPC    : std_logic_vector(N-1 downto 0);

  -- Branch/jump glue
  signal s_BrTaken    : std_logic;
  signal s_BrTarget   : std_logic_vector(N-1 downto 0);  -- PC + immB
  signal s_JumpTarget : std_logic_vector(N-1 downto 0);  -- JAL/JALR target
  signal s_isJALR     : std_logic;                       -- opcode check
  -- signal s_Flush_EX    : std_logic;  -- flush IF/ID and zero-control in ID/EXE
  
  -- signal of the control
  -- control
-- ========= Bit-field format banner (MSB..LSB) =========
-- [19]    [18]     [17:14]     [13:11]     [10:9]   [8]   [7]   [6]  [5]  [4]   [3:1]     [0]
-- ALUSrc  ALUSrcA  ALUOp(4)    ImmType(3)  Result   MWr   RWr  MRd  Jump Brch loadType(3) halt
-- Encodings:
--   ImmType  : 000=I, 001=S, 010=B, 011=U, 100=J
--   ResultSrc: 00=ALU, 01=MEM, 10=PC+4, 11=ImmU(LUI)
--   loadType : 000=lw, 001=lh, 010=lb, 011=lbu, 100=lhu
-- NOTE: '-' denotes don't-care for synthesis.
-----------------------------------------------------------------
  signal s_Ctrl        : std_logic_vector(19 downto 0);
  signal s_ALUSrc, s_ALUSrcA, s_MemWrite, s_RegWrite, s_MemRead, s_Jump, s_Branch : std_logic;
  signal s_ALUOp       : std_logic_vector(3 downto 0);
  signal s_ImmType     : std_logic_vector(2 downto 0);
  signal s_ResultSrc   : std_logic_vector(1 downto 0);
  signal s_loadType    : std_logic_vector(2 downto 0);

  -- read-path extension result for loadType
  signal s_LoadExt : std_logic_vector(31 downto 0);
  -- Write-back / immediate / pc+4
  signal s_PCplus4   : std_logic_vector(N-1 downto 0);
  
  -- ImmGen output
  signal s_ImmExt    : std_logic_vector(N-1 downto 0); -- from ImmGen (placeholder)

-- Signals for Pipeline register
  -- IF/ID
  signal ifid_PC       : std_logic_vector(N-1 downto 0);
  signal ifid_PCplus4  : std_logic_vector(N-1 downto 0);
  signal ifid_Inst     : std_logic_vector(31 downto 0);

  -- ID/EXE
  signal idex_oRS1     : std_logic_vector(31 downto 0);
  signal idex_oRS2     : std_logic_vector(31 downto 0);
  signal idex_rd       : std_logic_vector(4 downto 0);
  signal idex_rs1      : std_logic_vector(4 downto 0);
  signal idex_rs2      : std_logic_vector(4 downto 0);
  signal idex_PC       : std_logic_vector(N-1 downto 0);
  signal idex_PCplus4  : std_logic_vector(N-1 downto 0);
  signal idex_Imm      : std_logic_vector(31 downto 0);
  signal idex_funct3   : std_logic_vector(2 downto 0);
  signal idex_isJALR   : std_logic;
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

  -- EX/MEM
  signal exmem_ALUResult : std_logic_vector(31 downto 0);
  signal exmem_oRS2      : std_logic_vector(31 downto 0);
  signal exmem_rd        : std_logic_vector(4 downto 0);
  signal exmem_PCplus4   : std_logic_vector(N-1 downto 0);
  signal exmem_Imm       : std_logic_vector(31 downto 0);
  signal exmem_MemWrite  : std_logic;
  signal exmem_MemRead   : std_logic;
  signal exmem_RegWrite  : std_logic;
  signal exmem_ResultSrc : std_logic_vector(1 downto 0);
  signal exmem_LoadType  : std_logic_vector(2 downto 0);
  signal exmem_Halt      : std_logic;

  -- MEM/WB
  signal memwb_ReadData  : std_logic_vector(31 downto 0);
  signal memwb_LoadExt   : std_logic_vector(31 downto 0);
  signal memwb_ALUResult : std_logic_vector(31 downto 0);
  signal memwb_PCplus4   : std_logic_vector(31 downto 0);
  signal memwb_ImmU      : std_logic_vector(31 downto 0);
  signal memwb_rd        : std_logic_vector(4 downto 0);
  signal memwb_ResultSrc : std_logic_vector(1 downto 0);
  signal memwb_RegWrite  : std_logic;
  signal memwb_Halt      : std_logic;


-- declaration
  --ALU
  component ALU is
    port(
      i_A       : in  std_logic_vector(31 downto 0);
      i_B       : in  std_logic_vector(31 downto 0);
      i_ALUOp   : in  std_logic_vector(3 downto 0);
      o_Y       : out std_logic_vector(31 downto 0);
      o_Zero    : out std_logic;
      o_LT      : out std_logic;
      o_LTU     : out std_logic;
      o_Ovfl    : out std_logic
    );
  end component;

-- TODO: Immediate generator (outputs I/S/B/U/J immediates per s_ImmType)

  -- control unit
  component control_unit is
    port(
      i_opcode   : in  std_logic_vector(6 downto 0);
      i_funct3   : in  std_logic_vector(2 downto 0);
      i_funct7   : in  std_logic_vector(6 downto 0);
      o_Ctrl_Unt : out std_logic_vector(19 downto 0)
    );
  end component;

  -- fetch
  component fetch is
    generic(N : integer := 32);
    port(
      i_clk : in std_logic;
      i_rst : in std_logic; -- Active-high reset
      i_PCsrc : in std_logic;
      i_newPC : in std_logic_vector(N-1 downto 0); -- Immediate Input
      o_PC  : out std_logic_vector(N-1 downto 0)
    );
  end component;

  -- LoadType: 000=lw, 001=lh, 010=lb, 011=lbu, 100=lhu
  component loadType is
    port(
      i_word     : in  std_logic_vector(31 downto 0); -- DMEM 32-bit read
      i_addr_low : in  std_logic_vector(1 downto 0);  -- address(1 downto 0)
      i_LType    : in  std_logic_vector(2 downto 0);  -- s_Ctrl(3 downto 1)
      o_data     : out std_logic_vector(31 downto 0)  -- extended to 32-bit
    );
  end component;

  -- Register
  component RegFile is
    port (
      i_CLK : in  std_logic;
      i_RST : in  std_logic;
      i_WE  : in  std_logic;                          -- global write enable
      i_RD  : in  std_logic_vector(4 downto 0);       -- dest reg addr
      i_WD  : in  std_logic_vector(31 downto 0);      -- write data
      i_RS1 : in  std_logic_vector(4 downto 0);
      i_RS2 : in  std_logic_vector(4 downto 0);
      o_RS1 : out std_logic_vector(31 downto 0);
      o_RS2 : out std_logic_vector(31 downto 0)
    );
  end component;

  -- ImmGen
  component immGen is
    port(
      i_instr   : in  std_logic_vector(31 downto 0);
      i_immType : in  std_logic_vector(2 downto 0);  -- Instruction type selector
      o_imm     : out std_logic_vector(31 downto 0)
    );
  end component;

-- Pipeline Registers components instantiation
  component IFID_Register is
    generic ( N : integer := 32 );
    port(
      i_CLK, i_RST, i_WE, i_FLUSH : in std_logic;
      i_PC, i_PCplus4             : in std_logic_vector(N-1 downto 0);
      i_Instr                     : in std_logic_vector(31 downto 0);
      ifid_PC, ifid_PCplus4       : out std_logic_vector(N-1 downto 0);
      ifid_Inst                   : out std_logic_vector(31 downto 0)
    );
  end component;

  component ID_EXE is
    generic ( N : integer := 32 );
    port(
      i_CLK, i_RST, i_WE, i_FLUSH : in std_logic;
      i_oRS1, i_oRS2  : in  std_logic_vector(31 downto 0);
      i_rd, i_rs1, i_rs2 : in std_logic_vector(4 downto 0);
      i_PC, i_PCplus4 : in  std_logic_vector(N-1 downto 0);
      i_Imm           : in  std_logic_vector(31 downto 0);
      i_funct3        : in  std_logic_vector(2 downto 0);
      i_isJALR        : in  std_logic;
      i_ALUSrcA, i_ALUSrc, i_Branch, i_Jump, i_MemWrite, i_MemRead, i_RegWrite, i_Halt : in std_logic;
      i_ALUOp         : in  std_logic_vector(3 downto 0);
      i_ResultSrc     : in  std_logic_vector(1 downto 0);
      i_LoadType      : in  std_logic_vector(2 downto 0);

      idex_oRS1, idex_oRS2 : out std_logic_vector(31 downto 0);
      idex_rd, idex_rs1, idex_rs2 : out std_logic_vector(4 downto 0);
      idex_PC, idex_PCplus4 : out std_logic_vector(N-1 downto 0);
      idex_Imm           : out std_logic_vector(31 downto 0);
      idex_funct3        : out std_logic_vector(2 downto 0);
      idex_isJALR        : out std_logic;
      idex_ALUSrcA, idex_ALUSrc, idex_Branch, idex_Jump, idex_MemWrite, idex_MemRead, idex_RegWrite, idex_Halt : out std_logic;
      idex_ALUOp         : out std_logic_vector(3 downto 0);
      idex_ResultSrc     : out std_logic_vector(1 downto 0);
      idex_LoadType      : out std_logic_vector(2 downto 0)
    );
  end component;

  component EX_MEM is
    generic ( N : integer := 32 );
    port(
      i_CLK, i_RST, i_WE : in std_logic;
      i_ALUResult    : in  std_logic_vector(31 downto 0);
      i_RS2          : in  std_logic_vector(31 downto 0);
      i_rd           : in  std_logic_vector(4 downto 0);
      i_PCplus4      : in  std_logic_vector(N-1 downto 0);
      i_Imm          : in  std_logic_vector(31 downto 0);
      i_MemWrite, i_MemRead, i_RegWrite, i_Halt : in std_logic;
      i_ResultSrc    : in  std_logic_vector(1 downto 0);
      i_LoadType     : in  std_logic_vector(2 downto 0);

      exmem_ALUResult : out std_logic_vector(31 downto 0);
      exmem_oRS2      : out std_logic_vector(31 downto 0);
      exmem_rd        : out std_logic_vector(4 downto 0);
      exmem_PCplus4   : out std_logic_vector(N-1 downto 0);
      exmem_Imm       : out std_logic_vector(31 downto 0);
      exmem_MemWrite, exmem_MemRead, exmem_RegWrite, exmem_Halt : out std_logic;
      exmem_ResultSrc : out std_logic_vector(1 downto 0);
      exmem_LoadType  : out std_logic_vector(2 downto 0)
    );
  end component;

  component MEM_WB is
    port(
      i_CLK, i_RST, i_WE : in std_logic;
      i_ReadData, i_LoadExt, i_ALUResult, i_PCplus4, i_ImmU : in std_logic_vector(31 downto 0);
      i_rd : in std_logic_vector(4 downto 0);
      i_ResultSrc : in std_logic_vector(1 downto 0);
      i_RegWrite, i_Halt : in std_logic;

      memwb_ReadData, memwb_LoadExt, memwb_ALUResult, memwb_PCplus4, memwb_ImmU : out std_logic_vector(31 downto 0);
      memwb_rd : out std_logic_vector(4 downto 0);
      memwb_ResultSrc : out std_logic_vector(1 downto 0);
      memwb_RegWrite, memwb_Halt : out std_logic
    );
  end component;


-- main architecture body
begin
  -- IF stage
  with iInstLd select
    s_IMemAddr <= s_NextInstAddr when '0', iInstAddr when others;

  -- fetch (PC)
  FETCH_PC: fetch
    generic map(N => N)
    port map(
      i_clk   => iCLK,
      i_rst   => iRST,
      i_PCsrc => s_PCsrc,   -- PC source select: 0 = PC+4, 1 = new branch/jump target
      i_newPC => s_NewPC,   -- Next PC input (from ALU result for branch/jump)
      o_PC    => s_NextInstAddr   -- Output current PC value to instruction memory
    );

  -- PC+4 in IF that needs to be passed to ID/EXE and MEM/WB stages
  s_PCplus4 <= std_logic_vector(unsigned(s_NextInstAddr) + 4);

   -- Instruction Memory
  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);
  
  -- IF/ID register (stall disabled, flush from EX)
  IFID: IFID_Register
    generic map(N => N)
    port map(
      i_CLK => iCLK, i_RST => iRST,
      i_WE  => '1',                  -- no stall yet
      i_FLUSH => s_PCsrc,         --0 for SW-- flush on taken branch/jump 
      i_PC => s_NextInstAddr,
      i_PCplus4 => s_PCplus4,
      i_Instr => s_Inst,
      ifid_PC => ifid_PC,
      ifid_PCplus4 => ifid_PCplus4,
      ifid_Inst => ifid_Inst
    );

  -- ID stage

  -- Control Unit
  CONTROL: control_unit
    port map(
      i_opcode   => ifid_Inst(6 downto 0),       -- opcode[6:0]
      i_funct3   => ifid_Inst(14 downto 12),     -- funct3[2:0]
      i_funct7   => ifid_Inst(31 downto 25),     -- funct7[6:0]
      o_Ctrl_Unt => s_Ctrl                    -- packed 20-bit control bus
    );

      -- Unpack of 20-bit Ctrl
      s_ALUSrc   <= s_Ctrl(19);
      s_ALUSrcA  <= s_Ctrl(18);
      s_ALUOp    <= s_Ctrl(17 downto 14);
      s_ImmType  <= s_Ctrl(13 downto 11);
      s_ResultSrc<= s_Ctrl(10 downto 9);
      s_MemWrite <= s_Ctrl(8);
      s_RegWrite <= s_Ctrl(7);
      s_MemRead  <= s_Ctrl(6);
      s_Jump     <= s_Ctrl(5);
      s_Branch   <= s_Ctrl(4);
      s_LoadType <= s_Ctrl(3 downto 1);
      s_Halt_Pipeline     <= s_Ctrl(0);

  
  -- Connect s_RegWrAddr to address in instructions
  --s_RegWrAddr <= s_Inst(11 downto 7);

  -- Register file
  u_RegFile: RegFile
    port map(
      i_CLK => iCLK,
      i_RST => iRST,
      i_WE  => memwb_RegWrite,
      i_RD  => memwb_rd,
      i_WD  => s_RegWrData,
      i_RS1 => ifid_Inst(19 downto 15),
      i_RS2 => ifid_Inst(24 downto 20),
      o_RS1 => s_RS1Data,
      o_RS2 => s_RS2Data
      );

  -- ImmGen
  IMMEDIATEGEN: immGen
    port map(
      i_instr   => ifid_Inst,
      i_immType => s_ImmType,  -- Instruction type selector
      o_imm     => s_ImmExt
    );

  -- isJALR detection in ID stage that will be passed to EXE stage
  s_isJALR <= '1' when ifid_Inst(6 downto 0) = "1100111" else '0';
  
  -- ID/EXE register (flush zeros control; data still latches)
  IDEX: ID_EXE
    generic map(N => N)
    port map(
      i_CLK => iCLK, i_RST => iRST, i_WE => '1', 
      i_FLUSH => '0', --0 for SW-- flush on taken branch/jump

      i_oRS1 => s_RS1Data,   i_oRS2 => s_RS2Data,
      i_rd => ifid_Inst(11 downto 7),
      i_rs1 => ifid_Inst(19 downto 15),
      i_rs2 => ifid_Inst(24 downto 20),
      i_PC => ifid_PC,       i_PCplus4 => ifid_PCplus4,
      i_Imm => s_ImmExt,
      i_funct3 => ifid_Inst(14 downto 12),
      i_isJALR => s_isJALR,

      i_ALUSrcA => s_ALUSrcA, i_ALUSrc => s_ALUSrc,
      i_ALUOp => s_ALUOp, i_Branch => s_Branch, i_Jump => s_Jump,
      i_ResultSrc => s_ResultSrc,
      i_MemWrite => s_MemWrite, i_MemRead => s_MemRead,
      i_RegWrite => s_RegWrite, i_LoadType => s_LoadType, i_Halt => s_Halt_Pipeline,

      idex_oRS1 => idex_oRS1, idex_oRS2 => idex_oRS2,
      idex_rd => idex_rd, idex_rs1 => idex_rs1, idex_rs2 => idex_rs2,
      idex_PC => idex_PC, idex_PCplus4 => idex_PCplus4,
      idex_Imm => idex_Imm, idex_funct3 => idex_funct3, idex_isJALR => idex_isJALR,
      idex_ALUSrcA => idex_ALUSrcA, idex_ALUSrc => idex_ALUSrc,
      idex_Branch => idex_Branch, idex_Jump => idex_Jump,
      idex_MemWrite => idex_MemWrite, idex_MemRead => idex_MemRead,
      idex_RegWrite => idex_RegWrite, idex_LoadType => idex_LoadType, idex_Halt => idex_Halt,
      idex_ALUOp => idex_ALUOp, idex_ResultSrc => idex_ResultSrc
    );

 
  -- EXE stage
  -- ALU Input MUX 1, operand A: 0=RS1, 1=PC
  s_ALU_A <= idex_PC  when idex_ALUSrcA = '1' else idex_oRS1;

  -- ALU Input MUX 2, operand B: 0=RS2, 1=Imm
  s_ALU_B <= idex_Imm when idex_ALUSrc  = '1' else idex_oRS2;

  u_ALU: ALU
    port map(
      i_A       => s_ALU_A,
      i_B       => s_ALU_B,
      i_ALUOp   => idex_ALUOp,
      o_Y       => s_ALUResult,
      o_Zero    => s_Zero,
      o_LT      => s_LT,
      o_LTU     => s_LTU
      --o_Ovfl    => s_Ovfl
    );

  -- keep ALU result observable for synthesis
  oALUOut <= s_ALUResult;

  -- Branch decision from ALU flags + funct3
  process(idex_Branch, idex_funct3, s_Zero, s_LT, s_LTU)
    begin
      if idex_Branch='1' then
        case idex_funct3 is
     	    when "000" => s_BrTaken <= s_Zero;        -- beq
     	    when "001" => s_BrTaken <= not s_Zero;    -- bne
     	    when "100" => s_BrTaken <= s_LT;          -- blt  (signed)
      	  when "101" => s_BrTaken <= not s_LT;      -- bge  (signed)
     	    when "110" => s_BrTaken <= s_LTU;         -- bltu (unsigned)
      	  when "111" => s_BrTaken <= not s_LTU;     -- bgeu (unsigned)
     	    when others => s_BrTaken <= '0';
    	end case;
      else
     	s_BrTaken <= '0';
      end if;
  end process;

  -- Targets
  s_BrTarget <= std_logic_vector(unsigned(idex_PC) + unsigned(idex_Imm));  -- PC + immB

  --s_isJALR   <= '1' when s_Inst(6 downto 0) = "1100111" else '0';                 -- jalr opcode
  s_JumpTarget <= (s_ALUResult and x"FFFFFFFE") when idex_isJALR='1'                 -- jalr: clear bit0
                else s_ALUResult;                                               -- jal: ALU computed PC+immJ


  -- Final PC select
  s_PCsrc <= s_BrTaken or idex_Jump;    -- 1 => take branch or jump
  s_NewPC <= s_BrTarget when s_BrTaken='1' else s_JumpTarget;

  -- Flush younger stages when control flow changes in EX
  --s_Flush_EX <= s_PCsrc;  --no used in SW

  -- MEM stage
  -- EX/MEM register
   EXMEM: EX_MEM
    generic map(N => N)
    port map(
      i_CLK => iCLK, i_RST => iRST, i_WE => '1',
      i_ALUResult => s_ALUResult,
      i_RS2 => idex_oRS2,
      i_rd  => idex_rd,
      i_PCplus4 => idex_PCplus4,
      i_Imm => idex_Imm,
      i_MemWrite => idex_MemWrite, i_MemRead => idex_MemRead,
      i_RegWrite => idex_RegWrite, i_Halt => idex_Halt,
      i_ResultSrc => idex_ResultSrc,
      i_LoadType => idex_LoadType,

      exmem_ALUResult => exmem_ALUResult,
      exmem_oRS2      => exmem_oRS2,
      exmem_rd        => exmem_rd,
      exmem_PCplus4   => exmem_PCplus4,
      exmem_Imm       => exmem_Imm,
      exmem_MemWrite  => exmem_MemWrite,
      exmem_MemRead   => exmem_MemRead,
      exmem_RegWrite  => exmem_RegWrite,
      exmem_Halt      => exmem_Halt,
      exmem_ResultSrc => exmem_ResultSrc,
      exmem_LoadType  => exmem_LoadType
    );
  -- Connect EX/MEM outputs to data memory inputs' 
  -- Data Memory
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => exmem_ALUResult(11 downto 2),
             data => exmem_oRS2,
             we   => exmem_MemWrite,
             q    => s_DMemOut);

  s_DMemWr   <= exmem_MemWrite;  -- control => DMEM write enable
  --s_RegWr    <= s_RegWrite;  -- control => RegFile write enable
  s_DMemAddr <= exmem_ALUResult;  -- ALU result drives DMEM address
  s_DMemData <= exmem_oRS2; 
  --s_PCplus4 <= std_logic_vector(unsigned(s_NextInstAddr) + 4);



  -- LoadType: extend DMEM read according to loadType (000 lw, 001 lh, 010 lb, 011 lbu, 100 lhu)
  u_LoadType: loadType
    port map(
      i_word     => s_DMemOut,                -- 32-bit word from data memory
      i_addr_low => exmem_ALUResult(1 downto 0),   -- byte offset from address
      i_LType    => exmem_loadType,               -- s_Ctrl(3 downto 1)
      o_data     => s_LoadExt                -- extended load result
    );
  
   -- MEM/WB register
  MEMWB: MEM_WB
    port map(
      i_CLK => iCLK, i_RST => iRST, i_WE => '1',
      i_ReadData  => s_DMemOut,
      i_LoadExt   => s_LoadExt,
      i_ALUResult => exmem_ALUResult,
      i_PCplus4   => exmem_PCplus4,
      i_ImmU      => exmem_Imm,
      i_rd        => exmem_rd,
      i_ResultSrc => exmem_ResultSrc,
      i_RegWrite  => exmem_RegWrite,
      i_Halt      => exmem_Halt,

      memwb_ReadData  => memwb_ReadData,
      memwb_LoadExt   => memwb_LoadExt,
      memwb_ALUResult => memwb_ALUResult,
      memwb_PCplus4   => memwb_PCplus4,
      memwb_ImmU      => memwb_ImmU,
      memwb_rd        => memwb_rd,
      memwb_ResultSrc => memwb_ResultSrc,
      memwb_RegWrite  => memwb_RegWrite,
      memwb_Halt      => memwb_Halt
    );

  -- write-back mux (ResultSrc: 00=ALU, 01=MEM, 10=PC+4, 11=ImmU)
  with memwb_ResultSrc select
    s_RegWrData <= memwb_ALUResult when "00",
    memwb_LoadExt                  when "01",
    memwb_PCplus4                  when "10",
    memwb_ImmU                      when others; --or 11 lui

  s_RegWr     <= memwb_RegWrite;
  s_RegWrAddr <= memwb_rd;

-- Ensure that s_Halt is connected to an output control signal produced from decoding the Halt instruction (Opcode: 1110011)
  s_Halt <= memwb_Halt;
  oHalt  <= s_Halt;


end structure;

