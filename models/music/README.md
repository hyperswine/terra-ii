# Terra II music

**Skyward, Little World** (`Skyward_Little_World.mp3`), an original NeoMusic instrumental:
144 BPM, D major / B minor, about 95 seconds, synthesized from Haskell notes, patches and
percussion without samples. M toggles it in the game.

The reproducible score is in the NeoMusic repository
([hyperswine/neomusic](https://github.com/hyperswine/neomusic)), `app/terra-bgm/Main.hs`, with
the arrangement and rebuild notes beside it. This copy is the one QOS kept at
`models/music/Skyward_Little_World.mp3`, byte for byte.

The game asks the host for `models/music/Skyward_Little_World.mp3` (`musicFile` in
`src/input.fpr`). The host looks for that path as given (relative to where `qos run` is started,
the project root when you follow the README), then under `FPR_ASSETS`, then beside the `.qa`.
