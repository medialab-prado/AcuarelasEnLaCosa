
public void drawReposo() {

  // background(100,20);
  fill(0, 10);
  rect(0, 0, width, height);
  fill(255);


  //cosa.setColor(55);


  // render.render(cosa, g);

  noStroke();
  int i = 0;
  int lineWidth = 5;
  float vel = 35;
  for (Panel p : cosa.getPanels()) {
    float index = indicePanels[i];
    fill(50, 0, 50, 20);
    rect(p.x, p.y, p.width, p.height);

    int id = Integer.parseInt(p.name.substring(1));
    fill(0,255,150);

    if (id >= 180 && id <= 290
      || id >= 41 && id <= 71
      || id >= 330 && id <= 351) {
      //  if (true) {
      rect(p.x+p.width-index, p.y, lineWidth, p.height);
    } else {

      rect(p.x+index, p.y, lineWidth, p.height);
    }
    if (frameCount % 2== 0)
      index+=(p.width)/vel;

    if (index > p.width)
      index = 0;

    indicePanels[i] = index;
    i++;
  }

  List<Particula> particulasParaBorrar = new ArrayList();
  // println("redner");
  for (int ii = 0; ii<particulas.size(); ii++) {
    Particula p = particulas.get(ii);
    p.move();    
    if (p.death) {
      particulasParaBorrar.add(p);
    }

    p.render(g);
  }
  //println("añadiendo particulas");
  particulas.removeAll(particulasParaBorrar);

  if (mousePressed && frameCount % 20 == 0) {
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

  particula.init(pos, new PVector(nextVertex.x, nextVertex.y), move, c);
  particula.life = old;
  particulas.add(particula);

  // Particula particula2 = new Particula();
  // particula2.init(pos, new PVector(prevVertex.x, prevVertex.y), move2, color(255, 0, 0));
  // particula2.life = old;
  // particulas.add(particula2);
}