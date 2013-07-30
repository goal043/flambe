package flambe.platform.flash;

import flambe.display.Orientation;
import flambe.display.Texture;
import flambe.Entity;
import flambe.platform.BasicPrint;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.printing.PrintJobOrientation;
import flash.printing.PrintJob;
import flash.printing.PrintJobOptions;
import haxe.io.Bytes;
import haxe.io.BytesData;

class FlashPrint extends BasicPrint
{
    public function new()
    {}

    // override public function sendPage(e :Entity, orientation :Orientation) :Void
    // {
    //     var bounds :flambe.math.Rectangle = flambe.display.Sprite.getBounds(e);
    //     var bd :BitmapData = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0);

    // }

	override private function sendToPrinter(tex :Texture)
	{
		var bd :BitmapData = new BitmapData(tex.width, tex.height);
		var bit :Bitmap = new Bitmap(bd, PixelSnapping.AUTO, true);
		var pixels :Bytes = tex.readPixels(0, 0, tex.width, tex.height);
        var ii = pixels.length - 1;

        while (ii >= 0) {
            // Convert from RGBA to ARGB
            var alpha = pixels.get(ii);
            pixels.set(ii, pixels.get(--ii));
            pixels.set(ii, pixels.get(--ii));
            pixels.set(ii, pixels.get(--ii));
            pixels.set(ii, alpha);
            --ii;
        }
        
        var pixelData :BytesData = pixels.getData();
        pixelData.position = 0;
        bd.setPixels(bd.rect, pixelData);

        var page :Sprite = new Sprite();
        page.addChild(bit);

        var job :PrintJob = new PrintJob();

        if (job.start()) {
            try {
                job.addPage(page, bd.rect, new PrintJobOptions(false));
            }
            catch(e :Dynamic) {
                trace(e);
            }
            job.send();
        }
        bd.dispose();
	}

	override private function get_supported() :Bool {
		return PrintJob.isSupported;
	}


}