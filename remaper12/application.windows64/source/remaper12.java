import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.video.*; 
import java.util.ArrayList; 
import java.util.List; 
import deadpixel.keystone.remaper.CornerPinSurface; 
import deadpixel.keystone.remaper.Keystone; 
import deadpixel.keystone.remaper.MeshPoint; 
import processing.core.PApplet; 
import processing.core.PGraphics; 
import org.mlp.cosa.Cell; 
import org.mlp.cosa.Cosa; 
import org.mlp.cosa.Point; 
import org.mlp.cosa.Panel; 
import org.mlp.cosa.Panels; 
import java.util.*; 
import controlP5.*; 
import processing.core.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class remaper12 extends PApplet {

/**
 * This is a simple example of how to use the Keystone library.
 *
 * To use this example in the real world, you need a projector
 * and a surface you want to p+roject your Processing sketch onto.
 *
 * Simply drag the corners of the CornerPinSurface so that they
 * match the physical surface's corners. The result will be an
 * undistorted projection, regardless of projector position or 
 * orientation.
 *
 * You can also create more than one Surface object, and project
 * onto multiple flat surfaces using a single projector.
 *
 * This extra flexbility can comes at the sacrifice of more or 1
 * less pixel resolution, depending on your projector and how
 * many surfaces you want to map. 
 */



//CAMARA INICIO 




//import ipcapture.*;















Capture cam;
//IPCapture cam;
PImage previo;
PImage finalisimo;
PImage bg;
Keystone ks;
Keystone ksTarget;

QuadGrid qgrid;


List<CornerPinSurface> surfaces;
List<CornerPinSurface> surfacesTarget;

// CornerPinSurface selected = null;

int SURFACE_X = 300;
int SURFACE_Y = 300;

PGraphics offscreen;
PGraphics offscreenOrigin;
PGraphics offscreentarget;

int MODE_CONFIG = 0;
int MODE_PINTANDO = 1;
int MODE_REPOSO = 2;
int MODE_REPOSO_TEST = 3;

int mode = MODE_CONFIG;

int timeout = 0;
int TIMEOUT_TIME = 60 * 1000; //60 segundos

//controld e brillo
BrightnessContrastController bc;

//FILTR DE VIDEO
int numPixels;
int[] previousFrame;

int movementSum = 0;
float lastMovementSum = 0;
float smoothMovement = 0;

//REPOSO
Cosa cosa;
CosaRender render;
Cell lastCell;
List<Particula> particulas;
List<PVector> vertices;

//GUI
ControlP5 cp5;

Data data;

public void setup() {

  

  data = new Data();
  // Keystone will only BrightnessContrastController with P3D or OPENGL renderers,
  // since it relies on texture mapping to deform
  bc=new BrightnessContrastController();

  numPixels = 640*480;
  //CAMARA INICIO
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i, cameras[i]);
    }
  }      

  cam = new Capture(this, cameras[1]);
  //cam.start();     
  // cam = new IPCapture(this, "http://192.168.3.81:8080/?action=stream", "", "");
  cam.start();

  //PLANTILLA FINAL
  bg = loadImage("paneles.jpg");

  ks = new Keystone(this);
  ksTarget = new Keystone(this);
  surfaces = new ArrayList<CornerPinSurface>();
  surfacesTarget = new ArrayList<CornerPinSurface>();

  ks.startCalibration();
  ksTarget.stopCalibration();

  offscreen = createGraphics(SURFACE_X, SURFACE_Y, P3D);
  offscreenOrigin = createGraphics(1024, 768, P3D);
  offscreentarget = createGraphics(1024, 768, P3D);

  qgrid = new QuadGrid(offscreenOrigin, 10, 10);

  previousFrame = new int[640*480];
  finalisimo = createImage(640, 480, RGB);

  //estado de reposo
  cosa = new Cosa();
  File pathP = sketchFile("paneles.txt");
  File pathC = sketchFile("CoordCeldas.txt");
  cosa.init(pathP, pathC);

  render = new CosaRender();
  particulas = new ArrayList();

  initGUI();
}


public void draw() {

  background(bg);


  //CAMARA INICIO
  if (cam.available()) {
    // cam.read();
    //   }
    //  offscreenOrigin.image(cam, 0, 0);
    //if (cam.isAvailable()) {
    //ACTUALIZAMOS CAMARA SI ES POSIBLE
    cam.read();
    cam.loadPixels();
    bc.destructiveShift(cam, 0, data.contrast);

    frameDif(cam);
    bc.destructiveShift(finalisimo, (int)data.brightness, 1);
    //PINTAMOS LA IMAGEN EN EL CANVAS DE ORIGEN
    offscreenOrigin.beginDraw();
    offscreenOrigin.image(finalisimo, 0, 0, 1024, 768);
    offscreenOrigin.endDraw();
  } 


  boolean isMoving = false;
  float vx = smoothMovement/10000;
  if (vx > data.threshold) {
    isMoving = true;
  } 

  int i = 0;
  if (mode == MODE_CONFIG) {

    //IMPORTANTE meter dentro imagen la variable cam que es como se llama la capturacion de pantalla      

    image(finalisimo, 0, 0, 1024, 768);
    // image(finalisimo, 0, 0, 1024*0.2, 768*0.2);
    for (CornerPinSurface surface : surfaces) {

      // render the scene, transformed using the corner pin surface
      surface.render(offscreen);
      // Draw the scene, offscreen
      offscreen.beginDraw();
      offscreen.background(255, 0);
      offscreen.text("" + i, offscreen.width / 2, offscreen.height / 2);
      // offscreen.fill(0, 255, 0);
      // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
      offscreen.endDraw();
      i++;
    }
  } else if (mode == MODE_PINTANDO) {
    noStroke();
    for (int ii = 0; ii<surfaces.size(); ii++) {
      CornerPinSurface surfaceTarget = surfacesTarget.get(ii);

      offscreen.beginDraw();
      offscreen.background(0);
      //offscreen.text("" + i, offscreen.width / 2, offscreen.height / 2);
      // offscreen.fill(0, 255, 0);
      qgrid.drawGrid(offscreen, finalisimo);

      // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
      offscreen.endShape();
      offscreen.endDraw();
      surfaceTarget.render(offscreen);
      if (millis()>timeout) {
        mode = MODE_REPOSO;
      }
    }

    //QUI METEMOS EL TIMEOUT SI ESTAMOS PINTANDO Y NOHAY MOVIMIENTO
  } else if (mode == MODE_REPOSO || mode == MODE_REPOSO_TEST) {
    noStroke();
    drawReposo();
    if (isMoving && mode != MODE_REPOSO_TEST) {
      mode = MODE_PINTANDO;
    }
    //MODO REPOSO
  } else {
    //entramos en error

    println("ERROR ESTAMOS EN UN ESTADO INCORRECTO "+mode);
  }


  text("movement"+(smoothMovement/10000), 10, 10);
  //si detectamos una variaci\u00f3n en la cantidad de movimiento de m\u00e1s de x
  //pasamos al estado de juego
  if (isMoving) {
    fill(0, 255, 0);
    timeout = millis() + TIMEOUT_TIME;
  } else {
    fill(255, 0, 0);
  }
  rect(100, 10, (smoothMovement/10000), 10);
  fill(255);
  text("particulas"+particulas.size()+"\n fps: "+ frameRate, 10, 30);
  
  text(""+data.smooth,250, 80);
}

public void frameDif(PImage video) {
  //video.loadPixels(); // Make its pixels[] array available
  finalisimo.loadPixels();
  // Amount of movement in the frame
  
  lastMovementSum = movementSum;
  movementSum = 0;
  for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
    int currColor = video.pixels[i];
    int prevColor = previousFrame[i];
    // Extract the red, green, and blue components from current pixel
    int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
    int currG = (currColor >> 8) & 0xFF;
    int currB = currColor & 0xFF;
    // Extract red, green, and blue components from previous pixel
    int prevR = (prevColor >> 16) & 0xFF;
    int prevG = (prevColor >> 8) & 0xFF;
    int prevB = prevColor & 0xFF;
    // Compute the difference of the red, green, and blue values
    int diffR = abs(currR - prevR);
    int diffG = abs(currG - prevG);
    int diffB = abs(currB - prevB);

    float finalR = red(finalisimo.pixels[i]);
    float finalG = green(finalisimo.pixels[i]);
    float finalB = blue(finalisimo.pixels[i]);


    finalR = finalR + (currR - finalR)*data.smooth;
    finalG = finalG + (currG - finalG)*data.smooth;
    finalB = finalB + (currB - finalB)*data.smooth;

    //  finalR= 255;
    //  finalG = currG;
    //  finalB = currB;
    // Add these differences to the running tally
    movementSum += diffR + diffG + diffB;
    // Render the difference image to the screen
    finalisimo.pixels[i] = color(finalR, finalG, finalB);
    // The following line is much faster, but more confusing to read
    //pixels[i] = 0xff000000 | (diffR << 16) | (diffG << 8) | diffB;
    // Save the current color into the 'previous' buffer
    previousFrame[i] = currColor;
  }

  finalisimo.updatePixels();
  
  smoothMovement = smoothMovement +(movementSum-smoothMovement)*0.1f;
}

public void addSurface() {

  CornerPinSurface cornerPinSurface = ks.createCornerPinSurface(SURFACE_X, SURFACE_Y, 10);
  cornerPinSurface.setGridColor(color(255, 0, 0));
  surfaces.add(cornerPinSurface);

  CornerPinSurface cornerPinSurface2 = ksTarget.createCornerPinSurface(SURFACE_X, SURFACE_Y, 10);
  cornerPinSurface2.setGridColor(color(255, 0, 0));
  cornerPinSurface2.x = 100;
  surfacesTarget.add(cornerPinSurface2);
}

public void mousePressed(){
   println(mousePressed);
   int maxParticles= 15;
   int countparticles = 0;
    for (Panel p : cosa.getPanels()) {
      if (p.getCells() != null)
        for (Cell cell : p.getCells()) {
          for (int i =0; i<cell.polygon.size(); i++) {
            Point point = cell.polygon.get(i);
            PVector vp = new PVector(point.x, point.y);
            if (PVector.dist(vp, new PVector(mouseX, mouseY)) < 5 && countparticles < maxParticles) {
              countparticles++;
              //a\u00f1adimos nueva part\u00edcula
              println(frameCount+"\u00f1adimos nueva part\u00edcula");
              addParticulas(cell, point, i,0);
            }
          }
        }
    }
}

public void keyPressed() {
  switch (key) {
  case 'c':
    // enter/leave calibration mode, where surfaces can be warped
    // and moved
    ks.toggleCalibration();
    ksTarget.toggleCalibration();
    break;

  case 'l':
    // loads the saved layout

    XML xml = loadXML("origin.xml");
    println("xkml"+xml.getChildCount());
    XML[] children = xml.getChildren();
    int count = 0;
    for (int i = 0; i < children.length; i++) {
      if (children[i].getName().equals("surface")) {
        count++;
      }
    }

    if (surfacesTarget.size()<count)
      for (int i = surfacesTarget.size(); i<count; i++) {
        addSurface();
      }

    ks.load("origin.xml");
    ksTarget.load("target.xml");
    break;

  case 's':
    // saves the layout
    ks.save("origin.xml");
    ksTarget.save("target.xml");
    break;
  case 'm':
    // saves the layout

    if (mode == MODE_CONFIG) {
      mode = MODE_PINTANDO;
      ks.stopCalibration();
      ksTarget.startCalibration();
    } else if (mode == MODE_PINTANDO) {
      mode = MODE_REPOSO;
      ksTarget.stopCalibration();
      ks.startCalibration();
    } else if (mode == MODE_REPOSO) {
      mode = MODE_CONFIG;
      ksTarget.stopCalibration();
      ks.startCalibration();
    }

    break;
  case '+':
    // saves the layout
    addSurface();
    break;
  case '-':
    // saves the layout
    //  ks.save();
    break;
  }
}

/*
Copyright (c) 2014 Ale Gonz\u00e1lez

This software is free; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License version 2.1 as published by the Free Software Foundation.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA
*/

/**
 * BrightnessContrastController
 *
 * Shifts the global brightness and contrast of an image.
 *
 * Ported from Gimp's implementation, as explained by Pippin here:
 * http://pippin.gimp.org/image_processing/chap_point.html 
 * The following excerpts are from that--excellent btw--documentation:
 * "Changing the contrast of an image, changes the range of luminance values present. 
 *  Visualized in the histogram it is equivalent to expanding or compressing the histogram around the midpoint value. 
 *  Mathematically it is expressed as:
 *    new_value = (old_value - 0.5) \u00d7 contrast + 0.5
 *  It is common to bundle brightness and control in a single operations, the mathematical formula then becomes:
 *   new_value = (old_value - 0.5) \u00d7 contrast + 0.5 + brightness
 * The subtraction and addition of 0.5 is to center the expansion/compression of the range around 50% gray." 
 *
 * @author ale
 * @version 1.0
 */

class BrightnessContrastController
{        
    /**
    * Shifts brightness and contrast in the given image. Keeps alpha of the source pixels.
    * 
    * @param img
    *            Image to be adjusted.
    * @param brightness
    *            Value of the brightness adjustment. Integer in a range from -255 (all pixels to black) to 255 (all pixels to white). 0 causes no effect.
    * @param contrast
    *            Value of the contrast adjustment. Its range starts in 1f (no effect). Values over 1f increase contrast and below that value decrease contrast. Negative values will invert the image.
    */  
    public void destructiveShift(PImage img, int brightness, float contrast)
    {
        img.loadPixels();
        int l = img.pixels.length;
        
        //Variables to hold single pixel color and its components 
        int c = 0;
        int a = 0;
        int r = 0;
        int g = 0;
        int b = 0;
        
        for(int i = 0; i < l; i++)
        {
            c = img.pixels[i];
            a = c >> 24 & 0xFF;
            r = adjustedComponent(c >> 16 & 0xFF, brightness, contrast);
            g = adjustedComponent(c >> 8  & 0xFF, brightness, contrast);
            b = adjustedComponent(c       & 0xFF, brightness, contrast);
            img.pixels[i] = a << 24 | r << 16 | g << 8 | b;
        }
        img.updatePixels(); 
    }
  
    /**
    * Shifts brightness in the given image. Keeps alpha of the source pixels.
    * 
    * @param img
    *            Image to be adjusted.
    * @param brightness
    *            Value of the brightness adjustment. Integer in a range from -255 (all pixels to black) to 255 (all pixels to white). 0 causes no effect.
    */
    public void destructiveShift(PImage img, int brightness)
    {
        destructiveShift(img, brightness, 1.0f);  
    }
    
    /**
    * Shifts contrast in the given image. Keeps alpha of the source pixels.
    * 
    * @param img
    *            Image to be adjusted.
    * @param contrast
    *            Value of the contrast adjustment. Its range starts in 1f (no effect). Values over 1f increase contrast and below that value decrease contrast. Negative values will invert the image.
    */
    public void destructiveShift(PImage img, float contrast)
    {
        destructiveShift(img, 0, contrast);  
    }
  
    /**
    * Shifts brightness and contrast in a defensive copy of the given image. Keeps alpha of the source pixels.
    * 
    * @param img
    *            Source image.
    * @param brightness
    *            Value of the brightness adjustment. Integer in a range from -255 (all pixels to black) to 255 (all pixels to white). 0 causes no effect.
    * @param contrast
    *            Value of the contrast adjustment. Its range starts in 1f (no effect). Values over 1f increase contrast and below that value decrease contrast. Negative values will invert the image.
    * @return An adjusted defensive copy of the given image.
    */
    public PImage nondestructiveShift(PImage img, PImage out,int brightness, float contrast)
    {
        
        img.loadPixels();
        out.loadPixels();
        int l = img.pixels.length;
        
        //Variables to hold single pixel color and its components 
        int c = 0;
        int a = 0;
        int r = 0;
        int g = 0;
        int b = 0;
        
        for(int i = 0; i < l; i++)
        {
            c = img.pixels[i];
            a = c >> 24 & 0xFF;
            r = adjustedComponent(c >> 16 & 0xFF, brightness, contrast);
            g = adjustedComponent(c >> 8  & 0xFF, brightness, contrast);
            b = adjustedComponent(c       & 0xFF, brightness, contrast);
            out.pixels[i] = a << 24 | r << 16 | g << 8 | b;
        }
        out.updatePixels();
        return out;  
    }  
    
    /*
    * Shifts brightness in a defensive copy of the given image. Keeps alpha of the source pixels.
    * 
    * @param img
    *            Image to be adjusted.
    * @param brightness
    *            Value of the brightness adjustment. Integer in a range from -255 (all pixels to black) to 255 (all pixels to white). 0 causes no effect.
    */ 
  
        
    /**
    * Calculates the transformation of a single color component.
    * 
    * @param component
    *            Integer value of the component in a range 0-255.
    * @param brightness
    *            Value of the brightness adjustment. Integer in a range from -255 (all pixels to black) to 255 (all pixels to white). 0 causes no effect.
    * @param contrast
    *            Value of the contrast adjustment. Its range starts in 1f (no effect). Values over 1f increase contrast and below that value decrease contrast. Negative values will invert the image.
    * @return The adjusted value of the component, constrained in its natural range 0-255.
    */
    private int adjustedComponent(int component, int brightness, float contrast)
    {
        component = PApplet.parseInt((component - 128) * contrast) + 128 + brightness;
        return component < 0 ? 0 : component > 255 ? 255 : component;  
    }  
}
class Particula {

  PVector pos;
  PVector end;
  PVector move;
  int c;
  int maxLife = 1024*5;
  int life;
  boolean aniadidas = false;

  public void init(PVector pos, PVector end, PVector move, int c) {
    this.pos = pos;
    this.move = move;
    this.end =  end;
    this.c = c;
    life = 0;
  }

  public boolean move() {

    pos.add(move);

    List<Point> vecinos = new ArrayList();

    for (Panel p : cosa.getPanels()) {

      if (p.getCells() != null) {
       // int size = 50 / p.getCells().s;  
        for (Cell cell : p.getCells()) {
          for (int i =0; i<cell.polygon.size(); i++) {
            Point point = cell.polygon.get(i);
            PVector vp = new PVector(point.x, point.y);
            if (PVector.dist(vp, new PVector(pos.x, pos.y)) < 5) {
              //a\u00f1adimos nueva part\u00edcula
              if (!aniadidas) {
                addParticulas(cell, point, i, life);
                aniadidas = true;
                return true;
              }else{
                
              }
            }
          }
        }
      }
    }

    boolean death = false;
    life++;
    if (life > maxLife) {
      //  println(frameCount+"muerte por viejo aniadidas"+aniadidas);
      death = true;
    }

    if (PVector.dist(pos, end) < 2) {
      //println(frameCount+"muerte por llegar al fin aniadidas"+aniadidas);
      death =  true;
    }

    /*if (death && !aniadidas) {
      for (Panel p : cosa.getPanels()) {
        if (p.getCells() != null)
          for (Cell cell : p.getCells()) {
            for (int i =0; i<cell.polygon.size(); i++) {
              Point point = cell.polygon.get(i);
              PVector vp = new PVector(point.x, point.y);
              if (PVector.dist(vp, new PVector(mouseX, mouseY)) < 35) {
                //a\u00f1adimos nueva part\u00edcula
                if (particulas.size() < 100 && random(10) > 5) {
                  addParticulas(cell, point, i,life);
                  aniadidas = true;
                }
              }
            }
          }
      }

      return false;
    }*/

    return true;
  }

  public void render(PGraphics canvas) {
    canvas.stroke(c);
    canvas.strokeWeight(3);
    canvas.fill(c);
    canvas.point(pos.x, pos.y);
  }
}
// There is no need to modify the code in this tab.

 
public final class QuadGrid {
 
  public PImage img;
  private final int nbrCols, nbrRows;
  private final VPoint[][] vp;
 
  // Prevent use of default constructor
  public QuadGrid() {
    img = null;
    nbrCols = nbrRows = 0;
    vp = null;
  };
 
  /**
   * 
   * <a href="/two/profile/param">@param</a> img the image must not be null
   * <a href="/two/profile/param">@param</a> nbrXslices must be >= 1
   * <a href="/two/profile/param">@param</a> nbrYslices must be >= 1
   */
  public QuadGrid(PImage img, int nbrXslices, int nbrYslices) {
    this.img = img;
    nbrCols = (nbrXslices >= 1) ? nbrXslices : 1;
    nbrRows = (nbrYslices >= 1) ? nbrYslices : 1;
    if (img != null) {
      vp = new VPoint[nbrCols+1][nbrRows+1];
      // Set corners so top-left is [0,0] and bottom-right is [image width, image height]
      float deltaU = 1.0f/nbrCols;
      float deltaV = 1.0f/nbrRows;
      for (int col = 0; col <= nbrCols; col++)
        for (int row = 0; row <= nbrRows; row++)
          vp[col][row] = new VPoint(col * deltaU, row * deltaV);
      setCorners(0, 0, img.width, 0, img.width, img.height, 0, img.height);
    } else
      vp = null;
  }
 
  /**
   * Calculate all the quad coordinates
   *  Vetices in order TL, TR, BR, BL
   */
  public void setCorners(float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3) {
    if (vp == null) return;
    // Do outer corners
    vp[0][0].setXY(x0, y0);
    vp[nbrCols][0].setXY(x1, y1);
    vp[nbrCols][nbrRows].setXY(x2, y2);
    vp[0][nbrRows].setXY(x3, y3);
    // Top row
    float deltaX = (x1 - x0) / nbrCols;
    float deltaY = (y1 - y0) / nbrRows;
    for (int col = 0; col <= nbrCols; col++)
      vp[col][0].setXY(x0 + col * deltaX, y0 + col * deltaY); 
    // Bottom row
    deltaX = (x2 - x3) / nbrCols;
    deltaY = (y2 - y3) / nbrRows;
    for (int col = 0; col <= nbrCols; col++)
      vp[col][nbrRows].setXY(x3 + col * deltaX, y3 + col * deltaY);
    // Fill each column in the grid in turn
    for (int col = 0; col <= nbrCols; col++) {
      for (int row = 1; row < nbrRows; row++) {
        VPoint vpF = vp[col][0];
        VPoint vpL = vp[col][nbrRows];
        deltaX = (vpL.x - vpF.x) / nbrRows;
        deltaY = (vpL.y - vpF.y) / nbrRows;
        vp[col][row].setXY(vpF.x + row * deltaX, vpF.y + row * deltaY);
      }
    }
  }
 
  public void drawGrid(PGraphics app, PImage texture) {
    if (vp == null) return;
    app.textureMode(PApplet.NORMAL);
    app.noStroke(); // comment out this line to see triangles
    for (int row = 0; row < nbrRows; row++) {
      app.beginShape(PApplet.TRIANGLE_STRIP);
      app.texture(texture);
      for (int col = 0; col <= nbrCols; col++) {
 
        VPoint p0 = vp[col][row];
        VPoint p1 = vp[col][row+1];
        app.vertex(p0.x, p0.y, p0.u, p0.v);
        app.vertex(p1.x, p1.y, p1.u, p1.v);
      }
      app.endShape();
    }
  }
 
  private class VPoint {
    public float x = 0;
    public float y = 0;
    public float u;
    public float v;
 
 
    public VPoint(float u, float v) {
      this.u = u;
      this.v = v;
    }
 
    public void setXY(float x, float y) {
      this.x = x;
      this.y = y;
    }
  }
}

public class Data {
  float brightness = 1;
  float contrast= 1;
  float smooth = 0.05f;
  float threshold = 500;
}

RadioButton r1;
public void initGUI() {

  cp5 = new ControlP5(this);
  // add a vertical slider
  cp5.addSlider("brightness")
    .setPosition(200, 30)
    .setSize(200, 20)
    .setRange(0, 10)
    .setValue(data.brightness)
    .setId(1)
    ;

  cp5.addSlider("contrast")
    .setPosition(200, 50)
    .setSize(200, 20)
    .setRange(0, 4)
    .setValue(data.contrast)
    .setId(2)
    ;

  cp5.addSlider("smooth")
    .setPosition(200, 80)
    .setSize(200, 20)
    .setRange(0, 0.25f)
    .setValue(data.smooth)
    .setId(3)
    ;
    
    
    cp5.addSlider("threshold")
    .setPosition(600, 80)
    .setSize(200, 20)
    .setRange(100, 1000)
    .setValue(data.threshold)
    .setId(4)
    ;

  r1 = cp5.addRadioButton("MODOS")
    .setPosition(500, 40)
    .setSize(40, 20)
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .setItemsPerRow(5)
    .setSpacingColumn(50)
    .addItem("MODE CONF", 0)
    .addItem("MODE PLAY", 1)
    .addItem("MODE WAITTING TEST", 3);
  ;
}

public void controlEvent(ControlEvent theEvent) {
//  println("got a control event from controller with id "+theEvent.getController().getId());

  if (theEvent.isFrom(r1)) {
    
      mode = (int)theEvent.getValue();
    
  } else {

    switch(theEvent.getController().getId()) {
      case(1):
      data.brightness = theEvent.getController().getValue();
      break;
      case(2):
      data. contrast = theEvent.getController().getValue();
      break;
      case(3):
      data. smooth = theEvent.getController().getValue();
      break;
       case(4):
      data. threshold = theEvent.getController().getValue();
      break;
      
    }
  }
}

public void drawReposo() {

  background(0);

  fill(255);
  

  cosa.setColor(255);

  render.render(cosa, g);

  List<Particula> particulasParaBorrar = new ArrayList();
 // println("redner");
  for (int i = 0; i<particulas.size(); i++) {
    Particula p = particulas.get(i);
    if (!p.move()) {
      particulasParaBorrar.add(p);
    }

    p.render(g);
  }
  //println("a\u00f1adiendo particulas");
  particulas.removeAll(particulasParaBorrar);

  if (mousePressed && frameCount % 20 == 0) {
   
  }
}

public void addParticulas(Cell cell, Point point, int i,int old) {
  //vertices cont\u00edguos
  int ianterior = i-1;
  int iposterior = i+1;
  //miramos no nos salimos, hacemos lista circular
  if (ianterior < 0)
    ianterior = cell.polygon.size()-1;
  iposterior = iposterior % cell.polygon.size();
  //ya tenemos las posiciones anterior y posterior
  Point nextVertex = cell.polygon.get(iposterior);
  Point prevVertex = cell.polygon.get(ianterior);
  //ahora calculamos los vetores de movimiento
  PVector pos = new PVector(point.x, point.y);
  PVector move = PVector.sub(new PVector(nextVertex.x, nextVertex.y), pos);
  PVector move2 = PVector.sub(new PVector(prevVertex.x, prevVertex.y), pos);
  move.normalize();
  move.div(5);
  move2.normalize();

  Particula particula = new Particula();
  
  particula.init(pos, new PVector(nextVertex.x, nextVertex.y), move, color(255, 0, 0));
  particula.life = old;
  particulas.add(particula);

// Particula particula2 = new Particula();
 // particula2.init(pos, new PVector(prevVertex.x, prevVertex.y), move2, color(255, 0, 0));
 // particula2.life = old;
 // particulas.add(particula2);
}
  public void settings() {  size(1024, 768, P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "remaper12" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
