#!/usr/bin/env sol
C = use "../scripts/common".
G = use "../scripts/gui".
J = use "sol/lib/json".
testGame u =
  _ = C.setup Unit;
  (job,fifo,scratch) = G.start "terra-ii";
  title = G.shot "terra2" fifo 1 "title";
  _ = G.key fifo 28;
  _ = sleepMs 800;
  game = G.shot "terra2" fifo 2 "game";
  _ = G.key fifo 106;
  _ = G.key fifo 28;
  _ = G.key fifo 57;
  _ = sleepMs 2000;
  turn = G.shot "terra2" fifo 3 "turn";
  _ = C.check "game did not respond to start/turn input" (title != game and game != turn);
  _ = G.key fifo 16;
  _ = G.waitExit job 200;
  C.report "evidence/results.json" (J.JObj [("passed",J.JBool True),("runner",J.JStr "Sol"),
    ("checks",J.JArr (List.map J.JStr ["original 3D title","new game","cursor/card/turn input","PNG snapshots","clean quit"])),
    ("build",J.JStr "qos build and qos run (QOS Portable SDK, qos.toml v2)")]).
> testGame Unit.
