#define BYZANTINE

#define _POSIX_C_SOURCE 199309L

#include <alloca.h>
#include <assert.h>
#include <time.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <mpi.h>

typedef enum {
    REQUEST,
    REQUEST_OK,
    COMMIT
} Tag;

typedef struct {
    Tag tag;

    #define NO_SIGNATURE ((size_t)-1)
    size_t signs[2];
} Message;

typedef struct {
    size_t id;
    bool isHigh;
    bool isCompatible[];
} Senior;

size_t seniors;

MPI_Request* recvRequests;
Message* recvBuffers;

void seniorSend(size_t dest, Message* message) {
    int err = MPI_Send(message, sizeof(*message), MPI_BYTE, dest, 0, MPI_COMM_WORLD);
    assert(err == 0);
}

void seniorSendNew(const Senior* me, size_t dest, Tag tag) {
    Message message = {
        .tag = tag,
        .signs = {me->id, NO_SIGNATURE}
    };

    seniorSend(dest, &message);
}

void seniorRecv(size_t src, Message* message) {
    int err = MPI_Wait(&recvRequests[src], MPI_STATUS_IGNORE);
    assert(err == 0);
    memcpy(message, &recvBuffers[src], sizeof(*message));

    err = MPI_Irecv(&recvBuffers[src], sizeof(*message), MPI_BYTE, src, 0, MPI_COMM_WORLD, &recvRequests[src]);
    assert(err == 0);
}

void seniorRecvAny(Message* message, size_t* src) {
    int index;
    int err = MPI_Waitany(seniors, recvRequests, &index, MPI_STATUS_IGNORE);
    assert(err == 0);
    *src = index;
    memcpy(message, &recvBuffers[*src], sizeof(*message));

    err = MPI_Irecv(&recvBuffers[*src], sizeof(*message), MPI_BYTE, *src, 0, MPI_COMM_WORLD, &recvRequests[*src]);
    assert(err == 0);
}

void seniorProcess(const Senior* me) {
    bool compatibilityMatrix[seniors][seniors];
    memset(compatibilityMatrix, 0, sizeof(compatibilityMatrix));

    // Send all our neighbours a signed message that we're compatible
    size_t neighbourCount = 0;
    for (size_t s = 0; s < seniors; ++s) {
        if (!me->isCompatible[s])
            continue;
        seniorSendNew(me, s, REQUEST);
        compatibilityMatrix[me->id][s] = true;
        ++neighbourCount;
    }

    typedef struct {
        size_t acks;
        size_t parent; // Who did we originally hear of this compatibility from?
    } CompatibilityMatrixInfo;
    CompatibilityMatrixInfo compatibilityMatrixInfo[seniors][seniors];
    memset(compatibilityMatrixInfo, 0, sizeof(compatibilityMatrixInfo));

    size_t myBroadcastAcks = 0;

    size_t commitCount = 0;
    bool isCommitted[seniors];
    memset(isCommitted, 0, sizeof(isCommitted));

    // Wait for messages from our neighbours
    while (neighbourCount > 0 && commitCount != seniors) {
        size_t src;
        Message message;
        seniorRecvAny(&message, &src);

        size_t sign0 = message.signs[0]; // The originator of the message
        size_t sign1 = message.signs[1]; // The original target of the message
        bool* isCompatible = &compatibilityMatrix[sign0][sign1];
        CompatibilityMatrixInfo* info = &compatibilityMatrixInfo[sign0][sign1];

        if (message.tag == REQUEST) {
            if (sign1 == NO_SIGNATURE) {
                // New broadcast from our neighbour, so we sign it
                message.signs[1] = sign1 = me->id;

                isCompatible = &compatibilityMatrix[sign0][sign1];
                info = &compatibilityMatrixInfo[sign0][sign1];
                assert(!*isCompatible); // We shouldn't know about it yet
            }

            if (*isCompatible) {
                // We already know about this compatibility, so we ack it
                message.tag = REQUEST_OK;
                seniorSend(src, &message);
            } else {
                // We don't know about this compatibility, so we broadcast it
                *isCompatible = true;
                info->parent = src;

            #ifdef BYZANTINE
                bool noForward = rand() < RAND_MAX / 4;
            #endif

                for (size_t s = 0; s < seniors; ++s) {
                    if (!me->isCompatible[s])
                        continue;

                #ifdef BYZANTINE
                    if (me->isHigh && s != src && (noForward || rand() < RAND_MAX / 2)) {
                        // Pretend to send messages, but don't
                        ++info->acks;
                        continue;
                    }
                #endif

                    seniorSend(s, &message);
                }
            }
        } else if (message.tag == REQUEST_OK) {
            // Ack from a child
            assert(sign1 != NO_SIGNATURE && *isCompatible);
            if (sign0 == me->id && ++myBroadcastAcks == neighbourCount) {
                // We are the top level, so now we let everyone know that we're
                // done if all our neighbours acked
                isCommitted[me->id] = true;
                ++commitCount;
                for (size_t s = 0; s < seniors; ++s) {
                    if (!me->isCompatible[s])
                        continue;
                    seniorSendNew(me, s, COMMIT);
                }
            } else if (sign0 != me->id && ++info->acks == neighbourCount) {
                // Not top level, so we ack our parent if all children have acked
                seniorSend(info->parent, &message);
            }
        } else if (message.tag == COMMIT) {
            // Only broadcast the commit if it's new
            if (!isCommitted[sign0]) {
                isCommitted[sign0] = true;
                ++commitCount;
                for (size_t s = 0; s < seniors; ++s) {
                    if (!me->isCompatible[s])
                        continue;
                    seniorSend(s, &message);
                }
            }
        } else {
            assert(false);
        }
    }

    // Make the matrix symmetric, since some nodes might be leaves and their
    // incoming edge might never be broadcast
    for (size_t s = 0; s < seniors; ++s)
        for (size_t s2 = 0; s2 < seniors; ++s2)
            if (compatibilityMatrix[s][s2])
                compatibilityMatrix[s2][s] = true;

    // Deterministically work out a pairing from the compatibility matrix
    bool isTaken[seniors];
    bool isPaired = false;
    size_t pairedSenior = -1;
    memset(isTaken, 0, sizeof(isTaken));
    for (size_t s = 0; s < seniors; ++s) {
        for (size_t s2 = 0; s2 < seniors; ++s2) {
            if (!isTaken[s] && !isTaken[s2] && s != s2 && compatibilityMatrix[s][s2]) {
                isTaken[s] = isTaken[s2] = true;
                if (s == me->id) {
                    isPaired = true;
                    pairedSenior = s2;
                } else if (s2 == me->id) {
                    isPaired = true;
                    pairedSenior = s;
                }
            }
        }
    }

#if 0
    if (me->isHigh) return;
    for (size_t s = 0; s < seniors; ++s) {
        printf("[%zu] [%zu/%zu] ", me->id, s, seniors);
        for (size_t s2 = 0; s2 < seniors; ++s2)
            printf("%c", compatibilityMatrix[s][s2] ? '1' : '0');
        printf("\n");
    }
#endif

    if (isPaired)
        printf("%zu exchanges life stories with %zu.\n", me->id + 1, pairedSenior + 1);
    else
        printf("%zu has a seniors' moment.\n", me->id + 1);
    printf("%zu is %s.\n", me->id + 1, me->isHigh ? "hallucinating" : "sober");
}

bool readInput(const char* filename, size_t processes, Senior* me) {
    FILE* input = fopen(filename, "r");
    if (!input) {
        perror("Failed to open input file");
        return false;
    }

    size_t seniors;
    if (fscanf(input, "%zu", &seniors) != 1) {
        fprintf(stderr, "Input file in invalid format\n");
        fclose(input);
        return false;
    }
    if (seniors != processes) {
        fprintf(stderr, "Number of processes does not match seniors\n");
        fclose(input);
        return false;
    }
    if (seniors >= 1000) {
        fprintf(stderr, "Too many seniors\n");
        fclose(input);
        return false;
    }

    for (size_t s = 0; s < seniors; ++s) {
        char compatibilityBuffer[seniors + 1];
        char fmt[10];
        sprintf(fmt, "%%%zus", seniors);
        if (fscanf(input, fmt, compatibilityBuffer) != 1) {
            fprintf(stderr, "Input file in invalid format\n");
            fclose(input);
            return false;
        }

        if (s == me->id)
            for (size_t s2 = 0; s2 < seniors; ++s2)
                me->isCompatible[s2] = compatibilityBuffer[s2] == '1';
    }

    size_t highSenior;
    me->isHigh = false;
    while (fscanf(input, "%zu", &highSenior) == 1) {
        if (highSenior - 1 == me->id) {
            me->isHigh = true;
            break;
        }
    }

    fclose(input);
    return true;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int processes;
    int pid;
    MPI_Comm_size(MPI_COMM_WORLD, &processes);
    MPI_Comm_rank(MPI_COMM_WORLD, &pid);
    seniors = processes;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input file>\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    Senior* me = alloca(sizeof(*me) + sizeof(me->isCompatible[0]) * seniors);
    me->id = pid;
    if (!readInput(argv[1], seniors, me)) {
        MPI_Finalize();
        return 1;
    }

    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    srand(ts.tv_nsec);

#if 0
    printf("[%zu/%zu] Seed: %ld; ", me->id, seniors, ts.tv_nsec);
    for (size_t s = 0; s < seniors; ++s)
        printf("%c", me->isCompatible[s] ? '1' : '0');
    printf("%s\n", me->isHigh ? " (high)" : "");
#endif

    // MPI doesn't support poll/select(), so we have to set up async reads from
    // all other seniors and do a MPI_Waitany() on them instead
    MPI_Request _recvRequests[seniors];
    Message _recvBuffers[seniors];
    recvRequests = _recvRequests;
    recvBuffers = _recvBuffers;
    for (size_t s = 0; s < seniors; ++s) {
        int err = MPI_Irecv(&recvBuffers[s], sizeof(recvBuffers[s]), MPI_BYTE, s, 0, MPI_COMM_WORLD, &recvRequests[s]);
        assert(err == 0);
    }

    seniorProcess(me);

    MPI_Finalize();
    return 0;
}
