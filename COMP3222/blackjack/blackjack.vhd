library IEEE;
use IEEE.std_logic_1164.all;

entity blackjack is
    port (
        clk, start: in std_ulogic;

        cardReady: in std_ulogic;
        cardValue: in integer range 2 to 11;

        newCard: out std_ulogic;

        -- Max score is 26, since the maximum score we still accept cards at is
        -- 16, and the biggest card value is 10 (Aces will get converted to 1 at
        -- this point of the game)
        score: out integer range 0 to 26;

        lost, finished: out std_ulogic
    );
end blackjack;

architecture arch of blackjack is
    alias clock is clk;
    alias enable is start;

    signal isCardReady: boolean;
    signal wantNewCard: boolean;
    signal isBust, isFinished: boolean;

    signal cardValueCopy: integer range 2 to 11;
    signal currentScore: integer range 0 to 26;

    -- We can only ever have one 11-point ace without going bust
    signal has11PointAce: boolean;

    type state_t is (NewCardWait, CardAckWait, GameOver);
    signal state: state_t;
begin
    isCardReady <= cardReady = '1';
    newCard <= '1' when wantNewCard else '0';
    lost <= '1' when isBust else '0';
    finished <= '1' when isFinished else '0';

    score <= currentScore;

    process (clock)
        variable newScore: integer range 0 to 31;
    begin
        if enable = '0' then
            currentScore <= 0;

            wantNewCard <= false;
            isBust <= false;
            isFinished <= false;

            has11PointAce <= false;

            state <= NewCardWait;
        elsif rising_edge(clock) then
            case state is
                when NewCardWait =>
                    if isCardReady then
                        cardValueCopy <= cardValue;
                        wantNewCard <= false;

                        state <= CardAckWait;
                    else
                        wantNewCard <= true;
                    end if;

                when CardAckWait =>
                    if not isCardReady then
                        if cardValueCopy = 11 then
                            if currentScore > 21 - 11 then
                                -- Going to go bust, but we can use the just-dealt
                                -- ace as a 1-pointer (but we might still bust
                                -- regardless, which is why this check is up here)
                                newScore := currentScore + 1;
                            else
                                -- Save the fact we have an ace for later
                                has11PointAce <= true;
                                newScore := currentScore + cardValueCopy;
                            end if;
                        else
                            newScore := currentScore + cardValueCopy;
                        end if;

                        if newScore <= 16 then
                            state <= NewCardWait;
                        elsif newScore <= 21 then
                            isFinished <= true;
                            state <= GameOver;
                        elsif has11PointAce then
                            -- Was going to go bust, but we have an ace that can
                            -- be converted to 1 point
                            newScore := newScore - 10;
                            has11PointAce <= false;
                            state <= NewCardWait;

                            -- Our strategy guarantees this condition, since the
                            -- highest two cards are 10 and 11. If an 11 was dealt,
                            -- then that would have been handled above. If a 10
                            -- was dealt, and we're at the highest current score
                            -- where we're still accepting new cards (16), we
                            -- will be pulled back down to 16
                            assert(newScore <= 16);
                        else
                            isBust <= true;
                            state <= GameOver;
                        end if;

                        currentScore <= newScore;
                    end if;

                when GameOver =>
                    -- Do nothing
            end case;
        end if;
    end process;
end arch;
