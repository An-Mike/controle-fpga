LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY calculateur IS
    PORT(
        clk      : IN  std_logic;
        reset_n  : IN  std_logic;

        A        : IN  std_logic_vector(7 downto 0); -- opérande 1
        B        : IN  std_logic_vector(7 downto 0); -- opérande 2

        op_sel   : IN  std_logic_vector(1 downto 0); -- sélection opération

        result   : OUT std_logic_vector(9 downto 0)  -- résultat élargi (évite overflow)
    );
END calculateur;


ARCHITECTURE RTL OF calculateur IS

    signal res_tmp : unsigned(9 downto 0);

BEGIN

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            res_tmp <= (others => '0');

        elsif rising_edge(clk) then

            case op_sel is

                when "00" =>  -- ADDITION
                    res_tmp <= resize(unsigned(A),10) + resize(unsigned(B),10);

                when "01" =>  -- SOUSTRACTION
                    res_tmp <= resize(unsigned(A),10) - resize(unsigned(B),10);

                when "10" =>  -- AMPLIFICATION (gain x2)
                    res_tmp <= resize(unsigned(A),10) sll 1;

                when "11" =>  -- ATTENUATION (/2)
                    res_tmp <= resize(unsigned(A),10) srl 1;

                when others =>
                    res_tmp <= (others => '0');

            end case;

        end if;
    end process;

    result <= std_logic_vector(res_tmp);

END RTL;