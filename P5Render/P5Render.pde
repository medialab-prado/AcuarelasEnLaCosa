
/* IPCapture sample sketch for Java and Android   *
 *                                                *
 * === IMPORTANT ===                              *
 * In Android mode, Remember to enable            *
 * INTERNET permissions in the                    *
 * Android -> Sketch permissions menu             */


/*
   Acuarelas states
 
 REPOSO efectos de luz para decorar y atraer usuarios
 PINTANDO usando por un usuario
 SETUP modo de configuración de la app
 
 Acuarelas protocol
 
 START_WAITTING_USER
 USER_DETECTED
 
 */
import java.util.ArrayList;
import java.util.List;

import deadpixel.keystone.remaper.CornerPinSurface;
import deadpixel.keystone.remaper.Keystone;
import deadpixel.keystone.remaper.MeshPoint;
import processing.core.PApplet;
import processing.core.PGraphics;
import ipcapture.*;

IPCapture cam;


int REPOSO = 0;
int PINTANDO = 1;
int SETUP = 2;

int state = REPOSO;

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


void setup() {
  size(1024, 768,P3D);
  cam = new IPCapture(this, "http://195.235.198.107:3346/?action=stream", "", "");
  cam.start();

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
}

void draw() {
  
  background(0);
  
  text("state "+state,10,10);
  text("fps: "+frameRate,10,20);
  
  if (cam.isAvailable()) {
    cam.read();
    image(cam, 0, 0);

    offscreenOrigin.beginDraw();
    offscreenOrigin.fill(255, 0, 0);
    float w = offscreenOrigin.width / 10;
    float h = offscreenOrigin.height / 10;
    for (int i = 0; i <= 10; i++) {
      for (int j = 0; j <= 10; j++) { 
        offscreenOrigin.fill(random(50+20 * i), 10 * j, random(i-j*20));
        offscreenOrigin.rect(w * i, h * j, w, h);
        offscreenOrigin.fill(255);
        offscreenOrigin.text(""+i+":"+j, w * i-w/2, h * j-h/2);
      }
    }
    //offscreenOrigin.image(cam);
    offscreenOrigin.endDraw();
  }
  
  if (state == SETUP) {
    int i = 0;
    image(offscreenOrigin, 0, 0);
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
  } else if (state == REPOSO) {
    //controlar los colores de la mesa de la cosa

    //queremos detectar si un usuario se acercó a la mesa
    //cantidad de movimiento
    //entonces pasaríamos a state = PINTANDO;

    renderCosaReposo();
  } else if (state == PINTANDO) {

    //PROCESS IMAGE con filtrado de movimientos rápidos
    // estadoActual = estadoActual + (destino - estadoActual)*0.01;
    //el último parámetro da la velocidad
    renderCosaPintando();

    //TIMEOUT para volver a estado de reposo si no se detecta movimiento
    //state = REPOSO;
  } else {
    println("TENEMOS ERROR ESTADO DESCONOCIDO "+state);
  }
}

public void renderCosaReposo() {
}

public void renderCosaPintando() {

  noStroke();
  //para todas las superficies añadidas
  //renderizamos desde target a dest
  for (int ii = 0; ii<surfaces.size(); ii++) {
    CornerPinSurface surface = surfaces.get(ii);
    CornerPinSurface surfaceTarget = surfacesTarget.get(ii);

    offscreen.beginDraw();
    offscreen.background(0);

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

public void renderRemapping() {
}

void keyPressed() {
  if (key == ' ') {
    if (cam.isAlive()) cam.stop();
    else cam.start();
  }

  if (key == 'S') {
    state = SETUP;
  }
  switch (key) {
    case 'c':
      // enter/leave calibration mode, where surfaces can be warped
      // and moved
      ks.toggleCalibration();
      ksTarget.toggleCalibration();
      break;

    case 'l':
      // loads the saved layout
      ks.save("origin-not-usable.xml");
      ks.load("origin.xml");
       ksTarget.save("origin-not-usable2.xml");
      ksTarget.load("target.xml");
      break;

    case 's':
      // saves the layout
      ks.save("origin.xml");
      ksTarget.save("target.xml");
      break;
    case 'm':
      // saves the layout
      
      if(mode == MODE_CONFIG){
        mode = MODE_VIEW;
        ks.stopCalibration();
        ksTarget.startCalibration();
      }else{
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