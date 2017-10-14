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


Capture cam;
//IPCapture cam;
PImage previo;
PImage finalisimo;
PImage bg;
Keystone ks;
Keystone ksTarget;


List<CornerPinSurface> surfaces;
List<CornerPinSurface> surfacesTarget;

// CornerPinSurface selected = null;

int SURFACE_X = 300;
int SURFACE_Y = 300;

PGraphics offscreen;
PGraphics offscreenOrigin;
PGraphics offscreentarget;

int MODE_CONFIG = 0;
int MODE_VIEW = 1;

int mode = MODE_CONFIG;

int numPixels;
int[] previousFrame;
BrightnessContrastController bc;

public void setup() {

  size(1024, 768, P3D);
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
   println(i,cameras[i]);
   }
   
   // The camera can be initialized directly using an 
   // element from the array returned by list():
   // cam = new Capture(this, 640, 480, "HD Pro Webcam C920", 30);
   
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

  // We need an offscreen buffer to draw the surface we
  // want projected
  // note that we're matching the resolution of the
  // CornerPinSurface.
  // (The offscreen buffer can be P2D or P3D)
  offscreen = createGraphics(SURFACE_X, SURFACE_Y, P3D);
  offscreenOrigin = createGraphics(1024, 768, P3D);
  offscreentarget = createGraphics(1024, 768, P3D);

  previousFrame = new int[640*480];
  finalisimo = createImage(640, 480, RGB);
}


public void draw() {

  // Convert the mouse coordinate into surface coordinates
  // this will allow you to use mouse events inside the
  // surface from your screen.
  // PVector surfaceMouse = surface.getTransformedMouse();

  // most likely, you'll want a black background to minimize
  // bleeding around your projection area


  //PLANTILLA FINAL    
  background(bg);


  offscreenOrigin.beginDraw();




  //CAMARA INICIO
  if (cam.available()) {
    // cam.read();
    //   }

    //  offscreenOrigin.image(cam, 0, 0);
    //if (cam.isAvailable()) {
    cam.read();
  cam.loadPixels();
   frameDif(cam);
   bc.destructiveShift(finalisimo,(int)map(mouseX,0,width,-255,255),1);
   cam.updatePixels();
   
  } 
   
   offscreenOrigin.image(cam, 0, 0, 1024, 768);

 // 
  //IMPORTANTE meter la variable offscreenOrigin. delante de imagen 

  // The following does the same, and is faster when just drawing the image
  // without any additional resizing, transformations, or tint.
  //set(0, 0, cam);



  offscreenOrigin.endDraw();    



  /**    
   offscreenOrigin.fill(255, 0, 0);
   float w = offscreenOrigin.width / 10;
   float h = offscreenOrigin.height / 10;
   for (int i = 0; i <= 10; i++) {
   for (int j = 0; j <= 10; j++) { 
   offscreenOrigin.fill(random(50+20 * i), 10 * j,random(i-j*20));
   offscreenOrigin.rect(w * i, h * j, w, h);
   offscreenOrigin.fill(255);
   offscreenOrigin.text(""+i+":"+j,w * i-w/2, h * j-h/2);
   }
   }
   offscreenOrigin.endDraw();
   */



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
  } else {
    noStroke();
    for (int ii = 0; ii<surfaces.size(); ii++) {
      CornerPinSurface surface = surfaces.get(ii);
      CornerPinSurface surfaceTarget = surfacesTarget.get(ii);

      offscreen.beginDraw();
      offscreen.background(0);
      //offscreen.text("" + i, offscreen.width / 2, offscreen.height / 2);
      // offscreen.fill(0, 255, 0);


      offscreen.noStroke();
      offscreen.beginShape(QUAD);
      offscreen.texture(offscreenOrigin);

      MeshPoint pointTL = surface.getMeshPoint(CornerPinSurface.TL);
      MeshPoint pointTR = surface.getMeshPoint(CornerPinSurface.TR);
      MeshPoint pointBL = surface.getMeshPoint(CornerPinSurface.BL);
      MeshPoint pointBR = surface.getMeshPoint(CornerPinSurface.BR);

      offscreen.vertex(0, 0, pointTL.x, pointTL.y);
      offscreen.vertex(SURFACE_X, 0, pointTR.x, pointTR.y);

      offscreen.vertex(SURFACE_X, SURFACE_Y, pointBR.x, pointBR.y);
      offscreen.vertex(0, SURFACE_Y, pointBL.x, pointBL.y);


      // offscreen.ellipse(surfaceMouse.x, surfaceMouse.y, 75, 75);
      offscreen.endShape();
      offscreen.endDraw();
      surfaceTarget.render(offscreen);
    }
  }

  // surface.
}

public void frameDif(PImage video) {
  //video.loadPixels(); // Make its pixels[] array available
  finalisimo.loadPixels();
  int movementSum = 0; // Amount of movement in the frame
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

float vel = 0.05;
    finalR = finalR + (currR - finalR)*vel;
    finalG = finalG + (currG - finalG)*vel;
    finalB = finalB + (currB - finalB)*vel;

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
      mode = MODE_VIEW;
      ks.stopCalibration();
      ksTarget.startCalibration();
    } else {
      mode = MODE_CONFIG;

      ksTarget.stopCalibration();
      ks.startCalibration();
    }

    break;
  case '+':
    // saves the layout
    CornerPinSurface cornerPinSurface = ks.createCornerPinSurface(SURFACE_X, SURFACE_Y, 10);
    cornerPinSurface.setGridColor(color(255, 0, 0));
    surfaces.add(cornerPinSurface);

    CornerPinSurface cornerPinSurface2 = ksTarget.createCornerPinSurface(SURFACE_X, SURFACE_Y, 10);
    cornerPinSurface2.setGridColor(color(255, 0, 0));
    cornerPinSurface2.x = 100;
    surfacesTarget.add(cornerPinSurface2);
    break;
  case '-':
    // saves the layout
    //  ks.save();
    break;
  }
}