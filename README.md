# Enemylist — standalone test addon

Load with `//lua load Enemylist`. Unload with `//lua unload Enemylist`.
Actor is not required or modified. If Actor is running, disable its Enemies view in Theatre to avoid duplicate displays.

This is a copied Actor enemy-list renderer with its UI assets and an independent tracker.
It tracks targetable nearby monsters within 50 yalms, including unclaimed enemies, and observes combat involving your party/alliance.
Names and HP percentages come from Windower's live mob data. Enemies beyond 50 yalms or despawned are removed; defeated entries linger five seconds.

Commands: `//enemylist show`, `hide`, `toggle`, `clear`, `style` (also `//elist`).
Right-drag moves the view; middle-click toggles the background; double-click opens its own style editor.
Styles and saved positions belong to Enemylist, not Actor. No item use, movement, or combat automation is included.

Test limitations: this does not include Actor's complete combat model. It shows observed successful spell debuffs and skillchain results, not effects applied before loading or every buff/debuff source. No predicted skillchain openings or exact HP totals. Reload after switching characters. Use the game as authoritative for effect expiry.
