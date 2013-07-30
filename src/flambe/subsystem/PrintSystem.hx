
package flambe.subsystem;

import flambe.display.Orientation;
import flambe.Entity;

interface PrintSystem 
{

    /**
     * True if the environment allows printing.
     */
    var supported (get, null) :Bool;

    /**
     * Sends a page to the printer.
     */
    public function sendPage(entity :Entity, orientation :Orientation) :Void;

    private function get_supported() :Bool;
}