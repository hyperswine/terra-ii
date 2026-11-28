#!/usr/bin/env sol

C = use "sol/lib/project".
G = use "../scripts/gui".
J = use "std/jsondoc".

testGame u =
  _ = C.setup Unit;
  # the game with no window: tests/headless is a small app project around
  # tests/headless/game.fpr, run by the SDK's host with no display
  _ = C.command ["/bin/sh","-c","cd tests/headless && qos build"];
  disk = "{tempDir "terra-ii-headless"}/disk";
  played = C.command ["/bin/sh","-c","cd tests/headless && qos run . --disk \"$0\" 2>&1",disk];
  _ = C.check "headless game failed" (not (Str.contains "FAIL" played) and Str.contains "terra2 game: done" played);
  _ = C.writeText "evidence/game-headless.log" (Str.join "\n" (List.filter (fn l -> Str.startsWith "ok " l or Str.startsWith "terra2 game" l) (Str.lines played)));
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
    ("checks",J.JArr (List.map J.JStr ["headless game through std/game (disk, no disk, save acknowledgements, late load, tactical hint, real-disk failures)","original 3D title","new game","cursor/card/turn input","PNG snapshots","clean quit"])),
    ("build",J.JStr "qos build and qos run (QOS Portable SDK, qos.toml v2)")]).

>! testGame Unit.
