# dmgbuild settings for dist/Porter.dmg (see scripts/make-dmg.sh). The icon positions match the
# wells drawn by scripts/dmg-background.swift.
import os

app = defines["app"]
name = os.path.basename(app)

volume_name = "Porter for Claude Desktop"
format = "UDZO"
files = [app]
symlinks = {"Applications": "/Applications"}
icon_locations = {name: (180, 200), "Applications": (480, 200)}
background = defines["background"]
window_rect = ((200, 140), (660, 460))
default_view = "icon-view"
show_toolbar = False
show_status_bar = False
show_pathbar = False
show_sidebar = False
show_tab_view = False
icon_size = 128
text_size = 13
hide_extensions = [name]
