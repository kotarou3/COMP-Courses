#define BYZANTINE
#define SENIORS 2

typedef Message {
    #define NO_SIGNATURE (-1)
    int signs[2];
};

typedef Senior {
    bool isHigh;
    bool isCompatible[SENIORS];
    chan to[SENIORS] = [SENIORS*SENIORS] of {Message};

    bool isPaired = false;
    int pairedSenior = -1;
};
Senior seniors[SENIORS];
int finished;
int messages;

inline send(me, dest, message) {
    d_step {
        messages++;
    }
    seniors[me].to[dest] ! message;
}

inline sendNew(me, dest) {
    atomic {
        Message sendNew_message;
        sendNew_message.signs[0] = me;
        sendNew_message.signs[1] = NO_SIGNATURE;

        send(me, dest, sendNew_message);
    }
}

inline recvAny(me, message, src) {
    atomic {
        if
        :: seniors[0].to[me] ? message ->
            src = 0;
    #if SENIORS > 1
        :: seniors[1].to[me] ? message ->
            src = 1;
    #endif
    #if SENIORS > 2
        :: seniors[2].to[me] ? message ->
            src = 2;
    #endif
    #if SENIORS > 3
        :: seniors[3].to[me] ? message ->
            src = 3;
    #endif
    #if SENIORS > 4
        :: seniors[4].to[me] ? message ->
            src = 4;
    #endif
    #if SENIORS > 5
        :: seniors[5].to[me] ? message ->
            src = 5;
    #endif
    #if SENIORS > 6
        :: seniors[6].to[me] ? message ->
            src = 6;
    #endif
    #if SENIORS > 7
        :: seniors[7].to[me] ? message ->
            src = 7;
    #endif
    #if SENIORS > 8
        :: seniors[8].to[me] ? message ->
            src = 8;
    #endif
    #if SENIORS > 9
        #error Needs more copy pasting
    #endif
        fi
    }
}

typedef CompatibilityMatrixInner {
    bool to[SENIORS];
}

proctype seniorProcess(int me) {
    CompatibilityMatrixInner compatibilityMatrix[SENIORS];
    int s;

    // Send all our neighbours a signed message that we're compatible
    int neighbourCount = 0;
    atomic {
        for (s : 0 .. SENIORS - 1) {
            if
            :: seniors[me].isCompatible[s] ->
                sendNew(me, s);
                compatibilityMatrix[me].to[s] = true;
                neighbourCount++;
            :: else -> skip;
            fi
        }
    }

    // Wait for messages from our neighbours
    int src;
    Message message;
    do
    :: recvAny(me, message, src) ->
        int sign0 = message.signs[0]; // The originator of the message
        int sign1 = message.signs[1]; // The original target of the message

        d_step {
            if
            :: sign1 == NO_SIGNATURE ->
                // New broadcast from our neighbour, so we sign it
                message.signs[1] = me;
                sign1 = me;

                assert(!compatibilityMatrix[sign0].to[sign1]); // We shouldn't know about it yet
            :: else ->
                skip;
            fi
        }

        if
        :: compatibilityMatrix[sign0].to[sign1] ->
            // We already know about this compatibility, so we ignore it
            skip;
        :: else ->
            // We don't know about this compatibility, so we broadcast it
            compatibilityMatrix[sign0].to[sign1] = true;

            for (s : 0 .. SENIORS - 1) {
                if
                :: seniors[me].isCompatible[s] ->
                    if
                #ifdef BYZANTINE
                    :: seniors[me].isHigh && s != src ->
                        // Pretend to send messages, but don't
                        skip;
                #endif
                    :: true ->
                        send(me, s, message);
                    fi
                :: else ->
                    skip;
                fi
            }
        fi

        skip;
        d_step {
            messages--;
        }
    :: messages == 0 ->
        break;
    od

    skip;
    d_step {
        // Make the matrix symmetric, since some nodes might be leaves and their
        // incoming edge might never be broadcast
        for (s : 0 .. SENIORS - 1) {
            int s2;
            for (s2 : 0 .. SENIORS - 1) {
                if
                :: compatibilityMatrix[s].to[s2] ->
                    compatibilityMatrix[s2].to[s] = true;
                :: else ->
                    skip;
                fi
            }
        }

        // Deterministically work out a pairing from the compatibility matrix
        bool isTaken[SENIORS];
        for (s : 0 .. SENIORS - 1) {
            int s2;
            for (s2 : 0 .. SENIORS - 1) {
                if
                :: !isTaken[s] && !isTaken[s2] && s != s2 && compatibilityMatrix[s].to[s2] ->
                    isTaken[s] = true;
                    isTaken[s2] = true;
                    if
                    :: s == me ->
                        seniors[me].isPaired = true;
                        seniors[me].pairedSenior = s2;
                    :: s2 == me ->
                        seniors[me].isPaired = true;
                        seniors[me].pairedSenior = s;
                    :: else ->
                        skip;
                    fi
                :: else ->
                    skip;
                fi
            }
        }

        if
        :: seniors[me].isPaired ->
            printf("%d exchanges life stories with %d.\n", me + 1, seniors[me].pairedSenior + 1);
        :: else ->
            printf("%d has a seniors' moment.\n", me + 1);
        fi
        if
        :: seniors[me].isHigh ->
            printf("%d is hallucinating\n", me + 1);
        :: else ->
            printf("%d is sober\n", me + 1);
        fi

        finished++;
    }
}

init {
    // generate a random testcase
    int id;
    bool isSingleSoberSubgraph = false;
    atomic {
        int soberNodes = 0;
        int lastSoberNode = -1;
        for (id : 0 .. SENIORS - 1) {
            if
            :: soberNodes != 0 ->
                seniors[id].isHigh = true;
            :: true ->
                soberNodes++;
                lastSoberNode = id;
            fi

            int otherId;
            for (otherId : id + 1 .. SENIORS - 1) {
                if
                :: true ->
                    seniors[id].isCompatible[otherId] = true;
                    seniors[otherId].isCompatible[id] = true;
                :: true ->
                    skip;
                fi
            }
        }

        // Make sure our graph contains only a single sober subgraph
        bool isNodeChecked[SENIORS];
        bool isSoberReachable[SENIORS];
        isSoberReachable[lastSoberNode] = true;
        int sobersReachable = 1;

    continueChecking:
        for (id : 0 .. SENIORS - 1) {
            if
            :: isSoberReachable[id] && !isNodeChecked[id] ->
                assert(!seniors[id].isHigh);
                isNodeChecked[id] = true;

                int otherId;
                for (otherId : 0 .. SENIORS - 1) {
                    if
                    :: seniors[id].isCompatible[otherId] && !isSoberReachable[otherId] && !seniors[otherId].isHigh ->
                        isSoberReachable[otherId] = true;
                        sobersReachable++;
                    :: else ->
                        skip
                    fi
                }
            :: else ->
                skip;
            fi
        }
        for (id : 0 .. SENIORS - 1) {
            if
            :: isSoberReachable[id] && !isNodeChecked[id] ->
                goto continueChecking;
            :: else ->
                skip;
            fi
        }

        isSingleSoberSubgraph = sobersReachable == soberNodes;

#if 0
        printf("%d/%d ", sobersReachable, soberNodes);
        for (id : 0 .. SENIORS - 1) {
            printf("%d", isSoberReachable[id]);
        }
        printf("\n");

        for (id : 0 .. SENIORS - 1) {
            printf("[%d/%d] ", id, SENIORS);
            int otherId;
            for (otherId : 0 .. SENIORS - 1) {
                if
                :: seniors[id].isCompatible[otherId] ->
                    printf("1");
                :: else ->
                    printf("0");
                fi
            }
            if
            :: seniors[id].isHigh ->
                printf(" (high)\n");
            :: else ->
                printf("\n");
            fi
        }
#endif
    }

    if
    :: isSingleSoberSubgraph ->
        for (id : 0 .. SENIORS - 1) {
            run seniorProcess(id);
        }

        // Wait for seniors to finish
        finished == SENIORS;

        // Check for correctness
        d_step {
            for (id : 0 .. SENIORS - 1) {
                int otherId;
                if
                :: seniors[id].isHigh -> skip;
                :: else ->
                    if
                    :: seniors[id].isPaired ->
                        otherId = seniors[id].pairedSenior;
                        // Must be compatible with the other senior
                        assert(seniors[id].isCompatible[otherId]);

                        // No other sober senior wants the same pairing
                        int id2;
                        for (id2 : 0 .. SENIORS - 1) {
                            assert(id2 == id || seniors[id2].isHigh || !seniors[id2].isPaired || seniors[id2].pairedSenior != otherId);
                        }

                        // If other senior isn't high, they must have agreed with pairing
                        assert(seniors[otherId].isHigh || (seniors[otherId].isPaired && seniors[otherId].pairedSenior == id));
                    :: else ->
                        // No other unpaired compatible sober senior exists
                        for (otherId : 0 .. SENIORS - 1) {
                            assert(!seniors[id].isCompatible[otherId] || seniors[otherId].isHigh || seniors[otherId].isPaired);
                        }
                    fi
                fi
            }
        }
    :: else ->
        finished = SENIORS;
    fi
}

ltl seniors_finish {<>(finished == SENIORS)}
