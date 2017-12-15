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



import ipcapture.*;
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

Capture cam2;
IPCapture cam;
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
ContrastVibrance cv;

//FILTR DE VIDEO
int numPixels;
int[] previousFrame;

int movementSum = 0;
float lastMovementSum = 0;
float smoothMovement = 0;

ParticulaSystem pp = new ParticulaSystem();

//GUI
ControlP5 cp5;

Data data;
boolean readed = false;
public void setup() {

  size(1024, 768, P3D);

  data = new Data();
  // Keystone will only BrightnessContrastController with P3D or OPENGL renderers,
  // since it relies on texture mapping to deform
  bc=new BrightnessContrastController();
  cv = new ContrastVibrance();
  cv.init(this);

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

  if (data.localCamera) {
    cam2 = new Capture(this, 640, 480);
    cam2.start();
  }
  cam = new IPCapture(this, "http://192.168.1.52:8080/?action=stream", "", "");
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

  pp.init();

  initGUI();
  frameRate(30);
}


public void draw() {

  //CAMARA INICIO
  PImage filteredCam = null;

  if (data.localCamera) {
    if (cam2.available()) {
      cam2.read();
      readed = true;
      filteredCam = cv.process(cam2);
      //filteredCam = cam2;
    }
    //  offscreenOrigin.image(cam, 0, 0);

    // cam.loadPixels();
    //bc.destructiveShift(cam, 0, data.contrast
  } else {
    if (cam.isAvailable()) {
      //ACTUALIZAMOS CAMARA SI ES POSIBLE
      cam.read();
      readed = true;
      filteredCam = cv.process(cam);
    }
  } 

  if (readed && filteredCam != null) {
    filteredCam.loadPixels();
    finalisimo = frameDif(filteredCam);
    // bc.destructiveShift(finalisimo, (int)data.brightness, 1);
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
    background(0);
    image(finalisimo, 0, 0, 1024, 768);
    // image(finalisimo, 0, 0, 1024*0.2, 768*0.2);
    for (CornerPinSurface surface : surfaces) {
      if ( data.currentSurface == 0 ||  data.currentSurface == i) {
        // render the scene, transformed using the corner pin surface
        surface.render(offscreen);
        // Draw the scene, offscreen
        offscreen.beginDraw();
        offscreen.background(255, 0);
        offscreen.text("" + i, offscreen.width / 2, offscreen.height / 2);
        // offscreen.fill(0, 255, 0);
        // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
        offscreen.endDraw();
      }
      i++;
    }
  } else if (mode == MODE_PINTANDO) {
    background(bg);
    pushStyle();
    pp.drawParticles();

    rect(mouseX, mouseY, 60, 60);
    if (frameCount % 50 == 0) {
      pp.addPartcilesFromMouse();
    }

    popStyle();
    /* noStroke();
     for (int ii = 0; ii<surfaces.size(); ii++) {
     CornerPinSurface surfaceTarget = surfaces.get(ii);
     
     offscreen.beginDraw();
     offscreen.background(0);
     //offscreen.text("" + i, offscreen.width / 2, offscreen.height / 2);
     // offscreen.fill(0, 255, 0);
     
     //*  Vetices in order TL, TR, BR, BL
     MeshPoint pointTL = surfaceTarget.getMeshPoint(CornerPinSurface.TL);
     MeshPoint pointTR = surfaceTarget.getMeshPoint(CornerPinSurface.TR);
     MeshPoint pointBL = surfaceTarget.getMeshPoint(CornerPinSurface.BL);
     MeshPoint pointBR = surfaceTarget.getMeshPoint(CornerPinSurface.BR);
     qgrid.setCorners(pointTL.x, pointTL.y, pointTR.x, pointTL.y, pointBR.x, pointBR.y, pointBL.x, pointBL.y);
     qgrid.drawGrid(offscreen, finalisimo);
     
     // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
     offscreen.endShape();
     offscreen.endDraw();
     surfaceTarget.render(offscreen);
     if (millis()>timeout) {
     mode = MODE_REPOSO;
     }
     }*/

    noStroke();
    for (int ii = 0; ii<surfaces.size(); ii++) {
      if ( data.currentSurface == 0 ||  data.currentSurface == ii) {
        CornerPinSurface surface = surfaces.get(ii);
        CornerPinSurface surfaceTarget = surfacesTarget.get(ii);

        offscreen.beginDraw();
        offscreen.background(0, 100);
        //offscreen.text("" + i, offscreen.width / 2, offscreen.height / 2);
        // offscreen.fill(0, 255, 0);
        if (ksTarget.isCalibrating())
          offscreen.tint(255, 100);
        else
          offscreen.noTint();
        offscreen.noStroke();
        offscreen.beginShape(QUAD);
        offscreen.texture(offscreenOrigin);

        int size = 1;
        int sizeGrid = 10;
        int scale = sizeGrid / size;

        for (int xxx = 0; xxx< size; xxx++) {
          for (int yyy = 0; yyy< size; yyy++) {

            int xstep = SURFACE_X/size;
            int ystep = SURFACE_Y/size;

            int xo = xstep*xxx;
            int yo = ystep*yyy;
            
            int tlindex = xxx*scale;
            int trindex = (xxx+1)*scale;
            int blindex = (xxx+1)*scale+(yyy+1)*size*scale*scale;
            int brindex = (xxx+1)*scale+(yyy+1)*size*scale*scale + size/scale;
            
            println(tlindex+" "+CornerPinSurface.TL);
            println(trindex+" "+CornerPinSurface.TR);
            println(blindex+" "+CornerPinSurface.BL);
            println(brindex+" "+CornerPinSurface.BR);
            println();

            MeshPoint pointTL = surface.getMeshPoint(tlindex);
            MeshPoint pointTR = surface.getMeshPoint(trindex);
            MeshPoint pointBL = surface.getMeshPoint(blindex);
            MeshPoint pointBR = surface.getMeshPoint(brindex);

            /*     MeshPoint pointTL = surface.getMeshPoint(CornerPinSurface.TL);
             MeshPoint pointTR = surface.getMeshPoint(CornerPinSurface.TR);
             MeshPoint pointBL = surface.getMeshPoint(CornerPinSurface.BL);
             MeshPoint pointBR = surface.getMeshPoint(CornerPinSurface.BR);
             */
            offscreen.vertex(xo, yo, pointTL.x, pointTL.y);
            offscreen.vertex(xo+xstep, yo, pointTR.x, pointTR.y);

            offscreen.vertex(xo+xstep, yo+ystep, pointBR.x, pointBR.y);
            offscreen.vertex(xo, yo+ystep, pointBL.x, pointBL.y);
          }
        }

        // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
        offscreen.endShape();

        // qgrid.setCorners(pointTL.x, pointTL.y, pointTR.x, pointTL.y, pointBR.x, pointBR.y, pointBL.x, pointBL.y);
        //qgrid.drawGrid(offscreen, offscreenOrigin);

        offscreen.endDraw();
        surfaceTarget.render(offscreen);
      }
    }

    //QUI METEMOS EL TIMEOUT SI ESTAMOS PINTANDO Y NOHAY MOVIMIENTO
  } else if (mode == MODE_REPOSO || mode == MODE_REPOSO_TEST) {
    noStroke();
    pp.drawParticles();
    if (isMoving && mode != MODE_REPOSO_TEST) {
      mode = MODE_PINTANDO;
      fill(255);
    } else {
      rect(mouseX, mouseY, 60, 60);
      if (frameCount % 50 == 0) {
        pp.addPartcilesFromMouse();
      }
    }
    //MODO REPOSO
  } else {
    //entramos en error

    println("ERROR ESTAMOS EN UN ESTADO INCORRECTO "+mode);
  }
  fill(0);
  rect(10, 10, width, 100);

  text("movement"+(smoothMovement/10000), 10, 10);
  //si detectamos una variación en la cantidad de movimiento de más de x
  //pasamos al estado de juego
  if (isMoving) {
    fill(0, 255, 0);
    timeout = millis() + TIMEOUT_TIME;
  } else {
    fill(255, 0, 0);
  }
  rect(100, 10, (smoothMovement/10000), 10);
  fill(255);
  text("particulas"+pp.particulas.size()+"\n fps: "+ frameRate, 10, 30);

  text(""+data.smooth, 250, 80);
}

public PImage frameDif(PImage video) {
  //video.loadPixels(); // Make its pixels[] array available
  finalisimo.loadPixels();
  // Amount of movement in the frame

  lastMovementSum = movementSum;
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

  smoothMovement = smoothMovement +(movementSum-smoothMovement)*0.1;

  return finalisimo;
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

public void mousePressed() {

  pp.addPartcilesFromMouse();
}

public void keyPressed() {
  switch (key) {
  case 'c':
    // enter/leave calibration mode, where surfaces can be warped
    // and moved
    ks.toggleCalibration();
    ksTarget.toggleCalibration();
    data.currentSurface = 0;
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
  case 'n':
    // saves the layout
    //  ks.save();
    data.currentSurface++;
    if (data.currentSurface >= surfaces.size())
      data.currentSurface = 0;
    break;
  }
}