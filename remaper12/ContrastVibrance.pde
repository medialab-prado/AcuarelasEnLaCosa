

import processing.core.PApplet;
import processing.core.PGraphics;
import processing.opengl.PShader;

public class ContrastVibrance {

  PShader shader;

  PGraphics target;

  float vibrance = 0f;
  float contrast = 1f;
  

  /*
   * (non-Javadoc)
   * 
   * @see RenderPass#init(PostP5Manager)
   */
  
  public void init(PApplet parent) {

    shader = parent.loadShader("saturationVibranceFrag.glsl");
    target = parent.createGraphics(640,480,P2D);

  }

  /*
   * (non-Javadoc)
   * 
   * @see RenderPass#process(processing.core.PGraphics,
   * processing.core.PGraphics)
   */

  public PImage process(PImage src) {

    shader.set("vibrance", data.brightness);
    shader.set("saturation", data.contrast);
    // 3. Draw destination buffer
    target.beginDraw();
    target.shader(shader);
    target.image(src, 0, 0);
    target.endDraw();
    return target;

  }
  
  public void setVibrance(float t){
    this.vibrance = t;
  }

  /*
   * (non-Javadoc)
   * 
   * @see RenderPass#needDepth()
   */
  public boolean needDepth() {
    return true;
  }

  public void setContrast(float f) {
    contrast = f;
  }
}