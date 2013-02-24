class LedMap extends Pixels {
    
  int[] strandSizes;
  
  LedMap(PApplet p) {
    super(p);
    strandSizes = new int[]
    {
      1001, //mapUpperHalfTopDriverSide
      400, //mapDriverSideLowerPart2
      850, //mapDriverSideLowerPart1
      997, //mapLowerHalfTopDriverSide
      1175, //TODO: mapPassengerSideUpperTop1
      
      973, //mapLowerHalfTopPassengerSide
      
      250, //mapPassengerSideLower2
      849, //mapPassengerSideLower1
    };
  }
  
  void setup() {
    super.setup();
  }
  
  int getStrandSize(int whichStrand) {
    return strandSizes[whichStrand];
  }
  
  int getNumStrands() {
    return 8;
  }
  
  void mapAllLeds() {
    
    // read array of values from our spreadsheet
    String[] lines = loadStrings("data/pixels.csv");

    // the first line is the column headers, so skip it
    for(int i = 1; i < lines.length; i++){
      int[] tokens = int(split(lines[i], ','));
      int numElements = tokens.length;

      // println("Line " + i + " has " + numElements + " elements.");
      // if this doesn't have at least 7 elements, it's probably a comment, so continue
      if(numElements < 7) {
        continue;
      }
      
      // set LED value
      ledSetNew(tokens[0], tokens[1], tokens[2], tokens[3], tokens[4], tokens[5], tokens[6]);
    }
  }  
}
