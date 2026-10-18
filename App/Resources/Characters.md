# Walking characters

This note sits beside `Characters/`, not inside it. Xcode copies that folder
into the app as a whole, so a readme or a placeholder in there would ship with
the game (`Scripts/build.sh` refuses one).

The three files in `Characters/` are the pedestrians that walk the pavements.
They are made with the Meshy service, not by `Tools/assetgen`, so
`Scripts/models.sh` neither generates nor checks them; their brief sections in
`docs/asset-brief.md` carry `Status: external`. The app scales each to the
brief's 1.75 m and stands it on the floor when it loads (`EntityBuilder.align`),
and plays its embedded walk cycle on repeat (`TrafficDriver.startWalkCycles`).

| File | Preview task | Refine task | Rig task | Model | Credits | Date |
|---|---|---|---|---|---|---|
| pedestrian_a | `01a14e30-a66e-7448-926e-4e8c745296ed` | `01a14e31-7e55-75a3-b583-1d4c892b56ee` | `01a14e32-9b41-7709-8519-5006a5cb44be` | meshy-7.1 | 35 | 2026-10-18 |
| pedestrian_b | `01a14e30-ae84-75a1-8233-540719ce2469` | `01a14e31-8748-721b-b125-f6041049aaa2` | `01a14e32-a975-7076-9edf-5998b3efca51` | meshy-7.1 | 35 | 2026-10-18 |
| pedestrian_c | `01a14e30-b98b-776b-84cb-8ff417761b72` | `01a14e31-8eab-7728-911b-53b1a9e8e6da` | `01a14e32-b9b6-749e-9718-df05dea6b904` | meshy-7.1 | 35 | 2026-10-18 |

How each was made:

1. **Preview** — `meshy_text_to_3d`, `ai_model: meshy-7.1`, `pose_mode: t-pose`,
   `should_remesh: true`, `target_polycount: 12000`, `target_formats: [glb]`,
   with the `Prompt:` line of the character's brief section, verbatim.
2. **Refine** — `meshy_text_to_3d_refine` on the preview, model inherited,
   `target_formats: [glb, usdz]`, texture prompt
   `flat pastel colours, plain <coat colour> <hex> coat, cream #FAFAF7 skin and shirt, charcoal #22252B trousers and shoes, no logos, no text`
   (slate-grey #4A4E57, sage-green #6E8B74, mustard-yellow #E9C46A).
3. **Rig** — `meshy_rig` on the refine task, `height_meters: 1.75`. Its free
   walking animation (`basic_animations.walking_glb_url`,
   `Animation_Walking_withSkin.glb`) is the file shipped; the rig offers no USDZ.
4. **Convert** — locally, with Apple's USD tools in `/usr/bin` and no Meshy spend:

   ```bash
   usdextract -o tex Animation_Walking_withSkin.glb          # pulls out Image_0.jpg
   usdcat Animation_Walking_withSkin.glb -o pedestrian_x.usda
   # point the base-colour texture at ./tex/Image_0.jpg instead of the .glb[Image_0.jpg] sub-path
   sed -i '' -E 's#@[^@]*\.glb\[([^]]+)\]@#@./tex/\1@#g' pedestrian_x.usda
   usdzip --arkitAsset pedestrian_x.usda pedestrian_x.usdz
   usdchecker --arkit pedestrian_x.usdz                        # Success!
   ```

   The skeleton and its `SkelAnimation` survive the conversion;
   `TrafficDriverTests.characterFileCarriesAWalkAnimation_*` is the tripwire.
5. **Fix the joint paths** — the conversion writes every joint as
   `n25/n23/n14/…`, where the leading `n25` is not a joint. RealityKit then
   drops the skin binding: the file loads and the animation is listed, but the
   mesh never bends. Strip that leading segment from the `joints` list on the
   `Skeleton` and the `SkelAnimation`, then repack (needs Python with `pxr`):

   ```python
   # fix_joints.py in.usdz out.usdz
   import sys, os, shutil, subprocess, glob, tempfile
   from pxr import Usd, Vt
   src, dst = sys.argv[1:3]
   d = tempfile.mkdtemp()
   try:
       subprocess.run(["unzip", "-q", src, "-d", d], check=True)
       root = glob.glob(d + "/*.usd*")[0]
       st = Usd.Stage.Open(root)
       for prim in st.Traverse():
           if prim.GetTypeName() not in ("Skeleton", "SkelAnimation"): continue
           at = prim.GetAttribute("joints"); joints = list(at.Get())
           first = joints[0].split("/")[0]; prefix = first + "/"
           if first in joints or not all(j == first or j.startswith(prefix) for j in joints): continue
           at.Set(Vt.TokenArray([j[len(prefix):] if j.startswith(prefix) else j for j in joints]))
       st.GetRootLayer().Save()
       names = [os.path.basename(root)] + [p for p in os.listdir(d) if p != os.path.basename(root)]
       if os.path.exists(dst): os.remove(dst)
       subprocess.run(["usdzip", os.path.abspath(dst)] + names, cwd=d, check=True)
   finally:
       shutil.rmtree(d, ignore_errors=True)
   ```

   `TrafficDriverTests.characterMeshIsSkinnedToItsSkeleton` and
   `walkCycleBendsTheBodyOnScreen` are the tripwires: skip this step and they go red.

**Replacing a file.** Re-download from the rig task by its id first
(`meshy_get_task_status` on the rig task returns fresh walking-GLB links, free)
and repeat steps 4 and 5. Generate a new character only when the look itself has to
change, and record the new task ids, model and credits in this table.
