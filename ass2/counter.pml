#define B 3
#define R 1
#define BYTE_SIZE 2

#define BYTE_MAX ((1 << BYTE_SIZE) - 1)
#define COUNTER_MAX ((1 << (BYTE_SIZE * B)) - 1)

#define get_byte_in_int(int, byte) (((int) >> ((byte) * BYTE_SIZE)) & BYTE_MAX)
#define set_byte_in_int(int, byte, val) ((int) & ~(BYTE_MAX << ((byte) * BYTE_SIZE))) | ((val) << ((byte) * BYTE_SIZE))

bool of1 = false;
bool of2 = false;
byte c1[B] = 0;
byte c2[B] = 0;

int ref_low = 0;
int ref_high = 0;
int read_low[R + 1] = -1;

active proctype writer() {
    int ref = 1;
    do
    ::  // increment reference high
        d_step {
            ref_high = ref;
            int i;
            for (i in read_low) {
                if
                :: ref == read_low[i] -> read_low[i] = -1;
                :: else -> skip;
                fi
            }
        }

        // actual writer code
        int b;
        for (b : 0 .. B - 1) {
            byte tmp = get_byte_in_int(ref, b);
            atomic {
                if
                :: tmp == c1[b] -> break;
                :: else -> c1[b] = tmp;
                fi
            }
            if
            :: b == B - 1 && tmp == 0 -> of1 = !of1;
            :: else -> skip;
            fi
        }

        for (b : 0 .. B - 1) {
            byte tmp = get_byte_in_int(ref, b);
            atomic {
                if
                :: tmp == c2[b] -> break;
                :: else -> c2[b] = tmp;
                fi
            }
            if
            :: b == B - 1 && tmp == 0 -> of2 = !of2;
            :: else -> skip;
            fi
        }

        skip;
        d_step {
            ref_low = ref;
            if
            :: ref == COUNTER_MAX -> ref = 0;
            :: else -> ref++;
            fi
        }
    od
}

active[R] proctype reader() {
    // atomically get reference low value
    read_low[_pid] = ref_low;

    // actual reader code
    byte value[B];
    bool overflow = of2;
    int b;
    for (b : 0 .. B - 1) {
        value[B - 1 - b] = c2[B - 1 - b];
    }

    int j = 0;
    for (b : 1 .. B - 1) {
        byte tmp = c1[b];
        d_step {
            if
            :: tmp > value[b] ->
                value[b] = tmp;
                j = b;
            :: else -> skip;
            fi
        }

        tmp = c2[b];
        d_step {
            if
            :: tmp > value[b] ->
                value[b] = tmp;
                j = b;
            :: else -> skip;
            fi
        }
    }

    if
    :: overflow != of1 -> j = B;
    :: else -> skip;
    fi

    d_step {
        for (b : 0 .. j - 1) {
            value[b] = 0;
        }
    }

reader_end:

    // atomically get reference high value and check returned value is correct
    d_step {
        int value_int = 0;
        for (b : 0 .. B - 1) {
            value_int = set_byte_in_int(value_int, b, value[b]);
        }

        if
        :: read_low[_pid] != -1 ->
            if
            :: read_low[_pid] <= ref_high ->
                assert(read_low[_pid] <= value_int && value_int <= ref_high);
            :: else ->
                assert(read_low[_pid] <= value_int || value_int <= ref_high);
            fi
        :: else -> skip;
        fi
    }
}

ltl reads_finish {<>(reader@reader_end)}
