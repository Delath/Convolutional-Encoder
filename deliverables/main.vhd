--------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Gianluca Palermo - Anno 2021/2022
--
-- Dario Simoni (Codice Persona 10697990 Matricola 932957)
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
  port (
    i_clk     : in std_logic;
    i_rst     : in std_logic;
    i_start   : in std_logic;
    i_data    : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done    : out std_logic;
    o_en      : out std_logic;
    o_we      : out std_logic;
    o_data    : out std_logic_vector(7 downto 0)
  );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
  type STATE_TYPE is (
    START,
    WAIT_START,
    READ_NUMBER_OF_WORD,
    WAIT_READ_NUMBER_OF_WORD,
    PREPARE_BIT_READ,
    WAIT_PREPARE_BIT_READ,
    READ_BIT,
    WAIT_READ_BIT,
    WRITE_WORD_ONE,
    WAIT_WRITE_WORD_ONE,
    WRITE_WORD_TWO,
    WAIT_WRITE_WORD_TWO,
    DONE
  );

  signal state : STATE_TYPE := START;
  signal fsm_00 : boolean := true;
  signal fsm_01 : boolean := false;
  signal fsm_10 : boolean := false;
  signal fsm_11 : boolean := false;
  signal to_be_processed : integer;
  signal words_processed : integer := 0;
  signal ram_pos : std_logic_vector(15 downto 0) := (others => '0');
  signal ram_w_pos : std_logic_vector(15 downto 0) := "0000001111101000";
  signal word1 : std_logic_vector(7 downto 0);
  signal word2 : std_logic_vector(7 downto 0);
  signal count : integer := 0;
  signal counter : integer := 0;
  
begin
  transitions: process (i_clk)
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' or i_start = '0' then
        o_done    <= '0';
        o_we      <= '0';
        o_data    <= (others => '0');
        o_address <= (others => '0');
        o_en <= '0';
        state <= START;
        fsm_00 <= true;
        fsm_01 <= false;
        fsm_10 <= false;
        fsm_11 <= false;
        words_processed <= 0;
        ram_pos <= (others => '0');
        ram_w_pos <= "0000001111101000";
        count <= 0;
        counter <= 0;
      else
        case state is
          when START =>
            o_done <= '0';
            o_we <= '0';
            if i_start = '1' then
              ram_pos <= std_logic_vector(unsigned(ram_pos)+1);
              o_en <= '1';
              o_address <= "0000000000000000";
              state <= WAIT_START;
            else
              state <= START;
            end if;
             
          when WAIT_START =>
              state <= READ_NUMBER_OF_WORD;
             
          when READ_NUMBER_OF_WORD =>
              to_be_processed <= to_integer(unsigned(i_data));
              state <= WAIT_READ_NUMBER_OF_WORD;
              
          when WAIT_READ_NUMBER_OF_WORD =>
              state <= PREPARE_BIT_READ;
           
          when PREPARE_BIT_READ =>
              o_we <= '0';
              o_address <= ram_pos;
              ram_pos <= std_logic_vector(unsigned(ram_pos)+1);
              state <= WAIT_PREPARE_BIT_READ;
           
          when WAIT_PREPARE_BIT_READ =>
              state <= READ_BIT;
           
          when READ_BIT =>
              o_en <= '1';
              if (std_logic_vector(to_unsigned(to_be_processed, 8)) = std_logic_vector(to_unsigned(words_processed, 8))) then
                state <= DONE;
              else --count ora fa 0 2 4 6 8 10 .. 16 0 ma non va bene per i_data fixare
                if not (count = 8) then
                  if fsm_00 then
                      if i_data(7-count) ='0' then
                          if (counter < 8) then
                              word1(7-counter) <= '0';
                              word1(6-counter) <= '0';
                          else
                              word2(15-counter) <= '0';
                              word2(14-counter) <= '0';
                          end if;
                      elsif i_data(7-count) = '1' then
                          if (counter < 8) then
                              word1(7-counter) <= '1';
                              word1(6-counter) <= '1';
                          else
                              word2(15-counter) <= '1';
                              word2(14-counter) <= '1';
                          end if;
                          fsm_10 <= true;
                          fsm_00 <= false;
                      end if;
                  elsif fsm_01 then
                      if i_data(7-count) ='0' then
                          if (counter < 8) then
                              word1(7-counter) <= '1';
                              word1(6-counter) <= '1';
                          else
                              word2(15-counter) <= '1';
                              word2(14-counter) <= '1';
                          end if;
                          fsm_00 <= true;
                          fsm_01 <= false;
                      elsif i_data(7-count) = '1' then
                          if (counter < 8) then
                              word1(7-counter) <= '0';
                              word1(6-counter) <= '0';
                          else
                              word2(15-counter) <= '0';
                              word2(14-counter) <= '0';
                          end if;
                          fsm_10 <= true;
                          fsm_01 <= false;
                      end if;
                  elsif fsm_10 then
                      if i_data(7-count) ='0' then
                          if (counter < 8) then
                              word1(7-counter) <= '0';
                              word1(6-counter) <= '1';
                          else
                              word2(15-counter) <= '0';
                              word2(14-counter) <= '1';
                          end if;
                          fsm_01 <= true;
                          fsm_10 <= false;
                      elsif i_data(7-count) = '1' then
                          if (counter < 8) then
                              word1(7-counter) <= '1';
                              word1(6-counter) <= '0';
                          else
                              word2(15-counter) <= '1';
                              word2(14-counter) <= '0';
                          end if;
                          fsm_11 <= true;
                          fsm_10 <= false;
                      end if;
                  elsif fsm_11 then
                      if i_data(7-count) ='0' then
                          if (counter < 8) then
                              word1(7-counter) <= '1';
                              word1(6-counter) <= '0';
                          else
                              word2(15-counter) <= '1';
                              word2(14-counter) <= '0';
                          end if;
                          fsm_01 <= true;
                          fsm_11 <= false;
                      elsif i_data(7-count) = '1' then
                          if (counter < 8) then
                              word1(7-counter) <= '0';
                              word1(6-counter) <= '1';
                          else
                              word2(15-counter) <= '0';
                              word2(14-counter) <= '1';
                          end if;
                      end if;
                  end if;
                  count <= count+1;
                  counter <= counter+2;
                  state <= WAIT_READ_BIT;
                else
                  count <= 0;
                  counter <= 0;
                  state <= WRITE_WORD_ONE;
                end if;
              end if;

          when WAIT_READ_BIT =>
              state <= READ_BIT;
          
          when WRITE_WORD_ONE => 
              o_en <= '1';
              o_we <= '1';
              o_address <= ram_w_pos;
              o_data <= word1;
              ram_w_pos <= std_logic_vector(unsigned(ram_w_pos)+1);
              state <= WAIT_WRITE_WORD_ONE;
              
          when WAIT_WRITE_WORD_ONE =>
              state <= WRITE_WORD_TWO;
          
          when WRITE_WORD_TWO => 
              o_en <= '1';
              o_we <= '1';
              o_address <= ram_w_pos;
              o_data <= word2;
              ram_w_pos <= std_logic_vector(unsigned(ram_w_pos)+1);
              words_processed <= words_processed+1;
              state <= WAIT_WRITE_WORD_TWO;

              
          when WAIT_WRITE_WORD_TWO =>
              state <= PREPARE_BIT_READ;
              
          when DONE => 
              if i_start = '0' then
            -- Set the next state.
                state <= START;
              else
            -- Set done signal.
                o_en      <= '0';
                o_done <= '1';
            -- Set the next state.
                state <= DONE;
              end if;
              
        end case;
      end if;
    end if;
  end process;
end architecture;