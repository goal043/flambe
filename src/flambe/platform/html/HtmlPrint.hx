package flambe.platform.html;

import flambe.display.Orientation;
import flambe.display.Texture;
import flambe.platform.BasicPrint;
import flambe.platform.html.HtmlUtil;
import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.DOMWindow;
import js.html.IFrameElement;
import js.html.ImageData;
import js.html.ImageElement;

class HtmlPrint extends BasicPrint
{
	/** comment */
	public var _printEventsSupported :Bool;

	public function new()
	{}

	override private function sendToPrinter(tex :Texture)
	{
		var canvas :CanvasElement = HtmlUtil.createEmptyCanvas(tex.width, tex.height);
		var ctx :CanvasRenderingContext2D = canvas.getContext2d();
		var pixels :Bytes = tex.readPixels(0, 0, tex.width, tex.height);
		var canvasData :ImageData = ctx.createImageData(tex.width, tex.height);
		canvasData.data.set(pixels.getData());
		ctx.putImageData(canvasData, 0, 0);

		// Create the dynamic image to put in an iframe and print.
		var image :ImageElement = js.Browser.document.createImageElement();
		image.style.width = "100%"; // Automatically size to the width of the page.
		image.src = canvas.toDataURL();

		var iframe :IFrameElement = js.Browser.document.createIFrameElement();
		iframe.frameBorder = "none";
		iframe.style.visibility = "hidden";
		js.Browser.window.document.body.appendChild(iframe);

		// var w :DOMWindow = js.Browser.window.open("about:blank","printable");
		var w :DOMWindow = iframe.contentWindow;
		w.document.open();
		w.document.write("<!DOCTYPE html>");
		w.document.write("<html><head><title>Printable</title></head><body></body></html>");
		w.document.close();
		
		image.onload = function (e) {
			
			iframe.contentWindow.print();

			// Works reliably on firefox and chrome.
			HtmlUtil.callLater(function() {
				if (iframe.parentNode != null) {
					iframe.parentNode.removeChild(iframe);
				}
			},1000);
		}

		w.document.body.appendChild(image);
	}

	override private function get_supported() :Bool {
		return true;
	}


}