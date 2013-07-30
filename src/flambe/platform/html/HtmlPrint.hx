package flambe.platform.html;

import flambe.display.Texture;
import flambe.platform.BasicPrint;

class HtmlPrint extends BasicPrint
{
	override private function sendToPrinter(tex :Texture, orientation :Orientation)
	{
		trace("Printing");		
	}

	private function get_supported() :Bool {
		return true;
	}


}