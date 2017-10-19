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
import processing.video.*;



//import ipcapture.*;
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

  size(1024, 768, P3D);

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
  float vx = abs(smoothMovement-lastMovementSum);
  if (vx > 50000) {
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


  text("movement"+vx, 10, 10);
  //si detectamos una variación en la cantidad de movimiento de más de x
  //pasamos al estado de juego
  if (isMoving) {
    fill(0, 255, 0);
    timeout = millis() + TIMEOUT_TIME;
  } else {
    fill(255, 0, 0);
  }
  rect(100, 10, abs(smoothMovement-lastMovementSum)/1000.0, 10);

  text("particulas"+particulas.size()+"\n fps: "+ frameRate, 10, 30);
}

public void frameDif(PImage video) {
  //video.loadPixels(); // Make its pixels[] array available
  finalisimo.loadPixels();
  // Amount of movement in the frame
  lastMovementSum = smoothMovement;
  smoothMovement = smoothMovement +(movementSum-smoothMovement)*0.1;
  movementSum = 0;
  for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
    color currColor = video.pixels[i];
    color prevColor = previousFrame[i];
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