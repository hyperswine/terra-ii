# Pull a CC0 model from Poly Haven's public API and write it as a Terra II mesh
# module (the format tools/mkmesh.sol writes: triangles as milli ints).
#
#   sol scripts/fetch-model.sol ASSET NAME OUT [--height MILLI] [--cell METRES]
#   sol scripts/fetch-model.sol barrel_03 fuel_barrel models/fuel/fuel.fpr --height 900
#
# 1. GET https://api.polyhaven.com/files/ASSET: the glTF at 1k and its buffers
# 2. GET the .gltf (JSON) and its .bin
# 3. read the triangles of every primitive (POSITION + indices, any stride)
# 4. reduce them by vertex clustering on a grid of --cell metres (default
#    0.06): vertices in one cell merge at their mean, collapsed triangles go
# 5. stand it on y = 0, centre it in x and z, scale it to --height milli units
# 6. write OUT with the asset's name, authors, licence and source in a header
#
# glTF is Y-up like the scene, so coordinates are kept as they are (no node
# transforms are applied: Poly Haven props are one untransformed node).
unsafe program.
H = use "sol/lib/http".
J = use "sol/lib/json".

need r = case r of Ok x -> x | Err why -> error "{why}".
api = "https://api.polyhaven.com".

fetch url =
  options = H.withBodyLimit 4194304 (H.withDeadline 60000 (H.defaultOptions));
  HttpResponse status _ bytes = need (Http.request options (HttpRequest "GET" url [("user-agent","terra-ii-fetch-model/1")] (Bytes.empty Unit)));
  if status == 200 then bytes else error "GET {url}: HTTP {status}".
json url = need (J.parse (need (Utf8.decode (fetch url)))).
field key v = need (J.get key v).
text key v = need (J.text (field key v)).
num key v = need (J.num (field key v)).
numOr key fallback v = case J.get key v of Ok x -> need (J.num x) | Err _ -> fallback.
items v = need (J.items v).
nth i v = (items v) ! i.

# little-endian unsigned integer of width bytes at off
uint bytes off width =
  part = Bytes.toList (need (Bytes.slice off width bytes));
  List.fold (fn acc b -> acc * 256 + b) 0 (List.rev part).

# IEEE binary32, decoded exactly (as tools/mkmesh.sol does)
float32 bytes off =
  bits = uint bytes off 4;
  exponent = (bits / 8388608) % 256;
  fraction = bits % 8388608;
  sign = if bits >= 2147483648 then -1 else 1;
  power = if exponent == 0 then -149 else exponent - 150;
  mantissa = sign * (if exponent == 0 then fraction else fraction + 8388608);
  if exponent == 255 then error "non-finite coordinate"
  else if power < 0 then Num.div mantissa (2 ^ (0 - power)) else mantissa * (2 ^ power).

# an accessor's elements: (byte offset of element i, the view's stride)
element gltf accessor size =
  view = nth (num "bufferView" accessor) (field "bufferViews" gltf);
  base = numOr "byteOffset" 0 view + numOr "byteOffset" 0 accessor;
  stride = numOr "byteStride" size view;
  fn i -> base + i * stride.

positions gltf bin accessor =
  _ = (if num "componentType" accessor == 5126 then Unit else error "POSITION is not float");
  at = element gltf accessor 12;
  List.map (fn i -> o = at i; (float32 bin o, float32 bin (o + 4), float32 bin (o + 8))) (List.range 0 (num "count" accessor - 1)).

indexList gltf bin accessor =
  width = case num "componentType" accessor of 5121 -> 1 | 5123 -> 2 | 5125 -> 4 | t -> error "index type {t}";
  at = element gltf accessor width;
  List.map (fn i -> uint bin (at i) width) (List.range 0 (num "count" accessor - 1)).

# every primitive's triangles, as (a, b, c) position triples
triangles gltf bin =
  accessors = field "accessors" gltf;
  prims = List.concat (List.map (fn m -> items (field "primitives" m)) (items (field "meshes" gltf)));
  List.concat (List.map (fn p ->
      ps = positions gltf bin (nth (num "POSITION" (field "attributes" p)) accessors);
      is = indexList gltf bin (nth (num "indices" p) accessors);
      triples is ps) prims).
triples is ps = case is of
    a :: b :: c :: rest -> (ps ! a, ps ! b, ps ! c) :: triples rest ps
  | _ -> [].

# ---- vertex clustering ----
key cell p = (x, y, z) = p; (Num.round (x / cell), Num.round (y / cell), Num.round (z / cell)).
# clusters: (key, sx, sy, sz, n), one per occupied cell
addTo clusters k p = (x, y, z) = p; case clusters of
    [] -> [(k, x, y, z, 1)]
  | c :: rest -> (ck, sx, sy, sz, n) = c;
      if ck == k then (ck, sx + x, sy + y, sz + z, n + 1) :: rest else c :: addTo rest k p.
meanOf clusters k = case clusters of
    [] -> error "cluster missing"
  | c :: rest -> (ck, sx, sy, sz, n) = c; if ck == k then (sx / n, sy / n, sz / n) else meanOf rest k.
reduce cell tris =
  corners = List.concat (List.map (fn t -> (a, b, c) = t; [a, b, c]) tris);
  clusters = List.fold (fn cs p -> addTo cs (key cell p) p) [] corners;
  kept = List.filter (fn t -> (a, b, c) = t; ka = key cell a; kb = key cell b; kc = key cell c;
                         not (ka == kb or kb == kc or ka == kc)) tris;
  (List.map (fn t -> (a, b, c) = t; (meanOf clusters (key cell a), meanOf clusters (key cell b), meanOf clusters (key cell c))) kept, List.len clusters).

# ---- placement and output ----
corners tris = List.concat (List.map (fn t -> (a, b, c) = t; [a, b, c]) tris).
lowest f ps = List.fold (fn m p -> v = f p; if v < m then v else m) (f (ps ! 0)) ps.
highest f ps = List.fold (fn m p -> v = f p; if v > m then v else m) (f (ps ! 0)) ps.
px p = (x, _, _) = p; x.
py p = (_, y, _) = p; y.
pz p = (_, _, z) = p; z.
chunks words = case words of
    [] -> []
  | _ -> ("\"" + Str.join " " (List.take 48 words) + " \"") :: chunks (List.drop 48 words).

options argv height cell = case argv of
    [] -> (height, cell)
  | "--height" :: v :: rest -> options rest (parseNum v) cell
  | "--cell" :: v :: rest -> options rest height (parseNum v)
  | other :: _ -> error "unexpected argument {other}".

writeNow path text =
  bytes = need (Utf8.encode text);
  scratch = tempDir "fetch-model";
  w = need (Stream.openWrite "{scratch}/out" (Bytes.len bytes + 1));
  (result, w2) = Stream.writeChunk bytes w;
  _ = need (Stream.closeWrite w2);
  _ = need result;
  _ = need (Fs.copyPublishNow "{scratch}/out" path 65536 True);
  Unit.

pull asset name out height cell =
  info = json "{api}/info/{asset}";
  authors = Str.join ", " (List.map (fn kv -> (who, _) = kv; who) (need (J.fields (field "authors" info))));
  gltfEntry = field "gltf" (field "1k" (field "gltf" (json "{api}/files/{asset}")));
  gltfUrl = text "url" gltfEntry;
  gltf = json gltfUrl;
  binName = text "uri" (nth 0 (field "buffers" gltf));
  bin = fetch (text "url" (field binName (field "include" gltfEntry)));
  tris = triangles gltf bin;
  (reduced, cells) = reduce cell tris;
  ps = corners reduced;
  cx = (lowest px ps + highest px ps) / 2; cz = (lowest pz ps + highest pz ps) / 2;
  y0 = lowest py ps; tall = highest py ps - y0;
  s = height / tall;
  words = List.map (fn p -> (x, y, z) = p;
      "{Num.round ((x - cx) * s)} {Num.round ((y - y0) * s)} {Num.round ((z - cz) * s)}") ps;
  n = List.len reduced;
  header = ["# generated by scripts/fetch-model.sol -- do not edit; triangles as milli ints (x y z) x 3",
            "# {name}: Poly Haven \"{text "name" info}\" ({asset}) by {authors}, CC0 1.0",
            "# source: {gltfUrl}",
            "# {List.len tris} triangles reduced to {n} by {cells} clusters of {cell} m; {height} milli units tall",
            "unsafe module.", ""];
  body = "{name} = " + Str.join "\n  + " (chunks words) + ".";
  _ = writeNow out (Str.join "\n" (header + [body, "", "meshes = (\"{name}\", {name}) :: Nil.", ""]));
  print "{asset} by {authors}: {List.len tris} triangles -> {n} ({cells} clusters) -> {out}".

> case args Unit of
    asset :: name :: out :: rest -> (height, cell) = options rest 900 0.06; pull asset name out height cell
  | _ -> error "usage: sol scripts/fetch-model.sol ASSET NAME OUT [--height MILLI] [--cell METRES]".
