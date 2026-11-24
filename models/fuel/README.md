# fuel

`fuel.fpr` is generated: Poly Haven's "Barrel 03" (`barrel_03`) by Serhii Khromov,
CC0 1.0 (https://polyhaven.com/a/barrel_03), pulled through Poly Haven's public API
and reduced from 1,473 to 252 triangles by vertex clustering:

    sol scripts/fetch-model.sol barrel_03 fuel_barrel models/fuel/fuel.fpr --height 900 --cell 0.09

The FuelDump card (id 15) draws three of these barrels (`fuelDump` in `src/scene.fpr`).
