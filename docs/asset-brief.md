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

## Palette

| Name | Hex |
|---|---|
| primary | #6B2D8C |
| primaryDeep | #3E1A5C |
| primaryLight | #B58BD6 |
| accentMint | #7EE0B5 |
| mintDeep | #2FA37A |
| cream | #FFF6E5 |
| charcoal | #2B2B33 |
| priceRailYellow | #F7D23E |
| woodLight | #D9B382 |
| tileWhite | #F2F4F5 |
| asphalt | #5A5D66 |
| sidewalk | #C9C6BE |
| grassPastel | #A8D8A0 |
| skyPastel | #BFE3F5 |
| warmLamp | #FFD9A0 |

Use only these colours (and light or dark shades of them).

## Assets

### gondola_shelf

Dimensions: 1.0 x 1.0 x 1.75 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 6000 triangles

Palette: charcoal #2B2B33, primaryDeep #3E1A5C, cream #FFF6E5, tileWhite #F2F4F5, priceRailYellow #F7D23E, primary #6B2D8C

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, upright_left, upright_right, back_panel, slot_row_0-2, shelf_0-3, price_rail_0-3 (yellow strip on every shelf edge), header_sign with category text, product rows on every shelf (at least 16 facings mixing packets, cans and bottles in at least six colours)

Description: A free-standing metal shop shelf, 0.9 m wide, with four shelves, a yellow price strip on each shelf edge and a violet header sign. Rows of varied packets, cans and bottles sit on every shelf.

Prompt: Low-poly flat-shaded pastel diorama model of a free-standing metal shop shelf, 0.9 m wide, with four shelves, a yellow price strip on each shelf edge and a violet header sign. Rows of varied packets, cans and bottles sit on every shelf. Size 1.0 x 1.0 x 1.75 metres, pivot at the bottom centre, front facing +Z, at most 6000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #3E1A5C, #FFF6E5, #F2F4F5, #F7D23E, #6B2D8C), no text, no real-world logos. Export as USDZ.

### wall_shelf

Dimensions: 1.0 x 0.5 x 1.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 5000 triangles

Palette: charcoal #2B2B33, primaryDeep #3E1A5C, cream #FFF6E5, tileWhite #F2F4F5, priceRailYellow #F7D23E, primary #6B2D8C, woodLight #D9B382

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, upright_left, upright_right, back_panel, slot_row_0-2, shelf_0-3, price_rail_0-3, header_sign, wall_rail, product rows (at least 12 facings)

Description: A shallow shelf unit that stands against a wall, with four shelves, yellow price strips and a header sign. It is the single-sided version of the gondola shelf.

Prompt: Low-poly flat-shaded pastel diorama model of a shallow shelf unit that stands against a wall, with four shelves, yellow price strips and a header sign. It is the single-sided version of the gondola shelf. Size 1.0 x 0.5 x 1.9 metres, pivot at the bottom centre, front facing +Z, at most 5000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #3E1A5C, #FFF6E5, #F2F4F5, #F7D23E, #6B2D8C, #D9B382), no text, no real-world logos. Export as USDZ.

### end_cap

Dimensions: 1.0 x 0.5 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3000 triangles

Palette: charcoal #2B2B33, cream #FFF6E5, tileWhite #F2F4F5, priceRailYellow #F7D23E, mintDeep #2FA37A

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, back, shelf_0-2, price_rail_0-2, product rows (at least 4 facings), promo_sign with offer text

Description: A short display stand that closes the end of a shelf run. It has three shelves of promotional goods and a mint promo sign on top.

Prompt: Low-poly flat-shaded pastel diorama model of a short display stand that closes the end of a shelf run. It has three shelves of promotional goods and a mint promo sign on top. Size 1.0 x 0.5 x 1.5 metres, pivot at the bottom centre, front facing +Z, at most 3000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #FFF6E5, #F2F4F5, #F7D23E, #2FA37A), no text, no real-world logos. Export as USDZ.

### wall_fridge

Dimensions: 1.0 x 1.0 x 2.2 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 7000 triangles

Palette: charcoal #2B2B33, primaryDeep #3E1A5C, tileWhite #F2F4F5, skyPastel #BFE3F5, cream #FFF6E5, primary #6B2D8C

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: frame, frame_side_left, frame_side_right, plinth, interior_glow (light panel), shelf_0-3, bottle_<shelf>_<i> (at least 12 bottles behind the glass), door_left, door_right (glass), handle_left, handle_right, header (violet), compressor_vent

Description: A tall drinks cooler with two glass doors and long handles. The inside glows white and shows four shelves of bottles; a violet header sits on top.

Prompt: Low-poly flat-shaded pastel diorama model of a tall drinks cooler with two glass doors and long handles. The inside glows white and shows four shelves of bottles; a violet header sits on top. Size 1.0 x 1.0 x 2.2 metres, pivot at the bottom centre, front facing +Z, at most 7000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #3E1A5C, #F2F4F5, #BFE3F5, #FFF6E5, #6B2D8C), no text, no real-world logos. Export as USDZ.

### dairy_chiller

Dimensions: 1.5 x 1.0 x 1.4 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 5000 triangles

Palette: primaryLight #B58BD6, primaryDeep #3E1A5C, tileWhite #F2F4F5, primary #6B2D8C, cream #FFF6E5

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: body, open_front_lip, glow, shelf_0-2, carton_<shelf>_<i> (at least 8 cartons and tubs), back_riser, riser_text

Description: A low open-front chiller for milk, yoghurt and cheese. Three stepped shelves of cartons rise behind a violet riser.

Prompt: Low-poly flat-shaded pastel diorama model of a low open-front chiller for milk, yoghurt and cheese. Three stepped shelves of cartons rise behind a violet riser. Size 1.5 x 1.0 x 1.4 metres, pivot at the bottom centre, front facing +Z, at most 5000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#B58BD6, #3E1A5C, #F2F4F5, #6B2D8C, #FFF6E5), no text, no real-world logos. Export as USDZ.

### checkout_counter

Dimensions: 2.0 x 1.0 x 1.3 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 5000 triangles

Palette: primary #6B2D8C, woodLight #D9B382, accentMint #7EE0B5, charcoal #2B2B33, mintDeep #2FA37A, cream #FFF6E5, priceRailYellow #F7D23E

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: counter, counter_top, front_stripe, conveyor_belt, till, till_screen, card_terminal, receipt_printer, bag_dispenser, impulse_rack with at least 6 impulse_item_<i> (gum and sweets)

Description: A wood-topped checkout counter with a mint stripe, a till with a glowing screen, a card terminal and a rack of small sweets at the front.

Prompt: Low-poly flat-shaded pastel diorama model of a wood-topped checkout counter with a mint stripe, a till with a glowing screen, a card terminal and a rack of small sweets at the front. Size 2.0 x 1.0 x 1.3 metres, pivot at the bottom centre, front facing +Z, at most 5000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#6B2D8C, #D9B382, #7EE0B5, #2B2B33, #2FA37A, #FFF6E5, #F7D23E), no text, no real-world logos. Export as USDZ.

### cigarette_cabinet

Dimensions: 1.5 x 0.5 x 1.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3500 triangles

Palette: charcoal #2B2B33, skyPastel #BFE3F5, primaryLight #B58BD6, priceRailYellow #F7D23E, warmLamp #FFD9A0

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: cabinet, door_left, door_right (glass), shelf_0-2, lottery_screen, scratchcard_rack

Description: A tall dark cabinet with two glass doors for tobacco and lottery tickets, with a yellow lottery screen and a small rack of scratch cards. Show packs by colour only, no brand text.

Prompt: Low-poly flat-shaded pastel diorama model of a tall dark cabinet with two glass doors for tobacco and lottery tickets, with a yellow lottery screen and a small rack of scratch cards. Show packs by colour only, no brand text. Size 1.5 x 0.5 x 1.9 metres, pivot at the bottom centre, front facing +Z, at most 3500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #BFE3F5, #B58BD6, #F7D23E, #FFD9A0), no text, no real-world logos. Export as USDZ.

### hot_food_counter

Dimensions: 2.5 x 1.0 x 2.1 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 12000 triangles

Palette: primary #6B2D8C, woodLight #D9B382, charcoal #2B2B33, asphalt #5A5D66, primaryLight #B58BD6, skyPastel #BFE3F5, warmLamp #FFD9A0, mintDeep #2FA37A, priceRailYellow #F7D23E, accentMint #7EE0B5, tileWhite #F2F4F5, sidewalk #C9C6BE, cream #FFF6E5

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: counter, counter_top, kick_strip, roller_grill (grill_base, roller_0-5, sausage_0-3), heated_case (case_base, case_glass, case_roof, case_glow, pastry_0-2, baguette_0-1), bun_warmer (warmer_body, warmer_lid), condiment_station (station_tray, pump_0-2, napkin_box), tile_wall with grout lines

Description: A hot-food counter with a roller grill of sausages, a glass heated case with pastries and baguettes, a bun warmer and a condiment station with three pumps, in front of a white tile wall.

Prompt: Low-poly flat-shaded pastel diorama model of a hot-food counter with a roller grill of sausages, a glass heated case with pastries and baguettes, a bun warmer and a condiment station with three pumps, in front of a white tile wall. Size 2.5 x 1.0 x 2.1 metres, pivot at the bottom centre, front facing +Z, at most 12000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#6B2D8C, #D9B382, #2B2B33, #5A5D66, #B58BD6, #BFE3F5, #FFD9A0, #2FA37A, #F7D23E, #7EE0B5, #F2F4F5, #C9C6BE, #FFF6E5), no text, no real-world logos. Export as USDZ.

### coffee_machine

Dimensions: 0.5 x 0.5 x 0.8 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 3000 triangles

Palette: woodLight #D9B382, charcoal #2B2B33, accentMint #7EE0B5, asphalt #5A5D66, cream #FFF6E5

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: stand, body, screen, spout_left, spout_right, drip_tray, cup_stack_0-2

Description: A self-service coffee machine on a small wooden stand, with a mint screen, two spouts, a drip tray and three stacks of cups.

Prompt: Low-poly flat-shaded pastel diorama model of a self-service coffee machine on a small wooden stand, with a mint screen, two spouts, a drip tray and three stacks of cups. Size 0.5 x 0.5 x 0.8 metres, pivot at the bottom centre, front facing +Z, at most 3000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#D9B382, #2B2B33, #7EE0B5, #5A5D66, #FFF6E5), no text, no real-world logos. Export as USDZ.

### menu_screen

Dimensions: 2.5 x 0.1 x 0.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1500 triangles

Palette: charcoal #2B2B33, primaryDeep #3E1A5C, priceRailYellow #F7D23E, accentMint #7EE0B5, primaryLight #B58BD6, warmLamp #FFD9A0, mintDeep #2FA37A, cream #FFF6E5

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: bezel, screen (glowing), menu_tile_0-5 (coloured blocks standing in for dishes), price_dot_0-5

Description: A wide wall-hung menu screen showing six coloured tiles for dishes with a price dot on each. Pastel blocks only; the real menu is a texture, see menu_board_texture.

Prompt: Low-poly flat-shaded pastel diorama model of a wide wall-hung menu screen showing six coloured tiles for dishes with a price dot on each. Pastel blocks only; the real menu is a texture, see menu_board_texture. Size 2.5 x 0.1 x 0.9 metres, pivot at the bottom centre, front facing +Z, at most 1500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #3E1A5C, #F7D23E, #7EE0B5, #B58BD6, #FFD9A0, #2FA37A, #FFF6E5), no text, no real-world logos. Export as USDZ.

### window_ledge

Dimensions: 2.0 x 0.5 x 1.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 800 triangles

Palette: woodLight #D9B382, charcoal #2B2B33

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: ledge_top, support_left, support_right

Description: A light-wood counter ledge along the shop window with two dark steel supports, used for standing or sitting with a coffee.

Prompt: Low-poly flat-shaded pastel diorama model of a light-wood counter ledge along the shop window with two dark steel supports, used for standing or sitting with a coffee. Size 2.0 x 0.5 x 1.0 metres, pivot at the bottom centre, front facing +Z, at most 800 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#D9B382, #2B2B33), no text, no real-world logos. Export as USDZ.

### high_stool

Dimensions: 0.5 x 0.5 x 0.75 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1200 triangles

Palette: charcoal #2B2B33, asphalt #5A5D66, primary #6B2D8C

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base_disc, post, foot_ring, seat

Description: A tall round stool with a violet seat, a thin steel post and a foot ring above a dark base disc.

Prompt: Low-poly flat-shaded pastel diorama model of a tall round stool with a violet seat, a thin steel post and a foot ring above a dark base disc. Size 0.5 x 0.5 x 0.75 metres, pivot at the bottom centre, front facing +Z, at most 1200 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #5A5D66, #6B2D8C), no text, no real-world logos. Export as USDZ.

### basket_stack

Dimensions: 0.5 x 0.5 x 0.6 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 2500 triangles

Palette: charcoal #2B2B33, primary #6B2D8C, accentMint #7EE0B5

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: stand, basket_0-4 (alternating violet and mint)

Description: A stack of five shopping baskets, alternating violet and mint, on a small dark stand.

Prompt: Low-poly flat-shaded pastel diorama model of a stack of five shopping baskets, alternating violet and mint, on a small dark stand. Size 0.5 x 0.5 x 0.6 metres, pivot at the bottom centre, front facing +Z, at most 2500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #6B2D8C, #7EE0B5), no text, no real-world logos. Export as USDZ.

### back_room_door

Dimensions: 1.0 x 0.2 x 2.1 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 800 triangles

Palette: charcoal #2B2B33, woodLight #D9B382, asphalt #5A5D66, primaryDeep #3E1A5C

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: frame, door, push_plate, staff_only_sign

Description: A plain wooden staff door in a dark frame with a steel push plate and a small violet staff-only sign.

Prompt: Low-poly flat-shaded pastel diorama model of a plain wooden staff door in a dark frame with a steel push plate and a small violet staff-only sign. Size 1.0 x 0.2 x 2.1 metres, pivot at the bottom centre, front facing +Z, at most 800 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #D9B382, #5A5D66, #3E1A5C), no text, no real-world logos. Export as USDZ.

### pendant_lamp

Dimensions: 0.4 x 0.4 x 1.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1200 triangles

Palette: charcoal #2B2B33, primary #6B2D8C, warmLamp #FFD9A0

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: cord, shade (violet), bulb (warm glow)

Description: A ceiling pendant lamp: a thin cord, a violet cone shade and a warm glowing bulb underneath.

Prompt: Low-poly flat-shaded pastel diorama model of a ceiling pendant lamp: a thin cord, a violet cone shade and a warm glowing bulb underneath. Size 0.4 x 0.4 x 1.0 metres, pivot at the bottom centre, front facing +Z, at most 1200 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #6B2D8C, #FFD9A0), no text, no real-world logos. Export as USDZ.

### entrance_door

Dimensions: 1.5 x 0.5 x 2.4 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1500 triangles

Palette: charcoal #2B2B33, skyPastel #BFE3F5, cream #FFF6E5, primaryDeep #3E1A5C

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: frame, leaf_left, leaf_right (glass), handle_left, handle_right, mat

Description: A double glass shop door with long handles, a dark top frame and a violet doormat in front.

Prompt: Low-poly flat-shaded pastel diorama model of a double glass shop door with long handles, a dark top frame and a violet doormat in front. Size 1.5 x 0.5 x 2.4 metres, pivot at the bottom centre, front facing +Z, at most 1500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #BFE3F5, #FFF6E5, #3E1A5C), no text, no real-world logos. Export as USDZ.

### window_poster

Dimensions: 0.8 x 0.05 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 300 triangles

Palette: priceRailYellow #F7D23E, accentMint #7EE0B5, primary #6B2D8C

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: poster, headline_block

Description: A poster stuck on the shop window: a pastel sheet with a violet headline block. The artwork itself comes from window_poster_set.

Prompt: Low-poly flat-shaded pastel diorama model of a poster stuck on the shop window: a pastel sheet with a violet headline block. The artwork itself comes from window_poster_set. Size 0.8 x 0.05 x 1.5 metres, pivot at the bottom centre, front facing +Z, at most 300 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#F7D23E, #7EE0B5, #6B2D8C), no text, no real-world logos. Export as USDZ.

### atm_locker

Dimensions: 1.5 x 0.5 x 2.2 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 2500 triangles

Palette: primaryDeep #3E1A5C, accentMint #7EE0B5, asphalt #5A5D66, primary #6B2D8C, primaryLight #B58BD6

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: atm_body, atm_screen, keypad, locker_body, locker_door_0-3

Description: A cash machine with a glowing mint screen next to a parcel locker wall with four doors in alternating violet shades.

Prompt: Low-poly flat-shaded pastel diorama model of a cash machine with a glowing mint screen next to a parcel locker wall with four doors in alternating violet shades. Size 1.5 x 0.5 x 2.2 metres, pivot at the bottom centre, front facing +Z, at most 2500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#3E1A5C, #7EE0B5, #5A5D66, #6B2D8C, #B58BD6), no text, no real-world logos. Export as USDZ.

### a_frame_sign

Dimensions: 0.4 x 0.3 x 0.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 500 triangles

Palette: woodLight #D9B382, charcoal #2B2B33, cream #FFF6E5

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: leg_left, leg_right, board, board_text

Description: A wooden A-frame pavement sign with a dark chalk board and the word Coffee.

Prompt: Low-poly flat-shaded pastel diorama model of a wooden A-frame pavement sign with a dark chalk board and the word Coffee. Size 0.4 x 0.3 x 0.9 metres, pivot at the bottom centre, front facing +Z, at most 500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#D9B382, #2B2B33, #FFF6E5), no text, no real-world logos. Export as USDZ.

### litter_bin

Dimensions: 0.4 x 0.4 x 1.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 900 triangles

Palette: charcoal #2B2B33, mintDeep #2FA37A

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: post, body (mint), lid

Description: A round mint litter bin on a short post with a dark lid.

Prompt: Low-poly flat-shaded pastel diorama model of a round mint litter bin on a short post with a dark lid. Size 0.4 x 0.4 x 1.0 metres, pivot at the bottom centre, front facing +Z, at most 900 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #2FA37A), no text, no real-world logos. Export as USDZ.

### bike_rack

Dimensions: 1.4 x 0.12 x 0.9 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 800 triangles

Palette: asphalt #5A5D66, charcoal #2B2B33

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: base, hoop_0-2 (each with hoop_<i>_post_left, hoop_<i>_post_right, hoop_<i>_bar)

Description: A row of three upside-down U-shaped bike hoops on a flat steel base.

Prompt: Low-poly flat-shaded pastel diorama model of a row of three upside-down U-shaped bike hoops on a flat steel base. Size 1.4 x 0.12 x 0.9 metres, pivot at the bottom centre, front facing +Z, at most 800 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#5A5D66, #2B2B33), no text, no real-world logos. Export as USDZ.

### street_lamp

Dimensions: 0.8 x 0.3 x 4.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 1500 triangles

Palette: charcoal #2B2B33, warmLamp #FFD9A0

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: post, arm, head, glow

Description: A tall dark street lamp with a short arm and a head that glows warm.

Prompt: Low-poly flat-shaded pastel diorama model of a tall dark street lamp with a short arm and a head that glows warm. Size 0.8 x 0.3 x 4.5 metres, pivot at the bottom centre, front facing +Z, at most 1500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#2B2B33, #FFD9A0), no text, no real-world logos. Export as USDZ.

### tree

Dimensions: 1.4 x 1.4 x 4.0 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 2500 triangles

Palette: woodLight #D9B382, grassPastel #A8D8A0

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: trunk, crown, crown_top

Description: A stylised street tree: a short trunk with a rounded block-shaped crown and a smaller rounded block on top, in soft pastel green.

Prompt: Low-poly flat-shaded pastel diorama model of a stylised street tree: a short trunk with a rounded block-shaped crown and a smaller rounded block on top, in soft pastel green. Size 1.4 x 1.4 x 4.0 metres, pivot at the bottom centre, front facing +Z, at most 2500 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#D9B382, #A8D8A0), no text, no real-world logos. Export as USDZ.

### parked_car

Dimensions: 4.5 x 2.0 x 1.5 m (width x depth x height)

Pivot: bottom centre of the footprint, front towards +Z

Poly budget: 6000 triangles

Palette: primaryLight #B58BD6, accentMint #7EE0B5, priceRailYellow #F7D23E, cream #FFF6E5, skyPastel #BFE3F5, charcoal #2B2B33, warmLamp #FFD9A0, primaryDeep #3E1A5C, asphalt #5A5D66

Format: USDZ, embedded textures, one 1024 x 1024 atlas

Parts: body, cabin, windows (glass), wheel_0-3, headlight_left, headlight_right, tail_lights, bumper_front, bumper_rear. Long axis along X, the front of the car points to +X; offer four body colours.

Description: A small friendly hatchback with rounded body and cabin, glass windows, dark wheels and warm headlights. No manufacturer badges or recognisable real model.

Prompt: Low-poly flat-shaded pastel diorama model of a small friendly hatchback with rounded body and cabin, glass windows, dark wheels and warm headlights. No manufacturer badges or recognisable real model. Size 4.5 x 2.0 x 1.5 metres, pivot at the bottom centre, front facing +Z, at most 6000 triangles, one 1024 x 1024 texture atlas, only the Plum palette (#B58BD6, #7EE0B5, #F7D23E, #FFF6E5, #BFE3F5, #2B2B33, #FFD9A0, #3E1A5C, #5A5D66), no text, no real-world logos. Export as USDZ.

### plum_mark

Dimensions: 1024 x 1024 px

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primary #6B2D8C, mintDeep #2FA37A, primaryLight #B58BD6

Format: logo, SVG plus 1024 px PNG

Parts: mark, leaf, highlight

Description: The shop's logo: a round violet plum with a mint leaf and a soft light highlight on a transparent background.

Prompt: Flat vector-style artwork, the shop's logo: a round violet plum with a mint leaf and a soft light highlight on a transparent background. Size 1024 x 1024 px, palette #6B2D8C, #2FA37A, #B58BD6, crisp edges, English text only, no real-world logos.

### storefront_sign

Dimensions: 2048 x 256 px

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primaryDeep #3E1A5C, cream #FFF6E5, primary #6B2D8C

Format: emissive panel texture

Parts: panel, wordmark, mark

Description: The lit sign above the entrance: the word Plum in cream letters with the plum mark on a deep violet panel.

Prompt: Flat vector-style artwork, the lit sign above the entrance: the word Plum in cream letters with the plum mark on a deep violet panel. Size 2048 x 256 px, palette #3E1A5C, #FFF6E5, #6B2D8C, crisp edges, English text only, no real-world logos.

### price_strip

Dimensions: 512 x 64 px, tileable horizontally

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: priceRailYellow #F7D23E, charcoal #2B2B33

Format: tileable yellow rail texture

Parts: strip, price_blocks, edge

Description: A tileable yellow shelf-edge strip with small black price blocks and a thin darker top edge.

Prompt: Flat vector-style artwork, a tileable yellow shelf-edge strip with small black price blocks and a thin darker top edge. Size 512 x 64 px, tileable horizontally, palette #F7D23E, #2B2B33, crisp edges, English text only, no real-world logos.

### window_poster_set

Dimensions: 3 posters, 1024 x 1448 px each

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primary #6B2D8C, accentMint #7EE0B5, priceRailYellow #F7D23E, cream #FFF6E5

Format: three posters, PNG

Parts: poster_hot_coffee, poster_hungry, poster_open_hours

Description: Three window posters in brand colours with English copy: Hot coffee? / Hungry? / Open 6-23.

Prompt: Flat vector-style artwork, three window posters in brand colours with English copy: Hot coffee? / Hungry? / Open 6-23. Size 3 posters, 1024 x 1448 px each, palette #6B2D8C, #7EE0B5, #F7D23E, #FFF6E5, crisp edges, English text only, no real-world logos.

### menu_board_texture

Dimensions: 2048 x 683 px

Pivot: not applicable (flat image), centred

Poly budget: not applicable (texture)

Palette: primaryDeep #3E1A5C, cream #FFF6E5, accentMint #7EE0B5, priceRailYellow #F7D23E, primaryLight #B58BD6

Format: menu screen image, PNG

Parts: background, six dish tiles, price labels

Description: The hot-food menu screen image in English: six dishes in pastel tiles with prices, on a deep violet background.

Prompt: Flat vector-style artwork, the hot-food menu screen image in English: six dishes in pastel tiles with prices, on a deep violet background. Size 2048 x 683 px, palette #3E1A5C, #FFF6E5, #7EE0B5, #F7D23E, #B58BD6, crisp edges, English text only, no real-world logos.
