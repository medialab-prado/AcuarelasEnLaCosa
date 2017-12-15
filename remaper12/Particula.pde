class ParticulaSystem {

  //REPOSO
  Cosa cosa;
  CosaRender render;
  Cell lastCell;
  List<Particula> particulas;
  PShape shape;
  List<PVector> vertices;
  float[] indicePanels;
  public void init() {
    //estado de reposo
    cosa = new Cosa();
    File pathP = sketchFile("paneles.txt");
    File pathC = sketchFile("CoordCeldas.txt");
    cosa.init(pathP, pathC);

    indicePanels = new float[cosa.getPanels().size()];
    // shape = createShape(POINTS);

    render = new CosaRender();
    particulas = new ArrayList();
  }
public void addPartcilesFromMouse()
{
  println(mousePressed);
  int maxParticles= 1;

  for (Panel p : pp.cosa.getPanels()) {
    if (p.getCells() != null)
      for (Cell cell : p.getCells()) {
        int countparticles = 0;
        for (int i =0; i<cell.polygon.size(); i++) {
          Point point = cell.polygon.get(i);
          PVector vp = new PVector(point.x, point.y);
          if (PVector.dist(vp, new PVector(mouseX, mouseY)) < 1050 && countparticles < maxParticles
            && pp.particulas.size() < 500 ) {
            countparticles++;
            //añadimos nueva partícula
            println(frameCount+"ñadimos nueva partícula");
            pp.addParticulas(cell, point, i, 0);
          }
        }
      }
  }
}  


  public void addParticulas(Cell cell, Point point, int i, int old) {
    //vertices contíguos
    int ianterior = i-1;
    int iposterior = i+1;
    //miramos no nos salimos, hacemos lista circular
    if (ianterior < 0)
      ianterior = cell.polygon.size()-1;
    iposterior = iposterior % cell.polygon.size();
    //ya tenemos las posiciones anterior y posterior
    Point nextVertex = cell.polygon.get(iposterior);
    //Point prevVertex = cell.polygon.get(ianterior);
    //ahora calculamos los vetores de movimiento
    PVector pos = new PVector(point.x, point.y);
    PVector move = PVector.sub(new PVector(nextVertex.x, nextVertex.y), pos);
    //PVector move2 = PVector.sub(new PVector(prevVertex.x, prevVertex.y), pos);
    move.normalize();
    move.div( 4);

    //  move2.normalize();
    move.mult(random(1, 4));

    Particula particula = new Particula();

    int r = color(255, 0, 0);
    int g = color(0, 255, 0);
    int b = color(0, 0, 255);

    int c = 0;
    switch((int)random(2)) {
    case 0:
      c = r;
      break;
    case 1:
      c = b;
      break;
    case 2:


      c = g;
      break;
    }

    particula.init(this, pos, new PVector(nextVertex.x, nextVertex.y), move, c);
    particula.life = old;
    particulas.add(particula);

    // Particula particula2 = new Particula();
    // particula2.init(pos, new PVector(prevVertex.x, prevVertex.y), move2, color(255, 0, 0));
    // particula2.life = old;
    // particulas.add(particula2);
  }

  public void drawParticles() {

    // background(100,20);
    fill(0, 10);
    rect(0, 0, width, height);
    fill(255);

    noStroke();
    int i = 0;
    int lineWidth = 5;
    float vel = 35;
    for (Panel p : pp.cosa.getPanels()) {
      float index = pp.indicePanels[i];
      fill(50, 0, 50, 20);
      rect(p.x, p.y, p.width, p.height);

      int id = Integer.parseInt(p.name.substring(1));
      fill(0, 255, 150);

      if (id >= 180 && id <= 290
        || id >= 41 && id <= 71
        || id >= 330 && id <= 351
        || id >= 110 && id <= 131) {
        //  if (true) {
        rect(p.x+p.width-index, p.y, lineWidth, p.height);
      } else {

        rect(p.x+index, p.y, lineWidth, p.height);
      }
      if (frameCount % 2== 0)
        index+=(p.width)/vel;

      if (index > p.width)
        index = 0;

      pp. indicePanels[i] = index;
      i++;
    }

    List<Particula> particulasParaBorrar = new ArrayList();
    // println("redner");
    for (int ii = 0; ii<pp.particulas.size(); ii++) {
      Particula p =pp. particulas.get(ii);
      p.move();    
      if (p.death) {
        particulasParaBorrar.add(p);
      }

      p.render(g);
    }
    //println("añadiendo particulas");
    pp. particulas.removeAll(particulasParaBorrar);

    if (mousePressed && frameCount % 20 == 0) {
    }
  }
}


class Particula {

  ParticulaSystem pp;

  PVector pos;
  PVector end;
  PVector move;
  color c;
  int maxLife = 1024*5;
  int life;
  boolean aniadidas = false;
  boolean death = false;

  public void init(ParticulaSystem pp, PVector pos, PVector end, PVector move, color c) {
    this.pos = pos;
    this.move = move;
    this.end =  end;
    this.c = c;
    life = 0;
    this.pp = pp;
  }

  public boolean move() {

    pos.add(move);

    List<Point> vecinos = new ArrayList();

    for (Panel p : this.pp.cosa.getPanels()) {

      if (p.getCells() != null) {
        // int size = 50 / p.getCells().s;  
        for (Cell cell : p.getCells()) {
          for (int i =0; i<cell.polygon.size(); i++) {
            Point point = cell.polygon.get(i);
            PVector vp = new PVector(point.x, point.y);
            if (PVector.dist(vp, new PVector(pos.x, pos.y)) < 5) {
              //añadimos nueva partícula
              if (!aniadidas && this.pp.particulas.size() < 200 && life > 100) {
                // addParticulas(cell, point, i, life);
                aniadidas = true;
                return true;
              } else {
              }
            }
          }
        }
      }
    }


    life++;
    if (life > maxLife) {
      //  println(frameCount+"muerte por viejo aniadidas"+aniadidas);
      death = true;
    }

    if (PVector.dist(pos, end) < 2) {
      //println(frameCount+"muerte por llegar al fin aniadidas"+aniadidas);
      death =  true;
    }

    float x = PVector.sub(end, pos).x;
    float y = PVector.sub(end, pos).y;
    if (move.x > 0 && x < 0) {
      death = true;
    }

    if (move.x < 0 && x > 0) {
      death = true;
    }

    if (move.y <= 0 && y > 0) {
      death = true;
    }

    if (move.y > 0 && y < 0) {
      death = true;
    }

    if (death && !aniadidas) {
      for (Panel p : pp.cosa.getPanels()) {
        if (p.getCells() != null)
          for (Cell cell : p.getCells()) {
            for (int i =0; i<cell.polygon.size(); i++) {
              Point point = cell.polygon.get(i);
              PVector vp = new PVector(point.x, point.y);
              if (PVector.dist(vp, pos) < 5) {
                //añadimos nueva partícula
                if (!aniadidas && pp.particulas.size() < 200 && random(10) > 40) {
                  pp.addParticulas(cell, point, i, life);
                  aniadidas = true;
                }
              }
            }
          }
      }

      return false;
    }

    return true;
  }

  public void render(PGraphics canvas) {
    canvas.stroke(c);
    canvas.strokeWeight(3);
    canvas.fill(c);
    canvas.point(pos.x, pos.y);
     canvas.strokeWeight(1);
    //float xdif = PVector.sub(end, pos).x;
    // canvas.text(death+":xvel:"+move.x+" xdif:"+xdif, pos.x, pos.y);
  }
}