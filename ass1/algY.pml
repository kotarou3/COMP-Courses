bool b[2] = {false, false};
byte nCrit;

inline criticalSection() {
    nCrit++;
    assert(nCrit == 1);
    nCrit--;
}

inline nonCriticalSection() {
    do
    :: true ->
        skip
    :: true ->
        break
    od
}

active proctype p() {
again:
    nonCriticalSection();

wap:
    b[0] = true;
    do
    :: b[1] ->
        b[0] = true;
        b[0];
        b[0] = true;
    :: else ->
        break;
    od;

csp:
    criticalSection();

    b[0] = false;

    goto again;
}

active proctype q() {
again:
    nonCriticalSection();

waq:
    b[1] = true;
    do
    :: b[0] ->
        b[1] = false;
        !b[0];
        b[1] = true;
    :: else ->
        break;
    od;

csq:
    criticalSection();

    b[1] = false;

    goto again;
}

ltl mutex { !<>(p@csp && q@csq) }
ltl dlf   { [](p@wap && q@waq -> <>(p@csp || q@csq)) }
ltl audp  { [](p@wap && ([]!b[1]) -> <>p@csp) }
ltl audq  { [](q@waq && ([]!b[0]) -> <>q@csq) }
ltl eep   { [](p@wap -> <>p@csp) }
ltl eeq   { [](q@waq -> <>q@csq) }
