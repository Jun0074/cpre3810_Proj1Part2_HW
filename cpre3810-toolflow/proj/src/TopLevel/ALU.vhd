-- ALU.vhd
-- Consumes ALUOp(3:0) directly from control_unit bits[17:14].
-- Supports: AND, OR, XOR, ADD, SUB, SLT, SLTU, SLL, SRL, SRA
-- Provides branch compare flags for: beq/bne (Zero), blt/bge (LT), bltu/bgeu (LTU)
-- Structural 32-bit BarrelShifter inside ALU below
--------------------------------------------------------------------------------------
library ieee;                           
use ieee.std_logic_1164.all;               
use ieee.numeric_std.all;    
               
entity ALU is
  port(
    i_A       : in  std_logic_vector(31 downto 0); -- operand A (rs1 or PC)
    i_B       : in  std_logic_vector(31 downto 0); -- operand B (rs2 or Imm)
    i_ALUOp   : in  std_logic_vector(3 downto 0);  -- 4-bit op from control
    o_Y       : out std_logic_vector(31 downto 0); -- result
    o_Zero    : out std_logic;                     -- result == 0
    o_LT      : out std_logic;                     -- A < B (signed)
    o_LTU     : out std_logic;                     -- A < B (unsigned)
    o_Ovfl    : out std_logic                      -- overflow (ADD/SUB)
  );
end entity;

architecture dataflow of ALU is

--ALUOp encodings (matchgit  control spreadsheet)
  constant ALU_AND  : std_logic_vector(3 downto 0) := "0000"; -- and/andi
  constant ALU_OR   : std_logic_vector(3 downto 0) := "0001"; -- or/ori
  constant ALU_ADD  : std_logic_vector(3 downto 0) := "0010"; -- add/addi/lw/sw/auipc/jal/jalr addr
  constant ALU_SUB  : std_logic_vector(3 downto 0) := "0011"; -- sub + beq/bne compare
  constant ALU_XOR  : std_logic_vector(3 downto 0) := "0100"; -- xor/xori
  constant ALU_SLT  : std_logic_vector(3 downto 0) := "0111"; -- slt/slti  (signed)
  constant ALU_SLTU : std_logic_vector(3 downto 0) := "1000"; -- sltu/sltiu(unsigned)
  constant ALU_SLL  : std_logic_vector(3 downto 0) := "1001"; -- sll/slli
  constant ALU_SRL  : std_logic_vector(3 downto 0) := "1010"; -- srl/srli
  constant ALU_SRA  : std_logic_vector(3 downto 0) := "1011"; -- sra/srai

--typed views for math/flags 
  signal A_s, B_s : signed(31 downto 0);               -- signed view
  signal A_u, B_u : unsigned(31 downto 0);             -- unsigned view
  signal shamt    : std_logic_vector(4 downto 0);      -- shift amt = B[4:0]
  signal result      : std_logic_vector(31 downto 0);     -- result bus
  --signal ov_add   : std_logic;           -- add overflow
  --signal ov_sub   : std_logic;           -- sub overflow
  signal sum, diff : signed(31 downto 0); --(Add/Sub result)

  -- ---- barrel shifter I/O ----
  signal sh_right : std_logic;            -- 0=left, 1=right
  signal sh_arith : std_logic;            -- right: 1=arith
  signal sh_out   : std_logic_vector(31 downto 0);      -- shift result

  -- BarrelShifter Component
  component BarrelShifter32
    port(
      i_D     : in  std_logic_vector(31 downto 0); -- data to shift
      i_SA    : in  std_logic_vector(4 downto 0);  -- shift amount
      i_Right : in  std_logic;                     -- 0=left, 1=right
      i_Arith : in  std_logic;                     -- right: 1=arithmetic
      o_Y     : out std_logic_vector(31 downto 0)  -- shifted result
    );
  end component;

begin
  -- map input buses to numeric types
  A_s   <= signed(i_A);                                 -- signed A
  B_s   <= signed(i_B);                                 -- signed B
  A_u   <= unsigned(i_A);                               -- unsigned A
  B_u   <= unsigned(i_B);                               -- unsigned B
  shamt <= i_B(4 downto 0);                             -- shamt from B

  -- shifter mode from ALUOp
  sh_right <= '0' when i_ALUOp = ALU_SLL else '1';      -- left only for SLL
  sh_arith <= '1' when i_ALUOp = ALU_SRA else '0';      -- arith only for SRA

  -- structural barrel shifter (always shifts A by B[4:0])
  u_sh: BarrelShifter32
    port map(
      i_D     => i_A,                                   -- data in = A
      i_SA    => shamt,                                 -- amount = B[4:0]
      i_Right => sh_right,                              -- direction
      i_Arith => sh_arith,                              -- arithmetic?
      o_Y     => sh_out                                 -- shifted out
    );

    sum  <= A_s + B_s;
    diff <= A_s - B_s;

     result <= 
         (i_A and i_B)                  when i_ALUOp = ALU_AND  else
         (i_A or  i_B)                  when i_ALUOp = ALU_OR   else
         std_logic_vector(sum)          when i_ALUOp = ALU_ADD  else
         std_logic_vector(diff)         when i_ALUOp = ALU_SUB  else
         (i_A xor i_B)                  when i_ALUOp = ALU_XOR  else
         sh_out                         when i_ALUOp = ALU_SLL  or i_ALUOp = ALU_SRL or i_ALUOp = ALU_SRA  else
         (31 downto 1 => '0') & '1'     when (i_ALUOp = ALU_SLT  and A_s < B_s) or (i_ALUOp = ALU_SLTU and A_u < B_u) else (others => '0');  -- default


    -- flags driven from selected result / operands
    o_LT  <= '1' when A_s < B_s else '0';
    o_LTU <= '1' when A_u < B_u else '0';
 


    -- overflow per 2's-comp rules (ADD/SUB)
    --ov_add <= '1' when (i_ALUOp = ALU_ADD) and ((A_s(31) = B_s(31)) and (sum(31)  /= A_s(31))) else '0';
    --ov_sub <= '1' when (i_ALUOp = ALU_SUB) and ((A_s(31) /= B_s(31)) and (diff(31) /= A_s(31))) else '0';

  -- connect result/overflow to outputs
  o_Y    <= result;                -- result out
 -- o_Ovfl <= ov_add or ov_sub;   -- overflow out

  -- DO NOT TOUCH THIS LINE! It is intended to left outside of the combinational process
  o_Zero <= '1' when result = x"00000000" else '0';      -- Zero flag

end architecture;
