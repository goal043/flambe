package flambe.platform;

import flambe.display.Orientation;
import flambe.display.Sprite;
import flambe.display.Texture;
import flambe.Entity;
import flambe.subsystem.PrintSystem;
import flambe.util.Assert;
import flash.printing.PrintJob;

class BasicPrint implements PrintSystem
{
	/**  */
	public var supported(get, null) :Bool;


    public function sendPage(entity :Entity, orientation :Orientation) :Void
	{
		// if (Assert.that(this.supported, "Printing is not supported on this platform.")) {
		if (supported) {

			var width :Int = orientation == Orientation.Portrait ? 612 : 792; 
			var height :Int = orientation == Orientation.Portrait ? 792 : 612;
			width = width > System.stage.width ? System.stage.width : width;
			height = height > System.stage.height ? System.stage.height : height;
			
			var tex :Texture = System.createTexture(width, height);
			Sprite.render(entity, tex.graphics);
			sendToPrinter(tex, orientation);
		}
	}

	private function sendToPrinter(tex :Texture, orientation :Orientation)
	{
		throw "Must subclass the BasicPrint class.";
	}

	private function get_supported() :Bool {
		throw "Must subclass the BasicPrint class.";
		return false;
	}


}