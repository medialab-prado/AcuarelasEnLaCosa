
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
  for (Panel p : pp.cosa.getPanels()) {
    float index = pp.indicePanels[i];
    fill(50, 0, 50, 20);
    rect(p.x, p.y, p.width, p.height);

    int id = Integer.parseInt(p.name.substring(1));
    fill(0,255,150);

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