# Latin Garage

A first-person Godot 4.7 game for learning Latin grammar: stems and endings are physical
pieces you fit together and wire up with cables into sentences, and a pixel-art computer
draws what your sentence means.

**Play in the browser:** the HTML5 build lives in `docs/` and is served by GitHub Pages.

- Engine: Godot 4.7.2 (GL Compatibility renderer)
- Re-export the web build: `godot --headless --path . --export-release "Web" docs/index.html`
- Self-test: `godot --path . -- --test`
