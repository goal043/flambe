package flambe.platform;

import flambe.display.Orientation;
import flambe.display.Sprite;
import flambe.display.Texture;
import flambe.Entity;
import flambe.subsystem.PrintSystem;
import flambe.util.Assert;

class BasicPrint implements PrintSystem
{
	/**  */
	public var supported(get, null) :Bool;


    public function sendPage(entity :Entity, orientation :Orientation) :Void
	{
		if (supported) {

			var width :Int = (orientation == Orientation.Portrait ? 612 : 792) * 2; 
			var height :Int = (orientation == Orientation.Portrait ? 792 : 612) * 2;
			var nStartScaleX :Float = 1;
			var nStartScaleY :Float = 1;
			var s :Sprite = entity.get(Sprite);

			var removeSprite :Bool = s == null;
			if (removeSprite) {
				s = new Sprite();
				entity.add(s);
			}

			var bounds :flambe.math.Rectangle = Sprite.getBounds(entity);
			var newScale :Float = Math.min(width / bounds.width, height / bounds.height);
			s.setScale( newScale ); // We're going to set the scale to fit within the printable area.
			var tex :Texture = System.createTexture(width, height);
			Sprite.render(entity, tex.graphics);

			s.setScaleXY(nStartScaleX, nStartScaleY);

			if (removeSprite) {
				s.dispose();
			}

			sendToPrinter(tex);
			
			tex = System.createTexture(1, 1);
			Sprite.render(System.root, tex.graphics); // Restores the context back to the regular system.

		} else {
			Assert.fail("Printing not supported on this platform. Check it with System.print.supported");
		}
	}

	private function sendToPrinter(tex :Texture)
	{
		throw "Must subclass the BasicPrint class.";
	}

	private function get_supported() :Bool {
		throw "Must subclass the BasicPrint class.";
		return false;
	}


}