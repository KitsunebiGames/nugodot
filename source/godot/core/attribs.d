/**
    Attributes that affect the godot binding process.

    Copyright © 2025, Kitsunebi Games
    Distributed under the BSL 1.0 license, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module godot.core.attribs;
import godot.globals;

/**
    Specifies the name a class should be bound as.
*/
struct class_name { string name; }

/**
    Specifies the icon to use for the type.
*/
struct class_icon { string path; }

/**
    Annotates the name of the symbol that the attribute
    is attached to.
*/
struct gd_name { string name; }

/**
    Allows a class to run in the editor.
*/
struct gd_editor;

/**
    Annotates that the given class member should be hidden from
    Godot.
*/
struct gd_hide;

/**
    Exports a class property to the editor.
*/
struct gd_export;

/**
    Exports a class property to the editor as a multiline string.
*/
struct gd_export_mutliline { string hints; }

/**
    Exports a class property to the editor with a custom
    hint and hint string.
*/
struct gd_export_custom { PropertyHint hint; string hintString; PropertyUsageFlags flags; }

/**
    Marks a class as non-instantiable, telling nugodot not to try
    to generate an extension class for it.
*/
struct gd_non_instantiable;