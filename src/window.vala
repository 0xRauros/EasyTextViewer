/* window.vala
 *
 * Copyright 2022 0xrauros
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace TextViewer { // Instance structure of the Text View Window
    [GtkTemplate (ui = "/com/example/TextViewer/window.ui")]
    public class Window : Gtk.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.TextView main_text_view;

        [GtkChild]
        private unowned Gtk.Button open_button;

        public Window (Gtk.Application app) {
            Object (application: app);
        }

        construct {
            var open_action = new SimpleAction ("open", null);
            open_action.activate.connect (this.open_file_dialog);
            this.add_action (open_action);
        }

        private void open_file_dialog (Variant? parameter) {
            // Create a new file selection dialog, using the "open" mode
            // and keep a reference to it
            var filechooser = new Gtk.FileChooserNative ("Open File", null, Gtk.FileChooserAction.OPEN, "_Open", "_Cancel") {
                transient_for = this
            };
            filechooser.response.connect ((dialog, response) => {
                // If the user selected a file...
                if (response == Gtk.ResponseType.ACCEPT) {
                    // ... retrieve the location from the dialog and open it
                    this.open_file (filechooser.get_file ());
                }
            });
            filechooser.show ();
        }

        private void open_file (File file) {
                    // Reading the content of a file can take long and block the control flow.
            // That's why we read it asynchronously.
            file.load_contents_async.begin (null, (object, result) => {

                string display_name;
                // QUery the display name for the file
                try {
                    FileInfo? info = file.query_info ("standard::displayname", FileQueryInfoFlags.NONE);
                    display_name = info.get_attribute_string ("standard::displayname");
                } catch (Error e) {
                    display_name = file.get_basename ();
                }


                uint8[] contents;
                try {
                    // Complete the asynchronous operation; this function will either
                    // give you the contents of the file as a byte array, or will
                    // raise an exception
                    file.load_contents_async.end (result, out contents, null);
                } catch (Error e) {
                    // In case of an error, print a warning to the standard error output
                    stderr.printf ("Unable to open “%s“: %s", file.peek_path (), e.message);
                }

                // Ensure that the file is encoded with UTF-8
                if (!((string) contents).validate ())
                    stderr.printf ("Unable to load the contents of “%s”: "+
                                   "the file is not encoded with UTF-8\n",
                                   file.peek_path ());

                // Retrieve the GtkTextBuffer instance that stores the
                // text displayed by the GtkTextView widget
                Gtk.TextBuffer buffer = this.main_text_view.buffer;

                // Set the text using the contents of the file
                buffer.text = (string) contents;

                // Reposition the cursor so it's at the start of the text
                Gtk.TextIter start;
                buffer.get_start_iter (out start);
                buffer.place_cursor (start);

                // Set the title using the display name
                this.title = display_name;


            });
        }

    }
}
