LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY lights IS
    PORT (
        SW        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        KEY       : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        CLOCK_50  : IN  STD_LOGIC;
        LED       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        LTC_ADC_CONVST : OUT std_logic;
        LTC_ADC_SCK    : OUT std_logic;
        LTC_ADC_SDI    : OUT std_logic;
        LTC_ADC_SDO    : IN  std_logic
    );
END lights;

ARCHITECTURE Structure OF lights IS

    ------------------------------------------------
    -- signaux horloge
    ------------------------------------------------
    signal clk_40M : std_logic;
    signal clk_2k  : std_logic;

    ------------------------------------------------
    -- détecteur flanc montant clk_2k
    ------------------------------------------------
    signal clk_2k_prev   : std_logic := '0';
    signal capture_pulse : std_logic;

    ------------------------------------------------
    -- signaux capteurs
    ------------------------------------------------
    signal data0, data1 : std_logic_vector(7 downto 0);
    signal data_ready   : std_logic;

    ------------------------------------------------
    -- calculateur
    ------------------------------------------------
    signal op_sel     : std_logic_vector(1 downto 0);
    signal result_sig : std_logic_vector(9 downto 0);

BEGIN

    ------------------------------------------------
    -- PLL (50 MHz → 40 MHz + 2 kHz)
    ------------------------------------------------
    PLL_inst : entity work.pll_2freqs
        port map(
            inclk0 => CLOCK_50,
            c0     => clk_40M,
            c1     => clk_2k
        );

    ------------------------------------------------
    -- détecteur flanc montant sur clk_2k
    -- génère une impulsion d'1 cycle à 40 MHz
    ------------------------------------------------
    process(clk_40M, KEY)
    begin
        if KEY(0) = '0' then
            clk_2k_prev <= '0';
        elsif rising_edge(clk_40M) then
            clk_2k_prev <= clk_2k;
        end if;
    end process;

    capture_pulse <= '1' when (clk_2k = '1' and clk_2k_prev = '0') else '0';

    ------------------------------------------------
    -- sélection opération (switches)
    ------------------------------------------------
    op_sel <= SW(1 downto 0);

    ------------------------------------------------
    -- acquisition ADC
    ------------------------------------------------
    capteurs_inst : entity work.capteurs_sol
        port map(
            clk          => clk_40M,
            reset_n      => KEY(0),
            data_capture => capture_pulse,   -- impulsion courte
            data_readyr  => data_ready,
            data0r       => data0,
            data1r       => data1,
            data2r       => open,
            data3r       => open,
            data4r       => open,
            data5r       => open,
            data6r       => open,
            ADC_CONVSTr  => LTC_ADC_CONVST,
            ADC_SCK      => LTC_ADC_SCK,
            ADC_SDIr     => LTC_ADC_SDI,
            ADC_SDO      => LTC_ADC_SDO
        );

    ------------------------------------------------
    -- calculateur câblé
    ------------------------------------------------
    calc_inst : entity work.calculateur
        port map(
            clk     => CLOCK_50,
            reset_n => KEY(0),
            A       => data0,
            B       => data1,
            op_sel  => op_sel,
            result  => result_sig
        );

    ------------------------------------------------
    -- affichage résultat (uniquement si donnée valide)
    ------------------------------------------------
    LED <= result_sig(7 downto 0) when data_ready = '1' else (others => '0');

END Structure;