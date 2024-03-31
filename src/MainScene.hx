package;

import ceramic.PersistentData;
import ceramic.Scene;
import ceramic.KeyBindings;
import ceramic.KeyCode;
import haxe.ui.core.Screen;

class MainScene extends Scene {
	public var gui: ui.Index;
	public var store: PersistentData;

	/*
	 * Add any assets you want to load here
	 */
	override function preload() {
		assets.add(Fonts.FONTS__ROBOTO_REGULAR);
		// MODES
		assets.add(Images.ICONS__PLACE_MODE);
		assets.add(Images.ICONS__EDIT_MODE);
		assets.add(Images.ICONS__UNIT_MODE);
		assets.add(Images.ICONS__LEGEND_MODE);
		assets.add(Images.ICONS__KEYBOARD_MODE);
		assets.add(Images.ICONS__COLOR_MODE);
		// MISC ICONS
		assets.add(Images.ICONS__KEBAB_DROPDOWN);
		assets.add(Images.ICONS__UNDO);
		assets.add(Images.ICONS__REDO);
		assets.add(Images.ICONS__COPY);
		assets.add(Images.ICONS__CUT);
		assets.add(Images.ICONS__PASTE);
		assets.add(Images.HEADER);
		// JSON
		assets.add(Texts.NUMPAD);
		assets.add(Texts.ALLPAD);
	}

	/*
	 * Called when scene has finished preloading
	 */
	override function create() {
		// Grab the stored projects
		this.store = new ceramic.PersistentData("keyboard");

		// Initialize global variables
		this.gui = new ui.Index();
		this.gui.mainScene = this;

		// Render keys
		// TODO abandon this and make welcome screen work eventually
		openViewport(keyson.Keyson.parse(assets.text(Texts.NUMPAD)));
		openViewport(keyson.Keyson.parse(assets.text(Texts.ALLPAD)));

		// Add stored projects to list
		for (key in store.keys()) {
			// gui.welcome.findComponent("project-list").addComponent(new ui.Project(key));
		}

		// TODO: can we make picking "New" uncover the welcome screen even on a running session?
		// TODO: inhibit all worksurface actions for the while GUI is displayed
		Screen.instance.addComponent(gui);
		// Screen.instance.addComponent(gui.overlay);

		// KEYBINDINGS!
		var keyBindings = new KeyBindings();

		// Saving
		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_S)], () -> {
			save((cast gui.tabs.selectedPage: ui.ViewportContainer).display.keyson, store);
		});
		// TODO save all with SHIFT

		// Downloading
		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_D)], () -> {
			download((cast gui.tabs.selectedPage: ui.ViewportContainer).display.keyson);
		});
		// TODO download all with SHIFT

		// TODO close current tab
		// keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_W)], () -> {

		// TODO close all tabs
		// keyBindings.bind([SHIFT, CMD_OR_CTRL, KEY(KeyCode.KEY_W)], () -> {

		// Toggle overlay (i.e welcome screen)
		// gui.workSurface.display.paused = true;
		keyBindings.bind([KEY(KeyCode.TAB)], () -> {
			// gui.workSurface.display.paused = !gui.workSurface.display.paused;
			// gui.overlay.hidden = !gui.overlay.hidden;
		});

		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_Z)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.queue.undo();
		});
		/*// TODO make undoAll()
			keyBindings.bind([SHIFT, CMD_OR_CTRL, KEY(KeyCode.KEY_Z)], () -> {
				(cast gui.tabs.selectedPage: ui.ViewportContainer).display.queue.undoAll();
			});
		 */
		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_Y)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.queue.redo();
		});
		/*//TODO make redoAll
			keyBindings.bind([SHIFT, CMD_OR_CTRL, KEY(KeyCode.KEY_Y)], () -> {
				(cast gui.tabs.selectedPage: ui.ViewportContainer).display.queue.redoAll();
			});
		 */
		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_R)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.refreshKeycapSet();
		});

		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_A)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.selectEverything();
		});
		// TODO make shift+Ctrl+A bound here:
		keyBindings.bind([SHIFT, CMD_OR_CTRL, KEY(KeyCode.KEY_A)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.clearSelection(true);
		});

		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_C)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.copy();
		});

		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_X)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.cut();
		});

		keyBindings.bind([CMD_OR_CTRL, KEY(KeyCode.KEY_V)], () -> {
			(cast gui.tabs.selectedPage: ui.ViewportContainer).display.paste();
		});
	}

	public function download(keyboard: keyson.Keyson) {
		FileDialog.download(haxe.Json.stringify(keyboard, "\t"), keyboard.name, "application/json");
		StatusBar.inform("Download has been sent");
	}

	public function save(keyboard: keyson.Keyson, store: ceramic.PersistentData) {
		/*
		 * TODO: Compress using hxPako or similar - logo
		 * fire-h0und section:
		 * (if we compress the files we gain little but lose some of the simplicity when parsing our files)
		 * ((modern OSes have transparent compression options that makes even those small gains mooth))
		 * TODO: where we save (dialog) to lacal or remote storage?
		 */
		store.set(Std.string(keyboard.name), keyboard);
		store.save();
		StatusBar.inform("Project has been saved");
	}

	public function openViewport(keyboard: keyson.Keyson) {
		var viewport = new viewport.Viewport();
		viewport.keyson = keyboard;
		viewport.indexGui = gui;

		var container = new ui.ViewportContainer();
		container.styleString = "width: 100%; height: 100%; background-color: #282828;";
		container.text = keyboard.name;
		container.display = viewport;

		gui.tabs.addComponent(container);
		gui.tabs.selectedPage = container;

		var sidebars = new ui.SidebarCollection();
		sidebars.colorSidebar.viewport = viewport;
		sidebars.editSidebar.viewport = viewport;
		sidebars.modeSelector.mainScene = this;
		gui.sidebarsStack.addComponent(sidebars);
	}
}
