# Asset brief for the 3D models

This brief tells an artist, or an AI image-to-3D tool, exactly which models the game needs, how big they are and how they must be built, so each code-built shape can be replaced by a real model one file at a time. The game already contains a coloured stand-in for every item below; a file dropped into `App/Resources/Models/` with the asset's exact name replaces the stand-in at the next build with no code change. The shop is called Plum and sits on a street in a block of flats.

## Global conventions

- Units are metres. Y is up. The pivot is the bottom centre of the item's footprint.
- The front of the item faces +Z. The grid is half a metre per cell, so footprints are multiples of 0.5 m.
- Format: USDZ with embedded textures, one 1024 x 1024 atlas per asset at most.
- Style: flat pastel low-poly diorama, soft rounded edges, no photographic textures and no baked shadows.
- No baked text except on the signage assets (`plum_mark`, `storefront_sign`, `window_poster_set`, `menu_board_texture`). All text is English.
- No real-world brand, logo or trade dress other than the Plum brand.
- Naming: the file name is the asset name below, lower snake case, e.g. `gondola_shelf.usdz`.
- Level of detail: there is one USDZ per asset. The app drops nothing from a model, so keep the budgets below.
- Keep the parts listed under each asset as separate named meshes where the tool allows it; the stand-in is built from exactly those parts.
- A section whose Status line reads "stand-in only" is a kind with no model yet: the generator and the checker skip it and nothing is written for it (no section carries it today).
- Sourced street props (`parked_car_*`, `tree_*`) are the written exception to the flat-pastel rule and to the named-parts rule: realistic proportions and textured surfaces, colours muted toward the palette, one mesh. A section with a `Source:` line is not generated; `Tools/assetgen` skips it.
- Parts named `product_<shelf>_<facing>`, `bottle_<shelf>_<facing>` and `carton_<shelf>_<facing>` are recoloured per placed copy by the app and must carry a flat colour, no texture.

## Palette

| Name | Hex |
|---|---|
| primary | #4A4E57 |
| primaryDeep | #2E1A47 |
| primaryLight | #D9D6CF |
| accentMint | #B9C6B0 |
| mintDeep | #6E8B74 |
| cream | #FAFAF7 |
| charcoal | #22252B |
| priceRailYellow | #E9C46A |
| woodLight | #C9A27E |
| tileWhite | #F4F4F2 |
| asphalt | #4B4F57 |
| sidewalk | #BDBAB3 |
| grassPastel | #B7C4A8 |
| skyPastel | #E6EAEE |
| warmLamp | #FFE2B8 |

Use only these colours (and light or dark shades of them).

## Assets

### gondola_shelf

Dimensions: 1.0 x 1.0 x 1.75 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 6000 triangles

Palette: charcoal #22252B, primaryDeep #2E1A47, cream #FAFAF7, tileWhite #F4F4F2, priceRailYellow #E9C46A, primary #4A4E57

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, upright_left, upright_right, back_panel, slot_row_0-2, shelf_0-3, price_rail_0-3 (yellow strip on every shelf edge), header_sign with category text, product rows on every shelf (at least 16 facings mixing packets, cans and bottles in at least six colours)

Description: A free-standing metal shop shelf, 0.9 m wide, with four shelves, a yellow price strip on each shelf edge and a graphite header sign. Rows of varied packets, cans and bottles sit on every shelf.

Prompt: Low-poly flat-shaded pastel diorama model of a free-standing metal shop shelf, 0.9 m wide, with four shelves, a yellow price strip on each shelf edge and a graphite header sign. Rows of varied packets, cans and bottles sit on every shelf. Size 1.0 x 1.0 x 1.75 metres, pivot at the bottom centre, front facing +Z, at most 6000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #2E1A47, #FAFAF7, #F4F4F2, #E9C46A, #4A4E57), no text, no real-world logos. Export as USDZ.

### wall_shelf

Dimensions: 1.0 x 0.5 x 1.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 5000 triangles

Palette: charcoal #22252B, primaryDeep #2E1A47, cream #FAFAF7, tileWhite #F4F4F2, priceRailYellow #E9C46A, primary #4A4E57, woodLight #C9A27E

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, upright_left, upright_right, back_panel, slot_row_0-2, shelf_0-3, price_rail_0-3, header_sign, wall_rail, product rows (at least 12 facings)

Description: A shallow shelf unit that stands against a wall, with four shelves, yellow price strips and a header sign. It is the single-sided version of the gondola shelf.

Prompt: Low-poly flat-shaded pastel diorama model of a shallow shelf unit that stands against a wall, with four shelves, yellow price strips and a header sign. It is the single-sided version of the gondola shelf. Size 1.0 x 0.5 x 1.9 metres, pivot at the bottom centre, front facing +Z, at most 5000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #2E1A47, #FAFAF7, #F4F4F2, #E9C46A, #4A4E57, #C9A27E), no text, no real-world logos. Export as USDZ.

### end_cap

Dimensions: 1.0 x 0.5 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3000 triangles

Palette: charcoal #22252B, cream #FAFAF7, tileWhite #F4F4F2, priceRailYellow #E9C46A, mintDeep #6E8B74

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, back, shelf_0-2, price_rail_0-2, product rows (at least 4 facings), promo_sign with offer text

Description: A short display stand that closes the end of a shelf run. It has three shelves of promotional goods and a mint promo sign on top.

Prompt: Low-poly flat-shaded pastel diorama model of a short display stand that closes the end of a shelf run. It has three shelves of promotional goods and a mint promo sign on top. Size 1.0 x 0.5 x 1.5 metres, pivot at the bottom centre, front facing +Z, at most 3000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #FAFAF7, #F4F4F2, #E9C46A, #6E8B74), no text, no real-world logos. Export as USDZ.

### wall_fridge

Dimensions: 1.0 x 1.0 x 2.2 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 7000 triangles

Palette: charcoal #22252B, primaryDeep #2E1A47, tileWhite #F4F4F2, skyPastel #E6EAEE, cream #FAFAF7, primary #4A4E57

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: frame, frame_side_left, frame_side_right, plinth, interior_glow (light panel), shelf_0-3, bottle_<shelf>_<i> (at least 12 bottles behind the glass), door_left, door_right (glass), handle_left, handle_right, header (graphite), compressor_vent

Description: A tall drinks cooler with two glass doors and long handles. The inside glows white and shows four shelves of bottles; a graphite header sits on top.

Prompt: Low-poly flat-shaded pastel diorama model of a tall drinks cooler with two glass doors and long handles. The inside glows white and shows four shelves of bottles; a graphite header sits on top. Size 1.0 x 1.0 x 2.2 metres, pivot at the bottom centre, front facing +Z, at most 7000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #2E1A47, #F4F4F2, #E6EAEE, #FAFAF7, #4A4E57), no text, no real-world logos. Export as USDZ.

### dairy_chiller

Dimensions: 1.5 x 1.0 x 1.4 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 5000 triangles

Palette: primaryLight #D9D6CF, primaryDeep #2E1A47, tileWhite #F4F4F2, primary #4A4E57, cream #FAFAF7

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: body, open_front_lip, glow, shelf_0-2, carton_<shelf>_<i> (at least 8 cartons and tubs), back_riser, riser_text

Description: A low open-front chiller for milk, yoghurt and cheese. Three stepped shelves of cartons rise behind a graphite riser.

Prompt: Low-poly flat-shaded pastel diorama model of a low open-front chiller for milk, yoghurt and cheese. Three stepped shelves of cartons rise behind a graphite riser. Size 1.5 x 1.0 x 1.4 metres, pivot at the bottom centre, front facing +Z, at most 5000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#D9D6CF, #2E1A47, #F4F4F2, #4A4E57, #FAFAF7), no text, no real-world logos. Export as USDZ.

### checkout_counter

Dimensions: 2.0 x 1.0 x 1.3 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 5000 triangles

Palette: primary #4A4E57, woodLight #C9A27E, accentMint #B9C6B0, charcoal #22252B, mintDeep #6E8B74, cream #FAFAF7, priceRailYellow #E9C46A

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: counter, counter_top, front_stripe, conveyor_belt, till, till_screen, card_terminal, receipt_printer, bag_dispenser, impulse_rack with at least 6 impulse_item_<i> (gum and sweets)

Description: A wood-topped checkout counter with a mint stripe, a till with a glowing screen, a card terminal and a rack of small sweets at the front.

Prompt: Low-poly flat-shaded pastel diorama model of a wood-topped checkout counter with a mint stripe, a till with a glowing screen, a card terminal and a rack of small sweets at the front. Size 2.0 x 1.0 x 1.3 metres, pivot at the bottom centre, front facing +Z, at most 5000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#4A4E57, #C9A27E, #B9C6B0, #22252B, #6E8B74, #FAFAF7, #E9C46A), no text, no real-world logos. Export as USDZ.

### cigarette_cabinet

Dimensions: 1.5 x 0.5 x 1.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3500 triangles

Palette: charcoal #22252B, skyPastel #E6EAEE, primaryLight #D9D6CF, priceRailYellow #E9C46A, warmLamp #FFE2B8

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: cabinet, door_left, door_right (glass), shelf_0-2, lottery_screen, scratchcard_rack

Description: A tall dark cabinet with two glass doors for tobacco and lottery tickets, with a yellow lottery screen and a small rack of scratch cards. Show packs by colour only, no brand text.

Prompt: Low-poly flat-shaded pastel diorama model of a tall dark cabinet with two glass doors for tobacco and lottery tickets, with a yellow lottery screen and a small rack of scratch cards. Show packs by colour only, no brand text. Size 1.5 x 0.5 x 1.9 metres, pivot at the bottom centre, front facing +Z, at most 3500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #E6EAEE, #D9D6CF, #E9C46A, #FFE2B8), no text, no real-world logos. Export as USDZ.

### hot_food_counter

Dimensions: 2.5 x 1.0 x 2.1 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 12000 triangles

Palette: primary #4A4E57, woodLight #C9A27E, charcoal #22252B, asphalt #4B4F57, primaryLight #D9D6CF, skyPastel #E6EAEE, warmLamp #FFE2B8, mintDeep #6E8B74, priceRailYellow #E9C46A, accentMint #B9C6B0, tileWhite #F4F4F2, sidewalk #BDBAB3, cream #FAFAF7

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: counter, counter_top, kick_strip, roller_grill (grill_base, roller_0-5, sausage_0-3), heated_case (case_base, case_glass, case_roof, case_glow, pastry_0-2, baguette_0-1), bun_warmer (warmer_body, warmer_lid), condiment_station (station_tray, pump_0-2, napkin_box), tile_wall with grout lines

Description: A hot-food counter with a roller grill of sausages, a glass heated case with pastries and baguettes, a bun warmer and a condiment station with three pumps, in front of a white tile wall.

Prompt: Low-poly flat-shaded pastel diorama model of a hot-food counter with a roller grill of sausages, a glass heated case with pastries and baguettes, a bun warmer and a condiment station with three pumps, in front of a white tile wall. Size 2.5 x 1.0 x 2.1 metres, pivot at the bottom centre, front facing +Z, at most 12000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#4A4E57, #C9A27E, #22252B, #4B4F57, #D9D6CF, #E6EAEE, #FFE2B8, #6E8B74, #E9C46A, #B9C6B0, #F4F4F2, #BDBAB3, #FAFAF7), no text, no real-world logos. Export as USDZ.

### coffee_machine

Dimensions: 0.5 x 0.5 x 0.8 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3000 triangles

Palette: woodLight #C9A27E, charcoal #22252B, accentMint #B9C6B0, asphalt #4B4F57, cream #FAFAF7

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: stand, body, screen, spout_left, spout_right, drip_tray, cup_stack_0-2

Description: A self-service coffee machine on a small wooden stand, with a mint screen, two spouts, a drip tray and three stacks of cups.

Prompt: Low-poly flat-shaded pastel diorama model of a self-service coffee machine on a small wooden stand, with a mint screen, two spouts, a drip tray and three stacks of cups. Size 0.5 x 0.5 x 0.8 metres, pivot at the bottom centre, front facing +Z, at most 3000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#C9A27E, #22252B, #B9C6B0, #4B4F57, #FAFAF7), no text, no real-world logos. Export as USDZ.

### menu_screen

Dimensions: 2.5 x 0.1 x 0.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1500 triangles

Palette: charcoal #22252B, primaryDeep #2E1A47, priceRailYellow #E9C46A, accentMint #B9C6B0, primaryLight #D9D6CF, warmLamp #FFE2B8, mintDeep #6E8B74, cream #FAFAF7

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: bezel, screen (glowing), menu_tile_0-5 (coloured blocks standing in for dishes), price_dot_0-5

Description: A wide wall-hung menu screen showing six coloured tiles for dishes with a price dot on each. Pastel blocks only; the real menu is a texture, see menu_board_texture.

Prompt: Low-poly flat-shaded pastel diorama model of a wide wall-hung menu screen showing six coloured tiles for dishes with a price dot on each. Pastel blocks only; the real menu is a texture, see menu_board_texture. Size 2.5 x 0.1 x 0.9 metres, pivot at the bottom centre, front facing +Z, at most 1500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #2E1A47, #E9C46A, #B9C6B0, #D9D6CF, #FFE2B8, #6E8B74, #FAFAF7), no text, no real-world logos. Export as USDZ.

### window_ledge

Dimensions: 2.0 x 0.5 x 1.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 800 triangles

Palette: woodLight #C9A27E, charcoal #22252B

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: ledge_top, support_left, support_right

Description: A light-wood counter ledge along the shop window with two dark steel supports, used for standing or sitting with a coffee.

Prompt: Low-poly flat-shaded pastel diorama model of a light-wood counter ledge along the shop window with two dark steel supports, used for standing or sitting with a coffee. Size 2.0 x 0.5 x 1.0 metres, pivot at the bottom centre, front facing +Z, at most 800 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#C9A27E, #22252B), no text, no real-world logos. Export as USDZ.

### high_stool

Dimensions: 0.5 x 0.5 x 0.75 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1200 triangles

Palette: charcoal #22252B, asphalt #4B4F57, primary #4A4E57

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base_disc, post, foot_ring, seat

Description: A tall round stool with a graphite seat, a thin steel post and a foot ring above a dark base disc.

Prompt: Low-poly flat-shaded pastel diorama model of a tall round stool with a graphite seat, a thin steel post and a foot ring above a dark base disc. Size 0.5 x 0.5 x 0.75 metres, pivot at the bottom centre, front facing +Z, at most 1200 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #4B4F57, #4A4E57), no text, no real-world logos. Export as USDZ.

### basket_stack

Dimensions: 0.5 x 0.5 x 0.6 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 2500 triangles

Palette: charcoal #22252B, primary #4A4E57, accentMint #B9C6B0

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: stand, basket_0-4 (alternating graphite and mint)

Description: A stack of five shopping baskets, alternating graphite and mint, on a small dark stand.

Prompt: Low-poly flat-shaded pastel diorama model of a stack of five shopping baskets, alternating graphite and mint, on a small dark stand. Size 0.5 x 0.5 x 0.6 metres, pivot at the bottom centre, front facing +Z, at most 2500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #4A4E57, #B9C6B0), no text, no real-world logos. Export as USDZ.

### back_room_door

Dimensions: 1.0 x 0.2 x 2.1 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 800 triangles

Palette: charcoal #22252B, woodLight #C9A27E, asphalt #4B4F57, primaryDeep #2E1A47

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: frame, door, push_plate, staff_only_sign

Description: A plain wooden staff door in a dark frame with a steel push plate and a small graphite staff-only sign.

Prompt: Low-poly flat-shaded pastel diorama model of a plain wooden staff door in a dark frame with a steel push plate and a small graphite staff-only sign. Size 1.0 x 0.2 x 2.1 metres, pivot at the bottom centre, front facing +Z, at most 800 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #C9A27E, #4B4F57, #2E1A47), no text, no real-world logos. Export as USDZ.

### pendant_lamp

Dimensions: 0.4 x 0.4 x 1.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1200 triangles

Palette: charcoal #22252B, primary #4A4E57, warmLamp #FFE2B8

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: cord, shade (graphite), bulb (warm glow)

Description: A ceiling pendant lamp: a thin cord, a graphite cone shade and a warm glowing bulb underneath.

Prompt: Low-poly flat-shaded pastel diorama model of a ceiling pendant lamp: a thin cord, a graphite cone shade and a warm glowing bulb underneath. Size 0.4 x 0.4 x 1.0 metres, pivot at the bottom centre, front facing +Z, at most 1200 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #4A4E57, #FFE2B8), no text, no real-world logos. Export as USDZ.

### entrance_door

Dimensions: 1.5 x 0.5 x 2.4 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1500 triangles

Palette: charcoal #22252B, skyPastel #E6EAEE, cream #FAFAF7, primaryDeep #2E1A47

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: frame, leaf_left, leaf_right (glass), handle_left, handle_right, mat

Description: A double glass shop door with long handles, a dark top frame and a graphite doormat in front.

Prompt: Low-poly flat-shaded pastel diorama model of a double glass shop door with long handles, a dark top frame and a graphite doormat in front. Size 1.5 x 0.5 x 2.4 metres, pivot at the bottom centre, front facing +Z, at most 1500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #E6EAEE, #FAFAF7, #2E1A47), no text, no real-world logos. Export as USDZ.

### window_poster

Dimensions: 0.8 x 0.05 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 300 triangles

Palette: priceRailYellow #E9C46A, accentMint #B9C6B0, primary #4A4E57

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: poster, headline_block

Description: A poster stuck on the shop window: a pastel sheet with a graphite headline block. The artwork itself comes from window_poster_set. The sheet's texture coordinates cover the first of the three panels; the app slides them to the second or third per placed copy.

Prompt: Low-poly flat-shaded pastel diorama model of a poster stuck on the shop window: a pastel sheet with a graphite headline block. The artwork itself comes from window_poster_set. Size 0.8 x 0.05 x 1.5 metres, pivot at the bottom centre, front facing +Z, at most 300 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#E9C46A, #B9C6B0, #4A4E57), no text, no real-world logos. Export as USDZ.

### atm_locker

Dimensions: 1.5 x 0.5 x 2.2 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 2500 triangles

Palette: primaryDeep #2E1A47, accentMint #B9C6B0, asphalt #4B4F57, primary #4A4E57, primaryLight #D9D6CF

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: atm_body, atm_screen, keypad, locker_body, locker_door_0-3

Description: A cash machine with a glowing mint screen next to a parcel locker wall with four doors in alternating graphite shades.

Prompt: Low-poly flat-shaded pastel diorama model of a cash machine with a glowing mint screen next to a parcel locker wall with four doors in alternating graphite shades. Size 1.5 x 0.5 x 2.2 metres, pivot at the bottom centre, front facing +Z, at most 2500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2E1A47, #B9C6B0, #4B4F57, #4A4E57, #D9D6CF), no text, no real-world logos. Export as USDZ.

### a_frame_sign

Dimensions: 0.4 x 0.3 x 0.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 500 triangles

Palette: woodLight #C9A27E, charcoal #22252B, cream #FAFAF7

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: leg_left, leg_right, board, board_text

Description: A wooden A-frame pavement sign with a dark chalk board and the word Coffee.

Prompt: Low-poly flat-shaded pastel diorama model of a wooden A-frame pavement sign with a dark chalk board and the word Coffee. Size 0.4 x 0.3 x 0.9 metres, pivot at the bottom centre, front facing +Z, at most 500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#C9A27E, #22252B, #FAFAF7), no text, no real-world logos. Export as USDZ.

### litter_bin

Dimensions: 0.4 x 0.4 x 1.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 900 triangles

Palette: charcoal #22252B, mintDeep #6E8B74

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: post, body (mint), lid

Description: A round mint litter bin on a short post with a dark lid.

Prompt: Low-poly flat-shaded pastel diorama model of a round mint litter bin on a short post with a dark lid. Size 0.4 x 0.4 x 1.0 metres, pivot at the bottom centre, front facing +Z, at most 900 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #6E8B74), no text, no real-world logos. Export as USDZ.

### bike_rack

Dimensions: 1.4 x 0.12 x 0.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 800 triangles

Palette: asphalt #4B4F57, charcoal #22252B

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, hoop_0-2 (each with hoop_<i>_post_left, hoop_<i>_post_right, hoop_<i>_bar)

Description: A row of three upside-down U-shaped bike hoops on a flat steel base.

Prompt: Low-poly flat-shaded pastel diorama model of a row of three upside-down U-shaped bike hoops on a flat steel base. Size 1.4 x 0.12 x 0.9 metres, pivot at the bottom centre, front facing +Z, at most 800 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#4B4F57, #22252B), no text, no real-world logos. Export as USDZ.

### street_lamp

Dimensions: 0.8 x 0.3 x 4.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1500 triangles

Palette: charcoal #22252B, warmLamp #FFE2B8

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: post, arm, head, glow

Description: A tall dark street lamp with a short arm and a head that glows warm.

Prompt: Low-poly flat-shaded pastel diorama model of a tall dark street lamp with a short arm and a head that glows warm. Size 0.8 x 0.3 x 4.5 metres, pivot at the bottom centre, front facing +Z, at most 1500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #FFE2B8), no text, no real-world logos. Export as USDZ.

### parked_car_hatchback

Dimensions: 4.5 x 2.0 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, long axis along X, front of the car toward +X (the app turns the file two quarter turns on load)

Poly budget: 15000 triangles

Palette: accentMint #B9C6B0, mintDeep #6E8B74, charcoal #22252B, skyPastel #E6EAEE

Format: USDZ, embedded 1K texture (1024 x 1024 colour and normal, constant metallic and roughness), one mesh

Parts: single mesh (sourced, no named parts)

Description: A small five-door hatchback in muted sage green with real wheel arches, tyres with rims, door mirrors, glass windows and blank number-plate recesses. No badges or logos.

Prompt: small European-style five-door hatchback with a low, long body — roof height about one third of the car's length, muted sage green, real wheel arches, tyres with rims, door mirrors, blank number-plate recesses, no badges or logos, clean three-quarter view on a plain light background

Source: Meshy — text-to-image task 01a14b38-457f-761f-9091-45ff9d942059, image-to-3d task 01a14b38-f5ea-76db-9a3b-00867c297ca0, remesh task 01a14b3a-f15a-736c-83da-1c3b3c7066c6, meshy-6, 2026-10-17

### parked_car_saloon

Dimensions: 4.5 x 2.0 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, long axis along X, front of the car toward +X (the app turns the file two quarter turns on load)

Poly budget: 15000 triangles

Palette: sidewalk #BDBAB3, primaryLight #D9D6CF, charcoal #22252B, skyPastel #E6EAEE

Format: USDZ, embedded 1K texture (1024 x 1024 colour and normal, constant metallic and roughness), one mesh

Parts: single mesh (sourced, no named parts)

Description: A compact four-door saloon in warm grey with real wheel arches, tyres with rims, door mirrors, glass windows and blank number-plate recesses. No badges or logos.

Prompt: compact four-door saloon, warm grey, real wheel arches, tyres with rims, door mirrors, blank number-plate recesses, no badges or logos, clean three-quarter view on a plain light background

Source: Meshy — text-to-image task 01a14b26-a939-7155-87bf-d1f3b41d1472, image-to-3d task 01a14b27-db63-74da-86fb-28f5511f6817, remesh task 01a14b2e-bf92-76f0-b948-d00ffd978594, meshy-6, 2026-10-17

### parked_car_van

Dimensions: 4.5 x 2.0 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, long axis along X, front of the car toward +X (the app turns the file two quarter turns on load)

Poly budget: 15000 triangles

Palette: cream #FAFAF7, tileWhite #F4F4F2, charcoal #22252B, skyPastel #E6EAEE

Format: USDZ, embedded 1K texture (1024 x 1024 colour and normal, constant metallic and roughness), one mesh

Parts: single mesh (sourced, no named parts)

Description: A small low estate car in off-white with a long flat roofline, real wheel arches, tyres with rims, door mirrors, glass windows and blank number-plate recesses. No badges or logos.

Prompt: small low estate car (station wagon) with a long flat roofline — roof height about one third of the car's length, off-white, real wheel arches, tyres with rims, door mirrors, blank number-plate recesses, no badges or logos, clean three-quarter view on a plain light background

Source: Meshy — text-to-image task 01a14b38-4662-7729-84c3-bf6ae4be34e2, image-to-3d task 01a14b38-ff83-7054-b2bf-a695cccb910c, remesh task 01a14b3c-d04f-75b7-b8c6-b1cf8a9be350, meshy-6, 2026-10-17

### tree_linden

Dimensions: 1.4 x 1.4 x 4.0 m (width x depth x height)

Pivot: bottom centre of the footprint (no turn needed)

Poly budget: 10000 triangles

Palette: woodLight #C9A27E, grassPastel #B7C4A8, mintDeep #6E8B74, charcoal #22252B

Format: USDZ, embedded 1K texture (1024 x 1024 colour and normal, constant metallic and roughness), one mesh

Parts: single mesh (sourced, no named parts)

Description: A street linden with a tall straight trunk, a rounded crown with visible leaf clusters and a round metal grate at the base, in muted green.

Prompt: slender street linden with a narrow upright column-shaped crown, the whole tree about three times taller than it is wide, tall straight trunk, visible leaf clusters, round metal tree grate at the base, muted green, 4 m tall and about 1.4 m wide, full tree in frame on a plain light background

Source: Meshy — text-to-image task 01a14b38-4759-7042-bb38-9ee507c5eb22, image-to-3d task 01a14b39-08ef-76ff-bdbb-be63ee9c6b17, remesh task 01a14b3c-d162-727f-ba13-ce09f1bcf19c, meshy-6, 2026-10-17

### tree_maple

Dimensions: 1.4 x 1.4 x 4.0 m (width x depth x height)

Pivot: bottom centre of the footprint (no turn needed)

Poly budget: 10000 triangles

Palette: woodLight #C9A27E, grassPastel #B7C4A8, mintDeep #6E8B74, priceRailYellow #E9C46A

Format: USDZ, embedded 1K texture (1024 x 1024 colour and normal, constant metallic and roughness), one mesh

Parts: single mesh (sourced, no named parts)

Description: A young maple or plane street tree with a narrower crown, slightly autumn-tinted foliage and a wooden stake with ties.

Prompt: young maple or plane street tree, narrower crown, slightly autumn-tinted foliage, wooden stake with ties, 4 m tall and about 1.4 m wide

Source: Meshy — text-to-image task 01a14b26-abfe-772a-aaee-1fcb27511a24, image-to-3d task 01a14b27-fc56-76a6-9004-db5aba562992, remesh task 01a14b2d-59ae-7063-b276-9c2ef386aec3, meshy-6, 2026-10-17

### self_checkout

Dimensions: 1.0 x 0.5 x 1.6 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3000 triangles

Palette: charcoal #22252B, primary #4A4E57, accentMint #B9C6B0, asphalt #4B4F57, woodLight #C9A27E, priceRailYellow #E9C46A

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, body_left, body_right, screen_left, screen_right, scanner_left, scanner_right, card_terminal_left, card_terminal_right, bagging_shelf_left, bagging_shelf_right, light_pole_left, light_pole_right, beacon_left, beacon_right

Description: A compact dual self-checkout: two upright pedestals on a shared dark base, each with a mint touch screen, a flat scanner on top, a card terminal and a small wooden bagging shelf, with a yellow beacon light on a thin pole at each side.

Prompt: Low-poly flat-shaded pastel diorama model of a compact dual self-checkout: two upright pedestals on a shared dark base, each with a mint touch screen, a flat scanner on top, a card terminal and a small wooden bagging shelf, with a yellow beacon light on a thin pole at each side. Size 1.0 x 0.5 x 1.6 metres, pivot at the bottom centre, front facing +Z, at most 3000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #4A4E57, #B9C6B0, #4B4F57, #C9A27E, #E9C46A), no text, no real-world logos. Export as USDZ.

### alcohol_wall

Dimensions: 2.0 x 0.5 x 2.1 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 6000 triangles

Palette: charcoal #22252B, cream #FAFAF7, tileWhite #F4F4F2, priceRailYellow #E9C46A, primary #4A4E57

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, upright_left, upright_right, back_panel, shelf_0-4, price_rail_0-4, header_sign, bottle rows on every shelf (at least 40 bottle_<shelf>_<facing>)

Description: A tall open bottle wall for wine and spirits: five white shelves with yellow price rails between two dark uprights, rows of coloured bottles on every shelf and a dark grey header sign. Show bottles by colour only, no labels.

Prompt: Low-poly flat-shaded pastel diorama model of a tall open bottle wall for wine and spirits: five white shelves with yellow price rails between two dark uprights, rows of coloured bottles on every shelf and a dark grey header sign. Show bottles by colour only, no labels. Size 2.0 x 0.5 x 2.1 metres, pivot at the bottom centre, front facing +Z, at most 6000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#22252B, #FAFAF7, #F4F4F2, #E9C46A, #4A4E57), no text, no real-world logos. Export as USDZ.

### plum_mark

Dimensions: 1024 x 1024 px

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primary #4A4E57, mintDeep #6E8B74, primaryLight #D9D6CF

Format: logo, SVG plus 1024 px PNG

Parts: mark, leaf, highlight

Description: The shop's logo: a round graphite plum with a mint leaf and a soft light highlight on a transparent background.

Prompt: Flat vector-style artwork, the shop's logo: a round graphite plum with a mint leaf and a soft light highlight on a transparent background. Size 1024 x 1024 px, palette #4A4E57, #6E8B74, #D9D6CF, crisp edges, English text only, no real-world logos.

### storefront_sign

Dimensions: 2048 x 256 px

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primaryDeep #2E1A47, cream #FAFAF7, primary #4A4E57

Format: emissive panel texture

Parts: panel, wordmark, mark

Description: The lit sign above the entrance: the word Plum in cream letters with the plum mark on a deep aubergine panel.

Prompt: Flat vector-style artwork, the lit sign above the entrance: the word Plum in cream letters with the plum mark on a deep aubergine panel. Size 2048 x 256 px, palette #2E1A47, #FAFAF7, #4A4E57, crisp edges, English text only, no real-world logos.

### price_strip

Dimensions: 512 x 64 px, tileable horizontally

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: priceRailYellow #E9C46A, charcoal #22252B

Format: tileable yellow rail texture

Parts: strip, price_blocks, edge

Description: A tileable yellow shelf-edge strip with small black price blocks and a thin darker top edge.

Prompt: Flat vector-style artwork, a tileable yellow shelf-edge strip with small black price blocks and a thin darker top edge. Size 512 x 64 px, tileable horizontally, palette #E9C46A, #22252B, crisp edges, English text only, no real-world logos.

### window_poster_set

Dimensions: 3 posters, 1024 x 1448 px each

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primary #4A4E57, accentMint #B9C6B0, priceRailYellow #E9C46A, cream #FAFAF7

Format: three posters, PNG

Parts: poster_hot_coffee, poster_hungry, poster_open_hours

Description: Three window posters in brand colours with English copy: Hot coffee? / Hungry? / Open 6-23.

Prompt: Flat vector-style artwork, three window posters in brand colours with English copy: Hot coffee? / Hungry? / Open 6-23. Size 3 posters, 1024 x 1448 px each, palette #4A4E57, #B9C6B0, #E9C46A, #FAFAF7, crisp edges, English text only, no real-world logos.

### menu_board_texture

Dimensions: 2048 x 683 px

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primaryDeep #2E1A47, cream #FAFAF7, accentMint #B9C6B0, priceRailYellow #E9C46A, primaryLight #D9D6CF

Format: menu screen image, PNG

Parts: background, six dish tiles, price labels

Description: The hot-food menu screen image in English: six dishes in pastel tiles with prices, on a deep aubergine background.

Prompt: Flat vector-style artwork, the hot-food menu screen image in English: six dishes in pastel tiles with prices, on a deep aubergine background. Size 2048 x 683 px, palette #2E1A47, #FAFAF7, #B9C6B0, #E9C46A, #D9D6CF, crisp edges, English text only, no real-world logos.
